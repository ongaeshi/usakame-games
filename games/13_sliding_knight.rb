# ==============================================================================
# 13. SLIDING KNIGHT
# ------------------------------------------------------------------------------
# 止まらない氷床で敵を一掃するローグライト詰めタクティクス
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ← / → / ↑ / ↓ (WASD) : 氷上スライディング突撃 (壁か端まで止まらない!)
#   Z / Space / 左クリック : 氷砕旋風斬り (周囲4マス攻撃・チャージ制)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "13. SLIDING KNIGHT"
)

GRID_W = 8
GRID_H = 8
CELL = 24
OX = 32
OY = 36

$knight_best_floor ||= 0
$knight_best_score ||= 0

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
    bg(:mountain, dim: 0.42, tint: [155, 210, 255])

    spr(:knight, 72, 168)
    line(88, 176, 168, 176, 12)
    spr(:ice_slime, 172, 168)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 12)
    print_text("SLIDING KNIGHT", 86, 32, 10)
    print_text("ICE-SLIDE TACTICAL ROGUELITE", 44, 46, 12)

    rectfill(24, 78, 208, 58, 0)
    rect(24, 78, 208, 58, 5)
    print_text("ARROWS / WASD : SLIDE & SLASH", 36, 88, 7)
    print_text("Z / SPACE     : WHIRLWIND NOVA", 36, 101, 10)
    if $knight_best_floor > 0
      print_text("BEST: F#{$knight_best_floor}  SCR:#{$knight_best_score}", 58, 117, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO SLIDE", 53, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @floor = 1
    @score = 0
    @hp = 4
    @nova = 2
    @px = 1
    @py = 6
    @sliding = false
    @slide_dx = 0
    @slide_dy = 0
    @slide_timer = 0
    @slide_combo = 0

    @pillars = []
    @enemies = []
    @particles = []
    @popups = []
    @shake_t = 0
    @dead = false
    @dead_timer = 0

    generate_floor
  end

  def generate_floor
    @pillars = []
    @enemies = []
    @px = 1 + rand(6)
    @py = 6

    # 石柱配置
    cnt_p = 4 + (@floor / 2).to_i
    cnt_p = 9 if cnt_p > 9
    i = 0
    while i < cnt_p
      gx = rand(GRID_W)
      gy = rand(GRID_H)
      next if gx == @px && gy == @py
      next if @pillars.any? { |p| p[:x] == gx && p[:y] == gy }
      @pillars << { x: gx, y: gy }
      i += 1
    end

    # 敵配置
    cnt_e = 3 + @floor
    cnt_e = 10 if cnt_e > 10
    tries = 0
    while @enemies.size < cnt_e && tries < 60
      tries += 1
      gx = rand(GRID_W)
      gy = rand(GRID_H - 1)
      next if (gx - @px).abs + (gy - @py).abs <= 1
      next if @pillars.any? { |p| p[:x] == gx && p[:y] == gy }
      next if @enemies.any? { |e| e[:x] == gx && e[:y] == gy }
      kind = @floor >= 2 && rand(3) == 0 ? :skull : :ice_slime
      @enemies << { x: gx, y: gy, kind: kind, alive: true }
    end
  end

  def pillar_at?(gx, gy)
    return true if gx < 0 || gx >= GRID_W || gy < 0 || gy >= GRID_H
    @pillars.any? { |p| p[:x] == gx && p[:y] == gy }
  end

  def burst(gx, gy, col)
    cx = (OX + gx * CELL + 12).to_f
    cy = (OY + gy * CELL + 12).to_f
    i = 0
    while i < 8
      ang = rand() * Math::PI * 2.0
      @particles << { x: cx, y: cy, vx: cos(ang) * 2.0, vy: sin(ang) * 2.0, col: col, life: 14 }
      i += 1
    end
  end

  def enemy_turn
    @enemies.each do |e|
      next unless e[:alive]
      dx = @px - e[:x]
      dy = @py - e[:y]
      if dx.abs + dy.abs == 1
        @hp -= 1
        @shake_t = 10
        burst(@px, @py, 8)
        @popups << { x: OX + @px * CELL + 12, y: OY + @py * CELL, text: "-1 HP!", col: 8, life: 28 }
        if @hp <= 0
          @dead = true
          @dead_timer = 0
          return
        end
      elsif e[:kind] == :skull || @t % 2 == 0
        # 1マス接近
        nx = e[:x]
        ny = e[:y]
        if dx.abs >= dy.abs
          nx += (dx > 0 ? 1 : -1)
        else
          ny += (dy > 0 ? 1 : -1)
        end
        unless pillar_at?(nx, ny) || (nx == @px && ny == @py) || @enemies.any? { |o| o[:alive] && o[:x] == nx && o[:y] == ny }
          e[:x] = nx
          e[:y] = ny
        end
      end
    end
  end

  def do_whirlwind
    return if @nova <= 0 || @sliding
    @nova -= 1
    @shake_t = 8
    hit = 0
    [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |d|
      tx = @px + d[0]
      ty = @py + d[1]
      burst(tx, ty, 12) if tx >= 0 && tx < GRID_W && ty >= 0 && ty < GRID_H
      @enemies.each do |e|
        if e[:alive] && e[:x] == tx && e[:y] == ty
          e[:alive] = false
          hit += 1
          @score += 120
          burst(tx, ty, 10)
        end
      end
    end
    @enemies.reject! { |e| !e[:alive] }
    $knight_best_score = @score if @score > $knight_best_score
    @popups << { x: OX + @px * CELL + 12, y: OY + @py * CELL - 8, text: hit > 0 ? "NOVA x#{hit}!" : "NOVA!", col: 12, life: 26 }
    check_floor_clear
  end

  def check_floor_clear
    if @enemies.empty? && !@dead
      @floor += 1
      $knight_best_floor = @floor if @floor > $knight_best_floor
      @score += 300
      $knight_best_score = @score if @score > $knight_best_score
      @nova += 1 if @nova < 3
      @hp += 1 if @floor % 3 == 0 && @hp < 5
      @popups << { x: 128, y: 120, text: "FLOOR #{@floor}!", col: 10, life: 36 }
      generate_floor
    end
  end

  def update
    @t += 1
    @shake_t -= 1 if @shake_t > 0

    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }
    @popups.each do |pp|
      pp[:y] -= 0.5
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }

    if @dead
      @dead_timer += 1
      if @dead_timer > 30 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    if @sliding
      @slide_timer -= 1
      if @slide_timer <= 0
        @slide_timer = 2
        nx = @px + @slide_dx
        ny = @py + @slide_dy
        if pillar_at?(nx, ny)
          @sliding = false
          @shake_t = 4
          enemy_turn unless @enemies.empty?
          check_floor_clear
        else
          @px = nx
          @py = ny
          burst(@px, @py, 12)
          @enemies.each do |e|
            if e[:alive] && e[:x] == @px && e[:y] == @py
              e[:alive] = false
              @slide_combo += 1
              pts = 100 * @slide_combo
              @score += pts
              $knight_best_score = @score if @score > $knight_best_score
              @shake_t = 6
              burst(@px, @py, 10)
              @popups << { x: OX + @px * CELL + 12, y: OY + @py * CELL - 6, text: @slide_combo > 1 ? "x#{@slide_combo} +#{pts}" : "+#{pts}", col: 10, life: 24 }
            end
          end
          @enemies.reject! { |e| !e[:alive] }
        end
      end
      return
    end

    dx = 0; dy = 0
    if btnp(0)
      dx = -1
    elsif btnp(1)
      dx = 1
    elsif btnp(2)
      dy = -1
    elsif btnp(3)
      dy = 1
    elsif btnp(4) || btnp(5)
      do_whirlwind
      return
    elsif btnp(:mouse_l)
      mx = (mouse_x - OX) / CELL
      my = (mouse_y - OY) / CELL
      if (mx - @px).abs > (my - @py).abs
        dx = mx > @px ? 1 : -1
      elsif my != @py
        dy = my > @py ? 1 : -1
      else
        do_whirlwind
        return
      end
    end

    if (dx != 0 || dy != 0) && !pillar_at?(@px + dx, @py + dy)
      @sliding = true
      @slide_dx = dx
      @slide_dy = dy
      @slide_timer = 0
      @slide_combo = 0
    end
  end

  def draw
    cls(0)
    shk_x = @shake_t > 0 ? rand(-2..2) : 0
    shk_y = @shake_t > 0 ? rand(-2..2) : 0
    bg(:mountain, dim: 0.45, tint: [155, 210, 255], scale: 1.04, scroll_x: shk_x * 0.3, y: shk_y * 0.3)

    camera(shk_x, shk_y)

    # 8x8 氷盤面
    gy = 0
    while gy < GRID_H
      gx = 0
      while gx < GRID_W
        cx = OX + gx * CELL
        cy = OY + gy * CELL
        col = ((gx + gy) % 2 == 0) ? 1 : 12
        rectfill(cx, cy, CELL, CELL, col == 12 ? 1 : 0)
        rect(cx, cy, CELL, CELL, 12)
        gx += 1
      end
      gy += 1
    end

    # 石柱
    @pillars.each do |p|
      cx = OX + p[:x] * CELL + 2
      cy = OY + p[:y] * CELL + 2
      rectfill(cx, cy, CELL - 4, CELL - 4, 5)
      rect(cx, cy, CELL - 4, CELL - 4, 7)
    end

    # 敵
    @enemies.each do |e|
      next unless e[:alive]
      spr(e[:kind], OX + e[:x] * CELL + 4, OY + e[:y] * CELL + 4)
    end

    # 騎士
    unless @dead
      spr(:knight, OX + @px * CELL + 4, OY + @py * CELL + 4)
    end

    @particles.each { |p| rectfill(p[:x].to_i, p[:y].to_i, 2, 2, p[:col]) }
    @popups.each { |pp| print_text(pp[:text], pp[:x] - pp[:text].length * 3, pp[:y].to_i, pp[:col]) }

    camera()
    clip()

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 12)
    print_text("F:#{@floor}", 6, 6, 12)
    print_text("SCR:#{@score}", 54, 6, 7)
    print_text("NOVA:#{@nova}", 134, 6, 10)
    i = 0
    while i < 5
      circfill(210 + i * 9, 10, 3, i < @hp ? 8 : 5)
      i += 1
    end

    print_text("ARROWS: SLIDE  |  Z: NOVA (#{@nova})", 34, 238, 7)

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("FROZEN IN THE ABYSS!", 68, 96, 8)
      print_text("FLOOR : #{@floor}", 76, 114, 12)
      print_text("SCORE : #{@score}", 76, 128, 7)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 148, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #090C18
1: #1D2B53
5: #5F574F
6: #C2C3C7
7: #FFF1E8
8: #FF004D
A: #FFEC27
B: #00E436
C: #29ADFF

@SPRITE :knight 16x16 pal:1
................
.....000000.....
....06666660....
...0677777760...
...0600660060...
....06666660....
...0CCCCCCCC0...
..060CCCCCC060..
..060CCAA0C060..
...00CCCCCC00...
....01100110....
....01100110....
....000..000....
................
................
................

@SPRITE :ice_slime 16x16 pal:1
................
.....000000.....
...00CCCCCC00...
..0CC77CCCCCC0..
..0C7C0CCC0CC0..
.0CCCC0CCC0CCC0.
.0CCCCCCCCCCCC0.
.0CCCC1111CCCC0.
..0CC111111CC0..
...0011111100...
.....000000.....
................
................
................
................
................

@SPRITE :skull 16x16 pal:1
................
....00000000....
...0777777770...
..077007700770..
..077007700770..
...0777007770...
....07777770....
....00707000....
.....088880.....
....08800880....
................
................
................
................
................
................
