# ==============================================================================
# 17. GOLF GALAXY
# ------------------------------------------------------------------------------
# 惑星の万有引力で弾道が曲がる宇宙物理パターゴルフ (全9ホール)
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   マウス移動 / ← → ↑ ↓ : 角度とパワー調整 (重力軌道予測線表示!)
#   Z / Space / 左クリック : ショット!
#   R / X                  : ボール位置リセット
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "17. GOLF GALAXY"
)

HOLES = [
  { par: 2, start: [40.0, 196.0], goal: [212.0, 64.0],
    planets: [{ x: 128.0, y: 128.0, r: 16.0, mass: 180.0, col: 12 }] },
  { par: 2, start: [36.0, 132.0], goal: [218.0, 132.0],
    planets: [{ x: 128.0, y: 92.0, r: 14.0, mass: 160.0, col: 14 },
              { x: 128.0, y: 172.0, r: 14.0, mass: 160.0, col: 11 }] },
  { par: 3, start: [44.0, 212.0], goal: [212.0, 56.0],
    planets: [{ x: 100.0, y: 136.0, r: 18.0, mass: 210.0, col: 9 },
              { x: 172.0, y: 112.0, r: 14.0, mass: 150.0, col: 12 }] },
  { par: 3, start: [128.0, 222.0], goal: [128.0, 48.0],
    planets: [{ x: 86.0, y: 136.0, r: 15.0, mass: 180.0, col: 14 },
              { x: 170.0, y: 136.0, r: 15.0, mass: 180.0, col: 12 }] },
  { par: 3, start: [36.0, 60.0], goal: [216.0, 206.0],
    planets: [{ x: 128.0, y: 132.0, r: 22.0, mass: 260.0, col: 10 },
              { x: 76.0, y: 174.0, r: 11.0, mass: 120.0, col: 11 }] },
  { par: 3, start: [40.0, 210.0], goal: [44.0, 58.0],
    planets: [{ x: 132.0, y: 134.0, r: 20.0, mass: 240.0, col: 12 },
              { x: 196.0, y: 134.0, r: 12.0, mass: 130.0, col: 8 }] },
  { par: 4, start: [36.0, 212.0], goal: [218.0, 54.0],
    planets: [{ x: 90.0, y: 160.0, r: 14.0, mass: 170.0, col: 11 },
              { x: 140.0, y: 120.0, r: 16.0, mass: 190.0, col: 14 },
              { x: 184.0, y: 86.0, r: 12.0, mass: 140.0, col: 12 }] },
  { par: 4, start: [216.0, 212.0], goal: [40.0, 56.0],
    planets: [{ x: 128.0, y: 132.0, r: 18.0, mass: 220.0, col: 9 },
              { x: 74.0, y: 92.0, r: 12.0, mass: 140.0, col: 12 },
              { x: 180.0, y: 172.0, r: 12.0, mass: 140.0, col: 14 }] },
  { par: 4, start: [38.0, 134.0], goal: [218.0, 134.0],
    planets: [{ x: 102.0, y: 96.0, r: 14.0, mass: 180.0, col: 12 },
              { x: 102.0, y: 172.0, r: 14.0, mass: 180.0, col: 14 },
              { x: 164.0, y: 134.0, r: 18.0, mass: 230.0, col: 10 }] }
]

$golf_best_diff ||= nil

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
    if btnp(4) || btnp(:mouse_l)
      run GameScene.new
    end
  end

  def draw
    cls(0)
    bg(:space, dim: 0.4, scroll_x: @t * 0.12, mirror_x: true)

    circfill(128, 174, 16, 12)
    circ(128, 174, 34, 1)
    bx = 128 + (cos(@t * 0.06) * 34.0).to_i
    by = 174 + (sin(@t * 0.06) * 34.0).to_i
    circfill(bx, by, 3, 7)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 12)
    print_text("GOLF GALAXY", 95, 32, 10)
    print_text("ORBITAL GRAVITY SPACE GOLF", 50, 46, 12)

    rectfill(24, 78, 208, 56, 0)
    rect(24, 78, 208, 56, 5)
    print_text("MOUSE / ARROWS : AIM & POWER", 40, 88, 7)
    print_text("Z / CLICK      : LAUNCH BALL", 40, 101, 10)
    if $golf_best_diff
      lbl = $golf_best_diff <= 0 ? "#{$golf_best_diff}" : "+#{$golf_best_diff}"
      print_text("BEST 9-HOLE: #{lbl} PAR", 64, 117, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO TEE OFF", 47, 224, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @hole_idx = 0
    @total_strokes = 0
    @total_par = 0
    @strokes = 0

    @aim_ang = -0.6
    @power = 3.2
    @prev_mx = mouse_x
    @prev_my = mouse_y

    @state = :aim
    @hole_msg = ""
    @msg_t = 0
    @trails = []
    @sparks = []
    @finished = false
    @fin_timer = 0

    load_hole(0)
  end

  def load_hole(idx)
    @hole_idx = idx
    h = HOLES[idx]
    @bx = h[:start][0]
    @by = h[:start][1]
    @vx = 0.0
    @vy = 0.0
    @strokes = 0
    @state = :aim
    @trails = []
    @aim_ang = atan2(h[:goal][1] - @by, h[:goal][0] - @bx)
    @power = 3.2
  end

  def step_ball_physics(x, y, vx, vy, planets)
    planets.each do |pl|
      dx = pl[:x] - x
      dy = pl[:y] - y
      d2 = dx * dx + dy * dy
      d = sqrt(d2)
      if d > 4.0
        f = pl[:mass] / (d2 + 80.0)
        vx += dx / d * f
        vy += dy / d * f
      end
    end
    x += vx
    y += vy
    [x, y, vx, vy]
  end

  def compute_preview
    h = HOLES[@hole_idx]
    pts = []
    px = @bx; py = @by
    vx = cos(@aim_ang) * @power
    vy = sin(@aim_ang) * @power
    i = 0
    while i < 42
      res = step_ball_physics(px, py, vx, vy, h[:planets])
      px = res[0]; py = res[1]; vx = res[2]; vy = res[3]
      pts << [px.to_i, py.to_i] if i % 3 == 0
      i += 1
    end
    pts
  end

  def update
    @t += 1
    @sparks.each do |s|
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }

    if @finished
      @fin_timer += 1
      if @fin_timer > 30 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    if @state == :cleared
      @msg_t -= 1
      if @msg_t <= 0
        if @hole_idx + 1 < HOLES.size
          load_hole(@hole_idx + 1)
        else
          @finished = true
          @fin_timer = 0
          diff = @total_strokes - @total_par
          if $golf_best_diff.nil? || diff < $golf_best_diff
            $golf_best_diff = diff
          end
        end
      end
      return
    end

    h = HOLES[@hole_idx]

    if @state == :aim
      @aim_ang -= 0.045 if btn(0)
      @aim_ang += 0.045 if btn(1)
      @power = clamp_v(@power + 0.08, 1.2, 5.2) if btn(2)
      @power = clamp_v(@power - 0.08, 1.2, 5.2) if btn(3)

      mx = mouse_x; my = mouse_y
      if mx != @prev_mx || my != @prev_my
        dx = mx.to_f - @bx
        dy = my.to_f - @by
        d = sqrt(dx * dx + dy * dy)
        if d > 4.0
          @aim_ang = atan2(dy, dx)
          @power = clamp_v(d * 0.045, 1.2, 5.2)
        end
        @prev_mx = mx; @prev_my = my
      end

      if btnp(4) || btnp(:mouse_l)
        @vx = cos(@aim_ang) * @power
        @vy = sin(@aim_ang) * @power
        @strokes += 1
        @state = :fly
        @fly_t = 0
      end
    elsif @state == :fly
      @fly_t += 1
      res = step_ball_physics(@bx, @by, @vx, @vy, h[:planets])
      @bx = res[0]; @by = res[1]; @vx = res[2]; @vy = res[3]
      @trails << [@bx.to_i, @by.to_i] if @t % 2 == 0
      @trails.shift if @trails.size > 36

      # 惑星衝突
      h[:planets].each do |pl|
        dx = @bx - pl[:x]
        dy = @by - pl[:y]
        d = sqrt(dx * dx + dy * dy)
        if d < pl[:r] + 3.0 && d > 0.01
          nx = dx / d; ny = dy / d
          @bx = pl[:x] + nx * (pl[:r] + 3.0)
          @by = pl[:y] + ny * (pl[:r] + 3.0)
          dot = @vx * nx + @vy * ny
          if dot < 0.0
            @vx -= 1.65 * dot * nx
            @vy -= 1.65 * dot * ny
          end
        end
      end

      # 画面端反射
      if @bx < 8.0
        @bx = 8.0; @vx = @vx.abs * 0.8
      elsif @bx > 248.0
        @bx = 248.0; @vx = -@vx.abs * 0.8
      end
      if @by < 26.0
        @by = 26.0; @vy = @vy.abs * 0.8
      elsif @by > 248.0
        @by = 248.0; @vy = -@vy.abs * 0.8
      end

      # カップイン判定
      gx = h[:goal][0]; gy = h[:goal][1]
      dx = @bx - gx; dy = @by - gy
      if dx * dx + dy * dy < 10.0 * 10.0
        @state = :cleared
        @msg_t = 65
        @total_strokes += @strokes
        @total_par += h[:par]
        diff = @strokes - h[:par]
        @hole_msg = @strokes == 1 ? "HOLE IN ONE!" : (diff <= -2 ? "EAGLE!" : (diff == -1 ? "BIRDIE!" : (diff == 0 ? "PAR!" : "+#{diff}")))
        i = 0
        while i < 16
          ang = rand() * Math::PI * 2.0
          @sparks << { x: gx, y: gy, vx: cos(ang) * 2.4, vy: sin(ang) * 2.4, col: 10, life: 24 }
          i += 1
        end
        return
      end

      # 手動リセットまたは停止
      spd2 = @vx * @vx + @vy * @vy
      if btnp(5) || (@fly_t > 240 && spd2 < 0.15)
        @state = :aim
        @vx = 0.0; @vy = 0.0
      end
    end
  end

  def draw
    cls(0)
    bg(:space, dim: 0.42, scroll_x: @t * 0.08, mirror_x: true)

    h = HOLES[@hole_idx]

    # 惑星 & 重力圏
    h[:planets].each do |pl|
      circ(pl[:x].to_i, pl[:y].to_i, (pl[:r] * 2.2).to_i, 1)
      circfill(pl[:x].to_i, pl[:y].to_i, pl[:r].to_i, pl[:col])
      circ(pl[:x].to_i, pl[:y].to_i, pl[:r].to_i, 7)
    end

    # ゴール（ワープホール）
    gx = h[:goal][0].to_i
    gy = h[:goal][1].to_i
    circfill(gx, gy, 7, 0)
    circ(gx, gy, 7, 11)
    circ(gx, gy, 4 + (@t / 6) % 3, 10)

    # 軌道予測線
    if @state == :aim
      pts = compute_preview
      pts.each { |pt| pset(pt[0], pt[1], 10) }
    end

    # 軌跡 & ボール
    @trails.each { |tr| pset(tr[0], tr[1], 12) }
    circfill(@bx.to_i, @by.to_i, 3, 7)
    @sparks.each { |s| rectfill(s[:x].to_i, s[:y].to_i, 2, 2, s[:col]) }

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("HOLE:#{@hole_idx + 1}/9", 6, 6, 12)
    print_text("PAR:#{h[:par]}", 78, 6, 7)
    print_text("SHOT:#{@strokes}", 126, 6, 10)
    print_text("TOT:#{@total_strokes}", 192, 6, 11)

    if @state == :cleared
      rectfill(64, 106, 128, 30, 0)
      rect(64, 106, 128, 30, 10)
      print_text(@hole_msg, 128 - @hole_msg.length * 3, 117, 10)
    end

    if @finished
      diff = @total_strokes - @total_par
      lbl = diff <= 0 ? "#{diff}" : "+#{diff}"
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 10)
      print_text("GALAXY TOUR COMPLETE!", 65, 96, 10)
      print_text("TOTAL : #{@total_strokes} (PAR #{@total_par})", 58, 114, 7)
      print_text("SCORE : #{lbl}", 92, 128, 11)
      if (@fin_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO REPLAY", 50, 148, 12)
      end
    end
  end
end

run TitleScene.new
