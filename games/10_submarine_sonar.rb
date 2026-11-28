# ==============================================================================
# 10. SUBMARINE SONAR
# ------------------------------------------------------------------------------
# 暗黒の深海でソナー波紋を放ち海獣を暴く魚雷バトル
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ← / → / ↑ / ↓  : 潜水艦操縦
#   Z / 左クリック : ソナー波紋照射 (敵の姿を暴く!)
#   X / 右クリック : 魚雷発射 (暴いた敵に2倍クリティカル!)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "10. SUBMARINE SONAR"
)

$sonar_best ||= 0

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

  def burst(x, y, count, col, spd = 2.4, life = 18)
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

  def bubble(x, y)
    @particles << {
      x: x.to_f, y: y.to_f,
      vx: (rand() - 0.5) * 0.3, vy: -0.5 - rand() * 0.5,
      life: 24 + rand(16), col: 12, size: 1
    }
  end

  def ring(x, y, max_r, col, spd = 3.2)
    @rings << { x: x.to_f, y: y.to_f, r: 4.0, max_r: max_r.to_f, col: col, spd: spd }
  end

  def popup(x, y, text, col = 7)
    @popups << { x: x.to_f, y: y.to_f, vy: -0.6, life: 28, text: text, col: col }
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
    if btnp(1) || btnp(:mouse_l)
      run GameScene.new
    end
  end

  def draw
    cls(0)
    bg(:cave, dim: 0.72, tint: [55, 105, 185], scroll_x: @t * 0.15, mirror_x: true)

    r = (@t * 2) % 90 + 10
    circ(128, 174, r, 12)
    spr(:sub, 120, 166)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 12)
    print_text("SUBMARINE SONAR", 83, 32, 10)
    print_text("PING THE ABYSS & TORPEDO FOES!", 38, 46, 12)

    rectfill(24, 76, 208, 62, 0)
    rect(24, 76, 208, 62, 5)
    print_text("ARROWS / WASD : STEER SUB", 42, 86, 7)
    print_text("Z / CLICK     : SONAR PING", 42, 99, 12)
    print_text("X / R-CLICK   : FIRE TORPEDO", 42, 112, 10)
    if $sonar_best > 0
      print_text("HIGH SCORE: #{$sonar_best}", 74, 125, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO DIVE", 56, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @fx = EffectSystem.new
    @px = 128.0
    @py = 136.0
    @vx = 0.0
    @vy = 0.0
    @facing_left = false
    @hp = 4
    @inv = 0
    @score = 0
    @depth = 100

    @ping_cd = 0
    @torp_cd = 0
    @sonars = []
    @torps = []
    @monsters = []
    @pearls = []
    @spawn_cd = 30

    @dead = false
    @dead_timer = 0
  end

  def spawn_monster
    side = rand(2) == 0
    x = side ? -14.0 : 270.0
    y = 32.0 + rand() * 204.0
    kind = rand(4) == 0 ? :mine : (rand(3) == 0 ? :squid : :angler)
    hp = kind == :squid ? 3 : (kind == :angler ? 2 : 1)
    spd = kind == :mine ? 0.45 : (0.8 + rand() * 0.7)
    @monsters << {
      x: x, y: y, vx: side ? spd : -spd, vy: (rand() - 0.5) * 0.4,
      kind: kind, hp: hp, lit: 0, alive: true
    }
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

    @inv -= 1 if @inv > 0
    @ping_cd -= 1 if @ping_cd > 0
    @torp_cd -= 1 if @torp_cd > 0

    # 移動
    ax = 0.0
    ay = 0.0
    if btn(:left)
      ax -= 0.24
      @facing_left = true
    end
    if btn(:right)
      ax += 0.24
      @facing_left = false
    end
    ay -= 0.24 if btn(:up)
    ay += 0.24 if btn(:down)

    @vx = (@vx + ax) * 0.88
    @vy = (@vy + ay) * 0.88
    @px = clamp_v(@px + @vx, 12.0, 244.0)
    @py = clamp_v(@py + @vy, 28.0, 244.0)

    if @t % 8 == 0
      @fx.bubble(@px + (@facing_left ? 8.0 : -8.0), @py)
    end

    # ソナー発射
    if (btnp(1) || btnp(:mouse_l)) && @ping_cd <= 0
      @ping_cd = 28
      @sonars << { x: @px, y: @py, r: 6.0, max_r: 145.0 }
      @fx.burst(@px, @py, 6, 12, 1.8, 12)
    end

    # 魚雷発射
    if (btnp(2) || btnp(:mouse_r)) && @torp_cd <= 0
      @torp_cd = 16
      dir = @facing_left ? -1.0 : 1.0
      @torps << { x: @px + dir * 8.0, y: @py, vx: dir * 3.8, vy: 0.0, life: 90 }
      @fx.bubble(@px + dir * 10.0, @py)
    end

    # ソナー波紋更新 & 海獣発見
    @sonars.each do |sn|
      sn[:r] += 3.5
      @monsters.each do |m|
        dx = m[:x] - sn[:x]
        dy = m[:y] - sn[:y]
        d = sqrt(dx * dx + dy * dy)
        if (d - sn[:r]).abs < 8.0
          m[:lit] = 210
        end
      end
      @pearls.each do |pr|
        dx = pr[:x] - sn[:x]
        dy = pr[:y] - sn[:y]
        d = sqrt(dx * dx + dy * dy)
        pr[:lit] = 210 if (d - sn[:r]).abs < 8.0
      end
    end
    @sonars.reject! { |sn| sn[:r] >= sn[:max_r] }

    # 魚雷更新
    @torps.each do |tp|
      tp[:x] += tp[:vx]
      tp[:y] += tp[:vy]
      tp[:life] -= 1
      @fx.bubble(tp[:x], tp[:y]) if @t % 4 == 0

      @monsters.each do |m|
        next unless m[:alive]
        dx = tp[:x] - m[:x]
        dy = tp[:y] - m[:y]
        if dx * dx + dy * dy < 12.0 * 12.0
          tp[:life] = 0
          dmg = m[:lit] > 0 ? 2 : 1
          m[:hp] -= dmg
          m[:lit] = 120
          @fx.burst(tp[:x], tp[:y], 8, dmg > 1 ? 10 : 7, 2.2, 14)
          if m[:hp] <= 0
            m[:alive] = false
            pts = (m[:kind] == :squid ? 200 : 120) * dmg
            @score += pts
            $sonar_best = @score if @score > $sonar_best
            @depth += 25
            @fx.burst(m[:x], m[:y], 18, 9, 3.0, 20)
            @fx.ring(m[:x], m[:y], 22.0, 10, 2.5)
            @fx.popup(m[:x], m[:y] - 8.0, dmg > 1 ? "CRIT +#{pts}!" : "+#{pts}", 10)
            @fx.shake(3.0, 8)
            if rand(3) == 0
              @pearls << { x: m[:x], y: m[:y], lit: 180, got: false }
            end
          end
          break
        end
      end
    end
    @torps.reject! { |tp| tp[:life] <= 0 || tp[:x] < -10.0 || tp[:x] > 266.0 }

    # 海獣スポーン & 更新
    @spawn_cd -= 1
    if @spawn_cd <= 0
      spawn_monster
      @spawn_cd = 52 - (@depth / 100).to_i
      @spawn_cd = 22 if @spawn_cd < 22
    end

    @monsters.each do |m|
      next unless m[:alive]
      m[:lit] -= 1 if m[:lit] > 0
      if m[:kind] == :angler
        dx = @px - m[:x]
        dy = @py - m[:y]
        d = sqrt(dx * dx + dy * dy)
        if d > 1.0 && d < 90.0
          m[:x] += dx / d * 0.65
          m[:y] += dy / d * 0.65
        else
          m[:x] += m[:vx]
        end
      else
        m[:x] += m[:vx]
        m[:y] += m[:vy]
      end

      if @inv <= 0
        dx2 = m[:x] - @px
        dy2 = m[:y] - @py
        if dx2 * dx2 + dy2 * dy2 < 12.0 * 12.0
          m[:alive] = false
          @hp -= 1
          @inv = 50
          @fx.burst(@px, @py, 16, 8, 3.0, 20)
          @fx.shake(4.5, 12)
          @fx.flash(4)
          if @hp <= 0
            @dead = true
            @dead_timer = 0
          end
        end
      end
    end
    @monsters.reject! { |m| !m[:alive] || m[:x] < -30.0 || m[:x] > 286.0 }

    # 真珠回収
    @pearls.each do |pr|
      next if pr[:got]
      pr[:lit] -= 1 if pr[:lit] > 0
      dx = pr[:x] - @px
      dy = pr[:y] - @py
      if dx * dx + dy * dy < 14.0 * 14.0
        pr[:got] = true
        @score += 150
        $sonar_best = @score if @score > $sonar_best
        @fx.burst(pr[:x], pr[:y], 10, 14, 2.2, 16)
        @fx.popup(pr[:x], pr[:y] - 6.0, "PEARL +150", 14)
      end
    end
    @pearls.reject! { |pr| pr[:got] }

    @fx.update
  end

  def draw
    cls(0)
    shk = @fx.shake_offset
    bg(:cave, dim: 0.72, tint: [55, 105, 185], scale: 1.04,
       scroll_x: @t * 0.1 + shk[0] * 0.3, y: shk[1] * 0.3, mirror_x: true)

    camera(shk[0].to_i, shk[1].to_i)

    # ソナー波紋
    @sonars.each do |sn|
      circ(sn[:x].to_i, sn[:y].to_i, sn[:r].to_i, 12)
    end

    # 真珠
    @pearls.each do |pr|
      next if pr[:got]
      if pr[:lit] > 0
        circfill(pr[:x].to_i, pr[:y].to_i, 4, 14)
        pset(pr[:x].to_i - 1, pr[:y].to_i - 1, 7)
      else
        pset(pr[:x].to_i, pr[:y].to_i, 1)
      end
    end

    # 海獣（ソナーで照らされるとくっきり、暗闇では微かな目のみ）
    @monsters.each do |m|
      mx = m[:x].to_i
      my = m[:y].to_i
      if m[:lit] > 0
        sp = m[:kind] == :mine ? :mine : (m[:kind] == :squid ? :squid : :angler)
        spr(sp, mx - 8, my - 8, m[:vx] < 0)
        circ(mx, my, 10, 12) if @t % 8 < 4
      else
        pset(mx, my, m[:kind] == :mine ? 2 : 8)
      end
    end

    # 魚雷
    @torps.each do |tp|
      rectfill(tp[:x].to_i - 3, tp[:y].to_i - 1, 6, 3, 10)
      pset(tp[:x].to_i + (tp[:vx] > 0 ? 2 : -2), tp[:y].to_i, 7)
    end

    # 潜水艦
    unless @dead
      if @inv <= 0 || (@inv / 3) % 2 == 0
        spr(:sub, @px.to_i - 8, @py.to_i - 8, @facing_left)
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
    print_text("D:#{@depth}m", 6, 5, 12)
    print_text("SCR:#{@score}", 64, 5, 7)
    print_text("BEST:#{$sonar_best}", 134, 5, 10)
    i = 0
    while i < 4
      circfill(212 + i * 10, 9, 3, i < @hp ? 8 : 5)
      i += 1
    end

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("HULL BREACHED!", 86, 96, 8)
      print_text("DEPTH : #{@depth}m", 76, 112, 12)
      print_text("SCORE : #{@score}", 76, 124, 7)
      print_text("BEST  : #{$sonar_best}", 76, 136, 10)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 152, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #060914
1: #1D2B53
2: #7E2553
5: #5F574F
6: #C2C3C7
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
C: #29ADFF
E: #FF77A8

@SPRITE :sub 16x16 pal:1
................
.......000......
......0AAA0.....
....000AAA00....
..00AAAAAAAA00..
.0AA77AAACCAAA0.
0AAA77AACCCCAAA0
099AAAAAAAAAA990
.09999999999990.
...0000000000...
................
................
................
................
................
................

@SPRITE :angler 16x16 pal:1
................
.....0000.......
....0C0..0000...
...070..0222200.
.......022888220
......0228870820
.....02288888820
.....02287777820
......022822220.
.......0000000..
................
................
................
................
................
................

@SPRITE :squid 16x16 pal:1
.......00.......
......0EE0......
.....0E7EE0.....
....0EEEEEE0....
....0EE88EE0....
...0EE8080EE0...
....0EEEEEE0....
...0E0E00E0E0...
..0E0.0E0E0.0E0.
..00..00.00..00.
................
................
................
................
................
................

@SPRITE :mine 16x16 pal:1
.......00.......
...00..050..00..
...05005550050..
....055555550...
..005558855500..
.05555877855550.
..005558855500..
....055555550...
...05005550050..
...00..050..00..
.......00.......
................
................
................
................
................
