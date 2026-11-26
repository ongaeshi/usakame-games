config(
  title: "CYBER DISC DUEL",
  width: 320,
  height: 240,
  save_id: "cyber_disc_duel",
  save_salt: "p3g45e2a"
)

$cfg = {
  w: 320,
  h: 240,
  court_x: 16,
  court_y: 34,
  court_w: 288,
  court_h: 190,
  net_x: 160,
  win_score: 15,
  player_spd: 2.0,
  dash_spd: 4.5,
  dash_frames: 12,
  dash_cd: 28,
  disc_spd: 3.6,
  hyper_spd: 5.4,
  curve_accel: 0.085,
  shake_max: 7.0
}

$rivals = [
  { name: "VOLT-01", spd: 1.45, react: 0.14, curve_p: 0.30, col: 14 },
  { name: "BLAZE-X", spd: 1.75, react: 0.22, curve_p: 0.55, col: 9 },
  { name: "PHANTOM", spd: 2.00, react: 0.30, curve_p: 0.75, col: 13 },
  { name: "OMEGA", spd: 2.25, react: 0.42, curve_p: 0.90, col: 8 }
]

class TitleScene
  def initialize
    @mode = 0 # 0: 1P Cup, 1: 2P Duel
    @cup_wins = save_get("cup_wins", 0).to_i
    @total_goals = save_get("total_goals", 0).to_i
    @tick = 0
  end

  def update
    @tick += 1
    if btnp(2) || btnp(3)
      @mode = 1 - @mode
    end
    if btnp(:mouse_l)
      my = mouse_y
      if my >= 100 && my <= 126
        @mode = 0
        run DuelScene.new({ mode: :cup, stage: 0 })
        return
      elsif my >= 132 && my <= 158
        @mode = 1
        run DuelScene.new({ mode: :duel, stage: 0 })
        return
      end
    end
    if btnp(4) || btnp(5)
      run DuelScene.new({ mode: @mode == 0 ? :cup : :duel, stage: 0 })
    end
  end

  def draw
    cls(0)
    bg(:cyber, dim: 0.45, tint: "#3060FF", scroll_x: @tick * 0.4, mirror_x: true)

    spr(:p1, 56, 56)
    spr(:p2, 248, 56, true)
    circfill(160 + cos(@tick * 0.08) * 60, 64, 5, 10)

    print_text("CYBER DISC DUEL", 160, 22, 10, 16, 1.0, :center, 0, 2)
    pads = gamepad_count
    print_text("CUP WINS: #{@cup_wins}  GOALS: #{@total_goals}  PADS: #{pads}", 160, 78, 12, 8, 1.0, :center, 0)

    c0 = @mode == 0 ? 10 : 6
    rectfill(50, 100, 220, 24, @mode == 0 ? 1 : 0, 0.85)
    rect(50, 100, 220, 24, c0, 2)
    print_text("1P ARCADE CUP (4 RIVALS)", 160, 108, c0, 8, 1.0, :center, 0)

    c1 = @mode == 1 ? 10 : 6
    rectfill(50, 132, 220, 24, @mode == 1 ? 1 : 0, 0.85)
    rect(50, 132, 220, 24, c1, 2)
    print_text("2P LOCAL DUEL (IJKL+U/O)", 160, 140, c1, 8, 1.0, :center, 0)

    print_text("P1: WASD/ARROWS + Z(THROW) + X(DASH)", 160, 184, 7, 8, 1.0, :center, 0)
    print_text("HOLD UP/DOWN WHEN THROWING TO CURVE!", 160, 200, 11, 8, 1.0, :center, 0)
    print_text("DASH CATCH = HYPER SMASH!", 160, 214, 9, 8, 1.0, :center, 0)
  end
end

class DuelScene
  def initialize(opts)
    @mode = opts[:mode]
    @stage = opts[:stage]
    @rival = $rivals[@stage]

    @cx = $cfg[:court_x]
    @cy = $cfg[:court_y]
    @cw = $cfg[:court_w]
    @ch = $cfg[:court_h]
    @nx = $cfg[:net_x]

    @decal = create_surface($cfg[:w], $cfg[:h], :gpu)
    clear_surface(@decal, nil)

    @p1 = make_player(0, 44.0, @cy + @ch * 0.5, false)
    @p2 = make_player(1, 276.0, @cy + @ch * 0.5, @mode == :cup)

    @disc = {
      x: @nx.to_f, y: @cy + @ch * 0.5,
      vx: -2.6, vy: 1.2, curve: 0.0,
      hyper: false, holder: nil, hold_t: 0,
      trail: []
    }

    @s1 = 0
    @s2 = 0
    @particles = []
    @banner = @mode == :cup ? "STAGE #{@stage + 1}: #{@rival[:name]}" : "2P CYBER DUEL!"
    @banner_t = 90
    @shake = 0.0
    @hitstop = 0
    @tick = 0
    @done = false
    @winner = nil
  end

  def make_player(idx, x, y, is_cpu)
    {
      idx: idx, x: x, y: y, is_cpu: is_cpu,
      dash_t: 0, dash_cd: 0, dvx: 0.0, dvy: 0.0
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
    @banner_t -= 1 if @banner_t > 0

    update_particles

    if @done
      if btnp(4) || btnp(5) || btnp(:mouse_l)
        if @mode == :cup && @winner == 0 && @stage + 1 < $rivals.size
          run DuelScene.new({ mode: :cup, stage: @stage + 1 })
        else
          run TitleScene.new
        end
      end
      return
    end

    update_player(@p1)
    update_player(@p2)
    update_disc
  end

  def update_player(pl)
    pl[:dash_cd] -= 1 if pl[:dash_cd] > 0
    holding = (@disc[:holder] == pl[:idx])

    dx = 0.0
    dy = 0.0
    dash_press = false
    throw_press = false

    if !pl[:is_cpu]
      p = pl[:idx]
      dx -= 1.0 if btn(0, p)
      dx += 1.0 if btn(1, p)
      dy -= 1.0 if btn(2, p)
      dy += 1.0 if btn(3, p)
      throw_press = btnp(4, p) || (p == 0 && btnp(:mouse_l))
      dash_press = btnp(5, p)
    else
      # CPU AI
      if holding
        if @disc[:hold_t] <= 12
          dy = rand() < 0.5 ? -1.0 : 1.0
          throw_press = true
        end
      else
        tx = @disc[:vx] > 0 ? [@disc[:x] + 18.0, @nx + 20.0].max : 268.0
        ty = @disc[:y]
        dx = (tx - pl[:x]).clamp(-1.0, 1.0) * @rival[:react] * 4.0
        dy = (ty - pl[:y]).clamp(-1.0, 1.0) * @rival[:react] * 4.0
        if (@disc[:y] - pl[:y]).abs > 26 && @disc[:vx] > 2.5 && pl[:dash_cd] <= 0 && rand() < 0.08
          dash_press = true
        end
      end
    end

    if dx != 0.0 || dy != 0.0
      d = sqrt(dx * dx + dy * dy)
      if d > 1.0
        dx /= d
        dy /= d
      end
    end

    if pl[:dash_t] > 0
      pl[:dash_t] -= 1
      pl[:x] += pl[:dvx] * $cfg[:dash_spd]
      pl[:y] += pl[:dvy] * $cfg[:dash_spd]
      # Dash skid decal
      if @tick % 2 == 0
        col = pl[:idx] == 0 ? 12 : 14
        render_to(@decal) do
          circfill(pl[:x], pl[:y] + 5, 2, col, 0.35)
        end
      end
    elsif !holding
      if dash_press && pl[:dash_cd] <= 0 && (dx != 0.0 || dy != 0.0)
        pl[:dash_t] = $cfg[:dash_frames]
        pl[:dash_cd] = $cfg[:dash_cd]
        pl[:dvx] = dx
        pl[:dvy] = dy
        spawn_sparks(pl[:x], pl[:y], pl[:idx] == 0 ? 12 : 14, 6)
      else
        spd = pl[:is_cpu] ? @rival[:spd] : $cfg[:player_spd]
        pl[:x] += dx * spd
        pl[:y] += dy * spd
      end
    end

    # Clamp to own half
    if pl[:idx] == 0
      pl[:x] = pl[:x].clamp(@cx + 10.0, @nx - 10.0)
    else
      pl[:x] = pl[:x].clamp(@nx + 10.0, @cx + @cw - 10.0)
    end
    pl[:y] = pl[:y].clamp(@cy + 10.0, @cy + @ch - 10.0)

    # Throw if holding
    if holding
      @disc[:hold_t] -= 1
      if throw_press || @disc[:hold_t] <= 0
        throw_disc(pl, dy)
      end
    end
  end

  def throw_disc(pl, aim_y)
    dir = pl[:idx] == 0 ? 1.0 : -1.0
    spd = @disc[:hyper] ? $cfg[:hyper_spd] : $cfg[:disc_spd]
    ang = aim_y * 0.48
    @disc[:vx] = dir * cos(ang) * spd
    @disc[:vy] = sin(ang) * spd
    @disc[:curve] = aim_y * $cfg[:curve_accel]
    @disc[:holder] = nil
    @shake = @disc[:hyper] ? 4.5 : 1.8
    if @disc[:hyper]
      @banner = "HYPER SMASH!"
      @banner_t = 35
    end
    spawn_sparks(pl[:x], pl[:y], @disc[:hyper] ? 10 : 7, 8)
  end

  def update_disc
    if @disc[:holder] != nil
      pl = @disc[:holder] == 0 ? @p1 : @p2
      @disc[:x] = pl[:x] + (pl[:idx] == 0 ? 10.0 : -10.0)
      @disc[:y] = pl[:y]
      @disc[:trail].clear
      return
    end

    @disc[:trail] << [@disc[:x], @disc[:y]]
    @disc[:trail].shift if @disc[:trail].size > 10

    @disc[:vy] += @disc[:curve]
    @disc[:x] += @disc[:vx]
    @disc[:y] += @disc[:vy]

    # Top/bottom wall bounce + scorch decal
    if @disc[:y] <= @cy + 4.0
      @disc[:y] = @cy + 4.0
      @disc[:vy] = @disc[:vy].abs
      @disc[:curve] = -@disc[:curve] * 0.5
      stamp_bounce(@disc[:x], @cy + 2)
    elsif @disc[:y] >= @cy + @ch - 4.0
      @disc[:y] = @cy + @ch - 4.0
      @disc[:vy] = -@disc[:vy].abs
      @disc[:curve] = -@disc[:curve] * 0.5
      stamp_bounce(@disc[:x], @cy + @ch - 2)
    end

    # Catch check
    [@p1, @p2].each do |pl|
      dx = pl[:x] - @disc[:x]
      dy = pl[:y] - @disc[:y]
      catch_r = pl[:dash_t] > 0 ? 16.0 : 12.0
      if dx * dx + dy * dy <= catch_r * catch_r
        @disc[:holder] = pl[:idx]
        @disc[:hold_t] = 30
        @disc[:hyper] = (pl[:dash_t] > 0)
        @hitstop = @disc[:hyper] ? 4 : 2
        spawn_sparks(@disc[:x], @disc[:y], @disc[:hyper] ? 10 : 12, 8)
        return
      end
    end

    # Goal check
    if @disc[:x] <= @cx + 2.0
      score_goal(1)
    elsif @disc[:x] >= @cx + @cw - 2.0
      score_goal(0)
    end
  end

  def stamp_bounce(bx, by)
    render_to(@decal) do
      circfill(bx, by, 4, @disc[:hyper] ? 9 : 12, 0.5)
    end
    spawn_sparks(bx, by, 10, 5)
  end

  def score_goal(scorer)
    gy = @disc[:y]
    # Center zone = 3 pts, corner zones = 5 pts!
    pts = (gy - (@cy + @ch * 0.5)).abs > 48.0 ? 5 : 3
    if scorer == 0
      @s1 += pts
      save_set("total_goals", save_get("total_goals", 0).to_i + 1)
    else
      @s2 += pts
    end

    @shake = $cfg[:shake_max]
    @hitstop = 6
    @banner = "GOAL! +#{pts} PTS"
    @banner_t = 55

    gx = scorer == 0 ? @cx + @cw - 4 : @cx + 4
    render_to(@decal) do
      circfill(gx, gy, 16, scorer == 0 ? 12 : 14, 0.45)
      circ(gx, gy, 20, 7, 0.4)
    end
    spawn_sparks(gx, gy, 10, 18)

    if @s1 >= $cfg[:win_score] || @s2 >= $cfg[:win_score]
      @done = true
      @winner = @s1 >= $cfg[:win_score] ? 0 : 1
      if @mode == :cup && @winner == 0 && @stage + 1 == $rivals.size
        save_set("cup_wins", save_get("cup_wins", 0).to_i + 1)
      end
    else
      # Reset disc serve
      @disc[:x] = @nx.to_f
      @disc[:y] = @cy + @ch * 0.5
      @disc[:vx] = scorer == 0 ? -2.6 : 2.6
      @disc[:vy] = (rand() - 0.5) * 2.0
      @disc[:curve] = 0.0
      @disc[:hyper] = false
      @disc[:holder] = nil
    end
  end

  def spawn_sparks(x, y, col, cnt)
    k = 0
    while k < cnt
      a = rand() * 6.283
      sp = 1.0 + rand() * 3.0
      @particles << { x: x, y: y, vx: cos(a) * sp, vy: sin(a) * sp, col: col, life: 16 }
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
    bg(:cyber, dim: 0.50, tint: "#204080", scale: 1.04, scroll_x: sx * 0.3, y: sy * 0.3, mirror_x: true, mirror_y: true)

    camera(sx, sy)

    # Court surface & persistent scorch decals
    rectfill(@cx, @cy, @cw, @ch, 1, 0.45)
    draw_surface(@decal, 0, 0)

    # Court lines & 5pt/3pt goal zones
    rect(@cx, @cy, @cw, @ch, 12, 2)
    line(@nx, @cy, @nx, @cy + @ch, 6, 2, 0.7)
    circ(@nx, @cy + @ch * 0.5, 22, 6, 0.5)

    # Goal markers
    rectfill(@cx - 3, @cy, 4, 47, 10)
    rectfill(@cx - 3, @cy + 47, 4, 96, 14)
    rectfill(@cx - 3, @cy + 143, 4, 47, 10)

    rectfill(@cx + @cw - 1, @cy, 4, 47, 10)
    rectfill(@cx + @cw - 1, @cy + 47, 4, 96, 12)
    rectfill(@cx + @cw - 1, @cy + 143, 4, 47, 10)

    # Players
    spr(:p1, @p1[:x] - 8, @p1[:y] - 8, false)
    spr(:p2, @p2[:x] - 8, @p2[:y] - 8, true)

    # Disc & trail
    tr = @disc[:trail]
    if tr.size >= 2
      polyline(tr, @disc[:hyper] ? 9 : 10, @disc[:hyper] ? 4 : 2, 0.7)
    end
    circfill(@disc[:x], @disc[:y], 5, @disc[:hyper] ? 9 : 10)
    circfill(@disc[:x], @disc[:y], 2, 7)

    blend(:add)
    @particles.each do |pt|
      circfill(pt[:x], pt[:y], 2, pt[:col], pt[:life] / 16.0)
    end
    blend(:normal)

    camera()
    clip()
    draw_hud
  end

  def draw_hud
    rectfill(0, 0, 320, 28, 0, 0.8)
    print_text("P1: #{@s1}", 14, 7, 12, 16, 1.0, :left, 0)
    p2_name = @mode == :cup ? @rival[:name] : "P2"
    print_text("#{p2_name}: #{@s2}", 306, 7, 14, 16, 1.0, :right, 0)
    print_text("FIRST TO #{$cfg[:win_score]}", 160, 10, 7, 8, 1.0, :center, 0)

    if @banner_t > 0 && !@done
      print_text(@banner, 160, 110, 10, 16, 1.0, :center, 0, 2)
    end

    if @done
      rectfill(50, 74, 220, 88, 0, 0.90)
      rect(50, 74, 220, 88, 10, 2)
      msg = @winner == 0 ? "PLAYER 1 WINS!" : (@mode == :cup ? "#{@rival[:name]} WINS!" : "PLAYER 2 WINS!")
      print_text(msg, 160, 90, @winner == 0 ? 12 : 14, 16, 1.0, :center, 0)
      sub = (@mode == :cup && @winner == 0 && @stage + 1 < $rivals.size) ? "PRESS Z FOR NEXT RIVAL" : "PRESS Z FOR TITLE"
      print_text(sub, 160, 128, 7, 8, 1.0, :center, 0)
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #000000
1: #161C30
7: #FFF1E8
9: #FF8822
A: #FFEC27
C: #29ADFF
E: #FF44AA
F: #FFCCAA

@SPRITE :p1 16x16 pal:1
................
.....111111.....
....1CCCCCC1....
...1CC7CC7CC1...
...1FFFFFFFF1...
....11CCCC11....
...1CCCCCCCC1...
..1C1CCCCCC1C1..
..1..CCCCCC..1..
....11CCCC11....
....1CC11CC1....
....1CC11CC1....
....111..111....
................
................
................

@SPRITE :p2 16x16 pal:1
................
.....111111.....
....1EEEEEE1....
...1EE7EE7EE1...
...1FFFFFFFF1...
....11EEEE11....
...1EEEEEEEE1...
..1E1EEEEEE1E1..
..1..EEEEEE..1..
....11EEEE11....
....1EE11EE1....
....1EE11EE1....
....111..111....
................
................
................
