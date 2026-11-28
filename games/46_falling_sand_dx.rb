config(
  title: "FALLING SAND LAB DX",
  width: 320,
  height: 240,
  save_id: "falling_sand_dx",
  save_salt: "p3g46f1b"
)

$cfg = {
  w: 320,
  h: 240,
  sim_w: 64,
  sim_h: 38,
  sim_y: 20,
  cell: 5,
  brush_min: 1,
  brush_max: 4
}

$elements = {
  sand: { name: "SAND", col: 10 },
  water: { name: "WATR", col: 12 },
  wood: { name: "WOOD", col: 4 },
  fire: { name: "FIRE", col: 9 },
  oil: { name: "OIL", col: 2 },
  acid: { name: "ACID", col: 11 },
  lava: { name: "LAVA", col: 8 },
  steam: { name: "STEM", col: 6 },
  tnt: { name: "TNT", col: 14 },
  stone: { name: "STON", col: 5 },
  erase: { name: "ERAS", col: 0 }
}

$elem_order = [:sand, :water, :wood, :fire, :oil, :acid, :lava, :steam, :tnt, :stone, :erase]

$puzzles = [
  { name: "1. SAND FUNNEL", tool: :sand, target_col: 10, goal: [25, 28, 14, 9], need: 35, desc: "GUIDE SAND INTO BEAKER" },
  { name: "2. WATER BRIDGE", tool: :wood, target_col: 12, goal: [44, 28, 14, 9], need: 30, desc: "BUILD WOOD CHANNEL FOR WATER" },
  { name: "3. BURN THE GATE", tool: :fire, target_col: 10, goal: [25, 28, 14, 9], need: 30, desc: "BURN WOOD GATE TO DROP SAND" },
  { name: "4. ACID BREACH", tool: :acid, target_col: 12, goal: [25, 28, 14, 9], need: 28, desc: "DISSOLVE STONE PLUG" },
  { name: "5. STEAM CONDENSE", tool: :lava, target_col: 6, goal: [25, 4, 14, 8], need: 16, desc: "BOIL WATER INTO UPPER BEAKER" },
  { name: "6. OIL INFERNO", tool: :oil, target_col: 9, goal: [44, 16, 14, 10], need: 15, desc: "POUR OIL & IGNITE FIRE" },
  { name: "7. OBSIDIAN FORGE", tool: :water, target_col: 5, goal: [25, 28, 14, 9], need: 22, desc: "COOL LAVA INTO STONE" },
  { name: "8. TNT EXCAVATION", tool: :tnt, target_col: 10, goal: [44, 28, 14, 9], need: 28, desc: "BLAST SAND INTO RIGHT CUP" },
  { name: "9. DUAL REACTION", tool: :sand, target_col: 10, goal: [44, 28, 14, 9], need: 35, desc: "FILL RIGHT CUP WITH SAND" },
  { name: "10. ALCHEMIST MASTER", tool: :acid, target_col: 12, goal: [25, 28, 14, 9], need: 35, desc: "CLEAR PATH FOR WATER" }
]

class TitleScene
  def initialize
    @cleared = save_get("cleared", [])
    @mode = 0 # 0: Sandbox, 1: Puzzle
    @puz_idx = 0
    @tick = 0
  end

  def update
    @tick += 1
    if btnp(:up) || btnp(:down)
      @mode = 1 - @mode
    end
    if @mode == 1
      @puz_idx = (@puz_idx - 1 + $puzzles.size) % $puzzles.size if btnp(:left)
      @puz_idx = (@puz_idx + 1) % $puzzles.size if btnp(:right)
    end
    if btnp(:mouse_l)
      my = mouse_y
      if my >= 104 && my <= 128
        @mode = 0
        run LabScene.new({ mode: :sandbox, puz_idx: 0 })
        return
      elsif my >= 134 && my <= 158
        @mode = 1
        run LabScene.new({ mode: :puzzle, puz_idx: @puz_idx })
        return
      end
    end
    if btnp(1) || btnp(2)
      run LabScene.new({ mode: @mode == 0 ? :sandbox : :puzzle, puz_idx: @puz_idx })
    end
  end

  def draw
    cls(0)
    bg(:training, dim: 0.58, tint: "#485878", scroll_x: @tick * 0.2, mirror_x: true)

    # Falling sand particles demo
    i = 0
    while i < 24
      sx = 70 + i * 8
      sy = 64 + ((@tick * 2 + i * 11) % 32)
      circfill(sx, sy, 2, i % 3 == 0 ? 10 : (i % 3 == 1 ? 12 : 8))
      i += 1
    end

    print_text("FALLING SAND LAB DX", 160, 22, 10, 16, 1.0, :center, 0, 2)
    print_text("10-ELEMENT PIXEL SIM & PUZZLES", 160, 48, 7, 8, 1.0, :center, 0)
    print_text("PUZZLES CLEARED: #{@cleared.size}/#{$puzzles.size}", 160, 82, 11, 8, 1.0, :center, 0)

    c0 = @mode == 0 ? 10 : 6
    rectfill(44, 104, 232, 24, @mode == 0 ? 1 : 0, 0.85)
    rect(44, 104, 232, 24, c0, 2)
    print_text("SANDBOX LAB (3 RLE SAVE SLOTS)", 160, 112, c0, 8, 1.0, :center, 0)

    c1 = @mode == 1 ? 10 : 6
    rectfill(44, 134, 232, 24, @mode == 1 ? 1 : 0, 0.85)
    rect(44, 134, 232, 24, c1, 2)
    print_text("PUZZLE MODE: #{$puzzles[@puz_idx][:name]}", 160, 142, c1, 8, 1.0, :center, 0)

    print_text("DRAG/Z: PAINT | WHEEL: BRUSH SIZE | X: RESET", 160, 198, 7, 8, 1.0, :center, 0)
    print_text("ARROWS: SELECT ELEMENT / PUZZLE", 160, 214, 15, 8, 1.0, :center, 0)
  end
end

class LabScene
  def initialize(opts)
    @mode = opts[:mode]
    @puz_idx = opts[:puz_idx]
    @sw = $cfg[:sim_w]
    @sh = $cfg[:sim_h]
    @sy = $cfg[:sim_y]
    @sc = $cfg[:cell]

    @surf = create_surface(@sw, @sh, :pixel)
    @tool_idx = 0
    @brush = 3
    @tick = 0
    @won = false
    @goal_cnt = 0
    @slot_msg = ""
    @slot_msg_t = 0

    if @mode == :puzzle
      setup_puzzle(@puz_idx)
    else
      setup_sandbox_demo
    end
  end

  def setup_sandbox_demo
    clear_surface(@surf, nil)
    render_to(@surf) do
      # Stone basin & wood platform
      rectfill(15, 37, 50, 2, 5)
      rectfill(15, 27, 2, 12, 5)
      rectfill(63, 27, 2, 12, 5)
      rectfill(27, 21, 26, 2, 4)
      # Sand & water & TNT
      circfill(34, 11, 4, 10)
      circfill(48, 11, 4, 12)
      rectfill(38, 18, 4, 3, 14)
    end
  end

  def setup_puzzle(idx)
    @won = false
    @puz = $puzzles[idx]
    t_idx = $elem_order.index(@puz[:tool])
    @tool_idx = t_idx if t_idx
    clear_surface(@surf, nil)
    render_to(@surf) do
      g = @puz[:goal]
      # Goal beaker walls
      rectfill(g[0] - 1, g[1], 1, g[3] + 1, 5)
      rectfill(g[0] + g[2], g[1], 1, g[3] + 1, 5)
      rectfill(g[0] - 1, g[1] + g[3], g[2] + 2, 1, 5)

      if idx == 0
        rectfill(10, 16, 18, 2, 5)
        rectfill(52, 16, 18, 2, 5)
      elsif idx == 1
        circfill(14, 7, 5, 12)
        rectfill(5, 13, 18, 2, 5)
      elsif idx == 2
        rectfill(32, 9, 16, 5, 10)
        rectfill(30, 15, 20, 2, 4)
      elsif idx == 3
        rectfill(32, 6, 16, 6, 12)
        rectfill(30, 13, 20, 3, 5)
      elsif idx == 4
        rectfill(32, 36, 16, 6, 12)
        rectfill(30, 42, 20, 2, 5)
      elsif idx == 5
        rectfill(52, 15, 20, 2, 5)
      elsif idx == 6
        rectfill(33, 34, 14, 4, 8)
      elsif idx == 7
        rectfill(15, 15, 20, 8, 10)
        rectfill(13, 23, 24, 2, 5)
      elsif idx == 8
        rectfill(8, 13, 24, 2, 5)
      elsif idx == 9
        rectfill(31, 6, 18, 7, 12)
        rectfill(29, 14, 22, 3, 4)
      end
    end
  end

  def save_rle(slot)
    s = @surf
    w = @sw
    h = @sh
    runs = []
    cur = -1
    cnt = 0
    y = 0
    while y < h
      x = 0
      while x < w
        c = surface_pget(s, x, y)
        v = c.nil? ? -1 : c
        if v == cur
          cnt += 1
        else
          if cnt > 0
            runs << cur
            runs << cnt
          end
          cur = v
          cnt = 1
        end
        x += 1
      end
      y += 1
    end
    if cnt > 0
      runs << cur
      runs << cnt
    end
    save_set("slot_#{slot}", runs)
    @slot_msg = "SAVED SLOT #{slot + 1}!"
    @slot_msg_t = 60
  end

  def load_rle(slot)
    runs = save_get("slot_#{slot}", nil)
    unless runs.is_a?(Array) && runs.size >= 2
      @slot_msg = "SLOT #{slot + 1} EMPTY"
      @slot_msg_t = 50
      return
    end
    clear_surface(@surf, nil)
    s = @surf
    w = @sw
    idx = 0
    pos = 0
    while idx + 1 < runs.size
      v = runs[idx].to_i
      cnt = runs[idx + 1].to_i
      if v >= 0
        k = 0
        while k < cnt
          px = pos % w
          py = pos / w
          surface_pset(s, px, py, v)
          pos += 1
          k += 1
        end
      else
        pos += cnt
      end
      idx += 2
    end
    @slot_msg = "LOADED SLOT #{slot + 1}!"
    @slot_msg_t = 60
  end

  def update
    @tick += 1
    @slot_msg_t -= 1 if @slot_msg_t > 0

    if @won
      if btnp(1) || btnp(2) || btnp(:mouse_l)
        if @puz_idx + 1 < $puzzles.size
          @puz_idx += 1
          setup_puzzle(@puz_idx)
        else
          run TitleScene.new
        end
      end
      return
    end

    wh = mouse_wheel
    if wh > 0.0
      @brush = [@brush + 1, $cfg[:brush_max]].min
    elsif wh < 0.0
      @brush = [@brush - 1, $cfg[:brush_min]].max
    end

    if @mode == :sandbox
      @tool_idx = (@tool_idx - 1 + $elem_order.size) % $elem_order.size if btnp(:left)
      @tool_idx = (@tool_idx + 1) % $elem_order.size if btnp(:right)
    end

    if btnp(2)
      if @mode == :puzzle
        setup_puzzle(@puz_idx)
      else
        setup_sandbox_demo
      end
    end

    mx = mouse_x
    my = mouse_y
    if btn(:mouse_l)
      if my >= 214
        # Bottom palette click
        if @mode == :sandbox
          idx = (mx / 29).to_i
          @tool_idx = idx if idx >= 0 && idx < $elem_order.size
        else
          if mx >= 240
            setup_puzzle(@puz_idx)
          elsif mx < 60
            run TitleScene.new
            return
          end
        end
      elsif my >= @sy && my < @sy + @sh * @sc
        paint_at((mx / @sc).to_i, ((my - @sy) / @sc).to_i)
      end
    elsif btn(:mouse_r)
      if my >= @sy && my < @sy + @sh * @sc
        paint_erase((mx / @sc).to_i, ((my - @sy) / @sc).to_i)
      end
    elsif btn(1)
      paint_at(40 + (cos(@tick * 0.1) * 10).to_i, 8)
    end

    # Slot buttons in sandbox top bar
    if @mode == :sandbox && btnp(:mouse_l) && my < 18
      if mx >= 186 && mx < 228
        save_rle(0)
      elsif mx >= 230 && mx < 272
        load_rle(0)
      elsif mx >= 274 && mx < 316
        save_rle(1)
      end
    end

    step_simulation if @tick % 2 == 0

    if @mode == :puzzle && @tick % 10 == 0
      g = @puz[:goal]
      @goal_cnt = surface_count(@surf, @puz[:target_col], g[0], g[1], g[2], g[3])
      if @goal_cnt >= @puz[:need]
        @won = true
        cl = save_get("cleared", [])
        if cl.index(@puz_idx).nil?
          cl << @puz_idx
          save_set("cleared", cl)
        end
      end
    end
  end

  def paint_at(px, py)
    el = $elem_order[@tool_idx]
    col = el == :erase ? nil : $elements[el][:col]
    r = @brush
    render_to(@surf) do
      if col.nil?
        blend(:erase)
        circfill(px, py, r, 0)
        blend(:normal)
      else
        circfill(px, py, r, col)
      end
    end
  end

  def paint_erase(px, py)
    render_to(@surf) do
      blend(:erase)
      circfill(px, py, @brush, 0)
      blend(:normal)
    end
  end

  def step_simulation
    s = @surf
    w = @sw
    h = @sh
    c_sand = 10
    c_water = 12
    c_wood = 4
    c_fire = 9
    c_oil = 2
    c_acid = 11
    c_lava = 8
    c_steam = 6
    c_tnt = 14
    c_stone = 5
    flip = (@tick % 2 == 0)

    # Bottom-up pass for falling elements
    y = h - 2
    while y >= 0
      x = flip ? 0 : w - 1
      step_x = flip ? 1 : -1
      while x >= 0 && x < w
        c = surface_pget(s, x, y)
        if c == c_sand
          below = surface_pget(s, x, y + 1)
          if below.nil? || below == c_water || below == c_oil || below == c_acid
            surface_swap(s, x, y, x, y + 1)
          else
            d = rand() < 0.5 ? -1 : 1
            if x + d >= 0 && x + d < w && surface_pget(s, x + d, y + 1).nil?
              surface_swap(s, x, y, x + d, y + 1)
            elsif x - d >= 0 && x - d < w && surface_pget(s, x - d, y + 1).nil?
              surface_swap(s, x, y, x - d, y + 1)
            end
          end
        elsif c == c_water || c == c_oil || c == c_acid || c == c_lava
          below = surface_pget(s, x, y + 1)
          if c == c_lava && below == c_water
            surface_pset(s, x, y, c_steam)
            surface_pset(s, x, y + 1, c_stone)
          elsif c == c_acid && !below.nil? && below != c_acid && rand() < 0.22
            surface_pset(s, x, y, nil)
            surface_pset(s, x, y + 1, nil)
          elsif c == c_lava && (below == c_wood || below == c_oil || below == c_tnt)
            if below == c_tnt
              explode_tnt(x, y + 1)
            else
              surface_pset(s, x, y + 1, c_fire)
            end
          elsif below.nil? || (c == c_water && below == c_oil)
            surface_swap(s, x, y, x, y + 1)
          else
            d = rand() < 0.5 ? -1 : 1
            if x + d >= 0 && x + d < w && surface_pget(s, x + d, y + 1).nil?
              surface_swap(s, x, y, x + d, y + 1)
            elsif x + d >= 0 && x + d < w && surface_pget(s, x + d, y).nil?
              surface_swap(s, x, y, x + d, y)
            elsif x - d >= 0 && x - d < w && surface_pget(s, x - d, y).nil?
              surface_swap(s, x, y, x - d, y)
            end
          end
        elsif c == c_fire
          if rand() < 0.14
            surface_pset(s, x, y, nil)
          else
            # Ignite neighbors
            ny = y - 1
            if ny >= 0
              nb = surface_pget(s, x, ny)
              if nb == c_tnt
                explode_tnt(x, ny)
              elsif nb == c_wood || nb == c_oil
                surface_pset(s, x, ny, c_fire)
              elsif nb == c_water
                surface_pset(s, x, y, c_steam)
                surface_pset(s, x, ny, nil)
              elsif nb.nil? && rand() < 0.6
                surface_swap(s, x, y, x, ny)
              end
            end
          end
        end
        x += step_x
      end
      y -= 1
    end

    # Top-down pass for rising steam
    y = 1
    while y < h
      x = 0
      while x < w
        c = surface_pget(s, x, y)
        if c == c_steam
          if y <= 2 && rand() < 0.05
            surface_pset(s, x, y, c_water)
          elsif surface_pget(s, x, y - 1).nil?
            surface_swap(s, x, y, x, y - 1)
          elsif x > 0 && surface_pget(s, x - 1, y - 1).nil?
            surface_swap(s, x, y, x - 1, y - 1)
          end
        end
        x += 1
      end
      y += 1
    end
  end

  def explode_tnt(ex, ey)
    render_to(@surf) do
      blend(:erase)
      circfill(ex, ey, 11, 0)
      blend(:normal)
      circ(ex, ey, 9, 9)
    end
  end

  def draw
    cls(0)
    bg(:training, dim: 0.65, tint: "#304058")

    # Top bar
    rectfill(0, 0, 320, @sy, 0, 0.85)
    if @mode == :puzzle
      print_text(@puz[:name], 6, 3, 10, 8, 1.0, :left, 0)
      print_text("#{@goal_cnt}/#{@puz[:need]}", 314, 3, @goal_cnt >= @puz[:need] ? 11 : 7, 8, 1.0, :right, 0)
      print_text(@puz[:desc], 160, 12, 7, 8, 1.0, :center, 0)
    else
      print_text("SANDBOX (BRUSH:#{@brush})", 6, 6, 10, 8, 1.0, :left, 0)
      rectfill(186, 2, 40, 15, 1)
      print_text("SAVE1", 206, 6, 7, 8, 1.0, :center, 0)
      rectfill(230, 2, 40, 15, 1)
      print_text("LOAD1", 250, 6, 12, 8, 1.0, :center, 0)
      rectfill(274, 2, 40, 15, 1)
      print_text("SAVE2", 294, 6, 7, 8, 1.0, :center, 0)
    end

    # Simulation surface (crisp 5x pixel cells)
    s = @surf
    sw = @sw
    sh = @sh
    sc = @sc
    sy = @sy
    py = 0
    while py < sh
      px = 0
      while px < sw
        c = surface_pget(s, px, py)
        rectfill(px * sc, sy + py * sc, sc, sc, c) if c
        px += 1
      end
      py += 1
    end

    if @mode == :puzzle
      g = @puz[:goal]
      rect(g[0] * @sc, @sy + g[1] * @sc, g[2] * @sc, g[3] * @sc, 10, 1, 0.65)
    end

    # Brush preview
    if mouse_y >= @sy && mouse_y < @sy + @sh * @sc
      circ(mouse_x, mouse_y, @brush * @sc, 7, 0.7)
    end

    # Bottom palette
    rectfill(0, 212, 320, 28, 0, 0.9)
    if @mode == :sandbox
      i = 0
      while i < $elem_order.size
        el = $elem_order[i]
        spec = $elements[el]
        bx = i * 29 + 1
        sel = @tool_idx == i
        rectfill(bx, 215, 27, 22, sel ? 1 : 0)
        rect(bx, 215, 27, 22, sel ? 10 : spec[:col], sel ? 2 : 1)
        print_text(spec[:name], bx + 13, 222, spec[:col] == 0 ? 6 : spec[:col], 8, 1.0, :center, 0)
        i += 1
      end
    else
      el = $elem_order[@tool_idx]
      spec = $elements[el]
      print_text("TOOL: #{spec[:name]} (BRUSH:#{@brush})", 160, 222, spec[:col], 8, 1.0, :center, 0)
      print_text("<TITLE", 6, 222, 6, 8)
      print_text("RESET>", 314, 222, 9, 8, 1.0, :right)
    end

    if @slot_msg_t > 0
      print_text(@slot_msg, 160, 110, 11, 8, 1.0, :center, 0)
    end

    if @won
      rectfill(50, 74, 220, 84, 0, 0.9)
      rect(50, 74, 220, 84, 11, 2)
      print_text("PUZZLE CLEARED!", 160, 90, 11, 16, 1.0, :center, 0)
      print_text("PRESS Z / CLICK FOR NEXT", 160, 126, 7, 8, 1.0, :center, 0)
    end
  end
end

run TitleScene.new
