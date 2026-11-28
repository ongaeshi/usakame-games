config(
  title: "CYBER PINBALL SYMPHONY DX",
  width: 480,
  height: 270,
  save_id: "cyber_pinball_dx",
  save_salt: "p4g59cp9"
)

$cfg = {
  w: 480,
  h: 270,
  tbl_l: 40.0,
  tbl_r: 280.0,
  tbl_t: 16.0,
  tbl_b: 262.0,
  grav: 0.088,
  substeps: 4,
  ball_r: 4.5,
  flipper_len: 36.0,
  start_balls: 3
}

$bumpers = [
  { x: 112.0, y: 82.0, r: 12.0, col: 12, pts: 150 },
  { x: 184.0, y: 82.0, r: 12.0, col: 14, pts: 150 },
  { x: 148.0, y: 124.0, r: 14.0, col: 10, pts: 250 },
  { x: 84.0, y: 130.0, r: 9.0, col: 11, pts: 100 },
  { x: 212.0, y: 130.0, r: 9.0, col: 11, pts: 100 }
]

class TitleScene
  def initialize
    @hi = save_get("hi_score", 0)
    @max_combo = save_get("max_combo", 0)
    @tick = 0
    music(:table_bgm, true, 0.65)
  end

  def update
    @tick += 1
    if btnp(1) || btnp(2) || btnp(:mouse_l) || btnp(:space)
      sfx(:confirm)
      run PinballScene.new
    end
  end

  def draw
    cls(0)
    bg(:cyber, dim: 0.45, tint: "#6830B8", scroll_y: -@tick * 0.45, mirror_y: true)

    blend(:add)
    i = 0
    while i < 5
      b = $bumpers[i]
      r = b[:r] + (sin(@tick * 0.1 + i) * 3).to_i
      circ(b[:x] + 92, b[:y] + 68, r, b[:col], 0.55)
      i += 1
    end
    blend(:normal)

    print_text("CYBER PINBALL SYMPHONY DX", 240, 22, 10, 16, 1.0, :center, 0, 2)
    print_text("WIDE CABINET EDITION WITH DMD & MULTIBALL", 240, 46, 12, 8, 1.0, :center, 0)

    rectfill(110, 74, 260, 64, 0, 0.82)
    rect(110, 74, 260, 64, 12, 1)
    print_text("LEFT / Z   : LEFT FLIPPER", 240, 84, 7, 8, 1.0, :center, 0)
    print_text("RIGHT / X  : RIGHT FLIPPER", 240, 98, 7, 8, 1.0, :center, 0)
    print_text("SPACE/DOWN : LAUNCH   UP : NUDGE", 240, 112, 10, 8, 1.0, :center, 0)

    print_text("HIGH SCORE: #{@hi}   BEST COMBO: x#{@max_combo}", 240, 160, 11, 8, 1.0, :center, 0)

    rectfill(140, 192, 200, 26, 2, 0.92)
    rect(140, 192, 200, 26, 10, 2)
    print_text("INSERT COIN / PLAY (Z)", 240, 201, 10, 8, 1.0, :center, 0)
  end
end

class PinballScene
  def initialize
    @w = $cfg[:w]
    @h = $cfg[:h]
    @tl = $cfg[:tbl_l]
    @tr = $cfg[:tbl_r]
    @tt = $cfg[:tbl_t]
    @tb = $cfg[:tbl_b]

    # Rotating roulette wheel surface (36x36)
    @roulette_surf = create_surface(36, 36, :gpu)
    build_roulette_surface
    @roulette_ang = 0.0

    # Neon lightmap overlay for table glow
    @glow_surf = create_surface(300, @h, :gpu)

    @score = 0
    @balls_left = $cfg[:start_balls]
    @combo = 0
    @max_combo = 0
    @combo_t = 0
    @mult = 1
    @tick = 0
    @shake = 0.0
    @nudge_cd = 0

    @dmd_msg = "CYBER SYMPHONY!"
    @dmd_col = 10
    @dmd_t = 120

    @l_ang = 0.42
    @r_ang = Math::PI - 0.42
    @l_prev = @l_ang
    @r_prev = @r_ang

    @targets = [
      { x: 54, y: 74, w: 6, h: 16, hit: false },
      { x: 54, y: 96, w: 6, h: 16, hit: false },
      { x: 54, y: 118, w: 6, h: 16, hit: false }
    ]

    @bumper_flash = [0, 0, 0, 0, 0]
    @balls = []
    @particles = []
    @popups = []
    @multiball_bgm = false
    @state = :play
    @state_t = 0

    spawn_ball(true)
    music(:table_bgm, true, 0.68)
  end

  def build_roulette_surface
    render_to(@roulette_surf) do
      cls(nil)
      circfill(18, 18, 16, 1)
      circ(18, 18, 16, 12)
      trifill(18, 18, 18, 2, 30, 8, 8)
      trifill(18, 18, 30, 28, 18, 34, 10)
      trifill(18, 18, 6, 28, 6, 8, 11)
      circfill(18, 18, 5, 7)
    end
  end

  def spawn_ball(in_lane = false)
    if in_lane
      @balls << { x: 266.0, y: 226.0, vx: 0.0, vy: 0.0, lane: true, trail: [] }
    else
      @balls << { x: 160.0 + rand(20) - 10, y: 48.0, vx: (rand - 0.5) * 2.5, vy: 1.5, lane: false, trail: [] }
    end
  end

  def set_dmd(msg, col = 10, t = 90)
    @dmd_msg = msg
    @dmd_col = col
    @dmd_t = t
  end

  def update
    if @state == :gameover
      @state_t += 1
      if @state_t > 35 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        run TitleScene.new
      end
      return
    end

    @tick += 1
    @roulette_ang = (@roulette_ang + 2.2) % 360.0
    @shake *= 0.82
    @shake = 0.0 if @shake < 0.2
    @nudge_cd -= 1 if @nudge_cd > 0
    @dmd_t -= 1 if @dmd_t > 0
    if @combo_t > 0
      @combo_t -= 1
      @combo = 0 if @combo_t <= 0
    end

    i = 0
    while i < @bumper_flash.size
      @bumper_flash[i] -= 1 if @bumper_flash[i] > 0
      i += 1
    end

    # Flipper controls
    @l_prev = @l_ang
    @r_prev = @r_ang
    l_up = btn(:left) || btn(1) || btn(:mouse_l)
    r_up = btn(:right) || btn(2) || btn(:mouse_l)
    @l_ang += ((l_up ? -0.52 : 0.42) - @l_ang) * 0.45
    @r_ang += ((r_up ? Math::PI + 0.52 : Math::PI - 0.42) - @r_ang) * 0.45

    if btnp(:left) || btnp(1)
      sfx(:flipper, -1, 0.45, 1.1)
    end
    if btnp(:right) || btnp(2)
      sfx(:flipper, -1, 0.45, 1.0)
    end

    # Launch ball from plunger lane
    if btnp(:down) || btnp(:space) || btnp(:mouse_l) || btnp(1) || btnp(2)
      i = 0
      while i < @balls.size
        b = @balls[i]
        if b[:lane]
          b[:lane] = false
          b[:vy] = -10.8 - rand * 1.4
          b[:vx] = -0.35
          sfx(:launch, -1, 0.8, 1.0)
          set_dmd("BALL LAUNCHED!", 12, 70)
        end
        i += 1
      end
    end

    # Table nudge
    if btnp(:up) && @nudge_cd <= 0
      @nudge_cd = 35
      @shake = 4.0
      sfx(:step, -1, 0.6, 0.7)
      i = 0
      while i < @balls.size
        @balls[i][:vy] -= 1.2 unless @balls[i][:lane]
        i += 1
      end
    end

    step_physics
    update_fx

    # Dynamic Multiball BGM switch!
    if @balls.size >= 2 && !@multiball_bgm
      @multiball_bgm = true
      music(:multiball_bgm, true, 0.72)
    elsif @balls.size < 2 && @multiball_bgm
      @multiball_bgm = false
      music(:table_bgm, true, 0.68)
    end
  end

  def step_physics
    sub = $cfg[:substeps]
    dt = 1.0 / sub
    grav = $cfg[:grav] * dt
    br = $cfg[:ball_r]

    s = 0
    while s < sub
      i = @balls.size - 1
      while i >= 0
        b = @balls[i]
        unless b[:lane]
          b[:vy] += grav
          b[:x] += b[:vx] * dt
          b[:y] += b[:vy] * dt

          # Cap speed
          sp = hypot(b[:vx], b[:vy])
          if sp > 8.5
            b[:vx] = (b[:vx] / sp) * 8.5
            b[:vy] = (b[:vy] / sp) * 8.5
          end

          # Top & side walls (divider wall at x=256 below y=72)
          if b[:x] < @tl + br
            b[:x] = @tl + br
            b[:vx] = b[:vx].abs * 0.85
          elsif b[:x] > 256.0 - br && b[:y] > 64.0
            b[:x] = 256.0 - br
            b[:vx] = -b[:vx].abs * 0.85
          elsif b[:x] > @tr - br
            b[:x] = @tr - br
            b[:vx] = -b[:vx].abs * 0.85
          end

          if b[:y] < @tt + br
            b[:y] = @tt + br
            b[:vy] = b[:vy].abs * 0.85
          end

          # Curved top right arch guide
          if b[:y] < 64.0 && b[:x] > 236.0
            b[:vx] -= 0.14 * dt
          end

          # Slingshot / drain funnels
          if b[:y] > 210.0 && b[:x] < 98.0
            ny = 210.0 + (b[:x] - @tl) * 0.58
            if b[:y] > ny - br
              b[:y] = ny - br
              b[:vx] += 0.45 * dt
              b[:vy] = -b[:vy].abs * 0.55
            end
          elsif b[:y] > 210.0 && b[:x] > 198.0 && b[:x] < 256.0
            ny = 210.0 + (256.0 - b[:x]) * 0.58
            if b[:y] > ny - br
              b[:y] = ny - br
              b[:vx] -= 0.45 * dt
              b[:vy] = -b[:vy].abs * 0.55
            end
          end

          # Bumpers
          bi = 0
          while bi < $bumpers.size
            bm = $bumpers[bi]
            dx = b[:x] - bm[:x]
            dy = b[:y] - bm[:y]
            d = hypot(dx, dy)
            min_d = br + bm[:r]
            if d < min_d && d > 0.01
              nx = dx / d
              ny = dy / d
              b[:x] = bm[:x] + nx * min_d
              b[:y] = bm[:y] + ny * min_d
              b[:vx] = nx * 4.6
              b[:vy] = ny * 4.6
              on_bumper_hit(bi, bm, b)
            end
            bi += 1
          end

          # Central Roulette spin bonus (148, 174)
          rdx = b[:x] - 148.0
          rdy = b[:y] - 174.0
          if rdx * rdx + rdy * rdy < 260.0 && (@tick % 12 == 0)
            b[:vx] += cos(@roulette_ang * 0.01745) * 0.65
            b[:vy] += sin(@roulette_ang * 0.01745) * 0.45
            @score += 25 * @mult
          end

          # Drop Targets
          ti = 0
          all_hit = true
          while ti < @targets.size
            tg = @targets[ti]
            if !tg[:hit]
              if b[:x] > tg[:x] - br && b[:x] < tg[:x] + tg[:w] + br && b[:y] > tg[:y] - br && b[:y] < tg[:y] + tg[:h] + br
                tg[:hit] = true
                b[:vx] = b[:vx].abs + 1.5
                @score += 500 * @mult
                sfx(:powerup, -1, 0.8, 1.2)
                spawn_sparks(tg[:x] + 3, tg[:y] + 8, 11, 10)
                set_dmd("TARGET DOWN!", 11, 70)
              else
                all_hit = false
              end
            end
            ti += 1
          end

          if all_hit
            @targets.each { |tg| tg[:hit] = false }
            @mult = (@mult + 1).clamp(1, 5)
            @score += 2000
            if @balls.size < 3
              spawn_ball(false)
              set_dmd("MULTIBALL x#{@balls.size}!", 14, 120)
              sfx(:clear, -1, 0.85, 1.1)
            else
              set_dmd("JACKPOT +2000!", 10, 100)
              sfx(:bell, -1, 0.9, 1.4)
            end
          end

          # Flippers
          collide_flipper(b, 98.0, 240.0, @l_ang, @l_ang - @l_prev)
          collide_flipper(b, 198.0, 240.0, @r_ang, @r_ang - @r_prev)

          # Drain check
          if b[:y] > @tb + 10.0
            @balls.delete_at(i)
            if @balls.empty?
              @balls_left -= 1
              @mult = 1
              @combo = 0
              if @balls_left <= 0
                trigger_gameover
                return
              else
                sfx(:cancel, -1, 0.7, 0.8)
                set_dmd("BALLS LEFT: #{@balls_left}", 8, 90)
                spawn_ball(true)
              end
            end
          end
        end
        i -= 1
      end
      s += 1
    end

    # Record trails once per frame
    i = 0
    while i < @balls.size
      b = @balls[i]
      b[:trail] << [b[:x], b[:y]]
      b[:trail].shift if b[:trail].size > 10
      i += 1
    end
  end

  def collide_flipper(b, fx, fy, ang, ang_vel)
    len = $cfg[:flipper_len]
    ex = fx + cos(ang) * len
    ey = fy + sin(ang) * len
    vx = ex - fx
    vy = ey - fy
    l2 = vx * vx + vy * vy
    t = (((b[:x] - fx) * vx + (b[:y] - fy) * vy) / l2).clamp(0.0, 1.0)
    cx = fx + t * vx
    cy = fy + t * vy
    dx = b[:x] - cx
    dy = b[:y] - cy
    d = hypot(dx, dy)
    min_d = $cfg[:ball_r] + 3.5
    if d < min_d && d > 0.001
      nx = dx / d
      ny = dy / d
      b[:x] = cx + nx * min_d
      b[:y] = cy + ny * min_d
      kick = ang_vel.abs > 0.05 ? 5.6 : 1.6
      b[:vx] = b[:vx] * 0.4 + nx * kick + (t * ang_vel * 2.2)
      b[:vy] = b[:vy] * 0.4 + ny * kick - 2.2
      sfx(:click, -1, 0.45, 1.2)
    end
  end

  def on_bumper_hit(idx, bm, b)
    @bumper_flash[idx] = 8
    @combo += 1
    @max_combo = @combo if @combo > @max_combo
    @combo_t = 90
    pts = bm[:pts] * @mult * (1 + @combo / 4)
    @score += pts
    @shake = 2.8

    # Rising musical scale pitch!
    pitch = (1.0 + (@combo - 1) * 0.08).clamp(1.0, 2.4)
    sfx(:bumper, -1, 0.8, pitch)
    spawn_sparks(bm[:x], bm[:y], bm[:col], 7)
    @popups << { x: bm[:x], y: bm[:y] - 10, txt: "+#{pts}", col: bm[:col], t: 28 }
    if @combo >= 3
      set_dmd("COMBO x#{@combo}!", 10, 60)
    end
  end

  def trigger_gameover
    stop_music
    sfx(:gameover)
    hi = save_get("hi_score", 0)
    save_set("hi_score", @score) if @score > hi
    mc = save_get("max_combo", 0)
    save_set("max_combo", @max_combo) if @max_combo > mc
    @state = :gameover
    @state_t = 0
  end

  def spawn_sparks(x, y, col, n)
    i = 0
    while i < n
      a = rand * Math::PI * 2.0
      sp = 0.8 + rand * 2.4
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
    bg(:cyber, dim: 0.55, tint: @multiball_bgm ? "#D03070" : "#3060B8")

    sx = @shake > 0 ? (rand * @shake * 2.0 - @shake) : 0.0
    sy = @shake > 0 ? (rand * @shake * 2.0 - @shake) : 0.0
    camera(sx, sy)

    draw_table
    draw_balls_and_fx

    camera
    blend(:normal)
    draw_dmd_panel
    draw_gameover_overlay if @state == :gameover
  end

  def draw_table
    # Playfield glass
    rectfill(@tl, @tt, @tr - @tl, @tb - @tt, 0, 0.86)
    rect(@tl, @tt, @tr - @tl, @tb - @tt, 12, 2)
    # Plunger lane divider
    line(256, 64, 256, @tb, 12, 2)

    # Rotating Roulette in center via draw_surface(rot:, scale:)
    draw_surface(@roulette_surf, 130, 156, 0.85, nil, rot: @roulette_ang, scale: 1.25)

    # Targets
    i = 0
    while i < @targets.size
      tg = @targets[i]
      rectfill(tg[:x], tg[:y], tg[:w], tg[:h], tg[:hit] ? 5 : 11)
      i += 1
    end

    # Slingshot guides
    line(@tl, 210, 98, 240, 14, 3)
    line(256, 210, 198, 240, 14, 3)

    # Bumpers
    i = 0
    while i < $bumpers.size
      bm = $bumpers[i]
      fl = @bumper_flash[i] > 0
      circfill(bm[:x], bm[:y], bm[:r] + (fl ? 2 : 0), fl ? 7 : 1)
      circ(bm[:x], bm[:y], bm[:r] + (fl ? 2 : 0), bm[:col])
      circ(bm[:x], bm[:y], bm[:r] - 4, fl ? 10 : bm[:col])
      i += 1
    end

    # Flippers
    lx = 98.0 + cos(@l_ang) * $cfg[:flipper_len]
    ly = 240.0 + sin(@l_ang) * $cfg[:flipper_len]
    rx = 198.0 + cos(@r_ang) * $cfg[:flipper_len]
    ry = 240.0 + sin(@r_ang) * $cfg[:flipper_len]
    line(98, 240, lx, ly, 10, 6)
    line(198, 240, rx, ry, 10, 6)
    circfill(98, 240, 4, 7)
    circfill(198, 240, 4, 7)
  end

  def draw_balls_and_fx
    blend(:add)
    i = 0
    while i < @balls.size
      b = @balls[i]
      if b[:trail].size >= 2
        polyline(b[:trail], @multiball_bgm ? 14 : 12, 3, 0.45)
      end
      circfill(b[:x], b[:y], $cfg[:ball_r] + 2, 12, 0.35)
      i += 1
    end

    i = 0
    while i < @particles.size
      pt = @particles[i]
      circfill(pt[:x], pt[:y], 2, pt[:col], 0.9)
      i += 1
    end
    blend(:normal)

    i = 0
    while i < @balls.size
      b = @balls[i]
      circfill(b[:x], b[:y], $cfg[:ball_r], 7)
      pset(b[:x] - 1, b[:y] - 1, 12)
      i += 1
    end

    i = 0
    while i < @popups.size
      p = @popups[i]
      print_text(p[:txt], p[:x], p[:y], p[:col], 8, 1.0, :center, 0)
      i += 1
    end
  end

  def draw_dmd_panel
    px = 296
    pw = 172
    # Cabinet side panel
    rectfill(px, 16, pw, 246, 0, 0.88)
    rect(px, 16, pw, 246, 12, 2)

    print_text("CYBER SYMPHONY", px + pw / 2, 26, 10, 8, 1.0, :center, 0)

    # DMD Dot Matrix Screen
    rectfill(px + 8, 44, pw - 16, 48, 1)
    rect(px + 8, 44, pw - 16, 48, 9, 2)
    msg = @dmd_t > 0 ? @dmd_msg : "SCORE #{@score}"
    col = @dmd_t > 0 ? @dmd_col : 10
    print_text(msg, px + pw / 2, 64, col, 8, 1.0, :center, 0)

    print_text("SCORE", px + 14, 108, 6, 8, 1.0, :left, 0)
    print_text(@score.to_s, px + pw - 14, 120, 10, 16, 1.0, :right, 0)

    print_text("BALLS: #{@balls_left}", px + 14, 152, 8, 8, 1.0, :left, 0)
    print_text("MULT: x#{@mult}", px + pw - 14, 152, 11, 8, 1.0, :right, 0)
    print_text("COMBO: x#{@combo}", px + 14, 170, 14, 8, 1.0, :left, 0)
    print_text("ACTIVE: #{@balls.size}", px + pw - 14, 170, 12, 8, 1.0, :right, 0)

    print_text("CONTROLS:", px + 14, 200, 7, 8, 1.0, :left, 0)
    print_text("L/Z : LEFT FLIP", px + 14, 214, 6, 8, 1.0, :left, 0)
    print_text("R/X : RIGHT FLIP", px + 14, 226, 6, 8, 1.0, :left, 0)
    print_text("SPC : LAUNCH  UP:NUDGE", px + 14, 238, 6, 8, 1.0, :left, 0)
  end

  def draw_gameover_overlay
    rectfill(60, 84, 200, 96, 0, 0.92)
    rect(60, 84, 200, 96, 8, 2)
    print_text("GAME OVER", 160, 100, 8, 16, 1.0, :center, 0)
    print_text("FINAL: #{@score}", 160, 130, 10, 8, 1.0, :center, 0)
    print_text("PRESS Z OR X", 160, 152, 7, 8, 1.0, :center, 0)
  end
end

run TitleScene.new
__END__
@SFX :bumper
wave:square freq:440->660 dur:0.06 env:decay vol:0.65

@SFX :flipper
wave:triangle freq:220->360 dur:0.04 env:decay vol:0.55

@SFX :launch
wave:saw freq:160->720 dur:0.22 env:decay vol:0.7

@MUSIC :table_bgm
ch0 wave=pulse vol=4 T138 L8 O4 e g b > d c < b g e  c e g b a g e c  d f# a > c < b a f# d  e g b > e < b g e4
ch1 wave=tri vol=5 T138 L4 O2 e b c g  d a e b
ch2 wave=noise vol=2 T138 L8 O6 c r c r c r c c

@MUSIC :multiball_bgm
ch0 wave=saw vol=4 T168 L8 O4 e > e < b > e c > e < a > e  d > d < a > d < b > d < g > d
ch1 wave=tri vol=6 T168 L8 O2 e e g e c c e c  d d f d g g b g
ch2 wave=noise vol=3 T168 L8 O6 c c r c c c r c  c c r c c c c c
