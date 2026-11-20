# ==============================================================================
# 06. STAR DIVER
# ------------------------------------------------------------------------------
# 都市→山→空→宇宙→電脳へBG連続変化する3択ビルド縦STG
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ← / → / ↑ / ↓ (WASD) : 自機移動 (アップグレード選択時は ←/→)
#   Z / Space / 左クリック : ショット (押しっぱなし連射) / 決定
#   X / Enter / 右クリック : ノヴァボム (弾消し＆全体攻撃)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "06. STAR DIVER"
)

ZONES = [
  { name: "NEON CITY",    bg: :city,     tint: [180, 205, 255] },
  { name: "PEAK RIDGE",   bg: :mountain, tint: [255, 190, 150] },
  { name: "STRATOSPHERE", bg: :sky,      tint: [220, 240, 255] },
  { name: "DEEP SPACE",   bg: :space,    tint: [210, 190, 255] },
  { name: "CYBER CORE",   bg: :cyber,    tint: [140, 245, 255] }
]

UPGRADES = [
  { id: :spread,  title: "SPREAD +1",  desc: "ADD SIDE CANNONS",   col: 12 },
  { id: :rapid,   title: "RAPID FIRE", desc: "FASTER SHOT RATE",   col: 10 },
  { id: :drone,   title: "OPT DRONE",  desc: "AUTO-FIRE WINGMAN",  col: 11 },
  { id: :laser,   title: "POWER UP",   desc: "+1 BULLET DAMAGE",   col: 8 },
  { id: :shield,  title: "REPAIR +1",  desc: "RESTORE 1 SHIELD",   col: 14 },
  { id: :bomb,    title: "NOVA +1",    desc: "+1 NOVA BOMB STOCK", col: 9 }
]

$diver_best ||= 0

def clamp_v(v, lo, hi)
  return lo if v < lo
  return hi if v > hi
  v
end

class EffectSystem
  attr_accessor :shake_timer, :shake_power, :flash_timer, :flash_col

  def initialize
    @particles = []
    @rings = []
    @popups = []
    @shake_timer = 0
    @shake_power = 0.0
    @flash_timer = 0
    @flash_col = 7
  end

  def shake(power, frames)
    @shake_power = power.to_f if power > @shake_power || @shake_timer <= 0
    @shake_timer = frames if frames > @shake_timer
  end

  def flash(frames, col = 7)
    @flash_timer = frames if frames > @flash_timer
    @flash_col = col
  end

  def burst(x, y, count, col, spd = 2.6, life = 16)
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

  def ring(x, y, max_r, col, spd = 3.2)
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
    z = ZONES[(@t / 150) % ZONES.size]
    bg(z[:bg], dim: 0.4, tint: z[:tint], scroll_y: -@t * 0.8, mirror_y: true)

    spr(:ship, 120, 178)

    rectfill(26, 26, 204, 40, 0)
    rect(26, 26, 204, 40, 12)
    print_text("STAR DIVER", 98, 34, 10)
    print_text("5-ZONE ROGUELITE VERTICAL STG", 41, 48, 12)

    rectfill(26, 94, 204, 62, 0)
    rect(26, 94, 204, 62, 5)
    print_text("ARROWS / WASD : MOVE", 44, 104, 7)
    print_text("Z / SPACE     : FIRE", 44, 117, 10)
    print_text("X / ENTER     : NOVA BOMB", 44, 130, 9)
    if $diver_best > 0
      print_text("HIGH SCORE: #{$diver_best}", 74, 143, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO LAUNCH", 50, 212, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @fx = EffectSystem.new
    @px = 128.0
    @py = 204.0
    @hp = 4
    @max_hp = 5
    @bombs = 2
    @score = 0
    @inv = 0

    @shot_cd = 0
    @spread_lvl = 1
    @rapid_lvl = 0
    @power_lvl = 1
    @drones = 0

    @zone_idx = 0
    @wave_kills = 0
    @wave_goal = 14
    @boss_active = false

    @bullets = []
    @ebullets = []
    @enemies = []
    @spawn_cd = 25

    @choosing = false
    @choices = []
    @choice_idx = 0
    @dead = false
    @dead_timer = 0
  end

  def open_upgrade_choice
    @choosing = true
    @ebullets.clear
    # ランダムに3つ重複なしで選ぶ（Fisher-Yates）
    pool = []
    i = 0
    while i < UPGRADES.size
      pool << UPGRADES[i]
      i += 1
    end
    i = pool.size - 1
    while i > 0
      j = rand(i + 1)
      tmp = pool[i]
      pool[i] = pool[j]
      pool[j] = tmp
      i -= 1
    end
    @choices = [pool[0], pool[1], pool[2]]
    @choice_idx = 0
  end

  def apply_upgrade(u)
    if u[:id] == :spread
      @spread_lvl += 1
    elsif u[:id] == :rapid
      @rapid_lvl += 1
    elsif u[:id] == :drone
      @drones += 1 if @drones < 2
    elsif u[:id] == :laser
      @power_lvl += 1
    elsif u[:id] == :shield
      @hp += 1
      @hp = @max_hp if @hp > @max_hp
    elsif u[:id] == :bomb
      @bombs += 1
    end
    @choosing = false
    @zone_idx = (@zone_idx + 1) % ZONES.size
    @wave_kills = 0
    @wave_goal += 4
    @fx.flash(4, 12)
    @fx.popup(128.0, 120.0, ZONES[@zone_idx][:name], 10)
  end

  def spawn_enemy
    kind = rand(10) < 3 ? :shooter : (rand(4) == 0 ? :heavy : :scout)
    hp = kind == :heavy ? (4 + @zone_idx * 2) : (kind == :shooter ? (2 + @zone_idx) : 1)
    @enemies << {
      x: 20.0 + rand() * 216.0, y: -14.0,
      vx: (rand() - 0.5) * 1.4, vy: kind == :heavy ? 0.65 : 1.1 + rand() * 0.6,
      hp: hp, max_hp: hp, kind: kind, cd: 35 + rand(40), boss: false
    }
  end

  def spawn_boss
    @boss_active = true
    hp = 36 + @zone_idx * 18
    @enemies << {
      x: 128.0, y: -24.0, vx: 1.1, vy: 0.8,
      hp: hp, max_hp: hp, kind: :boss, cd: 30, boss: true
    }
    @fx.popup(128.0, 96.0, "WARNING: GUARDIAN!", 8)
  end

  def fire_player
    rate = 9 - @rapid_lvl * 2
    rate = 3 if rate < 3
    @shot_cd = rate

    @bullets << { x: @px, y: @py - 8.0, vx: 0.0, vy: -5.5, dmg: @power_lvl }
    if @spread_lvl >= 2
      @bullets << { x: @px - 5.0, y: @py - 6.0, vx: -1.1, vy: -5.2, dmg: @power_lvl }
      @bullets << { x: @px + 5.0, y: @py - 6.0, vx: 1.1, vy: -5.2, dmg: @power_lvl }
    end
    if @spread_lvl >= 3
      @bullets << { x: @px - 7.0, y: @py - 4.0, vx: -2.1, vy: -4.8, dmg: @power_lvl }
      @bullets << { x: @px + 7.0, y: @py - 4.0, vx: 2.1, vy: -4.8, dmg: @power_lvl }
    end
    if @drones >= 1
      @bullets << { x: @px - 18.0, y: @py, vx: 0.0, vy: -5.2, dmg: 1 }
    end
    if @drones >= 2
      @bullets << { x: @px + 18.0, y: @py, vx: 0.0, vy: -5.2, dmg: 1 }
    end
  end

  def trigger_bomb
    @bombs -= 1
    @inv = 45
    @ebullets.clear
    @fx.flash(6, 7)
    @fx.shake(5.0, 14)
    @fx.ring(@px, @py, 140.0, 12, 7.0)
    @enemies.each do |e|
      e[:hp] -= 12
      @fx.burst(e[:x], e[:y], 8, 10, 2.5, 14)
    end
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

    if @choosing
      @choice_idx = (@choice_idx - 1) % 3 if btnp(0) || btnp(2)
      @choice_idx = (@choice_idx + 1) % 3 if btnp(1) || btnp(3)
      if btnp(:mouse_l)
        my = mouse_y
        i = 0
        while i < 3
          cy = 72 + i * 48
          if my >= cy && my <= cy + 40
            apply_upgrade(@choices[i])
            return
          end
          i += 1
        end
      elsif btnp(4) || btnp(5)
        apply_upgrade(@choices[@choice_idx])
      end
      return
    end

    @inv -= 1 if @inv > 0
    @shot_cd -= 1 if @shot_cd > 0

    spd = 2.6
    @px -= spd if btn(0)
    @px += spd if btn(1)
    @py -= spd if btn(2)
    @py += spd if btn(3)
    @px = clamp_v(@px, 12.0, 244.0)
    @py = clamp_v(@py, 26.0, 242.0)

    if (btn(4) || btn(:mouse_l)) && @shot_cd <= 0
      fire_player
    end

    if @bombs > 0 && (btnp(5) || btnp(:mouse_r))
      trigger_bomb
    end

    # 自機弾
    @bullets.each do |b|
      b[:x] += b[:vx]
      b[:y] += b[:vy]
    end
    @bullets.reject! { |b| b[:y] < -10.0 || b[:x] < -10.0 || b[:x] > 266.0 }

    # 敵スポーン
    unless @boss_active
      @spawn_cd -= 1
      if @spawn_cd <= 0
        if @wave_kills >= @wave_goal
          spawn_boss
        else
          spawn_enemy
          @spawn_cd = 28 - @zone_idx * 3
          @spawn_cd = 14 if @spawn_cd < 14
        end
      end
    end

    # 敵更新 & 弾当たり判定
    @enemies.each do |e|
      if e[:boss]
        e[:y] = 48.0 if e[:y] < 48.0
        e[:x] += e[:vx]
        e[:vx] = -e[:vx] if e[:x] < 32.0 || e[:x] > 224.0
        e[:cd] -= 1
        if e[:cd] <= 0
          e[:cd] = 36
          a = -1
          while a <= 1
            ang = Math::PI * 0.5 + a * 0.35
            @ebullets << { x: e[:x], y: e[:y] + 10.0, vx: cos(ang) * 2.1, vy: sin(ang) * 2.1 }
            a += 1
          end
        end
      else
        e[:x] += e[:vx]
        e[:y] += e[:vy]
        e[:vx] = -e[:vx] if e[:x] < 12.0 || e[:x] > 244.0
        if e[:kind] == :shooter
          e[:cd] -= 1
          if e[:cd] <= 0
            e[:cd] = 65
            dx = @px - e[:x]
            dy = @py - e[:y]
            d = sqrt(dx * dx + dy * dy)
            if d > 1.0
              @ebullets << { x: e[:x], y: e[:y], vx: dx / d * 2.0, vy: dy / d * 2.0 }
            end
          end
        end
      end

      hit_r = e[:boss] ? 16.0 : 10.0
      @bullets.each do |b|
        dx = b[:x] - e[:x]
        dy = b[:y] - e[:y]
        if dx * dx + dy * dy < hit_r * hit_r
          b[:y] = -999.0
          e[:hp] -= b[:dmg]
          @fx.burst(b[:x], b[:y], 3, 7, 1.5, 8)
        end
      end

      if e[:hp] <= 0
        pts = e[:boss] ? 1000 : (e[:kind] == :heavy ? 180 : 60)
        @score += pts
        $diver_best = @score if @score > $diver_best
        @fx.burst(e[:x], e[:y], e[:boss] ? 26 : 10, 9, 3.0, 20)
        @fx.ring(e[:x], e[:y], e[:boss] ? 34.0 : 14.0, 10, 2.5)
        @fx.shake(e[:boss] ? 4.5 : 1.5, e[:boss] ? 12 : 4)
        if e[:boss]
          @boss_active = false
          open_upgrade_choice
        else
          @wave_kills += 1
        end
      elsif @inv <= 0
        dx2 = e[:x] - @px
        dy2 = e[:y] - @py
        if dx2 * dx2 + dy2 * dy2 < (hit_r + 5.0) * (hit_r + 5.0)
          damage_player
        end
      end
    end
    @enemies.reject! { |e| e[:hp] <= 0 || e[:y] > 272.0 }

    # 敵弾更新
    @ebullets.each do |eb|
      eb[:x] += eb[:vx]
      eb[:y] += eb[:vy]
      if @inv <= 0
        dx = eb[:x] - @px
        dy = eb[:y] - @py
        if dx * dx + dy * dy < 7.0 * 7.0
          eb[:y] = 999.0
          damage_player
        end
      end
    end
    @ebullets.reject! { |eb| eb[:y] > 266.0 || eb[:x] < -10.0 || eb[:x] > 266.0 }

    @fx.update
  end

  def damage_player
    @hp -= 1
    @inv = 50
    @fx.burst(@px, @py, 14, 8, 2.8, 18)
    @fx.shake(4.0, 10)
    @fx.flash(4, 8)
    if @hp <= 0
      @dead = true
      @dead_timer = 0
    end
  end

  def draw
    cls(0)
    shk = @fx.shake_offset
    z = ZONES[@zone_idx]
    bg(z[:bg], dim: 0.42, tint: z[:tint], scale: 1.04,
       scroll_y: -@t * 1.1 + shk[1] * 0.3, scroll_x: shk[0] * 0.3, mirror_y: true)

    camera(shk[0].to_i, shk[1].to_i)

    # 自機弾
    @bullets.each do |b|
      rectfill(b[:x].to_i - 1, b[:y].to_i - 4, 3, 7, 12)
      pset(b[:x].to_i, b[:y].to_i - 3, 7)
    end

    # 敵
    @enemies.each do |e|
      if e[:boss]
        spr(:boss_ship, e[:x].to_i - 16, e[:y].to_i - 16)
        bw = (e[:hp] * 32 / e[:max_hp]).to_i
        rectfill(e[:x].to_i - 16, e[:y].to_i - 20, 32, 3, 0)
        rectfill(e[:x].to_i - 16, e[:y].to_i - 20, bw, 3, 8)
      else
        sp = e[:kind] == :heavy ? :enemy_heavy : :enemy_scout
        spr(sp, e[:x].to_i - 8, e[:y].to_i - 8)
      end
    end

    # 敵弾
    @ebullets.each do |eb|
      circfill(eb[:x].to_i, eb[:y].to_i, 3, 8)
      pset(eb[:x].to_i, eb[:y].to_i, 10)
    end

    # ドローン & 自機
    unless @dead
      if @drones >= 1
        spr(:drone_wing, @px.to_i - 22, @py.to_i - 4)
      end
      if @drones >= 2
        spr(:drone_wing, @px.to_i + 14, @py.to_i - 4)
      end
      if @inv <= 0 || (@inv / 3) % 2 == 0
        spr(:ship, @px.to_i - 8, @py.to_i - 8)
      end
    end

    @fx.draw

    camera()
    clip()

    if @fx.flash_timer > 0
      rect(0, 0, 256, 256, @fx.flash_col)
      rect(1, 1, 254, 254, @fx.flash_col)
    end

    # HUD
    rectfill(0, 0, 256, 18, 0)
    line(0, 18, 256, 18, 5)
    print_text("SCR:#{@score}", 6, 5, 7)
    print_text(z[:name], 86, 5, 12)

    i = 0
    while i < @hp
      circfill(244 - i * 10, 9, 3, 8)
      i += 1
    end
    i = 0
    while i < @bombs
      rectfill(6 + i * 9, 244, 6, 6, 9)
      i += 1
    end

    if @choosing
      rectfill(20, 38, 216, 186, 0)
      rect(20, 38, 216, 186, 10)
      print_text("ZONE CLEAR! PICK UPGRADE", 56, 48, 10)
      i = 0
      while i < 3
        u = @choices[i]
        cy = 72 + i * 48
        sel = (i == @choice_idx)
        rectfill(32, cy, 192, 40, sel ? 1 : 0)
        rect(32, cy, 192, 40, sel ? 10 : u[:col])
        print_text(u[:title], 44, cy + 8, u[:col])
        print_text(u[:desc], 44, cy + 22, 7)
        i += 1
      end
    end

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("STARFIGHTER LOST!", 76, 96, 8)
      print_text("SCORE : #{@score}", 74, 114, 7)
      print_text("BEST  : #{$diver_best}", 74, 128, 12)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 148, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #080914
1: #1D2B53
5: #5F574F
6: #C2C3C7
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
B: #00E436
C: #29ADFF
E: #FF77A8

@SPRITE :ship 16x16 pal:1
.......00.......
......0770......
......0CC0......
.....0CCCC0.....
....0CC77CC0....
...0CC7CC7CC0...
..0CCC7CC7CCC0..
.011CCCCCCCC110.
01180CCCCCC08110
0110.0C88C0.0110
.00..09AA90..00.
......0990......
.......00.......
................
................
................

@SPRITE :drone_wing 8x8 pal:1
...00...
..0BB0..
.0B77B0.
0BBBBBB0
0B1BB1B0
.0B99B0.
..0000..
........

@SPRITE :enemy_scout 16x16 pal:1
................
....00....00....
...0880..0880...
..088880088880..
..088778877880..
...0888AA8880...
....00888800....
.....008800.....
......0990......
.......00.......
................
................
................
................
................
................

@SPRITE :enemy_heavy 16x16 pal:1
................
...0000000000...
..055666666550..
.05588777788550.
.0588A8888A8850.
.05588888888550.
..055566665550..
...0099009900...
....09900990....
.....00..00.....
................
................
................
................
................
................

@SPRITE :boss_ship 32x32 pal:1
................................
............00000000............
.........00055666655000.........
.......005566777777665500.......
.....0055668888888888665500.....
....05566888AA8888AA88866550....
...05568887788888888778886550...
..0556888777788888877778886550..
..056688887788AAAA887788886650..
.055688888888A7777A888888886550.
.056688888888A7AA7A888888886650.
.0568888888888AAAA8888888888650.
.056885558888888888888855588650.
.056855655888888888888556558650.
..0565666508888888888056665650..
..00555650.0088888800.05655500..
....00000....008800....00000....
...............00...............
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
