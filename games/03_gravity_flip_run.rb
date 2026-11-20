# ==============================================================================
# 03. GRAVITY FLIP RUN
# ------------------------------------------------------------------------------
# 床⇔天井の重力反転でネオン回廊を疾走するスピードラン
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   Z / Space / ↑ / ↓ / 左クリック : 重力反転 (床⇔天井)
#   X / Enter / 右クリック         : フェーズダッシュ (無敵突進)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "03. GRAVITY FLIP RUN"
)

FLOOR_Y = 208.0
CEIL_Y = 48.0
PLAYER_X = 54.0

$flip_best_dist ||= 0
$flip_best_score ||= 0

class EffectSystem
  attr_accessor :shake_timer, :shake_power, :hitstop, :flash_timer, :flash_col

  def initialize
    @particles = []
    @trails = []
    @rings = []
    @popups = []
    @shake_timer = 0
    @shake_power = 0.0
    @hitstop = 0
    @flash_timer = 0
    @flash_col = 7
  end

  def shake(power, frames)
    @shake_power = power.to_f if power > @shake_power || @shake_timer <= 0
    @shake_timer = frames if frames > @shake_timer
  end

  def stop(frames)
    @hitstop = frames if frames > @hitstop
  end

  def flash(frames, col = 7)
    @flash_timer = frames if frames > @flash_timer
    @flash_col = col
  end

  def burst(x, y, count, col, spd = 2.5, life = 16)
    i = 0
    while i < count
      ang = rand() * Math::PI * 2.0
      v = (0.3 + rand() * 0.7) * spd
      @particles << {
        x: x.to_f, y: y.to_f,
        vx: cos(ang) * v, vy: sin(ang) * v,
        life: life + rand(8), col: col, size: rand(2) + 1
      }
      i += 1
    end
  end

  def trail(x, y, col, flip_y)
    @trails << { x: x.to_f, y: y.to_f, col: col, flip_y: flip_y, life: 10 }
  end

  def ring(x, y, max_r, col, spd = 2.4)
    @rings << { x: x.to_f, y: y.to_f, r: 2.0, max_r: max_r.to_f, col: col, spd: spd }
  end

  def popup(x, y, text, col = 7)
    @popups << { x: x.to_f, y: y.to_f, vy: -0.7, life: 28, text: text, col: col }
  end

  def update(scroll_spd)
    @shake_timer -= 1 if @shake_timer > 0
    @flash_timer -= 1 if @flash_timer > 0

    @particles.each do |p|
      p[:x] += p[:vx] - scroll_spd * 0.4
      p[:y] += p[:vy]
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }

    @trails.each do |tr|
      tr[:x] -= scroll_spd
      tr[:life] -= 1
    end
    @trails.reject! { |tr| tr[:life] <= 0 }

    @rings.each { |r| r[:r] += r[:spd] }
    @rings.reject! { |r| r[:r] >= r[:max_r] }

    @popups.each do |pp|
      pp[:y] += pp[:vy]
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }
  end

  def shake_offset
    return [0.0, 0.0] if @shake_timer <= 0
    [(rand() * 2.0 - 1.0) * @shake_power, (rand() * 2.0 - 1.0) * @shake_power]
  end

  def draw
    @trails.each do |tr|
      if tr[:life] > 4 || tr[:life] % 2 == 0
        spr_ext(:runner, tr[:x].to_i, tr[:y].to_i, 0.0, 1.0, 1.0, false, tr[:flip_y], tr[:col])
      end
    end
    @rings.each do |r|
      circ(r[:x].to_i, r[:y].to_i, r[:r].to_i, r[:col])
    end
    @particles.each do |p|
      if p[:size] <= 1
        pset(p[:x].to_i, p[:y].to_i, p[:col])
      else
        rectfill(p[:x].to_i, p[:y].to_i, p[:size], p[:size], p[:col])
      end
    end
    @popups.each do |pp|
      print_text(pp[:text], pp[:x].to_i - pp[:text].length * 3, pp[:y].to_i, pp[:col])
    end
  end
end

def draw_corridor(scroll_x, speed_lvl, shk_x, shk_y)
  tint = speed_lvl < 2 ? [140, 220, 255] : (speed_lvl < 4 ? [220, 140, 255] : [255, 190, 110])
  bg(:cyber, dim: 0.45, tint: tint, scale: 1.04,
     scroll_x: scroll_x * 0.45 + shk_x * 0.3, y: shk_y * 0.3, mirror_x: true)

  # 天井・床のネオンレール
  rectfill(0, 0, 256, CEIL_Y.to_i, 0)
  rectfill(0, FLOOR_Y.to_i, 256, 256 - FLOOR_Y.to_i, 0)
  line(0, CEIL_Y.to_i, 256, CEIL_Y.to_i, 12)
  line(0, CEIL_Y.to_i - 2, 256, CEIL_Y.to_i - 2, 1)
  line(0, FLOOR_Y.to_i, 256, FLOOR_Y.to_i, 12)
  line(0, FLOOR_Y.to_i + 2, 256, FLOOR_Y.to_i + 2, 1)

  # スクロールするグリッド線
  off = (scroll_x.to_i) % 32
  gx = -off
  while gx < 260
    line(gx, CEIL_Y.to_i - 16, gx + 12, CEIL_Y.to_i, 1)
    line(gx, FLOOR_Y.to_i, gx + 12, FLOOR_Y.to_i + 16, 1)
    gx += 32
  end
end

class TitleScene
  def initialize
    @t = 0
  end

  def update
    @t += 1
    if btnp(4) || btnp(:mouse_l)
      run GameScene.new
    end
  end

  def draw
    cls(0)
    draw_corridor(@t * 3.0, 1, 0.0, 0.0)

    # デモ走行キャラ
    spr_ext(:runner, 64, FLOOR_Y.to_i - 8, 0.0, 1.0, 1.0, false, false)

    rectfill(24, 64, 208, 40, 0)
    rect(24, 64, 208, 40, 12)
    print_text("GRAVITY FLIP RUN", 80, 72, 10)
    print_text("NEON CORRIDOR SPEEDRUNNER", 53, 86, 12)

    rectfill(24, 114, 208, 62, 0)
    rect(24, 114, 208, 62, 5)
    print_text("Z / SPACE / CLICK : FLIP GRAVITY", 32, 124, 7)
    print_text("X / ENTER / R-CLK : PHASE DASH", 32, 138, 11)
    if $flip_best_dist > 0
      print_text("BEST: #{$flip_best_dist}m  HI: #{$flip_best_score}", 54, 156, 10)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO RUN", 59, 186, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @fx = EffectSystem.new
    @py = FLOOR_Y - 8.0
    @vy = 0.0
    @grav_dir = 1
    @grounded = true
    @coyote = 0
    @flip_buf = 0

    @dash_timer = 0
    @dash_cd = 0

    @scroll_x = 0.0
    @base_spd = 2.6
    @dist = 0
    @score = 0
    @combo = 0

    @obstacles = []
    @orbs = []
    @next_spawn_x = 290.0

    @dead = false
    @dead_timer = 0
  end

  def spawn_pattern
    x = @next_spawn_x
    pat = rand(5)
    if pat == 0
      # 床スパイク + 天井コイン
      @obstacles << { x: x, y: FLOOR_Y - 14.0, w: 22.0, h: 14.0, kind: :spike_floor }
      i = 0
      while i < 3
        @orbs << { x: x - 12.0 + i * 16.0, y: CEIL_Y + 18.0, got: false }
        i += 1
      end
      @next_spawn_x += 110.0
    elsif pat == 1
      # 天井スパイク + 床コイン
      @obstacles << { x: x, y: CEIL_Y, w: 22.0, h: 14.0, kind: :spike_ceil }
      i = 0
      while i < 3
        @orbs << { x: x - 12.0 + i * 16.0, y: FLOOR_Y - 18.0, got: false }
        i += 1
      end
      @next_spawn_x += 110.0
    elsif pat == 2
      # 交互ゲート
      @obstacles << { x: x, y: FLOOR_Y - 24.0, w: 16.0, h: 24.0, kind: :laser }
      @obstacles << { x: x + 68.0, y: CEIL_Y, w: 16.0, h: 24.0, kind: :laser }
      @orbs << { x: x + 34.0, y: 128.0, got: false }
      @next_spawn_x += 150.0
    elsif pat == 3
      # 中央ドローン + 上下選択
      @obstacles << { x: x, y: 120.0, w: 14.0, h: 14.0, kind: :drone, phase: rand() * 6.0 }
      @orbs << { x: x, y: FLOOR_Y - 16.0, got: false }
      @orbs << { x: x, y: CEIL_Y + 16.0, got: false }
      @next_spawn_x += 95.0
    else
      # 連続ブロック
      @obstacles << { x: x, y: CEIL_Y, w: 32.0, h: 18.0, kind: :spike_ceil }
      @obstacles << { x: x + 58.0, y: FLOOR_Y - 18.0, w: 32.0, h: 18.0, kind: :spike_floor }
      @orbs << { x: x + 28.0, y: 128.0, got: false }
      @next_spawn_x += 145.0
    end
  end

  def update
    @t += 1
    if @dead
      @dead_timer += 1
      @fx.update(0.0)
      if @dead_timer > 30 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    if @fx.hitstop > 0
      @fx.hitstop -= 1
      @fx.update(0.0)
      return
    end

    # スピード計算
    @base_spd = 2.6 + @dist * 0.0022
    @base_spd = 5.4 if @base_spd > 5.4
    cur_spd = @dash_timer > 0 ? @base_spd * 1.85 : @base_spd

    @scroll_x += cur_spd
    @dist = (@scroll_x / 16.0).to_i
    $flip_best_dist = @dist if @dist > $flip_best_dist

    # 入力バッファ
    if btnp(4) || btnp(2) || btnp(3) || btnp(:mouse_l)
      @flip_buf = 6
    elsif @flip_buf > 0
      @flip_buf -= 1
    end

    @dash_cd -= 1 if @dash_cd > 0
    if @dash_timer > 0
      @dash_timer -= 1
    elsif @dash_cd <= 0 && (btnp(5) || btnp(:mouse_r))
      @dash_timer = 14
      @dash_cd = 75
      @vy = 0.0
      @fx.burst(PLAYER_X, @py, 12, 11, 2.8, 14)
      @fx.ring(PLAYER_X, @py, 18.0, 11, 2.5)
      @fx.shake(2.0, 6)
    end

    @coyote = @grounded ? 5 : (@coyote > 0 ? @coyote - 1 : 0)

    if @flip_buf > 0 && (@grounded || @coyote > 0)
      @grav_dir = -@grav_dir
      @grounded = false
      @coyote = 0
      @flip_buf = 0
      @vy = @grav_dir * 2.2
      @fx.burst(PLAYER_X, @py, 8, 12, 2.2, 14)
      @fx.ring(PLAYER_X, @py, 14.0, 12, 2.0)
    end

    # 物理更新
    if @dash_timer <= 0
      @vy += @grav_dir * 0.42
      @vy = clamp_val(@vy, -7.2, 7.2)
      @py += @vy
    end

    if @py >= FLOOR_Y - 8.0
      if !@grounded && @grav_dir > 0
        @fx.burst(PLAYER_X, FLOOR_Y, 5, 12, 1.5, 10)
      end
      @py = FLOOR_Y - 8.0
      @vy = 0.0
      @grounded = true if @grav_dir > 0
    elsif @py <= CEIL_Y + 8.0
      if !@grounded && @grav_dir < 0
        @fx.burst(PLAYER_X, CEIL_Y, 5, 12, 1.5, 10)
      end
      @py = CEIL_Y + 8.0
      @vy = 0.0
      @grounded = true if @grav_dir < 0
    else
      @grounded = false
    end

    # 残像
    if @t % 2 == 0
      col = @dash_timer > 0 ? 11 : 12
      @fx.trail(PLAYER_X, @py, col, @grav_dir < 0)
    end

    # 障害物・オーブ移動 & スポーン
    @next_spawn_x -= cur_spd
    spawn_pattern while @next_spawn_x < 320.0

    @obstacles.each do |ob|
      ob[:x] -= cur_spd
      if ob[:kind] == :drone
        ob[:y] = 128.0 + sin(@t * 0.08 + ob[:phase]) * 38.0
      end

      # 当たり判定
      px1 = PLAYER_X - 5.0
      py1 = @py - 5.0
      px2 = PLAYER_X + 5.0
      py2 = @py + 5.0
      if px2 > ob[:x] + 2.0 && px1 < ob[:x] + ob[:w] - 2.0 &&
         py2 > ob[:y] + 2.0 && py1 < ob[:y] + ob[:h] - 2.0
        if @dash_timer > 0 && ob[:kind] == :drone
          ob[:x] = -999.0
          @score += 200
          $flip_best_score = @score if @score > $flip_best_score
          @fx.burst(PLAYER_X + 8.0, @py, 14, 10, 3.0, 18)
          @fx.popup(PLAYER_X, @py - 12.0, "SMASH +200!", 10)
          @fx.stop(3)
          @fx.shake(2.8, 8)
        elsif @dash_timer <= 0
          @dead = true
          @dead_timer = 0
          @fx.burst(PLAYER_X, @py, 24, 8, 3.5, 26)
          @fx.ring(PLAYER_X, @py, 30.0, 8, 2.8)
          @fx.shake(4.5, 14)
          @fx.flash(5, 8)
        end
      end
    end
    @obstacles.reject! { |ob| ob[:x] < -60.0 }

    @orbs.each do |o|
      next if o[:got]
      o[:x] -= cur_spd
      dx = o[:x] - PLAYER_X
      dy = o[:y] - @py
      if dx * dx + dy * dy < 14.0 * 14.0
        o[:got] = true
        @combo += 1
        pts = 20 + @combo * 5
        @score += pts
        $flip_best_score = @score if @score > $flip_best_score
        @fx.burst(o[:x], o[:y], 8, 10, 2.2, 14)
        @fx.popup(o[:x], o[:y] - 6.0, "+#{pts}", 10)
      end
    end
    @orbs.reject! { |o| o[:got] || o[:x] < -20.0 }

    if @t % 10 == 0
      @score += 5
      $flip_best_score = @score if @score > $flip_best_score
    end

    @fx.update(cur_spd)
  end

  def clamp_val(v, lo, hi)
    return lo if v < lo
    return hi if v > hi
    v
  end

  def draw
    cls(0)
    shk = @fx.shake_offset
    speed_lvl = 1 + (@dist / 120).to_i
    draw_corridor(@scroll_x, speed_lvl, shk[0], shk[1])

    camera(shk[0].to_i, shk[1].to_i)

    # オーブ
    @orbs.each do |o|
      next if o[:got]
      spr(:orb, o[:x].to_i - 4, o[:y].to_i - 4)
    end

    # 障害物
    @obstacles.each do |ob|
      ox = ob[:x].to_i
      oy = ob[:y].to_i
      ow = ob[:w].to_i
      oh = ob[:h].to_i
      if ob[:kind] == :drone
        spr(:drone, ox - 1, oy - 1)
      else
        rectfill(ox, oy, ow, oh, 8)
        rect(ox, oy, ow, oh, 7)
        line(ox + 2, oy + 2, ox + ow - 3, oy + oh - 3, 10)
      end
    end

    @fx.draw

    unless @dead
      pal_swap = @dash_timer > 0 ? 11 : nil
      spr_ext(:runner, PLAYER_X.to_i, @py.to_i, 0.0, 1.0, 1.0, false, @grav_dir < 0, pal_swap)
    end

    camera()
    clip()

    if @fx.flash_timer > 0
      rect(0, 0, 256, 256, @fx.flash_col)
      rect(1, 1, 254, 254, @fx.flash_col)
    end

    # HUD
    print_text("DIST:#{@dist}m", 8, 8, 10)
    print_text("SCR:#{@score}", 96, 8, 7)
    print_text("BEST:#{$flip_best_dist}m", 180, 8, 12)

    # ダッシュゲージ
    print_text("DASH", 8, 232, 11)
    rectfill(38, 233, 64, 6, 0)
    rect(38, 233, 64, 6, 5)
    fill = @dash_cd <= 0 ? 60 : ((75 - @dash_cd) * 60 / 75).to_i
    rectfill(40, 235, fill, 2, @dash_cd <= 0 ? 11 : 12)

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("CRASHED IN CORRIDOR!", 68, 96, 8)
      print_text("DIST  : #{@dist}m", 72, 112, 10)
      print_text("SCORE : #{@score}", 72, 124, 7)
      print_text("BEST  : #{$flip_best_dist}m", 72, 136, 12)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 152, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #080814
1: #1D2B53
5: #5F574F
7: #FFF1E8
8: #FF004D
A: #FFEC27
B: #00E436
C: #29ADFF
E: #FF77A8

@PALETTE 11
0: #000000
1: #004466
7: #8CF4FF
8: #29ADFF
A: #8CF4FF
C: #29ADFF
E: #29ADFF

@SPRITE :runner 16x16 pal:1
................
.....000000.....
....0CCCCCC0....
...0CC7777CC0...
...0C70CC07C0...
....00CCCC00....
...0888888880...
..08811AA110....
....01111110....
...0011CC1100...
....01100110....
...0110..0110...
..0CC0....0CC0..
................
................
................

@SPRITE :drone 16x16 pal:1
................
......0000......
....00888800....
...0887777880...
..088708807880..
..088777777880..
...0888888880...
....00111100....
...0AA0..0AA0...
..0AA0....0AA0..
................
................
................
................
................
................

@SPRITE :orb 8x8 pal:1
...00...
..0AA0..
.0A7AA0.
0A7AAAA0
0AAAAAA0
.0AAAA0.
..0AA0..
...00...
