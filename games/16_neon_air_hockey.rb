# ==============================================================================
# 16. NEON AIR HOCKEY
# ------------------------------------------------------------------------------
# マウス操作×超高速パック＆チャージ弾のネオン・エアホッケー
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   マウス移動 / 矢印キー : マレット操作
#   Z / Space / 左クリック : パワースマッシュ (高速ショット!)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "16. NEON AIR HOCKEY"
)

RINK_L = 20.0
RINK_R = 236.0
RINK_T = 26.0
RINK_B = 246.0
GOAL_L = 92.0
GOAL_R = 164.0
SUBSTEPS = 4

CPU_LEVELS = [
  { name: "LV1 ROOKIE",   spd: 1.8, col: 11 },
  { name: "LV2 STRIKER",  spd: 2.5, col: 12 },
  { name: "LV3 CYBER",    spd: 3.3, col: 14 },
  { name: "LV4 OVERLORD", spd: 4.2, col: 10 }
]

$hockey_wins ||= 0

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
      run GameScene.new(0)
    end
  end

  def draw
    cls(0)
    bg(:cyber, dim: 0.45, scroll_y: -@t * 0.4, mirror_y: true)

    rect(RINK_L.to_i, RINK_T.to_i, (RINK_R - RINK_L).to_i, (RINK_B - RINK_T).to_i, 12)
    circ(128, 136, 26, 1)

    rectfill(24, 28, 208, 40, 0)
    rect(24, 28, 208, 40, 12)
    print_text("NEON AIR HOCKEY", 83, 36, 10)
    print_text("4-STAGE CYBER TOURNAMENT", 53, 50, 12)

    rectfill(24, 82, 208, 60, 0)
    rect(24, 82, 208, 60, 5)
    print_text("MOUSE / ARROWS : MOVE MALLET", 40, 92, 7)
    print_text("Z / CLICK      : POWER SMASH!", 40, 106, 10)
    if $hockey_wins > 0
      print_text("TOURNAMENT WINS: #{$hockey_wins}", 62, 122, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO PLAY", 56, 206, 10)
    end
  end
end

class GameScene
  def initialize(cpu_idx)
    @t = 0
    @cpu_idx = cpu_idx
    @p_score = 0
    @c_score = 0

    @px = 128.0; @py = 210.0
    @pvx = 0.0; @pvy = 0.0
    @prev_mx = mouse_x
    @prev_my = mouse_y

    @cx = 128.0; @cy = 60.0
    @cvx = 0.0; @cvy = 0.0

    @bx = 128.0; @by = 136.0
    @bvx = 1.6; @bvy = 2.0

    @smash_cd = 0
    @smash_t = 0
    @goal_pause = 0
    @sparks = []
    @trails = []
    @rings = []
    @shake_t = 0
    @match_over = false
    @won = false
    @over_timer = 0
  end

  def reset_puck(dir_y)
    @bx = 128.0
    @by = 136.0
    @bvx = (rand() - 0.5) * 2.4
    @bvy = dir_y * 2.0
  end

  def add_sparks(x, y, col, cnt = 8)
    i = 0
    while i < cnt
      ang = rand() * Math::PI * 2.0
      spd = 1.2 + rand() * 2.4
      @sparks << { x: x, y: y, vx: cos(ang) * spd, vy: sin(ang) * spd, col: col, life: 14 }
      i += 1
    end
  end

  def collide_mallet(mx, my, mvx, mvy, mr, is_smash)
    dx = @bx - mx
    dy = @by - my
    min_d = mr + 6.0
    d2 = dx * dx + dy * dy
    if d2 < min_d * min_d && d2 > 0.0001
      d = sqrt(d2)
      nx = dx / d
      ny = dy / d
      @bx = mx + nx * min_d
      @by = my + ny * min_d
      @bvx = nx * (is_smash ? 6.2 : 3.8) + mvx * 0.45
      @bvy = ny * (is_smash ? 6.2 : 3.8) + mvy * 0.45
      add_sparks(@bx, @by, is_smash ? 10 : 12, is_smash ? 14 : 7)
      @rings << { x: @bx, y: @by, r: 4.0, max_r: is_smash ? 24.0 : 14.0, col: is_smash ? 10 : 7 }
      @shake_t = is_smash ? 8 : 3
    end
  end

  def update
    @t += 1
    @shake_t -= 1 if @shake_t > 0
    @sparks.each do |s|
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }
    @trails.each { |tr| tr[:life] -= 1 }
    @trails.reject! { |tr| tr[:life] <= 0 }
    @rings.each { |r| r[:r] += 2.4 }
    @rings.reject! { |r| r[:r] >= r[:max_r] }

    if @match_over
      @over_timer += 1
      if @over_timer > 30 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        if @won && @cpu_idx < CPU_LEVELS.size - 1
          run GameScene.new(@cpu_idx + 1)
        else
          run GameScene.new(0)
        end
      end
      return
    end

    if @goal_pause > 0
      @goal_pause -= 1
      return
    end

    @smash_cd -= 1 if @smash_cd > 0
    @smash_t -= 1 if @smash_t > 0

    if (btnp(4) || btnp(:mouse_l)) && @smash_cd <= 0
      @smash_t = 12
      @smash_cd = 32
      @rings << { x: @px, y: @py, r: 6.0, max_r: 22.0, col: 10 }
    end

    # プレイヤー移動
    old_px = @px; old_py = @py
    mx = mouse_x; my = mouse_y
    if mx != @prev_mx || my != @prev_my
      @px = clamp_v(mx.to_f, RINK_L + 12.0, RINK_R - 12.0)
      @py = clamp_v(my.to_f, 146.0, RINK_B - 12.0)
      @prev_mx = mx; @prev_my = my
    else
      spd = 3.2
      @px -= spd if btn(0)
      @px += spd if btn(1)
      @py -= spd if btn(2)
      @py += spd if btn(3)
      @px = clamp_v(@px, RINK_L + 12.0, RINK_R - 12.0)
      @py = clamp_v(@py, 146.0, RINK_B - 12.0)
    end
    @pvx = @px - old_px
    @pvy = @py - old_py

    # CPU移動
    old_cx = @cx; old_cy = @cy
    c_spd = CPU_LEVELS[@cpu_idx][:spd]
    target_x = @by < 140.0 ? @bx : 128.0
    target_y = @by < 126.0 ? clamp_v(@by - 12.0, RINK_T + 14.0, 118.0) : 54.0
    dx = target_x - @cx
    dy = target_y - @cy
    d = sqrt(dx * dx + dy * dy)
    if d > 1.0
      step = d < c_spd ? d : c_spd
      @cx += dx / d * step
      @cy += dy / d * step
    end
    @cx = clamp_v(@cx, RINK_L + 12.0, RINK_R - 12.0)
    @cy = clamp_v(@cy, RINK_T + 12.0, 124.0)
    @cvx = @cx - old_cx
    @cvy = @cy - old_cy

    # サブステップ物理
    s = 0
    while s < SUBSTEPS
      @bx += @bvx / SUBSTEPS
      @by += @bvy / SUBSTEPS
      @bvx *= 0.998
      @bvy *= 0.998

      b_spd = sqrt(@bvx * @bvx + @bvy * @bvy)
      if b_spd > 7.2
        @bvx = @bvx / b_spd * 7.2
        @bvy = @bvy / b_spd * 7.2
      end

      if @bx - 6.0 < RINK_L
        @bx = RINK_L + 6.0; @bvx = @bvx.abs
        add_sparks(@bx, @by, 12, 4)
      elsif @bx + 6.0 > RINK_R
        @bx = RINK_R - 6.0; @bvx = -@bvx.abs
        add_sparks(@bx, @by, 12, 4)
      end

      # ゴール判定
      in_goal_x = (@bx >= GOAL_L && @bx <= GOAL_R)
      if @by - 6.0 < RINK_T
        if in_goal_x
          @p_score += 1
          @goal_pause = 35
          add_sparks(@bx, RINK_T, 10, 18)
          @shake_t = 10
          if @p_score >= 5
            @match_over = true
            @won = true
            @over_timer = 0
            $hockey_wins += 1 if @cpu_idx == CPU_LEVELS.size - 1
          else
            reset_puck(1.0)
          end
          break
        else
          @by = RINK_T + 6.0; @bvy = @bvy.abs
          add_sparks(@bx, @by, 14, 4)
        end
      elsif @by + 6.0 > RINK_B
        if in_goal_x
          @c_score += 1
          @goal_pause = 35
          add_sparks(@bx, RINK_B, 8, 18)
          @shake_t = 10
          if @c_score >= 5
            @match_over = true
            @won = false
            @over_timer = 0
          else
            reset_puck(-1.0)
          end
          break
        else
          @by = RINK_B - 6.0; @bvy = -@bvy.abs
          add_sparks(@bx, @by, 12, 4)
        end
      end

      collide_mallet(@px, @py, @pvx, @pvy, 11.0, @smash_t > 0)
      collide_mallet(@cx, @cy, @cvx, @cvy, 11.0, false)
      s += 1
    end

    @trails << { x: @bx, y: @by, life: 7 } if @t % 2 == 0
  end

  def draw
    cls(0)
    shk_x = @shake_t > 0 ? rand(-2..2) : 0
    shk_y = @shake_t > 0 ? rand(-2..2) : 0
    bg(:cyber, dim: 0.45, scale: 1.04, scroll_x: shk_x * 0.3, y: shk_y * 0.3)

    camera(shk_x, shk_y)

    # リンク
    rect(RINK_L.to_i, RINK_T.to_i, (RINK_R - RINK_L).to_i, (RINK_B - RINK_T).to_i, 12)
    line(RINK_L.to_i, 136, RINK_R.to_i, 136, 1)
    circ(128, 136, 24, 1)

    # ゴールライン
    line(GOAL_L.to_i, RINK_T.to_i, GOAL_R.to_i, RINK_T.to_i, 14)
    line(GOAL_L.to_i, RINK_B.to_i, GOAL_R.to_i, RINK_B.to_i, 10)

    # トレイル & パック
    @trails.each { |tr| circfill(tr[:x].to_i, tr[:y].to_i, 3, 1) }
    circfill(@bx.to_i, @by.to_i, 6, 7)
    circ(@bx.to_i, @by.to_i, 6, 10)

    # CPU マレット
    cpu_col = CPU_LEVELS[@cpu_idx][:col]
    circfill(@cx.to_i, @cy.to_i, 11, 1)
    circ(@cx.to_i, @cy.to_i, 11, cpu_col)
    circfill(@cx.to_i, @cy.to_i, 4, cpu_col)

    # プレイヤーマレット
    circfill(@px.to_i, @py.to_i, 11, 1)
    circ(@px.to_i, @py.to_i, 11, @smash_t > 0 ? 10 : 12)
    circfill(@px.to_i, @py.to_i, 4, @smash_t > 0 ? 10 : 7)

    @rings.each { |r| circ(r[:x].to_i, r[:y].to_i, r[:r].to_i, r[:col]) }
    @sparks.each { |s| rectfill(s[:x].to_i, s[:y].to_i, 2, 2, s[:col]) }

    camera()
    clip()

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text(CPU_LEVELS[@cpu_idx][:name], 6, 6, cpu_col)
    print_text("YOU #{@p_score} - #{@c_score} CPU", 140, 6, 7)

    if @match_over
      rectfill(30, 84, 196, 84, 0)
      rect(30, 84, 196, 84, @won ? 10 : 8)
      print_text(@won ? "MATCH WON!" : "CPU WINS!", 95, 98, @won ? 10 : 8)
      print_text("SCORE: #{@p_score} - #{@c_score}", 84, 118, 7)
      lbl = @won && @cpu_idx < 3 ? "PRESS Z FOR NEXT LV" : "PRESS Z TO RETRY"
      if (@over_timer / 18) % 2 == 0
        print_text(lbl, 68, 142, 12)
      end
    end
  end
end

run TitleScene.new
