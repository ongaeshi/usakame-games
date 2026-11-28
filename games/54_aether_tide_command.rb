config(
  title: "AETHER TIDE COMMAND",
  width: 480,
  height: 270,
  save_id: "aether_tide_cmd",
  save_salt: "p4g54at5"
)

$cfg = {
  w: 480,
  h: 270,
  gw: 96,
  gh: 54,
  scale: 4,
  ox: 48,
  oy: 22,
  sim_interval: 3,
  start_energy: 60,
  max_energy: 160,
  energy_regen: 0.28,
  relay_range: 18.0
}

$towers = [
  { id: :relay, name: "RELAY", cost: 15, col: 12, range: 18, desc: "EXTEND ENERGY NET" },
  { id: :cannon, name: "CANNON", cost: 30, col: 10, range: 16, desc: "BLAST AETHER TIDE" },
  { id: :purifier, name: "PURIFIER", cost: 45, col: 11, range: 12, desc: "SEAL NEARBY EMITTER" },
  { id: :barrier, name: "BARRIER", cost: 10, col: 7, range: 4, desc: "DAM FLOW WALL" }
]

$stages = [
  { name: "01: OUTPOST DELTA", rate: 0.16, core: [14, 27], emitters: [[80, 27, 100]], walls: [[46, 12, 46, 22], [46, 32, 46, 42]] },
  { name: "02: TWIN CHANNELS", rate: 0.18, core: [12, 27], emitters: [[82, 12, 110], [82, 41, 110]], walls: [[36, 23, 60, 30]] },
  { name: "03: CENTRAL BASIN", rate: 0.20, core: [48, 27], emitters: [[10, 10, 110], [85, 43, 110]], walls: [[32, 15, 34, 38], [62, 15, 64, 38]] },
  { name: "04: CRESCENT RIDGE", rate: 0.22, core: [14, 44], emitters: [[82, 10, 125], [82, 42, 125]], walls: [[38, 0, 40, 30], [58, 24, 60, 53]] },
  { name: "05: THREE-WAY SURGE", rate: 0.23, core: [12, 27], emitters: [[78, 10, 120], [84, 27, 130], [78, 43, 120]], walls: [[42, 16, 44, 38]] },
  { name: "06: LABYRINTH LOCK", rate: 0.25, core: [12, 10], emitters: [[84, 44, 140], [50, 44, 120]], walls: [[28, 0, 30, 36], [56, 18, 58, 53]] },
  { name: "07: CALDERA RING", rate: 0.27, core: [48, 27], emitters: [[10, 10, 130], [85, 10, 130], [10, 43, 130], [85, 43, 130]], walls: [] },
  { name: "08: AETHER NEXUS", rate: 0.30, core: [10, 27], emitters: [[84, 9, 150], [84, 27, 160], [84, 44, 150], [56, 27, 130]], walls: [[36, 8, 38, 20], [36, 34, 38, 46]] }
]

class TitleScene
  def initialize
    @cleared = save_get("cleared", {})
    @best_times = save_get("best_times", {})
    @sel = 0
    @tick = 0
    music(:tactical_bgm, true, 0.65)
  end

  def update
    @tick += 1
    @sel = (@sel - 1 + $stages.size) % $stages.size if btnp(:left)
    @sel = (@sel + 1) % $stages.size if btnp(:right)
    @sel = (@sel - 4 + $stages.size) % $stages.size if btnp(:up)
    @sel = (@sel + 4) % $stages.size if btnp(:down)

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 96 && my <= 196
        col = ((mx - 44) / 100).to_i
        row = ((my - 96) / 50).to_i
        if col >= 0 && col < 4 && row >= 0 && row < 2
          idx = row * 4 + col
          if @sel == idx
            start_mission
            return
          else
            @sel = idx
            sfx(:select)
          end
        end
      elsif my >= 210 && my <= 238 && mx >= 140 && mx <= 340
        start_mission
        return
      end
    end

    start_mission if btnp(1) || btnp(2)
  end

  def start_mission
    sfx(:confirm)
    run CommandScene.new({ stage_idx: @sel })
  end

  def draw
    cls(0)
    bg(:space, dim: 0.48, tint: "#7040B8", scroll_x: @tick * 0.2, mirror_x: true)

    # Decorative rising tide wave at bottom
    i = 0
    while i < 24
      wh = (12 + sin(@tick * 0.08 + i * 0.45) * 6).to_i
      rectfill(i * 20, 270 - wh, 20, wh, 2, 0.45)
      rectfill(i * 20, 270 - wh, 20, 2, 14, 0.7)
      i += 1
    end

    print_text("AETHER TIDE COMMAND", 240, 18, 12, 16, 1.0, :center, 0, 2)
    print_text("FLUID CELLULAR AUTOMATON TACTICAL RTS", 240, 40, 14, 8, 1.0, :center, 0)

    clr_cnt = @cleared.size
    print_text("SECTORS PURIFIED: #{clr_cnt}/#{$stages.size}", 240, 60, 11, 8, 1.0, :center, 0)

    i = 0
    while i < $stages.size
      col = i % 4
      row = i / 4
      bx = 44 + col * 100
      by = 96 + row * 50
      sel = (@sel == i)
      done = @cleared.has_key?(i.to_s)
      rectfill(bx, by, 92, 42, sel ? 1 : 0, 0.88)
      rect(bx, by, 92, 42, sel ? 10 : (done ? 11 : 13), sel ? 2 : 1)

      print_text("SECTOR #{i + 1}", bx + 46, by + 8, sel ? 10 : 7, 8, 1.0, :center, 0)
      bt = @best_times[i.to_s]
      st_txt = done ? "CLR #{bt}s" : "UNSEALED"
      print_text(st_txt, bx + 46, by + 24, done ? 11 : 8, 8, 1.0, :center, 0)
      i += 1
    end

    rectfill(130, 210, 220, 24, 1, 0.92)
    rect(130, 210, 220, 24, 10, 2)
    print_text("DEPLOY #{$stages[@sel][:name]} (Z)", 240, 218, 10, 8, 1.0, :center, 0)
    print_text("MOUSE/ARROWS: BUILD  WHEEL/X: TOWER  RCLICK: SCRAP", 240, 248, 7, 8, 1.0, :center, 0)
  end
end

class CommandScene
  def initialize(opts)
    @s_idx = opts[:stage_idx] || 0
    @spec = $stages[@s_idx]
    @w = $cfg[:w]
    @h = $cfg[:h]
    @gw = $cfg[:gw]
    @gh = $cfg[:gh]
    @sc = $cfg[:scale]
    @ox = $cfg[:ox]
    @oy = $cfg[:oy]

    @fluid_surf = create_surface(@gw, @gh, :pixel)
    clear_surface(@fluid_surf, nil)

    @creep = []
    @terrain = [] # 0=ground, 1=wall
    @emitters = []
    @units = []
    @shots = []
    @pulses = []
    @particles = []

    @energy = $cfg[:start_energy].to_f
    @sel_tool = 0
    @cur_gx = @spec[:core][0] + 8
    @cur_gy = @spec[:core][1]
    @tick = 0
    @state = :play
    @state_t = 0

    init_map
    sync_fluid_surface
  end

  def init_map
    gw = @gw
    gh = @gh
    y = 0
    while y < gh
      crow = []
      trow = []
      x = 0
      while x < gw
        crow << 0.0
        border = (x == 0 || y == 0 || x == gw - 1 || y == gh - 1)
        trow << (border ? 1 : 0)
        x += 1
      end
      @creep << crow
      @terrain << trow
      y += 1
    end

    # Place rock walls
    i = 0
    while i < @spec[:walls].size
      wb = @spec[:walls][i]
      x = wb[0]
      while x <= wb[2]
        y = wb[1]
        while y <= wb[3]
          @terrain[y][x] = 1 if x > 0 && x < gw - 1 && y > 0 && y < gh - 1
          y += 1
        end
        x += 1
      end
      i += 1
    end

    # Core command nexus
    cx = @spec[:core][0]
    cy = @spec[:core][1]
    @units << { kind: :core, gx: cx, gy: cy, hp: 100, max_hp: 100, cd: 0, powered: true }

    # Emitters
    i = 0
    while i < @spec[:emitters].size
      em = @spec[:emitters][i]
      @emitters << { gx: em[0], gy: em[1], hp: em[2], max_hp: em[2], sealed: false }
      @creep[em[1]][em[0]] = 4.5
      i += 1
    end
  end

  def update
    if @state != :play
      @state_t += 1
      if @state_t > 25 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        if @state == :win && @s_idx + 1 < $stages.size
          run CommandScene.new({ stage_idx: @s_idx + 1 })
        else
          run TitleScene.new
        end
      end
      return
    end

    @tick += 1
    @energy = (@energy + $cfg[:energy_regen]).clamp(0.0, $cfg[:max_energy].to_f)

    handle_input

    if (@tick % $cfg[:sim_interval]) == 0
      step_fluid
      sync_fluid_surface
    end

    update_network_and_units
    update_shots_and_fx
    check_end_conditions
  end

  def handle_input
    w = mouse_wheel
    if w > 0
      @sel_tool = (@sel_tool - 1 + $towers.size) % $towers.size
      sfx(:select)
    elsif w < 0
      @sel_tool = (@sel_tool + 1) % $towers.size
      sfx(:select)
    elsif btnp(2)
      @sel_tool = (@sel_tool + 1) % $towers.size
      sfx(:select)
    end

    # Cursor via mouse or directional keys
    mx = mouse_x
    my = mouse_y
    if mx >= @ox && mx < @ox + @gw * @sc && my >= @oy && my < @oy + @gh * @sc
      @cur_gx = ((mx - @ox) / @sc).to_i.clamp(1, @gw - 2)
      @cur_gy = ((my - @oy) / @sc).to_i.clamp(1, @gh - 2)
    end

    @cur_gx = (@cur_gx - 1).clamp(1, @gw - 2) if btn(:left) && (@tick % 3 == 0)
    @cur_gx = (@cur_gx + 1).clamp(1, @gw - 2) if btn(:right) && (@tick % 3 == 0)
    @cur_gy = (@cur_gy - 1).clamp(1, @gh - 2) if btn(:up) && (@tick % 3 == 0)
    @cur_gy = (@cur_gy + 1).clamp(1, @gh - 2) if btn(:down) && (@tick % 3 == 0)

    if btnp(:mouse_l) || btnp(1)
      try_build_at(@cur_gx, @cur_gy)
    elsif btnp(:mouse_r)
      try_scrap_at(@cur_gx, @cur_gy)
    end
  end

  def in_network?(gx, gy)
    rr = $cfg[:relay_range]
    rr2 = rr * rr
    i = 0
    while i < @units.size
      u = @units[i]
      if (u[:kind] == :core || u[:kind] == :relay) && u[:powered]
        dx = gx - u[:gx]
        dy = gy - u[:gy]
        return true if dx * dx + dy * dy <= rr2
      end
      i += 1
    end
    false
  end

  def unit_near?(gx, gy, min_d = 4)
    i = 0
    while i < @units.size
      u = @units[i]
      return u if (u[:gx] - gx).abs < min_d && (u[:gy] - gy).abs < min_d
      i += 1
    end
    nil
  end

  def try_build_at(gx, gy)
    return if @terrain[gy][gx] == 1
    return if @creep[gy][gx] > 0.6
    return if unit_near?(gx, gy, 4)

    spec = $towers[@sel_tool]
    if @energy < spec[:cost]
      sfx(:cancel, -1, 0.5, 0.8)
      return
    end
    unless in_network?(gx, gy)
      sfx(:cancel, -1, 0.5, 0.7)
      return
    end

    @energy -= spec[:cost]
    @units << {
      kind: spec[:id],
      gx: gx,
      gy: gy,
      hp: spec[:id] == :barrier ? 90 : 45,
      max_hp: spec[:id] == :barrier ? 90 : 45,
      cd: 10,
      powered: true
    }
    sfx(:build_sfx, -1, 0.75, 1.0 + @sel_tool * 0.1)
  end

  def try_scrap_at(gx, gy)
    u = unit_near?(gx, gy, 4)
    if u && u[:kind] != :core
      @units.reject! { |x| x == u }
      @energy = (@energy + 8).clamp(0.0, $cfg[:max_energy].to_f)
      sfx(:cancel, -1, 0.6, 1.1)
    end
  end

  def step_fluid
    gw = @gw
    gh = @gh
    creep = @creep
    terrain = @terrain

    # 1. Emitters emit Aether fluid
    i = 0
    while i < @emitters.size
      em = @emitters[i]
      unless em[:sealed]
        ex = em[:gx]
        ey = em[:gy]
        creep[ey][ex] = (creep[ey][ex] + @spec[:rate] * 3.0).clamp(0.0, 6.0)
      end
      i += 1
    end

    # 2. Barriers block fluid flow temporarily
    ui = 0
    while ui < @units.size
      u = @units[ui]
      if u[:kind] == :barrier
        bx = u[:gx]
        by = u[:gy]
        dy = -1
        while dy <= 1
          dx = -1
          while dx <= 1
            creep[by + dy][bx + dx] *= 0.65
            dx += 1
          end
          dy += 1
        end
      end
      ui += 1
    end

    # 3. 4-neighbor cellular diffusion
    next_c = []
    y = 0
    while y < gh
      next_c << creep[y].dup
      y += 1
    end

    y = 1
    while y < gh - 1
      crow = creep[y]
      nrow = next_c[y]
      trow = terrain[y]
      x = 1
      while x < gw - 1
        if trow[x] == 0
          v = crow[x]
          if v > 0.08
            flow = v * 0.16
            # Spread to 4 neighbors if not wall
            if terrain[y][x + 1] == 0
              d = (v - creep[y][x + 1]) * 0.18
              if d > 0
                nrow[x] -= d
                next_c[y][x + 1] += d
              end
            end
            if terrain[y][x - 1] == 0
              d = (v - creep[y][x - 1]) * 0.18
              if d > 0
                nrow[x] -= d
                next_c[y][x - 1] += d
              end
            end
            if terrain[y + 1][x] == 0
              d = (v - creep[y + 1][x]) * 0.18
              if d > 0
                nrow[x] -= d
                next_c[y + 1][x] += d
              end
            end
            if terrain[y - 1][x] == 0
              d = (v - creep[y - 1][x]) * 0.18
              if d > 0
                nrow[x] -= d
                next_c[y - 1][x] += d
              end
            end
            # Slight evaporation so thin edges recede when cut off
            nrow[x] = (nrow[x] - 0.004).clamp(0.0, 6.0)
          end
        end
        x += 1
      end
      y += 1
    end
    @creep = next_c
  end

  def sync_fluid_surface
    gw = @gw
    gh = @gh
    creep = @creep
    terrain = @terrain
    surf = @fluid_surf

    y = 0
    while y < gh
      crow = creep[y]
      trow = terrain[y]
      x = 0
      while x < gw
        if trow[x] == 1
          surface_pset(surf, x, y, 5)
        else
          v = crow[x]
          if v > 2.4
            surface_pset(surf, x, y, 8)
          elsif v > 1.1
            surface_pset(surf, x, y, 14)
          elsif v > 0.35
            surface_pset(surf, x, y, 2)
          elsif v > 0.09
            surface_pset(surf, x, y, 13)
          else
            surface_pset(surf, x, y, nil)
          end
        end
        x += 1
      end
      y += 1
    end
  end

  def update_network_and_units
    # BFS connectivity from Core
    rr2 = $cfg[:relay_range] * $cfg[:relay_range]
    i = 0
    while i < @units.size
      @units[i][:powered] = (@units[i][:kind] == :core)
      i += 1
    end

    changed = true
    while changed
      changed = false
      i = 0
      while i < @units.size
        u = @units[i]
        if !u[:powered] && (u[:kind] == :relay || u[:kind] == :cannon || u[:kind] == :purifier)
          j = 0
          while j < @units.size
            p = @units[j]
            if p[:powered] && (p[:kind] == :core || p[:kind] == :relay)
              dx = u[:gx] - p[:gx]
              dy = u[:gy] - p[:gy]
              if dx * dx + dy * dy <= rr2
                u[:powered] = true
                changed = true
                break
              end
            end
            j += 1
          end
        end
        i += 1
      end
    end

    # Unit actions & fluid damage
    i = @units.size - 1
    while i >= 0
      u = @units[i]
      fl = @creep[u[:gy]][u[:gx]]
      if fl > 0.25
        u[:hp] -= fl * 0.45
        if u[:hp] <= 0 && u[:kind] != :core
          sfx(:explode, -1, 0.55, 0.8)
          @units.delete_at(i)
          i -= 1
          next
        end
      end

      if u[:powered]
        u[:cd] -= 1
        if u[:kind] == :cannon && u[:cd] <= 0
          tgt = find_creep_target(u[:gx], u[:gy], 16)
          if tgt && @energy >= 1.5
            @energy -= 1.5
            u[:cd] = 18
            ang = atan2(tgt[1] - u[:gy], tgt[0] - u[:gx])
            @shots << { x: u[:gx].to_f, y: u[:gy].to_f, vx: cos(ang) * 1.35, vy: sin(ang) * 1.35, tx: tgt[0], ty: tgt[1], t: 20 }
            sfx(:shoot, -1, 0.35, 1.3)
          else
            u[:cd] = 8
          end
        elsif u[:kind] == :purifier && u[:cd] <= 0
          u[:cd] = 38
          if @energy >= 3.0
            @energy -= 3.0
            sfx(:purify, -1, 0.65, 1.0)
            @pulses << { gx: u[:gx], gy: u[:gy], r: 2.0, max_r: 12.0, col: 11 }
            clear_fluid_circle(u[:gx], u[:gy], 8, 1.4)
            # Damage nearby emitters
            ei = 0
            while ei < @emitters.size
              em = @emitters[ei]
              if !em[:sealed]
                d = hypot(em[:gx] - u[:gx], em[:gy] - u[:gy])
                if d <= 14.0
                  em[:hp] -= 22
                  if em[:hp] <= 0
                    em[:sealed] = true
                    clear_fluid_circle(em[:gx], em[:gy], 10, 4.0)
                    sfx(:powerup, -1, 0.9, 1.2)
                  end
                end
              end
              ei += 1
            end
          end
        end
      end
      i -= 1
    end
  end

  def find_creep_target(gx, gy, range)
    best = nil
    best_d2 = range * range
    y = (gy - range).clamp(1, @gh - 2)
    y_max = (gy + range).clamp(1, @gh - 2)
    x_min = (gx - range).clamp(1, @gw - 2)
    x_max = (gx + range).clamp(1, @gw - 2)
    while y <= y_max
      x = x_min
      while x <= x_max
        if @creep[y][x] > 0.25
          d2 = (x - gx) * (x - gx) + (y - gy) * (y - gy)
          if d2 < best_d2
            best_d2 = d2
            best = [x, y]
          end
        end
        x += 2
      end
      y += 2
    end
    best
  end

  def clear_fluid_circle(cx, cy, r, amount)
    r2 = r * r
    y = (cy - r).clamp(1, @gh - 2)
    y1 = (cy + r).clamp(1, @gh - 2)
    x0 = (cx - r).clamp(1, @gw - 2)
    x1 = (cx + r).clamp(1, @gw - 2)
    while y <= y1
      x = x0
      while x <= x1
        if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2
          @creep[y][x] = (@creep[y][x] - amount).clamp(0.0, 6.0)
        end
        x += 1
      end
      y += 1
    end
  end

  def update_shots_and_fx
    i = @shots.size - 1
    while i >= 0
      s = @shots[i]
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:t] -= 1
      if hypot(s[:tx] - s[:x], s[:ty] - s[:y]) < 1.8 || s[:t] <= 0
        clear_fluid_circle(s[:tx], s[:ty], 4, 1.35)
        @particles << { x: @ox + s[:tx] * @sc, y: @oy + s[:ty] * @sc, col: 10, t: 10 }
        @shots.delete_at(i)
      end
      i -= 1
    end

    i = @pulses.size - 1
    while i >= 0
      p = @pulses[i]
      p[:r] += 0.6
      @pulses.delete_at(i) if p[:r] >= p[:max_r]
      i -= 1
    end

    i = @particles.size - 1
    while i >= 0
      @particles[i][:t] -= 1
      @particles.delete_at(i) if @particles[i][:t] <= 0
      i -= 1
    end
  end

  def check_end_conditions
    core = @units[0]
    if core[:hp] <= 0
      sfx(:gameover)
      @state = :lose
      @state_t = 0
      return
    end

    all_sealed = true
    i = 0
    while i < @emitters.size
      unless @emitters[i][:sealed]
        all_sealed = false
        break
      end
      i += 1
    end

    if all_sealed
      sfx(:clear)
      sec = (@tick / 60).to_i
      cleared = save_get("cleared", {})
      cleared[@s_idx.to_s] = true
      save_set("cleared", cleared)
      bt = save_get("best_times", {})
      prev = bt[@s_idx.to_s]
      if prev.nil? || sec < prev.to_i
        bt[@s_idx.to_s] = sec
        save_set("best_times", bt)
      end
      @state = :win
      @state_t = 0
    end
  end

  def draw
    cls(0)
    bg(:space, dim: 0.65, tint: "#304880")

    # Playfield background grid
    rectfill(@ox, @oy, @gw * @sc, @gh * @sc, 1, 0.72)
    rect(@ox - 1, @oy - 1, @gw * @sc + 2, @gh * @sc + 2, 12, 1)

    # Draw 96x54 :pixel fluid surface scaled 4.0x!
    draw_surface(@fluid_surf, @ox, @oy, scale: 4.0)

    draw_network_lines
    draw_units_and_emitters
    draw_shots_fx
    draw_cursor
    draw_hud
    draw_overlay if @state != :play
  end

  def draw_network_lines
    rr2 = $cfg[:relay_range] * $cfg[:relay_range]
    i = 0
    while i < @units.size
      a = @units[i]
      if a[:powered] && (a[:kind] == :core || a[:kind] == :relay)
        j = i + 1
        while j < @units.size
          b = @units[j]
          if b[:powered]
            dx = a[:gx] - b[:gx]
            dy = a[:gy] - b[:gy]
            if dx * dx + dy * dy <= rr2
              line(@ox + a[:gx] * @sc, @oy + a[:gy] * @sc, @ox + b[:gx] * @sc, @oy + b[:gy] * @sc, 12, 1, 0.42)
            end
          end
          j += 1
        end
      end
      i += 1
    end
  end

  def draw_units_and_emitters
    # Emitters
    i = 0
    while i < @emitters.size
      em = @emitters[i]
      ex = @ox + em[:gx] * @sc
      ey = @oy + em[:gy] * @sc
      if em[:sealed]
        circfill(ex, ey, 6, 11, 0.7)
        circ(ex, ey, 8, 7, 0.8)
      else
        r = 6 + (sin(@tick * 0.15 + i) * 2).to_i
        circfill(ex, ey, r, 8, 0.85)
        circ(ex, ey, r + 3, 14, 0.7)
        print_text("#{em[:hp]}", ex, ey - 14, 7, 8, 1.0, :center, 0)
      end
      i += 1
    end

    # Units
    i = 0
    while i < @units.size
      u = @units[i]
      ux = @ox + u[:gx] * @sc
      uy = @oy + u[:gy] * @sc
      if u[:kind] == :core
        spr(:core, ux - 8, uy - 8)
        hw = ((u[:hp] / u[:max_hp].to_f) * 20).to_i.clamp(0, 20)
        rectfill(ux - 10, uy + 10, 20, 3, 0)
        rectfill(ux - 10, uy + 10, hw, 3, 11)
      elsif u[:kind] == :relay
        circfill(ux, uy, 4, u[:powered] ? 12 : 5)
        circ(ux, uy, 5, 7, 0.7)
      elsif u[:kind] == :cannon
        rectfill(ux - 4, uy - 4, 8, 8, u[:powered] ? 10 : 5)
        rect(ux - 4, uy - 4, 8, 8, 0, 1)
      elsif u[:kind] == :purifier
        circfill(ux, uy, 5, u[:powered] ? 11 : 5)
        circ(ux, uy, 6, 7, 0.9)
      elsif u[:kind] == :barrier
        rectfill(ux - 5, uy - 5, 10, 10, 6)
        rect(ux - 5, uy - 5, 10, 10, 7, 1)
      end
      i += 1
    end
  end

  def draw_shots_fx
    blend(:add)
    i = 0
    while i < @shots.size
      s = @shots[i]
      circfill(@ox + s[:x] * @sc, @oy + s[:y] * @sc, 3, 10, 0.9)
      i += 1
    end
    i = 0
    while i < @pulses.size
      p = @pulses[i]
      circ(@ox + p[:gx] * @sc, @oy + p[:gy] * @sc, (p[:r] * @sc).to_i, p[:col], 0.65)
      i += 1
    end
    i = 0
    while i < @particles.size
      pt = @particles[i]
      circfill(pt[:x], pt[:y], 5, pt[:col], pt[:t] / 10.0)
      i += 1
    end
    blend(:normal)
  end

  def draw_cursor
    spec = $towers[@sel_tool]
    cx = @ox + @cur_gx * @sc
    cy = @oy + @cur_gy * @sc
    ok = @terrain[@cur_gy][@cur_gx] == 0 && @creep[@cur_gy][@cur_gx] <= 0.6 && in_network?(@cur_gx, @cur_gy) && @energy >= spec[:cost] && !unit_near?(@cur_gx, @cur_gy, 4)
    col = ok ? spec[:col] : 8
    circ(cx, cy, spec[:range] * @sc, col, 0.35)
    rect(cx - 5, cy - 5, 10, 10, col, 1)
  end

  def draw_hud
    rectfill(0, 0, @w, 18, 0, 0.88)
    print_text(@spec[:name], 10, 5, 10, 8, 1.0, :left, 0)
    print_text("ENERGY: #{@energy.to_i}/#{$cfg[:max_energy]}", 240, 5, 12, 8, 1.0, :center, 0)
    sealed_cnt = 0
    i = 0
    while i < @emitters.size
      sealed_cnt += 1 if @emitters[i][:sealed]
      i += 1
    end
    print_text("SEALED: #{sealed_cnt}/#{@emitters.size}", 470, 5, 11, 8, 1.0, :right, 0)

    # Bottom tower palette bar
    by = 242
    rectfill(0, by, @w, 28, 0, 0.88)
    i = 0
    while i < $towers.size
      tw = $towers[i]
      bx = 16 + i * 114
      sel = (@sel_tool == i)
      rectfill(bx, by + 3, 108, 22, sel ? 1 : 0, 0.9)
      rect(bx, by + 3, 108, 22, sel ? 10 : tw[:col], sel ? 2 : 1)
      print_text("#{tw[:name]} (#{tw[:cost]})", bx + 54, by + 10, sel ? 10 : tw[:col], 8, 1.0, :center, 0)
      i += 1
    end
  end

  def draw_overlay
    rectfill(110, 74, 260, 112, 0, 0.92)
    b_col = (@state == :win) ? 11 : 8
    rect(110, 74, 260, 112, b_col, 2)
    title = (@state == :win) ? "SECTOR PURIFIED!" : "CORE OVERRUN..."
    print_text(title, 240, 92, b_col, 16, 1.0, :center, 0)
    sec = (@tick / 60).to_i
    print_text("MISSION TIME: #{sec}s", 240, 124, 7, 8, 1.0, :center, 0)
    print_text("PRESS Z OR CLICK TO CONTINUE", 240, 152, 10, 8, 1.0, :center, 0)
  end
end

run TitleScene.new
__END__
@PALETTE 1
1: #161C2E
5: #4A546E
7: #F8FAFF
8: #FF2858
A: #FFE438
B: #34E878
C: #30B8FF
E: #FF70B8

@SPRITE :core 16x16 pal:1
....11111111....
..11CCCCCCCC11..
.1CC77CCCCCC1C1.
.1C7CCCCCCCC7C1.
1CC7CC1111CC7CC1
1CC7C1AAAA1C7CC1
1CC7C1A77A1C7CC1
1CC7C1AAAA1C7CC1
1CC7CC1111CC7CC1
.1C7CCCCCCCC7C1.
.1CC11CCCC11CC1.
..11CCCCCCCC11..
....11111111....
................
................
................

@SFX :build_sfx
wave:square freq:320->640 dur:0.08 env:decay vol:0.55

@SFX :purify
wave:triangle freq:440->880 dur:0.16 env:decay vol:0.65

@MUSIC :tactical_bgm
ch0 wave=pulse vol=4 T128 L8 O4 e g b > d c < b g e  c e g b a g e c  d f# a > c < b a f# d  e g b > e < b g e4
ch1 wave=tri vol=5 T128 L4 O2 e b c g  d a e b
ch2 wave=noise vol=2 T128 L8 O6 c r c r c r c c  c r c r c r c c
