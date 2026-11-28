config(
  title: "HYPER RAIL EXPRESS",
  width: 480,
  height: 270,
  save_id: "hyper_rail_express",
  save_salt: "p4g58hr7"
)

$cfg = {
  w: 480,
  h: 270,
  ts: 24,
  cols: 18,
  rows: 9,
  ox: 24,
  oy: 26,
  train_spd: 0.72,
  spawn_iv: 170
}

# Track cell directions: 0:Right, 1:Down, 2:Left, 3:Up
# Cell types:
#  '-' horiz (L<->R), '|' vert (U<->D), '+' cross (L<->R and U<->D)
#  'r' corner R<->D, 'l' corner L<->D, 'R' corner R<->U, 'L' corner L<->U
#  'S' switch: enters from Left -> goes Right(0) or Down(1)
#  'U' switch: enters from Left -> goes Right(0) or Up(3)
#  'W' switch: enters from Right -> goes Left(2) or Down(1)
#  'V' switch: enters from Right -> goes Left(2) or Up(3)
#  '0','1','2','3' = Stations (Red, Blue, Green, Yellow)
#  'A','B','C','D' = Spawners (Red, Blue, Green, Yellow)
$timetables = [
  {
    name: "01: MORNING COMMUTE",
    goal: 4, night: false, bg: :forest, tint: "#70A870",
    map: [
      "..................",
      "..................",
      "..A---S---0.......",
      "......|...........",
      "......R---1.......",
      "..................",
      "..................",
      "..................",
      ".................."
    ]
  },
  {
    name: "02: TWIN JUNCTION",
    goal: 6, night: false, bg: :forest, tint: "#60A088",
    map: [
      "..................",
      "......0...........",
      "......|...........",
      "..A---U---S---1...",
      "..........|.......",
      "..........R---2...",
      "..................",
      "..................",
      ".................."
    ]
  },
  {
    name: "03: CROSSING EXPRESS",
    goal: 6, night: false, bg: :mountain, tint: "#90A0B8",
    map: [
      "......B...........",
      "......|...........",
      "..A---+---S---0...",
      "......|...|.......",
      "......1...R---2...",
      "..................",
      "..................",
      "..................",
      ".................."
    ]
  },
  {
    name: "04: TWILIGHT LOOP",
    goal: 8, night: true, bg: :city, tint: "#605098",
    map: [
      "..................",
      "..A---S---U---0...",
      "......|...|.......",
      "......|...2.......",
      "......R---S---1...",
      "..........|.......",
      "..........3.......",
      "..................",
      ".................."
    ]
  },
  {
    name: "05: DUAL TERMINUS",
    goal: 8, night: false, bg: :city, tint: "#8890B0",
    map: [
      "..................",
      "..A---S-----0.....",
      "......|...........",
      "......+---W---B...",
      "......|...|.......",
      "......1...2.......",
      "..................",
      "..................",
      ".................."
    ]
  },
  {
    name: "06: MIDNIGHT CARGO",
    goal: 10, night: true, bg: :city, tint: "#384888",
    map: [
      "......B...........",
      "......|...........",
      "..A---U---S---0...",
      "..........|.......",
      "..C---S---+---1...",
      "......|...|.......",
      "......2...3.......",
      "..................",
      ".................."
    ]
  },
  {
    name: "07: ALPINE SWITCHBACK",
    goal: 10, night: false, bg: :mountain, tint: "#88A8D0",
    map: [
      "..................",
      "..A---S---U---0...",
      "......|...|.......",
      "......R---+-S-1...",
      "..........|.|.....",
      "......3---L.2.....",
      "..................",
      "..................",
      ".................."
    ]
  },
  {
    name: "08: NIGHT FREIGHT",
    goal: 12, night: true, bg: :city, tint: "#303870",
    map: [
      "..........B.......",
      "..........|.......",
      "..A---S---+-W-1...",
      "......|...|.|.....",
      "..C---U---S-+-0...",
      "..........|.|.....",
      "..........2.3.....",
      "..................",
      ".................."
    ]
  },
  {
    name: "09: METROPOLIS HUB",
    goal: 14, night: true, bg: :cyber, tint: "#5060B0",
    map: [
      "......B...D.......",
      "......|...|.......",
      "..A---S---+-S-0...",
      "......|...|.|.....",
      "......R---+-U-1...",
      "..........|.......",
      "......2---L...3...",
      "..................",
      ".................."
    ]
  },
  {
    name: "10: GRAND CENTRAL",
    goal: 16, night: true, bg: :cyber, tint: "#8040A8",
    map: [
      "......B.....D.....",
      "......|.....|.....",
      "..A---U--S--+--0..",
      ".........|..|.....",
      "..C---S--+--W--1..",
      "......|..|..|.....",
      "......2..3..R--0..",
      "..................",
      ".................."
    ]
  },
  {
    name: "ENDLESS RUSH",
    goal: 999, night: false, bg: :city, tint: "#6888B0",
    map: [
      "......B.....D.....",
      "......|.....|.....",
      "..A---S--U--+--0..",
      "......|..|..|.....",
      "..C---U--S--+--1..",
      ".........|..|.....",
      "......2..3..R--0..",
      "..................",
      ".................."
    ]
  }
]

class TitleScene
  def initialize
    @stars = save_get("stars", {})
    @endless_best = save_get("endless_best", 0)
    @sel = 0
    @tick = 0
    music(:rail_bgm, true, 0.62)
  end

  def update
    @tick += 1
    @sel = (@sel - 1 + $timetables.size) % $timetables.size if btnp(:left)
    @sel = (@sel + 1) % $timetables.size if btnp(:right)
    @sel = (@sel - 4 + $timetables.size) % $timetables.size if btnp(:up)
    @sel = (@sel + 4) % $timetables.size if btnp(:down)

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 88 && my <= 204
        col = ((mx - 28) / 108).to_i
        row = ((my - 88) / 38).to_i
        if col >= 0 && col < 4 && row >= 0 && row < 3
          idx = row * 4 + col
          if idx < $timetables.size
            if @sel == idx
              start_shift
              return
            else
              @sel = idx
              sfx(:select)
            end
          end
        end
      elsif my >= 214 && my <= 242 && mx >= 140 && mx <= 340
        start_shift
        return
      end
    end

    start_shift if btnp(1) || btnp(2)
  end

  def start_shift
    sfx(:whistle)
    run RailScene.new({ idx: @sel })
  end

  def draw
    cls(0)
    bg(:city, dim: 0.52, tint: "#5078A8", scroll_x: @tick * 0.35, mirror_x: true)

    # Decorative crossing train
    tx = ((@tick * 2.2) % 540) - 40
    spr(spr_id(:loco, 0), tx, 50)
    spr(:wagon, tx - 18, 50)
    spr(:wagon, tx - 36, 50)

    print_text("HYPER RAIL EXPRESS", 240, 14, 10, 16, 1.0, :center, 0, 2)
    print_text("SWITCH TRACKS & GUIDE TRAINS TO MATCHING STATIONS", 240, 36, 12, 8, 1.0, :center, 0)

    i = 0
    while i < $timetables.size
      col = i % 4
      row = i / 4
      bx = 28 + col * 108
      by = 88 + row * 38
      sel = (@sel == i)
      rectfill(bx, by, 100, 32, sel ? 1 : 0, 0.88)
      rect(bx, by, 100, 32, sel ? 10 : 12, sel ? 2 : 1)

      lbl = i == 10 ? "ENDLESS" : "DIA #{i + 1}"
      print_text(lbl, bx + 50, by + 5, sel ? 10 : 7, 8, 1.0, :center, 0)
      if i == 10
        print_text("BEST:#{@endless_best}", bx + 50, by + 18, 11, 8, 1.0, :center, 0)
      else
        sc = (@stars[i.to_s] || 0).to_i
        st_s = ""
        k = 0
        while k < 3
          st_s += (k < sc ? "★" : "☆")
          k += 1
        end
        print_text(st_s, bx + 50, by + 18, sc > 0 ? 10 : 5, 8, 1.0, :center, 0)
      end
      i += 1
    end

    rectfill(130, 214, 220, 24, 1, 0.92)
    rect(130, 214, 220, 24, 10, 2)
    print_text("START #{$timetables[@sel][:name]} (Z)", 240, 222, 10, 8, 1.0, :center, 0)
    print_text("CLICK SWITCH / Z: TOGGLE   WHEEL/X: SPEED 1x-3x", 240, 248, 7, 8, 1.0, :center, 0)
  end
end

class RailScene
  def initialize(opts)
    @idx = opts[:idx] || 0
    @spec = $timetables[@idx]
    @w = $cfg[:w]
    @h = $cfg[:h]
    @ts = $cfg[:ts]
    @cols = $cfg[:cols]
    @rows = $cfg[:rows]
    @ox = $cfg[:ox]
    @oy = $cfg[:oy]

    @lightmap = create_surface(@w, @h, :gpu) if @spec[:night]
    @grid = []
    @switches = []
    @spawners = []
    @stations = []
    @station_colors = []
    @trains = []
    @particles = []
    @popups = []

    @sel_sw = 0
    @speed_mult = 1
    @delivered = 0
    @mistakes = 0
    @score = 0
    @spawn_t = 45
    @tick = 0
    @state = :play
    @state_t = 0

    parse_map
  end

  def parse_map
    r = 0
    while r < @rows
      line_s = @spec[:map][r]
      row = []
      c = 0
      while c < @cols
        ch = line_s[c]
        row << ch
        if ch == "S" || ch == "U" || ch == "W" || ch == "V"
          @switches << { c: c, r: r, kind: ch, branch: false }
        elsif ch == "A" || ch == "B" || ch == "C" || ch == "D"
          cid = ch == "A" ? 0 : (ch == "B" ? 1 : (ch == "C" ? 2 : 3))
          dir = (r == 0) ? 1 : 0
          @spawners << { c: c, r: r, col_id: cid, dir: dir }
        elsif ch == "0" || ch == "1" || ch == "2" || ch == "3"
          cid = ch.to_i
          @stations << { c: c, r: r, col_id: cid }
          @station_colors << cid if @station_colors.index(cid).nil?
        end
        c += 1
      end
      @grid << row
      r += 1
    end
  end

  def update
    if @state != :play
      @state_t += 1
      if @state_t > 30 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        if @state == :win && @idx + 1 < $timetables.size - 1
          run RailScene.new({ idx: @idx + 1 })
        else
          run TitleScene.new
        end
      end
      return
    end

    handle_input

    steps = @speed_mult
    si = 0
    while si < steps
      step_simulation
      break if @state != :play
      si += 1
    end
  end

  def handle_input
    w = mouse_wheel
    if w > 0
      @speed_mult = (@speed_mult + 1).clamp(1, 3)
      sfx(:click)
    elsif w < 0
      @speed_mult = (@speed_mult - 1).clamp(1, 3)
      sfx(:click)
    elsif btnp(2)
      @speed_mult = (@speed_mult % 3) + 1
      sfx(:click)
    end

    if !@switches.empty?
      @sel_sw = (@sel_sw - 1 + @switches.size) % @switches.size if btnp(:left) || btnp(:up)
      @sel_sw = (@sel_sw + 1) % @switches.size if btnp(:right) || btnp(:down)
      if btnp(1)
        toggle_switch(@switches[@sel_sw])
      end
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      c = ((mx - @ox) / @ts).to_i
      r = ((my - @oy) / @ts).to_i
      i = 0
      while i < @switches.size
        sw = @switches[i]
        if (sw[:c] - c).abs <= 1 && (sw[:r] - r).abs <= 1
          @sel_sw = i
          toggle_switch(sw)
          break
        end
        i += 1
      end
    end
  end

  def toggle_switch(sw)
    sw[:branch] = !sw[:branch]
    sfx(:switch_clk, -1, 0.7, sw[:branch] ? 1.2 : 0.9)
  end

  def step_simulation
    @tick += 1
    if (@tick % 18) == 0 && !@trains.empty?
      tone(110, 0.025, :triangle, 0.14, 0.0)
    end

    @spawn_t -= 1
    if @spawn_t <= 0
      @spawn_t = (@idx == 10) ? [90, $cfg[:spawn_iv] - @delivered * 4].max : $cfg[:spawn_iv]
      sp = @spawners[rand(@spawners.size)]
      cid = @station_colors.empty? ? sp[:col_id] : @station_colors[rand(@station_colors.size)]
      @trains << {
        x: (@ox + sp[:c] * @ts + @ts * 0.5).to_f,
        y: (@oy + sp[:r] * @ts + @ts * 0.5).to_f,
        c: sp[:c],
        r: sp[:r],
        dir: sp[:dir],
        col_id: cid,
        prog: 0.0,
        trail: []
      }
      sfx(:whistle, -1, 0.45, 0.9 + cid * 0.1)
    end

    move_trains
    update_fx
    check_collisions
  end

  def exit_dir_for_tile(c, r, in_dir)
    ch = @grid[r][c]
    # Check switches
    i = 0
    while i < @switches.size
      sw = @switches[i]
      if sw[:c] == c && sw[:r] == r
        if sw[:kind] == "S"
          return sw[:branch] ? 1 : 0
        elsif sw[:kind] == "U"
          return sw[:branch] ? 3 : 0
        elsif sw[:kind] == "W"
          return sw[:branch] ? 1 : 2
        elsif sw[:kind] == "V"
          return sw[:branch] ? 3 : 2
        end
      end
      i += 1
    end

    case ch
    when "-", "+"
      return in_dir
    when "|"
      return in_dir
    when "r"
      return in_dir == 2 ? 1 : 0
    when "l"
      return in_dir == 0 ? 1 : 2
    when "R"
      return in_dir == 1 ? 0 : 3
    when "L"
      return in_dir == 1 ? 2 : 3
    end
    in_dir
  end

  def move_trains
    spd = $cfg[:train_spd]
    i = @trains.size - 1
    while i >= 0
      tr = @trains[i]
      tr[:trail] << [tr[:x], tr[:y]]
      tr[:trail].shift if tr[:trail].size > 10

      dx = tr[:dir] == 0 ? 1 : (tr[:dir] == 2 ? -1 : 0)
      dy = tr[:dir] == 1 ? 1 : (tr[:dir] == 3 ? -1 : 0)
      tr[:x] += dx * spd
      tr[:y] += dy * spd
      tr[:prog] += spd

      if tr[:prog] >= @ts
        tr[:prog] -= @ts
        tr[:c] += dx
        tr[:r] += dy

        if tr[:c] < 0 || tr[:c] >= @cols || tr[:r] < 0 || tr[:r] >= @rows
          on_derail(tr, "OUT OF TRACK!")
          @trains.delete_at(i)
          i -= 1
          next
        end

        ch = @grid[tr[:r]][tr[:c]]
        if ch == "."
          on_derail(tr, "DERAILED!")
          @trains.delete_at(i)
          i -= 1
          next
        elsif ch == "0" || ch == "1" || ch == "2" || ch == "3"
          st_col = ch.to_i
          if st_col == tr[:col_id]
            @delivered += 1
            @score += 100
            play_station_melody(st_col)
            @popups << { x: tr[:x], y: tr[:y] - 12, txt: "+100!", col: 11, t: 36 }
            if @delivered >= @spec[:goal]
              win_stage
              return
            end
          else
            @mistakes += 1
            sfx(:cancel, -1, 0.85, 0.7)
            @popups << { x: tr[:x], y: tr[:y] - 12, txt: "WRONG!", col: 8, t: 36 }
            if @mistakes >= 3
              lose_stage
              return
            end
          end
          @trains.delete_at(i)
          i -= 1
          next
        else
          tr[:dir] = exit_dir_for_tile(tr[:c], tr[:r], tr[:dir])
        end
      end
      i -= 1
    end
  end

  def play_station_melody(cid)
    base = [523.3, 587.3, 659.3, 784.0][cid % 4]
    tone(base, 0.08, :triangle, 0.55, 120.0)
  end

  def on_derail(tr, msg)
    @mistakes += 1
    sfx(:explode, -1, 0.85, 0.9)
    @popups << { x: tr[:x], y: tr[:y] - 12, txt: msg, col: 8, t: 40 }
    if @mistakes >= 3
      lose_stage
    end
  end

  def check_collisions
    i = 0
    while i < @trains.size
      a = @trains[i]
      j = i + 1
      while j < @trains.size
        b = @trains[j]
        if hypot(a[:x] - b[:x], a[:y] - b[:y]) < 12.0
          sfx(:explode, -1, 0.95, 0.7)
          @popups << { x: a[:x], y: a[:y] - 12, txt: "CRASH!", col: 8, t: 45 }
          lose_stage
          return
        end
        j += 1
      end
      i += 1
    end
  end

  def win_stage
    sfx(:clear)
    star_cnt = @mistakes == 0 ? 3 : (@mistakes == 1 ? 2 : 1)
    stars = save_get("stars", {})
    prev = (stars[@idx.to_s] || 0).to_i
    if star_cnt > prev
      stars[@idx.to_s] = star_cnt
      save_set("stars", stars)
    end
    @earned_stars = star_cnt
    @state = :win
    @state_t = 0
  end

  def lose_stage
    sfx(:gameover)
    if @idx == 10
      eb = save_get("endless_best", 0)
      save_set("endless_best", @delivered) if @delivered > eb
    end
    @state = :lose
    @state_t = 0
  end

  def update_fx
    i = @popups.size - 1
    while i >= 0
      @popups[i][:y] -= 0.4
      @popups[i][:t] -= 1
      @popups.delete_at(i) if @popups[i][:t] <= 0
      i -= 1
    end
  end

  def draw
    cls(0)
    bg(@spec[:bg], dim: @spec[:night] ? 0.65 : 0.45, tint: @spec[:tint])

    draw_tracks
    draw_trains
    draw_night_lights if @spec[:night]
    blend(:normal)
    draw_popups
    draw_hud
    draw_overlay if @state != :play
  end

  def draw_tracks
    ox = @ox
    oy = @oy
    ts = @ts
    half = ts / 2
    tcols = [8, 12, 11, 10]

    r = 0
    while r < @rows
      c = 0
      while c < @cols
        ch = @grid[r][c]
        if ch != "."
          px = ox + c * ts
          py = oy + r * ts
          cx = px + half
          cy = py + half

          if ch == "-" || ch == "+"
            line(px, cy, px + ts, cy, 6, 4)
            line(px, cy, px + ts, cy, 5, 2)
          end
          if ch == "|" || ch == "+"
            line(cx, py, cx, py + ts, 6, 4)
            line(cx, py, cx, py + ts, 5, 2)
          end
          if ch == "r"
            line(cx, cy, px + ts, cy, 6, 4)
            line(cx, cy, cx, py + ts, 6, 4)
          elsif ch == "l"
            line(px, cy, cx, cy, 6, 4)
            line(cx, cy, cx, py + ts, 6, 4)
          elsif ch == "R"
            line(cx, py, cx, cy, 6, 4)
            line(cx, cy, px + ts, cy, 6, 4)
          elsif ch == "L"
            line(cx, py, cx, cy, 6, 4)
            line(px, cy, cx, cy, 6, 4)
          elsif ch == "A" || ch == "B" || ch == "C" || ch == "D"
            cid = ch == "A" ? 0 : (ch == "B" ? 1 : (ch == "C" ? 2 : 3))
            rectfill(px + 3, py + 3, 18, 18, tcols[cid])
            rect(px + 3, py + 3, 18, 18, 7, 1)
            print_text("IN", cx, cy - 4, 0, 8, 1.0, :center)
          elsif ch == "0" || ch == "1" || ch == "2" || ch == "3"
            cid = ch.to_i
            rectfill(px + 2, py + 2, 20, 20, tcols[cid])
            rect(px + 2, py + 2, 20, 20, 7, 2)
            print_text("ST", cx, cy - 4, 0, 8, 1.0, :center)
          end
        end
        c += 1
      end
      r += 1
    end

    # Draw switches clearly with direction arrow
    i = 0
    while i < @switches.size
      sw = @switches[i]
      px = ox + sw[:c] * ts
      py = oy + sw[:r] * ts
      cx = px + half
      cy = py + half
      sel = (@sel_sw == i)

      rectfill(cx - 8, cy - 8, 16, 16, sel ? 1 : 0, 0.9)
      rect(cx - 8, cy - 8, 16, 16, sel ? 10 : 7, sel ? 2 : 1)

      # Show active branch line in bright yellow/cyan
      col = sw[:branch] ? 10 : 12
      if sw[:kind] == "S"
        line(cx, cy, sw[:branch] ? cx : px + ts, sw[:branch] ? py + ts : cy, col, 3)
      elsif sw[:kind] == "U"
        line(cx, cy, sw[:branch] ? cx : px + ts, sw[:branch] ? py : cy, col, 3)
      elsif sw[:kind] == "W"
        line(cx, cy, sw[:branch] ? cx : px, sw[:branch] ? py + ts : cy, col, 3)
      elsif sw[:kind] == "V"
        line(cx, cy, sw[:branch] ? cx : px, sw[:branch] ? py : cy, col, 3)
      end
      i += 1
    end
  end

  def draw_trains
    tcols = [8, 12, 11, 10]
    i = 0
    while i < @trains.size
      tr = @trains[i]
      c = tcols[tr[:col_id] % 4]
      if tr[:trail].size >= 2
        prev = tr[:trail][0]
        circfill(prev[0], prev[1], 5, c, 0.7)
        circ(prev[0], prev[1], 5, 7, 0.7)
      end
      pal(8, c)
      spr(spr_id(:loco, 0), tr[:x] - 8, tr[:y] - 8, tr[:dir] == 2)
      pal
      i += 1
    end
  end

  def draw_night_lights
    render_to(@lightmap) do
      cls(0, 0.76)
      blend(:erase)
      i = 0
      while i < @stations.size
        st = @stations[i]
        circfill(@ox + st[:c] * @ts + 12, @oy + st[:r] * @ts + 12, 34, 0, 1.0)
        i += 1
      end
      i = 0
      while i < @trains.size
        tr = @trains[i]
        ang = tr[:dir] == 0 ? 0.0 : (tr[:dir] == 1 ? 1.57 : (tr[:dir] == 2 ? 3.14159 : -1.57))
        x1 = tr[:x] + cos(ang - 0.35) * 68
        y1 = tr[:y] + sin(ang - 0.35) * 68
        x2 = tr[:x] + cos(ang + 0.35) * 68
        y2 = tr[:y] + sin(ang + 0.35) * 68
        circfill(tr[:x], tr[:y], 20, 0, 1.0)
        trifill(tr[:x], tr[:y], x1, y1, x2, y2, 0, 1.0)
        i += 1
      end
      blend(:normal)
    end
    draw_surface(@lightmap, 0, 0)
  end

  def draw_popups
    i = 0
    while i < @popups.size
      p = @popups[i]
      print_text(p[:txt], p[:x], p[:y], p[:col], 8, 1.0, :center, 0)
      i += 1
    end
  end

  def draw_hud
    rectfill(0, 0, @w, 20, 0, 0.88)
    print_text(@spec[:name], 10, 6, 10, 8, 1.0, :left, 0)
    goal_str = @idx == 10 ? "DELIVERED: #{@delivered}" : "ARRIVED: #{@delivered}/#{@spec[:goal]}"
    print_text(goal_str, 240, 6, 11, 8, 1.0, :center, 0)
    print_text("ERR:#{@mistakes}/3  SPD:#{@speed_mult}x", 470, 6, @mistakes >= 2 ? 8 : 12, 8, 1.0, :right, 0)

    rectfill(0, 246, @w, 24, 0, 0.88)
    print_text("CLICK SWITCH OR ARROWS+Z: TOGGLE TRACK   WHEEL/X: SPEED", 240, 254, 7, 8, 1.0, :center, 0)
  end

  def draw_overlay
    rectfill(110, 74, 260, 112, 0, 0.92)
    b_col = (@state == :win) ? 11 : 8
    rect(110, 74, 260, 112, b_col, 2)
    title = (@state == :win) ? "TIMETABLE COMPLETE!" : "RAILWAY INCIDENT..."
    print_text(title, 240, 92, b_col, 16, 1.0, :center, 0)
    print_text("DELIVERED: #{@delivered}   SCORE: #{@score}", 240, 124, 7, 8, 1.0, :center, 0)
    print_text("PRESS Z OR CLICK TO CONTINUE", 240, 152, 10, 8, 1.0, :center, 0)
  end
end

run TitleScene.new
__END__
@PALETTE 1
1: #18182E
5: #505870
6: #B4C4DC
7: #FFFFFF
8: #FF2454
A: #FFE438
B: #30E870
C: #30B8FF

@SPRITE :loco 16x16 pal:1
................
................
....11111111....
...1888888881...
..188778888881..
..188778888881..
.118888888888AA1
15588888888887A1
1555555555555511
.11001100110011.
..111..11..111..
................
................
................
................
................

@SPRITE :wagon 16x16 pal:1
................
................
................
..111111111111..
.1CCCCCCCCCCCC1.
.1CC77CCCC77CC1.
.1CCCCCCCCCCCC1.
.15555555555551.
..110011110011..
...111....111...
................
................
................
................
................
................

@SFX :switch_clk
wave:square freq:620->420 dur:0.04 env:decay vol:0.5

@SFX :whistle
wave:triangle freq:587->659 dur:0.22 env:flat vol:0.55

@MUSIC :rail_bgm
ch0 wave=pulse vol=4 T136 L8 O4 c e g > c < g e c e  f a > c f c < a f a  g b > d g d < b g b  c e g > c4 < c4
ch1 wave=tri vol=5 T136 L4 O3 c g f c  g d c g
ch2 wave=noise vol=2 T136 L8 O6 c r c r c r c c
