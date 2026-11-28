# ==============================================================================
# 01. GRAPPLE ASCENT
# ------------------------------------------------------------------------------
# 振り子フックショットで迫りくる溶岩から逃げ切る縦登りアクション
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   Z / 左クリック : フック発射（押している間ホールド・離すと射出）
#   ← / → (A / D)          : スイング加速 / 空中制御
#   ↑ / ↓ (W / S)          : ロープ巻き取り / 伸ばす
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "01. GRAPPLE ASCENT"
)

SCREEN_W = 256
SCREEN_H = 256
WALL_L = 14.0
WALL_R = 242.0
GRAVITY = 0.16
MAX_HOOK_DIST = 118.0

$best_alt ||= 0

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

# ------------------------------------------------------------------------------
# 汎用エフェクトシステム
# ------------------------------------------------------------------------------
class EffectSystem
  attr_accessor :shake_timer, :shake_power, :hitstop, :flash_timer

  def initialize
    @particles = []
    @rings = []
    @popups = []
    @trails = []
    @shake_timer = 0
    @shake_power = 0.0
    @hitstop = 0
    @flash_timer = 0
  end

  def shake(power, frames)
    @shake_power = power.to_f if power > @shake_power || @shake_timer <= 0
    @shake_timer = frames if frames > @shake_timer
  end

  def stop(frames)
    @hitstop = frames if frames > @hitstop
  end

  def flash(frames)
    @flash_timer = frames if frames > @flash_timer
  end

  def burst(x, y, count, col, spd = 2.5, life = 22)
    i = 0
    while i < count
      ang = rand() * Math::PI * 2.0
      v = (0.3 + rand() * 0.7) * spd
      @particles << {
        x: x.to_f, y: y.to_f,
        vx: cos(ang) * v, vy: sin(ang) * v,
        life: life + rand(10), max_life: life + 10,
        col: col, size: rand(2) + 1, grav: 0.05
      }
      i += 1
    end
  end

  def ember(x, y, col)
    @particles << {
      x: x.to_f, y: y.to_f,
      vx: (rand() - 0.5) * 0.6, vy: -0.6 - rand() * 1.1,
      life: 24 + rand(20), max_life: 44,
      col: col, size: 1 + rand(2), grav: -0.01
    }
  end

  def ring(x, y, max_r, col, spd = 2.2)
    @rings << { x: x.to_f, y: y.to_f, r: 2.0, max_r: max_r.to_f, col: col, spd: spd }
  end

  def popup(x, y, text, col = 7)
    @popups << { x: x.to_f, y: y.to_f, vy: -0.8, life: 34, text: text, col: col }
  end

  def trail(x, y, col, r = 4)
    @trails << { x: x.to_f, y: y.to_f, life: 10, max_life: 10, col: col, r: r }
  end

  def update
    @shake_timer -= 1 if @shake_timer > 0
    @flash_timer -= 1 if @flash_timer > 0

    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:vy] += p[:grav]
      p[:vx] *= 0.96
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }

    @rings.each do |r|
      r[:r] += r[:spd]
    end
    @rings.reject! { |r| r[:r] >= r[:max_r] }

    @popups.each do |pp|
      pp[:y] += pp[:vy]
      pp[:vy] *= 0.92
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }

    @trails.each { |tr| tr[:life] -= 1 }
    @trails.reject! { |tr| tr[:life] <= 0 }
  end

  def shake_offset
    return [0.0, 0.0] if @shake_timer <= 0
    sx = (rand() * 2.0 - 1.0) * @shake_power
    sy = (rand() * 2.0 - 1.0) * @shake_power
    [sx, sy]
  end

  def draw_world
    @trails.each do |tr|
      r = (tr[:r] * tr[:life].to_f / tr[:max_life]).to_i
      circfill(tr[:x].to_i, tr[:y].to_i, r, tr[:col]) if r >= 1
    end
    @rings.each do |r|
      circ(r[:x].to_i, r[:y].to_i, r[:r].to_i, r[:col])
    end
    @particles.each do |p|
      s = p[:size]
      if p[:life] < 6
        pset(p[:x].to_i, p[:y].to_i, p[:col])
      elsif s <= 1
        pset(p[:x].to_i, p[:y].to_i, p[:col])
      else
        rectfill(p[:x].to_i, p[:y].to_i, s, s, p[:col])
      end
    end
    @popups.each do |pp|
      print_text(pp[:text], pp[:x].to_i - pp[:text].length * 3, pp[:y].to_i, pp[:col])
    end
  end
end

# ------------------------------------------------------------------------------
# タイトルシーン
# ------------------------------------------------------------------------------
class TitleScene
  def initialize
    @t = 0
  end

  def update
    @t += 1
    if btnp(1) || btnp(:mouse_l)
      run GameScene.new
    end
  end

  def draw
    cls(0)
    bg(:cave, dim: 0.45, tint: [255, 165, 130], scroll_y: -@t * 0.4, mirror_y: true)

    # 溶岩演出
    rectfill(0, 224, 256, 32, 8)
    rectfill(0, 220, 256, 6, 9)
    x = 0
    while x < 256
      wy = 219 + (sin(x * 0.1 + @t * 0.12) * 2.5).to_i
      circfill(x, wy, 5, 10)
      x += 14
    end

    # デモ振り子アニメ
    ax = 128
    ay = 72
    ang = sin(@t * 0.06) * 0.9
    px = ax + sin(ang) * 44
    py = ay + cos(ang) * 44
    line(ax, ay, px.to_i, py.to_i, 6)
    spr(:anchor, ax - 8, ay - 8)
    spr_ext(:climber, px.to_i, py.to_i, -ang * 35.0, 1.0, 1.0, ang < 0, false)

    # タイトルロゴ
    rectfill(24, 20, 208, 36, 0)
    rect(24, 20, 208, 36, 9)
    print_text("GRAPPLE ASCENT", 86, 28, 10)
    print_text("SWING ABOVE THE RISING LAVA!", 44, 42, 7)

    # 操作説明ボックス
    rectfill(26, 132, 204, 62, 0)
    rect(26, 132, 204, 62, 5)
    print_text("HOLD Z / CLICK : GRAPPLE", 34, 142, 12)
    print_text("LEFT / RIGHT (A/D)     : SWING", 34, 156, 7)
    print_text("UP / DOWN (W/S)        : REEL ROPE", 34, 170, 7)
    if $best_alt > 0
      print_text("BEST ALTITUDE: #{$best_alt}m", 70, 182, 10)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO START", 53, 204, 10)
    end
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
    @py = 170.0
    @vx = 1.8
    @vy = -3.8
    @facing_left = false

    @cam_y = 0.0
    @lava_y = 260.0
    @lava_speed = 0.42
    @start_y = 170.0
    @max_alt = 0
    @score = 0
    @combo = 0

    @hooked = false
    @hook_x = 0.0
    @hook_y = 0.0
    @rope_len = 50.0
    @hook_anchor = nil
    @target_anchor = nil

    @anchors = []
    @gems = []
    @top_gen_y = 160.0
    generate_up_to(-400.0)

    @dead = false
    @dead_timer = 0
  end

  def generate_up_to(target_y)
    while @top_gen_y > target_y
      step_y = 34.0 + rand() * 20.0
      ny = @top_gen_y - step_y
      nx = 32.0 + rand() * 192.0
      # 直前アンカーから離れすぎないよう補正
      if !@anchors.empty?
        last = @anchors.last
        if (nx - last[:x]).abs > 96.0
          nx = clamp_v(last[:x] + (rand() < 0.5 ? -75.0 : 75.0), 28.0, 228.0)
        end
      end
      kind = rand(6) == 0 ? :boost : :normal
      @anchors << { x: nx, y: ny, kind: kind, pulse: rand(60), used: false }

      # ジェム配置
      if rand(10) < 7
        gx = clamp_v(nx + (rand() - 0.5) * 44.0, 26.0, 230.0)
        gy = ny + 14.0 + (rand() - 0.5) * 16.0
        @gems << { x: gx, y: gy, got: false, bob: rand(60) }
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

    @anchors.each do |a|
      d2 = dist_sq(@px, @py, a[:x], a[:y])
      next if d2 > MAX_HOOK_DIST * MAX_HOOK_DIST
      next if a[:y] > @py + 36.0

      # 上方にあるアンカーを優先
      sc = sqrt(d2) + (a[:y] > @py ? 45.0 : 0.0)
      if use_mouse
        sc += sqrt(dist_sq(mx, my, a[:x], a[:y])) * 0.9
      end
      if sc < best_score
        best_score = sc
        best = a
      end
    end
    best
  end

  def update
    @t += 1
    if @dead
      @dead_timer += 1
      @fx.update
      if @dead_timer > 30 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    if @fx.hitstop > 0
      @fx.hitstop -= 1
      @fx.update
      return
    end

    @target_anchor = find_best_anchor unless @hooked

    # フック発射 / 保持 / 解放
    holding = btn(1) || btn(:mouse_l)
    pressed = btnp(1) || btnp(:mouse_l)

    if pressed && !@hooked && @target_anchor
      @hooked = true
      @hook_anchor = @target_anchor
      @hook_x = @hook_anchor[:x]
      @hook_y = @hook_anchor[:y]
      dx = @px - @hook_x
      dy = @py - @hook_y
      @rope_len = clamp_v(sqrt(dx * dx + dy * dy), 22.0, MAX_HOOK_DIST)
      @fx.burst(@hook_x, @hook_y, 8, 12, 2.2, 14)
      @fx.ring(@hook_x, @hook_y, 14.0, 7, 1.8)

      if @hook_anchor[:kind] == :boost && !@hook_anchor[:used]
        @hook_anchor[:used] = true
        @vy = -5.6
        @vx *= 1.15
        @hooked = false
        @combo += 1
        @score += 50 * @combo
        @fx.burst(@hook_x, @hook_y, 16, 10, 3.2, 22)
        @fx.ring(@hook_x, @hook_y, 26.0, 10, 2.6)
        @fx.popup(@hook_x, @hook_y - 10.0, "BOOST x#{@combo}!", 10)
        @fx.shake(2.5, 8)
        @fx.stop(2)
      end
    elsif !holding && @hooked
      @hooked = false
      # 上向き解放時は少しブースト
      if @vy < -1.0
        @vy -= 0.75
        @combo += 1
        @score += 10 * @combo
        @fx.burst(@px, @py, 6, 7, 1.8, 12)
      end
    end

    # 重力 & 入力
    @vy += GRAVITY

    if @hooked
      # スイング加速
      if btn(:left)
        @vx -= 0.14
        @facing_left = true
      end
      if btn(:right)
        @vx += 0.14
        @facing_left = false
      end
      # ロープ伸縮
      @rope_len -= 1.6 if btn(:up)
      @rope_len += 1.6 if btn(:down)
      @rope_len = clamp_v(@rope_len, 18.0, MAX_HOOK_DIST)
    else
      if btn(:left)
        @vx -= 0.12
        @facing_left = true
      end
      if btn(:right)
        @vx += 0.12
        @facing_left = false
      end
      @vx *= 0.992
    end

    # 速度制限
    spd = sqrt(@vx * @vx + @vy * @vy)
    if spd > 7.5
      @vx = @vx / spd * 7.5
      @vy = @vy / spd * 7.5
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
        # 法線方向の速度成分を除去
        dot = @vx * nx + @vy * ny
        if dot > 0.0
          @vx -= dot * nx
          @vy -= dot * ny
        end
        @vx *= 0.996
        @vy *= 0.996
      end
    end

    # 左右壁バウンド
    if @px < WALL_L
      @px = WALL_L
      @vx = @vx.abs * 0.75
      @fx.burst(@px, @py, 5, 6, 1.5, 10)
    elsif @px > WALL_R
      @px = WALL_R
      @vx = -@vx.abs * 0.75
      @fx.burst(@px, @py, 5, 6, 1.5, 10)
    end

    # トレイル
    if spd > 2.8 && @t % 2 == 0
      @fx.trail(@px, @py, @hooked ? 12 : 9, 4)
    end

    # ジェム取得
    @gems.each do |g|
      next if g[:got]
      if dist_sq(@px, @py, g[:x], g[:y]) < 16.0 * 16.0
        g[:got] = true
        @combo += 1
        pts = 25 * @combo
        @score += pts
        @fx.burst(g[:x], g[:y], 10, 10, 2.4, 18)
        @fx.popup(g[:x], g[:y] - 6.0, "+#{pts}", 10)
      end
    end

    # 高度・カメラ更新
    alt = ((@start_y - @py) / 4.0).to_i
    if alt > @max_alt
      @max_alt = alt
      $best_alt = @max_alt if @max_alt > $best_alt
    end

    target_cam = @py - 148.0
    @cam_y = lerp_v(@cam_y, target_cam, 0.14) if target_cam < @cam_y

    # 溶岩上昇（距離が開きすぎたらゴムバンドで少し速く）
    @lava_speed = 0.42 + @max_alt * 0.0012
    @lava_speed = 1.35 if @lava_speed > 1.35
    gap = @lava_y - @cam_y
    if gap > 300.0
      @lava_y = @cam_y + 300.0
    else
      @lava_y -= @lava_speed
    end

    # 溶岩火花
    if @t % 3 == 0
      @fx.ember(16.0 + rand() * 224.0, @lava_y - 2.0, rand(2) == 0 ? 9 : 10)
    end

    # 画面下・溶岩判定
    if @py > @lava_y - 6.0
      @dead = true
      @hooked = false
      @fx.burst(@px, @py, 28, 8, 3.8, 30)
      @fx.burst(@px, @py, 16, 10, 2.5, 24)
      @fx.ring(@px, @py, 36.0, 9, 2.8)
      @fx.shake(5.0, 18)
      @fx.flash(6)
    end

    # 上方生成 & 古い要素掃除
    generate_up_to(@cam_y - 280.0)
    @anchors.reject! { |a| a[:y] > @lava_y + 80.0 }
    @gems.reject! { |g| g[:got] || g[:y] > @lava_y + 80.0 }

    @fx.update
  end

  def draw
    cls(0)
    shk = @fx.shake_offset
    bg(:cave, dim: 0.48, tint: [255, 160, 125], scale: 1.04,
       scroll_y: @cam_y * 0.25 + shk[1] * 0.3, scroll_x: shk[0] * 0.3, mirror_y: true)

    camera(shk[0].to_i, (@cam_y + shk[1]).to_i)

    # 左右の岩壁
    wy_start = ((@cam_y / 16.0).floor.to_i * 16) - 16
    wy_end = @cam_y + 272
    wy = wy_start
    while wy < wy_end
      rectfill(0, wy.to_i, 10, 16, 1)
      rectfill(8, wy.to_i, 2, 16, 5)
      rectfill(246, wy.to_i, 10, 16, 1)
      rectfill(246, wy.to_i, 2, 16, 5)
      wy += 16
    end

    # ターゲットレティクル
    if !@hooked && @target_anchor
      tx = @target_anchor[:x].to_i
      ty = @target_anchor[:y].to_i
      r = 10 + (sin(@t * 0.25) * 2.0).to_i
      circ(tx, ty, r, 11)
      line(@px.to_i, @py.to_i, tx, ty, 5) if @t % 2 == 0
    end

    # アンカー描画
    @anchors.each do |a|
      ax = a[:x].to_i
      ay = a[:y].to_i
      if a[:kind] == :boost && !a[:used]
        spr(:boost_anchor, ax - 8, ay - 8)
      else
        spr(:anchor, ax - 8, ay - 8)
      end
    end

    # ジェム描画
    @gems.each do |g|
      next if g[:got]
      gy = g[:y] + sin(@t * 0.1 + g[:bob]) * 2.5
      spr(:gem, g[:x].to_i - 4, gy.to_i - 4)
    end

    # ロープ描画
    if @hooked
      line(@px.to_i, @py.to_i, @hook_x.to_i, @hook_y.to_i, 7)
      circfill(@hook_x.to_i, @hook_y.to_i, 2, 10)
    end

    # エフェクト
    @fx.draw_world

    # プレイヤー描画
    unless @dead
      rot = @hooked ? (@vx * 6.0) : (@vx * 3.5)
      spr_ext(:climber, @px.to_i, @py.to_i, rot, 1.0, 1.0, @facing_left, false)
    end

    # 溶岩描画
    ly = @lava_y.to_i
    if ly < @cam_y + 264
      rectfill(0, ly + 4, 256, 300, 8)
      rectfill(0, ly, 256, 6, 9)
      lx = 0
      while lx < 256
        by = ly + (sin(lx * 0.14 + @t * 0.18) * 2.5).to_i
        circfill(lx, by, 4, 10)
        lx += 12
      end
    end

    # HUD
    camera()
    clip()
    if @fx.flash_timer > 0
      rect(0, 0, 256, 256, 7)
      rect(1, 1, 254, 254, 8)
    end

    rectfill(0, 0, 256, 18, 0)
    line(0, 18, 256, 18, 5)
    print_text("ALT:#{@max_alt}m", 6, 5, 10)
    print_text("SCR:#{@score}", 84, 5, 7)
    if @combo > 1
      print_text("x#{@combo}", 156, 5, 11)
    end
    print_text("BEST:#{$best_alt}m", 192, 5, 6)

    if @dead
      rectfill(34, 84, 188, 86, 0)
      rect(34, 84, 188, 86, 8)
      print_text("CONSUMED BY LAVA!", 76, 96, 8)
      print_text("ALTITUDE : #{@max_alt}m", 72, 114, 10)
      print_text("SCORE    : #{@score}", 72, 126, 7)
      print_text("BEST     : #{$best_alt}m", 72, 138, 11)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 154, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #0C0A14
1: #1D2B53
5: #5F574F
6: #C2C3C7
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
B: #00E436
C: #29ADFF
E: #FF77A8
F: #FFCCAA

@SPRITE :climber 16x16 pal:1
................
.....000000.....
....07777770....
...0770770770...
...0777777770...
....00FFFF00....
...0888888880...
..088111111080..
....01111110....
...0011AA1100...
..0F01111110F0..
.....0110110....
.....0110110....
....000..000....
................
................

@SPRITE :anchor 16x16 pal:1
................
.....000000.....
....06677660....
...06CCCCCC60...
..06CC777CCC60..
..06CC7C7CCC60..
..06CCCCCCCC60..
...06CCCCCC60...
....06666660....
.....005500.....
......0550......
......0660......
.......00.......
................
................
................

@SPRITE :boost_anchor 16x16 pal:1
................
.....000000.....
....099AA990....
...09AAAAAA90...
..09AA777AAA90..
..09AA7A7AAA90..
..09AAAAAAAA90..
...09AAAAAA90...
....09988990....
.....009900.....
......0AA0......
......0770......
.......00.......
................
................
................

@SPRITE :gem 8x8 pal:1
...00...
..0AA0..
.0A7AA0.
0A7AAA90
0AAAAA90
.0A9990.
..0990..
...00...
