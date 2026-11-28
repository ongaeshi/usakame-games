# ==============================================================================
# 14. ALCHEMY MERGE
# ------------------------------------------------------------------------------
# フラスコ内で魔法玉が転がり合体進化するスイカ風マージパズル
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ← / → / マウス移動     : 投下位置の移動
#   Z / 左クリック : 魔法玉を投下 (同種が触れると上位へ合体!)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "14. ALCHEMY MERGE"
)

FLASK_L = 56.0
FLASK_R = 200.0
FLASK_T = 58.0
FLASK_B = 238.0
DROP_Y  = 40.0
SUBSTEPS = 4

ORB_TIERS = [
  { r: 6.0,  col: 12, rim: 7,  pts: 10 },
  { r: 8.0,  col: 11, rim: 7,  pts: 20 },
  { r: 10.0, col: 10, rim: 7,  pts: 40 },
  { r: 12.0, col: 9,  rim: 10, pts: 80 },
  { r: 14.0, col: 8,  rim: 14, pts: 160 },
  { r: 17.0, col: 14, rim: 7,  pts: 320 },
  { r: 20.0, col: 2,  rim: 14, pts: 640 },
  { r: 23.0, col: 1,  rim: 12, pts: 1280 },
  { r: 26.0, col: 10, rim: 7,  pts: 2560 }
]

$alchemy_best ||= 0

def clamp_v(v, lo, hi)
  return lo if v < lo
  return hi if v > hi
  v
end

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
    bg(:cave, dim: 0.45, tint: [170, 140, 235])

    # デモ玉
    i = 0
    while i < 5
      tr = ORB_TIERS[i]
      ox = 64 + i * 32
      oy = 178 + (sin(@t * 0.08 + i) * 4.0).to_i
      circfill(ox, oy, tr[:r].to_i, tr[:col])
      circ(ox, oy, tr[:r].to_i, tr[:rim])
      i += 1
    end

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 14)
    print_text("ALCHEMY MERGE", 89, 32, 10)
    print_text("DROP & EVOLVE MAGICAL ORBS!", 47, 46, 12)

    rectfill(24, 78, 208, 56, 0)
    rect(24, 78, 208, 56, 5)
    print_text("ARROWS / MOUSE : AIM DROPPER", 40, 88, 7)
    print_text("Z / CLICK      : DROP ORB", 40, 101, 10)
    if $alchemy_best > 0
      print_text("HIGH SCORE: #{$alchemy_best}", 74, 117, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO BREW", 56, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @score = 0
    @drop_x = 128.0
    @prev_mx = mouse_x
    @cur_tier = rand(4)
    @next_tier = rand(4)
    @drop_cd = 0

    @orbs = []
    @particles = []
    @rings = []
    @popups = []
    @overflow_t = 0
    @shake_t = 0
    @dead = false
    @dead_timer = 0
  end

  def spawn_burst(x, y, col)
    i = 0
    while i < 10
      ang = rand() * Math::PI * 2.0
      spd = 1.0 + rand() * 2.0
      @particles << { x: x, y: y, vx: cos(ang) * spd, vy: sin(ang) * spd, col: col, life: 16 }
      i += 1
    end
    @rings << { x: x, y: y, r: 4.0, max_r: 22.0, col: 7 }
  end

  def update
    @t += 1
    @shake_t -= 1 if @shake_t > 0

    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }
    @rings.each { |r| r[:r] += 2.2 }
    @rings.reject! { |r| r[:r] >= r[:max_r] }
    @popups.each do |pp|
      pp[:y] -= 0.6
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }

    if @dead
      @dead_timer += 1
      if @dead_timer > 30 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    @drop_cd -= 1 if @drop_cd > 0
    cur_r = ORB_TIERS[@cur_tier][:r]

    @drop_x -= 2.4 if btn(:left)
    @drop_x += 2.4 if btn(:right)
    mx = mouse_x
    if mx != @prev_mx
      @drop_x = mx.to_f
      @prev_mx = mx
    end
    @drop_x = clamp_v(@drop_x, FLASK_L + cur_r + 2.0, FLASK_R - cur_r - 2.0)

    if (btnp(1) || btnp(:down) || btnp(:mouse_l)) && @drop_cd <= 0
      @drop_cd = 18
      @orbs << {
        x: @drop_x, y: DROP_Y + cur_r,
        vx: (rand() - 0.5) * 0.2, vy: 0.5,
        tier: @cur_tier, age: 0, alive: true
      }
      @cur_tier = @next_tier
      @next_tier = rand(4)
    end

    # サブステップ物理
    grav = 0.22 / SUBSTEPS
    s = 0
    while s < SUBSTEPS
      @orbs.each do |o|
        next unless o[:alive]
        o[:vy] += grav
        o[:x] += o[:vx] / SUBSTEPS
        o[:y] += o[:vy] / SUBSTEPS
        o[:vx] *= 0.994
        o[:vy] *= 0.994

        r = ORB_TIERS[o[:tier]][:r]
        if o[:x] - r < FLASK_L
          o[:x] = FLASK_L + r; o[:vx] = o[:vx].abs * 0.45
        elsif o[:x] + r > FLASK_R
          o[:x] = FLASK_R - r; o[:vx] = -o[:vx].abs * 0.45
        end
        if o[:y] + r > FLASK_B
          o[:y] = FLASK_B - r
          o[:vy] = -o[:vy].abs * 0.35
          o[:vx] *= 0.92
        end
      end

      # 円同士衝突 & 合体
      n = @orbs.size
      i = 0
      while i < n
        a = @orbs[i]
        if !a[:alive]
          i += 1
          next
        end
        j = i + 1
        while j < n
          b = @orbs[j]
          if !b[:alive]
            j += 1
            next
          end
          dx = b[:x] - a[:x]
          dy = b[:y] - a[:y]
          ra = ORB_TIERS[a[:tier]][:r]
          rb = ORB_TIERS[b[:tier]][:r]
          min_d = ra + rb
          d2 = dx * dx + dy * dy
          if d2 < min_d * min_d
            if a[:tier] == b[:tier] && a[:tier] < ORB_TIERS.size - 1
              # 合体!
              a[:alive] = false
              b[:alive] = false
              nt = a[:tier] + 1
              mx_p = (a[:x] + b[:x]) * 0.5
              my_p = (a[:y] + b[:y]) * 0.5
              @orbs << {
                x: mx_p, y: my_p, vx: 0.0, vy: -1.0,
                tier: nt, age: 0, alive: true
              }
              pts = ORB_TIERS[nt][:pts]
              @score += pts
              $alchemy_best = @score if @score > $alchemy_best
              spawn_burst(mx_p, my_p, ORB_TIERS[nt][:col])
              @popups << { x: mx_p.to_i, y: my_p.to_i - 8, text: "+#{pts}", col: 10, life: 26 }
              @shake_t = 5
            elsif d2 > 0.0001
              d = sqrt(d2)
              nx = dx / d
              ny = dy / d
              ov = (min_d - d) * 0.5
              a[:x] -= nx * ov
              a[:y] -= ny * ov
              b[:x] += nx * ov
              b[:y] += ny * ov

              rvx = b[:vx] - a[:vx]
              rvy = b[:vy] - a[:vy]
              vn = rvx * nx + rvy * ny
              if vn < 0.0
                imp = -1.2 * vn * 0.5
                a[:vx] -= imp * nx
                a[:vy] -= imp * ny
                b[:vx] += imp * nx
                b[:vy] += imp * ny
              end
            end
          end
          j += 1
        end
        i += 1
      end
      @orbs.reject! { |o| !o[:alive] }
      s += 1
    end

    # オーバーフロー判定
    over = false
    @orbs.each do |o|
      o[:age] += 1
      r = ORB_TIERS[o[:tier]][:r]
      if o[:age] > 60 && o[:y] - r < FLASK_T
        over = true
      end
    end
    if over
      @overflow_t += 1
      if @overflow_t > 75
        @dead = true
        @dead_timer = 0
      end
    else
      @overflow_t = 0
    end
  end

  def draw
    cls(0)
    shk_x = @shake_t > 0 ? rand(-2..2) : 0
    shk_y = @shake_t > 0 ? rand(-2..2) : 0
    bg(:cave, dim: 0.48, tint: [165, 135, 225], scale: 1.04, scroll_x: shk_x * 0.3, y: shk_y * 0.3)

    camera(shk_x, shk_y)

    # フラスコ本体
    rectfill(FLASK_L.to_i, FLASK_T.to_i, (FLASK_R - FLASK_L).to_i, (FLASK_B - FLASK_T).to_i, 0)
    line(FLASK_L.to_i, FLASK_T.to_i, FLASK_L.to_i, FLASK_B.to_i, 7)
    line(FLASK_R.to_i, FLASK_T.to_i, FLASK_R.to_i, FLASK_B.to_i, 7)
    line(FLASK_L.to_i, FLASK_B.to_i, FLASK_R.to_i, FLASK_B.to_i, 7)
    line(FLASK_L.to_i + 2, FLASK_T.to_i, FLASK_R.to_i - 2, FLASK_T.to_i, @overflow_t > 0 ? 8 : 5)

    # 投下ガイド & 現在の玉
    unless @dead
      tr = ORB_TIERS[@cur_tier]
      line(@drop_x.to_i, DROP_Y.to_i + tr[:r].to_i, @drop_x.to_i, FLASK_B.to_i, 1)
      circfill(@drop_x.to_i, DROP_Y.to_i, tr[:r].to_i, tr[:col])
      circ(@drop_x.to_i, DROP_Y.to_i, tr[:r].to_i, tr[:rim])
    end

    # フラスコ内の玉
    @orbs.each do |o|
      tr = ORB_TIERS[o[:tier]]
      ox = o[:x].to_i
      oy = o[:y].to_i
      r = tr[:r].to_i
      circfill(ox, oy, r, tr[:col])
      circ(ox, oy, r, tr[:rim])
      pset(ox - r / 3, oy - r / 3, 7)
      print_text("#{o[:tier] + 1}", ox - 2, oy - 3, 7) if r >= 8
    end

    @rings.each { |r| circ(r[:x].to_i, r[:y].to_i, r[:r].to_i, r[:col]) }
    @particles.each { |p| rectfill(p[:x].to_i, p[:y].to_i, 2, 2, p[:col]) }
    @popups.each { |pp| print_text(pp[:text], pp[:x] - pp[:text].length * 3, pp[:y], pp[:col]) }

    camera()
    clip()

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("SCR:#{@score}", 6, 6, 7)
    print_text("BEST:#{$alchemy_best}", 96, 6, 10)
    print_text("NEXT:", 194, 6, 12)
    ntr = ORB_TIERS[@next_tier]
    circfill(236, 10, ntr[:r].to_i, ntr[:col])
    circ(236, 10, ntr[:r].to_i, ntr[:rim])

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("FLASK OVERFLOWED!", 76, 96, 8)
      print_text("SCORE : #{@score}", 74, 114, 7)
      print_text("BEST  : #{$alchemy_best}", 74, 128, 10)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 148, 10)
      end
    end
  end
end

run TitleScene.new
