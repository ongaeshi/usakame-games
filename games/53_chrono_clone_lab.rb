config(
  title: "CHRONO CLONE LAB",
  width: 480,
  height: 270,
  save_id: "chrono_clone_lab",
  save_salt: "p4g53cc2"
)

$cfg = {
  w: 480,
  h: 270,
  ts: 16,
  cols: 26,
  rows: 13,
  ox: 32,
  oy: 24,
  loop_frames: 360,
  max_clones: 4,
  grav: 0.28,
  max_fall: 4.8,
  move_spd: 2.1,
  jump_vy: -4.7
}

# Tile legend:
# '.' air, '#' wall, 'P' player start, 'E' exit portal
# '1' switch A, 'a' door A (opens when switch 1 pressed)
# '2' switch B, 'b' door B (opens when switch 2 pressed)
# 'L' laser emitter (shoots right until wall or player/clone body!)
# 'G' laser receiver (opens 'g' door when laser hits it? Let's make 'L' downward laser hazard that can be blocked by a clone!)
$stages = [
  {
    name: "01: FIRST ECHO",
    par: 1,
    hint: "STAND ON SW-A, PRESS X TO REWIND, THEN WALK THROUGH!",
    map: [
      "##########################",
      "#........................#",
      "#........................#",
      "#........................#",
      "#........................#",
      "#........................#",
      "#........................#",
      "#........................#",
      "#...............a........#",
      "#...............a........#",
      "#..P.....1......a.....E..#",
      "##########################",
      "##########################"
    ]
  },
  {
    name: "02: ELEVATED LOCK",
    par: 1,
    hint: "CLIMB TO THE SWITCH, WAIT 2 SEC, THEN REWIND!",
    map: [
      "##########################",
      "#........................#",
      "#........................#",
      "#........................#",
      "#........................#",
      "#........1...............#",
      "#......#####.............#",
      "#...............a........#",
      "#..####.........a........#",
      "#...............a........#",
      "#..P............a.....E..#",
      "##########################",
      "##########################"
    ]
  },
  {
    name: "03: LASER SHIELD",
    par: 1,
    hint: "BLOCK THE RED LASER BEAM WITH YOUR CLONE!",
    map: [
      "##########################",
      "#........................#",
      "#........................#",
      "#........................#",
      "#...........L............#",
      "#...........#............#",
      "#........................#",
      "#........................#",
      "#........................#",
      "#........................#",
      "#..P..................E..#",
      "##########################",
      "##########################"
    ]
  },
  {
    name: "04: DUAL RELAY",
    par: 2,
    hint: "USE TWO CLONES TO HOLD BOTH A AND B SWITCHES!",
    map: [
      "##########################",
      "#........................#",
      "#........................#",
      "#........................#",
      "#........................#",
      "#.....1.........2........#",
      "#...#####.....#####......#",
      "#..................a..b..#",
      "#..................a..b..#",
      "#..................a..b..#",
      "#..P...............a..bE.#",
      "##########################",
      "##########################"
    ]
  },
  {
    name: "05: STEPPING STONE",
    par: 1,
    hint: "STAND ON A CLONE'S HEAD TO REACH THE HIGH LEDGE!",
    map: [
      "##########################",
      "#........................#",
      "#........................#",
      "#........................#",
      "#........................#",
      "#..............#######...#",
      "#....................E...#",
      "#..................#####.#",
      "#........................#",
      "#........................#",
      "#..P.....................#",
      "##########################",
      "##########################"
    ]
  },
  {
    name: "06: TIMED CROSSING",
    par: 2,
    hint: "BLOCK THE LASER AND HOLD SWITCH A AT THE SAME TIME!",
    map: [
      "##########################",
      "#........................#",
      "#........................#",
      "#...........L............#",
      "#........................#",
      "#........................#",
      "#......1........a........#",
      "#....#####......a........#",
      "#...............a........#",
      "#...............a........#",
      "#..P............a.....E..#",
      "##########################",
      "##########################"
    ]
  },
  {
    name: "07: TOWER BOOST",
    par: 2,
    hint: "STACK TWO CLONES OR BOOST UP THE SHAFT!",
    map: [
      "##########################",
      "#........................#",
      "#.................######.#",
      "#.....................E..#",
      "#.................######.#",
      "#........................#",
      "#...........1............#",
      "#.........#####...a......#",
      "#.................a......#",
      "#.................a......#",
      "#..P..............a......#",
      "##########################",
      "##########################"
    ]
  },
  {
    name: "08: DOUBLE LASER",
    par: 2,
    hint: "SHIELD TWO LASERS IN SEQUENCE WITH TWO CLONES!",
    map: [
      "##########################",
      "#........................#",
      "#........................#",
      "#.......L.......L........#",
      "#........................#",
      "#........................#",
      "#..............a.........#",
      "#....1.........a.........#",
      "#..#####.......a.........#",
      "#..............a.........#",
      "#..P...........a......E..#",
      "##########################",
      "##########################"
    ]
  },
  {
    name: "09: VAULT MATRIX",
    par: 3,
    hint: "COORDINATE 3 CLONES: A, B, AND LASER GUARD!",
    map: [
      "##########################",
      "#........................#",
      "#........................#",
      "#.............L..........#",
      "#..1.....................#",
      "#####......2.............#",
      "#........#####....a..b...#",
      "#.................a..b...#",
      "#.................a..b...#",
      "#.................a..b...#",
      "#..P..............a..b.E.#",
      "##########################",
      "##########################"
    ]
  },
  {
    name: "10: CHRONO FINALE",
    par: 3,
    hint: "THE ULTIMATE TEMPORAL SYMPHONY!",
    map: [
      "##########################",
      "#........................#",
      "#.................######.#",
      "#......L..........a...E..#",
      "#.................a.####.#",
      "#...........2.....b......#",
      "#.........#####...b......#",
      "#...1.............a......#",
      "#.#####...........a......#",
      "#.................b......#",
      "#..P..............b......#",
      "##########################",
      "##########################"
    ]
  }
]

class TitleScene
  def initialize
    @stars = save_get("stars", {})
    @sel = 0
    @tick = 0
    music(:lab_bgm, true, 0.65)
  end

  def update
    @tick += 1
    if btnp(:left)
      @sel = (@sel - 1 + $stages.size) % $stages.size
      sfx(:select)
    elsif btnp(:right)
      @sel = (@sel + 1) % $stages.size
      sfx(:select)
    elsif btnp(:up)
      @sel = (@sel - 5 + $stages.size) % $stages.size
      sfx(:select)
    elsif btnp(:down)
      @sel = (@sel + 5) % $stages.size
      sfx(:select)
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 96 && my <= 198
        col = ((mx - 40) / 80).to_i
        row = ((my - 96) / 50).to_i
        if col >= 0 && col < 5 && row >= 0 && row < 2
          idx = row * 5 + col
          if @sel == idx
            start_stage
            return
          else
            @sel = idx
            sfx(:select)
          end
        end
      elsif my >= 210 && my <= 238 && mx >= 160 && mx <= 320
        start_stage
        return
      end
    end

    start_stage if btnp(1) || btnp(2)
  end

  def start_stage
    sfx(:confirm)
    run LabScene.new({ stage_idx: @sel })
  end

  def draw
    cls(0)
    bg(:cyber, dim: 0.55, tint: "#3898D8", scroll_x: @tick * 0.3, mirror_x: true)

    # Ghost echo sprites
    k = 0
    while k < 3
      gx = 40 + k * 14 + (sin(@tick * 0.05 + k) * 5).to_i
      spr(spr_id(:scientist, (@tick / 12) % 2), gx, 16, false, nil, 0.0, 1.0, 0.35 + k * 0.25)
      k += 1
    end

    print_text("CHRONO CLONE LAB", 240, 16, 12, 16, 1.0, :center, 0, 2)
    print_text("RECORD YOUR PAST SELF & SOLVE TEMPORAL PUZZLES", 240, 38, 10, 8, 1.0, :center, 0)

    total_stars = 0
    @stars.each { |_, v| total_stars += v.to_i }
    print_text("TOTAL STARS: #{total_stars}/#{$stages.size * 3}", 240, 58, 11, 8, 1.0, :center, 0)

    i = 0
    while i < $stages.size
      col = i % 5
      row = i / 5
      bx = 40 + col * 81
      by = 96 + row * 50
      sel = (@sel == i)
      rectfill(bx, by, 74, 42, sel ? 1 : 0, 0.88)
      rect(bx, by, 74, 42, sel ? 10 : 12, sel ? 2 : 1)

      st_cnt = (@stars[i.to_s] || 0).to_i
      star_str = ""
      s = 0
      while s < 3
        star_str += (s < st_cnt ? "★" : "☆")
        s += 1
      end
      print_text("LAB #{i + 1}", bx + 37, by + 8, sel ? 10 : 7, 8, 1.0, :center, 0)
      print_text(star_str, bx + 37, by + 24, st_cnt > 0 ? 10 : 5, 8, 1.0, :center, 0)
      i += 1
    end

    rectfill(110, 210, 260, 24, 1, 0.9)
    rect(110, 210, 260, 24, 10, 2)
    print_text("START LAB #{$stages[@sel][:name]} (Z)", 240, 218, 10, 8, 1.0, :center, 0)

    print_text("ARROWS: MOVE  Z: JUMP  X: REWIND & SPAWN CLONE  R: RESET", 240, 248, 6, 8, 1.0, :center, 0)
  end
end

class LabScene
  def initialize(opts)
    @s_idx = opts[:stage_idx] || 0
    @spec = $stages[@s_idx]
    @w = $cfg[:w]
    @h = $cfg[:h]
    @ts = $cfg[:ts]
    @cols = $cfg[:cols]
    @rows = $cfg[:rows]
    @ox = $cfg[:ox]
    @oy = $cfg[:oy]

    @clones = []
    @rec = []
    @rewind_t = 0
    @state = :play # :play, :rewind, :win
    @state_t = 0

    load_stage
  end

  def load_stage
    @grid = []
    @lasers = []
    @sw_a = []
    @sw_b = []
    @start_x = 48.0
    @start_y = 160.0
    @exit_x = 340
    @exit_y = 160

    r = 0
    while r < @rows
      line_str = @spec[:map][r]
      row = []
      c = 0
      while c < @cols
        ch = line_str[c]
        if ch == "P"
          @start_x = (c * @ts).to_f
          @start_y = (r * @ts).to_f
          row << "."
        elsif ch == "E"
          @exit_x = c * @ts
          @exit_y = r * @ts
          row << "."
        elsif ch == "L"
          @lasers << [c, r]
          row << "#"
        elsif ch == "1"
          @sw_a << [c, r]
          row << "1"
        elsif ch == "2"
          @sw_b << [c, r]
          row << "2"
        else
          row << ch
        end
        c += 1
      end
      @grid << row
      r += 1
    end

    @clones.clear
    reset_loop
  end

  def reset_loop
    @px = @start_x
    @py = @start_y
    @vx = 0.0
    @vy = 0.0
    @flip = false
    @on_ground = false
    @frame = 0
    @rec = []
    @a_active = false
    @b_active = false
    @particles = []
  end

  def update
    if @state == :win
      @state_t += 1
      if @state_t > 25 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        if @s_idx + 1 < $stages.size
          run LabScene.new({ stage_idx: @s_idx + 1 })
        else
          run TitleScene.new
        end
      end
      return
    end

    if btnp(:key_r)
      sfx(:cancel)
      load_stage
      return
    end

    if @state == :rewind
      @rewind_t -= 1
      if (@rewind_t % 2) == 0
        tone(340 + @rewind_t * 24, 0.035, :triangle, 0.38, -60)
      end
      if @rewind_t <= 0
        @state = :play
        reset_loop
      end
      return
    end

    # Check manual rewind (X) or loop end (360 frames)
    if btnp(2) || @frame >= $cfg[:loop_frames]
      trigger_rewind
      return
    end

    update_player
    @rec << [@px, @py, @flip, (@frame_jump ? true : false)]
    @frame_jump = false

    # Play clone sound events at matching frames with clone-specific pitch!
    ci = 0
    while ci < @clones.size
      cl = @clones[ci]
      if @frame < cl.size
        st = cl[@frame]
        if st[3]
          pitch = (1.08 + ci * 0.16).clamp(1.0, 2.0)
          sfx(:jump, -1, 0.42, pitch)
        end
      end
      ci += 1
    end

    update_switches
    check_lasers_and_exit
    update_particles
    @frame += 1
  end

  def trigger_rewind
    if @rec.size > 4
      @clones << @rec
      if @clones.size > $cfg[:max_clones]
        @clones.shift
      end
    end
    @state = :rewind
    @rewind_t = 22
  end

  def all_bodies
    list = [[@px, @py]]
    i = 0
    while i < @clones.size
      cl = @clones[i]
      if !cl.empty?
        idx = @frame < cl.size ? @frame : cl.size - 1
        st = cl[idx]
        list << [st[0], st[1]]
      end
      i += 1
    end
    list
  end

  def update_switches
    prev_a = @a_active
    prev_b = @b_active
    @a_active = false
    @b_active = false

    bodies = all_bodies
    i = 0
    while i < bodies.size
      bd = bodies[i]
      cx = ((bd[0] + 8) / @ts).to_i
      cy = ((bd[1] + 12) / @ts).to_i
      if cy >= 0 && cy < @rows && cx >= 0 && cx < @cols
        ch = @grid[cy][cx]
        @a_active = true if ch == "1"
        @b_active = true if ch == "2"
      end
      i += 1
    end

    if @a_active && !prev_a
      sfx(:switch_on, -1, 0.7, 1.0)
    end
    if @b_active && !prev_b
      sfx(:switch_on, -1, 0.7, 1.25)
    end
  end

  def solid_tile?(c, r)
    return true if c < 0 || r < 0 || c >= @cols || r >= @rows
    ch = @grid[r][c]
    return true if ch == "#"
    return true if ch == "a" && !@a_active
    return true if ch == "b" && !@b_active
    false
  end

  def standing_on_clone?(nx, ny)
    i = 0
    while i < @clones.size
      cl = @clones[i]
      if !cl.empty?
        idx = @frame < cl.size ? @frame : cl.size - 1
        st = cl[idx]
        if (nx + 8 - (st[0] + 8)).abs < 12 && (ny + 16) >= st[1] && (ny + 16) <= st[1] + 6 && (@py + 16) <= st[1] + 4
          return st[1]
        end
      end
      i += 1
    end
    nil
  end

  def update_player
    move = 0
    move -= 1 if btn(:left)
    move += 1 if btn(:right)
    @vx = move * $cfg[:move_spd]
    @flip = true if move < 0
    @flip = false if move > 0

    if btnp(1) && @on_ground
      @vy = $cfg[:jump_vy]
      @on_ground = false
      @frame_jump = true
      sfx(:jump, -1, 0.65, 1.0)
    end

    @vy = (@vy + $cfg[:grav]).clamp(-8.0, $cfg[:max_fall])

    ts = @ts
    # Horizontal
    nx = @px + @vx
    x0 = (nx + 2).to_i / ts
    x1 = (nx + 13).to_i / ts
    y0 = (@py + 2).to_i / ts
    y1 = (@py + 14).to_i / ts
    hx = false
    r = y0
    while r <= y1
      c = x0
      while c <= x1
        if solid_tile?(c, r)
          hx = true
          break
        end
        c += 1
      end
      break if hx
      r += 1
    end

    if hx
      if @vx > 0
        @px = (x1 * ts - 14).to_f
      elsif @vx < 0
        @px = ((x0 + 1) * ts - 2).to_f
      end
      @vx = 0.0
    else
      @px = nx
    end

    # Vertical
    ny = @py + @vy
    x0 = (@px + 2).to_i / ts
    x1 = (@px + 13).to_i / ts
    y0 = (ny + 1).to_i / ts
    y1 = (ny + 15).to_i / ts
    hy = false
    @on_ground = false
    r = y0
    while r <= y1
      c = x0
      while c <= x1
        if solid_tile?(c, r)
          hy = true
          break
        end
        c += 1
      end
      break if hy
      r += 1
    end

    if hy
      if @vy > 0
        @py = (y1 * ts - 15).to_f
        @on_ground = true
      elsif @vy < 0
        @py = ((y0 + 1) * ts - 1).to_f
      end
      @vy = 0.0
    else
      clone_top = @vy >= 0 ? standing_on_clone?(@px, ny) : nil
      if clone_top
        @py = (clone_top - 16).to_f
        @vy = 0.0
        @on_ground = true
      else
        @py = ny
      end
    end
  end

  def compute_laser_end(lc, lr)
    lx = @ox + lc * @ts + 8
    top_y = @oy + (lr + 1) * @ts
    bodies = all_bodies
    # Raycast downward against walls and all clone/player bodies
    y = top_y
    max_y = @oy + @rows * @ts
    while y < max_y
      tc = ((lx - @ox) / @ts).to_i
      tr = ((y - @oy) / @ts).to_i
      return [y, nil] if solid_tile?(tc, tr)

      bi = 0
      while bi < bodies.size
        bd = bodies[bi]
        bx = @ox + bd[0]
        by = @oy + bd[1]
        if lx >= bx + 2 && lx <= bx + 14 && y >= by + 1 && y <= by + 15
          return [y, bi]
        end
        bi += 1
      end
      y += 2
    end
    [max_y, nil]
  end

  def check_lasers_and_exit
    i = 0
    while i < @lasers.size
      lp = @lasers[i]
      res = compute_laser_end(lp[0], lp[1])
      if res[1] == 0
        # Hit real player! Rewind loop
        sfx(:hit, -1, 0.85, 0.7)
        reset_loop
        return
      end
      i += 1
    end

    if (@px - @exit_x).abs < 12 && (@py - @exit_y).abs < 12
      sfx(:clear)
      used = @clones.size
      par = @spec[:par]
      star_cnt = used <= par ? 3 : (used <= par + 1 ? 2 : 1)
      stars = save_get("stars", {})
      prev = (stars[@s_idx.to_s] || 0).to_i
      if star_cnt > prev
        stars[@s_idx.to_s] = star_cnt
        save_set("stars", stars)
      end
      @earned_stars = star_cnt
      @state = :win
      @state_t = 0
    end
  end

  def update_particles
    if (@tick_p = (@tick_p || 0) + 1) % 6 == 0
      @particles << { x: @ox + @exit_x + 8, y: @oy + @exit_y + 12, vy: -0.5, col: 11, t: 20 }
    end
    i = @particles.size - 1
    while i >= 0
      pt = @particles[i]
      pt[:y] += pt[:vy]
      pt[:t] -= 1
      @particles.delete_at(i) if pt[:t] <= 0
      i -= 1
    end
  end

  def draw
    cls(0)
    bg(:cyber, dim: 0.62, tint: "#3068A0")

    draw_lab_grid
    draw_lasers
    draw_clones_and_player
    draw_hud
    draw_win_overlay if @state == :win
  end

  def draw_lab_grid
    ox = @ox
    oy = @oy
    ts = @ts
    r = 0
    while r < @rows
      row = @grid[r]
      py = oy + r * ts
      c = 0
      while c < @cols
        ch = row[c]
        px = ox + c * ts
        if ch == "#"
          rectfill(px, py, 16, 16, 1)
          rectfill(px + 1, py + 1, 14, 14, 5)
          rect(px, py, 16, 16, 0, 1)
        elsif ch == "1"
          rectfill(px + 2, py + 12, 12, 4, @a_active ? 11 : 3)
          rect(px + 2, py + 12, 12, 4, 7, 1)
        elsif ch == "2"
          rectfill(px + 2, py + 12, 12, 4, @b_active ? 10 : 9)
          rect(px + 2, py + 12, 12, 4, 7, 1)
        elsif ch == "a"
          if @a_active
            rect(px + 2, py, 12, 16, 11, 1, 0.25)
          else
            rectfill(px + 2, py, 12, 16, 3, 0.85)
            rect(px + 2, py, 12, 16, 11, 1)
          end
        elsif ch == "b"
          if @b_active
            rect(px + 2, py, 12, 16, 10, 1, 0.25)
          else
            rectfill(px + 2, py, 12, 16, 9, 0.85)
            rect(px + 2, py, 12, 16, 10, 1)
          end
        end
        c += 1
      end
      r += 1
    end

    # Laser emitters
    i = 0
    while i < @lasers.size
      lp = @lasers[i]
      lx = ox + lp[0] * ts
      ly = oy + lp[1] * ts
      rectfill(lx + 2, ly + 8, 12, 8, 8)
      rectfill(lx + 5, ly + 13, 6, 3, 7)
      i += 1
    end

    # Exit Portal
    ex = ox + @exit_x
    ey = oy + @exit_y
    blend(:add)
    circfill(ex + 8, ey + 8, 9, 11, 0.35)
    blend(:normal)
    spr(:portal, ex, ey)
  end

  def draw_lasers
    blend(:add)
    i = 0
    while i < @lasers.size
      lp = @lasers[i]
      res = compute_laser_end(lp[0], lp[1])
      lx = @ox + lp[0] * @ts + 8
      y0 = @oy + (lp[1] + 1) * @ts
      y1 = res[0]
      line(lx, y0, lx, y1, 8, 3, 0.75)
      line(lx, y0, lx, y1, 7, 1, 0.95)
      circfill(lx, y1, 4, 8, 0.7)
      i += 1
    end

    i = 0
    while i < @particles.size
      pt = @particles[i]
      circfill(pt[:x], pt[:y], 2, pt[:col], 0.7)
      i += 1
    end
    blend(:normal)
  end

  def draw_clones_and_player
    f = (@frame / 8) % 2
    # Draw clones as translucent cyan/pink ghosts
    i = 0
    while i < @clones.size
      cl = @clones[i]
      if !cl.empty?
        idx = @frame < cl.size ? @frame : cl.size - 1
        st = cl[idx]
        spr(spr_id(:scientist, f), @ox + st[0], @oy + st[1], st[2], nil, 0.0, 1.0, 0.52)
        print_text("C#{i + 1}", @ox + st[0] + 8, @oy + st[1] - 8, 12, 8, 0.8, :center, 0)
      end
      i += 1
    end

    # Player
    spr(spr_id(:scientist, f), @ox + @px, @oy + @py, @flip)

    if @state == :rewind
      rectfill(0, 0, @w, @h, 12, 0.22)
      print_text("<< REWINDING TAPE <<", 240, 120, 7, 16, 1.0, :center, 0)
    end
  end

  def draw_hud
    rectfill(0, 0, @w, 20, 0, 0.85)
    print_text(@spec[:name], 12, 6, 10, 8, 1.0, :left, 0)
    print_text("CLONES: #{@clones.size}/#{$cfg[:max_clones]} (PAR #{@spec[:par]})", 240, 6, 12, 8, 1.0, :center, 0)
    print_text("R: RESET", 468, 6, 6, 8, 1.0, :right, 0)

    # Bottom tape timeline bar
    by = 236
    rectfill(0, by, @w, 34, 0, 0.88)
    line(0, by, @w, by, 12, 1)
    print_text(@spec[:hint], 240, by + 4, 7, 8, 1.0, :center, 0)

    bar_x = 40
    bar_w = 400
    rectfill(bar_x, by + 16, bar_w, 10, 1)
    fill_w = ((@frame.to_f / $cfg[:loop_frames]) * bar_w).to_i.clamp(0, bar_w)
    rectfill(bar_x, by + 16, fill_w, 10, @state == :rewind ? 14 : 12)
    rect(bar_x, by + 16, bar_w, 10, 7, 1)
    sec_left = (($cfg[:loop_frames] - @frame) / 60.0)
    print_text(sprintf("%.1fs", sec_left), 450, by + 17, 10, 8, 1.0, :left, 0)
  end

  def draw_win_overlay
    rectfill(110, 72, 260, 114, 0, 0.92)
    rect(110, 72, 260, 114, 11, 2)
    print_text("LAB CLEARED!", 240, 86, 11, 16, 1.0, :center, 0)
    star_str = ""
    s = 0
    while s < 3
      star_str += (s < @earned_stars ? "★ " : "☆ ")
      s += 1
    end
    print_text(star_str, 240, 116, 10, 16, 1.0, :center, 0)
    print_text("CLONES USED: #{@clones.size} (PAR #{@spec[:par]})", 240, 144, 7, 8, 1.0, :center, 0)
    print_text("PRESS Z FOR NEXT LAB", 240, 162, 12, 8, 1.0, :center, 0)
  end
end

run TitleScene.new
__END__
@PALETTE 1
1: #161C2E
3: #107850
5: #4A546E
6: #B4C2DC
7: #F8FAFF
8: #FF2858
9: #FF9420
A: #FFE438
B: #34E878
C: #30B8FF
D: #8660D8
E: #FF70B8
F: #FFD4B0

@SPRITE :scientist 16x16 pal:1
....11111111....
...1777777771...
..177667777771..
..1FFFFFFFFFF1..
..1F1CC7FF1CC1..
..1FFFFFFFFFF1..
...1177777711...
..1777CCCC7771..
.177177CC771771.
.1F1177777711F1.
..1..177771..1..
....11111111....
....15511551....
...1111..1111...
................
................
---
....11111111....
...1777777771...
..177667777771..
..1FFFFFFFFFF1..
..1F1CC7FF1CC1..
..1FFFFFFFFFF1..
..1777CCCC7771..
.177177CC771771.
.1F1177777711F1.
..1..177771..1..
...1111111111...
..1551....1551..
..111......111..
................
................
................

@SPRITE :portal 16x16 pal:1
....11111111....
..11BBBBBBBB11..
.1BB77BBBBBB3B1.
.1B7CCCCCCCC7B1.
1BBC77777777CBB1
1BBC7CCCCCC7CBB1
1BBC7C7777C7CBB1
1BBC7C7BB7C7CBB1
1BBC7C7BB7C7CBB1
1BBC7C7777C7CBB1
1BBC7CCCCCC7CBB1
1BBC77777777CBB1
.1B7CCCCCCCC7B1.
.1BB33BBBBBB3B1.
..11BBBBBBBB11..
....11111111....

@SFX :switch_on
wave:triangle freq:523->784 dur:0.09 env:decay vol:0.6

@MUSIC :lab_bgm
ch0 wave=pulse vol=4 T124 L8 O4 c e g b a g e c  f a > c e d c < a f  g b > d f e d < b g  c2 g2
ch1 wave=tri vol=5 T124 L4 O3 c g a e  f c g d  g d b g  c g c2
ch2 wave=noise vol=2 T124 L8 O6 c r c r c r c c  c r c r c r c c
