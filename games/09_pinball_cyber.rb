# ==============================================================================
# 09. PINBALL CYBER
# ------------------------------------------------------------------------------
# マルチボール＆ネオンバンパー乱舞の1画面サイバーピンボール
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ← / A / Z          : 左フリッパー
#   → / D / X          : 右フリッパー
#   Space / 左クリック : ボール発射 (両フリッパー同時操作可)
#   ↑ / W              : テーブル揺らし (ナッジ)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "09. PINBALL CYBER"
)

TBL_L = 24.0
TBL_R = 232.0
TBL_T = 24.0
TBL_B = 248.0
GRAVITY = 0.085
SUBSTEPS = 4

$pinball_best ||= 0

def clamp_v(v, lo, hi)
  return lo if v < lo
  return hi if v > hi
  v
end

class EffectSystem
  attr_accessor :shake_timer, :shake_power, :flash_timer

  def initialize
    @particles = []
    @rings = []
    @popups = []
    @shake_timer = 0
    @shake_power = 0.0
    @flash_timer = 0
  end

  def shake(power, frames)
    @shake_power = power.to_f if power > @shake_power || @shake_timer <= 0
    @shake_timer = frames if frames > @shake_timer
  end

  def flash(frames)
    @flash_timer = frames if frames > @flash_timer
  end

  def burst(x, y, count, col, spd = 2.4, life = 16)
    i = 0
    while i < count
      ang = rand() * Math::PI * 2.0
      v = (0.3 + rand() * 0.7) * spd
      @particles << {
        x: x.to_f, y: y.to_f,
        vx: cos(ang) * v, vy: sin(ang) * v,
        life: life + rand(6), col: col, size: rand(2) + 1
      }
      i += 1
    end
  end

  def ring(x, y, max_r, col, spd = 2.6)
    @rings << { x: x.to_f, y: y.to_f, r: 4.0, max_r: max_r.to_f, col: col, spd: spd }
  end

  def popup(x, y, text, col = 7)
    @popups << { x: x.to_f, y: y.to_f, vy: -0.65, life: 26, text: text, col: col }
  end

  def update
    @shake_timer -= 1 if @shake_timer > 0
    @flash_timer -= 1 if @flash_timer > 0
    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }
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
    @rings.each { |r| circ(r[:x].to_i, r[:y].to_i, r[:r].to_i, r[:col]) }
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
    bg(:cyber, dim: 0.4, scroll_y: -@t * 0.4, mirror_y: true)

    circ(92, 168, 12, 12)
    circ(164, 168, 12, 14)
    circ(128, 138, 14, 10)

    rectfill(26, 26, 204, 40, 0)
    rect(26, 26, 204, 40, 12)
    print_text("PINBALL CYBER", 89, 34, 10)
    print_text("NEON BUMPERS & MULTIBALL!", 53, 48, 12)

    rectfill(24, 78, 208, 56, 0)
    rect(24, 78, 208, 56, 5)
    print_text("LEFT / A / Z  : LEFT FLIPPER", 40, 88, 7)
    print_text("RIGHT / D / X : RIGHT FLIPPER", 40, 101, 7)
    print_text("SPACE / CLICK : LAUNCH / BOTH", 40, 114, 10)

    if $pinball_best > 0
      print_text("HIGH SCORE: #{$pinball_best}", 74, 190, 11)
    end
    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO PLAY", 56, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @fx = EffectSystem.new
    @score = 0
    @balls_left = 3
    @mult = 1
    @nudge_cd = 0
    @dead = false
    @dead_timer = 0

    @bumpers = [
      { x: 90.0, y: 92.0, r: 12.0, col: 12, hit: 0, pts: 100 },
      { x: 166.0, y: 92.0, r: 12.0, col: 14, hit: 0, pts: 100 },
      { x: 128.0, y: 126.0, r: 14.0, col: 10, hit: 0, pts: 200 },
      { x: 74.0, y: 148.0, r: 9.0, col: 11, hit: 0, pts: 150 },
      { x: 182.0, y: 148.0, r: 9.0, col: 11, hit: 0, pts: 150 }
    ]

    @targets = [
      { x: 84.0, y: 46.0, lit: false },
      { x: 128.0, y: 40.0, lit: false },
      { x: 172.0, y: 46.0, lit: false }
    ]

    @l_ang = 0.45
    @r_ang = Math::PI - 0.45
    @l_prev = @l_ang
    @r_prev = @r_ang

    @balls = []
    spawn_ball
  end

  def spawn_ball
    @balls << {
      x: 128.0 + (rand() - 0.5) * 24.0, y: 54.0,
      vx: (rand() - 0.5) * 1.8, vy: -1.5,
      r: 4.5, active: true
    }
  end

  def collide_segment(b, x1, y1, x2, y2, bounce_mul, extra_vy = 0.0)
    vx = x2 - x1
    vy = y2 - y1
    wx = b[:x] - x1
    wy = b[:y] - y1
    len2 = vx * vx + vy * vy
    t = len2 > 0.0001 ? clamp_v((wx * vx + wy * vy) / len2, 0.0, 1.0) : 0.0
    cx = x1 + vx * t
    cy = y1 + vy * t
    dx = b[:x] - cx
    dy = b[:y] - cy
    d2 = dx * dx + dy * dy
    min_d = b[:r] + 2.0
    if d2 < min_d * min_d && d2 > 0.0001
      d = sqrt(d2)
      nx = dx / d
      ny = dy / d
      b[:x] = cx + nx * min_d
      b[:y] = cy + ny * min_d
      dot = b[:vx] * nx + b[:vy] * ny
      if dot < 0.0
        b[:vx] -= (1.0 + bounce_mul) * dot * nx
        b[:vy] -= (1.0 + bounce_mul) * dot * ny
        b[:vy] += extra_vy
        return true
      end
    end
    false
  end

  def update
    @t += 1
    if @dead
      @dead_timer += 1
      @fx.update
      if @dead_timer > 30 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    @nudge_cd -= 1 if @nudge_cd > 0
    if btnp(2) && @nudge_cd <= 0
      @nudge_cd = 35
      @fx.shake(2.5, 6)
      @balls.each do |b|
        b[:vy] -= 1.2
        b[:vx] += (rand() - 0.5) * 1.4
      end
    end

    # フリッパー操作
    l_hold = btn(0) || btn(4) || btn(:mouse_l)
    r_hold = btn(1) || btn(5) || btn(4) || btn(:mouse_l)
    @l_prev = @l_ang
    @r_prev = @r_ang
    target_l = l_hold ? -0.45 : 0.45
    target_r = r_hold ? (Math::PI + 0.45) : (Math::PI - 0.45)
    @l_ang += (target_l - @l_ang) * 0.45
    @r_ang += (target_r - @r_ang) * 0.45
    l_kicking = (@l_ang - @l_prev) < -0.05
    r_kicking = (@r_ang - @r_prev) > 0.05

    @bumpers.each { |bp| bp[:hit] -= 1 if bp[:hit] > 0 }

    # フリッパー端点
    fl_x1 = 76.0; fl_y1 = 222.0
    fl_x2 = fl_x1 + cos(@l_ang) * 34.0
    fl_y2 = fl_y1 + sin(@l_ang) * 34.0

    fr_x1 = 180.0; fr_y1 = 222.0
    fr_x2 = fr_x1 + cos(@r_ang) * 34.0
    fr_y2 = fr_y1 + sin(@r_ang) * 34.0

    # サブステップ物理
    step_g = GRAVITY / SUBSTEPS
    s = 0
    while s < SUBSTEPS
      @balls.each do |b|
        next unless b[:active]
        b[:vy] += step_g
        b[:x] += b[:vx] / SUBSTEPS
        b[:y] += b[:vy] / SUBSTEPS

        # 速度上限
        spd = sqrt(b[:vx] * b[:vx] + b[:vy] * b[:vy])
        if spd > 6.5
          b[:vx] = b[:vx] / spd * 6.5
          b[:vy] = b[:vy] / spd * 6.5
        end

        # 外壁
        if b[:x] - b[:r] < TBL_L
          b[:x] = TBL_L + b[:r]; b[:vx] = b[:vx].abs * 0.85
        elsif b[:x] + b[:r] > TBL_R
          b[:x] = TBL_R - b[:r]; b[:vx] = -b[:vx].abs * 0.85
        end
        if b[:y] - b[:r] < TBL_T
          b[:y] = TBL_T + b[:r]; b[:vy] = b[:vy].abs * 0.85
        end

        # 斜めガイドウォール
        collide_segment(b, TBL_L, 196.0, fl_x1, fl_y1, 0.85)
        collide_segment(b, TBL_R, 196.0, fr_x1, fr_y1, 0.85)
        # 上部コーナーアーチ
        collide_segment(b, TBL_L, 52.0, 52.0, TBL_T, 0.88)
        collide_segment(b, TBL_R, 52.0, 204.0, TBL_T, 0.88)

        # フリッパー衝突
        if collide_segment(b, fl_x1, fl_y1, fl_x2, fl_y2, l_kicking ? 1.35 : 0.75, l_kicking ? -2.8 : 0.0)
          @fx.burst(b[:x], b[:y], 4, 12, 1.8, 10) if l_kicking
        end
        if collide_segment(b, fr_x1, fr_y1, fr_x2, fr_y2, r_kicking ? 1.35 : 0.75, r_kicking ? -2.8 : 0.0)
          @fx.burst(b[:x], b[:y], 4, 12, 1.8, 10) if r_kicking
        end

        # バンパー衝突
        @bumpers.each do |bp|
          dx = b[:x] - bp[:x]
          dy = b[:y] - bp[:y]
          min_d = b[:r] + bp[:r]
          d2 = dx * dx + dy * dy
          if d2 < min_d * min_d && d2 > 0.0001
            d = sqrt(d2)
            nx = dx / d
            ny = dy / d
            b[:x] = bp[:x] + nx * min_d
            b[:y] = bp[:y] + ny * min_d
            b[:vx] = nx * 4.2
            b[:vy] = ny * 4.2
            bp[:hit] = 8
            pts = bp[:pts] * @mult
            @score += pts
            $pinball_best = @score if @score > $pinball_best
            @fx.burst(bp[:x] + nx * bp[:r], bp[:y] + ny * bp[:r], 6, bp[:col], 2.2, 12)
            @fx.ring(bp[:x], bp[:y], bp[:r] + 10.0, bp[:col], 2.2)
            @fx.popup(bp[:x], bp[:y] - 8.0, "+#{pts}", bp[:col])
            @fx.shake(1.8, 4)
          end
        end

        # ドロップターゲット
        @targets.each do |tg|
          dx = b[:x] - tg[:x]
          dy = b[:y] - tg[:y]
          if dx * dx + dy * dy < 10.0 * 10.0 && !tg[:lit]
            tg[:lit] = true
            @score += 300 * @mult
            $pinball_best = @score if @score > $pinball_best
            @fx.burst(tg[:x], tg[:y], 10, 10, 2.5, 16)
            if @targets.all? { |t2| t2[:lit] }
              @targets.each { |t2| t2[:lit] = false }
              @mult += 1 if @mult < 5
              @fx.flash(5)
              @fx.shake(3.5, 10)
              @fx.popup(128.0, 70.0, "MULTIBALL x#{@mult}!", 10)
              spawn_ball if @balls.size < 3
              spawn_ball if @balls.size < 3
            end
          end
        end

        if b[:y] > TBL_B + 10.0
          b[:active] = false
        end
      end
      s += 1
    end

    @balls.reject! { |b| !b[:active] }
    if @balls.empty?
      @balls_left -= 1
      @mult = 1
      if @balls_left <= 0
        @dead = true
        @dead_timer = 0
      else
        spawn_ball
      end
    end

    @fx.update
  end

  def draw
    cls(0)
    shk = @fx.shake_offset
    bg(:cyber, dim: 0.45, scale: 1.04, scroll_x: shk[0] * 0.3, scroll_y: -@t * 0.3 + shk[1] * 0.3, mirror_y: true)

    camera(shk[0].to_i, shk[1].to_i)

    # テーブル枠
    rect(TBL_L.to_i, TBL_T.to_i, (TBL_R - TBL_L).to_i, (TBL_B - TBL_T).to_i, 12)
    line(TBL_L.to_i, 52, 52, TBL_T.to_i, 12)
    line(TBL_R.to_i, 52, 204, TBL_T.to_i, 12)
    line(TBL_L.to_i, 196, 76, 222, 12)
    line(TBL_R.to_i, 196, 180, 222, 12)

    # ターゲット
    @targets.each do |tg|
      col = tg[:lit] ? 10 : 5
      circfill(tg[:x].to_i, tg[:y].to_i, 5, col)
      circ(tg[:x].to_i, tg[:y].to_i, 6, 7)
    end

    # バンパー
    @bumpers.each do |bp|
      r = bp[:r].to_i + (bp[:hit] > 0 ? 2 : 0)
      circfill(bp[:x].to_i, bp[:y].to_i, r, bp[:hit] > 0 ? 7 : 1)
      circ(bp[:x].to_i, bp[:y].to_i, r, bp[:col])
      circ(bp[:x].to_i, bp[:y].to_i, r - 3, bp[:col])
    end

    # フリッパー
    fl_x2 = (76.0 + cos(@l_ang) * 34.0).to_i
    fl_y2 = (222.0 + sin(@l_ang) * 34.0).to_i
    fr_x2 = (180.0 + cos(@r_ang) * 34.0).to_i
    fr_y2 = (222.0 + sin(@r_ang) * 34.0).to_i
    line(76, 222, fl_x2, fl_y2, 10)
    line(76, 223, fl_x2, fl_y2 + 1, 9)
    line(180, 222, fr_x2, fr_y2, 10)
    line(180, 223, fr_x2, fr_y2 + 1, 9)

    # ボール
    @balls.each do |b|
      circfill(b[:x].to_i, b[:y].to_i, 4, 7)
      pset(b[:x].to_i - 1, b[:y].to_i - 1, 12)
    end

    @fx.draw

    camera()
    clip()

    if @fx.flash_timer > 0
      rect(0, 0, 256, 256, 10)
      rect(1, 1, 254, 254, 10)
    end

    # HUD
    rectfill(0, 0, 256, 18, 0)
    line(0, 18, 256, 18, 5)
    print_text("SCR:#{@score}", 6, 5, 7)
    print_text("x#{@mult}", 100, 5, 10)
    print_text("BEST:#{$pinball_best}", 134, 5, 12)
    i = 0
    while i < @balls_left
      circfill(244 - i * 10, 9, 3, 7)
      i += 1
    end

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("GAME OVER", 101, 96, 8)
      print_text("SCORE : #{@score}", 74, 114, 7)
      print_text("BEST  : #{$pinball_best}", 74, 128, 12)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 148, 10)
      end
    end
  end
end

run TitleScene.new
