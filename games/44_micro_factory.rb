config(
  title: "MICRO FACTORY",
  width: 480,
  height: 270,
  save_id: "micro_factory",
  save_salt: "p3g44d8f"
)

$cfg = {
  w: 480,
  h: 270,
  gx: 8,
  gy: 34,
  cols: 18,
  rows: 11,
  cell: 20,
  tick_belt: 18,
  tick_mine: 70,
  tick_smelt: 65,
  auto_save_frames: 180
}

$machines = {
  belt: { name: "BELT", jp: "ベルト", cost: 2, col: 6 },
  miner: { name: "MINER", jp: "採掘機", cost: 15, col: 10 },
  smelter: { name: "SMELT", jp: "精錬炉", cost: 30, col: 9 },
  seller: { name: "SELL", jp: "出荷口", cost: 25, col: 11 }
}

$mach_order = [:belt, :miner, :smelter, :seller]

$items = {
  iron_ore: { name: "Fe ORE", col: 6, price: 2 },
  copper_ore: { name: "Cu ORE", col: 9, price: 3 },
  iron_bar: { name: "Fe BAR", col: 7, price: 8 },
  copper_bar: { name: "Cu BAR", col: 10, price: 11 }
}

$ores = [
  { x: 1, y: 2, type: :iron_ore, col: 12 },
  { x: 2, y: 2, type: :iron_ore, col: 12 },
  { x: 1, y: 3, type: :iron_ore, col: 12 },
  { x: 2, y: 7, type: :copper_ore, col: 9 },
  { x: 3, y: 7, type: :copper_ore, col: 9 },
  { x: 2, y: 8, type: :copper_ore, col: 9 },
  { x: 10, y: 1, type: :iron_ore, col: 12 },
  { x: 11, y: 1, type: :copper_ore, col: 9 }
]

$dirs = [
  [1, 0],
  [0, 1],
  [-1, 0],
  [0, -1]
]

class TitleScene
  def initialize
    @gold = save_get("gold", 120).to_i
    @shipped = save_get("shipped", 0).to_i
    @has_save = save_has?("grid")
    @tick = 0
  end

  def update
    @tick += 1
    if btnp(1) || btnp(2) || btnp(:mouse_l)
      run FactoryScene.new
    end
  end

  def draw
    cls(0)
    bg(:city, dim: 0.50, tint: "#6080A8", scroll_x: @tick * 0.2, mirror_x: true)

    print_text("MICRO FACTORY", 240, 42, 10, 16, 1.0, :center, 0, 2)
    print_text("自動生産ライン構築シム", 240, 68, 7, 8, 1.0, :center, 0)

    rectfill(110, 96, 260, 56, 0, 0.80)
    rect(110, 96, 260, 56, 12, 1)
    status = @has_save ? "セーブデータあり (自動復元)" : "新規工場 (スターターライン付き)"
    print_text(status, 240, 108, 11, 8, 1.0, :center, 0)
    print_text("所持GOLD: #{@gold}G   累計出荷数: #{@shipped}", 240, 128, 10, 8, 1.0, :center, 0)

    rectfill(140, 174, 200, 28, 1, 0.9)
    rect(140, 174, 200, 28, 10, 2)
    print_text("PRESS Z / CLICK TO BUILD", 240, 184, 10, 8, 1.0, :center, 0)

    print_text("左クリック: 設置 | 右クリック: 撤去 | ホイール/X: 回転", 240, 232, 7, 8, 1.0, :center, 0)
  end
end

class FactoryScene
  def initialize
    show_cursor(false)
    @cols = $cfg[:cols]
    @rows = $cfg[:rows]
    @cell = $cfg[:cell]
    @gx = $cfg[:gx]
    @gy = $cfg[:gy]

    @gold = save_get("gold", 120).to_i
    @shipped = save_get("shipped", 0).to_i
    @spd_lv = save_get("spd_lv", 0).to_i

    @grid = []
    r = 0
    while r < @rows
      row = []
      c = 0
      while c < @cols
        row << nil
        c += 1
      end
      @grid << row
      r += 1
    end

    if save_has?("grid")
      load_grid(save_get("grid", []))
    else
      setup_starter_factory
    end

    @tool_idx = 0
    @dir = 0
    @cur_c = 5
    @cur_r = 3
    @tick = 0
    @popups = []
    @dirty = false
  end

  def setup_starter_factory
    place_raw(1, 2, :miner, 0)
    place_raw(2, 2, :belt, 0)
    place_raw(3, 2, :belt, 0)
    place_raw(4, 2, :smelter, 0)
    place_raw(5, 2, :belt, 0)
    place_raw(6, 2, :belt, 0)
    place_raw(7, 2, :seller, 0)
  end

  def place_raw(c, r, type, dir)
    @grid[r][c] = { type: type, dir: dir, item: nil, timer: 0, prog: 0 }
  end

  def load_grid(arr)
    return unless arr.is_a?(Array)
    arr.each do |entry|
      next unless entry.is_a?(Hash)
      c = (entry["c"] || 0).to_i
      r = (entry["r"] || 0).to_i
      t = (entry["t"] || "belt").to_sym
      d = (entry["d"] || 0).to_i
      if c >= 0 && c < @cols && r >= 0 && r < @rows && $machines.has_key?(t)
        place_raw(c, r, t, d % 4)
      end
    end
  end

  def save_factory
    arr = []
    r = 0
    while r < @rows
      c = 0
      while c < @cols
        cell = @grid[r][c]
        if cell
          arr << { "c" => c, "r" => r, "t" => cell[:type].to_s, "d" => cell[:dir] }
        end
        c += 1
      end
      r += 1
    end
    save_set("grid", arr)
    save_set("gold", @gold)
    save_set("shipped", @shipped)
    save_set("spd_lv", @spd_lv)
    @dirty = false
  end

  def ore_at(c, r)
    $ores.each do |o|
      return o if o[:x] == c && o[:y] == r
    end
    nil
  end

  def update
    @tick += 1

    # Mouse hover
    mx = mouse_x
    my = mouse_y
    if mx >= @gx && mx < @gx + @cols * @cell && my >= @gy && my < @gy + @rows * @cell
      @cur_c = ((mx - @gx) / @cell).to_i
      @cur_r = ((my - @gy) / @cell).to_i
    end

    # Keyboard cursor
    @cur_c = (@cur_c - 1).clamp(0, @cols - 1) if btnp(:left)
    @cur_c = (@cur_c + 1).clamp(0, @cols - 1) if btnp(:right)
    @cur_r = (@cur_r - 1).clamp(0, @rows - 1) if btnp(:up)
    @cur_r = (@cur_r + 1).clamp(0, @rows - 1) if btnp(:down)

    # Rotate with wheel or X
    wh = mouse_wheel
    if wh > 0.0 || btnp(2)
      @dir = (@dir + 1) % 4
    elsif wh < 0.0
      @dir = (@dir + 3) % 4
    end

    # Click handling
    if btnp(:mouse_l)
      if mx >= 376 && mx <= 472
        # Side palette click
        i = 0
        while i < $mach_order.size
          by = 40 + i * 32
          if my >= by && my <= by + 28
            @tool_idx = i
            break
          end
          i += 1
        end
        # Upgrade button
        if my >= 180 && my <= 208
          buy_speed_upgrade
        elsif my >= 216 && my <= 242
          reset_factory
        end
      elsif mx >= @gx && mx < @gx + @cols * @cell && my >= @gy && my < @gy + @rows * @cell
        place_machine(@cur_c, @cur_r)
      end
    elsif btnp(:mouse_r)
      remove_machine(@cur_c, @cur_r)
    end

    if btnp(1)
      place_machine(@cur_c, @cur_r)
    end

    update_simulation
    update_popups

    if @dirty && @tick % $cfg[:auto_save_frames] == 0
      save_factory
    elsif @tick % $cfg[:auto_save_frames] == 0
      save_set("gold", @gold)
      save_set("shipped", @shipped)
    end
  end

  def place_machine(c, r)
    t = $mach_order[@tool_idx]
    spec = $machines[t]
    existing = @grid[r][c]
    if existing && existing[:type] == t
      existing[:dir] = @dir
      @dirty = true
      return
    end
    return if @gold < spec[:cost]
    @gold -= spec[:cost]
    @gold += ($machines[existing[:type]][:cost] / 2) if existing
    place_raw(c, r, t, @dir)
    @dirty = true
    save_factory
  end

  def remove_machine(c, r)
    existing = @grid[r][c]
    return unless existing
    @gold += ($machines[existing[:type]][:cost] / 2)
    @grid[r][c] = nil
    @dirty = true
    save_factory
  end

  def buy_speed_upgrade
    cost = 50 * (@spd_lv + 1)
    if @gold >= cost && @spd_lv < 5
      @gold -= cost
      @spd_lv += 1
      @popups << { x: 424, y: 178, text: "SPEED UP!", col: 11, life: 45 }
      save_factory
    end
  end

  def reset_factory
    r = 0
    while r < @rows
      c = 0
      while c < @cols
        @grid[r][c] = nil
        c += 1
      end
      r += 1
    end
    @gold = 120
    setup_starter_factory
    save_factory
  end

  def update_simulation
    spd_bonus = 1.0 + @spd_lv * 0.25
    belt_t = ($cfg[:tick_belt] / spd_bonus).to_i
    mine_t = ($cfg[:tick_mine] / spd_bonus).to_i
    smelt_t = ($cfg[:tick_smelt] / spd_bonus).to_i

    r = 0
    while r < @rows
      c = 0
      while c < @cols
        m = @grid[r][c]
        if m
          t = m[:type]
          if t == :miner
            ore = ore_at(c, r)
            if ore && m[:item].nil?
              m[:timer] += 1
              if m[:timer] >= mine_t
                m[:timer] = 0
                m[:item] = ore[:type]
              end
            end
            try_push(c, r, m)
          elsif t == :belt
            if m[:item]
              m[:timer] += 1
              if m[:timer] >= belt_t
                if try_push(c, r, m)
                  m[:timer] = 0
                end
              end
            end
          elsif t == :smelter
            if m[:item] == :iron_ore || m[:item] == :copper_ore
              m[:timer] += 1
              if m[:timer] >= smelt_t
                m[:timer] = 0
                m[:item] = m[:item] == :iron_ore ? :iron_bar : :copper_bar
              end
            elsif m[:item]
              try_push(c, r, m)
            end
          elsif t == :seller
            if m[:item]
              spec = $items[m[:item]]
              price = spec ? spec[:price] : 2
              @gold += price
              @shipped += 1
              px = @gx + c * @cell + 10
              py = @gy + r * @cell
              @popups << { x: px, y: py, text: "+#{price}G", col: 10, life: 32 }
              m[:item] = nil
            end
          end
        end
        c += 1
      end
      r += 1
    end
  end

  def try_push(c, r, m)
    return false unless m[:item]
    d = $dirs[m[:dir]]
    nc = c + d[0]
    nr = r + d[1]
    return false if nc < 0 || nc >= @cols || nr < 0 || nr >= @rows
    target = @grid[nr][nc]
    return false unless target
    return false if target[:type] == :miner
    if target[:item].nil?
      target[:item] = m[:item]
      target[:timer] = 0
      m[:item] = nil
      return true
    end
    false
  end

  def update_popups
    i = @popups.size - 1
    while i >= 0
      pp = @popups[i]
      pp[:y] -= 0.4
      pp[:life] -= 1
      @popups.delete_at(i) if pp[:life] <= 0
      i -= 1
    end
  end

  def draw
    cls(0)
    bg(:training, dim: 0.65, tint: "#2A384C")

    # Top bar
    rectfill(0, 0, 480, 28, 0, 0.85)
    print_text("MICRO FACTORY", 8, 6, 10, 8, 1.0, :left, 0)
    print_text("GOLD: #{@gold}G", 130, 6, 10, 8, 1.0, :left, 0)
    print_text("出荷: #{@shipped}", 230, 6, 11, 8, 1.0, :left, 0)
    print_text("速度Lv:#{@spd_lv}/5", 320, 6, 12, 8, 1.0, :left, 0)
    dir_names = ["右→", "下↓", "左←", "上↑"]
    print_text("向き: #{dir_names[@dir]}", 472, 6, 7, 8, 1.0, :right, 0)

    # Grid background & ore nodes
    rectfill(@gx, @gy, @cols * @cell, @rows * @cell, 1, 0.7)
    r = 0
    while r < @rows
      c = 0
      while c < @cols
        x = @gx + c * @cell
        y = @gy + r * @cell
        rect(x, y, @cell, @cell, 5, 1, 0.4)
        c += 1
      end
      r += 1
    end

    $ores.each do |o|
      ox = @gx + o[:x] * @cell + 2
      oy = @gy + o[:y] * @cell + 2
      rectfill(ox, oy, @cell - 4, @cell - 4, o[:col], 0.45)
      rect(ox, oy, @cell - 4, @cell - 4, o[:col], 1)
    end

    # Machines & items
    r = 0
    while r < @rows
      c = 0
      while c < @cols
        m = @grid[r][c]
        if m
          draw_machine(c, r, m)
        end
        c += 1
      end
      r += 1
    end

    # Custom Blueprint Cursor (show_cursor(false))
    cx = @gx + @cur_c * @cell
    cy = @gy + @cur_r * @cell
    rect(cx, cy, @cell, @cell, 10, 2)
    d = $dirs[@dir]
    line(cx + 10, cy + 10, cx + 10 + d[0] * 7, cy + 10 + d[1] * 7, 10, 2)

    # Mouse crosshair if inside screen
    mx = mouse_x
    my = mouse_y
    line(mx - 4, my, mx + 4, my, 7, 1)
    line(mx, my - 4, mx, my + 4, 7, 1)

    draw_side_panel

    @popups.each do |pp|
      print_text(pp[:text], pp[:x], pp[:y], pp[:col], 8, 1.0, :center, 0)
    end
  end

  def draw_machine(c, r, m)
    x = @gx + c * @cell
    y = @gy + r * @cell
    t = m[:type]
    spec = $machines[t]
    rectfill(x + 2, y + 2, @cell - 4, @cell - 4, spec[:col], 0.85)
    rect(x + 2, y + 2, @cell - 4, @cell - 4, 7, 1)

    d = $dirs[m[:dir]]
    ax = x + 10 + d[0] * 6
    ay = y + 10 + d[1] * 6
    if t != :seller
      line(x + 10, y + 10, ax, ay, 0, 2)
    end

    tag = t == :belt ? "" : (t == :miner ? "M" : (t == :smelter ? "S" : "$"))
    print_text(tag, x + 4, y + 3, 0, 8) if tag != ""

    if m[:item]
      it = $items[m[:item]]
      circfill(x + 10, y + 10, 4, it[:col])
      circ(x + 10, y + 10, 4, 0)
    end
  end

  def draw_side_panel
    rectfill(374, 34, 100, 224, 0, 0.82)
    rect(374, 34, 100, 224, 5, 1)

    i = 0
    while i < $mach_order.size
      k = $mach_order[i]
      spec = $machines[k]
      by = 40 + i * 32
      sel = @tool_idx == i
      rectfill(380, by, 88, 28, sel ? 1 : 0, 0.9)
      rect(380, by, 88, 28, sel ? 10 : spec[:col], sel ? 2 : 1)
      print_text(spec[:jp], 386, by + 4, sel ? 10 : 7, 8, 1.0, :left, 0)
      print_text("#{spec[:cost]}G", 462, by + 15, 10, 8, 1.0, :right, 0)
      i += 1
    end

    # Speed upgrade button
    ucost = 50 * (@spd_lv + 1)
    rectfill(380, 180, 88, 28, 1, 0.9)
    rect(380, 180, 88, 28, 12, 1)
    utxt = @spd_lv >= 5 ? "速度 MAX" : "高速化 #{ucost}G"
    print_text(utxt, 424, 190, 12, 8, 1.0, :center, 0)

    # Reset button
    rectfill(380, 216, 88, 24, 2, 0.8)
    rect(380, 216, 88, 24, 8, 1)
    print_text("工場リセット", 424, 224, 7, 8, 1.0, :center, 0)
  end
end

run TitleScene.new
