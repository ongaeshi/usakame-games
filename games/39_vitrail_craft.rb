# ==============================================================================
# 39. VITRAIL CRAFT
# ------------------------------------------------------------------------------
# 多角形の色ガラスを重ねて光の模様を創るステンドグラス幾何学パズル（全10図柄＋フリー）
# 256x256 / 1ファイル完結 / 基本API + bg() + マウス/キーボード
#
# 【操作方法】
#   マウス移動 / 矢印キー : ガラスピース選択
#   左クリック / Z(Space) : 色ガラスをはめる（色変更）
#   X             : パズル⇔フリーアート切替
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2,
  title: "39. VITRAIL CRAFT"
)

SW = 256
SH = 256
CX = 128.0
CY = 126.0

# 6色のステンドグラスパレット (0はクリアガラス)
GLASS_COLS = [5, 8, 10, 11, 12, 14]
GLASS_NAMES = ["CLR", "RED", "GLD", "EMR", "SAP", "AMT"]

def pt_in_poly?(px, py, pts)
  inside = false
  n = pts.size
  j = n - 1
  i = 0
  while i < n
    xi = pts[i][0]; yi = pts[i][1]
    xj = pts[j][0]; yj = pts[j][1]
    if ((yi > py) != (yj > py)) && (px < (xj - xi) * (py - yi) / (yj - yi + 0.00001) + xi)
      inside = !inside
    end
    j = i
    i += 1
  end
  inside
end

def poly_center(pts)
  sx = 0.0; sy = 0.0
  pts.each { |p| sx += p[0]; sy += p[1] }
  [sx / pts.size, sy / pts.size]
end

def make_ring_pattern(name, petals, r_in, r_mid, r_out, col_a, col_b, col_c)
  panes = []
  # 中央多角形
  c_pts = []
  petals.times do |i|
    a = i * Math::PI * 2.0 / petals
    c_pts << [CX + cos(a) * r_in, CY + sin(a) * r_in]
  end
  panes << { pts: c_pts, target: col_a, col: 0 }

  # 内輪 & 外輪ピース
  petals.times do |i|
    a0 = i * Math::PI * 2.0 / petals
    a1 = (i + 1) * Math::PI * 2.0 / petals
    am = (a0 + a1) * 0.5
    p0 = [CX + cos(a0) * r_in, CY + sin(a0) * r_in]
    p1 = [CX + cos(a1) * r_in, CY + sin(a1) * r_in]
    m0 = [CX + cos(a0) * r_mid, CY + sin(a0) * r_mid]
    m1 = [CX + cos(a1) * r_mid, CY + sin(a1) * r_mid]
    om = [CX + cos(am) * r_out, CY + sin(am) * r_out]
    panes << { pts: [p0, p1, m1, m0], target: (i % 2 == 0 ? col_b : col_c), col: 0 }
    panes << { pts: [m0, m1, om], target: (i % 2 == 0 ? col_c : col_b), col: 0 }
  end
  { name: name, panes: panes }
end

def make_diamond_pattern(name, col_a, col_b, col_c)
  panes = []
  # 中央ダイヤ
  panes << { pts: [[CX, CY - 34], [CX + 34, CY], [CX, CY + 34], [CX - 34, CY]], target: col_a, col: 0 }
  # 4隅ウィング
  [[-1, -1], [1, -1], [1, 1], [-1, 1]].each_with_index do |dir, i|
    dx = dir[0]; dy = dir[1]
    panes << {
      pts: [[CX, CY + dy * 34], [CX + dx * 34, CY], [CX + dx * 72, CY + dy * 72]],
      target: (i % 2 == 0 ? col_b : col_c), col: 0
    }
    panes << {
      pts: [[CX + dx * 34, CY], [CX + dx * 82, CY], [CX + dx * 72, CY + dy * 72]],
      target: (i % 2 == 0 ? col_c : col_b), col: 0
    }
  end
  { name: name, panes: panes }
end

def make_vitrail_patterns
  [
    make_ring_pattern("ROSE STAR", 6, 26.0, 58.0, 86.0, 2, 1, 5),
    make_diamond_pattern("DIAMOND CROWN", 2, 4, 1),
    make_ring_pattern("SUNBURST", 8, 22.0, 56.0, 88.0, 1, 2, 4),
    make_ring_pattern("LOTUS BLOOM", 5, 28.0, 62.0, 88.0, 5, 1, 3),
    make_diamond_pattern("SAPPHIRE CROSS", 4, 3, 5),
    make_ring_pattern("COMPASS ROSE", 4, 24.0, 52.0, 88.0, 2, 4, 1),
    make_ring_pattern("EMERALD HEX", 6, 32.0, 66.0, 88.0, 3, 4, 2),
    make_ring_pattern("PRISM OCTAGON", 8, 30.0, 60.0, 86.0, 5, 4, 3),
    make_ring_pattern("RUBY MANDALA", 10, 24.0, 54.0, 88.0, 1, 2, 5),
    make_ring_pattern("GRAND ROSETTE", 12, 22.0, 52.0, 88.0, 2, 1, 4)
  ]
end

class VitrailCraftGame
  def initialize
    @patterns = make_vitrail_patterns
    @state = :title
    @frame = 0
    @pat_idx = 0
    @sel_pane = 0
    @free_mode = false
    @complete_t = 0
    @sparks = []
    load_pattern(0)
  end

  def load_pattern(idx)
    @pat_idx = idx % @patterns.size
    pat = @patterns[@pat_idx]
    @panes = pat[:panes].map do |p|
      { pts: p[:pts], target: p[:target], col: 0, ctr: poly_center(p[:pts]) }
    end
    @sel_pane = 0
    @complete_t = 0
  end

  def cycle_pane(idx)
    return if idx < 0 || idx >= @panes.size
    p = @panes[idx]
    p[:col] = (p[:col] + 1) % GLASS_COLS.size
    c = p[:ctr]
    8.times do
      a = rand * 6.28
      @sparks << { x: c[0], y: c[1], vx: cos(a) * 1.5, vy: sin(a) * 1.5, life: 16, max_life: 16, col: GLASS_COLS[p[:col]] }
    end
    check_complete
  end

  def check_complete
    return if @free_mode
    all_ok = @panes.all? { |p| p[:col] == p[:target] }
    if all_ok && @complete_t == 0
      @complete_t = 1
      24.times do
        a = rand * 6.28
        @sparks << { x: CX, y: CY, vx: cos(a) * (1.5 + rand * 2.0), vy: sin(a) * (1.5 + rand * 2.0), life: 28, max_life: 28, col: [8, 10, 11, 12, 14][rand(5)] }
      end
    end
  end

  def update
    @frame += 1
    @sparks.each do |s|
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }

    if @state == :title
      if @frame > 5 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        @state = :play
        load_pattern(0)
      end
      return
    end

    if @complete_t > 0
      @complete_t += 1
      if @complete_t > 120 || (@complete_t > 20 && (btnp(1) || btnp(:mouse_l)))
        load_pattern(@pat_idx + 1)
      end
      return
    end

    @sel_pane = (@sel_pane - 1) % @panes.size if btnp(:left) || btnp(:up)
    @sel_pane = (@sel_pane + 1) % @panes.size if btnp(:right) || btnp(:down)

    if btnp(1)
      cycle_pane(@sel_pane)
    end

    if btnp(2)
      @free_mode = !@free_mode
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my < 22
        if mx < 56
          load_pattern(@pat_idx - 1)
        elsif mx > 200
          load_pattern(@pat_idx + 1)
        end
      elsif my > 230
        @free_mode = !@free_mode
      else
        @panes.each_with_index do |p, i|
          if pt_in_poly?(mx, my, p[:pts])
            @sel_pane = i
            cycle_pane(i)
            break
          end
        end
      end
    end
  end

  def draw
    cls(0)
    bg(:sky, 0, 0, dim: 0.65, scroll_x: @frame * 0.08, loop_x: true)

    # タイトル画面では完成例をキラキラ表示
    if @state == :title
      draw_stained_glass(true)
      draw_light_shafts(0.8)
      rectfill(26, 74, 204, 108, 0, 0.84)
      rect(26, 74, 204, 108, 10, 2)
      print_text("VITRAIL CRAFT", 88, 86, 10)
      print_text("STAINED GLASS GEOMETRY PUZZLE", 41, 102, 7)
      print_text("CLICK / Z : PAINT GLASS PANE", 44, 124, 12)
      print_text("X         : FREE ART MODE", 44, 138, 14)
      print_text("PRESS Z OR CLICK TO CREATE", 50, 160, 11)
      return
    end

    draw_stained_glass(false)

    if @complete_t > 0 || @free_mode
      draw_light_shafts(@complete_t > 0 ? 1.0 : 0.45)
    end

    # スパーク
    blend(:add)
    @sparks.each do |s|
      circfill(s[:x], s[:y], 2.2, s[:col], s[:life].to_f / s[:max_life])
    end
    blend(:normal)

    draw_hud
  end

  def draw_stained_glass(preview_target)
    # 外枠円
    circfill(CX, CY, 92, 0, 0.45)

    @panes.each_with_index do |p, i|
      c_idx = preview_target ? p[:target] : p[:col]
      col = GLASS_COLS[c_idx]
      al = c_idx == 0 ? 0.25 : 0.72
      polygonfill(p[:pts], col, al)

      # 鉛枠 (リード線)
      sel = (!preview_target && i == @sel_pane)
      poly(p[:pts], sel ? 7 : 0, sel ? 2 : 2)

      # パズルモード時、未一致ピースの中心に目標色ドットを表示
      if !preview_target && !@free_mode && p[:col] != p[:target]
        tcol = GLASS_COLS[p[:target]]
        circfill(p[:ctr][0], p[:ctr][1], 3.5, tcol, 0.95)
        circ(p[:ctr][0], p[:ctr][1], 4.0, 7, 0.7)
      end
    end

    circ(CX, CY, 92, 6, 0.8)
  end

  def draw_light_shafts(intensity)
    blend(:add)
    t = @frame * 0.025
    3.times do |i|
      ox = 40.0 + i * 70.0 + sin(t + i) * 24.0
      col = [10, 12, 14][i]
      quadfill(ox, 22, ox + 28, 22, ox + 96, 236, ox + 46, 236, col, 0.18 * intensity)
    end
    blend(:normal)
  end

  def draw_hud
    rectfill(0, 0, SW, 22, 0, 0.82)
    line(0, 22, SW, 22, 6, 1, 0.5)
    pat = @patterns[@pat_idx]
    print_text("< PREV", 6, 7, 6)
    print_text(format("%02d/10 %s", @pat_idx + 1, pat[:name]), 62, 7, 7)
    print_text("NEXT >", 214, 7, 6)

    rectfill(0, 232, SW, 24, 0, 0.82)
    matched = @panes.count { |p| p[:col] == p[:target] }
    if @free_mode
      print_text("MODE: FREE ART (X:PUZZLE)", 10, 240, 14)
    else
      print_text(format("MATCH: %d/%d", matched, @panes.size), 10, 240, matched == @panes.size ? 11 : 10)
      print_text("X:FREE MODE", 180, 240, 6)
    end

    if @complete_t > 0
      rectfill(42, 104, 172, 42, 0, 0.86)
      rect(42, 104, 172, 42, 10, 2)
      print_text("VITRAIL COMPLETE!", 77, 114, 10)
      print_text("CLICK OR Z FOR NEXT", 71, 130, 7)
    end
  end
end

run VitrailCraftGame.new
