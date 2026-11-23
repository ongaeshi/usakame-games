# ==============================================================================
# 35. NEON SLASH
# ------------------------------------------------------------------------------
# 光の斬撃軌跡で敵と弾を真っ二つに両断するハイスピード剣戟アクション
# 256x256 / 1ファイル完結 / 基本API + bg() + スプライト + キーボード/マウス
#
# 【操作方法】
#   矢印キー / WASD     : 移動・斬撃方向
#   Z / Space / クリック: 居合ダッシュ斬り（敵と弾を両断！）
#   X / Enter           : 奥義・閃光乱舞（ゲージ50%以上で発動）
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2,
  title: "35. NEON SLASH"
)

SW = 256
SH = 256

class NeonSlashGame
  def initialize
    @state = :title
    @frame = 0
    @best_score = 0
    reset_game
  end

  def reset_game
    @px = 128.0
    @py = 140.0
    @vx = 0.0
    @vy = 0.0
    @facing = 0.0
    @hp = 5
    @max_hp = 5
    @invuln = 0
    @dash_cd = 0
    @overdrive = 40.0
    @score = 0
    @combo = 0
    @combo_t = 0
    @wave = 1
    @wave_kills = 0
    @hitstop = 0
    @shake = 0.0
    @flash = 0

    @slashes = []
    @afterimages = []
    @halves = []
    @sparks = []
    @enemies = []
    @bullets = []
    @spawn_t = 20
  end

  def spawn_enemy
    side = rand(4)
    if side == 0
      x = rand(20..236).to_f; y = 26.0
    elsif side == 1
      x = rand(20..236).to_f; y = 242.0
    elsif side == 2
      x = 14.0; y = rand(30..230).to_f
    else
      x = 242.0; y = rand(30..230).to_f
    end
    kind = [:drone, :drone, :gunner, :samurai][rand(@wave >= 2 ? 4 : 3)]
    @enemies << {
      kind: kind, x: x, y: y,
      spd: kind == :samurai ? (1.35 + @wave * 0.08) : (0.85 + @wave * 0.05),
      hp: kind == :samurai ? 2 : 1,
      fire_t: 45 + rand(50),
      hit_t: 0
    }
  end

  def seg_circle_hit?(x0, y0, x1, y1, cx, cy, r)
    vx = x1 - x0
    vy = y1 - y0
    wx = cx - x0
    wy = cy - y0
    len2 = vx * vx + vy * vy
    t = len2 > 0.001 ? (wx * vx + wy * vy) / len2 : 0.0
    t = t.clamp(0.0, 1.0)
    px = x0 + vx * t
    py = y0 + vy * t
    (cx - px) ** 2 + (cy - py) ** 2 <= r * r
  end

  def perform_slash(x0, y0, x1, y1, col = 12)
    ang = atan2(y1 - y0, x1 - x0)
    # 斬撃トレイル (太線 + 白芯)
    mid_x = (x0 + x1) * 0.5 + cos(ang + 1.57) * ((rand - 0.5) * 10.0)
    mid_y = (y0 + y1) * 0.5 + sin(ang + 1.57) * ((rand - 0.5) * 10.0)
    @slashes << {
      pts: [[x0, y0], [mid_x, mid_y], [x1, y1]],
      col: col, life: 16, max_life: 16
    }

    # 残像生成
    5.times do |i|
      t = i / 5.0
      @afterimages << {
        x: x0 + (x1 - x0) * t,
        y: y0 + (y1 - y0) * t,
        flip: (x1 < x0),
        life: 12 - i, max_life: 12
      }
    end

    # 敵を両断！
    sliced_any = false
    @enemies.each do |e|
      next if e[:hp] <= 0
      if seg_circle_hit?(x0, y0, x1, y1, e[:x], e[:y], 14.0)
        e[:hp] -= 1
        e[:hit_t] = 5
        sliced_any = true
        if e[:hp] <= 0
          slice_enemy(e, ang)
        end
      end
    end

    # 敵弾を斬り裂く！
    @bullets.each do |b|
      if seg_circle_hit?(x0, y0, x1, y1, b[:x], b[:y], 12.0)
        b[:dead] = true
        @score += 30
        6.times do
          a = rand * 6.28
          @sparks << { x: b[:x], y: b[:y], vx: cos(a) * 2.2, vy: sin(a) * 2.2, life: 12, max_life: 12, col: 10 }
        end
      end
    end
    @bullets.reject! { |b| b[:dead] }

    if sliced_any
      @hitstop = 3
      @shake = 4.5
    end
  end

  def slice_enemy(e, ang)
    @combo += 1
    @combo_t = 110
    @wave_kills += 1
    @overdrive = [@overdrive + 12.0, 100.0].min
    @score += 100 * [1 + @combo / 2, 6].min
    @best_score = @score if @score > @best_score

    nx = -sin(ang)
    ny = cos(ang)
    col = e[:kind] == :samurai ? 14 : (e[:kind] == :gunner ? 9 : 8)

    # 真っ二つのポリゴン断面が左右に飛散！
    [-1.0, 1.0].each do |side|
      @halves << {
        x: e[:x], y: e[:y],
        vx: nx * side * 1.9 + cos(ang) * 0.6,
        vy: ny * side * 1.9 + sin(ang) * 0.6,
        ang: ang, side: side, rot: 0.0, vrot: side * 0.14,
        col: col, life: 26, max_life: 26
      }
    end
    10.times do
      a = rand * 6.28
      spd = 1.0 + rand * 2.8
      @sparks << { x: e[:x], y: e[:y], vx: cos(a) * spd, vy: sin(a) * spd, life: 16, max_life: 16, col: 7 }
    end
  end

  def update
    @frame += 1

    if @state == :title
      if @frame % 28 == 0
        a = rand * 6.28
        @slashes << {
          pts: [[128 - cos(a) * 70, 128 - sin(a) * 70], [128 + cos(a) * 70, 128 + sin(a) * 70]],
          col: [12, 14, 10][rand(3)], life: 18, max_life: 18
        }
      end
      update_fx
      if @frame > 5 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        reset_game
        @state = :play
      end
      return
    end

    if @state == :gameover
      update_fx
      if btnp(4) || btnp(5) || btnp(:mouse_l)
        reset_game
        @state = :play
      end
      return
    end

    if @hitstop > 0
      @hitstop -= 1
      @shake *= 0.85
      return
    end

    @invuln -= 1 if @invuln > 0
    @dash_cd -= 1 if @dash_cd > 0
    @flash -= 1 if @flash > 0
    @shake *= 0.82
    @combo_t -= 1 if @combo_t > 0
    @combo = 0 if @combo_t <= 0

    # 移動
    mx = 0.0
    my = 0.0
    mx -= 1.0 if btn(0)
    mx += 1.0 if btn(1)
    my -= 1.0 if btn(2)
    my += 1.0 if btn(3)

    if mx != 0.0 || my != 0.0
      len = sqrt(mx * mx + my * my)
      mx /= len
      my /= len
      @facing = atan2(my, mx)
    end

    @px = (@px + mx * 2.3).clamp(12.0, SW - 12.0)
    @py = (@py + my * 2.3).clamp(24.0, SH - 12.0)

    # 居合ダッシュ斬り (Z / クリック)
    slash_trigger = btnp(4) || btnp(:mouse_l)
    if slash_trigger && @dash_cd <= 0
      @dash_cd = 10
      @invuln = 10
      ang = btnp(:mouse_l) ? atan2(mouse_y - @py, mouse_x - @px) : @facing
      @facing = ang
      sx = @px
      sy = @py
      ex = (@px + cos(ang) * 58.0).clamp(12.0, SW - 12.0)
      ey = (@py + sin(ang) * 58.0).clamp(24.0, SH - 12.0)
      @px = ex
      @py = ey
      perform_slash(sx, sy, ex, ey, 12)
    end

    # 奥義・閃光乱舞 (X)
    if btnp(5) && @overdrive >= 50.0
      @overdrive -= 50.0
      @invuln = 26
      @flash = 7
      @shake = 6.0
      4.times do
        x0 = rand(24..232).to_f
        y0 = rand(30..236).to_f
        a = rand * 6.28
        perform_slash(x0, y0, (x0 + cos(a) * 110.0).clamp(10.0, 246.0), (y0 + sin(a) * 110.0).clamp(24.0, 246.0), 14)
      end
    end

    # 敵出現
    @spawn_t -= 1
    if @spawn_t <= 0 && @enemies.size < 10
      spawn_enemy
      @spawn_t = [42 - @wave * 3, 16].max
    end
    if @wave_kills >= 8 + @wave * 4
      @wave += 1
      @wave_kills = 0
    end

    # 敵更新
    @enemies.each do |e|
      next if e[:hp] <= 0
      e[:hit_t] -= 1 if e[:hit_t] > 0
      dx = @px - e[:x]
      dy = @py - e[:y]
      d = sqrt(dx * dx + dy * dy)
      if d > 1.0
        e[:x] += (dx / d) * e[:spd]
        e[:y] += (dy / d) * e[:spd]
      end
      if e[:kind] == :gunner
        e[:fire_t] -= 1
        if e[:fire_t] <= 0 && d > 20.0
          e[:fire_t] = 75 + rand(35)
          @bullets << { x: e[:x], y: e[:y], vx: (dx / d) * 1.9, vy: (dy / d) * 1.9, dead: false }
        end
      end
      if d < 11.0 && @invuln <= 0
        take_damage
      end
    end
    @enemies.reject! { |e| e[:hp] <= 0 }

    # 敵弾更新
    @bullets.each do |b|
      b[:x] += b[:vx]
      b[:y] += b[:vy]
      if (b[:x] - @px) ** 2 + (b[:y] - @py) ** 2 < 64.0 && @invuln <= 0
        b[:dead] = true
        take_damage
      end
    end
    @bullets.reject! { |b| b[:dead] || b[:x] < -8 || b[:x] > SW + 8 || b[:y] < -8 || b[:y] > SH + 8 }

    update_fx
  end

  def update_fx
    @slashes.each { |s| s[:life] -= 1 }
    @slashes.reject! { |s| s[:life] <= 0 }
    @afterimages.each { |a| a[:life] -= 1 }
    @afterimages.reject! { |a| a[:life] <= 0 }
    @halves.each do |h|
      h[:x] += h[:vx]
      h[:y] += h[:vy]
      h[:vx] *= 0.94
      h[:vy] *= 0.94
      h[:rot] += h[:vrot]
      h[:life] -= 1
    end
    @halves.reject! { |h| h[:life] <= 0 }
    @sparks.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:life] -= 1
    end
    @sparks.reject! { |p| p[:life] <= 0 }
  end

  def take_damage
    @hp -= 1
    @invuln = 45
    @combo = 0
    @shake = 6.0
    @flash = 5
    @state = :gameover if @hp <= 0
  end

  def draw
    cls(0)
    sx = @shake > 0.2 ? (rand * 2.0 - 1.0) * @shake : 0.0
    sy = @shake > 0.2 ? (rand * 2.0 - 1.0) * @shake : 0.0
    camera(sx, sy)

    bg(:cyber, 0, 0, dim: 0.62)

    # 居合残像 (alpha半透明スプライト)
    @afterimages.each do |a|
      al = (a[:life].to_f / a[:max_life]) * 0.55
      spr(:samurai, a[:x] - 8, a[:y] - 8, a[:flip], 11, 0.0, 1.0, al)
    end

    # 両断されたポリゴン半身
    @halves.each do |h|
      al = h[:life].to_f / h[:max_life]
      ca = cos(h[:ang] + h[:rot])
      sa = sin(h[:ang] + h[:rot])
      s = h[:side]
      p0 = [h[:x] - ca * 7.0, h[:y] - sa * 7.0]
      p1 = [h[:x] + ca * 7.0, h[:y] + sa * 7.0]
      p2 = [h[:x] - sa * 6.0 * s, h[:y] + ca * 6.0 * s]
      trifill(p0[0], p0[1], p1[0], p1[1], p2[0], p2[1], h[:col], al)
    end

    # 敵
    @enemies.each do |e|
      sp = e[:kind] == :samurai ? :oni : :drone
      spr(sp, e[:x] - 8, e[:y] - 8, e[:x] > @px, e[:hit_t] > 0 ? 11 : nil)
    end

    # 敵弾
    blend(:add)
    @bullets.each do |b|
      circfill(b[:x], b[:y], 4, 8, 0.55)
      circfill(b[:x], b[:y], 2, 10, 0.95)
    end
    blend(:normal)

    # 自機
    if @state != :gameover
      if @invuln == 0 || (@invuln % 4) >= 2
        spr(:samurai, @px - 8, @py - 8, cos(@facing) < 0)
      end
      # 斬撃方向ガイド
      gx = @px + cos(@facing) * 20.0
      gy = @py + sin(@facing) * 20.0
      line(@px, @py, gx, gy, 12, 1, 0.45)
    end

    # 加算ネオン斬撃トレイル & スパーク
    blend(:add)
    @slashes.each do |s|
      al = s[:life].to_f / s[:max_life]
      polyline(s[:pts], s[:col], 7, al * 0.6)
      polyline(s[:pts], 7, 2, al)
    end
    @sparks.each do |p|
      circfill(p[:x], p[:y], 2.0, p[:col], p[:life].to_f / p[:max_life])
    end
    if @flash > 0
      rectfill(0, 0, SW, SH, 7, @flash * 0.07)
    end
    blend(:normal)

    camera()
    draw_hud
  end

  def draw_hud
    rectfill(0, 0, SW, 18, 0, 0.8)
    line(0, 18, SW, 18, 12, 1, 0.6)
    print_text(format("%06d", @score), 6, 5, 7)
    print_text(format("W%d", @wave), 54, 5, 10)

    # HPハート
    @max_hp.times do |i|
      col = i < @hp ? 8 : 5
      rectfill(78 + i * 9, 5, 7, 7, col)
    end

    # 奥義ゲージ
    print_text("OD", 132, 5, 14)
    rectfill(148, 6, 46, 6, 1)
    rectfill(148, 6, (46 * (@overdrive / 100.0)).to_i, 6, @overdrive >= 50 ? 14 : 13)
    rect(148, 6, 46, 6, 7)

    if @combo >= 2
      print_text(format("x%d", @combo), 204, 5, 11)
    end

    if @state == :title
      rectfill(24, 56, 208, 132, 0, 0.85)
      rect(24, 56, 208, 132, 12, 2)
      print_text("NEON SLASH", 98, 68, 7)
      print_text("CYBER IAIJUTSU ACTION", 62, 84, 12)
      print_text("ARROWS/WASD : AIM & MOVE", 56, 106, 7)
      print_text("Z / CLICK   : DASH SLASH", 56, 120, 11)
      print_text("X           : OMNI SLASH", 56, 134, 14)
      print_text("PRESS Z OR CLICK TO START", 53, 160, 10)
    elsif @state == :gameover
      rectfill(42, 76, 172, 92, 0, 0.88)
      rect(42, 76, 172, 92, 8, 2)
      print_text("SYSTEM DOWN", 95, 90, 8)
      print_text(format("SCORE: %06d", @score), 86, 110, 7)
      print_text(format("BEST : %06d", @best_score), 86, 124, 10)
      print_text("PRESS Z OR CLICK TO RETRY", 53, 146, 6)
    end
  end
end

run NeonSlashGame.new

__END__
@PALETTE 1
1: #161830
7: #FFFFFF
8: #FF1848
9: #FFA300
A: #FFEC27
C: #29D8FF
E: #FF50D8

@PALETTE 11
1: #206088
8: #60FFFF
C: #A0FFFF
E: #FFFFFF

@SPRITE :samurai 16x16 pal:1
................
.....111111.....
....1CCCCCC1....
...1C111111C1...
...1117777111...
....11CCCC11....
...1111CC1111...
..1CC1CCCC1CC1..
..1C.1CCCC1.777.
.....111111.....
....1C1..1C1....
....11....11....
................
................
................
................

@SPRITE :drone 16x16 pal:1
................
................
.....188881.....
...1188888811...
..188817718881..
..18817AA71881..
...1881111881...
....11888811....
...181....181...
..11........11..
................
................
................
................
................
................

@SPRITE :oni 16x16 pal:1
................
....1E....E1....
...1EE1111EE1...
...1EEEEEEEE1...
...1E17EE71E1...
....1EEEEEE1....
..1111EEEE1111..
.1EE11EEEE11EE1.
.1E..1EEEE1..E1.
.....1E11E1.....
....1E1..1E1....
....11....11....
................
................
................
................
