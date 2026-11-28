config(
  title: "CRYPT OF THE BEAT",
  width: 320,
  height: 240,
  save_id: "crypt_of_the_beat",
  save_salt: "p4g51bt9"
)

$cfg = {
  w: 320,
  h: 240,
  tile: 16,
  map_w: 17,
  map_h: 11,
  ox: 24,
  oy: 22,
  bpm_norm: 120,
  bpm_boss: 150,
  beat_frames_norm: 30,
  beat_frames_boss: 24,
  window_perfect: 6,
  window_good: 10,
  start_hp: 6,
  max_floors: 5,
  torch_base_r: 68,
  torch_beat_r: 16,
  wall_torch_r: 42
}

$weapons = [
  { id: "dagger", name: "BEAT DAGGER", cost: 0, atk: 2, desc: "1-TILE LUNGE / +GROOVE", col: 7 },
  { id: "spear", name: "SONIC SPEAR", cost: 60, atk: 2, desc: "2-TILE PIERCE THRUST", col: 12 },
  { id: "broadsword", name: "CHORD BLADE", cost: 140, atk: 3, desc: "WIDE 3-TILE ARC SLASH", col: 10 },
  { id: "hammer", name: "BASS HAMMER", cost: 240, atk: 4, desc: "HEAVY QUAKE SHOCKWAVE", col: 9 }
]

$enemies = {
  slime: { name: "PULSE SLIME", spr: :slime, hp: 2, atk: 1, every: 2, gold: 8, col: 11 },
  bat: { name: "SYNC BAT", spr: :bat, hp: 2, atk: 1, every: 1, gold: 10, col: 14 },
  skeleton: { name: "BEAT BONES", spr: :skeleton, hp: 4, atk: 1, every: 2, gold: 15, col: 7 },
  reaper: { name: "TEMPO WRAITH", spr: :reaper, hp: 6, atk: 2, every: 2, gold: 24, col: 13 },
  boss: { name: "NECRO CONDUCTOR", spr: :conductor, hp: 28, atk: 2, every: 2, gold: 120, col: 8 }
}

class TitleScene
  def initialize
    @gold = save_get("gold", 0)
    @best_floor = save_get("best_floor", 0)
    @clears = save_get("clears", 0)
    @best_score = save_get("best_score", 0)
    @unlocked = save_get("unlocked", ["dagger"])
    @sel = save_get("last_weapon", 0)
    @sel = 0 if @sel < 0 || @sel >= $weapons.size
    @tick = 0
    @msg = ""
    @msg_t = 0
    music(:title_bgm, true, 0.7)
  end

  def update
    @tick += 1
    @msg_t -= 1 if @msg_t > 0

    if btnp(:left) || btnp(:up)
      @sel = (@sel - 1 + $weapons.size) % $weapons.size
      sfx(:select)
    elsif btnp(:right) || btnp(:down)
      @sel = (@sel + 1) % $weapons.size
      sfx(:select)
    end

    w = mouse_wheel
    if w > 0
      @sel = (@sel - 1 + $weapons.size) % $weapons.size
      sfx(:select)
    elsif w < 0
      @sel = (@sel + 1) % $weapons.size
      sfx(:select)
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 96 && my <= 168
        idx = ((mx - 16) / 72).to_i
        if idx >= 0 && idx < $weapons.size
          if @sel == idx
            try_action
            return
          else
            @sel = idx
            sfx(:select)
          end
        end
      elsif my >= 182 && my <= 210 && mx >= 84 && mx <= 236
        try_action
        return
      end
    end

    if btnp(1)
      try_action
    elsif btnp(2)
      wp = $weapons[@sel]
      if @unlocked.index(wp[:id]).nil? && @gold >= wp[:cost]
        unlock_selected
      end
    end
  end

  def unlock_selected
    wp = $weapons[@sel]
    @gold -= wp[:cost]
    @unlocked << wp[:id]
    save_set("gold", @gold)
    save_set("unlocked", @unlocked)
    sfx(:powerup)
    @msg = "UNLOCKED #{wp[:name]}!"
    @msg_t = 90
  end

  def try_action
    wp = $weapons[@sel]
    if !@unlocked.index(wp[:id]).nil?
      save_set("last_weapon", @sel)
      sfx(:confirm)
      run DungeonScene.new({ weapon_idx: @sel })
    elsif @gold >= wp[:cost]
      unlock_selected
    else
      sfx(:cancel)
      @msg = "NEED #{wp[:cost]}G TO UNLOCK!"
      @msg_t = 60
    end
  end

  def draw
    cls(0)
    beat_phase = (@tick % 30) / 30.0
    pulse = 1.0 - beat_phase
    bg(:cave, dim: 0.45 - pulse * 0.12, tint: "#9040C0", scroll_x: @tick * 0.2, mirror_x: true)

    # Disco crypt floor preview bars
    i = 0
    while i < 10
      col = ((i + (@tick / 30)) % 2 == 0) ? 2 : 13
      rectfill(i * 32, 206, 30, 34, col, 0.16 + pulse * 0.14)
      i += 1
    end
    rectfill(0, 208, 320, 32, 0, 0.65)

    spr_f = (@tick / 15) % 2
    spr(spr_id(:hero, spr_f), 44, 20, false, nil, 0.0, 1.5)
    spr(spr_id(:conductor, spr_f), 250, 12, false, nil, 0.0, 1.0)

    print_text("CRYPT OF THE BEAT", 160, 14, 10, 16, 1.0, :center, 0, 2)
    print_text("RHYTHM ROGUELITE DUNGEON", 160, 34, 14, 8, 1.0, :center, 0)

    stat = "GOLD:#{@gold}G  BEST:B#{@best_floor}F  HI:#{@best_score}  CLEARS:#{@clears}"
    rectfill(20, 50, 280, 16, 0, 0.78)
    rect(20, 50, 280, 16, 13, 1)
    print_text(stat, 160, 54, 7, 8, 1.0, :center, 0)

    print_text("SELECT WEAPON (ARROWS / Z: ENTER OR UNLOCK)", 160, 74, 6, 8, 1.0, :center, 0)

    idx = 0
    while idx < $weapons.size
      wp = $weapons[idx]
      owned = !@unlocked.index(wp[:id]).nil?
      sel = (@sel == idx)
      bx = 16 + idx * 73
      by = 88
      rectfill(bx, by, 68, 72, sel ? 1 : 0, 0.88)
      rect(bx, by, 68, 72, sel ? 10 : (owned ? wp[:col] : 5), sel ? 2 : 1)

      short_name = wp[:name].split(" ")[1] || wp[:name]
      print_text(short_name, bx + 34, by + 8, owned ? wp[:col] : 5, 8, 1.0, :center, 0)
      print_text("ATK #{wp[:atk]}", bx + 34, by + 24, 7, 8, 1.0, :center, 0)

      if owned
        print_text("OWNED", bx + 34, by + 44, 11, 8, 1.0, :center, 0)
      else
        c_col = @gold >= wp[:cost] ? 10 : 8
        print_text("#{wp[:cost]}G", bx + 34, by + 44, c_col, 8, 1.0, :center, 0)
      end
      idx += 1
    end

    cur = $weapons[@sel]
    owned_cur = !@unlocked.index(cur[:id]).nil?
    print_text("#{cur[:name]}: #{cur[:desc]}", 160, 166, cur[:col], 8, 1.0, :center, 0)

    rectfill(78, 180, 164, 24, 2, 0.92)
    rect(78, 180, 164, 24, 10, 2)
    act_txt = owned_cur ? "DESCEND CRYPT (Z)" : "UNLOCK #{cur[:cost]}G (Z)"
    print_text(act_txt, 160, 188, 10, 8, 1.0, :center, 0)

    if @msg_t > 0
      print_text(@msg, 160, 210, 11, 8, 1.0, :center, 0)
    else
      print_text("MOVE/ATTACK ON THE BEAT FOR 2X GROOVE & PITCH CHAIN!", 160, 212, 7, 8, 1.0, :center, 0)
    end
    print_text("DIRS: MOVE/ATTACK  Z: BOMB/WAIT  X: TORCH PULSE", 160, 226, 6, 8, 1.0, :center, 0)
  end
end

class DungeonScene
  def initialize(opts)
    @w_idx = opts[:weapon_idx] || 0
    @weapon = $weapons[@w_idx]
    @w = $cfg[:w]
    @h = $cfg[:h]
    @mw = $cfg[:map_w]
    @mh = $cfg[:map_h]
    @ox = $cfg[:ox]
    @oy = $cfg[:oy]
    @ts = $cfg[:tile]

    @lightmap = create_surface(@w, @h, :gpu)
    @decals = create_surface(@w, @h, :gpu)

    @floor = 1
    @hp = $cfg[:start_hp]
    @max_hp = $cfg[:start_hp]
    @atk_bonus = 0
    @torch_bonus = 0
    @bombs = 2
    @run_gold = 0
    @score = 0
    @groove = 0
    @max_groove = 0

    @tick = 0
    @beat_count = 0
    @acted_beat = -99
    @shake = 0.0
    @hitstop = 0
    @state = :play # :play, :win, :gameover
    @state_t = 0

    @px = 2
    @py = 5
    @p_flip = false
    @p_hop = 0.0
    @p_inv = 0

    @grid = []
    @torches = []
    @items = []
    @foes = []
    @slashes = []
    @popups = []
    @particles = []
    @stairs = [14, 5]
    @stairs_locked = false

    setup_floor
  end

  def setup_floor
    clear_surface(@decals, nil)
    @boss_floor = (@floor == $cfg[:max_floors])
    @beat_len = @boss_floor ? $cfg[:beat_frames_boss] : $cfg[:beat_frames_norm]
    music(@boss_floor ? :boss_bgm : :crypt_bgm, true, 0.72)

    @tick = 0
    @beat_count = 0
    @acted_beat = -99
    @slashes.clear
    @popups.clear
    @particles.clear
    @torches.clear
    @items.clear
    @foes.clear

    # Build grid: 0 = floor, 1 = wall
    @grid = []
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

    @px = 2
    @py = @mh / 2

    if @boss_floor
      build_boss_arena
    else
      build_crypt_rooms
    end

    add_popup(@px, @py, @boss_floor ? "FINAL CRYPT!" : "FLOOR B#{@floor}F", 10)
  end

  def build_boss_arena
    # Pillars + torches in grand concert crypt
    pillars = [[4, 3], [4, 7], [8, 2], [8, 8], [12, 3], [12, 7]]
    i = 0
    while i < pillars.size
      pt = pillars[i]
      @grid[pt[1]][pt[0]] = 1
      @torches << [pt[0], pt[1]]
      i += 1
    end
    @stairs = [15, 5]
    @stairs_locked = true
    spawn_foe(:boss, 13, 5)
    spawn_foe(:skeleton, 10, 3)
    spawn_foe(:skeleton, 10, 7)
    @items << { x: 6, y: 2, kind: :heart }
    @items << { x: 6, y: 8, kind: :bomb }
  end

  def build_crypt_rooms
    # Scatter destructible crypt pillars & wall torches
    y = 2
    while y < @mh - 2
      x = 3
      while x < @mw - 3
        if (x + y) % 3 == 0 && rand(100) < 34
          @grid[y][x] = 1
          if rand(100) < 45
            @torches << [x, y]
          end
        end
        x += 1
      end
      y += 1
    end

    # Ensure clear path from start to stairs
    @stairs = [@mw - 3, 2 + rand(@mh - 4)]
    cx = @px
    cy = @py
    while cx < @stairs[0]
      @grid[cy][cx] = 0
      cx += 1
      @grid[cy][cx] = 0
      if cy < @stairs[1] && rand(100) < 55
        cy += 1
        @grid[cy][cx] = 0
      elsif cy > @stairs[1] && rand(100) < 55
        cy -= 1
        @grid[cy][cx] = 0
      end
    end
    while cy != @stairs[1]
      cy += (cy < @stairs[1] ? 1 : -1)
      @grid[cy][cx] = 0
    end
    @stairs_locked = false

    # Boundary wall torches
    @torches << [4, 0]
    @torches << [12, 0]
    @torches << [4, @mh - 1]
    @torches << [12, @mh - 1]

    # Spawn enemies scaled by floor
    pool = [:slime, :bat]
    pool << :skeleton if @floor >= 2
    pool << :reaper if @floor >= 3
    count = 4 + @floor * 2
    tries = 0
    spawned = 0
    while spawned < count && tries < 80
      tries += 1
      ex = 4 + rand(@mw - 5)
      ey = 1 + rand(@mh - 2)
      next if @grid[ey][ex] != 0
      next if (ex - @px).abs + (ey - @py).abs < 4
      next if ex == @stairs[0] && ey == @stairs[1]
      next if foe_at(ex, ey)
      kind = pool[rand(pool.size)]
      spawn_foe(kind, ex, ey)
      spawned += 1
    end

    # Spawn treasure chests / pickups
    item_kinds = [:chest, :heart, :torch, :bomb]
    ic = 2 + (@floor >= 3 ? 1 : 0)
    k = 0
    while k < ic
      ix = 3 + rand(@mw - 5)
      iy = 1 + rand(@mh - 2)
      if @grid[iy][ix] == 0 && !(ix == @stairs[0] && iy == @stairs[1]) && !foe_at(ix, iy) && !item_at(ix, iy)
        @items << { x: ix, y: iy, kind: item_kinds[k % item_kinds.size] }
      end
      k += 1
    end
  end

  def spawn_foe(kind, x, y)
    spec = $enemies[kind]
    @foes << {
      kind: kind,
      spr: spec[:spr],
      x: x,
      y: y,
      hp: spec[:hp] + (@floor - 1) / 2,
      max_hp: spec[:hp] + (@floor - 1) / 2,
      atk: spec[:atk],
      every: spec[:every],
      cd: spec[:every],
      gold: spec[:gold],
      col: spec[:col],
      hop: 0.0,
      flip: false,
      intent_dx: 0,
      intent_dy: 0
    }
    if kind == :boss
      f = @foes.last
      f[:hp] = spec[:hp]
      f[:max_hp] = spec[:hp]
    end
  end

  def foe_at(x, y)
    i = 0
    while i < @foes.size
      f = @foes[i]
      return f if f[:hp] > 0 && f[:x] == x && f[:y] == y
      i += 1
    end
    nil
  end

  def item_at(x, y)
    i = 0
    while i < @items.size
      it = @items[i]
      return it if it[:x] == x && it[:y] == y
      i += 1
    end
    nil
  end

  def nearest_beat_info
    rem = @tick % @beat_len
    if rem <= @beat_len / 2
      [@beat_count, rem]
    else
      [@beat_count + 1, @beat_len - rem]
    end
  end

  def update
    if @state != :play
      @state_t += 1
      if @state_t > 25 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        finish_and_save
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
    @p_hop *= 0.72
    @p_inv -= 1 if @p_inv > 0

    # Beat trigger!
    if (@tick % @beat_len) == 0
      @beat_count += 1
      on_every_beat
    end

    handle_player_input
    update_effects
  end

  def on_every_beat
    # Subtle kick pulse & enemy beat step
    sfx(:kick_pulse, -1, 0.35, 1.0)
    step_enemies

    # Decay groove if player skipped 2 full beats without acting
    if @beat_count - @acted_beat >= 2 && @groove > 0
      @groove -= 1
    end
  end

  def handle_player_input
    dx = 0
    dy = 0
    act = nil

    if btnp(:left)
      dx = -1
      act = :move
    elsif btnp(:right)
      dx = 1
      act = :move
    elsif btnp(:up)
      dy = -1
      act = :move
    elsif btnp(:down)
      dy = 1
      act = :move
    elsif btnp(1)
      act = :bomb_or_wait
    elsif btnp(2)
      act = :flare
    end

    return unless act

    b_info = nearest_beat_info
    target_beat = b_info[0]
    dist = b_info[1]

    # Prevent mashing multiple moves on the exact same beat
    if target_beat == @acted_beat
      sfx(:click, -1, 0.3, 0.7)
      return
    end

    @acted_beat = target_beat
    rating = :off
    if dist <= $cfg[:window_perfect]
      rating = :perfect
      @groove = (@groove + 1).clamp(0, 16)
      @max_groove = @groove if @groove > @max_groove
      pitch = (1.0 + @groove * 0.055).clamp(1.0, 2.0)
      sfx(:beat_ok, -1, 0.65, pitch)
    elsif dist <= $cfg[:window_good]
      rating = :good
      @groove = (@groove + 1).clamp(0, 16)
      @max_groove = @groove if @groove > @max_groove
      pitch = (1.0 + @groove * 0.045).clamp(1.0, 1.85)
      sfx(:beat_ok, -1, 0.5, pitch)
    else
      # Off-beat still executes action for responsive play, but resets groove multiplier
      @groove = (@groove / 2).to_i
      sfx(:step, -1, 0.45, 0.8)
    end

    if act == :move
      @p_flip = true if dx < 0
      @p_flip = false if dx > 0
      perform_move_or_attack(dx, dy, rating)
    elsif act == :bomb_or_wait
      if @bombs > 0 && nearby_threat_or_wall?
        detonate_sonic_bomb(rating)
      else
        @p_hop = 3.5
        lbl = (rating == :off) ? "WAIT" : "BEAT!"
        add_popup(@px, @py, lbl, rating == :off ? 6 : 12)
      end
    elsif act == :flare
      # Sonic torch pulse: stuns adjacent foes by +1 beat & illuminates
      @p_hop = 4.0
      sfx(:laser, -1, 0.6, 1.25)
      stamp_ring(@px, @py, 22, 10)
      i = 0
      while i < @foes.size
        f = @foes[i]
        if f[:hp] > 0 && (f[:x] - @px).abs <= 2 && (f[:y] - @py).abs <= 2
          f[:cd] += 1
          add_popup(f[:x], f[:y], "DAZE!", 10)
        end
        i += 1
      end
    end
  end

  def nearby_threat_or_wall?
    i = 0
    while i < @foes.size
      f = @foes[i]
      return true if f[:hp] > 0 && (f[:x] - @px).abs <= 2 && (f[:y] - @py).abs <= 2
      i += 1
    end
    false
  end

  def detonate_sonic_bomb(rating)
    @bombs -= 1
    sfx(:explode, -1, 0.95, rating == :perfect ? 1.15 : 1.0)
    @shake = 7.0
    @hitstop = 3
    stamp_ring(@px, @py, 34, 9)

    # Clear surrounding walls & blast foes
    dy = -1
    while dy <= 1
      dx = -1
      while dx <= 1
        tx = @px + dx
        ty = @py + dy
        if tx > 0 && tx < @mw - 1 && ty > 0 && ty < @mh - 1
          @grid[ty][tx] = 0
        end
        dx += 1
      end
      dy += 1
    end

    dmg = (rating == :off) ? 4 : 6
    i = 0
    while i < @foes.size
      f = @foes[i]
      if f[:hp] > 0 && (f[:x] - @px).abs <= 2 && (f[:y] - @py).abs <= 2
        damage_foe(f, dmg, rating)
      end
      i += 1
    end
    add_popup(@px, @py, "SONIC DROP!", 9)
  end

  def weapon_targets(dx, dy)
    wid = @weapon[:id]
    targets = [[@px + dx, @py + dy]]
    if wid == "spear"
      targets << [@px + dx * 2, @py + dy * 2]
    elsif wid == "broadsword"
      if dx != 0
        targets << [@px + dx, @py - 1]
        targets << [@px + dx, @py + 1]
      else
        targets << [@px - 1, @py + dy]
        targets << [@px + 1, @py + dy]
      end
    elsif wid == "hammer"
      targets << [@px + dx * 2, @py + dy * 2]
      if dx != 0
        targets << [@px + dx, @py - 1]
        targets << [@px + dx, @py + 1]
      else
        targets << [@px - 1, @py + dy]
        targets << [@px + 1, @py + dy]
      end
    end
    targets
  end

  def perform_move_or_attack(dx, dy, rating)
    t_list = weapon_targets(dx, dy)
    hit_foes = []
    i = 0
    while i < t_list.size
      tp = t_list[i]
      f = foe_at(tp[0], tp[1])
      hit_foes << f if f && hit_foes.index(f).nil?
      i += 1
    end

    if !hit_foes.empty?
      # Attack!
      base_dmg = @weapon[:atk] + @atk_bonus
      mult = (rating == :off) ? 1 : (@groove >= 6 ? 2 : 1)
      dmg = base_dmg * mult + (rating == :perfect ? 1 : 0)
      pitch = (0.95 + @groove * 0.06).clamp(0.9, 2.1)
      sfx(:slash, -1, 0.85, pitch)
      @p_hop = 4.5
      @shake = 3.5
      @hitstop = 2 if rating != :off

      k = 0
      while k < t_list.size
        tp = t_list[k]
        if tp[0] >= 0 && tp[0] < @mw && tp[1] >= 0 && tp[1] < @mh
          @slashes << { x: tp[0], y: tp[1], t: 10, col: @weapon[:col] }
        end
        k += 1
      end

      j = 0
      while j < hit_foes.size
        damage_foe(hit_foes[j], dmg, rating)
        j += 1
      end
      return
    end

    # Otherwise try to step onto adjacent tile
    nx = @px + dx
    ny = @py + dy
    if nx < 0 || nx >= @mw || ny < 0 || ny >= @mh || @grid[ny][nx] != 0
      # Dig cracked interior wall on perfect/good beat with hammer or groove >= 4!
      if nx > 0 && nx < @mw - 1 && ny > 0 && ny < @mh - 1 && (@weapon[:id] == "hammer" || @groove >= 4) && rating != :off
        @grid[ny][nx] = 0
        sfx(:hit, -1, 0.7, 0.8)
        spawn_sparks(nx, ny, 6, 8)
        add_popup(nx, ny, "DIG!", 10)
        @p_hop = 3.5
      else
        sfx(:hit, -1, 0.4, 0.6)
        @p_hop = 2.0
      end
      return
    end

    @px = nx
    @py = ny
    @p_hop = 4.5
    if rating == :perfect && (@groove % 4 == 0)
      add_popup(@px, @py, "x#{1 + @groove / 4} GROOVE!", 10)
    end
    stamp_step(@px, @py, rating == :off ? 5 : 12)
    check_tile_events
  end

  def damage_foe(f, dmg, rating)
    f[:hp] -= dmg
    f[:hop] = 5.0
    f[:cd] += 1 if @weapon[:id] == "hammer"
    spawn_sparks(f[:x], f[:y], f[:col], 10)
    lbl = (rating == :perfect) ? "#{dmg}!" : "#{dmg}"
    add_popup(f[:x], f[:y], lbl, rating == :perfect ? 10 : 7)

    if f[:hp] <= 0
      mult = 1 + (@groove / 4)
      g = f[:gold] * mult
      @run_gold += g
      @score += g * 10 + @groove * 25
      stamp_blood(f[:x], f[:y], f[:col])
      pitch = (1.0 + @groove * 0.05).clamp(1.0, 2.2)
      sfx(:coin, -1, 0.75, pitch)
      add_popup(f[:x], f[:y], "+#{g}G", 10)

      if f[:kind] == :boss
        @stairs_locked = false
        sfx(:clear)
        @shake = 8.0
        add_popup(@stairs[0], @stairs[1], "STAIRS OPEN!", 11)
      end
      @foes.reject! { |e| e[:hp] <= 0 }
    else
      sfx(:hit, -1, 0.65, 1.1)
    end
  end

  def check_tile_events
    it = item_at(@px, @py)
    if it
      case it[:kind]
      when :heart
        @hp = (@hp + 2).clamp(0, @max_hp)
        sfx(:heal)
        add_popup(@px, @py, "HP +2!", 8)
      when :torch
        @torch_bonus += 16
        sfx(:powerup)
        add_popup(@px, @py, "LIGHT UP!", 10)
      when :bomb
        @bombs += 1
        sfx(:powerup)
        add_popup(@px, @py, "BOMB +1!", 9)
      when :chest
        roll = rand(3)
        if roll == 0
          @max_hp += 1
          @hp = (@hp + 2).clamp(0, @max_hp)
          add_popup(@px, @py, "MAX HP +1!", 11)
        elsif roll == 1
          @atk_bonus += 1
          add_popup(@px, @py, "ATK +1!", 10)
        else
          bonus = 25 + @floor * 10
          @run_gold += bonus
          @score += bonus * 10
          add_popup(@px, @py, "+#{bonus}G!", 10)
        end
        sfx(:powerup, -1, 0.9, 1.15)
      end
      @items.reject! { |x| x == it }
    end

    if @px == @stairs[0] && @py == @stairs[1] && !@stairs_locked
      if @floor >= $cfg[:max_floors]
        @score += 1000 + @hp * 150
        sfx(:clear)
        stop_music
        @state = :win
        @state_t = 0
      else
        @floor += 1
        @score += 250
        sfx(:confirm, -1, 0.9, 1.2)
        setup_floor
      end
    end
  end

  def step_enemies
    spawn_queue = []
    i = 0
    while i < @foes.size
      f = @foes[i]
      if f[:hp] > 0
        f[:cd] -= 1
        if f[:cd] <= 0
          f[:cd] = f[:every]
          # Boss summons skeleton every 3 actions if room
          if f[:kind] == :boss && (@beat_count % 6 == 0) && @foes.size < 6
            sx = (f[:x] - 2).clamp(2, @mw - 3)
            sy = (f[:y] + (rand(2) == 0 ? -2 : 2)).clamp(2, @mh - 3)
            if @grid[sy][sx] == 0 && !foe_at(sx, sy) && !(sx == @px && sy == @py)
              spawn_queue << [sx, sy]
            end
          end

          dx = 0
          dy = 0
          dist_x = @px - f[:x]
          dist_y = @py - f[:y]
          if dist_x.abs >= dist_y.abs
            dx = dist_x <=> 0
          else
            dy = dist_y <=> 0
          end

          tx = f[:x] + dx
          ty = f[:y] + dy
          f[:flip] = true if dx < 0
          f[:flip] = false if dx > 0

          if tx == @px && ty == @py
            hit_player(f[:atk])
            f[:hop] = 5.0
          elsif tx > 0 && tx < @mw - 1 && ty > 0 && ty < @mh - 1 && @grid[ty][tx] == 0 && !foe_at(tx, ty)
            f[:x] = tx
            f[:y] = ty
            f[:hop] = 3.5
          end
        end
      end
      i += 1
    end

    k = 0
    while k < spawn_queue.size
      sp = spawn_queue[k]
      spawn_foe(:skeleton, sp[0], sp[1])
      sfx(:powerup, -1, 0.5, 0.65)
      add_popup(sp[0], sp[1], "SUMMON!", 14)
      k += 1
    end
  end

  def hit_player(dmg)
    return if @p_inv > 0
    @hp -= dmg
    @p_inv = 18
    @groove = 0
    @shake = 6.5
    @hitstop = 3
    sfx(:hit, -1, 0.95, 0.7)
    spawn_sparks(@px, @py, 8, 12)
    add_popup(@px, @py, "-#{dmg} HP!", 8)

    if @hp <= 0
      @hp = 0
      sfx(:gameover)
      stop_music
      @state = :gameover
      @state_t = 0
    end
  end

  def stamp_step(gx, gy, col)
    sx = @ox + gx * @ts + 8
    sy = @oy + gy * @ts + 12
    render_to(@decals) do
      circfill(sx, sy, 2, col, 0.35)
    end
  end

  def stamp_blood(gx, gy, col)
    sx = @ox + gx * @ts + 8
    sy = @oy + gy * @ts + 8
    render_to(@decals) do
      j = 0
      while j < 5
        circfill(sx + rand(11) - 5, sy + rand(11) - 5, 2 + rand(3), col, 0.45)
        j += 1
      end
    end
  end

  def stamp_ring(gx, gy, r, col)
    sx = @ox + gx * @ts + 8
    sy = @oy + gy * @ts + 8
    render_to(@decals) do
      circ(sx, sy, r, col, 0.5)
    end
  end

  def add_popup(gx, gy, txt, col)
    @popups << { x: @ox + gx * @ts + 8, y: @oy + gy * @ts, txt: txt, col: col, t: 36 }
  end

  def spawn_sparks(gx, gy, col, n)
    cx = @ox + gx * @ts + 8
    cy = @oy + gy * @ts + 8
    i = 0
    while i < n
      ang = rand * Math::PI * 2.0
      spd = 0.8 + rand * 2.4
      @particles << {
        x: cx.to_f,
        y: cy.to_f,
        vx: cos(ang) * spd,
        vy: sin(ang) * spd,
        col: col,
        t: 14 + rand(12)
      }
      i += 1
    end
  end

  def update_effects
    i = 0
    while i < @foes.size
      @foes[i][:hop] *= 0.72
      i += 1
    end

    i = 0
    while i < @slashes.size
      @slashes[i][:t] -= 1
      i += 1
    end
    @slashes.reject! { |s| s[:t] <= 0 }

    i = 0
    while i < @popups.size
      p = @popups[i]
      p[:y] -= 0.45
      p[:t] -= 1
      i += 1
    end
    @popups.reject! { |p| p[:t] <= 0 }

    i = 0
    while i < @particles.size
      pt = @particles[i]
      pt[:x] += pt[:vx]
      pt[:y] += pt[:vy]
      pt[:vx] *= 0.9
      pt[:vy] *= 0.9
      pt[:t] -= 1
      i += 1
    end
    @particles.reject! { |pt| pt[:t] <= 0 }
  end

  def finish_and_save
    total_gold = save_get("gold", 0) + @run_gold
    save_set("gold", total_gold)
    best_f = save_get("best_floor", 0)
    save_set("best_floor", @floor) if @floor > best_f
    best_s = save_get("best_score", 0)
    save_set("best_score", @score) if @score > best_s
    if @state == :win
      save_set("clears", save_get("clears", 0) + 1)
    end
  end

  def draw
    cls(0)
    beat_phase = (@tick % @beat_len).to_f / @beat_len.to_f
    pulse = 1.0 - beat_phase

    bg(@boss_floor ? :cyber : :cave, dim: 0.58, tint: @boss_floor ? "#C03070" : "#583890")

    cam_x = @shake > 0 ? (rand * @shake * 2.0 - @shake) : 0.0
    cam_y = @shake > 0 ? (rand * @shake * 2.0 - @shake) : 0.0
    camera(cam_x, cam_y)

    draw_crypt_tiles(pulse)
    draw_surface(@decals, 0, 0)
    draw_entities(pulse)
    draw_lightmap(pulse)
    draw_world_fx

    camera
    clip
    blend(:normal)
    draw_hud(pulse, beat_phase)
    draw_overlay if @state != :play
  end

  def draw_crypt_tiles(pulse)
    ox = @ox
    oy = @oy
    ts = @ts
    parity = @beat_count % 2

    y = 0
    while y < @mh
      row = @grid[y]
      sy = oy + y * ts
      x = 0
      while x < @mw
        sx = ox + x * ts
        if row[x] == 1
          rectfill(sx, sy, 16, 16, 1)
          rectfill(sx + 1, sy + 1, 14, 10, 5)
          rect(sx, sy, 16, 16, 0, 1)
          line(sx + 2, sy + 5, sx + 13, sy + 5, 13, 1, 0.5)
        else
          disco = ((x + y + parity) % 2 == 0)
          base_c = disco ? (@groove >= 4 ? 2 : 1) : 0
          rectfill(sx, sy, 16, 16, base_c, 0.85)
          if disco && @groove >= 2
            rectfill(sx + 2, sy + 2, 12, 12, @boss_floor ? 8 : 13, 0.14 + pulse * 0.22)
          end
          rect(sx, sy, 16, 16, 1, 1, 0.45)
        end
        x += 1
      end
      y += 1
    end

    # Stairs
    stx = ox + @stairs[0] * ts
    sty = oy + @stairs[1] * ts
    spr(:stairs, stx, sty)
    if @stairs_locked
      rect(stx + 1, sty + 1, 14, 14, 8, 1)
    end

    # Wall torches
    tf = (@tick / 8) % 2
    i = 0
    while i < @torches.size
      tc = @torches[i]
      spr(spr_id(:torch, tf), ox + tc[0] * ts, oy + tc[1] * ts - 2)
      i += 1
    end
  end

  def draw_entities(pulse)
    ox = @ox
    oy = @oy
    ts = @ts
    anim_f = (@beat_count) % 2

    # Items
    i = 0
    while i < @items.size
      it = @items[i]
      ix = ox + it[:x] * ts
      iy = oy + it[:y] * ts - (pulse * 2.0).to_i
      case it[:kind]
      when :chest
        spr(:chest, ix, iy)
      when :heart
        print_text("♥", ix + 8, iy + 4, 8, 8, 1.0, :center, 0)
      when :torch
        spr(spr_id(:torch, (@tick / 6) % 2), ix, iy)
      when :bomb
        circfill(ix + 8, iy + 9, 5, 0)
        circ(ix + 8, iy + 9, 5, 9)
        pset(ix + 11, iy + 3, 10)
      end
      i += 1
    end

    # Enemies
    i = 0
    while i < @foes.size
      f = @foes[i]
      fx = ox + f[:x] * ts
      fy = oy + f[:y] * ts - f[:hop].to_i

      # Warn flash when enemy will move on the very next beat!
      if f[:cd] == 1
        blend(:add)
        circfill(fx + 8, fy + 10, 8, 8, 0.18 + pulse * 0.25)
        blend(:normal)
      end

      if f[:kind] == :boss
        spr(spr_id(:conductor, anim_f), fx - 8, fy - 12, f[:flip])
        # Boss HP bar
        bw = 30
        fill_w = ((f[:hp].to_f / f[:max_hp]) * bw).to_i.clamp(0, bw)
        rectfill(fx - 7, fy - 16, bw, 3, 0)
        rectfill(fx - 7, fy - 16, fill_w, 3, 8)
      else
        spr(spr_id(f[:spr], anim_f), fx, fy - 2, f[:flip])
        if f[:hp] < f[:max_hp]
          hw = ((f[:hp].to_f / f[:max_hp]) * 12).to_i.clamp(1, 12)
          rectfill(fx + 2, fy - 4, 12, 2, 0)
          rectfill(fx + 2, fy - 4, hw, 2, 8)
        end
      end
      i += 1
    end

    # Player
    if @p_inv == 0 || (@tick % 4 < 2)
      px = ox + @px * ts
      py = oy + @py * ts - @p_hop.to_i - 2
      if @groove >= 4
        blend(:add)
        circfill(px + 8, py + 10, 9 + (pulse * 3).to_i, 10, 0.28)
        blend(:normal)
      end
      spr(spr_id(:hero, anim_f), px, py, @p_flip)
    end
  end

  def draw_lightmap(pulse)
    ox = @ox
    oy = @oy
    ts = @ts
    px = ox + @px * ts + 8
    py = oy + @py * ts + 8
    pr = $cfg[:torch_base_r] + @torch_bonus + @groove * 3 + (pulse * $cfg[:torch_beat_r]).to_i

    render_to(@lightmap) do
      cls(0, @boss_floor ? 0.72 : 0.84)
      blend(:erase)
      circfill(px, py, pr, 0, 1.0)

      # Wall torches punch crisp holes
      tr = $cfg[:wall_torch_r] + (pulse * 6).to_i
      i = 0
      while i < @torches.size
        tc = @torches[i]
        tx = ox + tc[0] * ts + 8
        ty = oy + tc[1] * ts + 8
        circfill(tx, ty, tr, 0, 1.0)
        i += 1
      end

      # Stairs glow
      sx = ox + @stairs[0] * ts + 8
      sy = oy + @stairs[1] * ts + 8
      circfill(sx, sy, 26, 0, 1.0)
      blend(:normal)
    end

    draw_surface(@lightmap, 0, 0)

    # Warm additive torchlight & groove aura
    blend(:add)
    circfill(px, py, (pr * 0.75).to_i, @groove >= 4 ? 10 : 9, 0.08 + pulse * 0.05)
    circfill(px, py, (pr * 0.42).to_i, @groove >= 4 ? 10 : 9, 0.12 + pulse * 0.06)
    i = 0
    while i < @torches.size
      tc = @torches[i]
      tx = ox + tc[0] * ts + 8
      ty = oy + tc[1] * ts + 6
      circfill(tx, ty, 28 + (pulse * 5).to_i, 9, 0.09)
      circfill(tx, ty, 14 + (pulse * 3).to_i, 10, 0.16)
      i += 1
    end
    blend(:normal)
  end

  def draw_world_fx
    ox = @ox
    oy = @oy
    ts = @ts

    blend(:add)
    i = 0
    while i < @slashes.size
      s = @slashes[i]
      sx = ox + s[:x] * ts
      sy = oy + s[:y] * ts
      al = s[:t] / 10.0
      rectfill(sx + 1, sy + 1, 14, 14, s[:col], al * 0.55)
      line(sx + 2, sy + 14, sx + 14, sy + 2, 7, 2, al)
      i += 1
    end

    i = 0
    while i < @particles.size
      pt = @particles[i]
      circfill(pt[:x], pt[:y], 2, pt[:col], (pt[:t] / 24.0).clamp(0.1, 1.0))
      i += 1
    end
    blend(:normal)

    i = 0
    while i < @popups.size
      p = @popups[i]
      print_text(p[:txt], p[:x], p[:y], p[:col], 8, (p[:t] / 20.0).clamp(0.2, 1.0), :center, 0)
      i += 1
    end
  end

  def draw_hud(pulse, beat_phase)
    # Top HUD bar
    rectfill(0, 0, @w, 18, 0, 0.85)
    line(0, 18, @w, 18, 13, 1)

    # Hearts
    h_str = ""
    i = 0
    while i < @max_hp
      h_str += (i < @hp ? "♥" : "·")
      i += 1
    end
    print_text(h_str, 6, 5, 8, 8, 1.0, :left, 0)

    fl_txt = @boss_floor ? "B5F BOSS" : "B#{@floor}F/#{$cfg[:max_floors]}"
    print_text(fl_txt, 82, 5, 10, 8, 1.0, :left, 0)

    mult = 1 + (@groove / 4)
    g_col = @groove >= 4 ? 10 : 7
    print_text("GROOVE:#{@groove}(x#{mult})", 152, 5, g_col, 8, 1.0, :left, 0)
    print_text("BOMB:#{@bombs} #{(@run_gold)}G", 314, 5, 11, 8, 1.0, :right, 0)

    # Bottom Rhythm Beat Bar!
    by = 204
    rectfill(0, by, @w, 36, 0, 0.88)
    line(0, by, @w, by, @groove >= 4 ? 10 : 13, 1)

    # Hit zone box around x=160
    win_w = (($cfg[:window_good].to_f / @beat_len) * 64).to_i
    rectfill(160 - win_w, by + 6, win_w * 2, 16, 2, 0.65)
    rect(160 - win_w, by + 6, win_w * 2, 16, 14, 1)

    # Approaching beat markers from left and right converging on 160
    blend(:add)
    k = 0
    while k < 3
      off = ((k.to_f + 1.0 - beat_phase) * 52.0).to_i
      al = (1.0 - k * 0.28).clamp(0.25, 1.0)
      line(160 - off, by + 7, 160 - off, by + 21, 12, 2, al)
      line(160 + off, by + 7, 160 + off, by + 21, 12, 2, al)
      k += 1
    end

    # Central pulsing Beat Heart
    hr = 5 + (pulse * 4.0).to_i
    circfill(160, by + 14, hr, @groove >= 4 ? 10 : 8, 0.85)
    blend(:normal)
    print_text("♥", 160, by + 10, 7, 8, 1.0, :center, 0)

    print_text(@weapon[:name], 8, by + 25, @weapon[:col], 8, 1.0, :left, 0)
    print_text("SCORE #{@score}", 312, by + 25, 7, 8, 1.0, :right, 0)
  end

  def draw_overlay
    rectfill(44, 62, 232, 108, 0, 0.92)
    b_col = (@state == :win) ? 10 : 8
    rect(44, 62, 232, 108, b_col, 2)

    title = (@state == :win) ? "CRYPT CONQUERED!" : "LOST THE RHYTHM..."
    print_text(title, 160, 74, b_col, 16, 1.0, :center, 0)
    print_text("FLOOR REACHED: B#{@floor}F   MAX GROOVE: #{@max_groove}", 160, 102, 7, 8, 1.0, :center, 0)
    print_text("GOLD LOOTED: +#{@run_gold}G   SCORE: #{@score}", 160, 118, 10, 8, 1.0, :center, 0)
    print_text("PRESS Z OR X TO RETURN TO TITLE", 160, 144, 11, 8, 1.0, :center, 0)
  end
end

run TitleScene.new
__END__
@PALETTE 1
1: #181028
2: #6E1E52
4: #A85834
5: #4A4466
6: #B8C0D8
7: #FFF8F0
8: #FF2458
9: #FF9820
A: #FFE840
B: #30E870
C: #38B8FF
D: #8E64D8
E: #FF70B8
F: #FFD0A8

@SPRITE :hero 16x16 pal:1
....11111111....
...1AA9999AA1...
..1AA7AAAA99A1..
..1FFFFFFFFF1...
..1F1FF7FF1F1...
..1FFFFEFFFF1...
...1188888811...
..1888AAAA8881..
.1881CCCCCC1881.
.1F11CC77CC11F1.
..1..1CCCC1..1..
....14411441....
....14411441....
...1155115511...
................
................
---
....11111111....
...1AA9999AA1...
..1AA7AAAA99A1..
..1FFFFFFFFF1...
..1F1FF7FF1F1...
..1FFFFEFFFF1...
..1888AAAA8881..
.1881CCCCCC1881.
.1F11CC77CC11F1.
..1..1CCCC1..1..
...1144114411...
..1551....1551..
..111......111..
................
................
................

@SPRITE :slime 16x16 pal:1
................
................
.....111111.....
...11BBBBBB11...
..1BB77BBBBBB1..
.1BB77BBBBBBBB1.
.1BBB1BBBB1BBB1.
.1BBB1BBBB1BBB1.
1BBBBBB88BBBBBB1
1BBBBBBBBBBBBBB1
1BBBBBBBB333BBB1
.13333333333331.
..111111111111..
................
................
................
---
................
...1111111111...
..1BBBBBBBBBB1..
.1BB77BBBBBBBB1.
.1B77BBBBBBBBB1.
.1BBB1BBBB1BBB1.
.1BBB1BBBB1BBB1.
..1BBBB88BBBB1..
..1BBBBBBBBBB1..
...1333333331...
....11111111....
................
................
................
................
................

@SPRITE :bat 16x16 pal:1
.11..........11.
1DD1..1111..1DD1
1DDD11DDDD11DDD1
1DDDDDDDDDDDDDD1
1DD11D8DD8D11DD1
.11..1DDDD1..11.
.....1D77D1.....
......1111......
................
................
................
................
................
................
................
................
---
................
......1111......
.....1DDDD1.....
....1D8DD8D1....
...11DDDDDD11...
..1DDD7DD7DDD1..
.1DDD111111DDD1.
1DD11......11DD1
111..........111
................
................
................
................
................
................
................

@SPRITE :skeleton 16x16 pal:1
....11111111....
...1777777771...
..177777777661..
..171177771161..
..178171178161..
...1777777761...
....17177161....
...1166666611...
..171616616161..
..11.166661.11..
.....171161.....
....171..161....
....171..161....
...1161..1611...
................
................
---
................
....11111111....
...1777777771...
..177777777661..
..171177771161..
..178171178161..
...1777777761...
..171166661161..
..11.161161.11..
.....166661.....
....171..161....
...171....161...
...111....111...
................
................
................

@SPRITE :reaper 16x16 pal:1
.....111111.....
...1122222211...
..122DDDDDD221..
.122D111111D221.
.12D11A11A11D21.
.12D11111111D21.
..12DDDDDDDD21..
.122DDDDDDDD221.
122D22DDDD22D221
12112DDDDDD21121
.1..12DDDD21..1.
....122DD221....
...1221111221...
....11....11....
................
................
---
....11111111....
..112222222211..
.122DDDDDDDD221.
.12D11111111D21.
.12D11A11A11D21.
..12D111111D21..
.122DDDDDDDD221.
122D22DDDD22D221
121.12DDDD21.121
....122DD221....
...1221..1221...
....11....11....
................
................
................
................

@SPRITE :conductor 32x32 pal:1
..........111111111111..........
........112222AAAA222211........
.......12222AA7777AA22221.......
......122222AAAAAAAA222221......
.....1111111111111111111111.....
....1AA999999999999999999AA1....
.....1111777777777777771111.....
.......177777777777777661.......
......17711177777777111661......
......17718817711771881661......
......17718717711771871661......
.......177777777777777661.......
........1771771771771661........
......11222211111111222211......
....1122888222AAAA2228882211....
...1228888222AA77AA2228888221...
..1228822222DDDDDDDD2222288221..
.12222221122DDDDDDDD22112222221.
.1771111..12DDDDDDDD21..1111771.
177A1.....122DDDDDD221.....1A771
.11A1.....1222DDDD2221.....1A11.
..1A1....122222DD222221....1A1..
..171....12222222222221....171..
..171...1222211221122221...171..
...1....12221..11..12221....1...
........1221........1221........
.........11..........11.........
................................
................................
................................
................................
................................
---
................................
..........111111111111..........
........112222AAAA222211........
.......12222AA7777AA22221.......
......122222AAAAAAAA222221......
.....1111111111111111111111.....
....1AA999999999999999999AA1....
.....1111777777777777771111.....
.......177777777777777661.......
......17711177777777111661......
......1771AA17711771AA1661......
......17718717711771871661......
.......177777777777777661.......
..171...1771771771771661...171..
..171.11222211111111222211.171..
..1A1122888222AAAA2228882211A1..
.11A122888222AA77AA222888221A11.
177A12222222DDDDDDDD22222221A771
.1771.....12DDDDDDDD21.....1771.
..11......122DDDDDD221......11..
..........1222DDDD2221..........
.........122222DD222221.........
.........12222222222221.........
........1222211221122221........
........12221..11..12221........
.........111........111.........
................................
................................
................................
................................
................................
................................

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

@SPRITE :chest 16x16 pal:1
................
................
..111111111111..
.19999999999991.
19AAAA9999AAAA91
144444AAAA444441
111111A77A111111
144444AAAA444441
1499441111449941
1499444444449941
1444444444444441
.11111111111111.
................
................
................
................

@SPRITE :stairs 16x16 pal:1
1111111111111111
1555555555555551
1566666666666651
1511111111111651
1515555555551651
1515666666651651
1515111111651651
1515100001651651
151510CC01651651
151510CC01651651
1515100001651651
1515555555551651
1511111111111651
1566666666666651
1555555555555551
1111111111111111

@SFX :beat_ok
wave:triangle freq:330->660 dur:0.07 env:decay vol:0.55

@SFX :kick_pulse
wave:triangle freq:130->48 dur:0.08 env:decay vol:0.65

@MUSIC :title_bgm
ch0 wave=pulse vol=4 T120 L8 O4 e r g a b r a g  f# r a b > d r < b a  e r g a b r > e d  c < b a g f#4 r4
ch1 wave=tri vol=5 T120 L4 O3 e e b b  d d a a  c c g g  b b f#2
ch2 wave=noise vol=2 T120 L8 O6 c r c r c r c c  c r c r c r c c  c r c r c r c c  c r c r c c c r

@MUSIC :crypt_bgm
ch0 wave=square vol=4 T120 L8 O4 e g b > e < b g e g  d f# a > d < a f# d f#  c e g > c < g e c e  < b > d# f# b > d# < b f# d#
ch1 wave=tri vol=6 T120 L4 O2 e e e e  d d d d  c c c c  b b b b
ch2 wave=noise vol=3 T120 L8 O6 c r c c c r c r  c r c c c r c c  c r c c c r c r  c r c c c c c c

@MUSIC :boss_bgm
ch0 wave=saw vol=4 T150 L8 O4 e e > e < b > c < b g e  f f > f c d c < a f  e e > e < b > c d e f  f#4 g4 a4 b4
ch1 wave=tri vol=6 T150 L8 O2 e r e e r e g e  f r f f r f a f  e r e e r e g e  d# d# e e f# f# g# g#
ch2 wave=noise vol=3 T150 L8 O6 c c r c c r c c  c c r c c r c c  c c r c c r c c  c c c c c c c c
