# ==============================================================================
# 27. KALEIDOSCOPE BLOOM
# ------------------------------------------------------------------------------
# 8〜16軸対称で光の花が咲くジェネラティブ万華鏡アート
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   マウス移動 / ドラッグ : 対称曼荼羅アート描画!
#   ← / → / Z             : 対称軸数切替 (8 / 12 / 16軸)
#   ↑ / ↓                 : カラーテーマ切替 (NEON / SAKURA / GOLD / ABYSS)
#   X                     : オートブルーム切替
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "27. KALEIDOSCOPE BLOOM"
)

PALETTES = [
  { name: "NEON",   cols: [12, 14, 10, 7] },
  { name: "SAKURA", cols: [14, 8, 7, 15] },
  { name: "GOLD",   cols: [10, 9, 7, 8] },
  { name: "ABYSS",  cols: [11, 12, 3, 7] }
]
AXES_LIST = [8, 12, 16]

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
    bg(:space, dim: 0.55)

    # デモ万華鏡
    i = 0
    while i < 12
      ang = i * Math::PI * 2.0 / 12.0 + @t * 0.02
      r = 36.0 + sin(@t * 0.05) * 14.0
      cx = 128 + (cos(ang) * r).to_i
      cy = 166 + (sin(ang) * r).to_i
      circ(cx, cy, 8, i % 2 == 0 ? 12 : 14)
      i += 1
    end

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 14)
    print_text("KALEIDOSCOPE BLOOM", 74, 32, 10)
    print_text("SYMMETRIC MANDALA ART TOY", 50, 46, 12)

    rectfill(24, 78, 208, 56, 0)
    rect(24, 78, 208, 56, 5)
    print_text("MOUSE / AUTO : BLOOM PETALS", 42, 88, 7)
    print_text("LEFT / RIGHT : 8 / 12 / 16 AXES", 42, 101, 10)
    print_text("UP / DOWN    : COLOR PALETTES", 42, 114, 14)

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO BLOOM", 53, 224, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @axes_idx = 1
    @pal_idx = 0
    @auto = true
    @nodes = []
    @prev_mx = mouse_x
    @prev_my = mouse_y
  end

  def add_sym_node(r, ang, size, col)
    @nodes << { r: r, ang: ang, size: size, col: col, life: 135, max_life: 135 }
    @nodes.shift if @nodes.size > 140
  end

  def update
    @t += 1
    @axes_idx = (@axes_idx - 1) % AXES_LIST.size if btnp(:left)
    @axes_idx = (@axes_idx + 1) % AXES_LIST.size if btnp(:right) || btnp(1)
    @pal_idx = (@pal_idx - 1) % PALETTES.size if btnp(:up)
    @pal_idx = (@pal_idx + 1) % PALETTES.size if btnp(:down)
    @auto = !@auto if btnp(2)

    pal = PALETTES[@pal_idx][:cols]
    mx = mouse_x
    my = mouse_y
    if (mx != @prev_mx || my != @prev_my) && my > 20 && my < 236
      dx = mx.to_f - 128.0
      dy = my.to_f - 128.0
      r = sqrt(dx * dx + dy * dy)
      ang = atan2(dy, dx)
      add_sym_node(r, ang, btn(:mouse_l) ? 4 : 2, pal[(@t / 6) % pal.size])
      @prev_mx = mx; @prev_my = my
    elsif @auto && @t % 2 == 0
      r = 18.0 + sin(@t * 0.045) * 44.0 + cos(@t * 0.023) * 28.0
      ang = @t * 0.04
      add_sym_node(r.abs, ang, (@t / 8) % 3 + 2, pal[(@t / 10) % pal.size])
    end

    @nodes.each { |n| n[:life] -= 1 }
    @nodes.reject! { |n| n[:life] <= 0 }
  end

  def draw
    cls(0)
    bg(:space, dim: 0.6)

    axes = AXES_LIST[@axes_idx]
    step_ang = Math::PI * 2.0 / axes
    rot_off = @t * 0.005

    @nodes.each do |n|
      sz = (n[:size] * n[:life].to_f / n[:max_life]).to_i
      i = 0
      while i < axes
        a1 = n[:ang] + i * step_ang + rot_off
        a2 = -n[:ang] + i * step_ang + rot_off
        x1 = 128 + (cos(a1) * n[:r]).to_i
        y1 = 128 + (sin(a1) * n[:r]).to_i
        x2 = 128 + (cos(a2) * n[:r]).to_i
        y2 = 128 + (sin(a2) * n[:r]).to_i
        if sz <= 1
          pset(x1, y1, n[:col])
          pset(x2, y2, n[:col])
        else
          circ(x1, y1, sz, n[:col])
          circ(x2, y2, sz, n[:col])
        end
        i += 1
      end
    end

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("AXES:#{axes}", 6, 6, 12)
    print_text("PAL:#{PALETTES[@pal_idx][:name]}", 86, 6, 10)
    print_text(@auto ? "AUTO:ON[X]" : "AUTO:OFF", 190, 6, @auto ? 11 : 6)
  end
end

run TitleScene.new
