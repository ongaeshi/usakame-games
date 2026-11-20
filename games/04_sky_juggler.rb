# ==============================================================================
# 04. SKY JUGGLER
# ------------------------------------------------------------------------------
# 敵を落とさず空中お手玉コンボ＆フィーバーBG変貌アリーナ
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ← / → (A / D)          : 移動
#   ↑ (W)                  : ジャンプ (2段ジャンプ可)
#   Z / Space / 左クリック : アッパーお手玉打ち上げ (空中で再ジャンプ回復!)
#   ↓ (S) (空中)           : 急降下ポゴ踏み
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "04. SKY JUGGLER"
)

FLOOR_Y = 224.0
GRAV = 0.24

$juggle_best ||= 0
$juggle_max_combo ||= 0

def clamp_v(v, lo, hi)
  return lo if v < lo
  return hi if v > hi
  v
end

class EffectSystem
  attr_accessor :shake_timer, :shake_power, :hitstop, :flash_timer, :flash_col

  def initialize
    @particles = []
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

  def burst(x, y, count, col, spd = 2.6, life = 18)
    i = 0
    while i < count
      ang = rand() * Math::PI * 2.0
      v = (0.3 + rand() * 0.7) * spd
      @particles << {
        x: x.to_f, y: y.to_f,
        vx: cos(ang) * v, vy: sin(ang) * v,
        life: life + rand(8), col: col, size: rand(2) + 1, grav: 0.05
      }
      i += 1
    end
  end

  def ring(x, y, max_r, col, spd = 2.5)
    @rings << { x: x.to_f, y: y.to_f, r: 2.0, max_r: max_r.to_f, col: col, spd: spd }
  end

  def popup(x, y, text, col = 7)
    @popups << { x: x.to_f, y: y.to_f, vy: -0.85, life: 30, text: text, col: col }
  end

  def update
    @shake_timer -= 1 if @shake_timer > 0
    @flash_timer -= 1 if @flash_timer > 0

    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:vy] += p[:grav]
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }

    @rings.each { |r| r[:r] += r[:spd] }
    @rings.reject! { |r| r[:r] >= r[:max_r] }

    @popups.each do |pp|
      pp[:y] += pp[:vy]
      pp[:vy] *= 0.92
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
    bg(:sky, dim: 0.25, scroll_x: @t * 0.25, mirror_x: true)

    rectfill(0, FLOOR_Y.to_i, 256, 32, 3)
    rectfill(0, FLOOR_Y.to_i, 256, 4, 11)

    # デモお手玉
    by = 130.0 + sin(@t * 0.08).abs * -48.0
    spr(:slime, 120, by.to_i)
    spr(:juggler, 120, FLOOR_Y.to_i - 16)

    rectfill(26, 22, 204, 38, 0)
    rect(26, 22, 204, 38, 12)
    print_text("SKY JUGGLER", 95, 30, 10)
    print_text("KEEP ENEMIES AIRBORNE FOR FEVER!", 32, 44, 7)

    rectfill(24, 150, 208, 52, 0)
    rect(24, 150, 208, 52, 5)
    print_text("A/D: MOVE   W: JUMP (DOUBLE)", 42, 158, 7)
    print_text("Z / SPACE / CLICK : UPPERCUT", 42, 170, 10)
    if $juggle_best > 0
      print_text("BEST: #{$juggle_best}  MAX COMBO: #{$juggle_max_combo}", 48, 184, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO START", 53, 210, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @fx = EffectSystem.new
    @px = 128.0
    @py = FLOOR_Y - 8.0
    @vx = 0.0
    @vy = 0.0
    @facing_left = false
    @grounded = true
    @air_jumps = 1
    @atk_timer = 0
    @atk_cd = 0
    @hurt_inv = 0

    @hp = 3
    @score = 0
    @combo = 0
    @max_combo = 0
    @combo_timer = 0
    @fever = false

    @balls = []
    @spawn_cd = 20
    @dead = false
    @dead_timer = 0
  end

  def spawn_ball
    kind = rand(10) < 2 ? :star : (rand(4) == 0 ? :bat : :slime)
    x = 28.0 + rand() * 200.0
    vx = (rand() - 0.5) * 2.2
    @balls << {
      x: x, y: -12.0, vx: vx, vy: 0.6,
      kind: kind, spin: 0.0, hits: 0, alive: true
    }
  end

  def hit_ball(b, from_uppercut)
    b[:hits] += 1
    b[:vy] = from_uppercut ? -5.4 : -4.8
    b[:vx] = clamp_v((b[:x] - @px) * 0.16 + (rand() - 0.5) * 1.2, -3.2, 3.2)

    @combo += 1
    @combo_timer = 150
    @max_combo = @combo if @combo > @max_combo
    $juggle_max_combo = @max_combo if @max_combo > $juggle_max_combo

    was_fever = @fever
    @fever = @combo >= 10
    if @fever && !was_fever
      @fx.flash(5, 10)
      @fx.popup(128.0, 72.0, "FEVER MODE!!", 10)
    end

    mult = @fever ? 2 : 1
    base = b[:kind] == :star ? 80 : 30
    pts = (base + @combo * 10) * mult
    @score += pts
    $juggle_best = @score if @score > $juggle_best

    col = @fever ? 10 : 12
    @fx.burst(b[:x], b[:y], 10, col, 2.8, 18)
    @fx.ring(b[:x], b[:y], 18.0, 7, 2.4)
    @fx.popup(b[:x], b[:y] - 10.0, "+#{pts}", @fever ? 10 : 7)
    @fx.stop(2)
    @fx.shake(2.2, 6)
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

    @atk_timer -= 1 if @atk_timer > 0
    @atk_cd -= 1 if @atk_cd > 0
    @hurt_inv -= 1 if @hurt_inv > 0

    if @combo_timer > 0
      @combo_timer -= 1
      if @combo_timer == 0
        @combo = 0
        @fever = false
      end
    end

    # 移動
    if btn(0)
      @vx -= 0.55
      @facing_left = true
    elsif btn(1)
      @vx += 0.55
      @facing_left = false
    else
      @vx *= 0.78
    end
    @vx = clamp_v(@vx, -3.2, 3.2)

    # ジャンプ
    if btnp(2)
      if @grounded
        @vy = -5.2
        @grounded = false
        @fx.burst(@px, FLOOR_Y, 5, 7, 1.5, 10)
      elsif @air_jumps > 0
        @vy = -4.8
        @air_jumps -= 1
        @fx.burst(@px, @py + 6.0, 6, 12, 1.8, 12)
      end
    end

    # 急降下
    if !@grounded && btn(3)
      @vy += 0.45
    end

    # アッパーカット
    if (btnp(4) || btnp(:mouse_l)) && @atk_cd <= 0
      @atk_timer = 10
      @atk_cd = 13
      @vy = -2.2 if !@grounded && @vy > -1.0
      @fx.ring(@px, @py - 8.0, 20.0, @fever ? 10 : 7, 3.0)
    end

    @vy += GRAV
    @vy = 6.0 if @vy > 6.0

    @px += @vx
    @py += @vy

    if @px < 12.0
      @px = 12.0; @vx = 0.0
    elsif @px > 244.0
      @px = 244.0; @vx = 0.0
    end

    if @py >= FLOOR_Y - 8.0
      @py = FLOOR_Y - 8.0
      @vy = 0.0
      @grounded = true
      @air_jumps = 1
    else
      @grounded = false
    end

    # 敵スポーン
    @spawn_cd -= 1
    if @spawn_cd <= 0
      if @balls.size < 5 + (@score / 1500).to_i
        spawn_ball
      end
      @spawn_cd = 55 - (@score / 200).to_i
      @spawn_cd = 24 if @spawn_cd < 24
    end

    # 敵物理 & 判定
    @balls.each do |b|
      next unless b[:alive]
      b[:vy] += 0.13
      b[:vy] = 4.2 if b[:vy] > 4.2
      b[:x] += b[:vx]
      b[:y] += b[:vy]
      b[:spin] += b[:vx] * 4.0

      if b[:x] < 12.0
        b[:x] = 12.0; b[:vx] = b[:vx].abs
      elsif b[:x] > 244.0
        b[:x] = 244.0; b[:vx] = -b[:vx].abs
      end

      # アッパー攻撃判定
      if @atk_timer > 6
        dx = b[:x] - @px
        dy = b[:y] - (@py - 8.0)
        if dx * dx + dy * dy < 28.0 * 28.0
          hit_ball(b, true)
          @air_jumps = 1
          next
        end
      end

      # 踏みつけ(ポゴ)判定
      dx2 = b[:x] - @px
      dy2 = b[:y] - @py
      if dx2 * dx2 + dy2 * dy2 < 16.0 * 16.0
        if @vy > 0.2 && @py < b[:y] + 2.0
          @vy = -4.9
          @air_jumps = 1
          hit_ball(b, false)
          next
        elsif @hurt_inv <= 0 && b[:hits] == 0
          # 地面近くで未ヒットの敵に当たるとダメージ
          b[:alive] = false
          @hp -= 1
          @combo = 0
          @fever = false
          @hurt_inv = 45
          @fx.burst(@px, @py, 14, 8, 3.0, 20)
          @fx.shake(4.0, 12)
          @fx.flash(4, 8)
          if @hp <= 0
            @dead = true
            @dead_timer = 0
          end
          next
        end
      end

      # 地面落下
      if b[:y] >= FLOOR_Y - 6.0
        b[:alive] = false
        @fx.burst(b[:x], FLOOR_Y - 4.0, 8, 5, 2.0, 14)
        if b[:hits] > 0 && @combo > 0
          @combo = 0
          @fever = false
          @fx.popup(b[:x], FLOOR_Y - 18.0, "DROP!", 8)
        end
      end
    end
    @balls.reject! { |b| !b[:alive] }

    @fx.update
  end

  def draw
    cls(0)
    shk = @fx.shake_offset
    if @fever
      tint = [160 + (sin(@t * 0.15) * 60).to_i, 180, 255]
      bg(:cyber, dim: 0.42, tint: tint, scale: 1.04,
         scroll_x: @t * 0.8 + shk[0] * 0.3, y: shk[1] * 0.3, mirror_x: true)
    else
      bg(:sky, dim: 0.28, scale: 1.04,
         scroll_x: @t * 0.2 + shk[0] * 0.3, y: shk[1] * 0.3, mirror_x: true)
    end

    camera(shk[0].to_i, shk[1].to_i)

    # 床
    rectfill(0, FLOOR_Y.to_i, 256, 32, @fever ? 1 : 3)
    rectfill(0, FLOOR_Y.to_i, 256, 4, @fever ? 12 : 11)

    # 敵
    @balls.each do |b|
      sp = b[:kind] == :star ? :star : (b[:kind] == :bat ? :bat : :slime)
      spr_ext(sp, b[:x].to_i, b[:y].to_i, b[:spin], 1.0, 1.0, false, false)
    end

    # 攻撃エフェクト
    if @atk_timer > 0
      arc_y = @py.to_i - 16
      circ(@px.to_i, arc_y, 18, @fever ? 10 : 7)
    end

    # プレイヤー
    unless @dead
      if @hurt_inv <= 0 || (@hurt_inv / 3) % 2 == 0
        spr(:juggler, @px.to_i - 8, @py.to_i - 8, @facing_left)
      end
    end

    @fx.draw

    camera()
    clip()

    if @fx.flash_timer > 0
      rect(0, 0, 256, 256, @fx.flash_col)
      rect(1, 1, 254, 254, @fx.flash_col)
    end

    # HUD
    rectfill(0, 0, 256, 18, 0)
    line(0, 18, 256, 18, 5)
    print_text("SCR:#{@score}", 6, 5, 7)
    if @combo > 0
      col = @fever ? 10 : 12
      lbl = @fever ? "FEVER x#{@combo}" : "COMBO #{@combo}"
      print_text(lbl, 92, 5, col)
    end

    i = 0
    while i < 3
      circfill(214 + i * 13, 9, 4, i < @hp ? 8 : 5)
      i += 1
    end

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("SHOW'S OVER!", 90, 96, 8)
      print_text("SCORE     : #{@score}", 68, 112, 7)
      print_text("MAX COMBO : #{@max_combo}", 68, 124, 10)
      print_text("BEST      : #{$juggle_best}", 68, 136, 12)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 152, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #0C0A18
1: #1D2B53
3: #008751
5: #5F574F
7: #FFF1E8
8: #FF004D
A: #FFEC27
B: #00E436
C: #29ADFF
D: #83769C
E: #FF77A8
F: #FFCCAA

@SPRITE :juggler 16x16 pal:1
................
.....000000.....
....07777770....
...0770770770...
...0777777770...
....00FFFF00....
...0EE8888EE0...
..0E0CCCCCC0E0..
....0CCCCCC0....
...00CCAA0C00...
....0CC00CC0....
....01100110....
....000..000....
................
................
................

@SPRITE :slime 16x16 pal:1
................
.....000000.....
...00BBBBBB00...
..0BB77BBBBBB0..
..0B7B0BBB0BB0..
.0BBBB0BBB0BBB0.
.0BBBBBBBBBBBB0.
.0BBBB3333BBBB0.
..0BB333333BB0..
...0033333300...
.....000000.....
................
................
................
................
................

@SPRITE :bat 16x16 pal:1
................
................
.00..........00.
0DD0..0000..0DD0
0DDD00DDDD00DDD0
.0DD0D7007D0DD0.
..000DDDDDD000..
....0DD88DD0....
.....0DDDD0.....
......0000......
................
................
................
................
................
................

@SPRITE :star 16x16 pal:1
.......00.......
......0AA0......
.....0A7AA0.....
.0000AA7AAA0000.
0AAAAAAAAAAAAAA0
.0AAA0A7AA0AAA0.
..0AAAAAAAAAAAA.
...0AAAAAAAAA0..
..0AAAA00AAAA0..
..0AA00..00AA0..
..000......000..
................
................
................
................
................
