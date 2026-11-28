config(
  title: "INK TURF ARENA",
  width: 320,
  height: 240,
  save_id: "ink_turf_arena",
  save_salt: "p3g43c4d"
)

$cfg = {
  w: 320,
  h: 240,
  arena_y: 28,
  arena_w: 320,
  arena_h: 204,
  match_frames: 3600,
  base_spd: 1.55,
  swim_spd: 2.55,
  enemy_ink_spd: 0.85,
  ink_max: 100.0,
  team1_col: 12,
  team2_col: 14,
  respawn_frames: 90
}

$weapons = {
  shooter: { name: "SPLATTER", cost: 0, cd: 8, ink_cost: 3.0, spd: 4.2, rad: 8, dmg: 22, life: 28, spread: 0.14 },
  roller: { name: "INK ROLLER", cost: 40, cd: 16, ink_cost: 5.0, spd: 2.8, rad: 14, dmg: 35, life: 16, spread: 0.45 },
  blaster: { name: "TURF BLASTER", cost: 90, cd: 26, ink_cost: 11.0, spd: 3.4, rad: 22, dmg: 55, life: 32, spread: 0.05 }
}

$wep_order = [:shooter, :roller, :blaster]

$obstacles = [
  [144, 114, 32, 32],
  [68, 72, 20, 28],
  [232, 160, 20, 28]
]

class TitleScene
  def initialize
    @coins = save_get("coins", 0).to_i
    @wins = save_get("wins", 0).to_i
    @best_pct = save_get("best_pct", 0).to_i
    @unlocked = save_get("unlocked_weps", ["shooter"])
    @wep_idx = 0
    @mode = 0 # 0: 1P 2v2, 1: 2P VS
    @tick = 0
  end

  def update
    @tick += 1
    if btnp(:up) || btnp(:down)
      @mode = 1 - @mode
    end
    if btnp(:left)
      @wep_idx = (@wep_idx - 1 + $wep_order.size) % $wep_order.size
    elsif btnp(:right)
      @wep_idx = (@wep_idx + 1) % $wep_order.size
    end
    wh = mouse_wheel
    if wh > 0.0
      @wep_idx = (@wep_idx + 1) % $wep_order.size
    elsif wh < 0.0
      @wep_idx = (@wep_idx - 1 + $wep_order.size) % $wep_order.size
    end

    if btnp(1) || btnp(2) || btnp(:mouse_l)
      w_sym = $wep_order[@wep_idx]
      w_str = w_sym.to_s
      if !@unlocked.index(w_str).nil?
        run ArenaScene.new({ mode: @mode, p1_wep: w_sym })
      else
        cost = $weapons[w_sym][:cost]
        if @coins >= cost
          @coins -= cost
          @unlocked << w_str
          save_set("coins", @coins)
          save_set("unlocked_weps", @unlocked)
        end
      end
    end
  end

  def draw
    cls(0)
    bg(:cyber, dim: 0.48, tint: "#3060A0", scroll_x: @tick * 0.3, mirror_x: true)

    # Decorative ink splashes
    circfill(64, 52, 26, 12, 0.55)
    circfill(256, 62, 24, 14, 0.55)
    spr(:squid_p1, 56, 44)
    spr(:squid_p2, 248, 54, true)

    print_text("INK TURF ARENA", 160, 22, 10, 16, 1.0, :center, 0, 2)
    print_text("WINS: #{@wins}  BEST: #{@best_pct}%  COINS: #{@coins}", 160, 48, 7, 8, 1.0, :center, 0)

    # Mode selector
    c0 = @mode == 0 ? 10 : 6
    rectfill(50, 74, 220, 22, @mode == 0 ? 1 : 0, 0.85)
    rect(50, 74, 220, 22, c0, 2)
    print_text("1P TURF WAR (2v2 TEAM)", 160, 81, c0, 8, 1.0, :center, 0)

    c1 = @mode == 1 ? 10 : 6
    rectfill(50, 102, 220, 22, @mode == 1 ? 1 : 0, 0.85)
    rect(50, 102, 220, 22, c1, 2)
    print_text("2P LOCAL DUEL (P1 vs P2)", 160, 109, c1, 8, 1.0, :center, 0)

    # Weapon selector
    w_sym = $wep_order[@wep_idx]
    w_spec = $weapons[w_sym]
    owned = !@unlocked.index(w_sym.to_s).nil?
    rectfill(40, 138, 240, 46, 0, 0.85)
    rect(40, 138, 240, 46, 12, 2)
    print_text("< WEAPON: #{w_spec[:name]} >", 160, 146, 10, 8, 1.0, :center, 0)
    status = owned ? "EQUIPPED - PRESS Z TO BATTLE!" : "LOCKED (#{w_spec[:cost]} COINS - PRESS Z TO BUY)"
    print_text(status, 160, 164, owned ? 11 : 8, 8, 1.0, :center, 0)

    print_text("WASD/ARROWS: MOVE | Z/CLICK: SHOOT | X: SWIM INK", 160, 204, 7, 8, 1.0, :center, 0)
    print_text("2P: IJKL + U(SHOOT) / O(SWIM) OR GAMEPAD 2", 160, 218, 15, 8, 1.0, :center, 0)
  end
end

class ArenaScene
  def initialize(opts)
    @mode = opts[:mode]
    @p1_wep = opts[:p1_wep]
    @w = $cfg[:w]
    @h = $cfg[:h]
    @ay = $cfg[:arena_y]
    @ah = $cfg[:arena_h]

    @ink_surf = create_surface(@w, @ah, :pixel)
    clear_surface(@ink_surf, nil)

    @fighters = []
    if @mode == 0
      # 2v2: P1 + Ally CPU vs 2 Enemy CPUs
      @fighters << make_fighter(0, 1, false, 36.0, 90.0, @p1_wep, 0)
      @fighters << make_fighter(1, 1, true, 36.0, 170.0, :roller, 0)
      @fighters << make_fighter(2, 2, true, 284.0, 90.0, :shooter, 0)
      @fighters << make_fighter(3, 2, true, 284.0, 170.0, :blaster, 0)
    else
      # 2P Local Duel: P1 vs P2
      @fighters << make_fighter(0, 1, false, 36.0, 130.0, @p1_wep, 0)
      @fighters << make_fighter(1, 2, false, 284.0, 130.0, :shooter, 1)
    end

    # Initial spawn ink pads
    render_to(@ink_surf) do
      circfill(36, 90 - @ay, 20, $cfg[:team1_col])
      circfill(36, 170 - @ay, 20, $cfg[:team1_col])
      circfill(284, 90 - @ay, 20, $cfg[:team2_col])
      circfill(284, 170 - @ay, 20, $cfg[:team2_col])
    end

    @shots = []
    @particles = []
    @timer = $cfg[:match_frames]
    @tick = 0
    @t1_pct = 50.0
    @t2_pct = 50.0
    @total_px = (@w * @ah).to_f
    @done = false
    @saved = false
  end

  def make_fighter(id, team, is_cpu, x, y, wep, p_idx)
    {
      id: id, team: team, is_cpu: is_cpu, p_idx: p_idx,
      x: x, y: y, spawn_x: x, spawn_y: y,
      aim_x: team == 1 ? 1.0 : -1.0, aim_y: 0.0,
      hp: 100, ink: $cfg[:ink_max], wep: wep,
      cd: 0, swimming: false, dead_t: 0, flash: 0,
      ai_ang: 0.0, ai_t: 0
    }
  end

  def update
    @tick += 1
    if @done
      if btnp(1) || btnp(2) || btnp(:mouse_l)
        run TitleScene.new
      end
      return
    end

    @timer -= 1
    if @timer <= 0
      finish_match
      return
    end

    @fighters.each do |f|
      update_fighter(f)
    end
    update_shots
    update_particles

    if @tick % 6 == 0
      c1 = surface_count(@ink_surf, $cfg[:team1_col])
      c2 = surface_count(@ink_surf, $cfg[:team2_col])
      @t1_pct = c1 / @total_px * 100.0
      @t2_pct = c2 / @total_px * 100.0
    end
  end

  def update_fighter(f)
    f[:flash] -= 1 if f[:flash] > 0
    if f[:dead_t] > 0
      f[:dead_t] -= 1
      if f[:dead_t] == 0
        f[:x] = f[:spawn_x]
        f[:y] = f[:spawn_y]
        f[:hp] = 100
        f[:ink] = $cfg[:ink_max]
      end
      return
    end

    f[:cd] -= 1 if f[:cd] > 0
    my_col = f[:team] == 1 ? $cfg[:team1_col] : $cfg[:team2_col]
    en_col = f[:team] == 1 ? $cfg[:team2_col] : $cfg[:team1_col]
    floor_col = surface_pget(@ink_surf, f[:x].to_i, (f[:y] - @ay).to_i)

    dx = 0.0
    dy = 0.0
    shoot = false
    swim_btn = false

    if !f[:is_cpu]
      p = f[:p_idx]
      dx -= 1.0 if btn(:left, p)
      dx += 1.0 if btn(:right, p)
      dy -= 1.0 if btn(:up, p)
      dy += 1.0 if btn(:down, p)
      swim_btn = btn(2, p)
      shoot = btn(1, p)
      if p == 0 && btn(:mouse_l)
        mx = mouse_x - f[:x]
        my = mouse_y - f[:y]
        d = sqrt(mx * mx + my * my)
        if d > 2.0
          f[:aim_x] = mx / d
          f[:aim_y] = my / d
        end
        shoot = true
      elsif dx != 0.0 || dy != 0.0
        d = sqrt(dx * dx + dy * dy)
        f[:aim_x] = dx / d
        f[:aim_y] = dy / d
      end
    else
      # CPU AI
      f[:ai_t] -= 1
      if f[:ai_t] <= 0
        f[:ai_t] = 25 + rand(30)
        f[:ai_ang] += (rand() - 0.5) * 2.2
      end
      # Seek nearest enemy if close
      near = nil
      near_d = 99999.0
      @fighters.each do |o|
        next if o[:team] == f[:team] || o[:dead_t] > 0
        d = (o[:x] - f[:x]) ** 2 + (o[:y] - f[:y]) ** 2
        if d < near_d
          near_d = d
          near = o
        end
      end
      if near && near_d < 12000.0
        ang = atan2(near[:y] - f[:y], near[:x] - f[:x])
        f[:aim_x] = cos(ang)
        f[:aim_y] = sin(ang)
        dx = cos(ang + 0.3)
        dy = sin(ang + 0.3)
        shoot = true
      else
        dx = cos(f[:ai_ang])
        dy = sin(f[:ai_ang])
        f[:aim_x] = dx
        f[:aim_y] = dy
        shoot = f[:ink] > 20.0
        swim_btn = f[:ink] < 20.0
      end
    end

    if dx != 0.0 && dy != 0.0
      d = sqrt(dx * dx + dy * dy)
      dx /= d
      dy /= d
    end

    on_my_ink = (floor_col == my_col)
    on_en_ink = (floor_col == en_col)
    f[:swimming] = swim_btn && on_my_ink

    spd = $cfg[:base_spd]
    if f[:swimming]
      spd = $cfg[:swim_spd]
      f[:ink] = [f[:ink] + 1.8, $cfg[:ink_max]].min
      f[:hp] = [f[:hp] + 0.4, 100].min
    elsif on_en_ink
      spd = $cfg[:enemy_ink_spd]
      f[:hp] -= 0.15
    else
      f[:ink] = [f[:ink] + 0.25, $cfg[:ink_max]].min
    end

    nx = (f[:x] + dx * spd).clamp(10.0, @w - 10.0)
    ny = (f[:y] + dy * spd).clamp(@ay + 10.0, @ay + @ah - 10.0)
    if !hit_obstacle?(nx, f[:y], 6)
      f[:x] = nx
    end
    if !hit_obstacle?(f[:x], ny, 6)
      f[:y] = ny
    end

    # Roller paints under feet when moving & shooting
    w_spec = $weapons[f[:wep]]
    if shoot && !f[:swimming] && f[:cd] <= 0 && f[:ink] >= w_spec[:ink_cost]
      f[:cd] = w_spec[:cd]
      f[:ink] -= w_spec[:ink_cost]
      ang = atan2(f[:aim_y], f[:aim_x]) + (rand() - 0.5) * w_spec[:spread]
      @shots << {
        x: f[:x] + cos(ang) * 8.0,
        y: f[:y] + sin(ang) * 8.0,
        vx: cos(ang) * w_spec[:spd],
        vy: sin(ang) * w_spec[:spd],
        team: f[:team], col: my_col,
        rad: w_spec[:rad], dmg: w_spec[:dmg],
        life: w_spec[:life]
      }
      if f[:wep] == :roller
        splat_ink(f[:x], f[:y], 10, my_col)
      end
    end
  end

  def hit_obstacle?(px, py, r)
    $obstacles.each do |ob|
      ox = ob[0]
      oy = ob[1]
      ow = ob[2]
      oh = ob[3]
      if px + r > ox && px - r < ox + ow && py + r > oy && py - r < oy + oh
        return true
      end
    end
    false
  end

  def splat_ink(wx, wy, rad, col)
    sy = (wy - @ay).to_i
    render_to(@ink_surf) do
      circfill(wx.to_i, sy, rad, col)
      circfill(wx.to_i + rand(9) - 4, sy + rand(9) - 4, rad / 2 + 1, col)
    end
  end

  def update_shots
    i = @shots.size - 1
    while i >= 0
      s = @shots[i]
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1

      # Paint trail droplet periodically
      if s[:life] % 3 == 0
        splat_ink(s[:x], s[:y], 3, s[:col])
      end

      hit = false
      if s[:x] < 2 || s[:x] > @w - 2 || s[:y] < @ay + 2 || s[:y] > @ay + @ah - 2 || hit_obstacle?(s[:x], s[:y], 2)
        hit = true
      end

      @fighters.each do |f|
        next if f[:team] == s[:team] || f[:dead_t] > 0
        dx = f[:x] - s[:x]
        dy = f[:y] - s[:y]
        if dx * dx + dy * dy <= 100.0
          f[:hp] -= s[:dmg]
          f[:flash] = 6
          hit = true
          if f[:hp] <= 0
            f[:dead_t] = $cfg[:respawn_frames]
            splat_ink(f[:x], f[:y], 22, s[:col])
            spawn_sparks(f[:x], f[:y], s[:col], 12)
          end
          break
        end
      end

      if hit || s[:life] <= 0
        splat_ink(s[:x], s[:y], s[:rad], s[:col])
        spawn_sparks(s[:x], s[:y], s[:col], 5)
        @shots.delete_at(i)
      end
      i -= 1
    end
  end

  def spawn_sparks(x, y, col, cnt)
    k = 0
    while k < cnt
      a = rand() * 6.283
      sp = 0.8 + rand() * 2.2
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

  def finish_match
    @done = true
    return if @saved
    @saved = true
    c1 = surface_count(@ink_surf, $cfg[:team1_col])
    c2 = surface_count(@ink_surf, $cfg[:team2_col])
    @t1_pct = (c1 / @total_px * 100.0).round(1)
    @t2_pct = (c2 / @total_px * 100.0).round(1)
    if @t1_pct >= @t2_pct
      save_set("wins", save_get("wins", 0).to_i + 1)
      coins = save_get("coins", 0).to_i + 25 + (@t1_pct * 0.5).to_i
      save_set("coins", coins)
    else
      coins = save_get("coins", 0).to_i + 10
      save_set("coins", coins)
    end
    best = save_get("best_pct", 0).to_i
    save_set("best_pct", @t1_pct.to_i) if @t1_pct.to_i > best
  end

  def draw
    cls(1)
    bg(:training, dim: 0.55, tint: "#303850")
    draw_surface(@ink_surf, 0, @ay)

    # Obstacles
    $obstacles.each do |ob|
      rectfill(ob[0], ob[1], ob[2], ob[3], 5)
      rect(ob[0], ob[1], ob[2], ob[3], 6, 1)
    end

    # Fighters
    @fighters.each do |f|
      next if f[:dead_t] > 0
      if f[:swimming]
        circfill(f[:x], f[:y], 4, f[:team] == 1 ? 12 : 14)
        pset(f[:x], f[:y], 7)
      else
        spr_sym = f[:team] == 1 ? :squid_p1 : :squid_p2
        pal_id = f[:flash] > 0 ? 2 : nil
        spr(spr_sym, f[:x] - 8, f[:y] - 8, f[:aim_x] < 0, pal_id)
        # Ink tank indicator
        line(f[:x], f[:y], f[:x] + f[:aim_x] * 10.0, f[:y] + f[:aim_y] * 10.0, 7, 1)
      end
    end

    # Shots
    @shots.each do |s|
      circfill(s[:x], s[:y], 3, s[:col])
      pset(s[:x], s[:y], 7)
    end

    # Particles
    @particles.each do |pt|
      circfill(pt[:x], pt[:y], 2, pt[:col])
    end

    draw_hud
  end

  def draw_hud
    rectfill(0, 0, @w, @ay, 0, 0.85)
    sec = (@timer + 59) / 60
    print_text(sprintf("%d:%02d", sec / 60, sec % 60), 160, 4, 7, 8, 1.0, :center, 0)

    # Turf tug-of-war bar
    tot = @t1_pct + @t2_pct
    ratio = tot > 0.1 ? @t1_pct / tot : 0.5
    bar_w = 180
    bx = 70
    w1 = (bar_w * ratio).to_i
    w1 = 1 if w1 < 1
    w1 = bar_w - 1 if w1 >= bar_w
    rectfill(bx, 16, w1, 8, 12)
    rectfill(bx + w1, 16, bar_w - w1, 8, 14)
    rect(bx, 16, bar_w, 8, 7)

    print_text(sprintf("%.1f%%", @t1_pct), 64, 16, 12, 8, 1.0, :right, 0)
    print_text(sprintf("%.1f%%", @t2_pct), 256, 16, 14, 8, 1.0, :left, 0)

    p1 = @fighters[0]
    print_text("INK:#{p1[:ink].to_i}%", 6, 4, 12, 8, 1.0, :left, 0)

    if @done
      rectfill(56, 76, 208, 88, 0, 0.90)
      rect(56, 76, 208, 88, 10, 2)
      win = @t1_pct >= @t2_pct
      print_text(win ? "BLUE TEAM WINS!" : "PINK TEAM WINS!", 160, 90, win ? 12 : 14, 16, 1.0, :center, 0)
      print_text(sprintf("%.1f%% vs %.1f%%", @t1_pct, @t2_pct), 160, 116, 7, 8, 1.0, :center, 0)
      print_text("PRESS Z / CLICK TO CONTINUE", 160, 138, 10, 8, 1.0, :center, 0)
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #000000
1: #161C30
6: #C2C3C7
7: #FFF1E8
8: #FF2E54
A: #FFEC27
C: #29ADFF
E: #FF44AA
F: #FFCCAA

@PALETTE 2
0: #FFFFFF
1: #FFFFFF
7: #FFFFFF
C: #FFFFFF
E: #FFFFFF
F: #FFFFFF

@SPRITE :squid_p1 16x16 pal:1
................
.....111111.....
....1CCCCCC1....
...1CCCCCCCC1...
...1C77CC77C1...
...1C70CC70C1...
....1FFFFFF1....
....11CCCC11....
...1CCCCCCCC1...
..1CC1CCCC1CC1..
....1CCCCCC1....
....1CC11CC1....
....1CC11CC1....
....111..111....
................
................

@SPRITE :squid_p2 16x16 pal:1
................
.....111111.....
....1EEEEEE1....
...1EEEEEEEE1...
...1E77EE77E1...
...1E70EE70E1...
....1FFFFFF1....
....11EEEE11....
...1EEEEEEEE1...
..1EE1EEEE1EE1..
....1EEEEEE1....
....1EE11EE1....
....1EE11EE1....
....111..111....
................
................
