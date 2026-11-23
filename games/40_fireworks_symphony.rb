# ==============================================================================
# 40. FIREWORKS SYMPHONY DX
# ------------------------------------------------------------------------------
# 【26進化版】加算発光・滑らか減衰・大会演出を備えたワイド夜空の花火師
# 480x270 / 1ファイル完結 / 基本API + bg() + マウス/キーボード
#
# 【操作方法】
#   夜空をクリック / Z : 指定位置へ花火打ち上げ！
#   ← / → / 下部ボタン : 花火の種類切替 (菊/柳/ハート/土星/星/連発)
#   X / Enter          : シンフォニー大会モード切替
# ==============================================================================

config(
  width: 480,
  height: 270,
  scale: 2,
  title: "40. FIREWORKS SYMPHONY DX"
)

SW = 480
SH = 270
WATER_Y = 202.0

SHELLS = [
  { id: :kiku,     name: "KIKU",     col: 10 },
  { id: :yanagi,   name: "YANAGI",   col: 9  },
  { id: :heart,    name: "HEART",    col: 14 },
  { id: :saturn,   name: "SATURN",   col: 12 },
  { id: :star,     name: "STAR",     col: 11 },
  { id: :symphony, name: "SYMPHONY", col: 8  }
]

FW_COLS = [8, 9, 10, 11, 12, 14]

class FireworksSymphonyDX
  def initialize
    @state = :title
    @frame = 0
    @sel = 0
    @auto = true
    @launched = 0
    @rockets = []
    @sparks = []
    @flash = 0.0
    @program_step = 0
    launch_shell(240.0, 86.0, 0)
  end

  def launch_shell(tx, ty, kind_idx)
    @launched += 1
    if kind_idx == 5
      5.times do |i|
        rx = 72.0 + i * 84.0
        ry = 62.0 + (i % 2) * 28.0 + rand * 16.0
        @rockets << {
          x: rx, y: WATER_Y, ty: ry, vy: -4.8 - rand * 0.6,
          kind: i % 5, col: FW_COLS[(i + rand(3)) % FW_COLS.size], trail: []
        }
      end
    else
      col = FW_COLS[rand(FW_COLS.size)]
      col = 14 if kind_idx == 2
      col = 10 if kind_idx == 1
      @rockets << { x: tx, y: WATER_Y, ty: ty, vy: -4.9, kind: kind_idx, col: col, trail: [] }
    end
  end

  def detonate(rk)
    @flash = [0.22, @flash + 0.14].min
    x = rk[:x]
    y = rk[:y]
    col = rk[:col]
    col2 = FW_COLS[rand(FW_COLS.size)]
    col2 = 7 if col == col2

    case rk[:kind]
    when 0 # 菊 (二重菊)
      40.times do |i|
        a = i * Math::PI * 2.0 / 40.0
        spd = 1.9 + (i % 2) * 1.1
        @sparks << make_spark(x, y, cos(a) * spd, sin(a) * spd, i % 2 == 0 ? col : col2, 0.032, 48, 2.2)
      end
      20.times do |i|
        a = i * Math::PI * 2.0 / 20.0
        @sparks << make_spark(x, y, cos(a) * 1.1, sin(a) * 1.1, 7, 0.025, 36, 1.6)
      end
    when 1 # 柳 (金色しだれ)
      36.times do |i|
        a = i * Math::PI * 2.0 / 36.0
        spd = 1.3 + rand * 1.4
        @sparks << make_spark(x, y, cos(a) * spd, sin(a) * spd - 0.5, i % 3 == 0 ? 9 : 10, 0.048, 72, 1.8)
      end
    when 2 # ハート
      32.times do |i|
        t = i * Math::PI * 2.0 / 32.0
        hx = 16.0 * (sin(t) ** 3)
        hy = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
        @sparks << make_spark(x, y, hx * 0.15, hy * 0.15, i % 2 == 0 ? 14 : 8, 0.022, 52, 2.2)
      end
    when 3 # 土星 (コア＋斜めリング)
      24.times do |i|
        a = i * Math::PI * 2.0 / 24.0
        @sparks << make_spark(x, y, cos(a) * 1.4, sin(a) * 1.4, col, 0.028, 44, 2.0)
      end
      28.times do |i|
        a = i * Math::PI * 2.0 / 28.0
        rx = cos(a) * 3.0
        ry = sin(a) * 0.85
        # 25度傾ける
        vx = rx * 0.9 - ry * 0.42
        vy = rx * 0.42 + ry * 0.9
        @sparks << make_spark(x, y, vx, vy, 10, 0.024, 48, 1.8)
      end
    when 4 # 5芒星
      5.times do |p|
        a0 = p * Math::PI * 2.0 / 5.0 - Math::PI / 2.0
        a1 = (p + 2) * Math::PI * 2.0 / 5.0 - Math::PI / 2.0
        x0 = cos(a0) * 2.8; y0 = sin(a0) * 2.8
        x1 = cos(a1) * 2.8; y1 = sin(a1) * 2.8
        6.times do |k|
          f = k / 6.0
          @sparks << make_spark(x, y, x0 + (x1 - x0) * f, y0 + (y1 - y0) * f, col, 0.024, 48, 2.0)
        end
      end
    end
  end

  def make_spark(x, y, vx, vy, col, grav, life, r)
    { x: x, y: y, vx: vx, vy: vy, col: col, grav: grav, life: life, max_life: life, r: r, trail: [] }
  end

  def update
    @frame += 1
    @flash *= 0.86

    # ロケット更新
    @rockets.each do |rk|
      rk[:trail] << [rk[:x], rk[:y]]
      rk[:trail].shift if rk[:trail].size > 8
      rk[:y] += rk[:vy]
      rk[:vy] *= 0.985
      if rk[:y] <= rk[:ty] || rk[:vy] >= -0.8
        rk[:dead] = true
        detonate(rk)
      end
    end
    @rockets.reject! { |rk| rk[:dead] }

    # 火花更新
    @sparks.each do |s|
      s[:trail] << [s[:x], s[:y]] if @frame % 2 == 0
      s[:trail].shift if s[:trail].size > 6
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:vy] += s[:grav]
      s[:vx] *= 0.975
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }

    if @state == :title
      if @frame % 42 == 0
        launch_shell(90.0 + rand * 300.0, 56.0 + rand * 64.0, rand(5))
      end
      if @frame > 5 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        @state = :play
      end
      return
    end

    # シンフォニー大会モード自動打ち上げ
    if @auto && @frame % 38 == 0
      @program_step += 1
      if @program_step % 6 == 0
        launch_shell(240.0, 76.0, 5) # 定期的な5連発フィナーレ！
      else
        launch_shell(60.0 + rand * 360.0, 48.0 + rand * 82.0, @program_step % 5)
      end
    end

    @sel = (@sel - 1) % SHELLS.size if btnp(0)
    @sel = (@sel + 1) % SHELLS.size if btnp(1)
    @auto = !@auto if btnp(5)

    if btnp(4)
      launch_shell(80.0 + rand * 320.0, 52.0 + rand * 78.0, @sel)
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 238
        # 下部ボタン判定
        if mx >= 398
          @auto = !@auto
        else
          bw = 62
          idx = ((mx - 8) / (bw + 4)).to_i
          @sel = idx if idx >= 0 && idx < SHELLS.size
        end
      elsif my > 22 && my < WATER_Y
        launch_shell(mx.to_f, my.to_f.clamp(32.0, WATER_Y - 30.0), @sel)
      end
    end
  end

  def draw
    cls(0)
    bg(:city, 0, 0, dim: 0.48, tint: [120, 150, 220])

    # 夜空の打ち上げフラッシュ
    if @flash > 0.02
      blend(:add)
      rectfill(0, 0, SW, WATER_Y, 12, @flash * 0.35)
      blend(:normal)
    end

    # 港の水面ベース
    rectfill(0, WATER_Y, SW, SH - WATER_Y, 1, 0.85)
    line(0, WATER_Y, SW, WATER_Y, 12, 1, 0.7)

    # ロケット・火花・水面反射 (すべて加算合成！)
    blend(:add)
    @rockets.each do |rk|
      polyline(rk[:trail], rk[:col], 2, 0.75) if rk[:trail].size >= 2
      circfill(rk[:x], rk[:y], 3.0, 7, 0.95)
    end

    @sparks.each do |s|
      al = s[:life].to_f / s[:max_life]
      if s[:trail].size >= 2
        polyline(s[:trail], s[:col], 2, al * 0.55)
      end
      # 加算グロー + 白芯
      circfill(s[:x], s[:y], s[:r] * 2.2, s[:col], al * 0.35)
      circfill(s[:x], s[:y], s[:r] * 0.7, 7, al * 0.9)

      # 港の水面リアルタイム反射（Y反転＆波揺らぎ）
      if s[:y] < WATER_Y
        ry = WATER_Y + (WATER_Y - s[:y]) * 0.32
        if ry < 236.0
          wave_x = sin(@frame * 0.14 + ry * 0.25) * 3.0
          circfill(s[:x] + wave_x, ry, s[:r] * 1.4, s[:col], al * 0.22)
        end
      end
    end
    blend(:normal)

    draw_ui
  end

  def draw_ui
    if @state == :title
      rectfill(96, 52, 288, 138, 0, 0.8)
      rect(96, 52, 288, 138, 10, 2)
      print_text("FIREWORKS SYMPHONY DX", 136, 66, 10, 16)
      print_text("ADDITIVE BLOOM & HARBOR REFLECTION", 138, 90, 12, 8)
      print_text("CLICK SKY / Z : LAUNCH FIREWORK", 147, 114, 7, 8)
      print_text("X             : SYMPHONY AUTO SHOW", 147, 128, 14, 8)
      print_text("PRESS Z OR CLICK TO BEGIN SHOW", 150, 158, 11, 8)
      return
    end

    # 上部HUD
    rectfill(0, 0, SW, 20, 0, 0.7)
    print_text("FIREWORKS SYMPHONY DX", 8, 6, 10, 8)
    print_text(format("SHELLS LAUNCHED: %d", @launched), 192, 6, 7, 8)
    print_text(@auto ? "SHOW: AUTO ON" : "SHOW: MANUAL", 386, 6, @auto ? 11 : 6, 8)

    # 下部シェル選択バー
    rectfill(0, 236, SW, 34, 0, 0.85)
    line(0, 236, SW, 236, 5)
    SHELLS.each_with_index do |sh, i|
      bx = 8 + i * 64
      sel = (i == @sel)
      rectfill(bx, 242, 60, 22, sel ? 1 : 0)
      rect(bx, 242, 60, 22, sel ? sh[:col] : 5, sel ? 2 : 1)
      print_text(sh[:name], bx + 6, 249, sel ? 7 : 6, 8)
    end

    # AUTO切替ボタン
    rectfill(396, 242, 76, 22, @auto ? 3 : 0)
    rect(396, 242, 76, 22, @auto ? 11 : 6, 1)
    print_text(@auto ? "X:AUTO ON" : "X:MANUAL", 404, 249, 7, 8)
  end
end

run FireworksSymphonyDX.new
