config(
  title: "CRATER ARTILLERY",
  width: 480,
  height: 270,
  save_id: "crater_artillery",
  save_salt: "p3g41a9c"
)

$cfg = {
  w: 480,
  h: 270,
  gravity: 0.14,
  wind_max: 0.045,
  tank_speed: 1.1,
  tank_hp: 100,
  fuel_max: 70,
  power_min: 2.0,
  power_max: 9.5,
  power_step: 0.12,
  aim_step: 2.0,
  turn_time: 900,
  shake_max: 8.0,
  hitstop_frames: 4,
  preview_steps: 18
}

$weapons = {
  shell: { name: "HE SHELL", col: 10, rad: 18, dmg: 34, ammo: 99, speed_mul: 1.0, count: 1, drill: 0 },
  cluster: { name: "CLUSTER", col: 11, rad: 12, dmg: 18, ammo: 3, speed_mul: 1.0, count: 5, drill: 0 },
  drill: { name: "BUNKER", col: 9, rad: 22, dmg: 42, ammo: 2, speed_mul: 1.1, count: 1, drill: 18 },
  nuke: { name: "MEGA BOMB", col: 8, rad: 34, dmg: 60, ammo: 1, speed_mul: 0.9, count: 1, drill: 0 }
}

$weapon_order = [:shell, :cluster, :drill, :nuke]

$stages = [
  { name: "GREEN HILLS", bg: :sky, dim: 0.45, tint: "#B8D8FF", top_col: 11, mid_col: 3, bot_col: 4, cpu_hp: 80, cpu_acc: 0.22, amp: 28, freq: 0.018, base_y: 175 },
  { name: "SUNSET CANYON", bg: :mountain, dim: 0.45, tint: "#FFB078", top_col: 9, mid_col: 4, bot_col: 2, cpu_hp: 95, cpu_acc: 0.18, amp: 38, freq: 0.025, base_y: 170 },
  { name: "FROST PEAKS", bg: :mountain, dim: 0.40, tint: "#A0E8FF", top_col: 7, mid_col: 12, bot_col: 1, cpu_hp: 110, cpu_acc: 0.15, amp: 44, freq: 0.030, base_y: 172 },
  { name: "DEEP CAVERN", bg: :cave, dim: 0.42, tint: "#C090FF", top_col: 13, mid_col: 5, bot_col: 1, cpu_hp: 120, cpu_acc: 0.12, amp: 34, freq: 0.036, base_y: 168 },
  { name: "NEON METRO", bg: :city, dim: 0.45, tint: "#80C0FF", top_col: 6, mid_col: 5, bot_col: 1, cpu_hp: 130, cpu_acc: 0.10, amp: 42, freq: 0.022, base_y: 165 },
  { name: "TOXIC MARSH", bg: :forest, dim: 0.48, tint: "#88FF90", top_col: 11, mid_col: 3, bot_col: 5, cpu_hp: 140, cpu_acc: 0.08, amp: 32, freq: 0.042, base_y: 175 },
  { name: "CYBER GRID", bg: :cyber, dim: 0.45, tint: "#FF80E0", top_col: 14, mid_col: 2, bot_col: 1, cpu_hp: 155, cpu_acc: 0.06, amp: 46, freq: 0.028, base_y: 168 },
  { name: "ORBITAL CORE", bg: :space, dim: 0.35, tint: "#FFE090", top_col: 10, mid_col: 9, bot_col: 5, cpu_hp: 180, cpu_acc: 0.04, amp: 50, freq: 0.032, base_y: 164 }
]

class Tank
  attr_accessor :x, :y, :vx, :vy, :hp, :max_hp
  attr_accessor :angle, :power, :fuel, :player_idx, :is_cpu
  attr_accessor :ammo, :wep_idx, :facing, :flash_t, :alive

  def initialize(opts)
    @x = opts[:x]
    @y = opts[:y]
    @vx = 0.0
    @vy = 0.0
    @hp = opts[:hp]
    @max_hp = opts[:hp]
    @player_idx = opts[:player_idx]
    @is_cpu = opts[:is_cpu]
    @facing = opts[:facing]
    @angle = @facing > 0 ? -45.0 : -135.0
    @power = 5.6
    @fuel = $cfg[:fuel_max]
    @wep_idx = 0
    @ammo = { shell: 99, cluster: 3, drill: 2, nuke: 1 }
    @flash_t = 0
    @alive = true
  end

  def current_weapon
    $weapon_order[@wep_idx]
  end

  def cycle_weapon(dir)
    n = $weapon_order.size
    steps = 0
    while steps < n
      @wep_idx = (@wep_idx + dir + n) % n
      w = $weapon_order[@wep_idx]
      return if @ammo[w] > 0
      steps += 1
    end
  end
end

class TitleScene
  def initialize
    @mode = 0
    @stage_sel = 0
    @unlocked = save_get("unlocked_stage", 0).to_i
    @unlocked = 0 if @unlocked < 0
    @unlocked = $stages.size - 1 if @unlocked >= $stages.size
    @total_wins = save_get("total_wins", 0).to_i
    @tick = 0
    @demo_t = 0
  end

  def update
    @tick += 1
    if btnp(2) || btnp(3)
      @mode = 1 - @mode
    end
    if @mode == 0
      if btnp(0)
        @stage_sel = (@stage_sel - 1 + @unlocked + 1) % (@unlocked + 1)
      elsif btnp(1)
        @stage_sel = (@stage_sel + 1) % (@unlocked + 1)
      end
    end

    # Mouse selection
    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if mx >= 120 && mx <= 360
        if my >= 134 && my <= 162
          @mode = 0
          start_game
          return
        elsif my >= 170 && my <= 198
          @mode = 1
          start_game
          return
        end
      end
    end

    if btnp(4) || btnp(5)
      start_game
    end
  end

  def start_game
    if @mode == 0
      run BattleScene.new({ mode: :campaign, stage_idx: @stage_sel })
    else
      run BattleScene.new({ mode: :duel, stage_idx: rand($stages.size) })
    end
  end

  def draw
    cls(0)
    bg(:mountain, dim: 0.45, tint: "#FF9866", scroll_x: @tick * 0.25, mirror_x: true)

    # Decorative ground & tanks
    rectfill(0, 215, 480, 55, 1)
    spr(:tank_p1, 72, 199, false)
    spr(:tank_p2, 392, 199, true)

    # Title banner
    bob = sin(@tick * 0.06) * 3
    print_text("CRATER ARTILLERY", 240, 34 + bob, 10, 16, 1.0, :center, 0, 2)
    print_text("PIXEL DESTRUCTION BATTLE", 240, 60 + bob, 7, 8, 1.0, :center, 0)

    # Save summary
    print_text("UNLOCKED: STAGES #{@unlocked + 1}/#{$stages.size}   WINS: #{@total_wins}", 240, 86, 12, 8, 1.0, :center, 0)

    # Mode buttons
    c0 = @mode == 0 ? 10 : 6
    b0 = @mode == 0 ? 1 : 0
    rectfill(120, 134, 240, 28, b0, 0.85)
    rect(120, 134, 240, 28, c0, 2)
    st_name = $stages[@stage_sel][:name]
    print_text("1P CAMPAIGN (STAGE #{@stage_sel + 1}: #{st_name})", 240, 144, c0, 8, 1.0, :center, 0)

    c1 = @mode == 1 ? 10 : 6
    b1 = @mode == 1 ? 1 : 0
    rectfill(120, 170, 240, 28, b1, 0.85)
    rect(120, 170, 240, 28, c1, 2)
    print_text("2P LOCAL DUEL (P1 vs P2 / PAD)", 240, 180, c1, 8, 1.0, :center, 0)

    print_text("ARROWS/WASD: MOVE & AIM | Z/SPACE: HOLD FIRE | WHEEL/X: WEAPON", 240, 232, 7, 8, 1.0, :center, 0)
    print_text("2P: IJKL + U/O OR GAMEPAD 2 | CLICK TO AIM & FIRE", 240, 246, 15, 8, 1.0, :center, 0)
  end
end

class BattleScene
  def initialize(opts)
    @mode = opts[:mode]
    @stage_idx = opts[:stage_idx]
    @stage = $stages[@stage_idx]
    @w = $cfg[:w]
    @h = $cfg[:h]

    @terrain = create_surface(@w, @h, :pixel)
    generate_terrain

    y1 = find_ground_y(72)
    y2 = find_ground_y(408)
    @tanks = [
      Tank.new({ x: 72.0, y: y1 - 8.0, hp: $cfg[:tank_hp], player_idx: 0, is_cpu: false, facing: 1 }),
      Tank.new({ x: 408.0, y: y2 - 8.0, hp: @mode == :campaign ? @stage[:cpu_hp] : $cfg[:tank_hp], player_idx: 1, is_cpu: @mode == :campaign, facing: -1 })
    ]

    @turn = 0
    @phase = :aim # :aim, :charging, :flying, :cpu_think, :win
    @wind = (rand() * 2.0 - 1.0) * $cfg[:wind_max]
    @projectiles = []
    @particles = []
    @popups = []
    @shake = 0.0
    @hitstop = 0
    @turn_timer = $cfg[:turn_time]
    @cpu_wait = 0
    @cpu_target_ang = -135.0
    @cpu_target_pow = 5.5
    @winner = nil
    @tick = 0
    @flash_alpha = 0.0
    @saved_win = false
  end

  def generate_terrain
    clear_surface(@terrain, nil)
    amp = @stage[:amp]
    freq = @stage[:freq]
    base_y = @stage[:base_y]
    top_col = @stage[:top_col]
    mid_col = @stage[:mid_col]
    bot_col = @stage[:bot_col]
    phase = rand() * 6.28
    h = @h
    w = @w
    surf = @terrain

    render_to(surf) do
      x = 0
      while x < w
        # Smooth multi-sine terrain + flat spawn pads
        ny = base_y + sin(x * freq + phase) * amp + cos(x * freq * 2.1 + 1.0) * (amp * 0.35)
        if x < 96
          t = (x - 60).abs / 36.0
          t = 1.0 if t > 1.0
          ny = ny * t + (base_y - 10) * (1.0 - t)
        elsif x > 384
          t = (x - 420).abs / 36.0
          t = 1.0 if t > 1.0
          ny = ny * t + (base_y - 10) * (1.0 - t)
        end
        sy = ny.to_i
        sy = 90 if sy < 90
        sy = h - 24 if sy > h - 24

        line(x, sy, x, sy + 3, top_col)
        line(x, sy + 4, x, sy + 24, mid_col)
        line(x, sy + 25, x, h - 1, bot_col)
        x += 1
      end
    end
  end

  def find_ground_y(px)
    hit = surface_raycast(@terrain, px.to_i, 0, px.to_i, @h - 1)
    return hit[1].to_f if hit
    (@h - 10).to_f
  end

  def update
    @tick += 1
    if @hitstop > 0
      @hitstop -= 1
      return
    end
    @shake *= 0.85
    @shake = 0.0 if @shake < 0.2
    @flash_alpha *= 0.82

    update_particles
    update_popups
    update_tanks_physics

    if @phase == :win
      if btnp(4) || btnp(5) || btnp(:mouse_l)
        if @mode == :campaign && @winner == 0 && @stage_idx + 1 < $stages.size
          run BattleScene.new({ mode: :campaign, stage_idx: @stage_idx + 1 })
        else
          run TitleScene.new
        end
      end
      return
    end

    if @phase == :aim || @phase == :charging
      handle_player_turn
    elsif @phase == :cpu_think
      handle_cpu_turn
    elsif @phase == :flying
      update_projectiles
    end
  end

  def update_tanks_physics
    grav = $cfg[:gravity]
    surf = @terrain
    h = @h
    @tanks.each do |tk|
      next unless tk.alive
      tk.flash_t -= 1 if tk.flash_t > 0
      if !surface_solid?(surf, tk.x.to_i - 4, tk.y.to_i + 8, 9, 2)
        tk.vy += grav
        tk.y += tk.vy
        if surface_solid?(surf, tk.x.to_i - 4, tk.y.to_i + 8, 9, 2)
          while surface_solid?(surf, tk.x.to_i - 4, tk.y.to_i + 7, 9, 1) && tk.y > 10
            tk.y -= 1.0
          end
          tk.vy = 0.0
        end
      else
        tk.vy = 0.0
      end

      if tk.y > h + 10
        tk.hp = 0
        tk.alive = false
        check_win
      end
    end
  end

  def handle_player_turn
    tk = @tanks[@turn]
    p = tk.player_idx
    if tk.is_cpu
      @phase = :cpu_think
      @cpu_wait = 40
      plan_cpu_shot(tk)
      return
    end

    @turn_timer -= 1
    if @turn_timer <= 0
      fire_weapon(tk)
      return
    end

    # Weapon cycle via wheel or B button
    wh = mouse_wheel
    if wh > 0.0
      tk.cycle_weapon(-1)
    elsif wh < 0.0
      tk.cycle_weapon(1)
    end
    if btnp(5, p)
      tk.cycle_weapon(1)
    end

    if @phase == :aim
      # Movement
      spd = $cfg[:tank_speed]
      if btn(0, p) && tk.fuel > 0 && tk.x > 14
        move_tank(tk, -spd)
        tk.facing = -1
      elsif btn(1, p) && tk.fuel > 0 && tk.x < @w - 14
        move_tank(tk, spd)
        tk.facing = 1
      end

      # Aiming via keys
      astep = $cfg[:aim_step]
      if btn(2, p)
        tk.angle -= astep
      elsif btn(3, p)
        tk.angle += astep
      end
      tk.angle = -175.0 if tk.angle < -175.0
      tk.angle = -5.0 if tk.angle > -5.0

      # Mouse aiming for P1 (or P2 in 2P mode if mouse clicked)
      if p == 0 || @mode == :duel
        if btn(:mouse_l)
          dx = mouse_x - tk.x
          dy = mouse_y - tk.y
          if dx.abs > 2 || dy.abs > 2
            ang = atan2(dy, dx) * 180.0 / Math::PI
            ang = -175.0 if ang < -175.0 && ang > -180.0
            ang = -5.0 if ang > -5.0
            tk.angle = ang
            dist = sqrt(dx * dx + dy * dy)
            pw = (dist / 22.0).clamp($cfg[:power_min], $cfg[:power_max])
            tk.power = pw
            tk.facing = dx >= 0 ? 1 : -1
          end
        end
        if btnp(:mouse_r)
          tk.cycle_weapon(1)
        end
      end

      if btnp(4, p)
        @phase = :charging
        tk.power = $cfg[:power_min]
      elsif btnp(:mouse_l) && mouse_y > 30
        fire_weapon(tk)
      end
    elsif @phase == :charging
      tk.power += $cfg[:power_step]
      if tk.power >= $cfg[:power_max] || !btn(4, p)
        tk.power = $cfg[:power_max] if tk.power > $cfg[:power_max]
        fire_weapon(tk)
      end
    end
  end

  def move_tank(tk, dx)
    nx = tk.x + dx
    return if nx < 12 || nx > @w - 12
    # Check slope climb up to 4px
    step = 0
    while step <= 4
      if !surface_solid?(@terrain, nx.to_i - 4, tk.y.to_i + 7 - step, 9, 1)
        tk.x = nx
        tk.y -= step.to_f
        tk.fuel -= 1
        return
      end
      step += 1
    end
  end

  def plan_cpu_shot(tk)
    target = @tanks[0]
    dx = target.x - tk.x
    dy = target.y - tk.y
    tk.facing = dx >= 0 ? 1 : -1

    # Estimate ballistic angle & power
    best_ang = dx < 0 ? -135.0 : -45.0
    best_pow = 5.5
    best_err = 9999.0
    grav = $cfg[:gravity]
    wind = @wind

    cand_ang = dx < 0 ? -150.0 : -70.0
    end_ang = dx < 0 ? -110.0 : -30.0
    while cand_ang <= end_ang
      rad = cand_ang * Math::PI / 180.0
      cp = 3.5
      while cp <= 9.0
        px = tk.x
        py = tk.y - 4.0
        pvx = cos(rad) * cp
        pvy = sin(rad) * cp
        s = 0
        while s < 140
          pvx += wind
          pvy += grav
          px += pvx
          py += pvy
          if py >= target.y - 4 && (px - target.x).abs < 24
            err = (px - target.x).abs + (py - target.y).abs
            if err < best_err
              best_err = err
              best_ang = cand_ang
              best_pow = cp
            end
            break
          end
          break if py > @h
          s += 1
        end
        cp += 0.5
      end
      cand_ang += 8.0
    end

    acc = @stage[:cpu_acc]
    @cpu_target_ang = best_ang + (rand() * 2.0 - 1.0) * (acc * 35.0)
    @cpu_target_pow = (best_pow + (rand() * 2.0 - 1.0) * (acc * 2.2)).clamp($cfg[:power_min], $cfg[:power_max])

    # Choose weapon smartly
    if tk.ammo[:nuke] > 0 && rand() < 0.25
      tk.wep_idx = 3
    elsif tk.ammo[:cluster] > 0 && rand() < 0.4
      tk.wep_idx = 1
    else
      tk.wep_idx = 0
    end
  end

  def handle_cpu_turn
    tk = @tanks[@turn]
    @cpu_wait -= 1
    tk.angle += (@cpu_target_ang - tk.angle) * 0.12
    tk.power += (@cpu_target_pow - tk.power) * 0.12
    if @cpu_wait <= 0
      tk.angle = @cpu_target_ang
      tk.power = @cpu_target_pow
      fire_weapon(tk)
    end
  end

  def fire_weapon(tk)
    w_sym = tk.current_weapon
    w_spec = $weapons[w_sym]
    if tk.ammo[w_sym] > 0 && w_sym != :shell
      tk.ammo[w_sym] -= 1
    end
    rad = tk.angle * Math::PI / 180.0
    spd = tk.power * w_spec[:speed_mul]
    vx = cos(rad) * spd
    vy = sin(rad) * spd
    sx = tk.x + cos(rad) * 10.0
    sy = tk.y - 2.0 + sin(rad) * 10.0

    @projectiles << {
      x: sx, y: sy, vx: vx, vy: vy,
      wep: w_sym, owner: @turn,
      split_done: false, drill_left: w_spec[:drill],
      trail: []
    }
    @phase = :flying
    @shake = 2.0
    spawn_sparks(sx, sy, 6, 10)
    tk.cycle_weapon(0) if tk.ammo[w_sym] <= 0
  end

  def update_projectiles
    grav = $cfg[:gravity]
    wind = @wind
    surf = @terrain
    w = @w
    h = @h

    i = @projectiles.size - 1
    while i >= 0
      pr = @projectiles[i]
      pr[:trail] << [pr[:x], pr[:y]]
      pr[:trail].shift if pr[:trail].size > 14

      prev_x = pr[:x]
      prev_y = pr[:y]
      pr[:vx] += wind
      pr[:vy] += grav
      pr[:x] += pr[:vx]
      pr[:y] += pr[:vy]

      # Cluster split near apex or falling
      if pr[:wep] == :cluster && !pr[:split_done] && pr[:vy] > 0.4
        pr[:split_done] = true
        k = -2
        while k <= 2
          @projectiles << {
            x: pr[:x], y: pr[:y],
            vx: pr[:vx] + k * 0.55, vy: pr[:vy] - 0.3,
            wep: :cluster_sub, owner: pr[:owner],
            split_done: true, drill_left: 0, trail: []
          }
          k += 1
        end
        spawn_sparks(pr[:x], pr[:y], 8, 11)
        @projectiles.delete_at(i)
        i -= 1
        next
      end

      # Out of bounds
      if pr[:x] < -20 || pr[:x] > w + 20 || pr[:y] > h + 20
        @projectiles.delete_at(i)
        i -= 1
        next
      end

      # Check tank direct hit
      hit_tank = false
      @tanks.each do |tk|
        next unless tk.alive
        dx = pr[:x] - tk.x
        dy = pr[:y] - tk.y
        if dx * dx + dy * dy <= 81.0
          explode(pr[:x], pr[:y], pr[:wep])
          hit_tank = true
          break
        end
      end
      if hit_tank
        @projectiles.delete_at(i)
        i -= 1
        next
      end

      # Check terrain raycast
      if pr[:y] >= 0
        ray = surface_raycast(surf, prev_x.to_i, prev_y.to_i, pr[:x].to_i, pr[:y].to_i)
        if ray
          hx = ray[0].to_f
          hy = ray[1].to_f
          if pr[:drill_left] > 0
            pr[:drill_left] -= 1
            carve_crater(hx, hy, 5)
            spawn_sparks(hx, hy, 3, 9)
          else
            explode(hx, hy, pr[:wep])
            @projectiles.delete_at(i)
            i -= 1
            next
          end
        end
      end

      i -= 1
    end

    if @projectiles.empty? && @phase == :flying
      next_turn
    end
  end

  def carve_crater(ex, ey, rad)
    render_to(@terrain) do
      blend(:erase)
      circfill(ex.to_i, ey.to_i, rad, 0)
      blend(:normal)
    end
  end

  def explode(ex, ey, wep_sym)
    spec = wep_sym == :cluster_sub ? $weapons[:cluster] : $weapons[wep_sym]
    rad = spec[:rad]
    dmg = spec[:dmg]

    carve_crater(ex, ey, rad)
    @shake = [rad * 0.35, $cfg[:shake_max]].min
    @hitstop = $cfg[:hitstop_frames]
    @flash_alpha = 0.35
    spawn_sparks(ex, ey, rad + 6, spec[:col])

    @tanks.each do |tk|
      next unless tk.alive
      dx = tk.x - ex
      dy = tk.y - ey
      dist = sqrt(dx * dx + dy * dy)
      if dist <= rad + 12.0
        falloff = 1.0 - (dist / (rad + 14.0))
        falloff = 0.25 if falloff < 0.25
        hit_dmg = (dmg * falloff).to_i
        hit_dmg = 1 if hit_dmg < 1
        tk.hp -= hit_dmg
        tk.flash_t = 10
        tk.vy = -2.2 * falloff
        @popups << { x: tk.x, y: tk.y - 14, text: "-#{hit_dmg}", col: 8, life: 45 }
        if tk.hp <= 0
          tk.hp = 0
          tk.alive = false
          spawn_sparks(tk.x, tk.y, 28, 9)
        end
      end
    end
    check_win
  end

  def check_win
    return if @phase == :win
    p0 = @tanks[0].alive
    p1 = @tanks[1].alive
    if !p0 || !p1
      @phase = :win
      @winner = p0 ? 0 : 1
      if @mode == :campaign && @winner == 0 && !@saved_win
        @saved_win = true
        wins = save_get("total_wins", 0).to_i + 1
        save_set("total_wins", wins)
        unlocked = save_get("unlocked_stage", 0).to_i
        next_st = @stage_idx + 1
        next_st = $stages.size - 1 if next_st >= $stages.size
        save_set("unlocked_stage", next_st) if next_st > unlocked
      end
    end
  end

  def next_turn
    return if @phase == :win
    @turn = 1 - @turn
    @tanks[@turn].fuel = $cfg[:fuel_max]
    @wind = (@wind + (rand() * 2.0 - 1.0) * 0.015).clamp(-$cfg[:wind_max], $cfg[:wind_max])
    @turn_timer = $cfg[:turn_time]
    @phase = :aim
  end

  def spawn_sparks(x, y, count, col)
    k = 0
    while k < count
      ang = rand() * 6.283
      spd = 0.8 + rand() * 3.2
      @particles << {
        x: x, y: y,
        vx: cos(ang) * spd, vy: sin(ang) * spd - 0.8,
        col: k % 3 == 0 ? 7 : col,
        life: 18 + rand(20), max_life: 38,
        size: 1 + rand(3)
      }
      k += 1
    end
  end

  def update_particles
    i = @particles.size - 1
    while i >= 0
      pt = @particles[i]
      pt[:x] += pt[:vx]
      pt[:y] += pt[:vy]
      pt[:vy] += 0.08
      pt[:life] -= 1
      @particles.delete_at(i) if pt[:life] <= 0
      i -= 1
    end
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
    sx = @shake > 0 ? (rand() * 2.0 - 1.0) * @shake : 0.0
    sy = @shake > 0 ? (rand() * 2.0 - 1.0) * @shake : 0.0

    bg(@stage[:bg], dim: @stage[:dim], tint: @stage[:tint], scale: 1.04, scroll_x: sx * 0.3, y: sy * 0.3, mirror_x: true, mirror_y: true)

    camera(sx, sy)
    draw_surface(@terrain, 0, 0)

    # Trajectory preview for active human tank
    active = @tanks[@turn]
    if (@phase == :aim || @phase == :charging) && !active.is_cpu
      draw_trajectory_preview(active)
    end

    # Tanks
    @tanks.each do |tk|
      next unless tk.alive
      spr_sym = tk.player_idx == 0 ? :tank_p1 : :tank_p2
      pal_id = tk.flash_t > 0 ? 2 : nil
      spr(spr_sym, tk.x - 8, tk.y - 8, tk.facing < 0, pal_id)

      # Turret barrel
      rad = tk.angle * Math::PI / 180.0
      bx = tk.x + cos(rad) * 11.0
      by = tk.y + 1.0 + sin(rad) * 11.0
      line(tk.x, tk.y + 1, bx, by, 7, 2)

      # Mini HP bar above tank
      hp_w = (20.0 * tk.hp / tk.max_hp).to_i
      rectfill(tk.x - 10, tk.y - 15, 20, 3, 0)
      rectfill(tk.x - 10, tk.y - 15, hp_w, 3, tk.player_idx == 0 ? 12 : 8)
    end

    # Projectiles
    @projectiles.each do |pr|
      tr = pr[:trail]
      if tr.size >= 2
        col = pr[:wep] == :nuke ? 8 : 10
        polyline(tr, col, 2, 0.65)
      end
      circfill(pr[:x], pr[:y], 3, 7)
    end

    # Additive particles
    blend(:add)
    @particles.each do |pt|
      a = pt[:life].to_f / pt[:max_life]
      circfill(pt[:x], pt[:y], pt[:size], pt[:col], a)
    end
    blend(:normal)

    # Floating damage numbers
    @popups.each do |pp|
      print_text(pp[:text], pp[:x], pp[:y], pp[:col], 8, 1.0, :center, 0)
    end

    camera()
    clip()
    blend(:normal)

    if @flash_alpha > 0.02
      rectfill(0, 0, @w, @h, 7, @flash_alpha)
    end

    draw_hud
  end

  def draw_trajectory_preview(tk)
    rad = tk.angle * Math::PI / 180.0
    w_spec = $weapons[tk.current_weapon]
    spd = tk.power * w_spec[:speed_mul]
    px = tk.x + cos(rad) * 10.0
    py = tk.y - 2.0 + sin(rad) * 10.0
    vx = cos(rad) * spd
    vy = sin(rad) * spd
    grav = $cfg[:gravity]
    wind = @wind
    steps = $cfg[:preview_steps]
    s = 0
    while s < steps
      vx += wind
      vy += grav
      px += vx
      py += vy
      if s % 2 == 0
        circfill(px, py, 1, 7, 0.7 - s * 0.03)
      end
      s += 1
    end
  end

  def draw_hud
    rectfill(0, 0, @w, 26, 0, 0.65)
    t0 = @tanks[0]
    t1 = @tanks[1]
    print_text("P1 HP:#{t0.hp}", 8, 5, 12, 8, 1.0, :left, 0)
    p2_label = @mode == :campaign ? "CPU" : "P2"
    print_text("#{p2_label} HP:#{t1.hp}", @w - 8, 5, 8, 8, 1.0, :right, 0)

    # Stage & Wind
    print_text("STG #{@stage_idx + 1}: #{@stage[:name]}", 240, 4, 7, 8, 1.0, :center, 0)
    wind_px = (@wind / $cfg[:wind_max] * 36.0).to_i
    rectfill(204, 15, 72, 5, 1)
    if wind_px >= 0
      rectfill(240, 15, wind_px, 5, 11)
    else
      rectfill(240 + wind_px, 15, -wind_px, 5, 14)
    end
    line(240, 14, 240, 21, 7)

    # Active weapon & power bar
    atk = @tanks[@turn]
    w_sym = atk.current_weapon
    w_spec = $weapons[w_sym]
    ammo_str = w_sym == :shell ? "INF" : "x#{atk.ammo[w_sym]}"
    turn_str = atk.is_cpu ? "CPU TURN" : "P#{atk.player_idx + 1} TURN"
    print_text("#{turn_str} | #{w_spec[:name]} (#{ammo_str})", 8, 16, w_spec[:col], 8, 1.0, :left, 0)

    # Power gauge
    pw_ratio = (atk.power - $cfg[:power_min]) / ($cfg[:power_max] - $cfg[:power_min])
    rectfill(350, 16, 120, 6, 1)
    rectfill(350, 16, (120 * pw_ratio).to_i, 6, @phase == :charging ? 10 : 12)
    rect(350, 16, 120, 6, 7)

    if @phase == :win
      rectfill(100, 88, 280, 86, 0, 0.88)
      rect(100, 88, 280, 86, 10, 2)
      msg = @winner == 0 ? "VICTORY!" : (@mode == :campaign ? "DEFEATED..." : "PLAYER 2 WINS!")
      print_text(msg, 240, 104, @winner == 0 ? 10 : 8, 16, 1.0, :center, 0)
      sub = (@mode == :campaign && @winner == 0 && @stage_idx + 1 < $stages.size) ? "PRESS Z / CLICK FOR NEXT STAGE" : "PRESS Z / CLICK FOR TITLE"
      print_text(sub, 240, 144, 7, 8, 1.0, :center, 0)
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #000000
1: #162038
2: #5A1E2E
5: #4A5468
6: #9BA4B8
7: #FFF1E8
8: #FF2E54
9: #FF8822
A: #FFEC27
C: #29ADFF

@PALETTE 2
7: #FFFFFF
C: #FFFFFF
8: #FFFFFF
9: #FFFFFF
1: #FFFFFF
5: #FFFFFF

@SPRITE :tank_p1 16x16 pal:1
................
................
................
................
................
.....111111.....
....1CCCCCC1....
....1C7CCCC1....
..1111CCCC1111..
.1CCCCCCCCCCCC1.
.11111111111111.
.15656565656561.
.16565656565651.
..111111111111..
................
................

@SPRITE :tank_p2 16x16 pal:1
................
................
................
................
................
.....111111.....
....18888881....
....18988881....
..111188881111..
.18888888888881.
.11111111111111.
.15656565656561.
.16565656565651.
..111111111111..
................
................
