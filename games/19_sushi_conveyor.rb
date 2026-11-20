# ==============================================================================
# 19. SUSHI CONVEYOR
# ------------------------------------------------------------------------------
# 注文通りにネタを握って皿を飛ばす爆速回転寿司アクション
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   マウスクリック : 下部ネタボタンをクリックして注文客へ皿を飛ばす!
#   ← / → + Z      : ネタ選択 & 提供 (Xで即提供も可)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "19. SUSHI CONVEYOR"
)

SUSHI_TYPES = [
  { id: :maguro, name: "TUNA",   col: 8 },
  { id: :salmon, name: "SALMON", col: 9 },
  { id: :tamago, name: "EGG",    col: 10 },
  { id: :ebi,    name: "SHRIMP", col: 14 }
]

$sushi_best ||= 0

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
    bg(:training, dim: 0.55, tint: [185, 125, 85])

    spr(:maguro, 68, 168)
    spr(:salmon, 100, 168)
    spr(:tamago, 132, 168)
    spr(:ebi, 164, 168)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 9)
    print_text("SUSHI CONVEYOR", 86, 32, 10)
    print_text("FAST-PACED SUSHI CHEF ACTION!", 38, 46, 7)

    rectfill(24, 78, 208, 58, 0)
    rect(24, 78, 208, 58, 5)
    print_text("CLICK SUSHI / ARROWS+Z : SERVE!", 32, 88, 10)
    print_text("MATCH ORDERS BEFORE TIME OUT!", 32, 102, 7)
    if $sushi_best > 0
      print_text("HIGH SCORE: #{$sushi_best}", 74, 118, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO OPEN SHOP", 41, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @score = 0
    @combo = 0
    @misses = 0
    @sel_idx = 0
    @served_total = 0

    @seats = [nil, nil, nil, nil]
    @flying = []
    @popups = []
    @particles = []
    @spawn_cd = 15
    @dead = false
    @dead_timer = 0
  end

  def spawn_customer
    empty_indices = []
    @seats.each_with_index { |s, i| empty_indices << i if s.nil? }
    return if empty_indices.empty?
    si = empty_indices[rand(empty_indices.size)]
    pat_max = 360 - (@served_total * 3)
    pat_max = 160 if pat_max < 160
    @seats[si] = {
      order: rand(SUSHI_TYPES.size),
      pat: pat_max, max_pat: pat_max
    }
  end

  def serve_sushi(sushi_idx)
    # 最も忍耐が少ない一致客を探す
    best_seat = nil
    best_pat = 999999
    @seats.each_with_index do |s, i|
      next if s.nil?
      if s[:order] == sushi_idx && s[:pat] < best_pat
        best_pat = s[:pat]
        best_seat = i
      end
    end

    sx = (36 + sushi_idx * 58).to_f
    sy = 204.0

    if best_seat
      tx = (36 + best_seat * 58).to_f
      ty = 72.0
      @flying << { x: sx, y: sy, tx: tx, ty: ty, kind: sushi_idx, seat: best_seat }
    else
      # ミス提供
      @combo = 0
      @popups << { x: sx.to_i, y: 170, text: "NO ORDER!", col: 8, life: 24 }
    end
  end

  def update
    @t += 1
    @popups.each do |pp|
      pp[:y] -= 0.5
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }
    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }

    if @dead
      @dead_timer += 1
      if @dead_timer > 30 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    # 入力
    @sel_idx = (@sel_idx - 1) % 4 if btnp(0)
    @sel_idx = (@sel_idx + 1) % 4 if btnp(1)
    serve_sushi(@sel_idx) if btnp(4) || btnp(5)

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 186 && my <= 238
        i = 0
        while i < 4
          bx = 14 + i * 58
          if mx >= bx && mx <= bx + 52
            @sel_idx = i
            serve_sushi(i)
          end
          i += 1
        end
      end
    end

    # 客スポーン
    @spawn_cd -= 1
    if @spawn_cd <= 0
      spawn_customer
      cd = 72 - @served_total
      cd = 28 if cd < 28
      @spawn_cd = cd
    end

    # 飛行皿更新
    @flying.each do |fl|
      fl[:x] += (fl[:tx] - fl[:x]) * 0.28
      fl[:y] += (fl[:ty] - fl[:y]) * 0.28
      if (fl[:x] - fl[:tx]).abs < 4.0 && (fl[:y] - fl[:ty]).abs < 4.0
        fl[:done] = true
        s = @seats[fl[:seat]]
        if s && s[:order] == fl[:kind]
          @seats[fl[:seat]] = nil
          @combo += 1
          @served_total += 1
          pts = 50 + @combo * 15
          @score += pts
          $sushi_best = @score if @score > $sushi_best
          @popups << { x: fl[:tx].to_i, y: 54, text: @combo > 1 ? "x#{@combo} +#{pts}" : "+#{pts}", col: 10, life: 28 }
          i = 0
          while i < 8
            ang = rand() * Math::PI * 2.0
            @particles << { x: fl[:tx], y: fl[:ty], vx: cos(ang) * 2.0, vy: sin(ang) * 2.0, col: 10, life: 14 }
            i += 1
          end
        end
      end
    end
    @flying.reject! { |fl| fl[:done] }

    # 忍耐減少
    @seats.each_with_index do |s, i|
      next if s.nil?
      s[:pat] -= 1
      if s[:pat] <= 0
        @seats[i] = nil
        @combo = 0
        @misses += 1
        @popups << { x: 36 + i * 58, y: 66, text: "ANGRY!", col: 8, life: 30 }
        if @misses >= 3
          @dead = true
          @dead_timer = 0
        end
      end
    end
  end

  def draw
    cls(0)
    bg(:training, dim: 0.55, tint: [185, 125, 85])

    # コンベアベルト
    rectfill(0, 128, 256, 26, 5)
    line(0, 128, 256, 128, 6)
    line(0, 154, 256, 154, 6)
    off = (@t * 2) % 32
    x = -off
    while x < 260
      circ(x, 141, 8, 7)
      x += 32
    end

    # 客席 4つ
    i = 0
    while i < 4
      cx = 36 + i * 58
      rectfill(cx - 22, 30, 44, 86, 1)
      rect(cx - 22, 30, 44, 86, 5)
      s = @seats[i]
      if s
        st = SUSHI_TYPES[s[:order]]
        spr(:customer, cx - 8, 90)
        # 吹き出し
        rectfill(cx - 16, 38, 32, 34, 7)
        rect(cx - 16, 38, 32, 34, 0)
        spr(st[:id], cx - 8, 42)
        print_text(st[:name][0, 4], cx - 12, 60, 0)
        # 忍耐バー
        pw = (s[:pat] * 36 / s[:max_pat]).to_i
        pcol = pw > 18 ? 11 : (pw > 9 ? 10 : 8)
        rectfill(cx - 18, 78, 36, 4, 0)
        rectfill(cx - 18, 78, pw, 4, pcol)
      else
        print_text("OPEN", cx - 12, 68, 5)
      end
      i += 1
    end

    # 飛行皿
    @flying.each do |fl|
      st = SUSHI_TYPES[fl[:kind]]
      circfill(fl[:x].to_i, fl[:y].to_i, 9, 7)
      spr(st[:id], fl[:x].to_i - 8, fl[:y].to_i - 8)
    end

    @particles.each { |p| rectfill(p[:x].to_i, p[:y].to_i, 2, 2, p[:col]) }
    @popups.each { |pp| print_text(pp[:text], pp[:x] - pp[:text].length * 3, pp[:y].to_i, pp[:col]) }

    # 下部ネタトレイ
    rectfill(0, 176, 256, 80, 0)
    line(0, 176, 256, 176, 4)
    i = 0
    while i < 4
      st = SUSHI_TYPES[i]
      bx = 14 + i * 58
      sel = (i == @sel_idx)
      rectfill(bx, 186, 52, 52, sel ? 1 : 0)
      rect(bx, 186, 52, 52, sel ? 10 : st[:col])
      spr(st[:id], bx + 18, 196)
      print_text(st[:name], bx + 8, 220, st[:col])
      i += 1
    end

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("SCR:#{@score}", 6, 6, 7)
    print_text("COMBO:#{@combo}", 88, 6, 10)
    print_text("MISS:#{@misses}/3", 184, 6, @misses >= 2 ? 8 : 12)

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("SHOP CLOSED!", 92, 96, 8)
      print_text("SCORE  : #{@score}", 74, 114, 7)
      print_text("SERVED : #{@served_total}", 74, 126, 10)
      print_text("BEST   : #{$sushi_best}", 74, 138, 12)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 154, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #0A0814
4: #8A4836
5: #5F574F
6: #C2C3C7
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
C: #29ADFF
E: #FF77A8
F: #FFCCAA

@SPRITE :maguro 16x16 pal:1
................
................
....00000000....
...0888788880...
..088888788880..
..088888888880..
..007777777700..
...0777777770...
....00000000....
................
................
................
................
................
................
................

@SPRITE :salmon 16x16 pal:1
................
................
....00000000....
...0997997990...
..099997999970..
..099999999990..
..007777777700..
...0777777770...
....00000000....
................
................
................
................
................
................
................

@SPRITE :tamago 16x16 pal:1
................
................
....00000000....
...0AAAAAAAA0...
..0AA77AAAAAA0..
..0AAAAA00AAA0..
..007777007700..
...0777700770...
....00000000....
................
................
................
................
................
................
................

@SPRITE :ebi 16x16 pal:1
................
................
....00000000....
...0E7EE7EE80...
..0EEEEE7EE880..
..0EEEEEEEE880..
..007777777700..
...0777777770...
....00000000....
................
................
................
................
................
................
................

@SPRITE :customer 16x16 pal:1
................
.....000000.....
....04444440....
...044FFFF440...
...04F0FF0F40...
....00FFFF00....
...0CCCCCCCC0...
..0CC0CCCC0CC0..
....0CCCCCC0....
................
................
................
................
................
................
................
