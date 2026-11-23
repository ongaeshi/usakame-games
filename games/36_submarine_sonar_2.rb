# ==============================================================================
# 36. ABYSS SONAR II
# ------------------------------------------------------------------------------
# 【10進化版】乗算の漆黒深海をライトとソナー波紋で照らす深海探索＆ボス戦
# 320x240 / 1ファイル完結 / 基本API + bg() + スプライト + キーボード/マウス
#
# 【操作方法】
#   矢印キー / WASD        : 潜水艦操縦（サーチライトの向きも連動）
#   Z / Space / 左クリック : ソナー波紋照射（海獣を暴き2倍クリティカル！）
#   X / Enter / 右クリック : 魚雷発射
# ==============================================================================

config(
  width: 320,
  height: 240,
  scale: 2,
  title: "36. ABYSS SONAR II"
)

SW = 320
SH = 240
$abyss2_best ||= 0

class AbyssSonarII
  def initialize
    @state = :title
    @frame = 0
    reset_game
  end

  def reset_game
    @px = 160.0
    @py = 128.0
    @vx = 0.0
    @vy = 0.0
    @facing_left = false
    @hp = 5
    @max_hp = 5
    @inv = 0
    @depth = 200
    @score = 0
    @sonar_cd = 0
    @torp_cd = 0
    @shake = 0.0
    @flash = 0
    @next_boss_depth = 650

    @sonars = []
    @torps = []
    @monsters = []
    @pearls = []
    @ebullets = []
    @particles = []
    @popups = []
    @boss = nil
    @spawn_cd = 20
  end

  def point_in_light?(tx, ty)
    dx = tx - @px
    dy = ty - @py
    d2 = dx * dx + dy * dy
    return false if d2 > 115.0 * 115.0
    return true if d2 < 26.0 * 26.0
    dir_x = @facing_left ? -1.0 : 1.0
    len = sqrt(d2)
    dot = (dx / len) * dir_x
    dot > 0.72
  end

  def spawn_monster
    from_left = rand(2) == 0
    x = from_left ? -16.0 : (SW + 16.0)
    y = 30.0 + rand(SH - 48)
    kind = [:angler, :squid, :mine][rand(3)]
    spd = kind == :mine ? 0.45 : (kind == :squid ? 1.15 : 0.85)
    @monsters << {
      kind: kind, x: x, y: y,
      vx: from_left ? spd : -spd,
      vy: (rand - 0.5) * 0.4,
      hp: kind == :angler ? 2 : 1,
      lit: 0.0, alive: true
    }
    if rand(3) == 0
      @pearls << { x: 30.0 + rand(SW - 60), y: 32.0 + rand(SH - 50), lit: 0.0, got: false }
    end
  end

  def spawn_boss
    @boss = {
      x: SW + 28.0, y: 128.0, tx: 260.0,
      hp: 24 + (@depth / 400) * 6, max_hp: 24 + (@depth / 400) * 6,
      lit: 100.0, fire_t: 50, hit_t: 0, phase: 0.0
    }
    @popups << { x: 160.0, y: 70.0, text: "WARNING: ABYSS KRAKEN!", col: 8, life: 70 }
  end

  def burst(x, y, cnt, col, spd = 2.4)
    cnt.times do
      a = rand * 6.28
      v = (0.3 + rand * 0.7) * spd
      @particles << { x: x, y: y, vx: cos(a) * v, vy: sin(a) * v, life: 16 + rand(12), max_life: 28, col: col, r: 1.5 + rand * 2.0 }
    end
  end

  def update
    @frame += 1

    if @state == :title
      if @frame % 75 == 0
        @sonars << { x: 160.0, y: 120.0, r: 8.0, max_r: 130.0 }
      end
      @sonars.each { |s| s[:r] += 2.2 }
      @sonars.reject! { |s| s[:r] >= s[:max_r] }
      if @frame > 5 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        reset_game
        @state = :play
      end
      return
    end

    if @state == :gameover
      update_fx
      if btnp(4) || btnp(5) || btnp(:mouse_l)
        reset_game
        @state = :play
      end
      return
    end

    @depth += 1 if @frame % 4 == 0
    @inv -= 1 if @inv > 0
    @sonar_cd -= 1 if @sonar_cd > 0
    @torp_cd -= 1 if @torp_cd > 0
    @flash -= 1 if @flash > 0
    @shake *= 0.85

    # 移動
    ax = 0.0
    ay = 0.0
    ax -= 1.0 if btn(0)
    ax += 1.0 if btn(1)
    ay -= 1.0 if btn(2)
    ay += 1.0 if btn(3)
    @facing_left = true if ax < 0.0
    @facing_left = false if ax > 0.0

    @vx = (@vx + ax * 0.35) * 0.86
    @vy = (@vy + ay * 0.35) * 0.86
    @px = (@px + @vx).clamp(14.0, SW - 14.0)
    @py = (@py + @vy).clamp(28.0, SH - 14.0)

    if @frame % 10 == 0
      @particles << { x: @px, y: @py, vx: (rand - 0.5) * 0.3, vy: -0.6, life: 24, max_life: 24, col: 12, r: 1.2 }
    end

    # ソナー照射 (Z / 左クリック)
    if (btnp(4) || btnp(:mouse_l)) && @sonar_cd <= 0
      @sonar_cd = 22
      @sonars << { x: @px, y: @py, r: 8.0, max_r: 155.0 }
    end

    # 魚雷発射 (X / 右クリック)
    if (btnp(5) || btnp(:mouse_r)) && @torp_cd <= 0
      @torp_cd = 12
      dir = @facing_left ? -1.0 : 1.0
      @torps << { x: @px + dir * 10.0, y: @py + 2.0, vx: dir * 4.5, life: 75 }
    end

    # ソナー波紋判定
    @sonars.each do |sn|
      sn[:r] += 3.6
      @monsters.each do |m|
        d = sqrt((m[:x] - sn[:x]) ** 2 + (m[:y] - sn[:y]) ** 2)
        m[:lit] = 140.0 if (d - sn[:r]).abs < 12.0
      end
      @pearls.each do |pr|
        d = sqrt((pr[:x] - sn[:x]) ** 2 + (pr[:y] - sn[:y]) ** 2)
        pr[:lit] = 160.0 if (d - sn[:r]).abs < 12.0
      end
      if @boss
        d = sqrt((@boss[:x] - sn[:x]) ** 2 + (@boss[:y] - sn[:y]) ** 2)
        @boss[:lit] = 150.0 if (d - sn[:r]).abs < 20.0
      end
    end
    @sonars.reject! { |sn| sn[:r] >= sn[:max_r] }

    # サーチライト常時照射
    @monsters.each do |m|
      m[:lit] = [m[:lit], 55.0].max if point_in_light?(m[:x], m[:y])
    end
    @pearls.each do |pr|
      pr[:lit] = [pr[:lit], 55.0].max if point_in_light?(pr[:x], pr[:y])
    end

    # 魚雷更新
    @torps.each do |tp|
      tp[:x] += tp[:vx]
      tp[:life] -= 1
      @monsters.each do |m|
        next unless m[:alive]
        if (tp[:x] - m[:x]) ** 2 + (tp[:y] - m[:y]) ** 2 < 14.0 * 14.0
          dmg = m[:lit] > 10.0 ? 2 : 1
          m[:hp] -= dmg
          tp[:life] = 0
          if m[:hp] <= 0
            m[:alive] = false
            pts = dmg == 2 ? 200 : 100
            @score += pts
            $abyss2_best = @score if @score > $abyss2_best
            @shake = 3.5
            burst(m[:x], m[:y], 14, dmg == 2 ? 10 : 8, 2.8)
            @popups << { x: m[:x], y: m[:y] - 6.0, text: dmg == 2 ? "CRIT +200" : "+100", col: dmg == 2 ? 10 : 7, life: 26 }
          else
            burst(tp[:x], tp[:y], 5, 7, 1.5)
          end
          break
        end
      end
      if @boss && tp[:life] > 0
        if (@boss[:x] - tp[:x]).abs < 18.0 && (@boss[:y] - tp[:y]).abs < 18.0
          dmg = @boss[:lit] > 10.0 ? 2 : 1
          @boss[:hp] -= dmg
          @boss[:hit_t] = 5
          tp[:life] = 0
          burst(tp[:x], tp[:y], 6, dmg == 2 ? 10 : 8, 2.0)
          if @boss[:hp] <= 0
            @score += 1200
            $abyss2_best = @score if @score > $abyss2_best
            @shake = 7.5
            @flash = 6
            burst(@boss[:x], @boss[:y], 30, 14, 3.6)
            @popups << { x: @boss[:x], y: @boss[:y] - 10.0, text: "KRAKEN SLAIN +1200", col: 10, life: 45 }
            @boss = nil
            @next_boss_depth = @depth + 500
            @hp = [@hp + 1, @max_hp].min
          end
        end
      end
    end
    @torps.reject! { |tp| tp[:life] <= 0 || tp[:x] < -16 || tp[:x] > SW + 16 }

    # 敵・ボス出現
    if @boss.nil?
      if @depth >= @next_boss_depth
        spawn_boss
      else
        @spawn_cd -= 1
        if @spawn_cd <= 0
          spawn_monster
          @spawn_cd = [46 - @depth / 120, 20].max
        end
      end
    else
      b = @boss
      b[:phase] += 0.04
      b[:x] += (b[:tx] - b[:x]) * 0.04
      b[:y] = 128.0 + sin(b[:phase]) * 68.0
      b[:lit] -= 1.0 if b[:lit] > 0.0
      b[:hit_t] -= 1 if b[:hit_t] > 0
      b[:fire_t] -= 1
      if b[:fire_t] <= 0
        b[:fire_t] = 48
        (-1..1).each do |i|
          ang = atan2(@py - b[:y], @px - b[:x]) + i * 0.28
          @ebullets << { x: b[:x] - 12.0, y: b[:y], vx: cos(ang) * 2.1, vy: sin(ang) * 2.1 }
        end
      end
    end

    # 敵更新
    @monsters.each do |m|
      next unless m[:alive]
      m[:lit] -= 1.0 if m[:lit] > 0.0
      if m[:kind] == :angler
        d = sqrt((@px - m[:x]) ** 2 + (@py - m[:y]) ** 2)
        if d > 1.0 && d < 105.0
          m[:x] += (@px - m[:x]) / d * 0.7
          m[:y] += (@py - m[:y]) / d * 0.7
        else
          m[:x] += m[:vx]
        end
      else
        m[:x] += m[:vx]
        m[:y] += m[:vy]
      end

      if @inv <= 0 && ((m[:x] - @px) ** 2 + (m[:y] - @py) ** 2 < 13.0 * 13.0)
        m[:alive] = false
        damage_player
      end
    end
    @monsters.reject! { |m| !m[:alive] || m[:x] < -32.0 || m[:x] > SW + 32.0 }

    # 敵弾更新
    @ebullets.each do |eb|
      eb[:x] += eb[:vx]
      eb[:y] += eb[:vy]
      if @inv <= 0 && ((eb[:x] - @px) ** 2 + (eb[:y] - @py) ** 2 < 10.0 * 10.0)
        eb[:x] = -99.0
        damage_player
      end
    end
    @ebullets.reject! { |eb| eb[:x] < -16 || eb[:x] > SW + 16 || eb[:y] < 0 || eb[:y] > SH }

    # 真珠回収
    @pearls.each do |pr|
      next if pr[:got]
      pr[:lit] -= 1.0 if pr[:lit] > 0.0
      if (pr[:x] - @px) ** 2 + (pr[:y] - @py) ** 2 < 14.0 * 14.0
        pr[:got] = true
        @score += 150
        $abyss2_best = @score if @score > $abyss2_best
        burst(pr[:x], pr[:y], 10, 14, 2.2)
        @popups << { x: pr[:x], y: pr[:y] - 6.0, text: "PEARL +150", col: 14, life: 28 }
      end
    end
    @pearls.reject! { |pr| pr[:got] }

    update_fx
  end

  def damage_player
    @hp -= 1
    @inv = 50
    @shake = 5.5
    @flash = 5
    burst(@px, @py, 16, 8, 3.0)
    @state = :gameover if @hp <= 0
  end

  def update_fx
    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }
    @popups.each do |pp|
      pp[:y] -= 0.5
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }
  end

  def draw
    cls(0)
    sx = @shake > 0.2 ? (rand * 2.0 - 1.0) * @shake : 0.0
    sy = @shake > 0.2 ? (rand * 2.0 - 1.0) * @shake : 0.0
    camera(sx, sy)

    bg(:cave, 0, 0, dim: 0.58, tint: [55, 110, 195], scroll_x: @frame * 0.12, mirror_x: true)

    # 乗算モードで漆黒の深海暗闇を作る
    blend(:mul)
    rectfill(0, 0, SW, SH, 1, 0.84)
    blend(:normal)

    # ソナー波紋（alphaフェードアウト）
    blend(:add)
    @sonars.each do |sn|
      al = 1.0 - (sn[:r] / sn[:max_r])
      circ(sn[:x], sn[:y], sn[:r], 12, al * 0.9)
      circ(sn[:x], sn[:y], sn[:r] - 2.0, 7, al * 0.35) if sn[:r] > 4.0
    end
    blend(:normal)

    # 真珠（ソナーで照らされると半透明フェード表示）
    @pearls.each do |pr|
      next if pr[:got]
      if pr[:lit] > 0.0
        al = (pr[:lit] / 55.0).clamp(0.15, 1.0)
        circfill(pr[:x], pr[:y], 4.0, 14, al)
        circfill(pr[:x] - 1, pr[:y] - 1, 1.5, 7, al)
      end
    end

    # 海獣（ソナー/ライトで半透明フェード表示、未発見時は微かな赤い目のみ）
    @monsters.each do |m|
      if m[:lit] > 0.0
        al = (m[:lit] / 60.0).clamp(0.2, 1.0)
        sp = m[:kind] == :mine ? :mine : (m[:kind] == :squid ? :squid : :angler)
        spr(sp, m[:x] - 8, m[:y] - 8, m[:vx] < 0, nil, 0.0, 1.0, al)
        circ(m[:x], m[:y], 10, 12, al * 0.6) if @frame % 10 < 5
      else
        circfill(m[:x], m[:y], 1.5, m[:kind] == :mine ? 2 : 8, 0.55)
      end
    end

    # 巨大クラーケンボス
    if @boss
      b = @boss
      al = b[:lit] > 0.0 ? (b[:lit] / 60.0).clamp(0.35, 1.0) : 0.3
      spr(:kraken, b[:x] - 16, b[:y] - 16, false, b[:hit_t] > 0 ? 11 : nil, 0.0, 1.0, al)
    end

    # 敵弾
    blend(:add)
    @ebullets.each do |eb|
      circfill(eb[:x], eb[:y], 4.0, 8, 0.55)
      circfill(eb[:x], eb[:y], 2.0, 10, 0.95)
    end
    blend(:normal)

    # 魚雷（加算トレイル付き）
    @torps.each do |tp|
      blend(:add)
      tail = tp[:vx] > 0 ? -10.0 : 10.0
      line(tp[:x], tp[:y], tp[:x] + tail, tp[:y], 12, 3, 0.5)
      blend(:normal)
      rectfill(tp[:x] - 3, tp[:y] - 1, 6, 3, 10)
    end

    # 自機サーチライト（trifill + blend(:add)）
    if @state != :gameover
      dir_x = @facing_left ? -1.0 : 1.0
      blend(:add)
      trifill(@px + dir_x * 6.0, @py, @px + dir_x * 115.0, @py - 46.0, @px + dir_x * 115.0, @py + 46.0, 12, 0.24)
      trifill(@px + dir_x * 6.0, @py, @px + dir_x * 80.0, @py - 24.0, @px + dir_x * 80.0, @py + 24.0, 7, 0.14)
      blend(:normal)

      if @inv <= 0 || (@inv / 3) % 2 == 0
        spr(:sub, @px - 8, @py - 8, @facing_left)
      end
    end

    # パーティクル & ポップアップ
    blend(:add)
    @particles.each do |p|
      al = p[:life].to_f / p[:max_life]
      circfill(p[:x], p[:y], p[:r], p[:col], al)
    end
    if @flash > 0
      rectfill(0, 0, SW, SH, 7, @flash * 0.06)
    end
    blend(:normal)

    @popups.each do |pp|
      print_text(pp[:text], pp[:x] - pp[:text].length * 3, pp[:y], pp[:col], 8)
    end

    camera()
    draw_hud
  end

  def draw_hud
    rectfill(0, 0, SW, 20, 0, 0.8)
    line(0, 20, SW, 20, 12, 1, 0.6)
    print_text(format("SCORE %06d", @score), 8, 6, 7, 8)
    print_text(format("DEPTH %dm", @depth), 110, 6, 12, 8)
    print_text("HP", 190, 6, 8, 8)
    @max_hp.times do |i|
      rectfill(208 + i * 10, 6, 8, 8, i < @hp ? 11 : 5)
    end
    print_text(format("HI:%d", $abyss2_best), 266, 6, 10, 8)

    if @boss
      bw = 140
      bx = (SW - bw) / 2
      rectfill(bx, 24, bw, 6, 0, 0.8)
      rectfill(bx, 24, (bw * (@boss[:hp].to_f / @boss[:max_hp])).to_i, 6, 14)
      rect(bx, 24, bw, 6, 7)
    end

    if @state == :title
      rectfill(44, 52, 232, 132, 0, 0.85)
      rect(44, 52, 232, 132, 12, 2)
      print_text("ABYSS SONAR II", 104, 64, 12, 16)
      print_text("DEEP SEA SEARCHLIGHT & KRAKEN", 70, 88, 10, 8)
      print_text("ARROWS/WASD : STEER & AIM LIGHT", 67, 110, 7, 8)
      print_text("Z / L-CLICK : SONAR PULSE (2x CRIT)", 55, 124, 12, 8)
      print_text("X / R-CLICK : TORPEDO", 67, 138, 10, 8)
      print_text("PRESS Z OR CLICK TO DIVE", 88, 162, 11, 8)
    elsif @state == :gameover
      rectfill(64, 76, 192, 88, 0, 0.88)
      rect(64, 76, 192, 88, 8, 2)
      print_text("HULL CRUSHED", 112, 88, 8, 16)
      print_text(format("SCORE: %06d  DEPTH: %dm", @score, @depth), 76, 114, 7, 8)
      print_text(format("BEST : %06d", $abyss2_best), 118, 128, 10, 8)
      print_text("PRESS Z OR CLICK TO RETRY", 85, 146, 11, 8)
    end
  end
end

run AbyssSonarII.new

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

@PALETTE 11
0: #FFFFFF
2: #FFFFFF
8: #FFFFFF
E: #FFFFFF

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

@SPRITE :kraken 32x32 pal:1
............00000000............
.........000EEEEEEEE000.........
.......00EEEEEEEEEEEEEE00.......
......0EEEE777EEEEEEEEEEE0......
.....0EEE77EEEEEEEEEEEEEEE0.....
....0EEEEEEEEEEEEEEEEEEEEEE0....
....0EEEEEE222EEEE222EEEEEE0....
...0EEEEEE277A2EE2A772EEEEEE0...
...0EEEEEE270A2EE2A072EEEEEE0...
...0EEEEEEE222EEEE222EEEEEEE0...
....0EEEEEEEEEEEEEEEEEEEEEE0....
....0EEE22EEEEEEEEEEEE22EEE0....
.....0EE2222EEEEEEEE2222EE0.....
......00EEEEEEEEEEEEEEEE00......
.......00EE00EEEEEE00EE00.......
......0EE00..0EEEE0..00EE0......
.....0EE0...0EE00EE0...0EE0.....
....0EE0...0EE0..0EE0...0EE0....
...0EE0....0E0....0E0....0EE0...
...0E0.....0E0....0E0.....0E0...
..0EE0....0EE0....0EE0....0EE0..
..0E0.....0E0......0E0.....0E0..
..00......00........00......00..
................................
................................
................................
................................
................................
................................
................................
................................
................................
