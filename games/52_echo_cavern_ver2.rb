config(
  title: "ECHO CAVERN VER.2",
  width: 320,
  height: 240,
  save_id: "echo_cavern_ver2",
  save_salt: "v2g52ec9"
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

    # Floating crystal sparkles & additive aura
    blend(:add)
    circfill(34, 48, 22 + (sin(@tick * 0.08) * 3).to_i, 12, 0.22)
    circfill(286, 46, 26 + (sin(@tick * 0.07 + 1.2) * 4).to_i, 8, 0.24)
    i = 0
    while i < 14
      sx = ((i * 53 + @tick * (i % 3 == 0 ? 0.45 : 0.22)) % 320).to_i
      sy = (36 + sin(@tick * 0.045 + i) * 18 + (i * 19) % 144).to_i
      col = (i % 3 == 0) ? 10 : ((i % 2 == 0) ? 12 : 14)
      circfill(sx, sy, 2 + (i % 2), col, 0.35)
      pset(sx, sy, 7, 0.85)
      i += 1
    end
    blend(:normal)

    f = (@tick / 10) % 4
    ef = (@tick / 14) % 2
    sf = (@tick / 12) % 2
    gbob = (sin(@tick * 0.07) * 2.5).to_i
    spr(spr_id(:explorer, f), 22, 36, false, nil, 0.0, 1.5)
    spr(spr_id(:guardian, ef), 270, 30 + gbob, true, nil, 0.0, 1.0)
    spr(spr_id(:shard, sf), 12, 155 - gbob)
    spr(spr_id(:relic, sf), 292, 155 + gbob)

    print_text("ECHO CAVERN", 160, 18, 12, 16, 1.0, :center, 0, 2)
    print_text("VER.2 - MINI METROIDVANIA EXPEDITION", 160, 40, 10, 8, 1.0, :center, 0)

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
    @decals = create_surface(@ww, @wh, :gpu)
    clear_surface(@decals, nil, 0.0)
    # 20x12 pixel minimap scaled 3.0x => 60x36 px HUD
    @minimap = create_surface(20, 12, :pixel)

    @grid = []
    @visited = []
    @torches = []
    @pickups = []
    @foes = []
    @shots = []
    @particles = []
    @rings = []
    @ghosts = []
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
    @muzzle_t = 0
    @sx_scale = 1.0
    @sy_scale = 1.0
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
    @active_bgm = nil
    @combo = 0
    @combo_t = 0
    @boss_active = false
    @boss_defeated = false

    @tick = 0
    @shake = 0.0
    @hitstop = 0
    @screen_flash = 0.0
    @flash_col = 7
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
      recoil: 0.0,
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

  def desired_bgm
    return :pinch_bgm if @hp > 0 && @hp <= 2 && (@cur_area != 3 || @hp == 1)
    $areas[@cur_area >= 0 ? @cur_area : 0][:bgm]
  end

  def sync_bgm
    return if @state != :play
    target = desired_bgm
    return if @active_bgm == target
    @active_bgm = target
    music(target, true, target == :pinch_bgm ? 0.72 : 0.65)
  end

  def switch_area(idx)
    return if @cur_area == idx
    @cur_area = idx
    ar = $areas[idx]
    sync_bgm
    @banner_txt = ar[:name]
    @banner_t = 120
  end

  def stamp_decal(x, y, r, col, alpha = 0.45)
    render_to(@decals) do
      circfill(x, y, r, col, alpha)
      circfill(x, y, (r * 0.5).to_i.clamp(1, 16), 7, alpha * 0.65)
    end
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
      @shake *= 0.92
      @screen_flash *= 0.85
      return
    end

    @tick += 1
    @shake *= 0.82
    @shake = 0.0 if @shake < 0.2
    @screen_flash *= 0.78
    @screen_flash = 0.0 if @screen_flash < 0.02
    @sx_scale += (1.0 - @sx_scale) * 0.24
    @sy_scale += (1.0 - @sy_scale) * 0.24
    @muzzle_t -= 1 if @muzzle_t > 0
    @banner_t -= 1 if @banner_t > 0
    @dash_cd -= 1 if @dash_cd > 0
    @shot_cd -= 1 if @shot_cd > 0
    @inv -= 1 if @inv > 0
    if @combo_t > 0
      @combo_t -= 1
      @combo = 0 if @combo_t == 0
    end

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
        @ghosts << { x: @px, y: @py, flip: @flip, t: 10, max_t: 10 }
        @particles << { x: @px + 8, y: @py + 5 + rand(7), vx: -@dash_dir * (0.6 + rand * 0.8), vy: (rand - 0.5) * 0.6, col: (@tick % 4 == 0 ? 12 : 14), t: 12, max_t: 12 }
      end
    else
      move = 0
      move -= 1 if btn(:left)
      move += 1 if btn(:right)
      @vx = move * $cfg[:move_spd]
      @flip = true if move < 0
      @flip = false if move > 0

      if @on_ground && move != 0 && (@tick % 10) == 0
        @particles << { x: @px + 8 - move * 4, y: @py + 15, vx: -move * (0.4 + rand * 0.4), vy: -0.25 - rand * 0.3, col: 6, t: 10, max_t: 10 }
      end

      if btnp(1)
        if @on_ground
          @vy = $cfg[:jump_vy]
          @on_ground = false
          @sx_scale = 0.80
          @sy_scale = 1.24
          sfx(:jump, -1, 0.82, 0.96 + rand * 0.08)
          spawn_dust(@px + 8, @py + 15, 5)
        elsif @has_djump && @jumps_left > 0
          @vy = $cfg[:djump_vy]
          @jumps_left -= 1
          @sx_scale = 0.76
          @sy_scale = 1.28
          sfx(:djump, -1, 0.88, 1.0)
          spawn_ring(@px + 8, @py + 14, 18.0, 11, 14)
          spawn_sparks(@px + 8, @py + 15, 11, 10)
        end
      end

      @vy = (@vy + $cfg[:grav]).clamp(-8.0, $cfg[:max_fall])
    end

    # Sonic Blaster (X)
    if btnp(2) && @shot_cd <= 0 && @dash_t <= 0 && !(btn(:up) && @has_phase)
      @shot_cd = $cfg[:shot_cd]
      @muzzle_t = 4
      @sx_scale = 1.15
      @sy_scale = 0.88
      dir = @flip ? -1 : 1
      sx_pos = @px + 8 + dir * 7
      sy_pos = @py + 8
      @shots << {
        x: sx_pos,
        y: sy_pos,
        vx: dir * $cfg[:shot_spd],
        sonic: @has_sonic,
        t: 36
      }
      if @has_sonic
        spawn_ring(sx_pos, sy_pos, 13.0, 12, 10)
        sfx(:sonic_shot, -1, 0.82, 0.97 + rand * 0.08)
      else
        sfx(:shoot, -1, 0.78, 0.95 + rand * 0.10)
      end
    end

    move_player_with_collision(@dash_t > 0)
  end

  def start_dash(dir)
    @dash_dir = dir
    @flip = (dir < 0)
    @dash_t = $cfg[:dash_frames]
    @dash_cd = $cfg[:dash_cd]
    @sx_scale = 1.30
    @sy_scale = 0.74
    @inv = $cfg[:dash_frames] + 2 if @inv < $cfg[:dash_frames]
    spawn_ring(@px + 8, @py + 8, 20.0, 14, 12)
    sfx(:dash, -1, 0.88, 1.0 + rand * 0.08)
  end

  def move_player_with_collision(phase_pass)
    ts = @ts
    was_on_ground = @on_ground
    fall_vy = @vy
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
        if !was_on_ground && fall_vy > 1.6
          @sx_scale = 1.24
          @sy_scale = 0.78
          spawn_dust(@px + 8, @py + 15, 5)
          sfx(:land, -1, 0.55, 0.92 + rand * 0.16) if fall_vy > 2.4
        end
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
      if (s[:t] % 2) == 0
        @particles << {
          x: s[:x] - s[:vx] * 0.4,
          y: s[:y] + (rand - 0.5) * 2.0,
          vx: -s[:vx] * 0.12,
          vy: (rand - 0.5) * 0.35,
          col: s[:sonic] ? 12 : 10,
          t: 8,
          max_t: 8
        }
      end
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
              spawn_debris(tx * ts + 8, cy * ts + 8, 12, 7)
              stamp_decal(tx * ts + 8, cy * ts + 8, 6, 12, 0.38)
            end
            cy += 1
          end
          sfx(:shatter, -1, 0.95, 1.0)
          @hitstop = 4
          @shake = 6.5
          @screen_flash = 0.28
          @flash_col = 12
          spawn_ring(s[:x], s[:y], 34.0, 12, 18)
          @popups << { x: s[:x], y: s[:y] - 8, txt: "SHATTER!", col: 12, t: 38 }
          rm_shot = true
        elsif tile == 1 || tile == 2 || tile == 3 || tile == 4
          col = (tile == 3) ? 12 : ((tile == 4) ? 14 : (s[:sonic] ? 12 : 10))
          spawn_sparks(s[:x], s[:y], col, 5)
          spawn_ring(s[:x], s[:y], 9.0, col, 8)
          stamp_decal(s[:x], s[:y], s[:sonic] ? 3 : 2, col, 0.35)
          sfx(:hit, -1, 0.38, tile == 3 ? 1.55 : 1.25)
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
            f[:recoil] = (s[:vx] > 0 ? 2.6 : -2.6)
            @combo += 1
            @combo_t = 150
            cpitch = (0.96 + @combo * 0.06).clamp(0.96, 1.65)
            sfx(:hit, -1, 0.84, cpitch)
            @hitstop = s[:sonic] ? 2 : 1
            @shake = 2.4 if @shake < 2.4
            spawn_ring(s[:x], s[:y], s[:sonic] ? 18.0 : 12.0, s[:sonic] ? 12 : 10, 10)
            spawn_sparks(s[:x], s[:y], f[:col], s[:sonic] ? 9 : 6)
            if @combo >= 3 && f[:hp] > 0
              @popups << { x: f[:x] + fw * 0.5, y: f[:y] - 6, txt: "#{@combo} HIT!", col: 10, t: 26 }
            end
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
    cx = f[:x] + (f[:kind] == :boss ? 16 : 8)
    cy = f[:y] + (f[:kind] == :boss ? 16 : 8)
    spawn_sparks(cx, cy, f[:col], f[:kind] == :boss ? 28 : 16)
    spawn_debris(cx, cy, 7, f[:kind] == :boss ? 14 : 6)
    spawn_ring(cx, cy, f[:kind] == :boss ? 64.0 : 26.0, f[:col], f[:kind] == :boss ? 28 : 15)
    stamp_decal(cx, cy + 4, f[:kind] == :boss ? 12 : 5, f[:col], 0.42)
    if f[:kind] == :boss
      @boss_defeated = true
      @shake = 10.0
      @hitstop = 8
      @screen_flash = 0.55
      @flash_col = 7
      sfx(:clear)
      stop_music
      @state = :win
      @state_t = 0
    else
      @hitstop = 2 if @hitstop < 2
      @shake = 4.2 if @shake < 4.2
      kpitch = ((f[:kind] == :sentinel ? 0.86 : 1.04) + @combo * 0.04).clamp(0.85, 1.55)
      sfx(:foe_die, -1, 0.85, kpitch)
    end
  end

  def update_foes
    rm = current_room
    i = 0
    while i < @foes.size
      f = @foes[i]
      f[:flash] -= 1 if f[:flash] > 0
      f[:recoil] *= 0.72
      f[:recoil] = 0.0 if f[:recoil].abs < 0.1
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
    rage = (f[:hp] <= f[:max_hp] / 2) ? 1.22 : 1.0
    if dist > 4.0
      f[:x] += (dx / dist) * f[:spd] * rage
      f[:y] += (dy / dist) * (f[:spd] * 0.7) * rage
      f[:flip] = dx < 0
    end
    f[:cd] -= 1
    if f[:cd] <= 0
      f[:cd] = (f[:hp] <= f[:max_hp] / 2) ? 58 : 72
      # Fire 3-way echo orbs
      ang_base = atan2(dy, dx)
      k = -1
      while k <= 1
        a = ang_base + k * 0.35
        @particles << { x: f[:x] + 16, y: f[:y] + 16, vx: cos(a) * 2.15, vy: sin(a) * 2.15, col: 8, t: 90, max_t: 90, enemy_shot: true }
        k += 1
      end
      spawn_ring(f[:x] + 16, f[:y] + 16, 22.0, 8, 14)
      sfx(:boss_shot, -1, 0.80, 0.95 + rand * 0.10)
    end
  end

  def hurt_player(dmg)
    return if @inv > 0
    @hp -= dmg
    @combo = 0
    @combo_t = 0
    @inv = 45
    @shake = 6.5
    @hitstop = 4
    @screen_flash = 0.35
    @flash_col = 8
    @sx_scale = 0.82
    @sy_scale = 1.22
    sfx(:player_hurt, -1, 0.92, 1.0)
    spawn_ring(@px + 8, @py + 8, 24.0, 8, 14)
    spawn_sparks(@px + 8, @py + 8, 8, 12)
    if @hp <= 0
      @hp = 0
      sfx(:gameover)
      stop_music
      @active_bgm = nil
      @state = :gameover
      @state_t = 0
    else
      sync_bgm
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
          pitch = (0.95 + @shards * 0.07).clamp(0.95, 1.65)
          sfx(:shard, -1, 0.88, pitch)
          spawn_ring(pk[:x] + 8, pk[:y] + 8, 20.0, 10, 14)
          spawn_sparks(pk[:x] + 8, pk[:y] + 8, 12, 10)
          @popups << { x: pk[:x] + 8, y: pk[:y], txt: "SHARD #{@shards}/8", col: 10, t: 45 }
        elsif k == :heart
          @max_hp += 1
          @hp = @max_hp
          sync_bgm
          sfx(:heal, -1, 0.92, 1.0)
          spawn_ring(pk[:x] + 8, pk[:y] + 8, 24.0, 8, 16)
          spawn_sparks(pk[:x] + 8, pk[:y] + 8, 8, 12)
          @popups << { x: pk[:x] + 8, y: pk[:y], txt: "MAX HP +1!", col: 8, t: 45 }
        end
        @pickups.delete_at(i)
      end
      i -= 1
    end
  end

  def show_relic(key)
    rel = $relics[key]
    sfx(:relic, -1, 0.95, 1.0)
    @hitstop = 4
    @shake = 3.5
    @screen_flash = 0.30
    @flash_col = rel[:col]
    @banner_txt = "#{rel[:name]}: #{rel[:desc]}"
    @banner_t = 180
    spawn_ring(@px + 8, @py + 8, 36.0, rel[:col], 22)
    spawn_ring(@px + 8, @py + 8, 22.0, 7, 15)
    spawn_sparks(@px + 8, @py + 8, rel[:col], 20)
  end

  def spawn_ring(x, y, max_r, col, max_t)
    @rings << { x: x.to_f, y: y.to_f, max_r: max_r.to_f, col: col, t: max_t, max_t: max_t }
  end

  def spawn_dust(x, y, n)
    i = 0
    while i < n
      vx = (rand - 0.5) * 2.2
      vy = -0.2 - rand * 0.7
      mt = 12 + rand(8)
      @particles << { x: x.to_f, y: y.to_f, vx: vx, vy: vy, col: 6, t: mt, max_t: mt }
      i += 1
    end
  end

  def spawn_debris(x, y, col, n)
    i = 0
    while i < n
      a = rand * Math::PI * 2.0
      sp = 1.0 + rand * 2.6
      mt = 22 + rand(14)
      @particles << { x: x.to_f, y: y.to_f, vx: cos(a) * sp, vy: sin(a) * sp - 1.2, grav: 0.13, col: (i % 2 == 0 ? col : 7), t: mt, max_t: mt }
      i += 1
    end
  end

  def spawn_sparks(x, y, col, n)
    i = 0
    while i < n
      a = rand * Math::PI * 2.0
      sp = 0.6 + rand * 2.4
      mt = 16 + rand(12)
      @particles << { x: x.to_f, y: y.to_f, vx: cos(a) * sp, vy: sin(a) * sp, col: col, t: mt, max_t: mt }
      i += 1
    end
  end

  def update_fx
    i = @particles.size - 1
    while i >= 0
      pt = @particles[i]
      pt[:x] += pt[:vx]
      pt[:y] += pt[:vy]
      if pt[:grav]
        pt[:vy] += pt[:grav]
      elsif !pt[:enemy_shot]
        pt[:vx] *= 0.94
        pt[:vy] *= 0.94
      end
      pt[:t] -= 1
      if pt[:enemy_shot] && (@px + 8 - pt[:x]).abs < 7 && (@py + 8 - pt[:y]).abs < 7
        hurt_player(1)
        pt[:t] = 0
      end
      @particles.delete_at(i) if pt[:t] <= 0
      i -= 1
    end

    i = @rings.size - 1
    while i >= 0
      @rings[i][:t] -= 1
      @rings.delete_at(i) if @rings[i][:t] <= 0
      i -= 1
    end

    i = @ghosts.size - 1
    while i >= 0
      @ghosts[i][:t] -= 1
      @ghosts.delete_at(i) if @ghosts[i][:t] <= 0
      i -= 1
    end

    i = @popups.size - 1
    while i >= 0
      @popups[i][:y] -= 0.45
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

    # Ambient floating cavern dust motes
    blend(:add)
    m = 0
    while m < 10
      mx = ((m * 67 + @tick * 0.22 - cam_x * 0.45) % @w).to_i
      mx += @w if mx < 0
      my = ((m * 43 + sin(@tick * 0.035 + m) * 14.0 - cam_y * 0.35) % @h).to_i
      my += @h if my < 0
      pset(mx, my, (m % 2 == 0) ? 12 : 11, 0.45)
      m += 1
    end
    blend(:normal)

    camera(cam_x + sx, cam_y + sy)
    draw_tiles(cam_x, cam_y)
    blend(:add)
    draw_surface(@decals, 0, 0, 0.65)
    blend(:normal)
    draw_entities(cam_x, cam_y)
    draw_shots_and_particles
    camera
    clip

    draw_lightmap(cam_x + sx, cam_y + sy, ar[:dark])
    draw_world_glow(cam_x + sx, cam_y + sy)

    # Low-HP pinch danger pulse border
    if @state == :play && @hp > 0 && @hp <= 2
      dp = (sin(@tick * 0.16) * 0.12 + 0.20).clamp(0.06, 0.35)
      blend(:add)
      rect(0, 0, @w, @h, 8, 3, dp)
      rect(3, 3, @w - 6, @h - 6, 8, 2, dp * 0.55)
      blend(:normal)
    end

    if @screen_flash > 0.01
      blend(:add)
      rectfill(0, 0, @w, @h, @flash_col, @screen_flash.clamp(0.0, 0.65))
      blend(:normal)
    end

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

    stone_id = spr_id(:tile_stone, 0)
    moss_id = spr_id(:tile_moss, 0)
    crys_id = spr_id(:tile_crystal, 0)
    phase_id = spr_id(:tile_phase, (@tick / 6) % 2)
    spike_id = spr_id(:tile_spike, 0)
    plat_id = spr_id(:tile_plat, 0)

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
            spr(stone_id, px, py)
          elsif v == 2
            spr(moss_id, px, py)
          elsif v == 3
            spr(crys_id, px, py)
          elsif v == 4
            spr(phase_id, px, py, false, nil, 0.0, 1.0, 0.88)
          elsif v == 5
            spr(spike_id, px, py)
          elsif v == 6
            spr(plat_id, px, py)
          end
        end
        x += 1
      end
      y += 1
    end

    tf = (@tick / 7) % 2
    i = 0
    while i < @torches.size
      tc = @torches[i]
      if tc[0] >= cam_x - 24 && tc[0] <= cam_x + @w + 24 && tc[1] >= cam_y - 24 && tc[1] <= cam_y + @h + 24
        spr(spr_id(:torch, ((@tick / 7) + i) % 2), tc[0] - 8, tc[1] - 8)
      end
      i += 1
    end
  end

  def draw_entities(cam_x, cam_y)
    f = (@tick / 10) % 2
    i = 0
    while i < @pickups.size
      pk = @pickups[i]
      if pk[:x] >= cam_x - 24 && pk[:x] <= cam_x + @w + 24 && pk[:y] >= cam_y - 24 && pk[:y] <= cam_y + @h + 24
        bob = (sin(@tick * 0.1 + i) * 2.2).to_i
        pf_item = ((@tick / 12) + i) % 2
        if pk[:kind] == :shard
          spr(spr_id(:shard, pf_item), pk[:x], pk[:y] + bob)
        elsif pk[:kind] == :heart
          spr(spr_id(:heart_vessel, pf_item), pk[:x], pk[:y] + bob)
        else
          spr(spr_id(:relic, pf_item), pk[:x], pk[:y] + bob)
        end
      end
      i += 1
    end

    # Phase Dash luminous afterimages
    if @ghosts.size > 0
      blend(:add)
      gi = 0
      while gi < @ghosts.size
        g = @ghosts[gi]
        ga = (g[:t].to_f / g[:max_t]) * 0.55
        spr(spr_id(:explorer, 3), g[:x], g[:y], g[:flip], nil, 0.0, 1.0, ga)
        gi += 1
      end
      blend(:normal)
    end

    i = 0
    while i < @foes.size
      foe = @foes[i]
      fx = foe[:x] + foe[:recoil]
      if fx >= cam_x - 40 && fx <= cam_x + @w + 40 && foe[:y] >= cam_y - 40 && foe[:y] <= cam_y + @h + 40
        if foe[:flash] > 0
          pal([7, 7, 8, 7, 8, 7, 7, 7, 7, 10, 7, 7, 7, 7, 7, 7])
        end
        if foe[:kind] == :boss
          bf = (@tick / 12) % 2
          spr(spr_id(:guardian, bf), fx, foe[:y], foe[:flip])
          pal if foe[:flash] > 0
          bw = 32
          fw = ((foe[:hp].to_f / foe[:max_hp]) * bw).to_i.clamp(0, bw)
          rectfill(fx - 1, foe[:y] - 7, bw + 2, 5, 0, 0.85)
          rectfill(fx, foe[:y] - 6, fw, 3, (foe[:hp] <= foe[:max_hp] / 2) ? 9 : 8)
          rectfill(fx, foe[:y] - 6, fw, 1, 10) if fw > 0
        else
          ef = ((@tick / 9) + i) % 2
          spr(spr_id(foe[:spr], ef), fx, foe[:y], foe[:flip])
          pal if foe[:flash] > 0
        end
      end
      i += 1
    end

    if @inv == 0 || (@tick % 4 < 2)
      if @dash_t > 0 || !@on_ground
        pf = 3
      elsif @vx.abs > 0.2
        pf = 1 + ((@tick / 6) % 2)
      else
        pf = ((@tick / 24) % 2 == 0) ? 0 : 2
      end
      py_adj = @py + (1.0 - @sy_scale) * 8.0
      spr_ext(spr_id(:explorer, pf), @px, py_adj, 0.0, @sx_scale, @sy_scale, @flip, false, nil, 1.0)
    end
  end

  def draw_shots_and_particles
    blend(:add)
    if @muzzle_t > 0
      dir = @flip ? -1 : 1
      mx = @px + 8 + dir * 9
      my = @py + 8
      circfill(mx, my, 4 + @muzzle_t, @has_sonic ? 12 : 10, 0.55)
      circfill(mx, my, 2, 7, 0.95)
    end

    i = 0
    while i < @rings.size
      rg = @rings[i]
      prog = 1.0 - (rg[:t].to_f / rg[:max_t])
      rad = (2.0 + rg[:max_r] * prog).to_i
      al = ((1.0 - prog) * 0.85).clamp(0.05, 0.9)
      circ(rg[:x], rg[:y], rad, rg[:col], al)
      circ(rg[:x], rg[:y], (rad - 1).clamp(1, 999), 7, al * 0.55) if rad > 3
      i += 1
    end

    i = 0
    while i < @shots.size
      s = @shots[i]
      r = s[:sonic] ? 5 : 3
      col = s[:sonic] ? 12 : 10
      circfill(s[:x] - s[:vx] * 0.5, s[:y], r - 1, col, 0.45)
      circfill(s[:x], s[:y], r, col, 0.85)
      circfill(s[:x], s[:y], (r - 2).clamp(1, 4), 7, 0.95)
      circ(s[:x], s[:y], r + 2, 7, 0.45) if s[:sonic]
      i += 1
    end

    i = 0
    while i < @particles.size
      pt = @particles[i]
      if pt[:enemy_shot]
        circfill(pt[:x], pt[:y], 5, 8, 0.42)
        circfill(pt[:x], pt[:y], 3, 14, 0.85)
        pset(pt[:x], pt[:y], 7, 1.0)
      else
        mt = pt[:max_t] || 20
        al = (pt[:t].to_f / mt).clamp(0.15, 0.95)
        rad = (pt[:t] > mt * 0.5) ? 2 : 1
        circfill(pt[:x], pt[:y], rad, pt[:col], al)
      end
      i += 1
    end
    blend(:normal)

    i = 0
    while i < @popups.size
      p = @popups[i]
      al = (p[:t] / 12.0).clamp(0.0, 1.0)
      print_text(p[:txt], p[:x], p[:y], p[:col], 8, al, :center, 0)
      i += 1
    end
  end

  def draw_lightmap(cam_x, cam_y, darkness)
    pxs = @px + 8 - cam_x
    pys = @py + 8 - cam_y
    pulse = sin(@tick * 0.12) * 3.0
    amb_lift = (1.0 - darkness).clamp(0.18, 0.75)

    render_to(@lightmap) do
      # Opaque dark base + lifted ambient tint so multiply preserves 100% opaque screen alpha
      cls(0, 1.0)
      rectfill(0, 0, @w, @h, 1, 0.85)
      rectfill(0, 0, @w, @h, 7, amb_lift)

      blend(:add)
      # Soft 4-step feathered light around Explorer
      circfill(pxs, pys, 102 + pulse, 12, 0.22)
      circfill(pxs, pys, 80 + pulse * 0.8, 7, 0.32)
      circfill(pxs, pys, 58 + pulse * 0.5, 7, 0.45)
      circfill(pxs, pys, 36, 7, 0.65)

      i = 0
      while i < @torches.size
        tc = @torches[i]
        tx = tc[0] - cam_x
        ty = tc[1] - cam_y
        if tx > -64 && tx < @w + 64 && ty > -64 && ty < @h + 64
          tp = sin(@tick * 0.18 + i * 1.7) * 2.5
          circfill(tx, ty - 2, 58 + tp, 9, 0.30)
          circfill(tx, ty - 2, 38 + tp * 0.6, 10, 0.42)
          circfill(tx, ty - 2, 20, 7, 0.65)
        end
        i += 1
      end

      k = 0
      while k < @pickups.size
        pk = @pickups[k]
        kx = pk[:x] + 8 - cam_x
        ky = pk[:y] + 8 - cam_y
        if kx > -40 && kx < @w + 40 && ky > -40 && ky < @h + 40
          col = (pk[:kind] == :shard) ? 12 : ((pk[:kind] == :heart) ? 8 : $relics[pk[:kind]][:col])
          circfill(kx, ky, 36, col, 0.38)
          circfill(kx, ky, 18, 7, 0.65)
        end
        k += 1
      end

      j = 0
      while j < @shots.size
        s = @shots[j]
        r = s[:sonic] ? 36 : 26
        col = s[:sonic] ? 12 : 10
        circfill(s[:x] - cam_x, s[:y] - cam_y, r, col, 0.45)
        circfill(s[:x] - cam_x, s[:y] - cam_y, r * 0.5, 7, 0.70)
        j += 1
      end
      blend(:normal)
    end

    draw_surface(@lightmap, 0, 0, 1.0, :mul)
  end

  def draw_world_glow(cam_x, cam_y)
    blend(:add)
    # Explorer headlamp warm-cyan aura
    dir = @flip ? -1 : 1
    hx = @px + 8 + dir * 5 - cam_x
    hy = @py + 4 - cam_y
    circfill(hx, hy, 16, 12, 0.12)

    # Warm flickering torch bloom
    i = 0
    while i < @torches.size
      tc = @torches[i]
      tx = tc[0] - cam_x
      ty = tc[1] - 4 - cam_y
      if tx > -40 && tx < @w + 40 && ty > -40 && ty < @h + 40
        tp = (sin(@tick * 0.22 + i * 1.9) * 2.5).to_i
        circfill(tx, ty, 22 + tp, 9, 0.15)
        circfill(tx, ty, 10 + (tp / 2), 10, 0.20)
      end
      i += 1
    end

    # Pickup & Wisp / Boss bioluminescence
    i = 0
    while i < @pickups.size
      pk = @pickups[i]
      kx = pk[:x] + 8 - cam_x
      ky = pk[:y] + 8 - cam_y
      if kx > -30 && kx < @w + 30 && ky > -30 && ky < @h + 30
        col = (pk[:kind] == :shard) ? 12 : ((pk[:kind] == :heart) ? 8 : $relics[pk[:kind]][:col])
        circfill(kx, ky, 14 + (sin(@tick * 0.1 + i) * 2).to_i, col, 0.22)
      end
      i += 1
    end

    i = 0
    while i < @foes.size
      foe = @foes[i]
      if foe[:kind] == :wisp || foe[:kind] == :boss
        rad = (foe[:kind] == :boss) ? 26 : 13
        off = (foe[:kind] == :boss) ? 16 : 8
        fx = foe[:x] + off - cam_x
        fy = foe[:y] + off - cam_y
        if fx > -40 && fx < @w + 40 && fy > -40 && fy < @h + 40
          circfill(fx, fy, rad, foe[:col], 0.18)
        end
      end
      i += 1
    end
    blend(:normal)
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
0: #0A0C18
1: #18223C
2: #145082
3: #147858
4: #682A1E
5: #3C4660
6: #82EEFF
7: #F8FDFF
8: #C83C28
9: #F88C24
A: #FFF054
B: #3CE88C
C: #289CF0
D: #7888AA
E: #D4846E
F: #FFD8B8

@PALETTE 2
0: #090D14
1: #14242E
2: #8C1638
3: #0E5844
4: #3C2438
5: #6A4462
6: #AC849E
7: #F4FFF8
8: #FF2A58
9: #FF9A38
A: #80F888
B: #20B06E

@PALETTE 3
0: #0A081C
1: #1C1644
2: #462282
6: #9CF6FF
7: #FFFFFF
8: #FF3074
A: #FFF270
C: #30BCFF
D: #7C4CE8
E: #FF8AD0

@PALETTE 4
0: #0B0A16
1: #1C1A32
2: #561E68
4: #9236AC
5: #363C58
6: #ACC0E4
7: #F6FAFF
8: #FF2458
9: #FF9028
A: #FFF058
D: #626E96
E: #EC78FC

@PALETTE 5
0: #090714
1: #1A1430
2: #7C1234
3: #14688C
4: #7C3C16
5: #322A52
6: #9A92C8
7: #FAF8FF
8: #EC2052
9: #DC8020
A: #FFEE52
C: #38D8FF
D: #5A4E88
E: #FF78AC

@PALETTE 6
0: #080A14
1: #161C30
2: #185898
3: #125842
4: #5C3224
5: #2C3854
6: #7E94B8
7: #EAF6FF
8: #E82858
9: #B46838
A: #84F27C
B: #2AB868
C: #2EB8FF
D: #4C5E82
E: #C858F8

@SPRITE :explorer 16x16 pal:1
....00000000....
...02CCCCCCAA0..
..02C66CCCCA7A0.
..022CCCCCCAA0..
..01EEFFFFFE10..
..01EF0FF7F0F0..
...0EEFFFFFE0...
.004889999880...
048803BBBB309A0.
048033BC6B35DD70
.00.013333A5500.
....048804880...
....05DD05DD0...
...00555055500..
...00000.00000..
................
---
.....00000000...
....02CCCCCCAA0.
...02C66CCCCA7A0
...022CCCCCCAA0.
...01EEFFFFFE10.
...01EF0FF7F0F0.
000.0EEFFFFFE0..
08998889999880..
.044803BBBB39A0.
..00.03BC6B5DD70
.....01333A5500.
...00488004880..
..05DD50..05DD0.
.005500....05550
.0000.......0000
................
---
....00000000....
...02CCCCCCAA0..
..02C66CCCCA7A0.
..022CCCCCCAA0..
..01EEFFFFFE10..
..01EF0FF7F0F0..
...0EEFFFFFE0...
.0048999999880..
048803BBBB35DD70
0890.03BC6B35500
.00..01333A10...
.....0488840....
....05DD05DD0...
....0550.05550..
....000...0000..
................
---
.00..00000000...
089002CCCCCCAA0.
04882C66CCCCA7A0
.04822CCCCCCAA0.
..001EEFFFFFE10.
...01EF0FF7F0F0.
....0EEFFFFFE0..
...04889999880..
..09A03BBBB35DD0
..0F003BC6B357D0
...0.01333A1000.
....048804880...
...05DD0.05DD0..
...0050...0500..
................
................

@SPRITE :crawler 16x16 pal:2
................
.......00.......
......0890......
....00287200....
..003BBBBBB300..
.03BAA77AAABB30.
.03BAAAAAAAA330.
033BBBBBBBBBB310
013B089BB089B310
0603333333333060
0045544554455400
.0560.0560.0560.
0540..040...0540
00....00.....00.
................
................
---
................
................
......0000......
.....089780.....
...0032882300...
.003BBAA77ABB30.
03BBAAAAAAAAAB30
033BBBBBBBBBB310
013B097BB097B310
.06603333330660.
.04554455445540.
..0560.0560.0560
...040..0540.040
...00....00..00.
................
................

@SPRITE :wisp 16x16 pal:3
.....00..00.....
....0C600DC0....
..00DC766CCD00..
.02DCC777CCCD20.
.02DC67776CCDD0.
02DC00ECC00ECD20
02DC087CC087CD20
02DCCCCCCCCCDD20
.02DCCCDDDDDD20.
.002DDDDDDDD20A.
...022DDDD220...
....002DD220....
..A...022D20....
.......0020.....
........00......
................
---
......000.......
...000C760.A....
..0DC6776CD00...
.02DCC777CCCD20.
02DC08ECC08ECD20
02DC0E7CC0E7CD20
02DC088CC088CD20
.02DCCCCCCCCD20.
.022DDDDDDDD220.
..002DDDDDD200..
.A..02DDDD20....
...022DD200.....
...02D200....A..
...0200.........
....00..........
................

@SPRITE :sentinel 16x16 pal:4
......0000...00.
.....04EE40.08A0
...005666D500890
..05D6776DD5080.
..051089A015060.
..0511000115050.
.0024EE00EE4250.
024ED668866DE40.
02405DD9AD505D50
.00.055DD550050.
....02444420.050
...05D6006D50.0.
...05D5005D50...
..00550..05500..
..0000....0000..
................
---
................
......0000....00
.....04EE40..0A7
...005666D500890
..05D6776DD5080.
..051008A915060.
.0024EE00EE4250.
024ED669A66DE40.
020.05D88D556D0.
.0..055DD550050.
....02444420.00.
..005D6006D500..
.05D550..055D50.
.00500....00500.
................
................

@SPRITE :guardian 32x32 pal:5
..............0000..............
.....00......09AA90......00.....
....0820....09A77A90....0280....
...08E20..0049AC7C9400..02820...
...08220005669ACC94D550002220...
....02256676DD4994DDD6552220....
.....005676DDDDDDDDDDD55500.....
......056DDDDDDDDDDDDDD550......
.....056D10000DDDD00001D550.....
.....05D108EE80DD08EE801D50.....
.....05D108E780DD087E801D50.....
......05110000DDDD00001150......
...000055DDDD49AA94DDDD550000...
..049AA9455D49A77A94D5549AA940..
.049A766D55149ACCA94155D669940..
049966DDD51004999940015DDDD6940.
0445DDDD510.05DDDD50.015DDDD540.
.000555500..05288250..005555000.
.0566500...05D8EE8D50...0056D50.
05676D50...0528E78250...05D6D550
056DDD50...05D8EE8D50...05DDDD50
05551550....05288250....05515550
08E00080....05DDDD50....08000E80
080..080...049AAAA940...080..080
.0....0...04995DD59940...0....0.
.........0566510015D550.........
........056D510..015DD50........
........056D50....05DD50........
.......049AA940..0499A940.......
.......00444400..00444400.......
.........0CC0......0CC0.........
................................
---
.....00.......0000.......00.....
....08E0.....09AA90.....0E80....
...08E70...009A77A900...07820...
...08220.0049AC77CA9400.02220...
....022005669AC77CA955000220....
.....0056776DD4AA4DDD655000.....
..00..0566DDDDDDDDDDDD550..00...
.08E0056D10000DDDD00001D550E80..
08E7005D108EE80DD08EE801D507E80.
0566005D10E77E0DD0E77E01D506D50.
05676051108EE8DDDD8EE8115066D50.
056DD5055DDDD49AA94DDDD555DDD50.
049AA9555D49A7777A94D5559AA940..
.049966D5149AC77CA9415D669940...
..0056DD500049AAAA940005DD500...
...03CC300..05288250..003CC30...
..03C7C30..05D8EE8D50..03C7C30..
..003C30..0528E77E8250..03C300..
....030...05D8E77E8D50...030....
..........0528EEEE8250..........
...........05D2882D50...........
...........05DDDDDD50...........
..........049AAAAAA940..........
........004995DDDD599400........
.......0566651000015DD550.......
......056DD510....015DDD50......
......049AA940....0499AA940.....
......00444400....00444400......
.......03CC30......03CC30.......
........0770........0770........
................................
................................

@SPRITE :relic 16x16 pal:1
................
......0000......
....002CC200....
.00.02C67C20.00.
0AA0026776200AA0
09AA02CCCC20AA90
.09AA022220AA90.
..0499AAAA9940..
...0049AA9400...
.....049940.....
....049AA940....
...0048888400...
...0000000000...
................
................
................
---
......0000......
....002CC200....
.00.02677620.00.
0A7002C7BC2007A0
09AA02CBBC20AA90
.09AA02CC20AA90.
..049000000940..
...049AAAA940...
....004AA400....
.....049940.....
....049AA940....
...0048888400...
...0000000000...
................
................
................

@SPRITE :shard 16x16 pal:1
.......00.......
..A...0260......
.....026760.....
....02C67C20....
...02CC7ACC20...
...02CC77CC20...
...022CCCC220...
....022CC220..A.
.....022220.....
......0220......
.......00.......
................
................
................
................
................
---
.......00.......
......0670...A..
.....0267C0.....
....02C7AC20....
...02CA77AC20...
...02CC7ACC20...
...02CCC6CC20...
.A..022CC220....
.....022220.....
......0220......
.......00.......
................
................
................
................
................

@SPRITE :heart_vessel 16x16 pal:5
................
..0000....0000..
.049AA0..0AA940.
0498EE8008EE8940
098E77E88EE88290
098E7EEEEE882290
048EEEEEEEE82240
.048EEEEEE82240.
..0488EEE88240..
...0428888240...
....04288240....
.....042240.....
......0440......
.......00.......
................
................
---
................
..0000....0000..
.09AAA0..0AAA90.
09AEEE8008EEEA90
0AEE77EEEE7EE8A0
0AEE77EEEEEEE8A0
098EEEEEEEE88290
.098EEEEEE88290.
..0488EEE88240..
...0428888240...
....04288240....
.....042240.....
......0990......
.......00.......
................
................

@SPRITE :torch 16x16 pal:1
.......00.......
......09A0..A...
.....09A7A0.....
....089A7A90....
....089AA7980...
....0489A9840...
.....0488840....
....005DD5500...
.....05D9D50....
......05D50.....
......04840.....
......04440.....
.......000......
................
................
................
---
......00........
..A..0AA0.......
....09A790......
....08A77A0.....
...0897AA980....
....04899840....
.....0488840....
....005DD5500...
.....05D9D50....
......05D50.....
......04840.....
......04440.....
.......000......
................
................
................

@SPRITE :tile_stone 16x16 pal:6
006666DDDD551000
066DDDDDDD55105D
06DDDDDDDD5106DD
0DDDD55551105DDD
0DDD510000005DD5
055510666DDD1551
011006DDDDDD5000
06D50DDDDDDD5106
6DD50DDD5555110D
DDD105510000005D
55100000666DDD55
00066DD06DDDDDD5
5506DDD0DDDDDDD1
DD05DD5055555110
D501510000000066
10000055DDDD506D

@SPRITE :tile_moss 16x16 pal:6
03BAAABBBB33BAA0
3BAAAABBBBBAAAB3
BAAABBB33BBAAABB
3BBB3303B33BBB33
03B3060330503B30
00306DD006D50300
06D0DDD50DDD506D
6DD055510DDD10DD
DDD10000055105DD
551066DDD0000155
0006DDDDD5066000
550DDDDDD506DD50
DD0555551105DD50
D500000000015106
1066DDDD5510006D
006DDDDDD51055DD

@SPRITE :tile_crystal 16x16 pal:6
011002CC70011510
15102C77C2015D50
1102CC7CCC201510
002CCC7CCCC20000
022CC7CCCCCC2201
2CCC7CCCCCCCC720
CC77CCCCCCCC77C2
2CCCCCCCCCC7CCC2
022CCCC7CCCCCC20
1002CC77CCCC2201
5102CC7CCCC20015
D5002CCCCC2015DD
510102CCC2015DD5
0015102C20155510
06DD500200110006
0551001000005505

@SPRITE :tile_phase 16x16 pal:6
....0E7777E0....
....0ECCCCE0....
....07EEEE70....
....0EE77EE0....
....0E7EE7E0....
....0ECCECE0....
....07EEEE70....
....0EE77EE0....
....0E7EE7E0....
....0ECECCE0....
....07EEEE70....
....0EE77EE0....
....0E7EE7E0....
....0ECCCCE0....
....07EEEE70....
....0E7777E0....
---
....07EEEE70....
....0EE77EE0....
....0ECCCCE0....
....07EEEE70....
....0EE77EE0....
....0E7EE7E0....
....0ECCECE0....
....07EEEE70....
....0EE77EE0....
....0E7EE7E0....
....0ECECCE0....
....07EEEE70....
....0EE77EE0....
....0ECCCCE0....
....0EE77EE0....
....07EEEE70....

@SPRITE :tile_spike 16x16 pal:6
................
................
...00......00...
...080....080...
..0870....0870..
..0760....0760..
..06D50..06D50..
.076D50..076D50.
.06DDD5006DDD50.
.06DDD5006DDD50.
076DDD5506DDD550
06DDDD5106DDDD51
06DDD55106DDD551
055D5511055D5511
0155110001551100
0000000000000000

@SPRITE :tile_plat 16x16 pal:6
0999997999999790
9994449999444994
4440004444000440
00066D000066D000
..06D50..06D50..
...0510...0510..
....00.....00...
................
................
................
................
................
................
................
................
................

@SFX :confirm
wave=pulse12 T240 L16 O5 c e g > c e8:fade

@SFX :jump
wave:triangle freq:195->540 dur:0.11 env:decay vol:0.8

@SFX :djump
wave:pulse12 freq:360->760->1080 dur:0.14 env:decay vol:0.82

@SFX :land
wave:triangle freq:135->52 dur:0.045 env:decay vol:0.42

@SFX :shoot
wave:pulse freq:780->250 dur:0.085 env:punch vol:0.75

@SFX :sonic_shot
wave:phaser freq:1120->420->880 dur:0.15 env:punch vol:0.85

@SFX :dash
wave:phaser freq:640->210->960 dur:0.14 env:decay vol:0.85

@SFX :hit
wave:square freq:360->95 dur:0.075 env:punch vol:0.85

@SFX :shatter
wave:saw freq:720->150->520->85 dur:0.26 env:decay vol:0.95

@SFX :foe_die
wave:saw freq:440->85 dur:0.20 env:punch vol:0.85

@SFX :boss_shot
wave:phaser freq:300->140->380 dur:0.18 env:decay vol:0.78

@SFX :player_hurt
wave:saw freq:250->70 dur:0.22 env:punch vol:0.95

@SFX :shard
wave=pulse12 T260 L16 O5 g b > d g b8:fade

@SFX :heal
wave=triangle T240 L16 O4 f a > c f a > c8:fade

@SFX :relic
wave=pulse T210 L16 O4 e g b > e d# e g# b > e4:fade

@SFX :clear
wave=pulse T200 L16 O4 c e g > c < g > c e g > c4:fade

@SFX :gameover
wave=saw T150 L8 O4 e d# d c# c < b2:fade

@MUSIC :entry_bgm
ch0 wave=pulse vol=4 T112 L8 O4 e4 g b > e4 d < b  > c4 < b g e4 g4  f#4 a > d c < b a f#  g4 b > d d#4 < b4  > e4 g f# e4 < b g  a4 > c e d4 c < a  g4 > c d e4 d c  < b4 > d# f# e2
ch1 wave=pulse12 vol=3 T112 L8 O4 < b > e g b g e < b > e  c e g > c < g e c e  d f# a > d < a f# d f#  d g b > d < d# f# b > d# <  e g b > e < b g e g  c e a > c < a e c e  c e g > c < d f# a > d <  < b > d# f# b g e < b4
ch2 wave=tri vol=5 T112 L8 O2 e4 e b > e4 < b4  c4 c g > c4 < g4  d4 d a > d4 < a4  g4 d4 < b4 > f#4  e4 e b > e4 < g4  a4 a > e a4 e4 <  c4 g4 d4 a4  < b4 > f#4 e4 < b4 >
ch3 wave=noise vol=2 T112 L8 O5 c r > g < r g r > g < r  c r > g < r g r > g < r  c r > g < r g r > g < r  c r > g < r c > g c g <  c r > g g < c r > g < r  c r > g g < c r > g < r  c r > g g < c r > g < r  c > g < c > g c c g g <

@MUSIC :cavern_bgm
ch0 wave=pulse12 vol=4 T120 L8 O4 c4 d# g > c4 < g d#  < g#4 > c d# g4 f d#  f4 g# > c < a#4 g# f  g4 b > d < g2  > c4 d d# g4 f d#  d4 c < a# > c4 < g# g  f4 g g# b4 > d < b  > c4 < g d# c2
ch1 wave=organ vol=3 T120 L8 O3 g > c d# g d# c < g > c  < g# > c d# g# d# c < g# > c  < f g# > c f c < g# f g#  g b > d g f d < b g  g > c d# g d# c < g > d#  < g# > c d# < a# > d f < a# > d  < f g# > c f < g b > d g  < g > c d# g c4 < r4
ch2 wave=tri vol=5 T120 L8 O2 c4 c g > c4 < g4  < g#4 g# > d# g#4 d#4  < f4 f > c f4 c4  < g4 g > d g4 < b4 >  c4 g > c < g4 d#4  < g#4 > d#4 < a#4 > f4  < f4 > c4 < g4 > d4  c4 < g4 > c4 < g4 >
ch3 wave=noise vol=2 T120 L8 O5 c r > a < r c c > a < r  c r > a < r c c > a < r  c r > a < r c c > a < r  c r > a < c r > a a < c  c > a < c > a < c r > a < r  c > a < c > a < c r > a < r  c > a < c > a < c r > a < r  c > a < c > a < c c > a a <

@MUSIC :abyss_bgm
ch0 wave=square vol=4 T132 L8 O4 d4 f a > d4 c < a  a#4 > d f e4 d c <  g4 a# > d c4 < a# g  a4 > c# e < a2  > f4 e d a4 f d  d4 c < a# > c4 e g  f4 d < a# > c#4 e a  d4 < a f d2
ch1 wave=pulse12 vol=3 T132 L16 O4 d f a > d < a f d a d f a > d < a f d a  < a# > d f a# f d < a# > f < a# > d f a# e c < g > c  < g a# > d g d < a# g > d < g a# > d g c < g e g  a > c# e a e c# < a > e < a > c# e a g e c# < a  > d f a > d < a f d a d f a > d < a f d < a  a# > d f a# f d < a# > d c e g > c < g e c g  < g a# > d g d < a# g a# a > c# e a e c# < a > c#  d f a > d < a f d a f d < a > d d r r r
ch2 wave=tri vol=5 T132 L8 O2 d > d < d > d < d a f a  < a# > a# < a# > a# c > c < c g  < g > g < g > g c > c < c g  < a > a < a > a < a > e c# < a >  d > d < d > d < f > f < d a  < a# > a# < a# > f c > c < e g  < g > d < g a# a > e c# < a >  d a f a d4 < a4 >
ch3 wave=noise vol=2 T132 L8 O5 c > g < d > g < c c d > g <  c > g < d > g < c c d > g <  c > g < d > g < c c d > g <  c > g < d > g < c d c d  c > g < d > g < c > g < d > g <  c > g < d > g < c > g < d > g <  c > g < d > g < c > g < d > g <  c d c d c c d d

@MUSIC :boss_bgm
ch0 wave=saw vol=4 T156 L8 O4 e e > e < b > c < b g# e  f f > f c d c < a f  g g > g d e d < b g  a4 g#4 f4 e4  > c4 < b a > e4 d c  f4 e d c4 < b a  b4 > d c < b4 a g#  a b > c d# e4 < b4
ch1 wave=square vol=3 T156 L8 O3 b b > g# e f e < b g#  > c c a f g f c < a  > d d b g a g d < b  > c4 < b4 a4 g#4  a > c e a c e a e <  f a > c f < a > c f c <  f b > d f < e g# b > e <  f# g# a b > g#4 e4 <
ch2 wave=tri vol=6 T156 L8 O2 e e > e < e e e g# b  f f > f < f f f a > c <  g g > g < g g g b > d <  a a g# g# f f e e  a a > e < a a a > c e <  f f > c < f f f a > c <  d d a d e e b e  < b b > d# f# e e < b > d
ch3 wave=noise vol=3 T156 L8 O5 c > g < d > g < c c d > g <  c > g < d > g < c c d > g <  c > g < d > g < c c d > g <  c d c d c c d d  c > g < d > g < c > g < d > g <  c > g < d > g < c > g < d > g <  c > g < d > g < c > g < d > g <  d d c d d d c c

@MUSIC :pinch_bgm
ch0 wave=pulse vol=4 T146 L8 O4 c# d# e g# e d# c# < b >  c# e a g# f# e d# c#  < a > c# f# e d# c# < b a  g#4 > c4 d#4 g#4  > c#4 < b g# > c#4 d# e  d#4 c# < b a4 > c# < a  g#4 a f# g#4 > c < g#  f# g# a b > c#4 < g#4
ch1 wave=pulse12 vol=3 T146 L8 O3 g# > c# e g# e c# < g# > c#  < a > c# e a e c# < a > c#  < f# a > c# f# c# < a f# a  g# > c d# g# f# d# c < g#  > c# e g# > c# < g# e c# e  < a > c# e a < f# a > c# f# <  f# a > d# f# < g# > c d# g# <  a b > c# d# e4 c#4 <
ch2 wave=tri vol=6 T146 L8 O2 c# > c# < c# > c# < c# g# e g#  < a > a < a > a < a > e c# e  < f# > f# < f# > f# < f# > c# < a > c#  < g# > g# < g# > d# g# f# d# < g# >  c# > c# < c# > c# < e > e < c# g#  < a > e < a > c# < f# > c# < f# a  f# > c < f# a g# > d# c < g# >  c# g# e g# c#4 < g#4 >
ch3 wave=noise vol=3 T146 L8 O5 c c > g < d c c > d g <  c c > g < d c c > d g <  c c > g < d c c > d g <  c d c d c c d d  c > g < d > g < c c > d g <  c > g < d > g < c c > d g <  c > g < d > g < c c > d g <  d c d c d d c c
