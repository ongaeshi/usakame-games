# ==============================================================================
# 01. GRAPPLE ASCENT VER.2
# ------------------------------------------------------------------------------
# 振り子フックショットで迫りくる溶岩から逃げ切る縦登りアクション（完全版）
# 256x256 / 16-bit 4層シェーディングスプライト / 4ch動的BGM & SFX / GPUライトマップ演出
#
# 【操作方法】
#   Z / 左クリック : フック発射（押している間ホールド・離すと射出＆上昇リリースブースト）
#   ← / → (A / D)  : スイング加速 / 空中制御
#   ↑ / ↓ (W / S)  : ロープ巻き取り / 伸ばす
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "01. GRAPPLE ASCENT VER.2",
  save_id: "grapple_ascent_ver2",
  save_salt: "v2g01ga8"
)

SCREEN_W = 256
SCREEN_H = 256
WALL_L = 14.0
WALL_R = 242.0
GRAVITY = 0.16
MAX_HOOK_DIST = 118.0

$best_alt = save_get("best_alt", 0)
$best_score = save_get("best_score", 0)
$best_combo = save_get("best_combo", 0)
$lightmap ||= create_surface(SCREEN_W, SCREEN_H, :gpu)

$zones = [
  { alt: 0,   name: "MAGMA DEPTHS",   bg: :cave,     tint: [255, 145, 110], amb_col: 2, dark: 0.48 },
  { alt: 100, name: "OBSIDIAN SHAFT", bg: :cave,     tint: [175, 140, 235], amb_col: 1, dark: 0.54 },
  { alt: 220, name: "CRYSTAL VAULT",  bg: :cave,     tint: [110, 205, 255], amb_col: 1, dark: 0.50 },
  { alt: 360, name: "SOLAR SPIRE",    bg: :mountain, tint: [255, 200, 130], amb_col: 2, dark: 0.38 }
]

def clamp_v(v, lo, hi)
  return lo if v < lo
  return hi if v > hi
  v
end

def lerp_v(a, b, t)
  a + (b - a) * t
end

def dist_sq(x1, y1, x2, y2)
  dx = x2 - x1
  dy = y2 - y1
  dx * dx + dy * dy
end

def zone_for_alt(alt)
  res = $zones[0]
  i = 0
  while i < $zones.size
    res = $zones[i] if alt >= $zones[i][:alt]
    i += 1
  end
  res
end

# ------------------------------------------------------------------------------
# 汎用エフェクトシステム（GPU加算発光・残像・衝撃波・火花対応）
# ------------------------------------------------------------------------------
class EffectSystem
  attr_accessor :shake_timer, :shake_power, :hitstop, :flash_timer, :flash_col

  def initialize
    @particles = []
    @rings = []
    @popups = []
    @ghosts = []
    @scorch_marks = []
    @shake_timer = 0
    @shake_max = 1
    @shake_power = 0.0
    @hitstop = 0
    @flash_timer = 0
    @flash_col = 7
  end

  def shake(power, frames)
    if power >= @shake_power || @shake_timer <= 0
      @shake_power = power.to_f
      @shake_max = frames > 0 ? frames : 1
    end
    @shake_timer = frames if frames > @shake_timer
  end

  def stop(frames)
    @hitstop = frames if frames > @hitstop
  end

  def flash(frames, col = 7)
    if frames >= @flash_timer
      @flash_timer = frames
      @flash_col = col
    end
  end

  def burst(x, y, count, col, spd = 2.5, life = 22, grav = 0.05)
    i = 0
    while i < count
      ang = rand() * Math::PI * 2.0
      v = (0.3 + rand() * 0.8) * spd
      ml = life + rand(10)
      @particles << {
        x: x.to_f, y: y.to_f,
        vx: cos(ang) * v, vy: sin(ang) * v,
        life: ml, max_life: ml,
        col: (i % 4 == 0 ? 7 : col), size: rand(2) + 1, grav: grav, glow: true
      }
      i += 1
    end
  end

  def directional_sparks(x, y, nx, ny, count, col, spd = 2.8)
    base_ang = atan2(ny, nx)
    i = 0
    while i < count
      ang = base_ang + (rand() - 0.5) * 1.3
      v = (0.4 + rand() * 0.7) * spd
      ml = 14 + rand(10)
      @particles << {
        x: x.to_f, y: y.to_f,
        vx: cos(ang) * v, vy: sin(ang) * v,
        life: ml, max_life: ml,
        col: (i % 3 == 0 ? 7 : col), size: rand(2) + 1, grav: 0.06, glow: true
      }
      i += 1
    end
  end

  def ember(x, y, col)
    ml = 28 + rand(22)
    @particles << {
      x: x.to_f, y: y.to_f,
      vx: (rand() - 0.5) * 0.7, vy: -0.7 - rand() * 1.3,
      life: ml, max_life: ml,
      col: col, size: 1 + rand(2), grav: -0.012, glow: true
    }
  end

  def ring(x, y, max_r, col, spd = 2.2)
    @rings << { x: x.to_f, y: y.to_f, r: 2.0, max_r: max_r.to_f, col: col, spd: spd }
  end

  def popup(x, y, text, col = 7, size = 8)
    @popups << { x: x.to_f, y: y.to_f, vy: -0.95, life: 40, max_life: 40, text: text, col: col, size: size }
  end

  def ghost(x, y, frame, rot, sx, sy, flip_x, col)
    @ghosts << {
      x: x.to_f, y: y.to_f, frame: frame, rot: rot,
      sx: sx, sy: sy, flip_x: flip_x, col: col,
      life: 11, max_life: 11
    }
  end

  def scorch(x, y, col)
    @scorch_marks << { x: x.to_f, y: y.to_f, col: col, life: 240 }
    @scorch_marks.shift if @scorch_marks.size > 28
  end

  def prune_below(limit_y)
    @scorch_marks.reject! { |s| s[:y] > limit_y }
  end

  def update
    @shake_timer -= 1 if @shake_timer > 0
    @flash_timer -= 1 if @flash_timer > 0

    i = 0
    while i < @particles.size
      p = @particles[i]
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:vy] += p[:grav]
      p[:vx] *= 0.96
      p[:life] -= 1
      i += 1
    end
    @particles.reject! { |p| p[:life] <= 0 }

    i = 0
    while i < @rings.size
      @rings[i][:r] += @rings[i][:spd]
      i += 1
    end
    @rings.reject! { |r| r[:r] >= r[:max_r] }

    i = 0
    while i < @popups.size
      pp = @popups[i]
      pp[:y] += pp[:vy]
      pp[:vy] *= 0.92
      pp[:life] -= 1
      i += 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }

    i = 0
    while i < @ghosts.size
      @ghosts[i][:life] -= 1
      i += 1
    end
    @ghosts.reject! { |g| g[:life] <= 0 }

    i = 0
    while i < @scorch_marks.size
      @scorch_marks[i][:life] -= 1
      i += 1
    end
    @scorch_marks.reject! { |s| s[:life] <= 0 }
  end

  def shake_offset
    return [0.0, 0.0] if @shake_timer <= 0
    decay = @shake_timer.to_f / @shake_max.to_f
    amp = @shake_power * decay
    sx = (rand() * 2.0 - 1.0) * amp
    sy = (rand() * 2.0 - 1.0) * amp
    [sx, sy]
  end

  def draw_scorch_marks
    i = 0
    while i < @scorch_marks.size
      s = @scorch_marks[i]
      al = clamp_v(s[:life] / 90.0, 0.0, 0.55)
      circfill(s[:x].to_i, s[:y].to_i, 3, 0, al)
      blend(:add)
      circfill(s[:x].to_i, s[:y].to_i, 2, s[:col], al * 0.65)
      blend(:normal)
      i += 1
    end
  end

  def draw_world_additive
    blend(:add)
    # スピード残像
    i = 0
    while i < @ghosts.size
      g = @ghosts[i]
      al = (g[:life].to_f / g[:max_life].to_f) * 0.46
      circfill(g[:x].to_i, g[:y].to_i, 5, g[:col], al * 0.55)
      spr_ext(spr_id(:climber, g[:frame]), g[:x].to_i, g[:y].to_i, g[:rot], g[:sx], g[:sy], g[:flip_x], false, nil, al)
      i += 1
    end

    # 二重ショックウェーブリング
    i = 0
    while i < @rings.size
      r = @rings[i]
      prog = r[:r] / r[:max_r]
      al = clamp_v((1.0 - prog) * 0.9, 0.08, 0.95)
      ri = r[:r].to_i
      circ(r[:x].to_i, r[:y].to_i, ri, r[:col], al)
      circ(r[:x].to_i, r[:y].to_i, ri - 1, 7, al * 0.55) if ri > 3
      i += 1
    end

    # 発光パーティクル
    i = 0
    while i < @particles.size
      p = @particles[i]
      al = clamp_v(p[:life].to_f / p[:max_life].to_f, 0.15, 1.0)
      px = p[:x].to_i
      py = p[:y].to_i
      if p[:size] >= 2 && p[:life] > 6
        circfill(px, py, 2, p[:col], al * 0.55)
        pset(px, py, 7, al)
      else
        pset(px, py, p[:col], al)
      end
      i += 1
    end
    blend(:normal)
  end

  def draw_popups
    i = 0
    while i < @popups.size
      pp = @popups[i]
      al = clamp_v(pp[:life] / 14.0, 0.0, 1.0)
      print_text(pp[:text], pp[:x].to_i, pp[:y].to_i, pp[:col], pp[:size], al, :center, 0)
      i += 1
    end
  end
end

# ------------------------------------------------------------------------------
# タイトルシーン
# ------------------------------------------------------------------------------
class TitleScene
  def initialize
    @t = 0
    @embers = []
    i = 0
    while i < 18
      @embers << { x: rand() * 256.0, y: rand() * 220.0, vy: 0.4 + rand() * 0.9, col: (i % 2 == 0 ? 9 : 10) }
      i += 1
    end
    music(:title_bgm, true, 0.72)
  end

  def update
    @t += 1
    i = 0
    while i < @embers.size
      e = @embers[i]
      e[:y] -= e[:vy]
      e[:x] += sin(@t * 0.05 + i) * 0.3
      if e[:y] < -6.0
        e[:y] = 222.0
        e[:x] = 16.0 + rand() * 224.0
      end
      i += 1
    end

    if btnp(1) || btnp(:mouse_l) || btnp(:space)
      sfx(:confirm, -1, 0.9, 1.0)
      run GameScene.new
    end
  end

  def draw
    cls(0)
    bg(:cave, dim: 0.48, tint: [255, 150, 115], scroll_y: -@t * 0.45, mirror_y: true)

    # 左右の溶岩洞窟壁タイル
    wy = -(@t % 32)
    while wy < 256
      wf = ((wy / 16).to_i).abs % 2
      spr(spr_id(:wall_l, wf), 0, wy)
      spr(spr_id(:wall_r, wf), 240, wy)
      wy += 16
    end

    # 松明の揺らぎ演出
    tf = (@t / 6) % 2
    spr(spr_id(:wall_torch, tf), 12, 86, false)
    spr(spr_id(:wall_torch, (tf + 1) % 2), 228, 86, true)

    # デモ振り子アクション
    ax = 128
    ay = 72
    ang = sin(@t * 0.055) * 0.92
    ang_vel = cos(@t * 0.055)
    px = ax + sin(ang) * 44.0
    py = ay + cos(ang) * 44.0

    # ロープ + 光彩
    blend(:add)
    line(ax, ay, px.to_i, py.to_i, 12, 3, 0.35)
    circfill(ax, ay, 18, 12, 0.12)
    circfill(ax, ay, 10, 12, 0.18)
    circfill(20, 92, 26, 9, 0.10)
    circfill(20, 92, 14, 10, 0.18)
    circfill(236, 92, 26, 9, 0.10)
    circfill(236, 92, 14, 10, 0.18)
    i = 0
    while i < @embers.size
      e = @embers[i]
      circfill(e[:x].to_i, e[:y].to_i, 2, e[:col], 0.35)
      pset(e[:x].to_i, e[:y].to_i, 7, 0.85)
      i += 1
    end
    blend(:normal)

    line(ax, ay, px.to_i, py.to_i, 7, 1, 0.95)
    spr(spr_id(:anchor, (@t / 12) % 2), ax - 8, ay - 8)
    spr(spr_id(:hook_claw, 1), ax - 4, ay - 4)

    # デモジェムとブーストアンカー
    gf = (@t / 8) % 4
    spr(spr_id(:gem, gf), 64, 92 + (sin(@t * 0.1) * 2.5).to_i)
    spr(spr_id(:gem, (gf + 2) % 4), 176, 92 + (cos(@t * 0.1) * 2.5).to_i)
    spr(spr_id(:boost_anchor, (@t / 8) % 2), 184, 58)

    cf = ang_vel.abs > 0.35 ? 1 : 0
    spr_ext(spr_id(:climber, cf), px.to_i - 8, py.to_i - 8, -ang * 36.0, 1.0, 1.0, ang_vel < 0, false)

    # 煮えたぎる溶岩海
    draw_lava_band(220, @t)

    # タイトルロゴパネル
    rectfill(20, 14, 216, 42, 0, 0.84)
    rect(20, 14, 216, 42, 9, 1, 0.95)
    rect(22, 16, 212, 38, 10, 1, 0.45)
    print_text("GRAPPLE ASCENT", 128, 21, 10, 8, 1.0, :center, 0, 4)
    print_text("VER.2 - OVERDRIVE EDITION", 128, 32, 12, 8, 1.0, :center, 0)
    print_text("SWING ABOVE THE RISING MAGMA!", 128, 44, 7, 8, 0.9, :center, 0)

    # 操作説明 & ハイスコアボックス
    rectfill(18, 128, 220, 68, 0, 0.84)
    rect(18, 128, 220, 68, 12, 1, 0.75)
    print_text("HOLD Z / CLICK : GRAPPLE & BOOST", 28, 135, 12, 8, 1.0, :left, 0)
    print_text("LEFT / RIGHT   : SWING ACCEL", 28, 147, 7, 8, 0.95, :left, 0)
    print_text("UP / DOWN      : REEL ROPE", 28, 159, 7, 8, 0.95, :left, 0)
    line(26, 171, 230, 171, 5, 1, 0.7)
    print_text("BEST: #{$best_alt}m   HI-SCORE: #{$best_score}", 128, 176, 10, 8, 1.0, :center, 0)
    if $best_combo > 1
      print_text("MAX COMBO: x#{$best_combo}", 128, 186, 11, 8, 0.95, :center, 0)
    end

    pulse_a = 0.55 + (sin(@t * 0.16) * 0.45)
    print_text("PRESS Z OR CLICK TO LAUNCH!", 128, 204, 10, 8, pulse_a, :center, 0)
  end

  def draw_lava_band(ly, tick)
    pal_bank(3)
    rectfill(0, ly + 18, 256, 48, 2)
    rectfill(0, ly + 12, 256, 10, 4)
    rectfill(0, ly + 6, 256, 10, 8)
    pal_bank(0)
    lf = (tick / 7) % 2
    lx = 0
    while lx < 256
      wy = ly + (sin(lx * 0.09 + tick * 0.14) * 2.2).to_i
      spr(spr_id(:lava_top, (lf + (lx / 16)) % 2), lx, wy - 2)
      lx += 16
    end
    blend(:add)
    rectfill(0, ly - 10, 256, 14, 9, 0.22)
    rectfill(0, ly - 3, 256, 8, 10, 0.28)
    blend(:normal)
  end
end

# ------------------------------------------------------------------------------
# ゲームシーン
# ------------------------------------------------------------------------------
class GameScene
  def initialize
    @t = 0
    @fx = EffectSystem.new
    @px = 128.0
    @py = 172.0
    @vx = 1.8
    @vy = -3.8
    @facing_left = false
    @sx_scale = 1.0
    @sy_scale = 1.0
    @boost_glow = 0

    @cam_y = 0.0
    @lava_y = 262.0
    @lava_speed = 0.42
    @start_y = 172.0
    @max_alt = 0
    @next_milestone = 100
    @new_best_shown = ($best_alt <= 0)
    @score = 0
    @combo = 0
    @combo_timer = 0
    @dirty_save = false

    @hooked = false
    @hook_x = 0.0
    @hook_y = 0.0
    @rope_len = 50.0
    @hook_anchor = nil
    @target_anchor = nil
    @hook_shoot_t = 0

    @anchors = []
    @gems = []
    @torches = []
    @banner_text = "ZONE 1: MAGMA DEPTHS"
    @banner_col = 10
    @banner_timer = 95
    @cur_zone_alt = 0

    @bgm_mode = :normal
    @bgm_switch_cd = 0
    music(:ascent_bgm, true, 0.75)

    # 序盤から即座に爽快なスイング＆ブーストが繋がる初期配置
    seed_opening_shaft
    @top_gen_y = 16.0
    generate_up_to(-420.0)

    @dead = false
    @dead_timer = 0
  end

  def seed_opening_shaft
    @anchors << { x: 132.0, y: 114.0, kind: :normal, pulse: 0, used: false }
    @gems << { x: 148.0, y: 132.0, got: false, bob: 8 }
    @anchors << { x: 86.0,  y: 72.0,  kind: :normal, pulse: 15, used: false }
    @gems << { x: 106.0, y: 88.0, got: false, bob: 22 }
    @anchors << { x: 158.0, y: 30.0,  kind: :boost,  pulse: 30, used: false }
    @gems << { x: 158.0, y: 12.0, got: false, bob: 35 }
    @torches << { x: 18.0, y: 120.0, side: :l }
    @torches << { x: 238.0, y: 56.0, side: :r }
  end

  def generate_up_to(target_y)
    while @top_gen_y > target_y
      step_y = 34.0 + rand() * 20.0
      ny = @top_gen_y - step_y
      nx = 32.0 + rand() * 192.0
      if !@anchors.empty?
        last = @anchors.last
        if (nx - last[:x]).abs > 96.0
          nx = clamp_v(last[:x] + (rand() < 0.5 ? -75.0 : 75.0), 28.0, 228.0)
        end
      end
      kind = rand(6) == 0 ? :boost : :normal
      @anchors << { x: nx, y: ny, kind: kind, pulse: rand(60), used: false }

      if rand(10) < 7
        gx = clamp_v(nx + (rand() - 0.5) * 44.0, 26.0, 230.0)
        gy = ny + 14.0 + (rand() - 0.5) * 16.0
        @gems << { x: gx, y: gy, got: false, bob: rand(60) }
      end

      if rand(3) == 0
        on_left = rand(2) == 0
        @torches << { x: on_left ? 18.0 : 238.0, y: ny + 8.0, side: on_left ? :l : :r }
      end

      @top_gen_y = ny
    end
  end

  def find_best_anchor
    best = nil
    best_score = 999999.0
    use_mouse = btn(:mouse_l) || btnp(:mouse_l)
    mx = mouse_x.to_f
    my = mouse_y.to_f + @cam_y

    i = 0
    while i < @anchors.size
      a = @anchors[i]
      d2 = dist_sq(@px, @py, a[:x], a[:y])
      if d2 <= MAX_HOOK_DIST * MAX_HOOK_DIST && a[:y] <= @py + 36.0
        sc = sqrt(d2) + (a[:y] > @py ? 45.0 : 0.0)
        sc -= 8.0 if a[:kind] == :boost && !a[:used]
        if use_mouse
          sc += sqrt(dist_sq(mx, my, a[:x], a[:y])) * 0.9
        end
        if sc < best_score
          best_score = sc
          best = a
        end
      end
      i += 1
    end
    best
  end

  def register_combo_points(base_pts)
    @combo += 1
    @combo_timer = 210
    @dirty_save = true if @combo > $best_combo
    $best_combo = @combo if @combo > $best_combo
    pts = base_pts * @combo
    @score += pts
    if @score > $best_score
      $best_score = @score
      @dirty_save = true
    end
    pts
  end

  def flush_save_data
    return unless @dirty_save
    @dirty_save = false
    save_set("best_alt", $best_alt)
    save_set("best_score", $best_score)
    save_set("best_combo", $best_combo)
  end

  def update_dynamic_bgm
    @bgm_switch_cd -= 1 if @bgm_switch_cd > 0
    return if @bgm_switch_cd > 0

    lava_dist = @lava_y - @py
    if @bgm_mode == :normal && lava_dist < 92.0
      @bgm_mode = :pinch
      @bgm_switch_cd = 90
      sfx(:danger_alarm, -1, 0.78, 1.0)
      music(:pinch_bgm, true, 0.82)
    elsif @bgm_mode == :pinch && lava_dist > 140.0
      @bgm_mode = :normal
      @bgm_switch_cd = 90
      music(:ascent_bgm, true, 0.75)
    end
  end

  def update
    @t += 1
    @sx_scale = lerp_v(@sx_scale, 1.0, 0.22)
    @sy_scale = lerp_v(@sy_scale, 1.0, 0.22)
    @boost_glow -= 1 if @boost_glow > 0
    @banner_timer -= 1 if @banner_timer > 0

    if @dead
      @dead_timer += 1
      @fx.update
      if @t % 4 == 0
        @fx.ember(16.0 + rand() * 224.0, @lava_y - 2.0, rand(2) == 0 ? 9 : 10)
      end
      if @dead_timer > 28 && (btnp(1) || btnp(2) || btnp(:mouse_l) || btnp(:space))
        sfx(:confirm, -1, 0.88, 1.05)
        run GameScene.new
      end
      return
    end

    if @fx.hitstop > 0
      @fx.hitstop -= 1
      @fx.update
      return
    end

    if @combo_timer > 0
      @combo_timer -= 1
      @combo = 0 if @combo_timer <= 0 && !@hooked
    end

    @target_anchor = find_best_anchor unless @hooked

    holding = btn(1) || btn(:mouse_l) || btn(:space)
    pressed = btnp(1) || btnp(:mouse_l) || btnp(:space)
    move_l = btn(:left) || btn(:key_a)
    move_r = btn(:right) || btn(:key_d)
    move_u = btn(:up) || btn(:key_w)
    move_d = btn(:down) || btn(:key_s)

    if pressed && !@hooked && @target_anchor
      @hooked = true
      @hook_anchor = @target_anchor
      @hook_x = @hook_anchor[:x]
      @hook_y = @hook_anchor[:y]
      @hook_shoot_t = 6
      dx = @px - @hook_x
      dy = @py - @hook_y
      @rope_len = clamp_v(sqrt(dx * dx + dy * dy), 22.0, MAX_HOOK_DIST)
      @sx_scale = 0.84
      @sy_scale = 1.18
      @fx.burst(@hook_x, @hook_y, 9, 12, 2.3, 15)
      @fx.ring(@hook_x, @hook_y, 15.0, 12, 2.0)
      @fx.scorch(@hook_x, @hook_y, 12)

      if @hook_anchor[:kind] == :boost && !@hook_anchor[:used]
        @hook_anchor[:used] = true
        @vy = -5.75
        @vx *= 1.16
        @hooked = false
        @boost_glow = 28
        @sx_scale = 0.72
        @sy_scale = 1.34
        register_combo_points(50)
        pitch = clamp_v(0.95 + @combo * 0.04, 0.95, 1.65)
        sfx(:boost_burst, -1, 0.95, pitch)
        @fx.burst(@hook_x, @hook_y, 22, 10, 3.5, 24)
        @fx.burst(@hook_x, @hook_y, 10, 9, 2.4, 18)
        @fx.ring(@hook_x, @hook_y, 30.0, 10, 2.8)
        @fx.ring(@hook_x, @hook_y, 18.0, 7, 2.0)
        @fx.scorch(@hook_x, @hook_y, 9)
        @fx.popup(@hook_x, @hook_y - 10.0, "OVERDRIVE x#{@combo}!", 10)
        @fx.shake(3.4, 10)
        @fx.flash(4, 10)
        @fx.stop(3)
      else
        sfx(:grapple_shoot, -1, 0.78, 0.95 + rand() * 0.12)
        sfx(:grapple_latch, -1, 0.72, clamp_v(0.95 + @combo * 0.03, 0.95, 1.45))
      end
    elsif !holding && @hooked
      @hooked = false
      if @vy < -1.0
        @vy -= 0.78
        @sx_scale = 0.82
        @sy_scale = 1.22
        register_combo_points(10)
        pitch = clamp_v(0.96 + @combo * 0.035, 0.96, 1.6)
        sfx(:release_jump, -1, 0.78, pitch)
        @fx.burst(@px, @py, 8, 12, 2.0, 14)
        @fx.ring(@px, @py, 14.0, 7, 1.9)
      else
        sfx(:release_jump, -1, 0.45, 0.82)
      end
    end

    @hook_shoot_t -= 1 if @hook_shoot_t > 0

    # 重力 & スイング制御
    @vy += GRAVITY

    if @hooked
      if move_l
        @vx -= 0.14
        @facing_left = true
      end
      if move_r
        @vx += 0.14
        @facing_left = false
      end
      if move_u
        @rope_len -= 1.6
        sfx(:reel_tick, -1, 0.35, 1.15) if @t % 7 == 0 && @rope_len > 20.0
      end
      if move_d
        @rope_len += 1.6
        sfx(:reel_tick, -1, 0.30, 0.85) if @t % 7 == 0 && @rope_len < MAX_HOOK_DIST - 2.0
      end
      @rope_len = clamp_v(@rope_len, 18.0, MAX_HOOK_DIST)
    else
      if move_l
        @vx -= 0.12
        @facing_left = true
      end
      if move_r
        @vx += 0.12
        @facing_left = false
      end
      @vx *= 0.992
    end

    spd = sqrt(@vx * @vx + @vy * @vy)
    if spd > 7.5
      @vx = @vx / spd * 7.5
      @vy = @vy / spd * 7.5
      spd = 7.5
    end

    @px += @vx
    @py += @vy

    # 振り子拘束
    if @hooked
      dx = @px - @hook_x
      dy = @py - @hook_y
      dist = sqrt(dx * dx + dy * dy)
      if dist > @rope_len && dist > 0.001
        nx = dx / dist
        ny = dy / dist
        @px = @hook_x + nx * @rope_len
        @py = @hook_y + ny * @rope_len
        dot = @vx * nx + @vy * ny
        if dot > 0.0
          @vx -= dot * nx
          @vy -= dot * ny
        end
        @vx *= 0.996
        @vy *= 0.996
      end
    end

    # 左右岩壁バウンド演出
    if @px < WALL_L
      @px = WALL_L
      @vx = @vx.abs * 0.75
      @facing_left = false
      @sx_scale = 0.78
      @sy_scale = 1.22
      @fx.directional_sparks(@px - 2.0, @py, 1.0, -0.3, 7, 9, 2.2)
      @fx.scorch(@px - 3.0, @py, 9)
      @fx.shake(1.6, 5)
      sfx(:wall_bounce, -1, 0.68, 0.95 + rand() * 0.15)
    elsif @px > WALL_R
      @px = WALL_R
      @vx = -@vx.abs * 0.75
      @facing_left = true
      @sx_scale = 0.78
      @sy_scale = 1.22
      @fx.directional_sparks(@px + 2.0, @py, -1.0, -0.3, 7, 9, 2.2)
      @fx.scorch(@px + 3.0, @py, 9)
      @fx.shake(1.6, 5)
      sfx(:wall_bounce, -1, 0.68, 0.95 + rand() * 0.15)
    end

    # スピード残像（Afterimage）
    climber_frame = current_climber_frame
    rot = current_climber_rot
    if (@boost_glow > 0 && @t % 2 == 0) || (spd > 3.1 && @t % 3 == 0)
      gcol = @boost_glow > 0 ? 10 : (@hooked ? 12 : 9)
      @fx.ghost(@px - 8.0, @py - 8.0, climber_frame, rot, @sx_scale, @sy_scale, @facing_left, gcol)
    end

    # ジェム取得
    i = 0
    while i < @gems.size
      g = @gems[i]
      if !g[:got] && dist_sq(@px, @py, g[:x], g[:y]) < 17.0 * 17.0
        g[:got] = true
        pts = register_combo_points(25)
        pitch = clamp_v(0.95 + @combo * 0.05, 0.95, 1.9)
        sfx(:gem_get, -1, 0.85, pitch)
        @sx_scale = 1.16
        @sy_scale = 0.88
        @fx.burst(g[:x], g[:y], 12, 10, 2.5, 20)
        @fx.ring(g[:x], g[:y], 18.0, 10, 2.2)
        @fx.popup(g[:x], g[:y] - 8.0, "+#{pts}", 10)
      end
      i += 1
    end

    # 高度・マイルストーン・ゾーン更新
    alt = ((@start_y - @py) / 4.0).to_i
    if alt > @max_alt
      prev_best = $best_alt
      @max_alt = alt
      if @max_alt > $best_alt
        $best_alt = @max_alt
        @dirty_save = true
        if !@new_best_shown && prev_best > 0
          @new_best_shown = true
          sfx(:milestone, -1, 0.95, 1.12)
          @fx.flash(4, 11)
          @fx.popup(@px, @py - 18.0, "NEW BEST!", 11)
        end
      end

      if @max_alt >= @next_milestone
        flush_save_data
        sfx(:milestone, -1, 0.92, 1.0)
        @fx.ring(@px, @py, 36.0, 11, 2.6)
        @banner_text = "#{@next_milestone}m REACHED!"
        @banner_col = 11
        @banner_timer = 90
        @next_milestone += 100
      end

      zn = zone_for_alt(@max_alt)
      if zn[:alt] != @cur_zone_alt
        @cur_zone_alt = zn[:alt]
        @banner_text = "ENTERING: #{zn[:name]}"
        @banner_col = 12
        @banner_timer = 110
      end
    end

    target_cam = @py - 148.0
    @cam_y = lerp_v(@cam_y, target_cam, 0.14) if target_cam < @cam_y

    # 溶岩上昇
    @lava_speed = 0.42 + @max_alt * 0.0012
    @lava_speed = 1.35 if @lava_speed > 1.35
    gap = @lava_y - @cam_y
    if gap > 300.0
      @lava_y = @cam_y + 300.0
    else
      @lava_y -= @lava_speed
    end

    update_dynamic_bgm

    # 溶岩火の粉
    if @t % 2 == 0
      @fx.ember(16.0 + rand() * 224.0, @lava_y - 2.0, rand(2) == 0 ? 9 : 10)
    end

    # 溶岩接触判定
    if @py > @lava_y - 6.0
      @dead = true
      @hooked = false
      flush_save_data
      stop_music
      sfx(:lava_death, -1, 1.0, 1.0)
      sfx(:gameover, -1, 0.9, 1.0)
      @fx.burst(@px, @py, 32, 8, 4.0, 32)
      @fx.burst(@px, @py, 20, 10, 2.8, 26)
      @fx.ring(@px, @py, 42.0, 9, 3.0)
      @fx.ring(@px, @py, 26.0, 7, 2.2)
      @fx.shake(6.5, 22)
      @fx.flash(8, 8)
    end

    # 上方チャンク生成 & 不要オブジェクト掃除
    generate_up_to(@cam_y - 280.0)
    @anchors.reject! { |a| a[:y] > @lava_y + 80.0 }
    @gems.reject! { |g| g[:got] || g[:y] > @lava_y + 80.0 }
    @torches.reject! { |tc| tc[:y] > @lava_y + 80.0 }
    @fx.prune_below(@lava_y + 80.0)

    @fx.update
  end

  def current_climber_frame
    return 2 if @boost_glow > 0 || (@hooked && (btn(:up) || btn(:key_w))) || @vy < -4.4
    return 1 if @hooked
    0
  end

  def current_climber_rot
    @hooked ? clamp_v(@vx * 6.5, -38.0, 38.0) : clamp_v(@vx * 3.8, -24.0, 24.0)
  end

  def draw
    cls(0)
    zn = zone_for_alt(@max_alt)
    shk = @fx.shake_offset
    cam_x = shk[0].to_i
    cam_y = (@cam_y + shk[1]).to_i

    bg(zn[:bg], dim: zn[:dark], tint: zn[:tint], scale: 1.04,
       scroll_y: @cam_y * 0.25 + shk[1] * 0.3, scroll_x: shk[0] * 0.3, mirror_y: true)

    # 遠景の浮遊ダスト / 熱気粒
    blend(:add)
    m = 0
    while m < 10
      mx = ((m * 53 + sin(@t * 0.03 + m) * 14.0) % 224 + 16).to_i
      my = (((m * 61 - @cam_y * 0.45 - @t * 0.35) % 256) + 256) % 256
      pset(mx, my.to_i, (m % 2 == 0 ? 9 : 12), 0.38)
      m += 1
    end
    blend(:normal)

    camera(cam_x, cam_y)

    # 高度ライン（100mごとのシャフトマーカー）
    draw_altitude_markers(cam_y)

    # 左右の16-bit玄武岩・溶岩脈壁タイル
    wy_start = ((cam_y / 16.0).floor.to_i * 16) - 16
    wy_end = cam_y + 272
    wy = wy_start
    while wy < wy_end
      wf = ((wy / 16).to_i).abs % 2
      spr(spr_id(:wall_l, wf), 0, wy)
      spr(spr_id(:wall_r, wf), 240, wy)
      wy += 16
    end

    # 壁掛け松明
    tf = (@t / 6) % 2
    i = 0
    while i < @torches.size
      tc = @torches[i]
      if tc[:y] >= cam_y - 24 && tc[:y] <= cam_y + 272
        spr(spr_id(:wall_torch, (tf + i) % 2), tc[:x].to_i - 8, tc[:y].to_i - 8, tc[:side] == :r)
      end
      i += 1
    end

    # 壁やアンカーに残る焦げ跡デカール
    @fx.draw_scorch_marks

    # ターゲットロックオン・レティクル
    if !@hooked && @target_anchor && !@dead
      draw_target_reticle(@target_anchor)
    end

    # アンカー描画
    af = (@t / 10) % 2
    bf = (@t / 7) % 2
    i = 0
    while i < @anchors.size
      a = @anchors[i]
      if a[:y] >= cam_y - 24 && a[:y] <= cam_y + 272
        ax = a[:x].to_i - 8
        ay = a[:y].to_i - 8
        if a[:kind] == :boost
          if a[:used]
            spr(:anchor_used, ax, ay)
          else
            spr(spr_id(:boost_anchor, (bf + i) % 2), ax, ay)
          end
        else
          spr(spr_id(:anchor, (af + i) % 2), ax, ay)
        end
      end
      i += 1
    end

    # 回転プリズムジェム描画
    gf = (@t / 7) % 4
    i = 0
    while i < @gems.size
      g = @gems[i]
      if !g[:got] && g[:y] >= cam_y - 24 && g[:y] <= cam_y + 272
        gy = g[:y] + sin(@t * 0.11 + g[:bob]) * 2.5
        spr(spr_id(:gem, (gf + i) % 4), g[:x].to_i - 8, gy.to_i - 8)
      end
      i += 1
    end

    # エネルギーロープ + フッククロー描画
    if @hooked
      draw_grapple_rope
    end

    # プレイヤー描画（Squash & Stretch + 3フレームアニメ）
    unless @dead
      c_id = spr_id(:climber, current_climber_frame)
      spr_ext(c_id, (@px - 8.0).to_i, (@py - 8.0).to_i, current_climber_rot, @sx_scale, @sy_scale, @facing_left, false)
    end

    # 煮えたぎる溶岩海（ワールド座標）
    draw_world_lava(cam_y)

    # GPU ライトマップ乗算合成（暗がり＋プレイヤー光＋アンカー光＋溶岩照り返し）
    camera()
    clip()
    draw_gpu_lightmap(cam_x, cam_y, zn)

    # ワールド空間の加算発光パス（残像・衝撃波・火花・ブルーム）
    camera(cam_x, cam_y)
    draw_world_bloom(cam_y)
    @fx.draw_world_additive
    @fx.draw_popups

    # スクリーン空間エフェクト & HUD
    camera()
    clip()
    draw_speed_lines_and_danger
    draw_hud(zn)
  end

  def draw_altitude_markers(cam_y)
    m_start = (((@start_y - (cam_y + 260.0)) / 200.0).floor.to_i) * 50
    m_start = 50 if m_start < 50
    m = m_start
    while m < m_start + 250
      wy = (@start_y - m * 4.0).to_i
      if wy >= cam_y - 12 && wy <= cam_y + 268
        line(16, wy, 240, wy, 1, 1, 0.45)
        print_text("#{m}m", 20, wy - 9, 6, 8, 0.55)
      end
      m += 50
    end
  end

  def draw_target_reticle(ta)
    tx = ta[:x].to_i
    ty = ta[:y].to_i
    col = (ta[:kind] == :boost && !ta[:used]) ? 10 : 11
    pulse = (sin(@t * 0.28) * 2.0).to_i
    r = 10 + pulse

    # 点線ガイドライン
    steps = 7
    s = 1
    while s < steps
      if (s + (@t / 3)) % 2 == 0
        t0 = s.to_f / steps.to_f
        t1 = (s + 0.55) / steps.to_f
        x0 = lerp_v(@px, ta[:x], t0).to_i
        y0 = lerp_v(@py, ta[:y], t0).to_i
        x1 = lerp_v(@px, ta[:x], t1).to_i
        y1 = lerp_v(@py, ta[:y], t1).to_i
        line(x0, y0, x1, y1, col, 1, 0.55)
      end
      s += 1
    end

    # 四隅のロックオンブラケット
    line(tx - r, ty - r, tx - r + 4, ty - r, col, 1, 0.95)
    line(tx - r, ty - r, tx - r, ty - r + 4, col, 1, 0.95)
    line(tx + r - 4, ty - r, tx + r, ty - r, col, 1, 0.95)
    line(tx + r, ty - r, tx + r, ty - r + 4, col, 1, 0.95)
    line(tx - r, ty + r - 4, tx - r, ty + r, col, 1, 0.95)
    line(tx - r, ty + r, tx - r + 4, ty + r, col, 1, 0.95)
    line(tx + r - 4, ty + r, tx + r, ty + r, col, 1, 0.95)
    line(tx + r, ty + r - 4, tx + r, ty + r, col, 1, 0.95)
  end

  def draw_grapple_rope
    pxi = @px.to_i
    pyi = @py.to_i
    hxi = @hook_x.to_i
    hyi = @hook_y.to_i
    ready_boost = @vy < -1.0
    glow_col = ready_boost ? 10 : 12

    blend(:add)
    line(pxi, pyi - 3, hxi, hyi, glow_col, 3, ready_boost ? 0.52 : 0.35)
    blend(:normal)
    line(pxi, pyi - 3, hxi, hyi, 7, 1, 0.95)

    claw_frame = @hook_shoot_t > 2 ? 0 : 1
    spr(spr_id(:hook_claw, claw_frame), hxi - 4, hyi - 4)
  end

  def draw_world_lava(cam_y)
    ly = @lava_y.to_i
    return if ly >= cam_y + 272

    pal_bank(3)
    rectfill(0, ly + 18, 256, 300, 2)
    rectfill(0, ly + 11, 256, 10, 4)
    rectfill(0, ly + 5, 256, 10, 8)
    pal_bank(0)
    lf = (@t / 6) % 2
    lx = 0
    while lx < 256
      wy = ly + (sin(lx * 0.11 + @t * 0.17) * 2.5).to_i
      spr(spr_id(:lava_top, (lf + (lx / 16)) % 2), lx, wy - 3)
      lx += 16
    end
  end

  def draw_gpu_lightmap(cam_x, cam_y, zn)
    pxs = (@px - cam_x).to_i
    pys = (@py - cam_y).to_i
    amb_lift = clamp_v(1.0 - zn[:dark] * 0.82, 0.38, 0.78)
    pulse = (sin(@t * 0.12) * 3.0).to_i

    render_to($lightmap) do
      cls(0, 1.0)
      rectfill(0, 0, SCREEN_W, SCREEN_H, zn[:amb_col], 0.85)
      rectfill(0, 0, SCREEN_W, SCREEN_H, 7, amb_lift)

      blend(:add)
      # クライマー周囲の多段ソフトライト
      unless @dead
        circfill(pxs, pys, 88 + pulse, 12, 0.22)
        circfill(pxs, pys, 56 + pulse / 2, 7, 0.34)
        circfill(pxs, pys, 28, 7, 0.55)
        if @boost_glow > 0
          circfill(pxs, pys, 72, 10, 0.38)
        end
      end

      # アンカー光源
      i = 0
      while i < @anchors.size
        a = @anchors[i]
        ays = (a[:y] - cam_y).to_i
        if ays > -36 && ays < 292
          axs = (a[:x] - cam_x).to_i
          if a[:kind] == :boost && !a[:used]
            circfill(axs, ays, 38, 9, 0.38)
            circfill(axs, ays, 20, 10, 0.55)
          elsif !a[:used]
            circfill(axs, ays, 26, 12, 0.28)
            circfill(axs, ays, 13, 7, 0.42)
          end
        end
        i += 1
      end

      # 松明光源
      i = 0
      while i < @torches.size
        tc = @torches[i]
        tys = (tc[:y] - cam_y).to_i
        if tys > -44 && tys < 300
          txs = (tc[:x] - cam_x).to_i
          tp = (sin(@t * 0.2 + i) * 3.0).to_i
          circfill(txs, tys - 2, 44 + tp, 9, 0.34)
          circfill(txs, tys - 2, 22, 10, 0.48)
        end
        i += 1
      end

      # ジェムのきらめき光源
      i = 0
      while i < @gems.size
        g = @gems[i]
        if !g[:got]
          gys = (g[:y] - cam_y).to_i
          if gys > -24 && gys < 280
            circfill((g[:x] - cam_x).to_i, gys, 18, 10, 0.34)
          end
        end
        i += 1
      end

      # 下方から迫る溶岩の強烈な照り返し
      lys = (@lava_y - cam_y).to_i
      if lys < 320
        rectfill(0, lys - 96, 256, 120, 8, 0.34)
        rectfill(0, lys - 54, 256, 80, 9, 0.48)
        rectfill(0, lys - 22, 256, 60, 10, 0.68)
      end
      blend(:normal)
    end

    draw_surface($lightmap, 0, 0, 1.0, :mul)
  end

  def draw_world_bloom(cam_y)
    blend(:add)
    # ブーストアンカー＆ジェムの加算ハロー
    i = 0
    while i < @anchors.size
      a = @anchors[i]
      if a[:y] >= cam_y - 24 && a[:y] <= cam_y + 272
        if a[:kind] == :boost && !a[:used]
          circfill(a[:x].to_i, a[:y].to_i, 12 + (sin(@t * 0.18 + i) * 2.0).to_i, 9, 0.24)
        else
          circfill(a[:x].to_i, a[:y].to_i, 8, 12, 0.14) unless a[:used]
        end
      end
      i += 1
    end

    # 松明の炎ブルーム
    i = 0
    while i < @torches.size
      tc = @torches[i]
      if tc[:y] >= cam_y - 24 && tc[:y] <= cam_y + 272
        circfill(tc[:x].to_i, tc[:y].to_i - 3, 10 + (sin(@t * 0.25 + i) * 1.5).to_i, 9, 0.24)
      end
      i += 1
    end

    # 溶岩表面の白熱グロー
    ly = @lava_y.to_i
    if ly < cam_y + 272
      rectfill(0, ly - 14, 256, 18, 9, 0.22)
      rectfill(0, ly - 4, 256, 10, 10, 0.30)
    end
    blend(:normal)
  end

  def draw_speed_lines_and_danger
    # 高速上昇時の集中スピードライン
    if @vy < -4.2 && !@dead
      blend(:add)
      al = clamp_v(((-@vy - 4.2) / 3.2) * 0.45, 0.08, 0.45)
      k = 0
      while k < 6
        sx = (k < 3) ? (6 + k * 6) : (250 - (k - 3) * 6)
        sy = ((@t * 15 + k * 47) % 240)
        line(sx, sy, sx, sy + 24, (@boost_glow > 0 ? 10 : 12), 1, al)
        k += 1
      end
      blend(:normal)
    end

    # 溶岩接近時のピンチ赤色ビネットパルス
    lava_dist = @lava_y - @py
    if lava_dist < 105.0 && !@dead
      danger_a = clamp_v((1.0 - lava_dist / 105.0) * (0.35 + (sin(@t * 0.3) * 0.18).abs), 0.05, 0.55)
      blend(:add)
      rect(0, 19, 256, 237, 8, 3, danger_a)
      rectfill(0, 236, 256, 20, 8, danger_a * 0.45)
      blend(:normal)
      if (@t / 10) % 2 == 0
        print_text("! MAGMA DANGER !", 128, 242, 8, 8, 0.95, :center, 0)
      end
    end

    # 画面フラッシュ演出
    if @fx.flash_timer > 0
      blend(:add)
      rectfill(0, 0, 256, 256, @fx.flash_col, clamp_v(@fx.flash_timer / 10.0, 0.0, 0.55))
      blend(:normal)
    end
  end

  def draw_hud(zn)
    rectfill(0, 0, 256, 20, 0, 0.88)
    line(0, 20, 256, 20, @bgm_mode == :pinch ? 8 : 12, 1, 0.85)

    print_text("ALT:#{@max_alt}m", 6, 4, 10, 8, 1.0, :left, 0)
    print_text("SCR:#{@score}", 74, 4, 7, 8, 1.0, :left, 0)

    if @combo > 1
      bar_w = clamp_v((@combo_timer / 210.0 * 34.0).to_i, 0, 34)
      rectfill(146, 13, 34, 3, 1)
      rectfill(146, 13, bar_w, 3, 11)
      print_text("x#{@combo}", 148, 3, 11, 8, 1.0, :left, 0)
    end

    print_text("BEST:#{$best_alt}m", 250, 4, 6, 8, 1.0, :right, 0)

    # ゾーン・マイルストーンバナー
    if @banner_timer > 0 && !@dead
      ba = clamp_v(@banner_timer / 20.0, 0.0, 1.0)
      rectfill(42, 24, 172, 14, 0, 0.76 * ba)
      rect(42, 24, 172, 14, @banner_col, 1, 0.55 * ba)
      print_text(@banner_text, 128, 27, @banner_col, 8, ba, :center, 0)
    end

    if @dead
      rectfill(28, 72, 200, 106, 0, 0.90)
      rect(28, 72, 200, 106, 8, 1, 0.95)
      rect(30, 74, 196, 102, 9, 1, 0.45)
      print_text("CONSUMED BY MAGMA!", 128, 82, 8, 8, 1.0, :center, 0)
      line(40, 94, 216, 94, 2, 1, 0.8)
      print_text("ALTITUDE   : #{@max_alt}m", 52, 102, 10, 8, 1.0, :left, 0)
      print_text("SCORE      : #{@score}", 52, 114, 7, 8, 1.0, :left, 0)
      print_text("BEST ALT   : #{$best_alt}m", 52, 126, 11, 8, 1.0, :left, 0)
      print_text("HI-SCORE   : #{$best_score}", 52, 138, 12, 8, 1.0, :left, 0)
      if (@dead_timer / 16) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 128, 158, 10, 8, 1.0, :center, 0)
      end
    end
  end
end

run TitleScene.new

__END__
# パレット1: ヒーロー（コバルトスーツ・真紅のスカーフ・黄金バックル 4層ランプ）
@PALETTE 1
0: #0D0A14
1: #1A2854
2: #8E1838
4: #7A3E2E
6: #74C8FF
7: #FFFDF4
8: #ED3854
9: #E68A1E
A: #FFE852
C: #2E72EB
E: #FF889C
F: #F8C4A0

# パレット2: マギテックアンカー＆ブーストコア（鋼鉄・シアン結晶・太陽金 4層ランプ）
@PALETTE 2
0: #0C0914
1: #18223C
3: #0C5E80
4: #7A2C16
5: #3B4D6E
6: #8AA6CA
7: #F6FCFF
8: #FF2E54
9: #F07C18
A: #FFE448
B: #84FAFF
C: #20B8F4

# パレット3: 火山洞窟壁・溶岩・プリズムジェム・松明（玄武岩・灼熱マグマ 4層ランプ）
@PALETTE 3
0: #0B0710
1: #1D152B
2: #5E1122
3: #0E7E60
4: #A6261E
5: #382B4A
6: #65537A
7: #FFFFF2
8: #F23038
9: #FF8A18
A: #FFEE4A
B: #2CF098
D: #9684AD

@SPRITE :climber 16x16 pal:1
....0000000.....
...01CC66CC10...
..096769967690..
..01FFFFFFFF10..
..0FF0FFFF0FF0..
.028EEEE888820..
028801CC66108E0.
022001CCCC108EA0
.00..019AA91000.
.....01CCCC10...
....01C6001C10..
....0110..0110..
...04940..04940.
...0000....0000.
................
................
---
...........000..
....00000008EA0.
...01CC66C08E0..
..09676996700...
..0FF0FFFF0F0...
0028EEEE88820...
08EE801CC6C10...
0282001CCCC10...
.00..019AA90....
....01CCCCC0....
...01CC11CC0....
..0494004940....
..0000..0000....
................
................
................
---
.........0AA0...
....000008EA80..
...01CC660880...
..09676996760...
..0FF0FFFF0F0...
..028EEEE8820...
.02801CC6610....
.08201CCCC10....
.020.019AA90....
..0..01CCC10....
.....01C6C10....
.....0110110....
.....0490490....
.....000.000....
................
................

@SPRITE :anchor 16x16 pal:2
....00000000....
..006677665500..
.06655000055110.
.06503CCBB30510.
06503CB77BC30510
0650CB7BB7BC0510
0510CBC33CBC0110
05103CCCCCC30110
.051033CC330110.
.01550000005510.
..001156651100..
....06700650....
....060..050....
....05666510....
.....000000.....
................
---
....00000000....
..006777765500..
.06655000055110.
.0650CBBBB30510.
0650CB7777BC0510
0650B7BBBB7B0510
0510B7BCCB7C0110
05103CBBBBC30110
.05103CCCC30110.
.01550000005510.
..001157751100..
....07700650....
....060..050....
....06776510....
.....000000.....
................

@SPRITE :boost_anchor 16x16 pal:2
......0000......
....009AA900....
.0009A7777A9000.
09A909A77A909A40
0A7A90499409A940
09AA909AA909940.
.04909A77A9040..
..009A7AA7A900..
..049AA88AA940..
...0499889940...
....00499400....
.....09AA90.....
.....0A77A0.....
......0990......
.......00.......
................
---
.00...0770...00.
09A0009AA9000A40
0A7A9A7777A9A790
09AA90977909AA40
.04909A77A90940.
..009A7777A900..
..09A77AA77A90..
..09AA9889AA90..
...0499889940...
....04499440....
.....009900.....
.....0A77A0.....
......0770......
......0AA0......
.......00.......
................

@SPRITE :anchor_used 16x16 pal:2
......0000......
....00566500....
.00056655665000.
0565051111505510
0515014884105110
.01101498410110.
..001544445100..
...0155115510...
....01155110....
.....001100.....
......0550......
......0110......
.......00.......
................
................
................

@SPRITE :hook_claw 8x8 pal:2
.060060.
06700760
050BB050
.0CBBC0.
.03CC30.
..0550..
..0110..
...00...
---
..0000..
.067760.
06B77B50
05B77B10
.03CC30.
..0650..
..0110..
...00...

@SPRITE :gem 16x16 pal:3
................
.......00.......
......0AA0......
.....0A77A0.....
....0A77AA90....
...0A77AAAA90...
..0A77AAAAAA90..
..0A7AAAA99940..
..0AAAAA999420..
...0AAA999420...
....0A999420....
.....099420.....
......0420......
.......00.......
................
................
---
................
.......00.......
......07A0......
.....077AA0.....
....0A7AAA90....
....0A7AAA90....
...0A7AAAA940...
...0AAAAA9940...
...0AAAA99420...
....0AA99420....
....0AA94220....
.....099420.....
......0420......
.......00.......
................
................
---
.......7........
..7....00....A..
......07A0......
......07A0......
.....07AA90.....
.....07AA90.....
.....0AAA90.....
.....0AA940.....
.....0AA940.....
.....0A9420.....
......0940......
......0940......
..A...0420...7..
.......00.......
........7.......
................
---
................
.......00.......
......0A70......
.....0AA770.....
....09AAA7A0....
....09AAA7A0....
...049AAAA7A0...
...0499AAAAA0...
...02499AAAA0...
....02499AA0....
....02249AA0....
.....024990.....
......0240......
.......00.......
................
................

@SPRITE :wall_l 16x16 pal:3
0115556D60......
0155666DD0......
01524456D60.....
012494256D0.....
01248415560.....
00122101560.....
011000156D0.....
01551156DD60....
015665566D60....
01155511560.....
00011101560.....
012200156D0.....
01492156DD0.....
01242155660.....
01121156D60.....
00111556D60.....
---
0011556DD60.....
01556666D60.....
0156651560......
01155101560.....
001100156D0.....
01242156DD60....
014982556D60....
01249411560.....
00124201550.....
011020156D0.....
01551156DD0.....
01566556660.....
0155511560......
001110156D0.....
01122156DD0.....
011421556D0.....

@SPRITE :wall_r 16x16 pal:3
......06D6555110
......0DD6665510
.....06D65442510
.....0D652494210
.....06551484210
.....06510122100
.....0D651000110
....06DD65115510
....06D665566510
.....06511555110
.....06510111000
.....0D651002210
.....0DD65129410
.....06655124210
.....06D65112110
.....06D65511100
---
.....06DD6551100
.....06D66665510
......0651566510
.....06510155110
.....0D651001100
....06DD65124210
....06D655289410
.....06511494210
.....05510242100
.....0D651020110
.....0DD65115510
.....06665566510
......0651155510
.....0D651011100
.....0DD65122110
.....0D655124110

@SPRITE :lava_top 16x16 pal:3
..000......000..
00AAA00..00AAA00
AA777AA00AA777AA
99AAA99AA99AAA99
8999999999988999
8889994224988899
8842242002488888
8420024224889988
884224888889AA98
9888888999999988
99988899AA998884
8999888999988422
8888842488884202
4888420248888424
2488842488448888
2248888884224888
---
......0000......
00..00AAAA00..00
AA00AA7777AA00AA
7AA99AAAAAA99AA7
9999999889999999
9988998888942249
8888888998420024
8899889AA9422424
89AA989999888888
8899888888842248
4888842248842024
2488420024884248
0248842248888899
2488888888998999
8884488844998884
8842248422488842

@SPRITE :wall_torch 16x16 pal:3
.......00.......
......09A0......
.....08A790.....
.....08A7A0.....
....089A7A90....
....0489AA80....
.....048980.....
....006DD600....
....05666650....
.....015510.....
....0156510.....
...0155110......
..01510.........
..000...........
................
................
---
........00......
.......0A90.....
......097A0.....
.....09A7A80....
....09AA7980....
....08AA9840....
.....089840.....
....006DD600....
....05666650....
.....015510.....
....0156510.....
...0155110......
..01510.........
..000...........
................
................

@SFX :confirm
wave=pulse12 T240 L16 O5 d f a > d f8:fade

@SFX :grapple_shoot
wave:pulse freq:880->320 dur:0.075 env:punch vol:0.75

@SFX :grapple_latch
wave:square freq:520->1160 dur:0.055 env:decay vol:0.78

@SFX :release_jump
wave:triangle freq:260->680 dur:0.11 env:decay vol:0.80

@SFX :boost_burst
wave:phaser freq:320->920->1360 dur:0.22 env:punch vol:0.95

@SFX :gem_get
wave=pulse12 T260 L16 O5 a > c# e a8:fade

@SFX :wall_bounce
wave:square freq:220->85 dur:0.07 env:punch vol:0.72

@SFX :reel_tick
wave:pulse12 freq:680->420 dur:0.025 env:decay vol:0.45

@SFX :danger_alarm
wave:saw freq:440->620->440 dur:0.24 env:flat vol:0.75

@SFX :milestone
wave=pulse T220 L16 O4 e g b > e g b > e8:fade

@SFX :lava_death
wave:saw freq:360->65 dur:0.34 env:drop vol:0.95

@SFX :gameover
wave=saw T150 L8 O4 f e d c# d2:fade

# タイトルBGM（8小節 × 4拍 = 64八分音符）
@MUSIC :title_bgm
ch0 wave=pulse12 vol=4 T116 L8 O4 d4 f a > d4 c < a  a#4 a g a2  g4 a a# > c4 < a# g  a4 g f e2  d4 f a > f4 e d  c4 e g > c2 <  a#4 > d c < a4 g f  e4 c# e d2
ch1 wave=pulse vol=3 T116 L8 O3 a > d f a f d < a > d  < a# > d f a# < a > c# e a  < g a# > d g < c e g > c  < f a > c f < e a > c# e  < a > d f a f d < a > f  < g > c e g e c < g > e  < a# > d f a# < a > d f a  < a > c# e a < f a > d4
ch2 wave=tri vol=5 T116 L8 O2 d4 d a > d4 < a4  < a#4 a# > f < a4 > e4  < g4 g > d c4 g4  < f4 > c4 < a4 > e4  d4 d a > d4 < f4  c4 c g > c4 < g4  < a#4 > f4 < a4 > d4  < a4 > e4 d4 < a4 >
ch3 wave=noise vol=2 T116 L8 O5 c r > g < r d r > g < r  c r > g < r d r > g g <  c r > g < r d r > g < r  c r > g < c d r d d  c > g < d > g < c r d > g <  c > g < d > g < c r d > g <  c > g < d > g < c c d > g <  c d c d d d c r

# 通常登攀BGM（12小節 × 4拍 = 96八分音符）
@MUSIC :ascent_bgm
ch0 wave=pulse vol=4 T144 L8 O4 e4 g b > e4 d < b  > c4 < b g a4 b > d <  e4 g b > g4 f# e  d4 < b > d e2 <  > c4 e g > c4 < b g  b4 g d g2 <  a4 > c e d4 c < a  b4 > c < a b2  > e4 d c g4 e c <  d4 g b > d2 <  > c4 < b a g4 f# g  f#4 b > d# e2 <
ch1 wave=pulse12 vol=3 T144 L8 O4 < b > e g b g e < b > e  c e g > c < d f# a > d <  < b > e g b > e < b g e  d f# a > d < < b > e g b  c e g > c < g e c g  < b > d g b g d < b > d  c e a > c < f# a > c < a  < b > d# f# b a f# d# f#  c e g > c < g e c e  < b > d g b > d < b g d  c e a > c < < b > e g b  < b > d# f# b g e < b4 >
ch2 wave=tri vol=5 T144 L8 O2 e > e < e > e < e g b g  c > c < c g d > d < d a  e > e < e > e < e g b g  d > d < d a e > e < < b > d  c > c < c > c < c e g e  g > g < g > g < g b > d < b  a > a < a > e < f# > f# < d a  < b > b < b > f# < b > d# f# a  c > c < c g c e g e  g > g < g > d < g b > d < g  a > e < a g e > b < e g  < b > f# < b > d# e4 < b4 >
ch3 wave=noise vol=2 T144 L8 O5 c > g < d > g < c c d > g <  c > g < d > g < c d c > g <  c > g < d > g < c c d > g <  c > g < d c d d c d  c > g < d > g < c > g < d > g <  c > g < d > g < c c d > g <  c > g < d > g < c > g < d > g <  c d c d c c d d  c > g < d > g < c c d > g <  c > g < d > g < c d c > g <  c > g < d > g < c c d > g <  d c d c d d c c

# 溶岩接近ピンチBGM（8小節 × 4拍 = 64八分音符）
@MUSIC :pinch_bgm
ch0 wave=saw vol=4 T172 L8 O4 f f > c < g# f4 g# > c <  f# f# > c# < a f#4 a > c# <  g g > d < a# g4 a# > d <  > c4 < a#4 g#4 g4  > f4 d# c# c4 < a# g#  g4 g# a# > c2 <  c#4 f d# c4 < a# g#  g4 > c < e f2
ch1 wave=square vol=3 T172 L8 O3 g# g# > f c < g#4 > c f <  a a > f# c# < a4 > c# f# <  a# a# > g d < a#4 > d g <  > e4 c#4 c4 < e4  g# > c f g# e c < g# > c <  g a# > c# g e c < g a#  g# > c# f g# d# c < g# > c <  g > c e g f c < g#4
ch2 wave=tri vol=6 T172 L8 O2 f > f < f > f < f f g# > c <  f# > f# < f# > f# < f# f# a > c# <  g > g < g > g < g g a# > d <  c > c < a# a# g# g# g e  f > f < f > c < g# > d# < g# > c <  g > d < g a# c > c < g e  c# > c# < c# g# d# > d# < d# a#  c g > c < e f4 c4
ch3 wave=noise vol=3 T172 L8 O5 c > g < d > g < c > g < d > g <  c > g < d > g < c c d > g <  c > g < d > g < c > g < d > g <  d c d c d d c d  c > g < d > g < c > g < d > g <  c > g < d > g < c d c > g <  c > g < d > g < c c d d  d d c d d d c c
