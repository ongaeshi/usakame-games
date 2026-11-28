config(
  title: "PICROSS ATELIER",
  width: 480,
  height: 270,
  save_id: "picross_atelier",
  save_salt: "p3g47g9a"
)

$cfg = {
  w: 480,
  h: 270,
  cell_5: 22,
  cell_10: 15,
  grid_x: 205,
  grid_y: 88,
  col_bg: 1,
  col_fill: 12,
  col_mark: 8,
  col_clue_ok: 5,
  col_clue: 7
}

$puzzles = [
  { name: "HEART", col: 8, rows: ["01010", "11111", "11111", "01110", "00100"] },
  { name: "CROWN", col: 10, rows: ["10101", "11111", "11111", "11111", "00000"] },
  { name: "ARROW", col: 11, rows: ["00100", "00110", "11111", "00110", "00100"] },
  { name: "CHALICE", col: 12, rows: ["11111", "11111", "01110", "00100", "01110"] },
  { name: "CAT", col: 9, rows: [
    "0100000010", "0110000110", "0111111110", "0101111010", "0111111110",
    "0011001100", "0011111100", "0011111100", "0011001100", "0000000000"
  ] },
  { name: "APPLE", col: 8, rows: [
    "00001100", "00010000", "01111110", "11111111", "11111111",
    "11111111", "11111111", "01111110"
  ] },
  { name: "SWORD", col: 6, rows: [
    "0000000110", "0000001110", "0000011100", "0000111000", "0001110000",
    "0111100000", "0011000000", "0110100000", "1100000000", "0000000000"
  ] },
  { name: "ROCKET", col: 12, rows: [
    "0000110000", "0001111000", "0011111100", "0011001100", "0011111100",
    "0111111110", "1111111111", "1011111101", "0010000100", "0001001000"
  ] },
  { name: "GHOST", col: 7, rows: [
    "00111100", "01111110", "11011011", "11011011", "11111111",
    "11111111", "11111111", "10101010"
  ] },
  { name: "TREE", col: 3, rows: [
    "0000110000", "0001111000", "0011111100", "0111111110", "0011111100",
    "0111111110", "1111111111", "0000110000", "0000110000", "0001111000"
  ] },
  { name: "KEY", col: 10, rows: [
    "0111000000", "1000100000", "1000100000", "0111111111", "0000000101",
    "0000000101", "0000000000", "0000000000"
  ] },
  { name: "FISH", col: 12, rows: [
    "0001111000", "0011111100", "1011101110", "1111111111", "1111111110",
    "1011111100", "0001110000", "0000000000"
  ] },
  { name: "SKULL", col: 7, rows: [
    "0011111100", "0111111110", "1111111111", "1100110011", "1100110011",
    "0111001110", "0011111100", "0010110100", "0010110100", "0000000000"
  ] },
  { name: "UFO", col: 11, rows: [
    "0001111000", "0011111100", "0111111110", "1101111011", "1111111111",
    "0010000100", "0100000010", "0000000000"
  ] },
  { name: "CROWN2", col: 10, rows: [
    "1000110001", "1101111011", "1111111111", "1101111011", "1111111111",
    "1111111111", "0111111110", "0000000000"
  ] },
  { name: "USAKAME", col: 14, rows: [
    "0110000110", "0110000110", "0111111110", "1101111011", "1111111111",
    "0111001110", "0011111100", "0111111110", "0110000110", "0000000000"
  ] }
]

class TitleScene
  def initialize
    @solved = save_get("solved", [])
    @sel = 0
    @mode = 0 # 0: Play, 1: Gallery
    @tick = 0
  end

  def update
    @tick += 1
    @sel = (@sel - 1 + $puzzles.size) % $puzzles.size if btnp(:left)
    @sel = (@sel + 1) % $puzzles.size if btnp(:right)
    @sel = (@sel - 4 + $puzzles.size) % $puzzles.size if btnp(:up)
    @sel = (@sel + 4) % $puzzles.size if btnp(:down)

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 224 && mx >= 320 && mx <= 460
        run GalleryScene.new
        return
      end
      c = ((mx - 40) / 100).to_i
      r = ((my - 68) / 36).to_i
      if c >= 0 && c < 4 && r >= 0 && r < 4
        @sel = r * 4 + c
        run PuzzleScene.new({ idx: @sel })
        return
      end
    end

    if btnp(1)
      run PuzzleScene.new({ idx: @sel })
    elsif btnp(2)
      run GalleryScene.new
    end
  end

  def draw
    cls(0)
    bg(:forest, dim: 0.55, tint: "#605080", scroll_x: @tick * 0.15, mirror_x: true)

    print_text("PICROSS ATELIER", 240, 16, 10, 16, 1.0, :center, 0, 2)
    print_text("SOLVED: #{@solved.size}/#{$puzzles.size}", 240, 40, 11, 8, 1.0, :center, 0)

    i = 0
    while i < $puzzles.size
      p = $puzzles[i]
      c = i % 4
      r = i / 4
      bx = 40 + c * 100
      by = 68 + r * 36
      sel = @sel == i
      done = !@solved.index(i).nil?
      rectfill(bx, by, 92, 30, sel ? 1 : 0, 0.85)
      rect(bx, by, 92, 30, sel ? 10 : (done ? 11 : 6), sel ? 2 : 1)
      tag = done ? "* #{p[:name]}" : "#{i + 1}. #{p[:name]}"
      print_text(tag, bx + 46, by + 11, done ? 11 : (sel ? 10 : 7), 8, 1.0, :center, 0)
      i += 1
    end

    rectfill(320, 224, 140, 24, 1, 0.9)
    rect(320, 224, 140, 24, 12, 1)
    print_text("X: VIEW GALLERY", 390, 232, 12, 8, 1.0, :center, 0)
    print_text("ARROWS: SELECT | Z/CLICK: PLAY", 160, 232, 7, 8, 1.0, :center, 0)
  end
end

class GalleryScene
  def initialize
    @solved = save_get("solved", [])
    @tick = 0
  end

  def update
    @tick += 1
    if btnp(1) || btnp(2) || btnp(:mouse_l)
      run TitleScene.new
    end
  end

  def draw
    cls(0)
    bg(:city, dim: 0.65, tint: "#504060")
    print_text("ATELIER GALLERY (#{@solved.size}/#{$puzzles.size})", 240, 14, 10, 16, 1.0, :center, 0)

    i = 0
    while i < $puzzles.size
      p = $puzzles[i]
      c = i % 8
      r = i / 8
      fx = 24 + c * 56
      fy = 48 + r * 92
      rectfill(fx, fy, 46, 68, 0, 0.85)
      rect(fx, fy, 46, 68, 9, 2)
      done = !@solved.index(i).nil?
      if done
        rows = p[:rows]
        h = rows.size
        w = rows[0].size
        bob = sin(@tick * 0.08 + i) * 2
        ry = 0
        while ry < h
          rx = 0
          while rx < w
            if rows[ry][rx] == "1"
              rectfill(fx + 8 + rx * 3, fy + 10 + ry * 3 + bob, 3, 3, p[:col])
            end
            rx += 1
          end
          ry += 1
        end
        print_text(p[:name], fx + 23, fy + 54, 7, 8, 1.0, :center, 0)
      else
        print_text("?", fx + 23, fy + 26, 5, 16, 1.0, :center, 0)
      end
      i += 1
    end

    print_text("PRESS Z / CLICK TO RETURN", 240, 244, 12, 8, 1.0, :center, 0)
  end
end

class PuzzleScene
  def initialize(opts)
    @idx = opts[:idx]
    @puz = $puzzles[@idx]
    @rows = @puz[:rows]
    @h = @rows.size
    @w = @rows[0].size
    @cell = @h <= 5 ? $cfg[:cell_5] : $cfg[:cell_10]
    @gx = $cfg[:grid_x]
    @gy = $cfg[:grid_y]

    # Load WIP save or init empty board (0: empty, 1: filled, 2: marked X)
    wip = save_get("wip_#{@idx}", nil)
    if wip.is_a?(Array) && wip.size == @h
      @board = wip
    else
      @board = []
      r = 0
      while r < @h
        row = []
        c = 0
        while c < @w
          row << 0
          c += 1
        end
        @board << row
        r += 1
      end
    end

    @row_clues = compute_row_clues
    @col_clues = compute_col_clues
    @cur_c = 0
    @cur_r = 0
    @tool = 1 # 1: Fill, 2: Mark X
    @tick = 0
    @won = false
    @timer = 0
  end

  def compute_row_clues
    res = []
    r = 0
    while r < @h
      clues = []
      run = 0
      c = 0
      while c < @w
        if @rows[r][c] == "1"
          run += 1
        elsif run > 0
          clues << run.to_s
          run = 0
        end
        c += 1
      end
      clues << run.to_s if run > 0
      clues << "0" if clues.empty?
      res << clues.join(" ")
      r += 1
    end
    res
  end

  def compute_col_clues
    res = []
    c = 0
    while c < @w
      clues = []
      run = 0
      r = 0
      while r < @h
        if @rows[r][c] == "1"
          run += 1
        elsif run > 0
          clues << run.to_s
          run = 0
        end
        r += 1
      end
      clues << run.to_s if run > 0
      clues << "0" if clues.empty?
      res << clues
      c += 1
    end
    res
  end

  def update
    @tick += 1
    if @won
      if btnp(1) || btnp(2) || btnp(:mouse_l)
        if @idx + 1 < $puzzles.size
          run PuzzleScene.new({ idx: @idx + 1 })
        else
          run GalleryScene.new
        end
      end
      return
    end

    @timer += 1
    wh = mouse_wheel
    if wh != 0.0 || btnp(2)
      @tool = @tool == 1 ? 2 : 1
    end

    @cur_c = (@cur_c - 1).clamp(0, @w - 1) if btnp(:left)
    @cur_c = (@cur_c + 1).clamp(0, @w - 1) if btnp(:right)
    @cur_r = (@cur_r - 1).clamp(0, @h - 1) if btnp(:up)
    @cur_r = (@cur_r + 1).clamp(0, @h - 1) if btnp(:down)

    mx = mouse_x
    my = mouse_y
    if mx >= @gx && mx < @gx + @w * @cell && my >= @gy && my < @gy + @h * @cell
      @cur_c = ((mx - @gx) / @cell).to_i
      @cur_r = ((my - @gy) / @cell).to_i
      if btnp(:mouse_l)
        toggle_cell(@cur_c, @cur_r, @tool)
      elsif btnp(:mouse_r)
        toggle_cell(@cur_c, @cur_r, 2)
      end
    elsif btnp(:mouse_l) && mx < 80 && my < 28
      run TitleScene.new
      return
    end

    if btnp(1)
      toggle_cell(@cur_c, @cur_r, @tool)
    end
  end

  def toggle_cell(c, r, mode)
    cur = @board[r][c]
    @board[r][c] = (cur == mode ? 0 : mode)
    save_set("wip_#{@idx}", @board)
    check_win
  end

  def check_win
    r = 0
    while r < @h
      c = 0
      while c < @w
        want = @rows[r][c] == "1"
        got = @board[r][c] == 1
        return if want != got
        c += 1
      end
      r += 1
    end
    @won = true
    save_del("wip_#{@idx}")
    solved = save_get("solved", [])
    if solved.index(@idx).nil?
      solved << @idx
      save_set("solved", solved)
    end
  end

  def draw
    cls(0)
    bg(:training, dim: 0.65, tint: "#304060")

    rectfill(0, 0, 480, 26, 0, 0.85)
    print_text("< BACK", 8, 8, 6, 8, 1.0, :left, 0)
    print_text("NO.#{@idx + 1} #{@puz[:name]} (#{@w}x#{@h})", 240, 8, 10, 8, 1.0, :center, 0)
    tool_str = @tool == 1 ? "TOOL: FILL" : "TOOL: MARK X"
    print_text(tool_str, 472, 8, @tool == 1 ? 12 : 8, 8, 1.0, :right, 0)

    # Row clues (right-aligned using :right!)
    r = 0
    while r < @h
      clue = @row_clues[r]
      tw = text_width(clue, 8)
      cy = @gy + r * @cell + (@cell - 8) / 2
      rectfill(@gx - tw - 10, cy - 2, tw + 6, 11, 0, 0.55)
      print_text(clue, @gx - 6, cy, 7, 8, 1.0, :right, 0)
      r += 1
    end

    # Column clues (centered using :center!)
    c = 0
    while c < @w
      clues = @col_clues[c]
      cx = @gx + c * @cell + @cell / 2
      k = clues.size - 1
      row_off = 0
      while k >= 0
        print_text(clues[k], cx, @gy - 12 - row_off * 10, 7, 8, 1.0, :center, 0)
        row_off += 1
        k -= 1
      end
      c += 1
    end

    # Grid
    r = 0
    while r < @h
      c = 0
      while c < @w
        x = @gx + c * @cell
        y = @gy + r * @cell
        v = @board[r][c]
        rectfill(x, y, @cell, @cell, v == 1 ? (@won ? @puz[:col] : $cfg[:col_fill]) : 1)
        rect(x, y, @cell, @cell, 6, 1)
        if v == 2
          line(x + 3, y + 3, x + @cell - 4, y + @cell - 4, 8, 1)
          line(x + @cell - 4, y + 3, x + 3, y + @cell - 4, 8, 1)
        end
        c += 1
      end
      r += 1
    end

    # 5x5 sub-grid bold lines
    if @w == 10
      line(@gx + 5 * @cell, @gy, @gx + 5 * @cell, @gy + @h * @cell, 7, 2)
    end
    if @h >= 8
      line(@gx, @gy + 5 * @cell, @gx + @w * @cell, @gy + 5 * @cell, 7, 2)
    end
    rect(@gx, @gy, @w * @cell, @h * @cell, 7, 2)

    # Cursor
    unless @won
      rect(@gx + @cur_c * @cell, @gy + @cur_r * @cell, @cell, @cell, 10, 2)
    end

    print_text("L-CLICK/Z: FILL | R-CLICK: X | WHEEL/X: TOOL", 240, 254, 7, 8, 1.0, :center, 0)

    if @won
      rectfill(120, 88, 240, 86, 0, 0.90)
      rect(120, 88, 240, 86, 11, 2)
      print_text("ARTWORK COMPLETE!", 240, 104, 11, 16, 1.0, :center, 0)
      print_text("ADDED TO GALLERY: #{@puz[:name]}", 240, 130, 10, 8, 1.0, :center, 0)
      print_text("PRESS Z / CLICK FOR NEXT", 240, 148, 7, 8, 1.0, :center, 0)
    end
  end
end

run TitleScene.new
