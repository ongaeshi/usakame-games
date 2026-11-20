# ==============================================================================
# 07. TANK RICOCHET
# ------------------------------------------------------------------------------
# 壁跳弾×予測線で敵戦車を撃ち抜くタクティカル戦車アリーナ
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ← / → / ↑ / ↓ (WASD) : 戦車移動
#   マウス移動             : 砲塔エイム＆跳弾予測線
#   Z / Space / 左クリック : 跳弾砲発射 (最大2回壁反射!)
#   X / Enter / 右クリック : 回避ブースト
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "07. TANK RICOCHET"
)

ARENA_X = 8.0
ARENA_Y = 24.0
ARENA_W = 240.0
ARENA_H = 224.0

$tank_best ||= 0

def clamp_v(v, lo, hi)
  return lo if v < lo
  return hi if v > hi
  v
end

class EffectSystem
  attr_accessor :shake_timer, :shake_power, :hitstop, :flash_timer

  def initialize
    @particles = []
    @rings = []
    @popups = []
    @shake_timer = 0
    @shake_power = 0.0
    @hitstop = 0
    @flash_timer = 0
  end

  def shake(power, frames)
    @shake_power = power.to_f if power > @shake_power || @shake_timer <= 0
    @shake_timer = frames if frames > @shake_timer
  end

  def stop(frames)
    @hitstop = frames if frames > @hitstop
  end

  def flash(frames)
    @flash_timer = frames if frames > @flash_timer
  end

  def burst(x, y, count, col, spd = 2.6, life = 18)
    i = 0
    while i < count
      ang = rand() * Math::PI * 2.0
      v = (0.3 + rand() * 0.7) * spd
      @particles << {
        x: x.to_f, y: y.to_f,
        vx: cos(ang) * v, vy: sin(ang) * v,
        life: life + rand(8), col: col, size: rand(2) + 1
      }
      i += 1
    end
  end

  def ring(x, y, max_r, col, spd = 2.6)
    @rings << { x: x.to_f, y: y.to_f, r: 2.0, max_r: max_r.to_f, col: col, spd: spd }
  end

  def popup(x, y, text, col = 7)
    @popups << { x: x.to_f, y: y.to_f, vy: -0.7, life: 28, text: text, col: col }
  end

  def update
    @shake_timer -= 1 if @shake_timer > 0
    @flash_timer -= 1 if @flash_timer > 0
    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:vx] *= 0.94
      p[:vy] *= 0.94
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }
    @rings.each { |r| r[:r] += r[:spd] }
    @rings.reject! { |r| r[:r] >= r[:max_r] }
    @popups.each do |pp|
      pp[:y] += pp[:vy]
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }
  end

  def shake_offset
    return [0.0, 0.0] if @shake_timer <= 0
    [(rand() * 2.0 - 1.0) * @shake_power, (rand() * 2.0 - 1.0) * @shake_power]
  end

  def draw
    @rings.each { |r| circ(r[:x].to_i, r[:y].to_i, r[:r].to_i, r[:col]) }
    @particles.each do |p|
      if p[:size] <= 1
        pset(p[:x].to_i, p[:y].to_i, p[:col])
      else
        rectfill(p[:x].to_i, p[:y].to_i, p[:size], p[:size], p[:col])
      end
    end
    @popups.each do |pp|
      print_text(pp[:text], pp[:x].to_i - pp[:text].length * 3, pp[:y].to_i, pp[:col])
    end
  end
end

class TitleScene
  def initialize
    @t = 0
  end

  def update
    @t += 1
    if btnp(4) || btnp(:mouse_l)
      run GameScene.new
    end
  end

  def draw
    cls(0)
    bg(:training, dim: 0.55, tint: [130, 145, 175])

    spr(:tank_p, 60, 168)
    spr(:tank_e, 180, 168)
    # 跳弾ラインデモ
    line(68, 172, 128, 124, 10)
    line(128, 124, 188, 172, 10)

    rectfill(26, 26, 204, 40, 0)
    rect(26, 26, 204, 40, 10)
    print_text("TANK RICOCHET", 89, 34, 10)
    print_text("BOUNCE SHELLS AROUND WALLS!", 47, 48, 7)

    rectfill(24, 78, 208, 62, 0)
    rect(24, 78, 208, 62, 5)
    print_text("ARROWS / WASD : MOVE TANK", 40, 88, 7)
    print_text("MOUSE         : AIM + PREVIEW", 40, 101, 12)
    print_text("Z / CLICK     : FIRE SHELL", 40, 114, 10)
    if $tank_best > 0
      print_text("HIGH SCORE: #{$tank_best}", 74, 127, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO DEPLOY", 50, 212, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @fx = EffectSystem.new
    @stage = 1
    @score = 0
    @hp = 3
    @dead = false
    @dead_timer = 0
    @clear_timer = 0

    @px = 40.0
    @py = 212.0
    @body_ang = 0.0
    @aim_ang = -0.4
    @prev_mx = mouse_x
    @prev_my = mouse_y
    @shot_cd = 0
    @dash_cd = 0
    @inv = 0

    @walls = []
    @enemies = []
    @shells = []
    setup_stage(@stage)
  end

  def setup_stage(st)
    @walls = []
    @shells = []
    @enemies = []
    @px = 40.0
    @py = 208.0
    @inv = 30

    pat = (st - 1) % 4
    if pat == 0
      @walls << { x: 88.0, y: 80.0, w: 16.0, h: 112.0 }
      @walls << { x: 152.0, y: 80.0, w: 16.0, h: 112.0 }
    elsif pat == 1
      @walls << { x: 64.0, y: 84.0, w: 128.0, h: 16.0 }
      @walls << { x: 64.0, y: 168.0, w: 128.0, h: 16.0 }
    elsif pat == 2
      @walls << { x: 120.0, y: 64.0, w: 16.0, h: 144.0 }
      @walls << { x: 48.0, y: 128.0, w: 48.0, h: 16.0 }
      @walls << { x: 160.0, y: 128.0, w: 48.0, h: 16.0 }
    else
      @walls << { x: 56.0, y: 72.0, w: 24.0, h: 48.0 }
      @walls << { x: 176.0, y: 72.0, w: 24.0, h: 48.0 }
      @walls << { x: 56.0, y: 156.0, w: 24.0, h: 48.0 }
      @walls << { x: 176.0, y: 156.0, w: 24.0, h: 48.0 }
    end

    count = 2 + st
    count = 7 if count > 7
    i = 0
    while i < count
      ex = 140.0 + (i % 3) * 38.0
      ey = 48.0 + (i / 3) * 56.0
      # 壁に埋まらないよう調整
      while hit_wall?(ex, ey, 9.0)
        ex -= 14.0
        ey += 14.0
        ex = 216.0 if ex < 32.0
        ey = 52.0 if ey > 220.0
      end
      kind = (st >= 2 && i == 0) ? :sniper : :patrol
      @enemies << {
        x: ex, y: ey, vx: (rand() < 0.5 ? 0.9 : -0.9), vy: (rand() < 0.5 ? 0.7 : -0.7),
        kind: kind, cd: 50 + rand(50), hp: (st >= 4 && i == 0) ? 2 : 1, ang: Math::PI
      }
      i += 1
    end
  end

  def hit_wall?(x, y, r)
    return true if x - r < ARENA_X || x + r > ARENA_X + ARENA_W
    return true if y - r < ARENA_Y || y + r > ARENA_Y + ARENA_H
    @walls.each do |w|
      if x + r > w[:x] && x - r < w[:x] + w[:w] &&
         y + r > w[:y] && y - r < w[:y] + w[:h]
        return true
      end
    end
    false
  end

  def compute_ricochet_pts(sx, sy, ang, max_bounces)
    pts = [[sx, sy]]
    cx = sx
    cy = sy
    vx = cos(ang) * 3.0
    vy = sin(ang) * 3.0
    bounces = 0
    steps = 0
    while steps < 70 && bounces <= max_bounces
      nx = cx + vx
      if hit_wall?(nx, cy, 2.0)
        vx = -vx
        pts << [cx, cy]
        bounces += 1
      else
        cx = nx
      end
      ny = cy + vy
      if hit_wall?(cx, ny, 2.0)
        vy = -vy
        pts << [cx, cy]
        bounces += 1
      else
        cy = ny
      end
      steps += 1
    end
    pts << [cx, cy]
    pts
  end

  def fire_shell(x, y, ang, owner, max_bounces)
    spd = owner == :player ? 3.5 : 2.3
    @shells << {
      x: x + cos(ang) * 10.0, y: y + sin(ang) * 10.0,
      vx: cos(ang) * spd, vy: sin(ang) * spd,
      owner: owner, bounces: max_bounces, life: 240
    }
    @fx.burst(x + cos(ang) * 10.0, y + sin(ang) * 10.0, 4, 10, 1.8, 10)
  end

  def update
    @t += 1
    if @dead
      @dead_timer += 1
      @fx.update
      if @dead_timer > 30 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    if @clear_timer > 0
      @clear_timer -= 1
      @fx.update
      if @clear_timer == 0
        @stage += 1
        setup_stage(@stage)
      end
      return
    end

    if @fx.hitstop > 0
      @fx.hitstop -= 1
      @fx.update
      return
    end

    @shot_cd -= 1 if @shot_cd > 0
    @dash_cd -= 1 if @dash_cd > 0
    @inv -= 1 if @inv > 0

    # 移動
    dx = 0.0
    dy = 0.0
    dx -= 1.0 if btn(0)
    dx += 1.0 if btn(1)
    dy -= 1.0 if btn(2)
    dy += 1.0 if btn(3)

    if dx != 0.0 || dy != 0.0
      len = sqrt(dx * dx + dy * dy)
      spd = 1.6
      if @dash_cd <= 0 && (btnp(5) || btnp(:mouse_r))
        spd = 12.0
        @dash_cd = 45
        @fx.burst(@px, @py, 8, 12, 2.0, 12)
      end
      mx = dx / len * spd
      my = dy / len * spd
      @px += mx unless hit_wall?(@px + mx, @py, 7.0)
      @py += my unless hit_wall?(@px, @py + my, 7.0)
      @body_ang = atan2(dy, dx)
      @aim_ang = @body_ang if mouse_x == @prev_mx && mouse_y == @prev_my
    end

    # マウスエイム
    cur_mx = mouse_x
    cur_my = mouse_y
    if cur_mx != @prev_mx || cur_my != @prev_my
      @aim_ang = atan2(cur_my.to_f - @py, cur_mx.to_f - @px)
      @prev_mx = cur_mx
      @prev_my = cur_my
    end

    # 発射
    if (btnp(4) || btnp(:mouse_l)) && @shot_cd <= 0
      @shot_cd = 16
      fire_shell(@px, @py, @aim_ang, :player, 2)
    end

    # 敵AI
    @enemies.each do |e|
      if hit_wall?(e[:x] + e[:vx], e[:y], 7.0)
        e[:vx] = -e[:vx]
      else
        e[:x] += e[:vx]
      end
      if hit_wall?(e[:x], e[:y] + e[:vy], 7.0)
        e[:vy] = -e[:vy]
      else
        e[:y] += e[:vy]
      end
      e[:ang] = atan2(@py - e[:y], @px - e[:x])
      e[:cd] -= 1
      if e[:cd] <= 0
        e[:cd] = e[:kind] == :sniper ? 75 : 95
        fire_shell(e[:x], e[:y], e[:ang], :enemy, e[:kind] == :sniper ? 1 : 0)
      end
    end

    # 砲弾更新
    @shells.each do |sh|
      sh[:life] -= 1
      nx = sh[:x] + sh[:vx]
      if hit_wall?(nx, sh[:y], 2.5)
        if sh[:bounces] > 0
          sh[:vx] = -sh[:vx]
          sh[:bounces] -= 1
          @fx.burst(sh[:x], sh[:y], 4, 10, 1.5, 10)
        else
          sh[:life] = 0
          @fx.burst(sh[:x], sh[:y], 5, 6, 1.5, 10)
        end
      else
        sh[:x] = nx
      end

      ny = sh[:y] + sh[:vy]
      if hit_wall?(sh[:x], ny, 2.5)
        if sh[:bounces] > 0
          sh[:vy] = -sh[:vy]
          sh[:bounces] -= 1
          @fx.burst(sh[:x], sh[:y], 4, 10, 1.5, 10)
        else
          sh[:life] = 0
          @fx.burst(sh[:x], sh[:y], 5, 6, 1.5, 10)
        end
      else
        sh[:y] = ny
      end

      next if sh[:life] <= 0

      # 敵命中
      if sh[:owner] == :player
        @enemies.each do |e|
          dx2 = sh[:x] - e[:x]
          dy2 = sh[:y] - e[:y]
          if dx2 * dx2 + dy2 * dy2 < 10.0 * 10.0
            sh[:life] = 0
            e[:hp] -= 1
            if e[:hp] <= 0
              pts = e[:kind] == :sniper ? 200 : 100
              @score += pts
              $tank_best = @score if @score > $tank_best
              @fx.burst(e[:x], e[:y], 18, 9, 3.0, 20)
              @fx.ring(e[:x], e[:y], 22.0, 10, 2.6)
              @fx.popup(e[:x], e[:y] - 8.0, "+#{pts}", 10)
              @fx.stop(3)
              @fx.shake(3.0, 8)
            else
              @fx.burst(e[:x], e[:y], 8, 7, 2.0, 12)
            end
            break
          end
        end
      else
        # プレイヤー被弾
        if @inv <= 0
          dx2 = sh[:x] - @px
          dy2 = sh[:y] - @py
          if dx2 * dx2 + dy2 * dy2 < 9.0 * 9.0
            sh[:life] = 0
            @hp -= 1
            @inv = 50
            @fx.burst(@px, @py, 16, 8, 3.0, 20)
            @fx.shake(4.5, 12)
            @fx.flash(4)
            if @hp <= 0
              @dead = true
              @dead_timer = 0
            end
          end
        end
      end
    end
    @shells.reject! { |sh| sh[:life] <= 0 }
    @enemies.reject! { |e| e[:hp] <= 0 }

    if @enemies.empty? && !@dead
      @clear_timer = 45
      @score += 250
      $tank_best = @score if @score > $tank_best
      @fx.popup(128.0, 110.0, "STAGE #{@stage} CLEAR!", 11)
    end

    @fx.update
  end

  def draw
    cls(0)
    shk = @fx.shake_offset
    bg(:training, dim: 0.55, tint: [120, 135, 165], scale: 1.04,
       scroll_x: shk[0] * 0.3, y: shk[1] * 0.3)

    camera(shk[0].to_i, shk[1].to_i)

    # アリーナ外枠
    rect(ARENA_X.to_i - 1, ARENA_Y.to_i - 1, ARENA_W.to_i + 2, ARENA_H.to_i + 2, 6)

    # 壁
    @walls.each do |w|
      rectfill(w[:x].to_i, w[:y].to_i, w[:w].to_i, w[:h].to_i, 5)
      rect(w[:x].to_i, w[:y].to_i, w[:w].to_i, w[:h].to_i, 6)
    end

    # 跳弾予測線
    unless @dead
      pts = compute_ricochet_pts(@px, @py, @aim_ang, 1)
      i = 0
      while i < pts.size - 1
        line(pts[i][0].to_i, pts[i][1].to_i, pts[i + 1][0].to_i, pts[i + 1][1].to_i, i == 0 ? 10 : 12)
        i += 1
      end
    end

    # 敵戦車
    @enemies.each do |e|
      sp = e[:kind] == :sniper ? :tank_s : :tank_e
      spr_ext(sp, e[:x].to_i, e[:y].to_i, e[:ang] * 180.0 / Math::PI, 1.0, 1.0, false, false)
    end

    # 自機戦車
    unless @dead
      if @inv <= 0 || (@inv / 3) % 2 == 0
        spr_ext(:tank_p, @px.to_i, @py.to_i, @aim_ang * 180.0 / Math::PI, 1.0, 1.0, false, false)
      end
    end

    # 砲弾
    @shells.each do |sh|
      col = sh[:owner] == :player ? 10 : 8
      circfill(sh[:x].to_i, sh[:y].to_i, 3, col)
      pset(sh[:x].to_i, sh[:y].to_i, 7)
    end

    @fx.draw

    camera()
    clip()

    if @fx.flash_timer > 0
      rect(0, 0, 256, 256, 8)
      rect(1, 1, 254, 254, 8)
    end

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("STG:#{@stage}", 6, 6, 12)
    print_text("SCR:#{@score}", 62, 6, 7)
    print_text("BEST:#{$tank_best}", 134, 6, 10)
    i = 0
    while i < 3
      circfill(218 + i * 12, 10, 4, i < @hp ? 8 : 5)
      i += 1
    end

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("TANK DESTROYED!", 82, 96, 8)
      print_text("STAGE : #{@stage}", 76, 112, 12)
      print_text("SCORE : #{@score}", 76, 124, 7)
      print_text("BEST  : #{$tank_best}", 76, 136, 10)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 152, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #0A0B12
3: #008751
5: #5F574F
6: #C2C3C7
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
B: #00E436
C: #29ADFF

@SPRITE :tank_p 16x16 pal:1
................
..000000000000..
.03333333333330.
.03BBBBBBBBBB30.
..03B33BB33B30..
..03B3BBBB3B3000
..03B3B77B3BBBB0
..03B3B77B3BBBB0
..03B3BBBB3B3000
..03B33BB33B30..
.03BBBBBBBBBB30.
.03333333333330.
..000000000000..
................
................
................

@SPRITE :tank_e 16x16 pal:1
................
..000000000000..
.08888888888880.
.08999999999980.
..089889988980..
..08989999898000
..08989779899990
..08989779899990
..08989999898000
..089889988980..
.08999999999980.
.08888888888880.
..000000000000..
................
................
................

@SPRITE :tank_s 16x16 pal:1
................
..000000000000..
.01111111111110.
.01CCCCCCCCCC10.
..01C11CC11C10..
..01C1CCCC1C1000
..01C1C77C1CCCC0
..01C1C77C1CCCC0
..01C1CCCC1C1000
..01C11CC11C10..
.01CCCCCCCCCC10.
.01111111111110.
..000000000000..
................
................
................
