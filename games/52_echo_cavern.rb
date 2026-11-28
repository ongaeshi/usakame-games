config(
  title: "ECHO CAVERN",
  width: 320,
  height: 240,
  save_id: "echo_cavern",
  save_salt: "p4g52ec8"
)

$cfg = {
  w: 320,
  h: 240,
  ts: 16,
  room_w: 20,
  room_h: 15,
  grid_cols: 4,
  grid_rows: 3,
  grav: 0.28,
  max_fall: 4.6,
  move_spd: 1.85,
  jump_vy: -4.85,
  djump_vy: -4.45,
  dash_spd: 4.8,
  dash_frames: 12,
  dash_cd: 24,
  shot_cd: 16,
  shot_spd: 4.5
}

$areas = [
  { name: "MOSSY ENTRY", bg: :forest, tint: "#509878", bgm: :entry_bgm, dark: 0.42 },
  { name: "SUNKEN VAULT", bg: :cave, tint: "#3878C0", bgm: :cavern_bgm, dark: 0.62 },
  { name: "CRYSTAL ABYSS", bg: :cave, tint: "#9048D0", bgm: :abyss_bgm, dark: 0.74 },
  { name: "CORE SANCTUM", bg: :cyber, tint: "#D04060", bgm: :boss_bgm, dark: 0.58 }
]

$relics = {
  djump: { name: "WINGED ECHO", desc: "PRESS Z IN MIDAIR TO DOUBLE JUMP!", col: 11 },
  sonic: { name: "SONIC RESONATOR", desc: "PRESS X TO SHATTER CRYSTAL WALLS!", col: 12 },
  phase: { name: "PHASE CLOAK", desc: "TAP DIR TWICE (OR UP+X) TO PHASE DASH!", col: 14 }
}

$enemies = {
  crawler: { spr: :crawler, hp: 2, spd: 0.65, dmg: 1, col: 11 },
  wisp: { spr: :wisp, hp: 3, spd: 0.85, dmg: 1, col: 12 },
  sentinel: { spr: :sentinel, hp: 5, spd: 0.55, dmg: 1, col: 14 },
  boss: { spr: :guardian, hp: 34, spd: 1.1, dmg: 1, col: 8 }
}

class TitleScene
  def initialize
    @best_sec = save_get("best_sec", 0)
    @clears = save_get("clears", 0)
    @best_shards = save_get("best_shards", 0)
    @tick = 0
    music(:entry_bgm, true, 0.65)
  end

  def update
    @tick += 1
    if btnp(1) || btnp(2) || btnp(:mouse_l)
      sfx(:confirm)
      run CavernScene.new
    end
  end

  def draw
    cls(0)
    bg(:cave, dim: 0.48, tint: "#4888B8", scroll_x: @tick * 0.25, mirror_x: true)

    # Floating crystal sparkles
    i = 0
    while i < 12
      sx = ((i * 53 + @tick * (i % 3 == 0 ? 0.4 : 0.2)) % 320).to_i
      sy = (40 + sin(@tick * 0.04 + i) * 18 + (i * 19) % 140).to_i
      circfill(sx, sy, 1 + (i % 2), i % 2 == 0 ? 12 : 14, 0.55)
      i += 1
    end

    f = (@tick / 16) % 2
    spr(spr_id(:explorer, f), 54, 46, false, nil, 0.0, 1.5)
    spr(spr_id(:guardian, f), 240, 32, false, nil, 0.0, 1.0)

    print_text("ECHO CAVERN", 160, 20, 12, 16, 1.0, :center, 0, 2)
    print_text("MINI METROIDVANIA EXPEDITION", 160, 42, 10, 8, 1.0, :center, 0)

    rectfill(34, 72, 252, 72, 0, 0.78)
    rect(34, 72, 252, 72, 12, 1)
    print_text("RELICS TO DISCOVER:", 160, 80, 7, 8, 1.0, :center, 0)
    print_text("1. WINGED ECHO   (DOUBLE JUMP)", 160, 96, 11, 8, 1.0, :center, 0)
    print_text("2. SONIC BLASTER (BREAK CRYSTALS)", 160, 110, 12, 8, 1.0, :center, 0)
    print_text("3. PHASE CLOAK   (PASS BARRIERS)", 160, 124, 14, 8, 1.0, :center, 0)

    best_str = @best_sec > 0 ? "#{@best_sec}s" : "--"
    rectfill(34, 152, 252, 22, 0, 0.78)
    rect(34, 152, 252, 22, 5, 1)
    print_text("CLEARS:#{@clears}  BEST TIME:#{best_str}  SHARDS:#{@best_shards}/8", 160, 159, 10, 8, 1.0, :center, 0)

    pulse = (sin(@tick * 0.1) * 0.3 + 0.7).clamp(0.4, 1.0)
    rectfill(80, 184, 160, 24, 1, 0.9)
    rect(80, 184, 160, 24, 10, 2)
    print_text("ENTER CAVERN (Z)", 160, 192, 10, 8, pulse, :center, 0)

    print_text("ARROWS: MOVE  Z: JUMP  X: SONIC  2xDIR/UP+X: DASH", 160, 220, 6, 8, 1.0, :center, 0)
  end
end

class CavernScene
  def initialize
    @w = $cfg[:w]
    @h = $cfg[:h]
    @ts = $cfg[:ts]
    @rw = $cfg[:room_w]
    @rh = $cfg[:room_h]
    @cols = $cfg[:grid_cols]
    @rows = $cfg[:grid_rows]
    @mw = @rw * @cols # 80 tiles
    @mh = @rh * @rows # 45 tiles
    @ww = @mw * @ts   # 1280 px
    @wh = @mh * @ts   # 720 px

    @lightmap = create_surface(@w, @h, :gpu)
    # 20x12 pixel minimap scaled 3.0x => 60x36 px HUD
    @minimap = create_surface(20, 12, :pixel)

    @grid = []
    @visited = []
    @torches = []
    @pickups = []
    @foes = []
    @shots = []
    @particles = []
    @popups = []

    @px = 4.0 * @ts
    @py = 10.0 * @ts
    @vx = 0.0
    @vy = 0.0
    @flip = false
    @on_ground = false
    @jumps_left = 1
    @dash_t = 0
    @dash_cd = 0
    @dash_dir = 1
    @shot_cd = 0
    @inv = 0
    @hp = 6
    @max_hp = 6

    @has_djump = false
    @has_sonic = false
    @has_phase = false
    @shards = 0

    @last_tap_dir = 0
    @last_tap_t = -99
    @cur_area = -1
    @boss_active = false
    @boss_defeated = false

    @tick = 0
    @shake = 0.0
    @hitstop = 0
    @banner_txt = ""
    @banner_t = 0
    @state = :play
    @state_t = 0

    build_world
    update_minimap
    switch_area(0)
  end

  def build_world
    # Initialize 80x45 tile grid:
    # 0=air, 1=stone, 2=moss_stone, 3=crystal_block(breakable), 4=phase_gate, 5=spike, 6=platform
    y = 0
    while y < @mh
      row = []
      x = 0
      while x < @mw
        border = (x == 0 || y == 0 || x == @mw - 1 || y == @mh - 1)
        row << (border ? 1 : 0)
        x += 1
      end
      @grid << row
      y += 1
    end

    # Room borders with carved doorways between rooms
    rc = 0
    while rc < @cols
      rr = 0
      while rr < @rows
        bx = rc * @rw
        by = rr * @rh
        # Floor & ceiling of each room (with gaps for vertical shafts)
        x = 0
        while x < @rw
          @grid[by][bx + x] = (rr == 0 ? 2 : 1) if @grid[by][bx + x] == 0
          @grid[by + @rh - 1][bx + x] = (rr == 0 ? 2 : 1)
          x += 1
        end
        # Left & right walls of each room
        y = 0
        while y < @rh
          @grid[by + y][bx] = (rr == 0 ? 2 : 1)
          @grid[by + y][bx + @rw - 1] = (rr == 0 ? 2 : 1)
          y += 1
        end
        rr += 1
      end
      rc += 1
    end

    # Carve horizontal doorways (height 4 tiles)
    # Row 0: (0,0)<->(1,0)<->(2,0)<->(3,0)
    carve_h_door(1, 0, 9, 4)
    carve_h_door(2, 0, 9, 4)
    carve_h_door(3, 0, 9, 4)
    # Row 1: (0,1)<->(1,1)<->(2,1)<->(3,1)
    carve_h_door(1, 1, 9, 4)
    carve_h_door(2, 1, 9, 4)
    carve_h_door(3, 1, 9, 4)
    # Row 2: (0,2)<->(1,2)<->(2,2)<->(3,2)
    carve_h_door(1, 2, 9, 4)
    carve_h_door(2, 2, 9, 4)
    carve_h_door(3, 2, 9, 4)

    # Carve vertical shafts (width 4 tiles)
    carve_v_shaft(0, 1, 8, 4)  # (0,0)<->(0,1)
    carve_v_shaft(2, 1, 8, 4)  # (2,0)<->(2,1)
    carve_v_shaft(3, 1, 8, 4)  # (3,0)<->(3,1)
    carve_v_shaft(1, 2, 8, 4)  # (1,1)<->(1,2)
    carve_v_shaft(3, 2, 8, 4)  # (3,1)<->(3,2)

    # Decorate each room with platforms, obstacles, relics, shards & foes
    setup_room_platforms

    # Place Crystal breakable walls (tile 3) & Phase barriers (tile 4)
    # Crystal wall guarding (2,0) -> (3,0) and (1,1) -> (0,1)
    place_wall_col(3 * @rw, 9, 4, 3)
    place_wall_col(1 * @rw, 9, 4, 3)
    # Phase barrier guarding Core Sanctum (2,2) -> (3,2)
    place_wall_col(3 * @rw, 9, 4, 4)
    place_wall_col(2 * @rw, 9, 4, 4)

    # Place 3 Relics
    @pickups << { kind: :djump, x: (3 * @rw + 10) * @ts, y: 5 * @ts } # Room (3,0) high ledge (accessible via shaft from 3,1? Let's make (2,0)->(3,0) or (1,0) have Winged Echo!)
    # Better progression:
    # 1. Start (0,0) -> go right to (1,0) -> (2,0) -> down shaft to (2,1) -> get WINGED ECHO in (1,0) or (2,1)!
    # Let's place WINGED ECHO in (2,1) reachable without double jump, then DOUBLE JUMP lets you reach (3,0) / (1,1) -> SONIC RESONATOR in (1,0) high ledge -> break crystal walls -> PHASE CLOAK in (0,2) -> enter BOSS in (3,2)!
    @pickups.clear
    @pickups << { kind: :djump, x: (2 * @rw + 10) * @ts, y: (1 * @rh + 11) * @ts }
    @pickups << { kind: :sonic, x: (1 * @rw + 10) * @ts, y: (0 * @rh + 4) * @ts }
    @pickups << { kind: :phase, x: (0 * @rw + 6) * @ts, y: (2 * @rh + 11) * @ts }

    # 8 Echo Shards & Heart upgrades scattered across rooms
    shard_spots = [
      [0, 0, 15, 5], [1, 0, 4, 11], [3, 0, 14, 11], [0, 1, 5, 6],
      [3, 1, 14, 6], [1, 2, 10, 11], [2, 2, 10, 5], [3, 1, 5, 11]
    ]
    i = 0
    while i < shard_spots.size
      sp = shard_spots[i]
      @pickups << { kind: :shard, x: (sp[0] * @rw + sp[2]) * @ts, y: (sp[1] * @rh + sp[3]) * @ts }
      i += 1
    end

    @pickups << { kind: :heart, x: (1 * @rw + 15) * @ts, y: (1 * @rh + 6) * @ts }
    @pickups << { kind: :heart, x: (2 * @rw + 5) * @ts, y: (2 * @rh + 11) * @ts }

    # Torches across rooms
    rc = 0
    while rc < @cols
      rr = 0
      while rr < @rows
        @torches << [(rc * @rw + 4) * @ts + 8, (rr * @rh + 11) * @ts]
        @torches << [(rc * @rw + 15) * @ts + 8, (rr * @rh + 11) * @ts]
        rr += 1
      end
      rc += 1
    end

    # Enemies in rooms
    spawn_room_foes
  end

  def carve_h_door(rc, rr, y0, h)
    bx = rc * @rw
    by = rr * @rh
    y = y0
    while y < y0 + h
      @grid[by + y][bx] = 0
      @grid[by + y][bx - 1] = 0
      y += 1
    end
  end

  def carve_v_shaft(rc, rr, x0, w)
    bx = rc * @rw
    by = rr * @rh
    x = x0
    while x < x0 + w
      @grid[by][bx + x] = 0
      @grid[by - 1][bx + x] = 0
      x += 1
    end
  end

  def place_wall_col(x, y0, h, tile_val)
    y = y0
    while y < y0 + h
      @grid[y][x] = tile_val
      y += 1
    end
  end

  def set_plat(rc, rr, x0, y0, w, tile = 6)
    bx = rc * @rw
    by = rr * @rh
    i = 0
    while i < w
      @grid[by + y0][bx + x0 + i] = tile
      i += 1
    end
  end

  def setup_room_platforms
    # (0,0) Entry: gentle stepping stones
    set_plat(0, 0, 10, 10, 4)
    set_plat(0, 0, 13, 7, 4)
    # (1,0) High Sonic Relic ledge (needs double jump from 10->7->4)
    set_plat(1, 0, 5, 10, 4)
    set_plat(1, 0, 8, 7, 5)
    set_plat(1, 0, 8, 5, 5)
    # (2,0) Bridge over spikes
    set_plat(2, 0, 5, 11, 3)
    set_plat(2, 0, 11, 11, 3)
    set_plat(2, 0, 7, 13, 5, 5) # spikes
    # (3,0) Crystal vault
    set_plat(3, 0, 5, 10, 4)
    set_plat(3, 0, 12, 9, 4)

    # (0,1) Sunken chamber
    set_plat(0, 1, 3, 9, 4)
    set_plat(0, 1, 11, 10, 4)
    # (1,1) Central hub
    set_plat(1, 1, 4, 10, 4)
    set_plat(1, 1, 12, 8, 5)
    # (2,1) Winged Echo chamber
    set_plat(2, 1, 5, 11, 3)
    set_plat(2, 1, 12, 11, 3)
    # (3,1) Vertical tower
    set_plat(3, 1, 4, 10, 4)
    set_plat(3, 1, 12, 7, 4)

    # (0,2) Phase Cloak shrine
    set_plat(0, 2, 11, 10, 4)
    set_plat(0, 2, 4, 12, 5)
    # (1,2) Abyssal corridor
    set_plat(1, 2, 5, 10, 4)
    set_plat(1, 2, 12, 10, 4)
    # (2,2) Pre-boss trial
    set_plat(2, 2, 4, 10, 4)
    set_plat(2, 2, 9, 7, 4)
    set_plat(2, 2, 13, 10, 4)
    # (3,2) Core Sanctum Boss Arena
    set_plat(3, 2, 4, 10, 3)
    set_plat(3, 2, 13, 10, 3)
  end

  def spawn_room_foes
    # Patrol crawlers & wisps
    add_foe(:crawler, 1, 0, 13, 12)
    add_foe(:wisp, 2, 0, 10, 7)
    add_foe(:crawler, 3, 0, 10, 12)
    add_foe(:wisp, 0, 1, 12, 7)
    add_foe(:crawler, 1, 1, 13, 12)
    add_foe(:sentinel, 2, 1, 14, 12)
    add_foe(:wisp, 3, 1, 10, 8)
    add_foe(:sentinel, 0, 2, 10, 12)
    add_foe(:sentinel, 1, 2, 10, 12)
    add_foe(:wisp, 2, 2, 10, 6)
    # Boss in (3,2)
    add_foe(:boss, 3, 2, 14, 10)
  end

  def add_foe(kind, rc, rr, tx, ty)
    spec = $enemies[kind]
    px = (rc * @rw + tx) * @ts
    py = (rr * @rh + ty) * @ts
    @foes << {
      kind: kind,
      spr: spec[:spr],
      hp: spec[:hp],
      max_hp: spec[:hp],
      spd: spec[:spd],
      dmg: spec[:dmg],
      col: spec[:col],
      x: px.to_f,
      y: py.to_f,
      vx: spec[:spd],
      vy: 0.0,
      home_x: px.to_f,
      home_y: py.to_f,
      rc: rc,
      rr: rr,
      flip: false,
      flash: 0,
      cd: 60
    }
  end

  def current_room
    rc = (@px / (@rw * @ts)).to_i.clamp(0, @cols - 1)
    rr = (@py / (@rh * @ts)).to_i.clamp(0, @rows - 1)
    [rc, rr]
  end

  def area_for_room(rc, rr)
    return 3 if rc == 3 && rr == 2
    return 2 if rr == 2
    return 1 if rr == 1
    0
  end

  def switch_area(idx)
    return if @cur_area == idx
    @cur_area = idx
    ar = $areas[idx]
    music(ar[:bgm], true, 0.65)
    @banner_txt = ar[:name]
    @banner_t = 120
  end

  def update_minimap
    rm = current_room
    key = "#{rm[0]},#{rm[1]}"
    if @visited.index(key).nil?
      @visited << key
    end

    render_to(@minimap) do
      cls(0, 0.85)
      rr = 0
      while rr < @rows
        rc = 0
        while rc < @cols
          rx = 2 + rc * 4
          ry = 1 + rr * 3
          k = "#{rc},#{rr}"
          if rc == rm[0] && rr == rm[1]
            rectfill(rx, ry, 3, 2, 10)
          elsif !@visited.index(k).nil?
            col = (rc == 3 && rr == 2) ? 8 : 12
            rectfill(rx, ry, 3, 2, col)
          else
            rectfill(rx, ry, 3, 2, 1)
          end
          rc += 1
        end
        rr += 1
      end
    end
  end

  def solid_at?(tx, ty, phase_pass = false)
    return true if tx < 0 || ty < 0 || tx >= @mw || ty >= @mh
    v = @grid[ty][tx]
    return false if v == 0 || v == 5
    return false if v == 4 && phase_pass
    return false if v == 6
    true
  end

  def platform_at?(tx, ty)
    return false if tx < 0 || ty < 0 || tx >= @mw || ty >= @mh
    @grid[ty][tx] == 6
  end

  def update
    if @state != :play
      @state_t += 1
      if @state_t > 30 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        save_progress
        run TitleScene.new
      end
      return
    end

    if @hitstop > 0
      @hitstop -= 1
      return
    end

    @tick += 1
    @shake *= 0.82
    @shake = 0.0 if @shake < 0.2
    @banner_t -= 1 if @banner_t > 0
    @dash_cd -= 1 if @dash_cd > 0
    @shot_cd -= 1 if @shot_cd > 0
    @inv -= 1 if @inv > 0

    rm = current_room
    ar_idx = area_for_room(rm[0], rm[1])
    if ar_idx != @cur_area
      switch_area(ar_idx)
      update_minimap
    else
      k = "#{rm[0]},#{rm[1]}"
      update_minimap if @visited.index(k).nil?
    end

    update_player
    update_shots
    update_foes
    update_pickups
    update_fx
  end

  def update_player
    # Double-tap horizontal or Up+X for Phase Dash (once Phase Cloak acquired)
    if @has_phase && @dash_cd <= 0 && @dash_t <= 0
      tap_dir = 0
      tap_dir = -1 if btnp(:left)
      tap_dir = 1 if btnp(:right)
      if tap_dir != 0
        if tap_dir == @last_tap_dir && (@tick - @last_tap_t) <= 14
          start_dash(tap_dir)
          @last_tap_dir = 0
        else
          @last_tap_dir = tap_dir
          @last_tap_t = @tick
        end
      elsif btn(:up) && btnp(2)
        start_dash(@flip ? -1 : 1)
      end
    end

    if @dash_t > 0
      @dash_t -= 1
      @vx = @dash_dir * $cfg[:dash_spd]
      @vy = 0.0
      if (@tick % 2) == 0
        @particles << { x: @px + 8, y: @py + 8, vx: -@dash_dir * 0.5, vy: 0.0, col: 14, t: 10 }
      end
    else
      move = 0
      move -= 1 if btn(:left)
      move += 1 if btn(:right)
      @vx = move * $cfg[:move_spd]
      @flip = true if move < 0
      @flip = false if move > 0

      if btnp(1)
        if @on_ground
          @vy = $cfg[:jump_vy]
          @on_ground = false
          sfx(:jump, -1, 0.75, 1.0)
        elsif @has_djump && @jumps_left > 0
          @vy = $cfg[:djump_vy]
          @jumps_left -= 1
          sfx(:jump, -1, 0.75, 1.32)
          spawn_sparks(@px + 8, @py + 15, 11, 7)
        end
      end

      @vy = (@vy + $cfg[:grav]).clamp(-8.0, $cfg[:max_fall])
    end

    # Sonic Blaster (X)
    if btnp(2) && @shot_cd <= 0 && @dash_t <= 0 && !(btn(:up) && @has_phase)
      @shot_cd = $cfg[:shot_cd]
      dir = @flip ? -1 : 1
      @shots << {
        x: @px + 8 + dir * 6,
        y: @py + 7,
        vx: dir * $cfg[:shot_spd],
        sonic: @has_sonic,
        t: 36
      }
      sfx(@has_sonic ? :laser : :shoot, -1, 0.65, @has_sonic ? 1.15 : 1.0)
    end

    move_player_with_collision(@dash_t > 0)
  end

  def start_dash(dir)
    @dash_dir = dir
    @flip = (dir < 0)
    @dash_t = $cfg[:dash_frames]
    @dash_cd = $cfg[:dash_cd]
    @inv = $cfg[:dash_frames] + 2 if @inv < $cfg[:dash_frames]
    sfx(:dash, -1, 0.85, 1.2)
  end

  def move_player_with_collision(phase_pass)
    ts = @ts
    # Horizontal
    nx = @px + @vx
    x0 = (nx + 2).to_i / ts
    x1 = (nx + 13).to_i / ts
    y0 = (@py + 2).to_i / ts
    y1 = (@py + 14).to_i / ts
    hit_x = false
    ty = y0
    while ty <= y1
      tx = x0
      while tx <= x1
        if solid_at?(tx, ty, phase_pass)
          hit_x = true
          break
        end
        tx += 1
      end
      break if hit_x
      ty += 1
    end

    if hit_x
      if @vx > 0
        @px = (x1 * ts - 14).to_f
      elsif @vx < 0
        @px = ((x0 + 1) * ts - 2).to_f
      end
      @vx = 0.0
    else
      @px = nx.clamp(2.0, (@ww - 18).to_f)
    end

    # Vertical
    ny = @py + @vy
    x0 = (@px + 2).to_i / ts
    x1 = (@px + 13).to_i / ts
    y0 = (ny + 1).to_i / ts
    y1 = (ny + 15).to_i / ts
    hit_y = false
    @on_ground = false

    ty = y0
    while ty <= y1
      tx = x0
      while tx <= x1
        if solid_at?(tx, ty, phase_pass)
          hit_y = true
          break
        elsif @vy > 0 && platform_at?(tx, ty) && (@py + 15) <= ty * ts + 4
          hit_y = true
          break
        end
        tx += 1
      end
      break if hit_y
      ty += 1
    end

    if hit_y
      if @vy > 0
        @py = (y1 * ts - 15).to_f
        @on_ground = true
        @jumps_left = @has_djump ? 1 : 0
      elsif @vy < 0
        @py = ((y0 + 1) * ts - 1).to_f
      end
      @vy = 0.0
    else
      @py = ny.clamp(2.0, (@wh - 18).to_f)
    end

    # Spike hazard check
    cx = (@px + 8).to_i / ts
    cy = (@py + 12).to_i / ts
    if cx >= 0 && cx < @mw && cy >= 0 && cy < @mh && @grid[cy][cx] == 5 && !phase_pass
      hurt_player(1)
    end
  end

  def update_shots
    ts = @ts
    i = @shots.size - 1
    while i >= 0
      s = @shots[i]
      s[:x] += s[:vx]
      s[:t] -= 1
      tx = (s[:x] / ts).to_i
      ty = (s[:y] / ts).to_i
      rm_shot = false

      if tx < 0 || tx >= @mw || ty < 0 || ty >= @mh || s[:t] <= 0
        rm_shot = true
      else
        tile = @grid[ty][tx]
        if tile == 3 && s[:sonic]
          # Shatter entire crystal column!
          cy = ty - 3
          while cy <= ty + 3
            if cy > 0 && cy < @mh - 1 && @grid[cy][tx] == 3
              @grid[cy][tx] = 0
              spawn_sparks(tx * ts + 8, cy * ts + 8, 12, 8)
            end
            cy += 1
          end
          sfx(:explode, -1, 0.85, 1.35)
          @shake = 5.0
          @popups << { x: s[:x], y: s[:y] - 8, txt: "SHATTER!", col: 12, t: 35 }
          rm_shot = true
        elsif tile == 1 || tile == 2 || tile == 3 || tile == 4
          spawn_sparks(s[:x], s[:y], s[:sonic] ? 12 : 10, 4)
          rm_shot = true
        end
      end

      unless rm_shot
        dmg = s[:sonic] ? 2 : 1
        j = 0
        while j < @foes.size
          f = @foes[j]
          fw = f[:kind] == :boss ? 28 : 14
          if f[:hp] > 0 && (s[:x] - (f[:x] + fw * 0.5)).abs < fw * 0.6 && (s[:y] - (f[:y] + fw * 0.5)).abs < fw * 0.6
            f[:hp] -= dmg
            f[:flash] = 6
            sfx(:hit, -1, 0.7, 1.15)
            spawn_sparks(s[:x], s[:y], f[:col], 6)
            if f[:hp] <= 0
              on_foe_killed(f)
            end
            rm_shot = true
            break
          end
          j += 1
        end
      end

      @shots.delete_at(i) if rm_shot
      i -= 1
    end
    @foes.reject! { |f| f[:hp] <= 0 }
  end

  def on_foe_killed(f)
    spawn_sparks(f[:x] + 8, f[:y] + 8, f[:col], 14)
    if f[:kind] == :boss
      @boss_defeated = true
      @shake = 9.0
      @hitstop = 4
      sfx(:clear)
      stop_music
      @state = :win
      @state_t = 0
    else
      sfx(:explode, -1, 0.65, 1.2)
    end
  end

  def update_foes
    rm = current_room
    i = 0
    while i < @foes.size
      f = @foes[i]
      f[:flash] -= 1 if f[:flash] > 0
      # Only simulate foes in current or adjacent room
      if (f[:rc] - rm[0]).abs <= 1 && (f[:rr] - rm[1]).abs <= 1
        if f[:kind] == :crawler
          f[:x] += f[:vx]
          if (f[:x] - f[:home_x]).abs > 42
            f[:vx] = -f[:vx]
            f[:flip] = f[:vx] < 0
          end
        elsif f[:kind] == :wisp
          f[:x] += cos(@tick * 0.04 + i) * f[:spd]
          f[:y] = f[:home_y] + sin(@tick * 0.07 + i) * 18.0
        elsif f[:kind] == :sentinel
          dx = @px - f[:x]
          if dx.abs < 96 && (f[:rr] == rm[1])
            f[:vx] = (dx <=> 0) * f[:spd]
            f[:flip] = f[:vx] < 0
            f[:x] += f[:vx]
          end
        elsif f[:kind] == :boss && rm[0] == 3 && rm[1] == 2
          update_boss(f)
        end

        bw = f[:kind] == :boss ? 24 : 12
        if (@px + 8 - (f[:x] + bw * 0.5)).abs < (bw * 0.5 + 5) && (@py + 8 - (f[:y] + bw * 0.5)).abs < (bw * 0.5 + 5)
          hurt_player(f[:dmg])
        end
      end
      i += 1
    end
  end

  def update_boss(f)
    dx = @px - (f[:x] + 8)
    dy = @py - (f[:y] + 8)
    dist = hypot(dx, dy)
    if dist > 4.0
      f[:x] += (dx / dist) * f[:spd]
      f[:y] += (dy / dist) * (f[:spd] * 0.7)
      f[:flip] = dx < 0
    end
    f[:cd] -= 1
    if f[:cd] <= 0
      f[:cd] = 72
      # Fire 3-way echo orbs
      ang_base = atan2(dy, dx)
      k = -1
      while k <= 1
        a = ang_base + k * 0.35
        @particles << { x: f[:x] + 16, y: f[:y] + 16, vx: cos(a) * 2.1, vy: sin(a) * 2.1, col: 8, t: 90, enemy_shot: true }
        k += 1
      end
      sfx(:laser, -1, 0.6, 0.75)
    end
  end

  def hurt_player(dmg)
    return if @inv > 0
    @hp -= dmg
    @inv = 45
    @shake = 5.5
    @hitstop = 3
    sfx(:hit, -1, 0.9, 0.75)
    spawn_sparks(@px + 8, @py + 8, 8, 10)
    if @hp <= 0
      @hp = 0
      sfx(:gameover)
      stop_music
      @state = :gameover
      @state_t = 0
    end
  end

  def update_pickups
    i = @pickups.size - 1
    while i >= 0
      pk = @pickups[i]
      if (@px - pk[:x]).abs < 14 && (@py - pk[:y]).abs < 14
        k = pk[:kind]
        if k == :djump
          @has_djump = true
          @jumps_left = 1
          show_relic(:djump)
        elsif k == :sonic
          @has_sonic = true
          show_relic(:sonic)
        elsif k == :phase
          @has_phase = true
          show_relic(:phase)
        elsif k == :shard
          @shards += 1
          pitch = (1.0 + @shards * 0.08).clamp(1.0, 1.8)
          sfx(:coin, -1, 0.85, pitch)
          @popups << { x: pk[:x] + 8, y: pk[:y], txt: "SHARD #{@shards}/8", col: 10, t: 45 }
        elsif k == :heart
          @max_hp += 1
          @hp = @max_hp
          sfx(:heal, -1, 0.9, 1.1)
          @popups << { x: pk[:x] + 8, y: pk[:y], txt: "MAX HP +1!", col: 8, t: 45 }
        end
        @pickups.delete_at(i)
      end
      i -= 1
    end
  end

  def show_relic(key)
    rel = $relics[key]
    sfx(:powerup, -1, 0.95, 1.0)
    @banner_txt = "#{rel[:name]}: #{rel[:desc]}"
    @banner_t = 180
    spawn_sparks(@px + 8, @py + 8, rel[:col], 18)
  end

  def spawn_sparks(x, y, col, n)
    i = 0
    while i < n
      a = rand * Math::PI * 2.0
      sp = 0.6 + rand * 2.2
      @particles << { x: x.to_f, y: y.to_f, vx: cos(a) * sp, vy: sin(a) * sp, col: col, t: 18 + rand(12) }
      i += 1
    end
  end

  def update_fx
    i = @particles.size - 1
    while i >= 0
      pt = @particles[i]
      pt[:x] += pt[:vx]
      pt[:y] += pt[:vy]
      pt[:t] -= 1
      if pt[:enemy_shot] && (@px + 8 - pt[:x]).abs < 7 && (@py + 8 - pt[:y]).abs < 7
        hurt_player(1)
        pt[:t] = 0
      end
      @particles.delete_at(i) if pt[:t] <= 0
      i -= 1
    end

    i = @popups.size - 1
    while i >= 0
      @popups[i][:y] -= 0.4
      @popups[i][:t] -= 1
      @popups.delete_at(i) if @popups[i][:t] <= 0
      i -= 1
    end
  end

  def save_progress
    sec = (@tick / 60).to_i
    bs = save_get("best_shards", 0)
    save_set("best_shards", @shards) if @shards > bs
    if @state == :win
      save_set("clears", save_get("clears", 0) + 1)
      bt = save_get("best_sec", 0)
      save_set("best_sec", sec) if bt == 0 || sec < bt
    end
  end

  def draw
    cls(0)
    ar = $areas[@cur_area]
    cam_x = (@px + 8 - @w * 0.5).clamp(0.0, (@ww - @w).to_f)
    cam_y = (@py + 8 - @h * 0.5).clamp(0.0, (@wh - @h).to_f)
    sx = @shake > 0 ? (rand * @shake * 2.0 - @shake) : 0.0
    sy = @shake > 0 ? (rand * @shake * 2.0 - @shake) : 0.0

    bg(ar[:bg], dim: 0.52, tint: ar[:tint], scroll_x: cam_x * 0.25, mirror_x: true)

    camera(cam_x + sx, cam_y + sy)
    draw_tiles(cam_x, cam_y)
    draw_entities
    draw_shots_and_particles
    camera
    clip

    draw_lightmap(cam_x, cam_y, ar[:dark])
    blend(:normal)
    draw_hud
    draw_overlay if @state != :play
  end

  def draw_tiles(cam_x, cam_y)
    ts = @ts
    x0 = (cam_x / ts).to_i.clamp(0, @mw - 1)
    x1 = ((cam_x + @w) / ts + 1).to_i.clamp(0, @mw - 1)
    y0 = (cam_y / ts).to_i.clamp(0, @mh - 1)
    y1 = ((cam_y + @h) / ts + 1).to_i.clamp(0, @mh - 1)

    y = y0
    while y <= y1
      row = @grid[y]
      py = y * ts
      x = x0
      while x <= x1
        v = row[x]
        if v != 0
          px = x * ts
          if v == 1
            rectfill(px, py, 16, 16, 1)
            rectfill(px + 1, py + 1, 14, 14, 5)
            rect(px, py, 16, 16, 0, 1)
          elsif v == 2
            rectfill(px, py, 16, 16, 1)
            rectfill(px + 1, py + 2, 14, 13, 5)
            rectfill(px, py, 16, 3, 3)
          elsif v == 3
            rectfill(px, py, 16, 16, 1)
            rectfill(px + 2, py + 2, 12, 12, 12)
            line(px + 3, py + 3, px + 12, py + 12, 7, 1)
          elsif v == 4
            rectfill(px + 4, py, 8, 16, 14, 0.55)
            line(px + 8, py, px + 8, py + 16, 7, 1, 0.8)
          elsif v == 5
            trifill(px + 1, py + 15, px + 8, py + 3, px + 15, py + 15, 8)
            trifill(px + 4, py + 15, px + 8, py + 6, px + 12, py + 15, 7)
          elsif v == 6
            rectfill(px, py, 16, 4, 4)
            rectfill(px, py, 16, 2, 9)
          end
        end
        x += 1
      end
      y += 1
    end

    tf = (@tick / 8) % 2
    i = 0
    while i < @torches.size
      tc = @torches[i]
      if tc[0] >= cam_x - 24 && tc[0] <= cam_x + @w + 24 && tc[1] >= cam_y - 24 && tc[1] <= cam_y + @h + 24
        spr(spr_id(:torch, tf), tc[0] - 8, tc[1] - 8)
      end
      i += 1
    end
  end

  def draw_entities
    f = (@tick / 12) % 2
    i = 0
    while i < @pickups.size
      pk = @pickups[i]
      bob = (sin(@tick * 0.1 + i) * 2.0).to_i
      if pk[:kind] == :shard
        circfill(pk[:x] + 8, pk[:y] + 8 + bob, 5, 10)
        circfill(pk[:x] + 8, pk[:y] + 7 + bob, 2, 7)
      elsif pk[:kind] == :heart
        print_text("♥", pk[:x] + 8, pk[:y] + 4 + bob, 8, 8, 1.0, :center, 0)
      else
        col = $relics[pk[:kind]][:col]
        circfill(pk[:x] + 8, pk[:y] + 8 + bob, 7, col, 0.4)
        spr(:relic, pk[:x], pk[:y] + bob)
      end
      i += 1
    end

    i = 0
    while i < @foes.size
      foe = @foes[i]
      pal(7, 8) if foe[:flash] > 0
      if foe[:kind] == :boss
        spr(spr_id(:guardian, f), foe[:x], foe[:y], foe[:flip])
        bw = 32
        fw = ((foe[:hp].to_f / foe[:max_hp]) * bw).to_i.clamp(0, bw)
        rectfill(foe[:x], foe[:y] - 6, bw, 3, 0)
        rectfill(foe[:x], foe[:y] - 6, fw, 3, 8)
      else
        spr(spr_id(foe[:spr], f), foe[:x], foe[:y], foe[:flip])
      end
      pal if foe[:flash] > 0
      i += 1
    end

    if @inv == 0 || (@tick % 4 < 2)
      pf = @on_ground ? ((@vx.abs > 0.2) ? (@tick / 8) % 2 : 0) : 1
      spr(spr_id(:explorer, pf), @px, @py, @flip)
    end
  end

  def draw_shots_and_particles
    blend(:add)
    i = 0
    while i < @shots.size
      s = @shots[i]
      r = s[:sonic] ? 5 : 3
      circfill(s[:x], s[:y], r, s[:sonic] ? 12 : 10, 0.85)
      circ(s[:x], s[:y], r + 2, 7, 0.5)
      i += 1
    end

    i = 0
    while i < @particles.size
      pt = @particles[i]
      circfill(pt[:x], pt[:y], pt[:enemy_shot] ? 3 : 2, pt[:col], 0.85)
      i += 1
    end
    blend(:normal)

    i = 0
    while i < @popups.size
      p = @popups[i]
      print_text(p[:txt], p[:x], p[:y], p[:col], 8, 1.0, :center, 0)
      i += 1
    end
  end

  def draw_lightmap(cam_x, cam_y, darkness)
    pxs = @px + 8 - cam_x
    pys = @py + 8 - cam_y
    pulse = sin(@tick * 0.12) * 3.0

    render_to(@lightmap) do
      cls(0, darkness)
      blend(:erase)
      circfill(pxs, pys, 84 + pulse, 0, 1.0)
      i = 0
      while i < @torches.size
        tc = @torches[i]
        tx = tc[0] - cam_x
        ty = tc[1] - cam_y
        if tx > -60 && tx < @w + 60 && ty > -60 && ty < @h + 60
          circfill(tx, ty, 44 + pulse, 0, 1.0)
        end
        i += 1
      end
      j = 0
      while j < @shots.size
        s = @shots[j]
        circfill(s[:x] - cam_x, s[:y] - cam_y, 24, 0, 1.0)
        j += 1
      end
      blend(:normal)
    end

    draw_surface(@lightmap, 0, 0)
  end

  def draw_hud
    rectfill(0, 0, @w, 16, 0, 0.78)
    h_str = ""
    i = 0
    while i < @max_hp
      h_str += (i < @hp ? "♥" : "·")
      i += 1
    end
    print_text(h_str, 6, 4, 8, 8, 1.0, :left, 0)

    rel_str = ""
    rel_str += @has_djump ? "JUMP " : "---- "
    rel_str += @has_sonic ? "SONIC " : "----- "
    rel_str += @has_phase ? "PHASE" : "-----"
    print_text(rel_str, 76, 4, 11, 8, 1.0, :left, 0)
    print_text("SHARD:#{@shards}/8", 248, 4, 10, 8, 1.0, :right, 0)

    # Live minimap scaled 3.0x with draw_surface(scale:)
    rect(254, 18, 62, 38, 12, 1)
    draw_surface(@minimap, 255, 19, scale: 3.0)

    if @banner_t > 0
      rectfill(16, 206, 288, 22, 0, 0.85)
      rect(16, 206, 288, 22, 10, 1)
      print_text(@banner_txt, 160, 213, 10, 8, 1.0, :center, 0)
    end
  end

  def draw_overlay
    rectfill(44, 62, 232, 108, 0, 0.92)
    b_col = (@state == :win) ? 10 : 8
    rect(44, 62, 232, 108, b_col, 2)
    title = (@state == :win) ? "SANCTUM CLEARED!" : "LOST IN THE ABYSS"
    print_text(title, 160, 76, b_col, 16, 1.0, :center, 0)
    sec = (@tick / 60).to_i
    print_text("TIME: #{sec}s   SHARDS: #{@shards}/8", 160, 108, 7, 8, 1.0, :center, 0)
    print_text("PRESS Z OR X TO RETURN", 160, 140, 11, 8, 1.0, :center, 0)
  end
end

run TitleScene.new
__END__
@PALETTE 1
1: #161828
3: #1E7A50
4: #945232
5: #4E5870
6: #B0C0D8
7: #F8F8FF
8: #FF2E5C
9: #FF9C28
A: #FFE642
B: #38E078
C: #30B8FF
D: #865ED6
E: #FF6EB8
F: #FFD4B0

@SPRITE :explorer 16x16 pal:1
....11111111....
...1CCCCCCCC1...
..1CC77CCCCCC1..
..1FFFFFFFFFF1..
..1F1FF7FF1FF1..
..1FFFFEFFFFF1..
...1199999911...
..1999AAAA9991..
.19913333331991.
.1F1133CC3311F1.
..1..133331..1..
....14411441....
....14411441....
...1155115511...
................
................
---
....11111111....
...1CCCCCCCC1...
..1CC77CCCCCC1..
..1FFFFFFFFFF1..
..1F1FF7FF1FF1..
..1FFFFEFFFFF1..
..1999AAAA9991..
.19913333331991.
.1F1133CC3311F1.
..1..133331..1..
...1144114411...
..1551....1551..
..111......111..
................
................
................

@SPRITE :crawler 16x16 pal:1
................
................
................
.....111111.....
...11BBBBBB11...
..1BB77BBBBBB1..
.1BBBBBBBBBBBB1.
.1BB18BBBB18BB1.
.13333333333331.
1133113333113311
1331..1331..1331
.11....11....11.
................
................
................
................
---
................
................
.....111111.....
...11BBBBBB11...
..1BB77BBBBBB1..
.1BBBBBBBBBBBB1.
.1BB18BBBB18BB1.
.13333333333331.
.13311333311331.
..131.1331.131..
...1...11...1...
................
................
................
................
................

@SPRITE :wisp 16x16 pal:1
.....111111.....
...11CCCCCC11...
..1CC77CCCCCC1..
.1CC7CCCCCCCCD1.
.1CC11CCCC11CD1.
.1CC17CCCC17CD1.
.1CCCCCCCCCCCD1.
..1CCCCCCCCDD1..
...1CCDDDDDD1...
....11DDDD11....
......1DD1......
.......11.......
................
................
................
................
---
......1111......
....11CCCC11....
..11CC77CCCC11..
.1CCC7CCCCCCCD1.
.1CC11CCCC11CD1.
.1CC17CCCC17CD1.
..1CCCCCCCCCD1..
...1CCDDDDDD1...
....11DDDD11....
.....1DDDD1.....
......1111......
................
................
................
................
................

@SPRITE :sentinel 16x16 pal:1
....11111111....
...1DDDDDDDD1...
..1DD77DDDDDD1..
..1D11DDDD11D1..
..1D1E1DD1E1D1..
..1DDDDDDDDDD1..
.1155DDDDDD5511.
1555511EE1155551
15511DDDDDD11551
.11..1DDDD1..11.
....15511551....
....15511551....
...1111..1111...
................
................
................
---
....11111111....
...1DDDDDDDD1...
..1DD77DDDDDD1..
..1D11DDDD11D1..
..1D1E1DD1E1D1..
..1DDDDDDDDDD1..
1555511EE1155551
15511DDDDDD11551
.11..1DDDD1..11.
....15511551....
...1551..1551...
...111....111...
................
................
................
................

@SPRITE :guardian 32x32 pal:1
.........11111111111111.........
.......11DDDDDDDDDDDDDD11.......
......1DD77DDDDDDDDDDDDDD1......
.....1DD7DDDDDDDDDDDDDDDDD1.....
....1DD111DDDDDDDDDDDD111DD1....
....1D18881DDDDDDDDDD18881D1....
....1D18781DDDDDDDDDD18781D1....
.....1D111DDDDDDDDDDDD111D1.....
......1DDDDDD11AA11DDDDDD1......
.....11555551AA77AA15555511.....
...115555551AAAAAAAA155555511...
..155555111DDDDDDDDDD111555551..
.1555111..1DDDDDDDDDD1..1115551.
.1551.....1DD888888DD1.....1551.
1551......1DD887788DD1......1551
1E1.......1DD888888DD1.......1E1
.1........1DDDDDDDDDD1........1.
..........1DDDD11DDDD1..........
.........155551..155551.........
........155551....155551........
........15551......15551........
.......11111........11111.......
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................
---
................................
.........11111111111111.........
.......11DDDDDDDDDDDDDD11.......
......1DD77DDDDDDDDDDDDDD1......
.....1DD7DDDDDDDDDDDDDDDDD1.....
....1DD111DDDDDDDDDDDD111DD1....
....1D18881DDDDDDDDDD18881D1....
....1D18781DDDDDDDDDD18781D1....
.....1D111DDDDDDDDDDDD111D1.....
..1...1DDDDDD11AA11DDDDDD1...1..
.1E1.11555551AA77AA15555511.1E1.
155115555551AAAAAAAA155555511551
15555551111DDDDDDDDDD11115555551
.111111...1DDDDDDDDDD1...111111.
..........1DD888888DD1..........
..........1DD887788DD1..........
..........1DD888888DD1..........
..........1DDDDDDDDDD1..........
..........1DDDD11DDDD1..........
.........155551..155551.........
........155551....155551........
........11111......11111........
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................

@SPRITE :relic 16x16 pal:1
................
......1111......
....11AAAA11....
...1AA77AAAA1...
..1AA7CC7AAAA1..
..1AAC77CAAAA1..
..1AACCCCAAAA1..
...1AAAAAAAA1...
....11AAAA11....
.....199991.....
....19AAAA91....
....11111111....
................
................
................
................

@SPRITE :torch 16x16 pal:1
.......11.......
......1AA1......
.....1A77A1.....
....19A77A91....
....189AA981....
.....189981.....
.....114411.....
......1441......
......1441......
......1441......
......1111......
................
................
................
................
................
---
......11........
.....1AA1.......
....19A7A1......
....18A7791.....
.....189A81.....
.....189981.....
.....114411.....
......1441......
......1441......
......1441......
......1111......
................
................
................
................
................

@MUSIC :entry_bgm
ch0 wave=tri vol=5 T108 L8 O4 e g b > d < b g e g  c e g b g e c e  d f# a > d < a f# d f#  e g b > e < b g e4
ch1 wave=pulse vol=3 T108 L4 O3 e b c g  d a e b
ch2 wave=noise vol=2 T108 L8 O6 c r r c r r c r  c r r c r r c r

@MUSIC :cavern_bgm
ch0 wave=pulse vol=4 T118 L8 O4 c e g b a g e c  d f a > c < b a f d  e g b > d c < b g e  c2 d2
ch1 wave=tri vol=5 T118 L4 O3 c g d a  e b c g

@MUSIC :abyss_bgm
ch0 wave=square vol=4 T126 L8 O4 d f a > c < a f d f  c e g b g e c e  < b > d f# a f# d < b > d  d f a > d < a f d4
ch1 wave=tri vol=5 T126 L8 O2 d r d r c r c r  < b r b r > d r d r

@MUSIC :boss_bgm
ch0 wave=saw vol=4 T148 L8 O4 e e > e < b > c < b g e  f f > f c d c < a f  g g > g d e d < b g  a4 g4 f#4 e4
ch1 wave=tri vol=6 T148 L8 O2 e e g e f f a f  g g b g a g f# e
ch2 wave=noise vol=3 T148 L8 O6 c c r c c r c c  c c r c c r c c  c c r c c r c c  c c c c c c c c
