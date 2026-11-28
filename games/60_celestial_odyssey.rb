config(
  title: "CELESTIAL ODYSSEY",
  width: 480,
  height: 270,
  save_id: "celestial_odyssey",
  save_salt: "p4g60co1"
)

$cfg = {
  w: 480,
  h: 270,
  ts: 16,
  mw: 28,
  mh: 16,
  ox: 16,
  oy: 18,
  spd: 1.75,
  sword_cd: 16,
  sub_cd: 20,
  start_hp: 8
}

$zones = [
  { id: 0, jp: "天界の草原", bg: :forest, tint: "#70B880", bgm: :field_bgm, dark: false, floor_col: 3 },
  { id: 1, jp: "森の神殿", bg: :forest, tint: "#308860", bgm: :temple_bgm, dark: false, floor_col: 1 },
  { id: 2, jp: "暗闇の神殿", bg: :cave, tint: "#483888", bgm: :sanctum_bgm, dark: true, floor_col: 1 },
  { id: 3, jp: "炎の神殿", bg: :cave, tint: "#B84830", bgm: :temple_bgm, dark: false, floor_col: 2 },
  { id: 4, jp: "魔王城・玉座", bg: :cyber, tint: "#902050", bgm: :boss_bgm, dark: true, floor_col: 0 }
]

$enemies = {
  slime: { spr: :slime, hp: 2, spd: 0.55, atk: 1, col: 11, gold: 5 },
  knight: { spr: :knight, hp: 4, spd: 0.75, atk: 1, col: 12, gold: 12 },
  mage: { spr: :mage, hp: 3, spd: 0.5, atk: 1, col: 14, gold: 15 },
  boss: { spr: :demon, hp: 40, spd: 0.95, atk: 2, col: 8, gold: 200 }
}

class TitleScene
  def initialize
    @clears = save_get("clears", 0)
    @best_sec = save_get("best_sec", 0)
    @atk_lv = save_get("atk_lv", 1)
    @gold = save_get("gold", 0)
    @tick = 0
    music(:field_bgm, true, 0.65)
  end

  def update
    @tick += 1
    if btnp(2) && @gold >= 40 * @atk_lv
      @gold -= 40 * @atk_lv
      @atk_lv += 1
      save_set("gold", @gold)
      save_set("atk_lv", @atk_lv)
      sfx(:powerup)
    end
    if btnp(1) || btnp(:mouse_l)
      sfx(:confirm)
      run OdysseyScene.new({ atk_lv: @atk_lv })
    end
  end

  def draw
    cls(0)
    bg(:forest, dim: 0.45, tint: "#60A880", scroll_x: @tick * 0.25, mirror_x: true)

    f = (@tick / 15) % 2
    spr(spr_id(:hero, f), 76, 48, false, nil, 0.0, 1.8)
    spr(spr_id(:demon, f), 368, 34, true, nil, 0.0, 1.2)

    print_text("CELESTIAL ODYSSEY", 240, 16, 10, 16, 1.0, :center, 0, 2)
    print_text("60本記念・3つの神殿と魔王討伐アクションRPG", 240, 38, 7, 8, 1.0, :center, 0)

    rectfill(96, 86, 288, 74, 0, 0.82)
    rect(96, 86, 288, 74, 10, 1)
    print_text("3つの神殿でクリスタルを集め、魔王を討て！", 240, 96, 11, 8, 1.0, :center, 0)
    print_text("クリア回数: #{@clears}   最速: #{@best_sec > 0 ? "#{@best_sec}秒" : "--"}", 240, 116, 7, 8, 1.0, :center, 0)
    print_text("所持GOLD: #{@gold}G   剣Lv: #{@atk_lv} (Xで強化:#{40 * @atk_lv}G)", 240, 136, 10, 8, 1.0, :center, 0)

    rectfill(150, 180, 180, 26, 3, 0.92)
    rect(150, 180, 180, 26, 10, 2)
    print_text("冒険を始める (Z)", 240, 189, 10, 8, 1.0, :center, 0)

    print_text("移動:矢印  剣:Z  弓/爆弾:X  道具切替:ホイール/C", 240, 232, 7, 8, 1.0, :center, 0)
  end
end

class OdysseyScene
  def initialize(opts)
    @atk_lv = opts[:atk_lv] || 1
    @w = $cfg[:w]
    @h = $cfg[:h]
    @ts = $cfg[:ts]
    @mw = $cfg[:mw]
    @mh = $cfg[:mh]
    @ox = $cfg[:ox]
    @oy = $cfg[:oy]

    @lightmap = create_surface(@w, @h, :gpu)
    # 24x16 live minimap scaled 3.0x => 72x48 px
    @minimap = create_surface(24, 16, :pixel)
    # Destructible cracked walls per zone (:pixel)
    @crack_surfs = []
    z = 0
    while z < 5
      @crack_surfs << create_surface(@mw * @ts, @mh * @ts, :pixel)
      z += 1
    end

    @hp = $cfg[:start_hp]
    @max_hp = $cfg[:start_hp]
    @gold = 0
    @crystals = [false, false, false]
    @sub_tool = 0 # 0: Bow, 1: Bomb

    @px = 14.0 * @ts
    @py = 8.0 * @ts
    @dir = 1 # 0:R, 1:D, 2:L, 3:U
    @sword_t = 0
    @sword_cd = 0
    @sub_cd = 0
    @inv = 0

    @zone_id = 0
    @visited_zones = [true, false, false, false, false]
    @zones_data = []
    @arrows = []
    @bombs = []
    @e_shots = []
    @particles = []
    @popups = []

    @tick = 0
    @shake = 0.0
    @hitstop = 0
    @banner_txt = ""
    @banner_t = 0
    @state = :play
    @state_t = 0

    build_all_zones
    enter_zone(0, 14 * @ts, 8 * @ts)
  end

  def build_all_zones
    z = 0
    while z < 5
      grid = []
      y = 0
      while y < @mh
        row = []
        x = 0
        while x < @mw
          border = (x == 0 || y == 0 || x == @mw - 1 || y == @mh - 1)
          row << (border ? 1 : 0)
          x += 1
        end
        grid << row
        y += 1
      end

      foes = []
      portals = []
      torches = []
      crystal = nil

      if z == 0
        # Celestial Field: portals to 3 temples & citadel
        portals << { x: 4, y: 2, to_z: 1, tx: 14, ty: 13, col: 11, lbl: "森" }
        portals << { x: 23, y: 13, to_z: 2, tx: 14, ty: 13, col: 13, lbl: "闇" }
        portals << { x: 4, y: 13, to_z: 3, tx: 14, ty: 13, col: 9, lbl: "炎" }
        portals << { x: 14, y: 2, to_z: 4, tx: 14, ty: 13, col: 8, lbl: "魔王城", sealed: true }
        # Decorative pillars
        [[10, 5], [17, 5], [10, 10], [17, 10]].each { |pt| grid[pt[1]][pt[0]] = 1 }
        foes << make_foe(:slime, 8, 7)
        foes << make_foe(:slime, 19, 7)
        foes << make_foe(:knight, 14, 12)
      elsif z >= 1 && z <= 3
        portals << { x: 14, y: 14, to_z: 0, tx: z == 1 ? 4 : (z == 2 ? 23 : 4), ty: z == 1 ? 4 : 11, col: 7, lbl: "出口" }
        # Cracked wall barrier guarding crystal room on :pixel surface!
        render_to(@crack_surfs[z]) do
          cls(nil)
          rectfill(11 * @ts, 5 * @ts, 6 * @ts, @ts, 4)
          rect(11 * @ts, 5 * @ts, 6 * @ts, @ts, 9, 1)
        end
        [[6, 5], [7, 5], [8, 5], [9, 5], [10, 5], [17, 5], [18, 5], [19, 5], [20, 5], [21, 5]].each { |pt| grid[pt[1]][pt[0]] = 1 }
        torches << [12 * @ts, 3 * @ts]
        torches << [16 * @ts, 3 * @ts]
        torches << [6 * @ts, 10 * @ts]
        torches << [22 * @ts, 10 * @ts]
        crystal = { x: 14 * @ts, y: 3 * @ts, idx: z - 1, taken: false }
        foes << make_foe(:slime, 8, 9)
        foes << make_foe(:knight, 19, 9)
        foes << make_foe(:mage, 14, 7)
      elsif z == 4
        # Demon Citadel Boss Arena
        portals << { x: 14, y: 14, to_z: 0, tx: 14, ty: 4, col: 7, lbl: "帰還" }
        torches << [6 * @ts, 4 * @ts]
        torches << [21 * @ts, 4 * @ts]
        torches << [6 * @ts, 11 * @ts]
        torches << [21 * @ts, 11 * @ts]
        foes << make_foe(:boss, 13, 5)
      end

      @zones_data << { grid: grid, foes: foes, portals: portals, torches: torches, crystal: crystal }
      z += 1
    end
  end

  def make_foe(kind, gx, gy)
    spec = $enemies[kind]
    {
      kind: kind,
      spr: spec[:spr],
      hp: spec[:hp],
      max_hp: spec[:hp],
      spd: spec[:spd],
      atk: spec[:atk],
      col: spec[:col],
      gold: spec[:gold],
      x: (gx * @ts).to_f,
      y: (gy * @ts).to_f,
      flash: 0,
      cd: 50,
      flip: false
    }
  end

  def enter_zone(zid, px, py)
    @zone_id = zid
    @visited_zones[zid] = true
    @px = px.to_f
    @py = py.to_f
    @arrows.clear
    @bombs.clear
    @e_shots.clear
    zn = $zones[zid]
    music(zn[:bgm], true, 0.68)
    @banner_txt = zn[:jp]
    @banner_t = 100
    update_minimap
  end

  def update_minimap
    render_to(@minimap) do
      cls(0, 0.85)
      # Field center (8,6), Forest(2,1), Dark(14,1), Flame(2,11), Citadel(8,1)
      coords = [[8, 6], [2, 1], [14, 1], [2, 11], [8, 1]]
      i = 0
      while i < 5
        cp = coords[i]
        col = (@zone_id == i) ? 10 : (@visited_zones[i] ? 12 : 5)
        rectfill(cp[0], cp[1], 6, 4, col)
        i += 1
      end
    end
  end

  def solid_at?(px, py)
    ts = @ts
    x0 = (px + 2).to_i / ts
    x1 = (px + 13).to_i / ts
    y0 = (py + 2).to_i / ts
    y1 = (py + 14).to_i / ts
    grid = @zones_data[@zone_id][:grid]
    y = y0
    while y <= y1
      x = x0
      while x <= x1
        return true if x < 0 || y < 0 || x >= @mw || y >= @mh || grid[y][x] != 0
        x += 1
      end
      y += 1
    end
    # Check destructible :pixel cracked walls
    surface_solid?(@crack_surfs[@zone_id], px.to_i + 2, py.to_i + 2, 12, 12)
  end

  def update
    if @state != :play
      @state_t += 1
      if @state_t > 35 && (btnp(1) || btnp(2) || btnp(:mouse_l))
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
    @sword_t -= 1 if @sword_t > 0
    @sword_cd -= 1 if @sword_cd > 0
    @sub_cd -= 1 if @sub_cd > 0
    @inv -= 1 if @inv > 0
    @banner_t -= 1 if @banner_t > 0

    handle_player
    update_projectiles_and_bombs
    update_foes
    check_portals_and_crystals
    update_fx
  end

  def handle_player
    if mouse_wheel != 0 || btnp(:key_c)
      @sub_tool = (@sub_tool + 1) % 2
      sfx(:select)
    end

    dx = 0.0
    dy = 0.0
    if btn(:left)
      dx = -1.0
      @dir = 2
    elsif btn(:right)
      dx = 1.0
      @dir = 0
    end
    if btn(:up)
      dy = -1.0
      @dir = 3
    elsif btn(:down)
      dy = 1.0
      @dir = 1
    end

    if dx != 0.0 && dy != 0.0
      dx *= 0.707
      dy *= 0.707
    end

    spd = $cfg[:spd]
    nx = @px + dx * spd
    @px = nx unless solid_at?(nx, @py)
    ny = @py + dy * spd
    @py = ny unless solid_at?(@px, ny)

    # Sword Attack (Z)
    if btnp(1) && @sword_cd <= 0
      @sword_t = 10
      @sword_cd = $cfg[:sword_cd]
      sfx(:slash, -1, 0.75, 1.1)
      slash_foes
    end

    # Sub-weapon (X): Bow or Bomb
    if btnp(2) && @sub_cd <= 0
      @sub_cd = $cfg[:sub_cd]
      vx = @dir == 0 ? 1 : (@dir == 2 ? -1 : 0)
      vy = @dir == 1 ? 1 : (@dir == 3 ? -1 : 0)
      if @sub_tool == 0
        @arrows << { x: @px + 8, y: @py + 8, vx: vx * 4.2, vy: vy * 4.2, t: 45 }
        sfx(:shoot, -1, 0.65, 1.3)
      else
        @bombs << { x: @px + 8 + vx * 10, y: @py + 8 + vy * 10, t: 55 }
        sfx(:click, -1, 0.6, 0.8)
      end
    end
  end

  def slash_foes
    vx = @dir == 0 ? 1 : (@dir == 2 ? -1 : 0)
    vy = @dir == 1 ? 1 : (@dir == 3 ? -1 : 0)
    sx = @px + 8 + vx * 14
    sy = @py + 8 + vy * 14
    foes = @zones_data[@zone_id][:foes]
    i = 0
    while i < foes.size
      f = foes[i]
      fw = f[:kind] == :boss ? 24 : 14
      if f[:hp] > 0 && hypot(sx - (f[:x] + fw * 0.5), sy - (f[:y] + fw * 0.5)) < (fw * 0.6 + 14)
        damage_foe(f, 1 + @atk_lv)
      end
      i += 1
    end
  end

  def damage_foe(f, dmg)
    f[:hp] -= dmg
    f[:flash] = 6
    @hitstop = 2
    @shake = 3.5
    sfx(:hit, -1, 0.8, 1.1)
    spawn_sparks(f[:x] + 8, f[:y] + 8, f[:col], 8)
    @popups << { x: f[:x] + 8, y: f[:y], txt: "-#{dmg}", col: 10, t: 28 }

    if f[:hp] <= 0
      @gold += f[:gold]
      sfx(:coin, -1, 0.75, 1.15)
      if f[:kind] == :boss
        on_victory
      end
    end
  end

  def update_projectiles_and_bombs
    foes = @zones_data[@zone_id][:foes]
    i = @arrows.size - 1
    while i >= 0
      a = @arrows[i]
      a[:x] += a[:vx]
      a[:y] += a[:vy]
      a[:t] -= 1
      hit = (a[:t] <= 0) || solid_at?(a[:x] - 6, a[:y] - 6)
      unless hit
        j = 0
        while j < foes.size
          f = foes[j]
          fw = f[:kind] == :boss ? 24 : 14
          if f[:hp] > 0 && (a[:x] - (f[:x] + fw * 0.5)).abs < fw * 0.6 && (a[:y] - (f[:y] + fw * 0.5)).abs < fw * 0.6
            damage_foe(f, 1 + @atk_lv / 2)
            hit = true
            break
          end
          j += 1
        end
      end
      @arrows.delete_at(i) if hit
      i -= 1
    end

    # Bombs detonate & erase :pixel cracked walls!
    i = @bombs.size - 1
    while i >= 0
      bm = @bombs[i]
      bm[:t] -= 1
      if bm[:t] <= 0
        sfx(:explode, -1, 0.9, 1.0)
        @shake = 7.0
        spawn_sparks(bm[:x], bm[:y], 9, 16)
        render_to(@crack_surfs[@zone_id]) do
          blend(:erase)
          circfill(bm[:x].to_i, bm[:y].to_i, 22, 0, 1.0)
          blend(:normal)
        end
        j = 0
        while j < foes.size
          f = foes[j]
          if f[:hp] > 0 && hypot(bm[:x] - (f[:x] + 8), bm[:y] - (f[:y] + 8)) < 36
            damage_foe(f, 4 + @atk_lv)
          end
          j += 1
        end
        @bombs.delete_at(i)
      end
      i -= 1
    end

    foes.reject! { |f| f[:hp] <= 0 }
  end

  def update_foes
    foes = @zones_data[@zone_id][:foes]
    i = 0
    while i < foes.size
      f = foes[i]
      f[:flash] -= 1 if f[:flash] > 0
      dx = @px - f[:x]
      dy = @py - f[:y]
      dist = hypot(dx, dy)
      if dist > 4.0 && dist < 170.0
        vx = (dx / dist) * f[:spd]
        vy = (dy / dist) * f[:spd]
        f[:flip] = vx < 0
        f[:x] += vx unless solid_at?(f[:x] + vx, f[:y])
        f[:y] += vy unless solid_at?(f[:x], f[:y] + vy)
      end

      if f[:kind] == :mage || f[:kind] == :boss
        f[:cd] -= 1
        if f[:cd] <= 0
          f[:cd] = f[:kind] == :boss ? 65 : 95
          ang = atan2(dy, dx)
          cnt = f[:kind] == :boss ? 3 : 1
          k = 0
          while k < cnt
            a = ang + (k - (cnt - 1) * 0.5) * 0.35
            @e_shots << { x: f[:x] + 8, y: f[:y] + 8, vx: cos(a) * 2.1, vy: sin(a) * 2.1, t: 90 }
            k += 1
          end
          sfx(:laser, -1, 0.45, 0.85)
        end
      end

      bw = f[:kind] == :boss ? 24 : 12
      if hypot(@px + 8 - (f[:x] + bw * 0.5), @py + 8 - (f[:y] + bw * 0.5)) < (bw * 0.5 + 5)
        hurt_player(f[:atk])
      end
      i += 1
    end

    i = @e_shots.size - 1
    while i >= 0
      es = @e_shots[i]
      es[:x] += es[:vx]
      es[:y] += es[:vy]
      es[:t] -= 1
      if hypot(@px + 8 - es[:x], @py + 8 - es[:y]) < 8
        hurt_player(1)
        @e_shots.delete_at(i)
      elsif es[:t] <= 0
        @e_shots.delete_at(i)
      end
      i -= 1
    end
  end

  def hurt_player(dmg)
    return if @inv > 0
    @hp -= dmg
    @inv = 45
    @shake = 5.5
    sfx(:hit, -1, 0.9, 0.7)
    if @hp <= 0
      @hp = 0
      stop_music
      sfx(:gameover)
      save_set("gold", save_get("gold", 0) + @gold)
      @state = :gameover
      @state_t = 0
    end
  end

  def check_portals_and_crystals
    zn = @zones_data[@zone_id]
    cr = zn[:crystal]
    if cr && !cr[:taken] && hypot(@px - cr[:x], @py - cr[:y]) < 16
      cr[:taken] = true
      @crystals[cr[:idx]] = true
      @hp = @max_hp
      sfx(:powerup, -1, 0.95, 1.2)
      @banner_txt = "聖なるクリスタル獲得！ (#{crystal_count}/3)"
      @banner_t = 120
    end

    i = 0
    while i < zn[:portals].size
      pt = zn[:portals][i]
      if hypot(@px - pt[:x] * @ts, @py - pt[:y] * @ts) < 14
        if pt[:sealed] && crystal_count < 3
          @banner_txt = "クリスタルが3つ必要です (#{crystal_count}/3)"
          @banner_t = 60
        else
          sfx(:confirm, -1, 0.65, 1.1)
          enter_zone(pt[:to_z], pt[:tx] * @ts, pt[:ty] * @ts)
          return
        end
      end
      i += 1
    end
  end

  def crystal_count
    c = 0
    i = 0
    while i < 3
      c += 1 if @crystals[i]
      i += 1
    end
    c
  end

  def on_victory
    stop_music
    sfx(:clear)
    sec = (@tick / 60).to_i
    save_set("clears", save_get("clears", 0) + 1)
    save_set("gold", save_get("gold", 0) + @gold + 100)
    bt = save_get("best_sec", 0)
    save_set("best_sec", sec) if bt == 0 || sec < bt
    @clear_sec = sec
    @state = :win
    @state_t = 0
  end

  def spawn_sparks(x, y, col, n)
    i = 0
    while i < n
      a = rand * Math::PI * 2.0
      sp = 0.8 + rand * 2.2
      @particles << { x: x.to_f, y: y.to_f, vx: cos(a) * sp, vy: sin(a) * sp, col: col, t: 16 }
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
      @particles.delete_at(i) if pt[:t] <= 0
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

  def draw
    cls(0)
    z_spec = $zones[@zone_id]
    bg(z_spec[:bg], dim: 0.55, tint: z_spec[:tint])

    sx = @shake > 0 ? (rand * @shake * 2.0 - @shake) : 0.0
    sy = @shake > 0 ? (rand * @shake * 2.0 - @shake) : 0.0
    camera(sx, sy)

    draw_zone_tiles(z_spec)
    draw_surface(@crack_surfs[@zone_id], @ox, @oy)
    draw_entities
    draw_fx

    camera
    draw_lightmap if z_spec[:dark]
    blend(:normal)
    draw_hud(z_spec)
    draw_overlay if @state != :play
  end

  def draw_zone_tiles(z_spec)
    ox = @ox
    oy = @oy
    ts = @ts
    zn = @zones_data[@zone_id]
    grid = zn[:grid]

    rectfill(ox, oy, @mw * ts, @mh * ts, z_spec[:floor_col], 0.55)
    y = 0
    while y < @mh
      x = 0
      while x < @mw
        if grid[y][x] == 1
          px = ox + x * ts
          py = oy + y * ts
          rectfill(px, py, 16, 16, 1)
          rectfill(px + 1, py + 1, 14, 14, 5)
          rect(px, py, 16, 16, 0, 1)
        end
        x += 1
      end
      y += 1
    end

    # Portals
    i = 0
    while i < zn[:portals].size
      pt = zn[:portals][i]
      px = ox + pt[:x] * ts
      py = oy + pt[:y] * ts
      locked = pt[:sealed] && crystal_count < 3
      circfill(px + 8, py + 8, 8, locked ? 5 : pt[:col], 0.85)
      circ(px + 8, py + 8, 9, 7, 0.9)
      print_text(pt[:lbl], px + 8, py - 10, 7, 8, 1.0, :center, 0)
      i += 1
    end

    # Torches
    tf = (@tick / 8) % 2
    i = 0
    while i < zn[:torches].size
      tc = zn[:torches][i]
      spr(spr_id(:torch, tf), ox + tc[0], oy + tc[1])
      i += 1
    end

    # Crystal
    cr = zn[:crystal]
    if cr && !cr[:taken]
      bob = (sin(@tick * 0.1) * 3).to_i
      blend(:add)
      circfill(ox + cr[:x] + 8, oy + cr[:y] + 8 + bob, 11, 12, 0.45)
      blend(:normal)
      spr(:crystal, ox + cr[:x], oy + cr[:y] + bob)
    end
  end

  def draw_entities
    ox = @ox
    oy = @oy
    f = (@tick / 12) % 2

    # Bombs
    i = 0
    while i < @bombs.size
      bm = @bombs[i]
      circfill(ox + bm[:x], oy + bm[:y], 5, (bm[:t] < 16 && bm[:t] % 4 < 2) ? 8 : 0)
      circ(ox + bm[:x], oy + bm[:y], 5, 9)
      i += 1
    end

    # Foes
    foes = @zones_data[@zone_id][:foes]
    i = 0
    while i < foes.size
      foe = foes[i]
      pal(7, 8) if foe[:flash] > 0
      if foe[:kind] == :boss
        spr(spr_id(:demon, f), ox + foe[:x], oy + foe[:y], foe[:flip])
        bw = 32
        fw = ((foe[:hp].to_f / foe[:max_hp]) * bw).to_i.clamp(0, bw)
        rectfill(ox + foe[:x], oy + foe[:y] - 6, bw, 3, 0)
        rectfill(ox + foe[:x], oy + foe[:y] - 6, fw, 3, 8)
      else
        spr(spr_id(foe[:spr], f), ox + foe[:x], oy + foe[:y], foe[:flip])
      end
      pal if foe[:flash] > 0
      i += 1
    end

    # Player & Sword Swing
    if @inv == 0 || (@tick % 4 < 2)
      spr(spr_id(:hero, f), ox + @px, oy + @py, @dir == 2)
    end
    if @sword_t > 0
      vx = @dir == 0 ? 1 : (@dir == 2 ? -1 : 0)
      vy = @dir == 1 ? 1 : (@dir == 3 ? -1 : 0)
      blend(:add)
      line(ox + @px + 8, oy + @py + 8, ox + @px + 8 + vx * 20, oy + @py + 8 + vy * 20, 10, 4, 0.9)
      blend(:normal)
    end

    # Arrows & Enemy Shots
    i = 0
    while i < @arrows.size
      a = @arrows[i]
      line(ox + a[:x], oy + a[:y], ox + a[:x] - a[:vx] * 2, oy + a[:y] - a[:vy] * 2, 10, 2)
      i += 1
    end
    i = 0
    while i < @e_shots.size
      es = @e_shots[i]
      circfill(ox + es[:x], oy + es[:y], 3, 8)
      i += 1
    end
  end

  def draw_fx
    ox = @ox
    oy = @oy
    blend(:add)
    i = 0
    while i < @particles.size
      pt = @particles[i]
      circfill(ox + pt[:x], oy + pt[:y], 2, pt[:col], 0.85)
      i += 1
    end
    blend(:normal)

    i = 0
    while i < @popups.size
      p = @popups[i]
      print_text(p[:txt], ox + p[:x], oy + p[:y], p[:col], 8, 1.0, :center, 0)
      i += 1
    end
  end

  def draw_lightmap
    ox = @ox
    oy = @oy
    zn = @zones_data[@zone_id]
    render_to(@lightmap) do
      cls(0, 0.82)
      blend(:erase)
      circfill(ox + @px + 8, oy + @py + 8, 86, 0, 1.0)
      i = 0
      while i < zn[:torches].size
        tc = zn[:torches][i]
        circfill(ox + tc[0] + 8, oy + tc[1] + 8, 52, 0, 1.0)
        i += 1
      end
      blend(:normal)
    end
    draw_surface(@lightmap, 0, 0)
  end

  def draw_hud(z_spec)
    rectfill(0, 0, @w, 18, 0, 0.88)
    h_str = ""
    i = 0
    while i < @max_hp
      h_str += (i < @hp ? "♥" : "·")
      i += 1
    end
    print_text(h_str, 8, 5, 8, 8, 1.0, :left, 0)
    print_text(z_spec[:jp], 124, 5, 11, 8, 1.0, :left, 0)
    print_text("聖晶:#{crystal_count}/3", 252, 5, 12, 8, 1.0, :left, 0)
    tool_s = @sub_tool == 0 ? "道具:弓(X)" : "道具:爆弾(X)"
    print_text("#{tool_s} #{@gold}G", 472, 5, 10, 8, 1.0, :right, 0)

    # Live minimap via draw_surface(scale: 3.0)
    rect(397, 21, 74, 50, 12, 1)
    draw_surface(@minimap, 398, 22, scale: 3.0)

    if @banner_t > 0
      rectfill(120, 232, 240, 22, 0, 0.88)
      rect(120, 232, 240, 22, 10, 1)
      print_text(@banner_txt, 240, 239, 10, 8, 1.0, :center, 0)
    end
  end

  def draw_overlay
    rectfill(110, 74, 260, 112, 0, 0.92)
    b_col = (@state == :win) ? 10 : 8
    rect(110, 74, 260, 112, b_col, 2)
    title = (@state == :win) ? "CELESTIA SAVED!" : "FALLEN IN BATTLE..."
    print_text(title, 240, 92, b_col, 16, 1.0, :center, 0)
    if @state == :win
      print_text("クリアタイム: #{@clear_sec}秒  GOLD: +#{@gold}", 240, 124, 11, 8, 1.0, :center, 0)
    end
    print_text("ZまたはXでタイトルへ", 240, 152, 7, 8, 1.0, :center, 0)
  end
end

run TitleScene.new
__END__
@PALETTE 1
1: #161828
3: #1E7A50
4: #985432
5: #4A546E
6: #B0C0D8
7: #FFF8F0
8: #FF2454
9: #FF9420
A: #FFE438
B: #34E878
C: #30B8FF
D: #865ED8
E: #FF70B8
F: #FFD4B0

@SPRITE :hero 16x16 pal:1
....11111111....
...1AA9999AA1...
..1AA7AAAAAA91..
..1FFFFFFFFFF1..
..1F1CC7FF1CC1..
..1FFFFFFFFFF1..
...1133333311...
..1333AAAA3331..
.133133BB331331.
.1F1133333311F1.
..1..133331..1..
....14411441....
....14411441....
...1155115511...
................
................
---
....11111111....
...1AA9999AA1...
..1AA7AAAAAA91..
..1FFFFFFFFFF1..
..1F1CC7FF1CC1..
..1FFFFFFFFFF1..
..1333AAAA3331..
.133133BB331331.
.1F1133333311F1.
..1..133331..1..
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
1BBBBBBBBBBBBBB1
1BBBBBBBB333BBB1
.13333333333331.
..111111111111..
................
................
................
................
---
................
...1111111111...
..1BBBBBBBBBB1..
.1BB77BBBBBBBB1.
.1BBB1BBBB1BBB1.
.1BBB1BBBB1BBB1.
..1BBBBBBBBBB1..
..1BBBB33BBBB1..
...1333333331...
....11111111....
................
................
................
................
................
................

@SPRITE :knight 16x16 pal:1
....11111111....
...1CCCCCCCC1...
..1CC77CCCCCC1..
..1C11111111C1..
..1C18711781C1..
..1CCCCCCCCCC1..
.1155CCCCCC5511.
155551CCCC155551
15511CCCCCC11551
.11..1CCCC1..11.
....15511551....
...1111..1111...
................
................
................
................
---
....11111111....
...1CCCCCCCC1...
..1CC77CCCCCC1..
..1C11111111C1..
..1C18711781C1..
..1CCCCCCCCCC1..
155551CCCC155551
15511CCCCCC11551
.11..1CCCC1..11.
....15511551....
...1551..1551...
...111....111...
................
................
................
................

@SPRITE :mage 16x16 pal:1
......1111......
....11DDDD11....
...1DDDDDDDD1...
..111111111111..
...1D1A11A1D1...
...1DDDDDDDD1...
..122DDDDDD221..
.122D2DDDD2D221.
.121.1DDDD1.121.
.....12DD21.....
....12211221....
....111..111....
................
................
................
................
---
......1111......
....11DDDD11....
...1DDDDDDDD1...
..111111111111..
...1D1A11A1D1...
...1DDDDDDDD1...
.122DDDDDDDD221.
1221.1DDDD1.1221
.....1DDDD1.....
....12211221....
....111..111....
................
................
................
................
................

@SPRITE :demon 32x32 pal:1
...11......................11...
..1AA1......11111111......1AA1..
..1AAA1...112222222211...1AAA1..
...1AAA1.12222222222221.1AAA1...
....1AA112288222222882211AA1....
.....1122287822222287822211.....
......12222222222222222221......
......12221122222222112221......
.......122171222222171221.......
......11222222222222222211......
....1188222211AAAA1122228811....
...188888221AA7777AA122888881...
..188822221AAAAAAAAAA122228881..
.1881..12221AAAAAAAA12221..1881.
.181...1222211AAAA1122221...181.
..1....122222222222222221....1..
.......122221222222122221.......
......122221.122221.122221......
......12221..122221..12221......
.....11221....1111....12211.....
.....18881............18881.....
.....11111............11111.....
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
...11......................11...
..1AA1......11111111......1AA1..
..1AAA1...112222222211...1AAA1..
...1AAA1.12222222222221.1AAA1...
....1AA112288222222882211AA1....
.....1122287822222287822211.....
......12222222222222222221......
......12221122222222112221......
.......122171222222171221.......
..1...11222222222222222211...1..
.1811188222211AAAA1122228811181.
188888888221AA7777AA122888888881
.1111122221AAAAAAAAAA1222211111.
......122221AAAAAAAA122221......
......12222211AAAA11222221......
......12222222222222222221......
......122221.122221.122221......
.....122221..122221..122221.....
.....12221....1111....12221.....
....18881..............18881....
....11111..............11111....
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

@SPRITE :crystal 16x16 pal:1
.......11.......
......1CC1......
.....1C77C1.....
....1CC7CCC1....
...1CCC7CCCC1...
..1CCCCCCCCC1...
..1CCCCCCCCC1...
..1CCCCDCCCC1...
...1CCDDDDC1....
....1CDDDD1.....
.....1DDD1......
......111.......
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

@MUSIC :field_bgm
ch0 wave=pulse vol=4 T124 L8 O4 c e g > c < b g e g  f a > c f e c < a f  d f a > d c < a f d  g b > d g e4 d4
ch1 wave=tri vol=5 T124 L4 O3 c g f c  d a g d
ch2 wave=noise vol=2 T124 L8 O6 c r r c r r c r

@MUSIC :temple_bgm
ch0 wave=square vol=4 T128 L8 O4 e g b > d c < b g e  d f# a > c < b a f# d  c e g b a g e c  < b > d# f# b4 r4
ch1 wave=tri vol=5 T128 L4 O2 e b d a  c g b f#

@MUSIC :sanctum_bgm
ch0 wave=tri vol=5 T116 L8 O4 d f a > c < a f d f  c e g b g e c e  < b > d f# a f# d < b > d  d f a > d4 r4
ch1 wave=pulse vol=3 T116 L4 O3 d a c g  < b > f# d a

@MUSIC :boss_bgm
ch0 wave=saw vol=4 T152 L8 O4 e e > e < b > c < b g e  f f > f c d c < a f  g g > g d e d < b g  a4 g4 f#4 e4
ch1 wave=tri vol=6 T152 L8 O2 e e g e f f a f  g g b g a g f# e
ch2 wave=noise vol=3 T152 L8 O6 c c r c c r c c  c c r c c r c c
