config(
  title: "ABYSSAL DRILLER",
  width: 320,
  height: 240,
  save_id: "abyssal_driller",
  save_salt: "p3g49k3m"
)

$cfg = {
  w: 320,
  h: 240,
  world_h: 1160,
  ground_y: 64,
  core_y: 1100,
  gravity: 0.14,
  base_spd: 1.6,
  jet_power: 0.28,
  base_fuel: 120.0,
  base_light: 64.0,
  drill_r: 9
}

$ores = {
  copper: { name: "COPPER", col: 9, val: 15, min_y: 80, max_y: 500 },
  silver: { name: "SILVER", col: 6, val: 35, min_y: 220, max_y: 800 },
  gold: { name: "GOLD", col: 10, val: 75, min_y: 400, max_y: 1050 },
  ruby: { name: "RUBY", col: 8, val: 140, min_y: 650, max_y: 1120 },
  diamond: { name: "DIAMOND", col: 12, val: 260, min_y: 850, max_y: 1140 }
}

$upgrades = {
  drill: { name: "DRILL PWR", cost: 40, max_lv: 5 },
  tank: { name: "FUEL TANK", cost: 35, max_lv: 5 },
  light: { name: "HEADLIGHT", cost: 30, max_lv: 5 },
  jet: { name: "JETPACK", cost: 45, max_lv: 5 }
}

$upg_order = [:drill, :tank, :light, :jet]

class TitleScene
  def initialize
    @cash = save_get("cash", 0).to_i
    @best_m = save_get("best_m", 0).to_i
    @cores = save_get("cores", 0).to_i
    @upgs = save_get("upgs", { "drill" => 0, "tank" => 0, "light" => 0, "jet" => 0 })
    @sel = 0
    @tick = 0
  end

  def update
    @tick += 1
    @sel = (@sel - 1 + 5) % 5 if btnp(2)
    @sel = (@sel + 1) % 5 if btnp(3)

    if btnp(4) || btnp(5)
      if @sel == 0
        run DrillScene.new({ upgs: @upgs })
      else
        buy_upgrade($upg_order[@sel - 1])
      end
    end

    if btnp(:mouse_l)
      my = mouse_y
      if my >= 104 && my <= 128
        run DrillScene.new({ upgs: @upgs })
      elsif my >= 134 && my <= 214
        idx = ((my - 134) / 20).to_i
        if idx >= 0 && idx < 4
          @sel = idx + 1
          buy_upgrade($upg_order[idx])
        end
      end
    end
  end

  def buy_upgrade(k)
    ks = k.to_s
    lv = (@upgs[ks] || 0).to_i
    spec = $upgrades[k]
    return if lv >= spec[:max_lv]
    cost = spec[:cost] * (lv + 1)
    if @cash >= cost
      @cash -= cost
      @upgs[ks] = lv + 1
      save_set("cash", @cash)
      save_set("upgs", @upgs)
    end
  end

  def draw
    cls(0)
    bg(:cave, dim: 0.45, tint: "#705890", scroll_y: @tick * 0.2, mirror_y: true)
    spr(:driller, 152, 54)

    print_text("ABYSSAL DRILLER", 160, 18, 10, 16, 1.0, :center, 0, 2)
    print_text("MAX DEPTH: #{@best_m}m  CORES: #{@cores}  CASH: $#{@cash}", 160, 78, 12, 8, 1.0, :center, 0)

    c0 = @sel == 0 ? 10 : 7
    rectfill(60, 104, 200, 22, @sel == 0 ? 1 : 0, 0.85)
    rect(60, 104, 200, 22, c0, 2)
    print_text("LAUNCH DRILL POD (1000m)", 160, 111, c0, 8, 1.0, :center, 0)

    i = 0
    while i < 4
      k = $upg_order[i]
      spec = $upgrades[k]
      lv = (@upgs[k.to_s] || 0).to_i
      cost = spec[:cost] * (lv + 1)
      y = 134 + i * 20
      col = @sel == i + 1 ? 10 : 6
      rectfill(60, y, 200, 18, @sel == i + 1 ? 1 : 0, 0.8)
      rect(60, y, 200, 18, col, 1)
      tag = lv >= spec[:max_lv] ? "MAX" : "$#{cost}"
      print_text("#{spec[:name]} [#{lv}/#{spec[:max_lv]}] #{tag}", 160, y + 5, col, 8, 1.0, :center, 0)
      i += 1
    end

    print_text("WASD/ARROWS: DRILL & JET | X/Z: DROP FLARE", 160, 224, 15, 8, 1.0, :center, 0)
  end
end

class DrillScene
  def initialize(opts)
    @upgs = opts[:upgs] || {}
    @w = $cfg[:w]
    @h = $cfg[:h]
    @wh = $cfg[:world_h]
    @gy = $cfg[:ground_y]

    @terrain = create_surface(@w, @wh, :pixel)
    @lightmap = create_surface(@w, @h, :gpu)

    @drill_lv = (@upgs["drill"] || 0).to_i
    @tank_lv = (@upgs["tank"] || 0).to_i
    @light_lv = (@upgs["light"] || 0).to_i
    @jet_lv = (@upgs["jet"] || 0).to_i

    @max_fuel = $cfg[:base_fuel] + @tank_lv * 40.0
    @fuel = @max_fuel
    @light_r = $cfg[:base_light] + @light_lv * 14.0
    @jet_pwr = $cfg[:jet_power] + @jet_lv * 0.04

    @px = 160.0
    @py = (@gy - 10).to_f
    @vx = 0.0
    @vy = 0.0
    @facing = 1
    @cargo_val = 0
    @cash_run = 0
    @flares = []
    @ore_nodes = []
    @boulders = []
    @particles = []
    @popups = []
    @tick = 0
    @shake = 0.0
    @state = :play # :play, :win, :out_of_fuel
    @saved = false

    generate_strata
  end

  def generate_strata
    clear_surface(@terrain, nil)
    wh = @wh
    w = @w
    gy = @gy

    render_to(@terrain) do
      rectfill(0, gy, w, 240, 4)
      rectfill(0, gy + 240, w, 260, 9)
      rectfill(0, gy + 500, w, 280, 5)
      rectfill(0, gy + 780, w, 320, 2)
      # Cavern pockets
      k = 0
      while k < 28
        blend(:erase)
        circfill(24 + rand(w - 48), gy + 70 + rand(wh - gy - 120), 10 + rand(12), 0)
        blend(:normal)
        k += 1
      end
    end

    # Spawn ore nodes
    $ores.each do |sym, spec|
      cnt = 18
      k = 0
      while k < cnt
        ox = 18.0 + rand(w - 36)
        oy = spec[:min_y] + rand(spec[:max_y] - spec[:min_y]).to_f
        @ore_nodes << { x: ox, y: oy, type: sym, col: spec[:col], val: spec[:val] }
        k += 1
      end
    end

    # Spawn boulders
    k = 0
    while k < 16
      @boulders << {
        x: 24.0 + rand(w - 48),
        y: gy + 90.0 + rand(wh - gy - 160),
        vy: 0.0, falling: false
      }
      k += 1
    end
  end

  def update
    @tick += 1
    @shake *= 0.85
    @shake = 0.0 if @shake < 0.2
    update_particles
    update_popups

    if @state != :play
      if btnp(4) || btnp(5) || btnp(:mouse_l)
        run TitleScene.new
      end
      return
    end

    # Drop flare
    if btnp(5) || btnp(:mouse_r)
      if @flares.size >= 12
        @flares.shift
      end
      @flares << { x: @px, y: @py, life: 900 }
    end

    # Update flares
    i = @flares.size - 1
    while i >= 0
      @flares[i][:life] -= 1
      @flares.delete_at(i) if @flares[i][:life] <= 0
      i -= 1
    end

    # Player input
    spd = $cfg[:base_spd] + @drill_lv * 0.15
    dx = 0.0
    dx -= 1.0 if btn(0)
    dx += 1.0 if btn(1)
    @facing = dx > 0 ? 1 : -1 if dx != 0.0

    if btn(2) && @fuel > 0.0
      @vy -= @jet_pwr
      @fuel -= 0.12
      @particles << { x: @px, y: @py + 7, vx: (rand() - 0.5) * 1.2, vy: 1.5, col: 9, life: 10 } if @tick % 2 == 0
    else
      @vy += $cfg[:gravity]
    end
    @vy = @vy.clamp(-3.2, 3.6)

    dig_down = btn(3)

    # Horizontal move & drill
    nx = (@px + dx * spd).clamp(10.0, (@w - 10).to_f)
    if dx != 0.0
      if surface_circle_solid?(@terrain, nx.to_i, @py.to_i, 5) && @fuel > 0.0
        carve_tunnel(nx, @py, $cfg[:drill_r])
        @fuel -= [0.35 - @drill_lv * 0.04, 0.12].max
        @shake = 1.2
      end
      @px = nx
    end

    # Vertical move & drill
    ny = (@py + @vy).clamp(16.0, (@wh - 12).to_f)
    if @vy > 0.0
      if surface_circle_solid?(@terrain, @px.to_i, (ny + 4).to_i, 5)
        if dig_down && @fuel > 0.0
          carve_tunnel(@px, ny + 4.0, $cfg[:drill_r])
          @fuel -= [0.40 - @drill_lv * 0.04, 0.14].max
          @shake = 1.5
          @py = (@py + 1.2).clamp(16.0, (@wh - 12).to_f)
          @vy = 0.4
        else
          @vy = 0.0
        end
      else
        @py = ny
      end
    elsif @vy < 0.0
      if surface_circle_solid?(@terrain, @px.to_i, (ny - 4).to_i, 5) && @fuel > 0.0
        carve_tunnel(@px, ny - 4.0, $cfg[:drill_r])
        @fuel -= 0.25
      end
      @py = ny
    end

    # Surface base refuel & sell
    if @py <= @gy
      @fuel = [@fuel + 2.5, @max_fuel].min
      if @cargo_val > 0
        @cash_run += @cargo_val
        save_set("cash", save_get("cash", 0).to_i + @cargo_val)
        @popups << { x: @px, y: @py - 12, text: "SOLD +$#{@cargo_val}!", col: 10, life: 55 }
        @cargo_val = 0
      end
    end

    # Collect ores
    i = @ore_nodes.size - 1
    while i >= 0
      o = @ore_nodes[i]
      dxo = o[:x] - @px
      dyo = o[:y] - @py
      if dxo * dxo + dyo * dyo <= 144.0
        @cargo_val += o[:val]
        @popups << { x: o[:x], y: o[:y] - 8, text: "+$#{o[:val]}", col: o[:col], life: 36 }
        spawn_sparks(o[:x], o[:y], o[:col], 6)
        @ore_nodes.delete_at(i)
      end
      i -= 1
    end

    # Falling boulders (using surface_circle_solid?)
    @boulders.each do |b|
      if !surface_circle_solid?(@terrain, b[:x].to_i, (b[:y] + 8).to_i, 4)
        b[:vy] = [b[:vy] + 0.16, 3.2].min
        b[:y] += b[:vy]
      else
        b[:vy] = 0.0
      end
    end

    depth_m = [((@py - @gy) / ($cfg[:core_y] - @gy) * 1000.0).to_i, 0].max
    best_m = save_get("best_m", 0).to_i
    save_set("best_m", depth_m) if depth_m > best_m

    if @py >= $cfg[:core_y]
      @state = :win
      save_set("cores", save_get("cores", 0).to_i + 1)
      save_set("cash", save_get("cash", 0).to_i + 500 + @cargo_val)
    elsif @fuel <= 0.0 && @py > @gy + 10
      @fuel = 0.0
      @state = :out_of_fuel
    end
  end

  def carve_tunnel(cx, cy, r)
    render_to(@terrain) do
      blend(:erase)
      circfill(cx.to_i, cy.to_i, r, 0)
      blend(:normal)
    end
    spawn_sparks(cx, cy, 4, 2) if @tick % 3 == 0
  end

  def spawn_sparks(x, y, col, cnt)
    k = 0
    while k < cnt
      a = rand() * 6.283
      sp = 0.6 + rand() * 1.8
      @particles << { x: x, y: y, vx: cos(a) * sp, vy: sin(a) * sp, col: col, life: 14 }
      k += 1
    end
  end

  def update_particles
    i = @particles.size - 1
    while i >= 0
      pt = @particles[i]
      pt[:x] += pt[:vx]
      pt[:y] += pt[:vy]
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
    cam_y = (@py - @h * 0.45).clamp(0.0, (@wh - @h).to_f)
    sx = @shake > 0 ? (rand() * 2.0 - 1.0) * @shake : 0.0
    sy = @shake > 0 ? (rand() * 2.0 - 1.0) * @shake : 0.0

    bg(:cave, dim: 0.45, tint: "#605080", scale: 1.04, scroll_y: cam_y * 0.25, mirror_y: true, mirror_x: true)

    camera(sx, cam_y + sy)

    # Surface Refuel Base
    rectfill(120, @gy - 22, 80, 22, 1)
    rect(120, @gy - 22, 80, 22, 12, 1)
    print_text("BASE", 160, @gy - 15, 10, 8, 1.0, :center, 0)

    # Pixel strata
    draw_surface(@terrain, 0, 0)

    # Core goal line
    rectfill(0, $cfg[:core_y], @w, 60, 10, 0.35)
    print_text("ABYSSAL CORE (1000m)", 160, $cfg[:core_y] + 14, 10, 8, 1.0, :center, 0)

    # Ores & Boulders
    @ore_nodes.each do |o|
      next if o[:y] < cam_y - 16 || o[:y] > cam_y + @h + 16
      circfill(o[:x], o[:y], 4, o[:col])
      pset(o[:x] - 1, o[:y] - 1, 7)
    end
    @boulders.each do |b|
      next if b[:y] < cam_y - 16 || b[:y] > cam_y + @h + 16
      circfill(b[:x], b[:y], 6, 6)
      circ(b[:x], b[:y], 6, 0)
    end

    # Flares
    @flares.each do |fl|
      circfill(fl[:x], fl[:y], 3, 9)
      pset(fl[:x], fl[:y], 7)
    end

    # Driller Pod
    spr(:driller, @px - 8, @py - 8, @facing < 0)

    @particles.each do |pt|
      circfill(pt[:x], pt[:y], 2, pt[:col])
    end
    @popups.each do |pp|
      print_text(pp[:text], pp[:x], pp[:y], pp[:col], 8, 1.0, :center, 0)
    end

    camera()
    clip()

    # Depth-based :gpu Lightmap
    depth_ratio = ((@py - @gy) / ($cfg[:core_y] - @gy)).clamp(0.0, 1.0)
    dark_a = 0.15 + depth_ratio * 0.78
    py_scr = @py - cam_y
    render_to(@lightmap) do
      cls(0, dark_a)
      blend(:erase)
      circfill(@px, py_scr, @light_r, 0, 0.4)
      circfill(@px, py_scr, @light_r * 0.6, 0, 0.9)
      @flares.each do |fl|
        fy_scr = fl[:y] - cam_y
        if fy_scr > -40 && fy_scr < @h + 40
          circfill(fl[:x], fy_scr, 44, 0, 0.5)
          circfill(fl[:x], fy_scr, 22, 0, 0.95)
        end
      end
      blend(:normal)
    end
    draw_surface(@lightmap, 0, 0)

    draw_hud(depth_ratio)
  end

  def draw_hud(depth_ratio)
    rectfill(0, 0, @w, 22, 0, 0.8)
    depth_m = (depth_ratio * 1000.0).to_i
    print_text("DEPTH: #{depth_m}m", 8, 7, 12, 8, 1.0, :left, 0)
    print_text("CARGO: $#{@cargo_val}", 160, 7, 10, 8, 1.0, :center, 0)

    # Fuel gauge
    fw = (80.0 * @fuel / @max_fuel).to_i
    rectfill(230, 7, 82, 8, 1)
    rectfill(231, 8, fw, 6, @fuel < 25 ? 8 : 11)
    rect(230, 7, 82, 8, 7)

    if @state == :win || @state == :out_of_fuel
      rectfill(50, 76, 220, 84, 0, 0.90)
      rect(50, 76, 220, 84, @state == :win ? 10 : 8, 2)
      msg = @state == :win ? "CORE EXTRACTED! (+$500)" : "OUT OF FUEL..."
      print_text(msg, 160, 94, @state == :win ? 10 : 8, 8, 1.0, :center, 0)
      print_text("PRESS Z / CLICK FOR BASE", 160, 130, 7, 8, 1.0, :center, 0)
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #000000
1: #182038
5: #5F574F
6: #C2C3C7
7: #FFF1E8
8: #FF2E54
9: #FF9922
A: #FFEC27
C: #29ADFF

@SPRITE :driller 16x16 pal:1
................
.....111111.....
....1AAAAAA1....
...1AAC77CAA1...
...1AACCCCAA1...
...1AAAAAAAA1...
..115555555511..
..156666666651..
...1155555511...
....19999991....
.....19AA91.....
.....19AA91.....
......1991......
......1661......
.......11.......
................
