# ==============================================================================
# 08. COMET LASSO
# ------------------------------------------------------------------------------
# 回転投げ縄で小惑星や敵を振り回し連鎖爆破する物理アクション
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ← / → / ↑ / ↓ (WASD) : スラスター移動 (捕獲中は振り回し!)
#   Z / Space / 左クリック : 投げ縄発射 (ホールドで振り回し・離して投擲!)
#   X / Enter / 右クリック : ブーストダッシュ
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "08. COMET LASSO"
)

$lasso_best ||= 0

def clamp_v(v, lo, hi)
  return lo if v < lo
  return hi if v > hi
  v
end

class EffectSystem
  attr_accessor :shake_timer, :shake_power, :hitstop, :flash_timer

  def initialize
    @particles = []
    @rings = []
    @popups = []
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

  def burst(x, y, count, col, spd = 2.8, life = 18)
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

  def ring(x, y, max_r, col, spd = 2.8)
    @rings << { x: x.to_f, y: y.to_f, r: 2.0, max_r: max_r.to_f, col: col, spd: spd }
  end

  def popup(x, y, text, col = 7)
    @popups << { x: x.to_f, y: y.to_f, vy: -0.75, life: 30, text: text, col: col }
  end

  def update
    @shake_timer -= 1 if @shake_timer > 0
    @flash_timer -= 1 if @flash_timer > 0
    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:vx] *= 0.95
      p[:vy] *= 0.95
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
    bg(:space, dim: 0.35, scroll_x: @t * 0.2, scroll_y: @t * 0.1, mirror_x: true, mirror_y: true)

    ax = 128 + (cos(@t * 0.05) * 44.0).to_i
    ay = 160 + (sin(@t * 0.05) * 24.0).to_i
    line(128, 160, ax, ay, 10)
    spr(:cowboy, 120, 152)
    spr(:asteroid, ax - 8, ay - 8)

    rectfill(26, 26, 204, 40, 0)
    rect(26, 26, 204, 40, 10)
    print_text("COMET LASSO", 95, 34, 10)
    print_text("SWING ASTEROIDS TO SMASH UFOS!", 38, 48, 12)

    rectfill(24, 78, 208, 56, 0)
    rect(24, 78, 208, 56, 5)
    print_text("ARROWS/WASD : THRUST & SWING", 40, 88, 7)
    print_text("HOLD Z/CLK  : LASSO -> RELEASE!", 40, 101, 10)
    if $lasso_best > 0
      print_text("HIGH SCORE: #{$lasso_best}", 74, 116, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO RIDE", 56, 212, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @fx = EffectSystem.new
    @px = 128.0
    @py = 148.0
    @vx = 0.0
    @vy = 0.0
    @hp = 3
    @inv = 0
    @score = 0
    @wave = 1
    @dash_cd = 0

    @grabbed = nil
    @rope_len = 36.0
    @orbit_ang = 0.0
    @orbit_spd = 0.12

    @rocks = []
    @ufos = []
    @ebullets = []
    @dead = false
    @dead_timer = 0

    spawn_wave
  end

  def spawn_wave
    i = 0
    while i < 4 + @wave
      ang = rand() * Math::PI * 2.0
      dist = 70.0 + rand() * 50.0
      rx = clamp_v(128.0 + cos(ang) * dist, 20.0, 236.0)
      ry = clamp_v(136.0 + sin(ang) * dist, 34.0, 236.0)
      @rocks << {
        x: rx, y: ry,
        vx: (rand() - 0.5) * 0.9, vy: (rand() - 0.5) * 0.9,
        thrown: 0, chain: 0, rot: rand() * 360.0, alive: true
      }
      i += 1
    end

    u_cnt = 1 + @wave
    u_cnt = 5 if u_cnt > 5
    i = 0
    while i < u_cnt
      ux = i % 2 == 0 ? 28.0 : 228.0
      uy = 42.0 + rand() * 160.0
      @ufos << {
        x: ux, y: uy, vx: (rand() - 0.5) * 1.4, vy: (rand() - 0.5) * 1.4,
        cd: 50 + rand(60), alive: true
      }
      i += 1
    end
  end

  def find_grabbable
    best = nil
    best_d2 = 88.0 * 88.0
    @rocks.each do |r|
      next unless r[:alive]
      dx = r[:x] - @px
      dy = r[:y] - @py
      d2 = dx * dx + dy * dy
      if d2 < best_d2
        best_d2 = d2
        best = r
      end
    end
    best
  end

  def explode_chain(x, y, chain)
    pts = 100 * (chain + 1)
    @score += pts
    $lasso_best = @score if @score > $lasso_best
    @fx.burst(x, y, 18, 9, 3.2, 20)
    @fx.burst(x, y, 10, 10, 2.2, 16)
    @fx.ring(x, y, 26.0, 10, 2.8)
    @fx.popup(x, y - 8.0, chain > 0 ? "CHAIN x#{chain + 1}! +#{pts}" : "+#{pts}", 10)
    @fx.stop(3)
    @fx.shake(3.2, 8)
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

    if @fx.hitstop > 0
      @fx.hitstop -= 1
      @fx.update
      return
    end

    @inv -= 1 if @inv > 0
    @dash_cd -= 1 if @dash_cd > 0

    # 移動
    ax = 0.0
    ay = 0.0
    ax -= 1.0 if btn(0)
    ax += 1.0 if btn(1)
    ay -= 1.0 if btn(2)
    ay += 1.0 if btn(3)

    if @dash_cd <= 0 && (btnp(5) || btnp(:mouse_r)) && (ax != 0.0 || ay != 0.0)
      len = sqrt(ax * ax + ay * ay)
      @vx = ax / len * 5.2
      @vy = ay / len * 5.2
      @dash_cd = 40
      @fx.burst(@px, @py, 8, 12, 2.2, 12)
    else
      @vx += ax * 0.26
      @vy += ay * 0.26
    end

    @vx *= 0.90
    @vy *= 0.90
    @px = clamp_v(@px + @vx, 12.0, 244.0)
    @py = clamp_v(@py + @vy, 28.0, 244.0)

    # 投げ縄
    holding = btn(4) || btn(:mouse_l)
    if (btnp(4) || btnp(:mouse_l)) && @grabbed.nil?
      target = find_grabbable
      if target
        @grabbed = target
        @orbit_ang = atan2(target[:y] - @py, target[:x] - @px)
        @orbit_spd = 0.14
        @fx.ring(target[:x], target[:y], 14.0, 10, 2.2)
      end
    elsif !holding && @grabbed
      # 投擲!
      tang = @orbit_ang + Math::PI * 0.5
      spd = 5.4 + sqrt(@vx * @vx + @vy * @vy) * 0.7
      @grabbed[:vx] = cos(tang) * spd + @vx * 0.5
      @grabbed[:vy] = sin(tang) * spd + @vy * 0.5
      @grabbed[:thrown] = 65
      @grabbed[:chain] = 0
      @fx.burst(@grabbed[:x], @grabbed[:y], 8, 10, 2.5, 14)
      @grabbed = nil
    end

    if @grabbed
      if !@grabbed[:alive]
        @grabbed = nil
      else
        @orbit_spd += 0.004 if @orbit_spd < 0.24
        @orbit_ang += @orbit_spd
        @grabbed[:x] = clamp_v(@px + cos(@orbit_ang) * @rope_len, 10.0, 246.0)
        @grabbed[:y] = clamp_v(@py + sin(@orbit_ang) * @rope_len, 24.0, 246.0)
        @grabbed[:thrown] = 10
      end
    end

    # 小惑星更新
    @rocks.each do |r|
      next unless r[:alive]
      r[:rot] += 3.0
      if r != @grabbed
        r[:x] += r[:vx]
        r[:y] += r[:vy]
        if r[:x] < 12.0 || r[:x] > 244.0
          r[:vx] = -r[:vx]
          r[:x] = clamp_v(r[:x], 12.0, 244.0)
        end
        if r[:y] < 26.0 || r[:y] > 244.0
          r[:vy] = -r[:vy]
          r[:y] = clamp_v(r[:y], 26.0, 244.0)
        end
        if r[:thrown] > 0
          r[:thrown] -= 1
          r[:vx] *= 0.985
          r[:vy] *= 0.985
        end
      end

      # 投擲中の衝突（UFO / 他の岩）
      if r[:thrown] > 0
        @ufos.each do |u|
          next unless u[:alive]
          dx = r[:x] - u[:x]
          dy = r[:y] - u[:y]
          if dx * dx + dy * dy < 16.0 * 16.0
            u[:alive] = false
            explode_chain(u[:x], u[:y], r[:chain])
            r[:chain] += 1
          end
        end
      end
    end
    @rocks.reject! { |r| !r[:alive] }
    @ufos.reject! { |u| !u[:alive] }

    # UFO 更新
    @ufos.each do |u|
      u[:x] += u[:vx]
      u[:y] += u[:vy]
      u[:vx] = -u[:vx] if u[:x] < 16.0 || u[:x] > 240.0
      u[:vy] = -u[:vy] if u[:y] < 28.0 || u[:y] > 240.0
      u[:cd] -= 1
      if u[:cd] <= 0
        u[:cd] = 85 + rand(40)
        dx = @px - u[:x]
        dy = @py - u[:y]
        d = sqrt(dx * dx + dy * dy)
        if d > 1.0
          @ebullets << { x: u[:x], y: u[:y], vx: dx / d * 1.9, vy: dy / d * 1.9 }
        end
      end
    end

    # 敵弾
    @ebullets.each do |eb|
      eb[:x] += eb[:vx]
      eb[:y] += eb[:vy]
      if @inv <= 0
        dx = eb[:x] - @px
        dy = eb[:y] - @py
        if dx * dx + dy * dy < 8.0 * 8.0
          eb[:x] = -999.0
          @hp -= 1
          @inv = 50
          @fx.burst(@px, @py, 14, 8, 3.0, 18)
          @fx.shake(4.0, 12)
          @fx.flash(4)
          if @hp <= 0
            @dead = true
            @dead_timer = 0
          end
        end
      end
    end
    @ebullets.reject! { |eb| eb[:x] < -10.0 || eb[:x] > 266.0 || eb[:y] < -10.0 || eb[:y] > 266.0 }

    # ウェーブクリア
    if @ufos.empty? && !@dead
      @wave += 1
      @score += 300
      $lasso_best = @score if @score > $lasso_best
      @fx.popup(128.0, 110.0, "WAVE #{@wave}!", 11)
      @rocks.clear
      @grabbed = nil
      spawn_wave
    end

    @fx.update
  end

  def draw
    cls(0)
    shk = @fx.shake_offset
    bg(:space, dim: 0.4, scale: 1.04,
       scroll_x: @t * 0.15 + shk[0] * 0.3, scroll_y: @t * 0.08 + shk[1] * 0.3,
       mirror_x: true, mirror_y: true)

    camera(shk[0].to_i, shk[1].to_i)

    # ロープ
    if @grabbed
      line(@px.to_i, @py.to_i, @grabbed[:x].to_i, @grabbed[:y].to_i, 10)
      circ(@grabbed[:x].to_i, @grabbed[:y].to_i, 10, 10)
    else
      cand = find_grabbable
      if cand
        circ(cand[:x].to_i, cand[:y].to_i, 10, 11)
      end
    end

    # 小惑星
    @rocks.each do |r|
      spr_ext(:asteroid, r[:x].to_i, r[:y].to_i, r[:rot], 1.0, 1.0, false, false)
    end

    # UFO
    @ufos.each do |u|
      spr(:ufo, u[:x].to_i - 8, u[:y].to_i - 8)
    end

    # 敵弾
    @ebullets.each do |eb|
      circfill(eb[:x].to_i, eb[:y].to_i, 3, 8)
      pset(eb[:x].to_i, eb[:y].to_i, 10)
    end

    # 自機
    unless @dead
      if @inv <= 0 || (@inv / 3) % 2 == 0
        spr(:cowboy, @px.to_i - 8, @py.to_i - 8)
      end
    end

    @fx.draw

    camera()
    clip()

    if @fx.flash_timer > 0
      rect(0, 0, 256, 256, 8)
      rect(1, 1, 254, 254, 8)
    end

    # HUD
    rectfill(0, 0, 256, 18, 0)
    line(0, 18, 256, 18, 5)
    print_text("W:#{@wave}", 6, 5, 12)
    print_text("SCR:#{@score}", 54, 5, 7)
    print_text("BEST:#{$lasso_best}", 134, 5, 10)
    i = 0
    while i < 3
      circfill(218 + i * 12, 9, 4, i < @hp ? 8 : 5)
      i += 1
    end

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("LOST IN ORBIT!", 86, 96, 8)
      print_text("WAVE  : #{@wave}", 76, 112, 12)
      print_text("SCORE : #{@score}", 76, 124, 7)
      print_text("BEST  : #{$lasso_best}", 76, 136, 10)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 152, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #080914
4: #8A4836
5: #5F574F
6: #C2C3C7
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
B: #00E436
C: #29ADFF

@SPRITE :cowboy 16x16 pal:1
................
....00000000....
...0444444440...
..000000000000..
....07777770....
...0770770770...
....00777700....
...0CC8888CC0...
..0CC0CCCC0CC0..
....0CCCCCC0....
.....09AA90.....
......0990......
.......00.......
................
................
................

@SPRITE :asteroid 16x16 pal:1
................
.....000000.....
...0066655500...
..066676555550..
.06666554455550.
.06555544445550.
.05554445555450.
.05555555654450.
..055555555550..
...0055555500...
.....000000.....
................
................
................
................
................

@SPRITE :ufo 16x16 pal:1
................
.....000000.....
....0CCCCCC0....
...0CC7777CC0...
..000CCCCCC000..
.05555555555550.
0558855AA5588550
.05555555555550.
..000BB00BB000..
.....00..00.....
................
................
................
................
................
................
