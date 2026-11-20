# ==============================================================================
# 02. PARRY DOJO
# ------------------------------------------------------------------------------
# 月夜の竹林で四方の刃・矢を見切り居合斬りする1ボタン道場
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   Z / Space / 左クリック : 見切りパリィ / 居合斬り（自動方向対応）
#   ← / → / ↑ (任意)       : 斬撃方向の明示指定
#   X / Enter / 右クリック : 奥義「月光居合」（ゲージ100%時）
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "02. PARRY DOJO"
)

CENTER_X = 128.0
CENTER_Y = 166.0
PARRY_RANGE = 42.0
JUST_MIN = 12.0
JUST_MAX = 30.0
HIT_RADIUS = 10.0

$dojo_best ||= 0
$dojo_max_combo ||= 0

def clamp_f(v, lo, hi)
  return lo if v < lo
  return hi if v > hi
  v
end

class EffectSystem
  attr_accessor :shake_timer, :shake_power, :hitstop, :flash_timer, :flash_col

  def initialize
    @particles = []
    @rings = []
    @slashes = []
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
      v = (0.35 + rand() * 0.65) * spd
      @particles << {
        x: x.to_f, y: y.to_f,
        vx: cos(ang) * v, vy: sin(ang) * v,
        life: life + rand(8), col: col, size: rand(2) + 1, grav: 0.06
      }
      i += 1
    end
  end

  def petal(x, y)
    @particles << {
      x: x.to_f, y: y.to_f,
      vx: -0.4 - rand() * 0.5, vy: 0.3 + rand() * 0.4,
      life: 90 + rand(60), col: rand(3) == 0 ? 14 : 7, size: 1, grav: 0.0
    }
  end

  def ring(x, y, max_r, col, spd = 2.8)
    @rings << { x: x.to_f, y: y.to_f, r: 3.0, max_r: max_r.to_f, col: col, spd: spd }
  end

  def slash_arc(x, y, ang, len, col)
    @slashes << { x: x.to_f, y: y.to_f, ang: ang, len: len.to_f, col: col, life: 9, max_life: 9 }
  end

  def popup(x, y, text, col = 7)
    @popups << { x: x.to_f, y: y.to_f, vy: -0.9, life: 32, text: text, col: col }
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

    @rings.each { |r| r[:r] += r[:spd] }
    @rings.reject! { |r| r[:r] >= r[:max_r] }

    @slashes.each { |s| s[:life] -= 1 }
    @slashes.reject! { |s| s[:life] <= 0 }

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
    @rings.each do |r|
      circ(r[:x].to_i, r[:y].to_i, r[:r].to_i, r[:col])
    end
    @slashes.each do |s|
      t = s[:life].to_f / s[:max_life]
      l = s[:len] * (1.2 - t * 0.2)
      x1 = s[:x] + cos(s[:ang] - 0.55) * l
      y1 = s[:y] + sin(s[:ang] - 0.55) * l
      x2 = s[:x] + cos(s[:ang] + 0.55) * l
      y2 = s[:y] + sin(s[:ang] + 0.55) * l
      xm = s[:x] + cos(s[:ang]) * (l * 1.18)
      ym = s[:y] + sin(s[:ang]) * (l * 1.18)
      line(x1.to_i, y1.to_i, xm.to_i, ym.to_i, s[:col])
      line(xm.to_i, ym.to_i, x2.to_i, y2.to_i, s[:col])
      if s[:life] > 5
        line(s[:x].to_i, s[:y].to_i, xm.to_i, ym.to_i, 7)
      end
    end
    @particles.each do |p|
      if p[:size] <= 1 || p[:life] < 6
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

def draw_moon_backdrop(t, shk_x, shk_y)
  bg(:forest, dim: 0.52, tint: [115, 145, 225], scale: 1.04,
     scroll_x: shk_x * 0.3, y: shk_y * 0.3, mirror_x: true)

  # 満月
  mx = 194 + (shk_x * 0.2).to_i
  my = 54 + (shk_y * 0.2).to_i
  circfill(mx, my, 24, 10)
  circfill(mx - 2, my - 2, 20, 7)

  # 道場の床（木製ステージ）
  rectfill(0, 178, 256, 78, 1)
  rectfill(0, 176, 256, 6, 4)
  line(0, 176, 256, 176, 9)
  x = 16
  while x < 256
    line(x, 182, x - 20, 256, 0)
    x += 32
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
    draw_moon_backdrop(@t, 0.0, 0.0)

    spr(:samurai, 120, 158)

    rectfill(28, 22, 200, 38, 0)
    rect(28, 22, 200, 38, 12)
    print_text("PARRY DOJO", 98, 30, 7)
    print_text("MOONLIT BAMBOO BLADE TRIAL", 47, 44, 12)

    rectfill(24, 96, 208, 56, 0)
    rect(24, 96, 208, 56, 5)
    print_text("Z / SPACE / CLICK : PARRY SLASH", 33, 105, 10)
    print_text("X / ENTER / R-CLK : MOONLIGHT IAI", 33, 118, 12)
    print_text("TIMING = JUST PARRY -> DEFLECT!", 33, 131, 7)
    if $dojo_best > 0
      print_text("BEST: #{$dojo_best}  MAX COMBO: #{$dojo_max_combo}", 48, 142, 10)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO ENTER DOJO", 38, 208, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @fx = EffectSystem.new
    @hp = 3
    @score = 0
    @combo = 0
    @max_combo = 0
    @iai_gauge = 0
    @wave = 1
    @kills_in_wave = 0

    @facing_left = false
    @slash_cd = 0
    @slash_anim = 0
    @hurt_inv = 0

    @threats = []
    @deflected = []
    @spawn_timer = 35
    @dead = false
    @dead_timer = 0
  end

  def spawn_threat
    # 0: 左, 1: 右, 2: 左上, 3: 右上, 4: 真上
    dir_idx = rand(5)
    spd = 1.65 + @wave * 0.14 + rand() * 0.45
    spd = 3.8 if spd > 3.8

    if dir_idx == 0
      sx = -12.0; sy = CENTER_Y - 2.0
    elsif dir_idx == 1
      sx = 268.0; sy = CENTER_Y - 2.0
    elsif dir_idx == 2
      sx = -10.0; sy = 56.0
    elsif dir_idx == 3
      sx = 266.0; sy = 56.0
    else
      sx = CENTER_X + (rand() - 0.5) * 40.0; sy = -12.0
    end

    dx = CENTER_X - sx
    dy = CENTER_Y - sy
    d = sqrt(dx * dx + dy * dy)
    vx = dx / d * spd
    vy = dy / d * spd

    kind = :arrow
    r = rand(10)
    if @wave >= 2 && r < 3
      kind = :shuriken
    elsif @wave >= 3 && r >= 8
      kind = :shinobi
      vx *= 1.15
      vy *= 1.15
    end

    @threats << {
      x: sx, y: sy, vx: vx, vy: vy,
      kind: kind, ang: atan2(vy, vx),
      alive: true, spin: 0.0
    }
  end

  def do_parry
    @slash_cd = 10
    @slash_anim = 9

    # 最も近い脅威を探す
    closest = nil
    closest_d = 9999.0
    @threats.each do |th|
      next unless th[:alive]
      dx = th[:x] - CENTER_X
      dy = th[:y] - CENTER_Y
      d = sqrt(dx * dx + dy * dy)
      if d < closest_d
        closest_d = d
        closest = th
      end
    end

    # 斬撃方向決定
    slash_ang = @facing_left ? Math::PI : 0.0
    if btn(0)
      slash_ang = Math::PI
      @facing_left = true
    elsif btn(1)
      slash_ang = 0.0
      @facing_left = false
    elsif btn(2)
      slash_ang = -Math::PI * 0.5
    elsif closest && closest_d < 90.0
      slash_ang = atan2(closest[:y] - CENTER_Y, closest[:x] - CENTER_X)
      @facing_left = closest[:x] < CENTER_X
    end

    @fx.slash_arc(CENTER_X, CENTER_Y, slash_ang, 32.0, 12)

    # パリィ判定（範囲内の全脅威を斬る）
    hit_any = false
    just_any = false
    @threats.each do |th|
      next unless th[:alive]
      dx = th[:x] - CENTER_X
      dy = th[:y] - CENTER_Y
      d = sqrt(dx * dx + dy * dy)
      if d <= PARRY_RANGE
        th[:alive] = false
        hit_any = true
        is_just = (d >= JUST_MIN && d <= JUST_MAX)
        just_any = true if is_just

        @combo += 1
        @max_combo = @combo if @combo > @max_combo
        $dojo_max_combo = @max_combo if @max_combo > $dojo_max_combo

        pts = is_just ? (100 * (1 + @combo / 5)) : (40 * (1 + @combo / 10))
        @score += pts
        $dojo_best = @score if @score > $dojo_best

        @iai_gauge += is_just ? 20 : 10
        @iai_gauge = 100 if @iai_gauge > 100

        @kills_in_wave += 1
        if @kills_in_wave >= 8 + @wave * 3
          @wave += 1
          @kills_in_wave = 0
          @fx.popup(CENTER_X, CENTER_Y - 36.0, "WAVE #{@wave}!", 10)
        end

        if is_just
          @fx.burst(th[:x], th[:y], 14, 12, 3.4, 20)
          @fx.ring(th[:x], th[:y], 20.0, 7, 2.8)
          @fx.popup(th[:x], th[:y] - 12.0, "JUST! +#{pts}", 10)
          # 跳ね返し弾
          @deflected << {
            x: th[:x], y: th[:y],
            vx: -th[:vx] * 2.2, vy: -th[:vy] * 2.2,
            life: 40
          }
        else
          @fx.burst(th[:x], th[:y], 8, 7, 2.2, 14)
          @fx.popup(th[:x], th[:y] - 10.0, "+#{pts}", 7)
        end
      end
    end

    if just_any
      @fx.stop(4)
      @fx.shake(3.2, 8)
      @fx.flash(3, 12)
    elsif hit_any
      @fx.stop(2)
      @fx.shake(1.6, 5)
    end
  end

  def do_moonlight_iai
    @iai_gauge = 0
    @slash_anim = 16
    @fx.flash(6, 7)
    @fx.shake(5.0, 14)
    @fx.stop(5)
    @fx.ring(CENTER_X, CENTER_Y, 120.0, 12, 6.5)
    @fx.popup(CENTER_X, CENTER_Y - 32.0, "MOONLIGHT IAI!!", 10)

    cleared = 0
    @threats.each do |th|
      next unless th[:alive]
      th[:alive] = false
      cleared += 1
      @combo += 1
      @fx.burst(th[:x], th[:y], 12, 12, 3.0, 20)
      @fx.slash_arc(th[:x], th[:y], rand() * Math::PI, 20.0, 7)
    end
    @max_combo = @combo if @combo > @max_combo
    $dojo_max_combo = @max_combo if @max_combo > $dojo_max_combo
    bonus = 200 + cleared * 120
    @score += bonus
    $dojo_best = @score if @score > $dojo_best
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

    @fx.petal(258.0, 10.0 + rand() * 140.0) if @t % 12 == 0

    if @fx.hitstop > 0
      @fx.hitstop -= 1
      @fx.update
      return
    end

    @slash_cd -= 1 if @slash_cd > 0
    @slash_anim -= 1 if @slash_anim > 0
    @hurt_inv -= 1 if @hurt_inv > 0

    # 奥義発動
    if @iai_gauge >= 100 && (btnp(5) || btnp(:mouse_r))
      do_moonlight_iai
    elsif (btnp(4) || btnp(:mouse_l)) && @slash_cd <= 0
      do_parry
    end

    # スポーン管理
    @spawn_timer -= 1
    if @spawn_timer <= 0
      spawn_threat
      if @wave >= 3 && rand(10) < 3
        spawn_threat
      end
      interval = 54 - @wave * 4
      interval = 20 if interval < 20
      @spawn_timer = interval + rand(14)
    end

    # 脅威移動
    @threats.each do |th|
      next unless th[:alive]
      th[:x] += th[:vx]
      th[:y] += th[:vy]
      th[:spin] += 14.0

      # 跳ね返し弾との衝突
      @deflected.each do |df|
        dx2 = th[:x] - df[:x]
        dy2 = th[:y] - df[:y]
        if dx2 * dx2 + dy2 * dy2 < 18.0 * 18.0
          th[:alive] = false
          @combo += 1
          @score += 150
          $dojo_best = @score if @score > $dojo_best
          @fx.burst(th[:x], th[:y], 10, 10, 2.8, 16)
          @fx.popup(th[:x], th[:y] - 8.0, "CHAIN +150!", 10)
        end
      end

      next unless th[:alive]

      # プレイヤー被弾判定
      dx = th[:x] - CENTER_X
      dy = th[:y] - CENTER_Y
      if dx * dx + dy * dy < HIT_RADIUS * HIT_RADIUS
        th[:alive] = false
        if @hurt_inv <= 0
          @hp -= 1
          @combo = 0
          @hurt_inv = 36
          @fx.burst(CENTER_X, CENTER_Y, 16, 8, 3.0, 22)
          @fx.shake(4.5, 12)
          @fx.flash(4, 8)
          @fx.popup(CENTER_X, CENTER_Y - 16.0, "HIT!", 8)
          if @hp <= 0
            @dead = true
            @dead_timer = 0
          end
        end
      end
    end
    @threats.reject! { |th| !th[:alive] }

    @deflected.each do |df|
      df[:x] += df[:vx]
      df[:y] += df[:vy]
      df[:life] -= 1
    end
    @deflected.reject! { |df| df[:life] <= 0 }

    @fx.update
  end

  def draw
    cls(0)
    shk = @fx.shake_offset
    draw_moon_backdrop(@t, shk[0], shk[1])

    camera(shk[0].to_i, shk[1].to_i)

    # パリィ有効範囲の薄いリングガイド
    circ(CENTER_X.to_i, CENTER_Y.to_i, PARRY_RANGE.to_i, 1)

    # 脅威描画
    @threats.each do |th|
      tx = th[:x].to_i
      ty = th[:y].to_i
      dx = th[:x] - CENTER_X
      dy = th[:y] - CENTER_Y
      d = sqrt(dx * dx + dy * dy)
      if d <= PARRY_RANGE
        circ(tx, ty, 9, d >= JUST_MIN && d <= JUST_MAX ? 10 : 7)
      end

      if th[:kind] == :arrow
        deg = th[:ang] * 180.0 / Math::PI
        spr_ext(:kunai, tx, ty, deg, 1.0, 1.0, false, false)
      elsif th[:kind] == :shuriken
        spr_ext(:shuriken, tx, ty, th[:spin], 1.0, 1.0, false, false)
      else
        spr_ext(:shinobi, tx, ty, 0.0, 1.0, 1.0, th[:vx] < 0, false)
      end
    end

    # 跳ね返し弾
    @deflected.each do |df|
      circfill(df[:x].to_i, df[:y].to_i, 3, 12)
      pset(df[:x].to_i, df[:y].to_i, 7)
    end

    # プレイヤー
    unless @dead
      if @hurt_inv <= 0 || (@hurt_inv / 3) % 2 == 0
        sp = @slash_anim > 0 ? :samurai_slash : :samurai
        spr(sp, CENTER_X.to_i - 8, CENTER_Y.to_i - 8, @facing_left)
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
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("SCR:#{@score}", 6, 6, 7)
    print_text("W#{@wave}", 78, 6, 12)
    if @combo > 1
      print_text("#{@combo} HIT", 104, 6, 10)
    end

    # HP ハート
    i = 0
    while i < 3
      col = i < @hp ? 8 : 5
      circfill(214 + i * 13, 10, 4, col)
      i += 1
    end

    # 居合ゲージ
    rectfill(64, 234, 128, 8, 0)
    rect(64, 234, 128, 8, 5)
    gw = (@iai_gauge * 124 / 100).to_i
    gcol = @iai_gauge >= 100 ? ((@t / 6) % 2 == 0 ? 10 : 7) : 12
    rectfill(66, 236, gw, 4, gcol) if gw > 0
    if @iai_gauge >= 100
      print_text("IAI READY! [X/R-CLK]", 70, 223, 10)
    else
      print_text("IAI GAUGE", 101, 223, 6)
    end

    if @dead
      rectfill(32, 82, 192, 88, 0)
      rect(32, 82, 192, 88, 8)
      print_text("DEFEATED IN THE DOJO", 68, 94, 8)
      print_text("SCORE     : #{@score}", 68, 112, 7)
      print_text("MAX COMBO : #{@max_combo}", 68, 124, 10)
      print_text("BEST      : #{$dojo_best}", 68, 136, 12)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 152, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #090A14
1: #1D2B53
4: #8A4836
5: #5F574F
6: #C2C3C7
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
C: #29ADFF
E: #FF77A8
F: #FFCCAA

@SPRITE :samurai 16x16 pal:1
................
.....000000.....
....07777770....
...0770770770...
...0777777770...
....00FFFF00....
...0111881110...
..01111AA11110..
..011111111170..
...00111111070..
....0110011070..
....01100110.0..
....000..000....
................
................
................

@SPRITE :samurai_slash 16x16 pal:1
................
.....000000.....
....07777770....
...0770770770...
...0777777770...
....00FFFF00....
...0111881110...
..01111AA1111077
..011111111107C0
...00111111000..
....01100110....
....01100110....
....000..000....
................
................
................

@SPRITE :kunai 16x16 pal:1
................
................
................
................
................
......000.......
...00067600.....
..08067777600...
...00066600.....
......000.......
................
................
................
................
................
................

@SPRITE :shuriken 16x16 pal:1
................
.......00.......
......0760......
......0660......
...0000550000...
..076508805670..
...0000550000...
......0660......
......0670......
.......00.......
................
................
................
................
................
................

@SPRITE :shinobi 16x16 pal:1
................
.....000000.....
....01111110....
...011F00F110...
...0111111110...
....00888800....
...0111111110...
..067011110110..
......0110......
.....0110110....
....0110.0110...
....000...000...
................
................
................
................
