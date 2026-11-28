config(
  title: "LANTERN SURVIVORS",
  width: 320,
  height: 240,
  save_id: "lantern_survivors",
  save_salt: "p3g42b7e"
)

$cfg = {
  w: 320,
  h: 240,
  world_w: 640,
  world_h: 480,
  base_hp: 100,
  base_speed: 1.5,
  base_light_r: 68,
  dark_alpha: 0.90,
  xp_magnet_r: 44,
  survive_goal: 180,
  shake_max: 6.0
}

$enemies = {
  slime: { spr: :slime, hp: 16, spd: 0.65, dmg: 8, xp: 3, decal_col: 11, light_col: 11, r: 7 },
  bat: { spr: :bat, hp: 10, spd: 1.15, dmg: 6, xp: 2, decal_col: 2, light_col: 14, r: 6 },
  knight: { spr: :knight, hp: 45, spd: 0.55, dmg: 14, xp: 8, decal_col: 5, light_col: 8, r: 9 },
  wraith: { spr: :wraith, hp: 90, spd: 0.80, dmg: 18, xp: 20, decal_col: 13, light_col: 12, r: 10 }
}

$meta_upgrades = {
  hp: { name: "VITALITY (+20 HP)", cost_base: 15, max_lv: 5 },
  light: { name: "LANTERN (+12 RAD)", cost_base: 20, max_lv: 5 },
  dmg: { name: "FLAME (+15% DMG)", cost_base: 25, max_lv: 5 },
  spd: { name: "AGILITY (+10% SPD)", cost_base: 20, max_lv: 4 }
}

$run_upgrades = [
  { id: :bolt, name: "FIREBOLT +1", desc: "Fires extra homing spark" },
  { id: :orb, name: "SPIRIT ORB +1", desc: "Adds orbiting lantern orb" },
  { id: :nova, name: "SOLAR NOVA", desc: "Periodic fiery blast" },
  { id: :light, name: "BRIGHT WICK", desc: "Lantern radius +16" },
  { id: :heal, name: "ELIXIR", desc: "Restore 40 HP" },
  { id: :haste, name: "SWIFTNESS", desc: "Move & fire rate +15%" }
]

class TitleScene
  def initialize
    @souls = save_get("souls", 0).to_i
    @best_sec = save_get("best_sec", 0).to_i
    @best_kills = save_get("best_kills", 0).to_i
    @meta = save_get("meta", { "hp" => 0, "light" => 0, "dmg" => 0, "spd" => 0 })
    @sel = 0
    @keys = [:hp, :light, :dmg, :spd]
    @tick = 0
    @lightmap = create_surface($cfg[:w], $cfg[:h], :gpu)
  end

  def update
    @tick += 1
    if btnp(:up)
      @sel = (@sel - 1 + 5) % 5
    elsif btnp(:down)
      @sel = (@sel + 1) % 5
    end

    if btnp(1) || btnp(2)
      if @sel == 0
        run GameScene.new({ meta: @meta })
      else
        buy_upgrade(@keys[@sel - 1])
      end
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if mx >= 60 && mx <= 260
        if my >= 108 && my <= 130
          run GameScene.new({ meta: @meta })
          return
        elsif my >= 138 && my <= 218
          idx = ((my - 138) / 20).to_i
          if idx >= 0 && idx < 4
            @sel = idx + 1
            buy_upgrade(@keys[idx])
          end
        end
      end
    end
  end

  def buy_upgrade(k)
    ks = k.to_s
    lv = (@meta[ks] || 0).to_i
    spec = $meta_upgrades[k]
    return if lv >= spec[:max_lv]
    cost = spec[:cost_base] * (lv + 1)
    if @souls >= cost
      @souls -= cost
      @meta[ks] = lv + 1
      save_set("souls", @souls)
      save_set("meta", @meta)
    end
  end

  def draw
    cls(0)
    bg(:forest, dim: 0.45, tint: "#304060", scroll_x: @tick * 0.2, mirror_x: true)

    # Preview lantern cutout
    lx = 160 + cos(@tick * 0.03) * 70
    ly = 72 + sin(@tick * 0.05) * 18
    render_to(@lightmap) do
      cls(0, 0.78)
      blend(:erase)
      circfill(lx, ly, 72, 0, 0.35)
      circfill(lx, ly, 46, 0, 0.65)
      circfill(lx, ly, 26, 0, 1.0)
      blend(:normal)
    end
    draw_surface(@lightmap, 0, 0)

    spr(:hero, 152, 48, false)
    print_text("LANTERN SURVIVORS", 160, 18, 10, 16, 1.0, :center, 0, 2)
    print_text("BEST: #{@best_sec}s  KILLS: #{@best_kills}  SOULS: #{@souls}", 160, 78, 12, 8, 1.0, :center, 0)

    c0 = @sel == 0 ? 10 : 7
    rectfill(60, 108, 200, 22, @sel == 0 ? 1 : 0, 0.85)
    rect(60, 108, 200, 22, c0, 2)
    print_text("ENTER DARK FOREST (START)", 160, 115, c0, 8, 1.0, :center, 0)

    i = 0
    while i < 4
      k = @keys[i]
      spec = $meta_upgrades[k]
      lv = (@meta[k.to_s] || 0).to_i
      cost = spec[:cost_base] * (lv + 1)
      y = 138 + i * 20
      col = @sel == i + 1 ? 10 : 6
      rectfill(60, y, 200, 18, @sel == i + 1 ? 1 : 0, 0.8)
      rect(60, y, 200, 18, col, 1)
      tag = lv >= spec[:max_lv] ? "MAX" : "#{cost}S"
      print_text("#{spec[:name]} [#{lv}/#{spec[:max_lv]}] #{tag}", 160, y + 5, col, 8, 1.0, :center, 0)
      i += 1
    end

    print_text("WASD/ARROWS: MOVE | AUTO-FIRE | Z: UPGRADE", 160, 224, 15, 8, 1.0, :center, 0)
  end
end

class GameScene
  def initialize(opts)
    @meta = opts[:meta] || {}
    @w = $cfg[:w]
    @h = $cfg[:h]
    @ww = $cfg[:world_w]
    @wh = $cfg[:world_h]

    @decal = create_surface(@ww, @wh, :gpu)
    clear_surface(@decal, nil)
    @lightmap = create_surface(@w, @h, :gpu)

    # Pre-stamp mossy stones on decal
    render_to(@decal) do
      k = 0
      while k < 45
        circfill(rand(@ww), rand(@wh), 2 + rand(4), 1, 0.45)
        k += 1
      end
    end

    hp_lv = (@meta["hp"] || 0).to_i
    light_lv = (@meta["light"] || 0).to_i
    dmg_lv = (@meta["dmg"] || 0).to_i
    spd_lv = (@meta["spd"] || 0).to_i

    @px = @ww * 0.5
    @py = @wh * 0.5
    @facing_x = 1.0
    @max_hp = $cfg[:base_hp] + hp_lv * 20
    @hp = @max_hp
    @spd = $cfg[:base_speed] * (1.0 + spd_lv * 0.1)
    @light_r = $cfg[:base_light_r] + light_lv * 12
    @dmg_mul = 1.0 + dmg_lv * 0.15

    @xp = 0
    @xp_next = 12
    @lv = 1
    @kills = 0
    @souls_run = 0
    @tick = 0
    @inv_t = 0
    @shake = 0.0

    @bolt_lv = 1
    @orb_lv = 1
    @nova_lv = 0
    @fire_rate_mul = 1.0
    @bolt_cd = 0
    @nova_cd = 0

    @enemies = []
    @bullets = []
    @gems = []
    @particles = []
    @torches = [
      { x: 230.0, y: 175.0 },
      { x: 410.0, y: 175.0 },
      { x: 230.0, y: 305.0 },
      { x: 410.0, y: 305.0 }
    ]

    @state = :play # :play, :levelup, :gameover
    @choices = []
    @choice_sel = 0
    @saved_end = false
  end

  def update
    if @state == :levelup
      update_levelup
      return
    elsif @state == :gameover
      if btnp(1) || btnp(2) || btnp(:mouse_l)
        run TitleScene.new
      end
      return
    end

    @tick += 1
    @shake *= 0.85
    @shake = 0.0 if @shake < 0.2
    @inv_t -= 1 if @inv_t > 0

    # Player movement
    dx = 0.0
    dy = 0.0
    dx -= 1.0 if btn(:left)
    dx += 1.0 if btn(:right)
    dy -= 1.0 if btn(:up)
    dy += 1.0 if btn(:down)
    if dx != 0.0 && dy != 0.0
      dx *= 0.7071
      dy *= 0.7071
    end
    @facing_x = dx if dx != 0.0
    @px = (@px + dx * @spd).clamp(12.0, @ww - 12.0)
    @py = (@py + dy * @spd).clamp(12.0, @wh - 12.0)

    # Periodic footprint decal
    if (dx != 0.0 || dy != 0.0) && @tick % 12 == 0
      render_to(@decal) do
        circfill(@px, @py + 6, 1, 1, 0.35)
      end
    end

    spawn_enemies
    update_weapons
    update_bullets
    update_enemies
    update_gems
    update_particles
  end

  def spawn_enemies
    sec = @tick / 60
    interval = [42 - sec / 3, 10].max
    return if @tick % interval != 0 || @enemies.size >= 48

    ang = rand() * 6.283
    dist = 135.0 + rand() * 35.0
    ex = (@px + cos(ang) * dist).clamp(12.0, @ww - 12.0)
    ey = (@py + sin(ang) * dist).clamp(12.0, @wh - 12.0)

    kind = :slime
    r = rand()
    if sec > 60 && r < 0.15
      kind = :wraith
    elsif sec > 30 && r < 0.32
      kind = :knight
    elsif sec > 10 && r < 0.55
      kind = :bat
    end

    spec = $enemies[kind]
    @enemies << {
      kind: kind, x: ex, y: ey,
      hp: spec[:hp] + sec / 8, max_hp: spec[:hp] + sec / 8,
      spd: spec[:spd], dmg: spec[:dmg], xp: spec[:xp],
      r: spec[:r], flash: 0
    }
  end

  def update_weapons
    # Firebolt
    @bolt_cd -= 1
    if @bolt_cd <= 0 && !@enemies.empty?
      @bolt_cd = (34 / @fire_rate_mul).to_i
      @bolt_cd = 12 if @bolt_cd < 12
      k = 0
      while k < @bolt_lv
        target = @enemies[rand(@enemies.size)]
        # Aim nearest on first bolt
        if k == 0
          best_d = 999999.0
          @enemies.each do |en|
            d = (en[:x] - @px) ** 2 + (en[:y] - @py) ** 2
            if d < best_d
              best_d = d
              target = en
            end
          end
        end
        ang = atan2(target[:y] - @py, target[:x] - @px)
        @bullets << {
          x: @px, y: @py,
          vx: cos(ang) * 3.6, vy: sin(ang) * 3.6,
          dmg: (14 * @dmg_mul).to_i, life: 65, col: 10
        }
        k += 1
      end
    end

    # Orbiting Spirit Orbs
    orb_cnt = @orb_lv
    if orb_cnt > 0
      i = 0
      while i < orb_cnt
        ang = @tick * 0.07 + i * (6.283 / orb_cnt)
        ox = @px + cos(ang) * 34.0
        oy = @py + sin(ang) * 34.0
        @enemies.each do |en|
          dx = en[:x] - ox
          dy = en[:y] - oy
          if dx * dx + dy * dy <= (en[:r] + 6) ** 2
            if @tick % 8 == 0
              damage_enemy(en, (8 * @dmg_mul).to_i)
            end
          end
        end
        i += 1
      end
    end

    # Solar Nova
    if @nova_lv > 0
      @nova_cd -= 1
      if @nova_cd <= 0
        @nova_cd = 140
        rad = 48.0 + @nova_lv * 12.0
        @shake = 3.5
        render_to(@decal) do
          circ(@px, @py, rad * 0.7, 5, 0.35)
        end
        k = 0
        while k < 16
          a = k * 0.392
          @particles << { x: @px, y: @py, vx: cos(a) * 2.5, vy: sin(a) * 2.5, col: 9, life: 18, max_life: 18 }
          k += 1
        end
        @enemies.each do |en|
          dx = en[:x] - @px
          dy = en[:y] - @py
          if dx * dx + dy * dy <= rad * rad
            damage_enemy(en, (22 * @dmg_mul).to_i)
          end
        end
      end
    end
  end

  def update_bullets
    i = @bullets.size - 1
    while i >= 0
      b = @bullets[i]
      b[:x] += b[:vx]
      b[:y] += b[:vy]
      b[:life] -= 1
      hit = false
      @enemies.each do |en|
        dx = en[:x] - b[:x]
        dy = en[:y] - b[:y]
        if dx * dx + dy * dy <= (en[:r] + 4) ** 2
          damage_enemy(en, b[:dmg])
          hit = true
          break
        end
      end
      if hit || b[:life] <= 0
        @bullets.delete_at(i)
      end
      i -= 1
    end
  end

  def damage_enemy(en, dmg)
    en[:hp] -= dmg
    en[:flash] = 5
    @particles << { x: en[:x], y: en[:y], vx: (rand() - 0.5) * 2, vy: -1.2, col: 10, life: 12, max_life: 12 }
  end

  def update_enemies
    i = @enemies.size - 1
    while i >= 0
      en = @enemies[i]
      en[:flash] -= 1 if en[:flash] > 0
      if en[:hp] <= 0
        spec = $enemies[en[:kind]]
        # Stamp permanent splatter onto :gpu decal surface
        render_to(@decal) do
          circfill(en[:x], en[:y], 4 + rand(4), spec[:decal_col], 0.45)
          circfill(en[:x] + rand(9) - 4, en[:y] + rand(9) - 4, 2, spec[:decal_col], 0.35)
        end
        @gems << { x: en[:x], y: en[:y], val: en[:xp] }
        @kills += 1
        @souls_run += 1 if @kills % 3 == 0
        @enemies.delete_at(i)
        i -= 1
        next
      end

      dx = @px - en[:x]
      dy = @py - en[:y]
      dist = sqrt(dx * dx + dy * dy)
      if dist > 0.1
        en[:x] += (dx / dist) * en[:spd]
        en[:y] += (dy / dist) * en[:spd]
      end

      if dist <= en[:r] + 6.0 && @inv_t <= 0
        @hp -= en[:dmg]
        @inv_t = 24
        @shake = 4.0
        if @hp <= 0
          @hp = 0
          trigger_gameover
          return
        end
      end
      i -= 1
    end
  end

  def update_gems
    mag_r2 = $cfg[:xp_magnet_r] ** 2
    i = @gems.size - 1
    while i >= 0
      g = @gems[i]
      dx = @px - g[:x]
      dy = @py - g[:y]
      d2 = dx * dx + dy * dy
      if d2 <= 64.0
        @xp += g[:val]
        @gems.delete_at(i)
        if @xp >= @xp_next
          @xp -= @xp_next
          @lv += 1
          @xp_next = (@xp_next * 1.35).to_i + 4
          open_levelup
        end
      elsif d2 <= mag_r2
        d = sqrt(d2)
        g[:x] += (dx / d) * 3.2
        g[:y] += (dy / d) * 3.2
      end
      i -= 1
    end
  end

  def open_levelup
    @state = :levelup
    @choices = []
    pool = $run_upgrades.dup
    # Fisher-Yates pick 3
    idx = pool.size - 1
    while idx > 0
      j = rand(idx + 1)
      tmp = pool[idx]
      pool[idx] = pool[j]
      pool[j] = tmp
      idx -= 1
    end
    @choices = [pool[0], pool[1], pool[2]]
    @choice_sel = 0
  end

  def update_levelup
    if btnp(:up)
      @choice_sel = (@choice_sel + 2) % 3
    elsif btnp(:down)
      @choice_sel = (@choice_sel + 1) % 3
    end
    if btnp(1) || btnp(2)
      apply_choice(@choices[@choice_sel])
      @state = :play
    elsif btnp(:mouse_l)
      my = mouse_y
      if my >= 78 && my <= 186
        idx = ((my - 78) / 36).to_i
        if idx >= 0 && idx < 3
          apply_choice(@choices[idx])
          @state = :play
        end
      end
    end
  end

  def apply_choice(ch)
    id = ch[:id]
    if id == :bolt
      @bolt_lv += 1
    elsif id == :orb
      @orb_lv += 1
    elsif id == :nova
      @nova_lv += 1
    elsif id == :light
      @light_r += 16
    elsif id == :heal
      @hp = [@hp + 40, @max_hp].min
    elsif id == :haste
      @fire_rate_mul += 0.15
      @spd += 0.15
    end
  end

  def trigger_gameover
    @state = :gameover
    return if @saved_end
    @saved_end = true
    sec = @tick / 60
    best_s = save_get("best_sec", 0).to_i
    best_k = save_get("best_kills", 0).to_i
    souls = save_get("souls", 0).to_i
    save_set("best_sec", sec) if sec > best_s
    save_set("best_kills", @kills) if @kills > best_k
    save_set("souls", souls + @souls_run + sec / 5)
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

  def draw
    cls(0)
    cam_x = (@px - @w * 0.5).clamp(0.0, (@ww - @w).to_f)
    cam_y = (@py - @h * 0.5).clamp(0.0, (@wh - @h).to_f)
    sx = @shake > 0 ? (rand() * 2.0 - 1.0) * @shake : 0.0
    sy = @shake > 0 ? (rand() * 2.0 - 1.0) * @shake : 0.0

    bg(:forest, dim: 0.42, tint: "#486858", scale: 1.04, scroll_x: cam_x * 0.25, scroll_y: cam_y * 0.25, mirror_x: true, mirror_y: true)

    camera(cam_x + sx, cam_y + sy)

    # Persistent battlefield decals
    draw_surface(@decal, 0, 0)

    # Torches
    @torches.each do |tc|
      spr(:torch, tc[:x] - 8, tc[:y] - 8)
    end

    # XP Gems
    @gems.each do |g|
      circfill(g[:x], g[:y], 2, 12)
      pset(g[:x], g[:y], 7)
    end

    # Enemies
    @enemies.each do |en|
      spec = $enemies[en[:kind]]
      pal_id = en[:flash] > 0 ? 2 : nil
      spr(spec[:spr], en[:x] - 8, en[:y] - 8, en[:x] > @px, pal_id)
    end

    # Player
    spr(:hero, @px - 8, @py - 8, @facing_x < 0, @inv_t > 0 && @inv_t % 4 < 2 ? 2 : nil)

    # Orbiting orbs
    i = 0
    while i < @orb_lv
      ang = @tick * 0.07 + i * (6.283 / @orb_lv)
      ox = @px + cos(ang) * 34.0
      oy = @py + sin(ang) * 34.0
      circfill(ox, oy, 4, 10)
      circfill(ox, oy, 2, 7)
      i += 1
    end

    # Bullets
    @bullets.each do |b|
      circfill(b[:x], b[:y], 3, b[:col])
      pset(b[:x], b[:y], 7)
    end

    # Build 2D lightmap on :gpu surface using blend(:erase)
    flicker = sin(@tick * 0.18) * 3.0
    lr = @light_r + flicker
    px_scr = @px - cam_x
    py_scr = @py - cam_y
    render_to(@lightmap) do
      cls(0, $cfg[:dark_alpha])
      blend(:erase)
      # Player lantern
      circfill(px_scr, py_scr, lr, 0, 0.35)
      circfill(px_scr, py_scr, lr * 0.65, 0, 0.65)
      circfill(px_scr, py_scr, lr * 0.35, 0, 1.0)

      # Torches
      @torches.each do |tc|
        tx = tc[:x] - cam_x
        ty = tc[:y] - cam_y
        circfill(tx, ty, 54 + flicker, 0, 0.4)
        circfill(tx, ty, 30, 0, 0.9)
      end

      # Bullets & orbs emit small light cutouts
      @bullets.each do |b|
        circfill(b[:x] - cam_x, b[:y] - cam_y, 14, 0, 0.7)
      end
      k = 0
      while k < @orb_lv
        ang = @tick * 0.07 + k * (6.283 / @orb_lv)
        ox = @px + cos(ang) * 34.0 - cam_x
        oy = @py + sin(ang) * 34.0 - cam_y
        circfill(ox, oy, 16, 0, 0.75)
        k += 1
      end
      blend(:normal)
    end

    # Additive particles
    blend(:add)
    @particles.each do |pt|
      circfill(pt[:x], pt[:y], 2, pt[:col], pt[:life].to_f / pt[:max_life])
    end
    blend(:normal)

    camera()
    clip()
    draw_surface(@lightmap, 0, 0)

    # Subtle warm lantern glow in :add
    blend(:add)
    circfill(px_scr, py_scr, lr * 0.45, 9, 0.14)
    blend(:normal)

    draw_hud
  end

  def draw_hud
    # XP bar at very top
    xp_w = (@w * @xp / @xp_next).to_i
    rectfill(0, 0, @w, 5, 1)
    rectfill(0, 0, xp_w, 5, 12)

    sec = @tick / 60
    print_text(sprintf("LV %d  %02d:%02d", @lv, sec / 60, sec % 60), 8, 9, 7, 8, 1.0, :left, 0)
    print_text("KILLS:#{@kills}  SOULS:+#{@souls_run}", @w - 8, 9, 10, 8, 1.0, :right, 0)

    # HP bar
    hp_w = (90.0 * @hp / @max_hp).to_i
    rectfill(8, 20, 90, 6, 0)
    rectfill(8, 20, hp_w, 6, 8)
    rect(8, 20, 90, 6, 7)

    if @state == :levelup
      rectfill(36, 40, 248, 160, 0, 0.90)
      rect(36, 40, 248, 160, 10, 2)
      print_text("LEVEL UP! CHOOSE BLESSING", 160, 50, 10, 8, 1.0, :center, 0)
      i = 0
      while i < 3
        ch = @choices[i]
        y = 78 + i * 36
        c = @choice_sel == i ? 10 : 7
        rectfill(48, y, 224, 30, @choice_sel == i ? 1 : 0, 0.85)
        rect(48, y, 224, 30, c, 1)
        print_text(ch[:name], 160, y + 5, c, 8, 1.0, :center, 0)
        print_text(ch[:desc], 160, y + 17, 6, 8, 1.0, :center, 0)
        i += 1
      end
    elsif @state == :gameover
      rectfill(50, 72, 220, 96, 0, 0.90)
      rect(50, 72, 220, 96, 8, 2)
      print_text("LANTERN EXTINGUISHED", 160, 86, 8, 8, 1.0, :center, 0)
      print_text("SURVIVED: #{sec}s | KILLS: #{@kills}", 160, 108, 7, 8, 1.0, :center, 0)
      print_text("SOULS EARNED: +#{@souls_run + sec / 5}", 160, 124, 10, 8, 1.0, :center, 0)
      print_text("PRESS Z / CLICK TO RETURN", 160, 146, 12, 8, 1.0, :center, 0)
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #000000
1: #181425
2: #5A1E2E
3: #1E6F50
5: #4A5468
7: #FFF1E8
8: #FF2E54
9: #FF9922
A: #FFEC27
B: #38E456
C: #29ADFF
D: #9B76FF
F: #FFCCAA

@PALETTE 2
0: #FFFFFF
1: #FFFFFF
2: #FFFFFF
3: #FFFFFF
5: #FFFFFF
7: #FFFFFF
8: #FFFFFF
9: #FFFFFF
A: #FFFFFF
B: #FFFFFF
C: #FFFFFF
D: #FFFFFF
F: #FFFFFF

@SPRITE :hero 16x16 pal:1
................
.....111111.....
....12222221....
...12FFFFFF21...
...1F0FFFF0F1...
...1FFFFFFFF1...
....11999911....
...199A77A991...
..1999AAAA9991..
..1.19999991.1..
....11111111....
....15511551....
....15511551....
....111..111....
................
................

@SPRITE :slime 16x16 pal:1
................
................
................
.....111111.....
...11BBBBBB11...
..1BB7BBBBBBB1..
..1BBBBBBBBBB1..
.1BB1BBBBBB1BB1.
.1BB1BBBBBB1BB1.
.1BBBBBBBBBBBB1.
.1333BBBBBB3331.
..133333333331..
...1111111111...
................
................
................

@SPRITE :bat 16x16 pal:1
................
................
.11..........11.
1DD1..1111..1DD1
1DDD11DDDD11DDD1
.1DDDDDDDDDDDD1.
..11DD8DD8DD11..
....1DDDDDD1....
....1D7DD7D1....
.....111111.....
................
................
................
................
................
................

@SPRITE :knight 16x16 pal:1
................
.....111111.....
....15555551....
...1577557751...
...1585555851...
....11555511....
...1555115551...
..155555555551..
..151555555151..
....15511551....
....15511551....
....111..111....
................
................
................
................

@SPRITE :wraith 16x16 pal:1
................
.....111111.....
....1CCCCCC1....
...1CC7CC7CC1...
...1CCCCCCCC1...
...1CDDDDDDC1...
..1CCDDDDDDCC1..
..1CC1CDDC1CC1..
..1C1.1DD1.1C1..
..1...1..1...1..
................
................
................
................
................
................

@SPRITE :torch 16x16 pal:1
................
.......7........
......A7A.......
.....9AAA9......
.....9AAA9......
......999.......
.....15551......
.....15551......
......151.......
......151.......
......151.......
......151.......
......151.......
......111.......
................
................
