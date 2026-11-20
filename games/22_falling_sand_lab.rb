# ==============================================================================
# 22. FALLING SAND LAB
# ------------------------------------------------------------------------------
# 砂・水・火・木・爆薬・酸が連鎖反応する落ち砂物理ラボ
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   マウスドラッグ / Z : 選択した素材を配置
#   下部パレット / ← → : 素材切替 (SAND/WATER/WOOD/FIRE/TNT/ACID/STONE)
#   X                  : デモシーン再構築
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "22. FALLING SAND LAB"
)

GW = 64
GH = 54
CELL = 4
OY = 20

E_EMPTY = 0
E_SAND  = 1
E_WATER = 2
E_WOOD  = 3
E_FIRE  = 4
E_TNT   = 5
E_ACID  = 6
E_STONE = 7

ELEM_INFO = [
  { id: E_SAND,  name: "SAND",  col: 10 },
  { id: E_WATER, name: "WATR",  col: 12 },
  { id: E_WOOD,  name: "WOOD",  col: 4 },
  { id: E_FIRE,  name: "FIRE",  col: 9 },
  { id: E_TNT,   name: "TNT",   col: 8 },
  { id: E_ACID,  name: "ACID",  col: 11 },
  { id: E_STONE, name: "STON",  col: 6 },
  { id: E_EMPTY, name: "ERAS",  col: 5 }
]

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
    bg(:training, dim: 0.65, tint: [110, 130, 160])

    # 落下する砂デモ
    i = 0
    while i < 16
      sx = 96 + (i * 4)
      sy = 152 + ((@t + i * 7) % 48)
      rectfill(sx, sy, 3, 3, i % 3 == 0 ? 10 : (i % 3 == 1 ? 12 : 9))
      i += 1
    end

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 10)
    print_text("FALLING SAND LAB", 80, 32, 10)
    print_text("CELLULAR AUTOMATA PHYSICS TOY", 41, 46, 12)

    rectfill(24, 78, 208, 60, 0)
    rect(24, 78, 208, 60, 5)
    print_text("DRAG MOUSE / Z : PAINT ELEMENTS", 34, 88, 7)
    print_text("MIX FIRE + TNT + WATER + ACID!", 34, 102, 9)
    print_text("X              : RESET DEMO", 34, 116, 12)

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO EXPERIMENT", 38, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @sel = 0
    @brush = 1
    @grid = Array.new(GW * GH, E_EMPTY)
    @updated = Array.new(GW * GH, 0)
    @step_id = 1
    setup_demo
  end

  def setup_demo
    @grid = Array.new(GW * GH, E_EMPTY)
    # 石のボウル & 木の橋 & 砂・水・TNT
    x = 12
    while x <= 52
      set_cell(x, 46, E_STONE)
      set_cell(x, 26, E_WOOD) if x >= 18 && x <= 46
      x += 1
    end
    y = 32
    while y <= 46
      set_cell(12, y, E_STONE)
      set_cell(52, y, E_STONE)
      y += 1
    end
    # 上から砂と水
    x = 22
    while x <= 42
      set_cell(x, 8, E_SAND)
      set_cell(x, 12, E_WATER)
      x += 2
    end
    set_cell(32, 24, E_TNT)
    set_cell(33, 24, E_TNT)
  end

  def get_cell(x, y)
    return E_STONE if x < 0 || x >= GW || y < 0 || y >= GH
    @grid[y * GW + x]
  end

  def set_cell(x, y, val)
    return if x < 0 || x >= GW || y < 0 || y >= GH
    @grid[y * GW + x] = val
    @updated[y * GW + x] = @step_id
  end

  def swap_cells(x1, y1, x2, y2)
    i1 = y1 * GW + x1
    i2 = y2 * GW + x2
    tmp = @grid[i1]
    @grid[i1] = @grid[i2]
    @grid[i2] = tmp
    @updated[i1] = @step_id
    @updated[i2] = @step_id
  end

  def explode(cx, cy)
    dy = -4
    while dy <= 4
      dx = -4
      while dx <= 4
        if dx * dx + dy * dy <= 18
          nx = cx + dx; ny = cy + dy
          if nx >= 0 && nx < GW && ny >= 0 && ny < GH
            v = get_cell(nx, ny)
            set_cell(nx, ny, rand(3) == 0 ? E_FIRE : E_EMPTY) if v != E_STONE
          end
        end
        dx += 1
      end
      dy += 1
    end
  end

  def step_sim
    @step_id += 1
    y = GH - 1
    while y >= 0
      left_first = (@t + y) % 2 == 0
      i = 0
      while i < GW
        x = left_first ? i : (GW - 1 - i)
        idx = y * GW + x
        if @updated[idx] == @step_id
          i += 1
          next
        end
        e = @grid[idx]
        if e == E_SAND
          b = get_cell(x, y + 1)
          if b == E_EMPTY || b == E_WATER || b == E_ACID
            swap_cells(x, y, x, y + 1)
          else
            d = rand(2) == 0 ? -1 : 1
            if get_cell(x + d, y + 1) == E_EMPTY || get_cell(x + d, y + 1) == E_WATER
              swap_cells(x, y, x + d, y + 1)
            elsif get_cell(x - d, y + 1) == E_EMPTY || get_cell(x - d, y + 1) == E_WATER
              swap_cells(x, y, x - d, y + 1)
            end
          end
        elsif e == E_WATER
          if get_cell(x, y + 1) == E_EMPTY
            swap_cells(x, y, x, y + 1)
          else
            d = rand(2) == 0 ? -1 : 1
            if get_cell(x + d, y + 1) == E_EMPTY
              swap_cells(x, y, x + d, y + 1)
            elsif get_cell(x - d, y + 1) == E_EMPTY
              swap_cells(x, y, x - d, y + 1)
            elsif get_cell(x + d, y) == E_EMPTY
              swap_cells(x, y, x + d, y)
            elsif get_cell(x - d, y) == E_EMPTY
              swap_cells(x, y, x - d, y)
            end
          end
        elsif e == E_FIRE
          if rand(14) == 0
            set_cell(x, y, E_EMPTY)
          else
            # 周囲の燃焼・爆発
            [[0, 1], [0, -1], [1, 0], [-1, 0]].each do |dd|
              nx = x + dd[0]; ny = y + dd[1]
              nb = get_cell(nx, ny)
              if nb == E_TNT
                explode(nx, ny)
              elsif nb == E_WOOD && rand(8) == 0
                set_cell(nx, ny, E_FIRE)
              elsif nb == E_WATER
                set_cell(x, y, E_EMPTY)
              end
            end
            if get_cell(x, y - 1) == E_EMPTY && rand(3) != 0
              swap_cells(x, y, x, y - 1)
            end
          end
        elsif e == E_ACID
          if get_cell(x, y + 1) == E_EMPTY
            swap_cells(x, y, x, y + 1)
          else
            b = get_cell(x, y + 1)
            if b != E_EMPTY && b != E_STONE && b != E_ACID && rand(5) == 0
              set_cell(x, y + 1, E_EMPTY)
              set_cell(x, y, E_EMPTY) if rand(2) == 0
            else
              d = rand(2) == 0 ? -1 : 1
              swap_cells(x, y, x + d, y) if get_cell(x + d, y) == E_EMPTY
            end
          end
        end
        i += 1
      end
      y -= 1
    end
  end

  def paint_at(gx, gy, elem)
    dy = -@brush
    while dy <= @brush
      dx = -@brush
      while dx <= @brush
        set_cell(gx + dx, gy + dy, elem)
        dx += 1
      end
      dy += 1
    end
  end

  def update
    @t += 1
    @sel = (@sel - 1) % ELEM_INFO.size if btnp(0)
    @sel = (@sel + 1) % ELEM_INFO.size if btnp(1)
    setup_demo if btnp(5)

    if btn(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 236
        i = 0
        while i < ELEM_INFO.size
          bx = i * 32
          if mx >= bx && mx < bx + 32
            @sel = i
          end
          i += 1
        end
      elsif my >= OY && my < OY + GH * CELL
        gx = mx / CELL
        gy = (my - OY) / CELL
        paint_at(gx, gy, ELEM_INFO[@sel][:id])
      end
    elsif btn(4)
      paint_at(GW / 2 + rand(-4..4), 6, ELEM_INFO[@sel][:id])
    end

    step_sim
  end

  def draw
    cls(0)

    # グリッド描画
    y = 0
    while y < GH
      x = 0
      while x < GW
        e = @grid[y * GW + x]
        if e != E_EMPTY
          col = e == E_SAND ? 10 :
                e == E_WATER ? 12 :
                e == E_WOOD ? 4 :
                e == E_FIRE ? (rand(2) == 0 ? 8 : 9) :
                e == E_TNT ? 14 :
                e == E_ACID ? 11 : 6
          rectfill(x * CELL, OY + y * CELL, CELL, CELL, col)
        end
        x += 1
      end
      y += 1
    end

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("SAND LAB", 6, 6, 10)
    print_text("TOOL: #{ELEM_INFO[@sel][:name]}", 76, 6, ELEM_INFO[@sel][:col])
    print_text("[X] RESET", 194, 6, 12)

    # 下部パレット
    rectfill(0, 236, 256, 20, 0)
    line(0, 236, 256, 236, 5)
    i = 0
    while i < ELEM_INFO.size
      el = ELEM_INFO[i]
      bx = i * 32
      sel = (i == @sel)
      rectfill(bx + 1, 238, 30, 16, sel ? 1 : 0)
      rect(bx + 1, 238, 30, 16, sel ? 7 : el[:col])
      print_text(el[:name], bx + 4, 242, el[:col])
      i += 1
    end
  end
end

run TitleScene.new
