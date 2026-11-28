config(
  title: "TITAN COLOSSEUM",
  width: 480,
  height: 270,
  save_id: "titan_colosseum",
  save_salt: "p3g50z9x"
)

$cfg = {
  w: 480,
  h: 270,
  arena_x: 24,
  arena_y: 34,
  arena_w: 432,
  arena_h: 220,
  p_hp: 100,
  p_spd: 2.1,
  dash_spd: 5.2,
  dash_frames: 10,
  dash_cd: 34,
  shot_cd: 8,
  shot_spd: 5.8,
  shot_dmg: 8,
  shake_max: 9.0
}

$titans = [
  { name: "IRON GOLEM", spr: :golem, hp: 360, spd: 0.7, col: 6, bg: :mountain, tint: "#A09080", dark: false, s_sec: 35 },
  { name: "INFERNO WYRM", spr: :wyrm, hp: 460, spd: 1.0, col: 9, bg: :cave, tint: "#FF7040", dark: false, s_sec: 40 },
  { name: "STORM VALKYRIE", spr: :valkyrie, hp: 540, spd: 1.35, col: 12, bg: :sky, tint: "#80C8FF", dark: false, s_sec: 45 },
  { name: "ABYSS KRAKEN", spr: :kraken, hp: 640, spd: 0.9, col: 14, bg: :cave, tint: "#6040A0", dark: true, s_sec: 50 },
  { name: "OMEGA COLOSSUS", spr: :omega, hp: 820, spd: 1.15, col: 10, bg: :cyber, tint: "#FFD060", dark: true, s_sec: 65 }
]

class TitleScene
  def initialize
    @ranks = save_get("ranks", {})
    @times = save_get("times", {})
    @sel = 0
    @coop = false
    @tick = 0
  end

  def update
    @tick += 1
    @sel = (@sel - 1 + $titans.size) % $titans.size if btnp(:left) || btnp(:up)
    @sel = (@sel + 1) % $titans.size if btnp(:right) || btnp(:down)
    @coop = !@coop if btnp(2)

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 174 && my <= 198 && mx >= 140 && mx <= 340
        @coop = !@coop
        return
      elsif my >= 204 && my <= 232 && mx >= 140 && mx <= 340
        run RaidScene.new({ idx: @sel, coop: @coop })
        return
      elsif my >= 88 && my <= 156
        i = ((mx - 20) / 88).to_i
        if i >= 0 && i < $titans.size
          @sel = i
          run RaidScene.new({ idx: @sel, coop: @coop })
          return
        end
      end
    end

    if btnp(1)
      run RaidScene.new({ idx: @sel, coop: @coop })
    end
  end

  def draw
    cls(0)
    bg(:cyber, dim: 0.45, tint: "#9050B0", scroll_x: @tick * 0.25, mirror_x: true)

    print_text("TITAN COLOSSEUM", 240, 18, 10, 16, 1.0, :center, 0, 2)
    print_text("50TH GAME ANNIVERSARY BOSS RAID", 240, 44, 7, 8, 1.0, :center, 0)

    i = 0
    while i < $titans.size
      t = $titans[i]
      bx = 20 + i * 88
      by = 88
      sel = @sel == i
      rectfill(bx, by, 82, 68, sel ? 1 : 0, 0.85)
      rect(bx, by, 82, 68, sel ? 10 : t[:col], sel ? 2 : 1)
      spr(t[:spr], bx + 25, by + 6)
      rk = @ranks[i.to_s] || "-"
      tm = @times[i.to_s]
      tm_str = tm ? "#{tm}s" : "--"
      print_text("T#{i + 1} [#{rk}] #{tm_str}", bx + 41, by + 48, sel ? 10 : 7, 8, 1.0, :center, 0)
      i += 1
    end

    rectfill(140, 174, 200, 22, 0, 0.85)
    rect(140, 174, 200, 22, 12, 1)
    mode_str = @coop ? "MODE: 2P CO-OP RAID (X)" : "MODE: 1P SOLO RAID (X)"
    print_text(mode_str, 240, 181, 12, 8, 1.0, :center, 0)

    rectfill(140, 204, 200, 26, 1, 0.9)
    rect(140, 204, 200, 26, 10, 2)
    print_text("ENTER COLOSSEUM (Z)", 240, 213, 10, 8, 1.0, :center, 0)

    print_text("P1: WASD + MOUSE/Z: SHOOT + X: DODGE | P2: IJKL + U/O", 240, 246, 7, 8, 1.0, :center, 0)
  end
end

class RaidScene
  def initialize(opts)
    show_cursor(false)
    @idx = opts[:idx]
    @coop = opts[:coop]
    @spec = $titans[@idx]
    @w = $cfg[:w]
    @h = $cfg[:h]

    @scars = create_surface(@w, @h, :gpu)
    clear_surface(@scars, nil)
    @lightmap = create_surface(@w, @h, :gpu)

    @players = [make_player(0, 180.0, 210.0)]
    if @coop
      @players << make_player(1, 300.0, 210.0)
    end

    @boss = {
      x: 240.0, y: 92.0, vx: 0.0, vy: 0.0,
      hp: @spec[:hp], max_hp: @spec[:hp],
      flash: 0, state: :chase, state_t: 70,
      ang: 0.0, phase2: false
    }

    @p_shots = []
    @b_shots = []
    @particles = []
    @warnings = []
    @shake = 0.0
    @hitstop = 0
    @tick = 0
    @state = :play # :play, :win, :lose
    @saved = false
  end

  def make_player(idx, x, y)
    {
      idx: idx, x: x, y: y,
      hp: $cfg[:p_hp], max_hp: $cfg[:p_hp],
      dash_t: 0, dash_cd: 0, dvx: 0.0, dvy: 0.0,
      shot_cd: 0, inv_t: 0, aim_x: 0.0, aim_y: -1.0,
      alive: true
    }
  end

  def update
    @tick += 1
    if @hitstop > 0
      @hitstop -= 1
      return
    end
    @shake *= 0.85
    @shake = 0.0 if @shake < 0.2

    update_particles

    if @state != :play
      if btnp(1) || btnp(2) || btnp(:mouse_l)
        if @state == :win && @idx + 1 < $titans.size
          run RaidScene.new({ idx: @idx + 1, coop: @coop })
        else
          run TitleScene.new
        end
      end
      return
    end

    # Drop-in P2 anytime
    if !@coop && (btnp(1, 1) || btnp(:left, 1) || btnp(:right, 1))
      @coop = true
      @players << make_player(1, 240.0, 210.0)
    end

    @players.each { |pl| update_player(pl) }
    update_boss
    update_p_shots
    update_b_shots
    update_warnings

    any_alive = false
    @players.each { |pl| any_alive = true if pl[:alive] }
    if !any_alive
      @state = :lose
    end
  end

  def update_player(pl)
    return unless pl[:alive]
    pl[:dash_cd] -= 1 if pl[:dash_cd] > 0
    pl[:shot_cd] -= 1 if pl[:shot_cd] > 0
    pl[:inv_t] -= 1 if pl[:inv_t] > 0

    p = pl[:idx]
    dx = 0.0
    dy = 0.0
    dx -= 1.0 if btn(:left, p)
    dx += 1.0 if btn(:right, p)
    dy -= 1.0 if btn(:up, p)
    dy += 1.0 if btn(:down, p)
    if dx != 0.0 && dy != 0.0
      dx *= 0.7071
      dy *= 0.7071
    end

    if p == 0
      mx = mouse_x - pl[:x]
      my = mouse_y - pl[:y]
      d = sqrt(mx * mx + my * my)
      if d > 2.0
        pl[:aim_x] = mx / d
        pl[:aim_y] = my / d
      end
    else
      # P2 auto-aims at boss
      bx = @boss[:x] - pl[:x]
      by = @boss[:y] - pl[:y]
      d = sqrt(bx * bx + by * by)
      if d > 1.0
        pl[:aim_x] = bx / d
        pl[:aim_y] = by / d
      end
    end

    if pl[:dash_t] > 0
      pl[:dash_t] -= 1
      pl[:x] += pl[:dvx] * $cfg[:dash_spd]
      pl[:y] += pl[:dvy] * $cfg[:dash_spd]
      if @tick % 2 == 0
        render_to(@scars) do
          circfill(pl[:x], pl[:y] + 5, 2, p == 0 ? 12 : 11, 0.3)
        end
      end
    else
      if (btnp(2, p) || (p == 0 && btnp(:mouse_r))) && pl[:dash_cd] <= 0
        pl[:dash_t] = $cfg[:dash_frames]
        pl[:dash_cd] = $cfg[:dash_cd]
        pl[:inv_t] = $cfg[:dash_frames] + 2
        pl[:dvx] = (dx == 0.0 && dy == 0.0) ? pl[:aim_x] : dx
        pl[:dvy] = (dx == 0.0 && dy == 0.0) ? pl[:aim_y] : dy
        spawn_sparks(pl[:x], pl[:y], 12, 6)
      else
        pl[:x] += dx * $cfg[:p_spd]
        pl[:y] += dy * $cfg[:p_spd]
      end
    end

    ax = $cfg[:arena_x]
    ay = $cfg[:arena_y]
    pl[:x] = pl[:x].clamp(ax + 8.0, ax + $cfg[:arena_w] - 8.0)
    pl[:y] = pl[:y].clamp(ay + 8.0, ay + $cfg[:arena_h] - 8.0)

    shoot = btn(1, p) || (p == 0 && btn(:mouse_l))
    if shoot && pl[:shot_cd] <= 0
      pl[:shot_cd] = $cfg[:shot_cd]
      @p_shots << {
        x: pl[:x] + pl[:aim_x] * 8.0,
        y: pl[:y] + pl[:aim_y] * 8.0,
        vx: pl[:aim_x] * $cfg[:shot_spd],
        vy: pl[:aim_y] * $cfg[:shot_spd],
        col: p == 0 ? 12 : 11,
        life: 75
      }
    end
  end

  def update_boss
    b = @boss
    b[:flash] -= 1 if b[:flash] > 0
    b[:phase2] = true if b[:hp] <= b[:max_hp] * 0.5
    b[:state_t] -= 1

    # Pick target player
    target = @players[0]
    @players.each do |pl|
      target = pl if pl[:alive] && (!target[:alive] || rand() < 0.02)
    end

    if b[:state] == :chase
      ang = atan2(target[:y] - b[:y], target[:x] - b[:x])
      spd = @spec[:spd] * (b[:phase2] ? 1.25 : 1.0)
      b[:x] += cos(ang) * spd
      b[:y] += sin(ang) * spd
      if b[:state_t] <= 0
        pick = rand(3)
        if pick == 0
          b[:state] = :ring
          b[:state_t] = 40
        elsif pick == 1
          b[:state] = :slam
          b[:state_t] = 45
          @warnings << { x: target[:x], y: target[:y], r: 28, t: 38 }
        else
          b[:state] = :charge
          b[:state_t] = 32
          b[:vx] = cos(ang) * 3.8
          b[:vy] = sin(ang) * 3.8
        end
      end
    elsif b[:state] == :ring
      if b[:state_t] == 20
        cnt = b[:phase2] ? 16 : 12
        k = 0
        while k < cnt
          a = k * (6.283 / cnt) + @tick * 0.03
          @b_shots << { x: b[:x], y: b[:y], vx: cos(a) * 2.5, vy: sin(a) * 2.5, col: @spec[:col], life: 140 }
          k += 1
        end
        stamp_scar(b[:x], b[:y], 18, @spec[:col])
      end
      if b[:state_t] <= 0
        b[:state] = :chase
        b[:state_t] = b[:phase2] ? 55 : 75
      end
    elsif b[:state] == :slam
      if b[:state_t] <= 0
        b[:state] = :chase
        b[:state_t] = 65
      end
    elsif b[:state] == :charge
      b[:x] += b[:vx]
      b[:y] += b[:vy]
      if @tick % 3 == 0
        stamp_scar(b[:x], b[:y], 8, 5)
      end
      if b[:state_t] <= 0
        b[:state] = :chase
        b[:state_t] = 60
      end
    end

    ax = $cfg[:arena_x]
    ay = $cfg[:arena_y]
    b[:x] = b[:x].clamp(ax + 16.0, ax + $cfg[:arena_w] - 16.0)
    b[:y] = b[:y].clamp(ay + 16.0, ay + $cfg[:arena_h] - 16.0)

    # Contact damage
    @players.each do |pl|
      next unless pl[:alive] && pl[:inv_t] <= 0
      dx = pl[:x] - b[:x]
      dy = pl[:y] - b[:y]
      if dx * dx + dy * dy <= 400.0
        hurt_player(pl, 16)
      end
    end
  end

  def stamp_scar(x, y, r, col)
    render_to(@scars) do
      circfill(x, y, r, 0, 0.35)
      circ(x, y, r, col, 0.35)
    end
  end

  def update_warnings
    i = @warnings.size - 1
    while i >= 0
      wn = @warnings[i]
      wn[:t] -= 1
      if wn[:t] <= 0
        @shake = 5.0
        stamp_scar(wn[:x], wn[:y], wn[:r], 9)
        spawn_sparks(wn[:x], wn[:y], 9, 14)
        @players.each do |pl|
          next unless pl[:alive] && pl[:inv_t] <= 0
          dx = pl[:x] - wn[:x]
          dy = pl[:y] - wn[:y]
          if dx * dx + dy * dy <= wn[:r] * wn[:r]
            hurt_player(pl, 22)
          end
        end
        @warnings.delete_at(i)
      end
      i -= 1
    end
  end

  def update_p_shots
    b = @boss
    i = @p_shots.size - 1
    while i >= 0
      s = @p_shots[i]
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1
      dx = s[:x] - b[:x]
      dy = s[:y] - b[:y]
      if dx * dx + dy * dy <= 289.0
        b[:hp] -= $cfg[:shot_dmg]
        b[:flash] = 4
        spawn_sparks(s[:x], s[:y], 10, 4)
        @p_shots.delete_at(i)
        if b[:hp] <= 0
          b[:hp] = 0
          win_titan
          return
        end
      elsif s[:life] <= 0
        @p_shots.delete_at(i)
      end
      i -= 1
    end
  end

  def update_b_shots
    i = @b_shots.size - 1
    while i >= 0
      s = @b_shots[i]
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1
      hit = false
      @players.each do |pl|
        next unless pl[:alive] && pl[:inv_t] <= 0
        dx = pl[:x] - s[:x]
        dy = pl[:y] - s[:y]
        if dx * dx + dy * dy <= 64.0
          hurt_player(pl, 12)
          hit = true
          break
        end
      end
      if hit || s[:life] <= 0
        @b_shots.delete_at(i)
      end
      i -= 1
    end
  end

  def hurt_player(pl, dmg)
    pl[:hp] -= dmg
    pl[:inv_t] = 35
    @shake = 4.5
    @hitstop = 3
    spawn_sparks(pl[:x], pl[:y], 8, 8)
    if pl[:hp] <= 0
      pl[:hp] = 0
      pl[:alive] = false
    end
  end

  def win_titan
    @state = :win
    @shake = $cfg[:shake_max]
    @hitstop = 8
    stamp_scar(@boss[:x], @boss[:y], 36, 10)
    spawn_sparks(@boss[:x], @boss[:y], 10, 32)
    return if @saved
    @saved = true
    sec = @tick / 60
    rank = sec <= @spec[:s_sec] ? "S" : "A"
    ranks = save_get("ranks", {})
    ranks[@idx.to_s] = rank if ranks[@idx.to_s] != "S"
    save_set("ranks", ranks)

    times = save_get("times", {})
    prev = times[@idx.to_s]
    if prev.nil? || sec < prev.to_i
      times[@idx.to_s] = sec
      save_set("times", times)
    end
  end

  def spawn_sparks(x, y, col, cnt)
    k = 0
    while k < cnt
      a = rand() * 6.283
      sp = 1.0 + rand() * 3.0
      @particles << { x: x, y: y, vx: cos(a) * sp, vy: sin(a) * sp, col: col, life: 18 }
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

  def draw
    cls(0)
    sx = @shake > 0 ? (rand() * 2.0 - 1.0) * @shake : 0.0
    sy = @shake > 0 ? (rand() * 2.0 - 1.0) * @shake : 0.0
    bg(@spec[:bg], dim: 0.45, tint: @spec[:tint], scale: 1.04, scroll_x: sx * 0.3, y: sy * 0.3, mirror_x: true, mirror_y: true)

    camera(sx, sy)

    # Arena floor & persistent battle scars
    rectfill($cfg[:arena_x], $cfg[:arena_y], $cfg[:arena_w], $cfg[:arena_h], 1, 0.35)
    draw_surface(@scars, 0, 0)
    rect($cfg[:arena_x], $cfg[:arena_y], $cfg[:arena_w], $cfg[:arena_h], @spec[:col], 2)

    # Warnings
    @warnings.each do |wn|
      circ(wn[:x], wn[:y], wn[:r], 8, 0.8)
      circfill(wn[:x], wn[:y], wn[:r] * (1.0 - wn[:t] / 38.0), 8, 0.35)
    end

    # Boss (32x32)
    if @state != :win
      pal_id = @boss[:flash] > 0 ? 2 : nil
      spr(@spec[:spr], @boss[:x] - 16, @boss[:y] - 16, false, pal_id)
    end

    # Players
    @players.each do |pl|
      next unless pl[:alive]
      next if pl[:inv_t] > 0 && pl[:inv_t] % 4 < 2
      spr(pl[:idx] == 0 ? :p1 : :p2, pl[:x] - 8, pl[:y] - 8, pl[:aim_x] < 0)
    end

    # Shots
    @p_shots.each do |s|
      circfill(s[:x], s[:y], 3, s[:col])
      pset(s[:x], s[:y], 7)
    end
    @b_shots.each do |s|
      circfill(s[:x], s[:y], 4, s[:col])
      circfill(s[:x], s[:y], 2, 7)
    end

    blend(:add)
    @particles.each do |pt|
      circfill(pt[:x], pt[:y], 2, pt[:col], pt[:life] / 18.0)
    end
    blend(:normal)

    camera()
    clip()

    # Darkness phase lightmap for Abyss Kraken / Omega Colossus Phase 2
    if @spec[:dark] && (@idx == 3 || @boss[:phase2])
      render_to(@lightmap) do
        cls(0, 0.86)
        blend(:erase)
        @players.each do |pl|
          next unless pl[:alive]
          circfill(pl[:x], pl[:y], 68, 0, 0.45)
          circfill(pl[:x], pl[:y], 38, 0, 0.95)
        end
        circfill(@boss[:x], @boss[:y], 46, 0, 0.75)
        blend(:normal)
      end
      draw_surface(@lightmap, 0, 0)
    end

    # Custom Reticle (show_cursor(false))
    mx = mouse_x
    my = mouse_y
    circ(mx, my, 5, 10, 0.85)
    pset(mx, my, 7)

    draw_hud
  end

  def draw_hud
    rectfill(0, 0, @w, 28, 0, 0.85)
    print_text("T#{@idx + 1}: #{@spec[:name]}", 10, 5, @spec[:col], 8, 1.0, :left, 0)

    # Boss HP bar
    bw = 220
    bx = 130
    bh_w = (bw * @boss[:hp] / @boss[:max_hp]).to_i
    rectfill(bx, 6, bw, 8, 1)
    rectfill(bx, 6, bh_w, 8, @spec[:col])
    rect(bx, 6, bw, 8, 7)

    sec = @tick / 60
    print_text("#{sec}s", 470, 5, 7, 8, 1.0, :right, 0)

    # Player HP
    p1 = @players[0]
    print_text("P1 HP:#{p1[:hp]}", 10, 17, 12, 8, 1.0, :left, 0)
    if @coop && @players[1]
      print_text("P2 HP:#{@players[1][:hp]}", 470, 17, 11, 8, 1.0, :right, 0)
    end

    if @state == :win || @state == :lose
      rectfill(110, 84, 260, 92, 0, 0.90)
      rect(110, 84, 260, 92, @state == :win ? 10 : 8, 2)
      msg = @state == :win ? "TITAN VANQUISHED!" : "RAID FAILED..."
      print_text(msg, 240, 100, @state == :win ? 10 : 8, 16, 1.0, :center, 0)
      if @state == :win
        rk = sec <= @spec[:s_sec] ? "S" : "A"
        print_text("TIME: #{sec}s   RANK: #{rk}", 240, 126, 11, 8, 1.0, :center, 0)
      end
      print_text("PRESS Z / CLICK TO CONTINUE", 240, 150, 7, 8, 1.0, :center, 0)
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #000000
1: #161C30
2: #5A1E2E
5: #4A5468
6: #9BA4B8
7: #FFF1E8
8: #FF2E54
9: #FF9922
A: #FFEC27
B: #38E456
C: #29ADFF
D: #9B76FF
E: #FF44AA
F: #FFCCAA

@PALETTE 2
0: #FFFFFF
1: #FFFFFF
2: #FFFFFF
5: #FFFFFF
6: #FFFFFF
7: #FFFFFF
8: #FFFFFF
9: #FFFFFF
A: #FFFFFF
B: #FFFFFF
C: #FFFFFF
D: #FFFFFF
E: #FFFFFF
F: #FFFFFF

@SPRITE :p1 16x16 pal:1
................
.....111111.....
....1CCCCCC1....
...1CC7CC7CC1...
...1FFFFFFFF1...
....11CCCC11....
...1CCCCCCCC1...
..1C1CCCCCC1C1..
....11CCCC11....
....1CC11CC1....
....1CC11CC1....
....111..111....
................
................
................
................

@SPRITE :p2 16x16 pal:1
................
.....111111.....
....1BBBBBB1....
...1BB7BB7BB1...
...1FFFFFFFF1...
....11BBBB11....
...1BBBBBBBB1...
..1B1BBBBBB1B1..
....11BBBB11....
....1BB11BB1....
....1BB11BB1....
....111..111....
................
................
................
................

@SPRITE :golem 32x32 pal:1
................................
.........11111111111111.........
.......116666666666666611.......
......16666666666666666661......
.....1665556666666666555661.....
.....1658856666666666588561.....
.....1655566655555566655561.....
....116666666555555666666611....
...16666666666666666666666661...
..1666166666666666666666166661..
..1661.16665555555555661.16661..
..1661.16665666666665661.16661..
..1551.16665555555555661.15551..
..1551.16666666666666661.15551..
...11...166666111166661...111...
........166661....16661.........
........155551....15551.........
........155551....15551.........
.......1155551....155511........
.......1666661....166661........
.......1111111....111111........
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
................................

@SPRITE :wyrm 32x32 pal:1
................................
..........111111111111..........
........1199999999999911........
.......1999AA999999AA9991.......
......1999A7A999999A7A9991......
.....1999999999999999999991.....
.....1998899999999999988991.....
....119999999988889999999911....
...19999199999999999991999991...
..19991..19999AAAA9991..199991..
.1991.....199AAAAAA91.....19991.
.181......1999AAAA991......1881.
..........19999999991...........
...........199888891............
............1999991.............
.............19991..............
..............191...............
...............1................
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
................................
................................
................................
................................

@SPRITE :valkyrie 32x32 pal:1
................................
...........1111111111...........
..........1CCCCCCCCCC1..........
.........1CC7CCCCCC7CC1.........
.........1CCCCCCCCCCCC1.........
...111....11CCCCCCCC11....111...
..177711...1CCCCCCCC1...117771..
.17CCCCC111CCCCCCCCCC111CCCCC71.
.17CCCCCCCCCCCCCCCCCCCCCCCCCC71.
..1CCCCCCCCCC777777CCCCCCCCCC1..
...11CCCCCCCC77CC77CCCCCCCC11...
.....11CCCCCC77CC77CCCCCC11.....
.......11CCCC777777CCCC11.......
.........11CCCCCCCCCC11.........
...........1CCC11CCC1...........
...........1CCC11CCC1...........
...........1111..1111...........
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
................................
................................
................................
................................
................................

@SPRITE :kraken 32x32 pal:1
................................
..........111111111111..........
........11EEEEEEEEEEEE11........
.......1EEEEEEEEEEEEEEEE1.......
......1EEEEEEEEEEEEEEEEEE1......
......1EEE77EEEEEEEE77EEE1......
......1EEE7AEEEEEEEE7AEEE1......
......1EEEEEEEEEEEEEEEEEE1......
.......1EEEE11111111EEEE1.......
........11EEEEEEEEEEEE11........
.....111..1EEEEEEEEEE1..111.....
....1EEE1.1EE1EEEE1EE1.1EEE1....
...1EE1...1E1.1EE1.1E1...1EE1...
..1EE1...1E1..1EE1..1E1...1EE1..
..1E1....11...1EE1...11....1E1..
...............11...............
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
................................
................................
................................
................................
................................
................................

@SPRITE :omega 32x32 pal:1
................................
.........11111111111111.........
.......11AAAAAAAAAAAAAA11.......
......1AAAAAAAAAAAAAAAAAA1......
.....1AA88AAAAAAAAAAAA88AA1.....
.....1AA87AAAAAAAAAAAA78AA1.....
.....1AAAAAAAAAAAAAAAAAAAA1.....
....11AAAA111111111111AAAA11....
...1AAAAAA1CCCCCCCCCC1AAAAAA1...
..1AAA1AAA1CC77CC77CC1AAA1AAA1..
..1AA1.1AA1CCCCCCCCCC1AA1.1AA1..
..1A1..1AA111111111111AA1..1A1..
.......1AAAAAAAAAAAAAAAA1.......
........1AAAAAA11AAAAAA1........
........1AAAAA1..1AAAAA1........
........11AAA1....1AAA11........
.........1111......1111.........
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
................................
................................
................................
................................
................................
