# ==============================================================================
# 21. PIXEL AQUARIUM
# ------------------------------------------------------------------------------
# 熱帯魚・クラゲが泳ぎ繁殖する癒やしのインタラクティブ水槽
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   クリック / Z : 水槽内にエサをまく (下部ボタンで魚やクラゲを追加購入!)
#   X            : バブルエアー発生
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "21. PIXEL AQUARIUM"
)

def clamp_v(v, lo, hi)
  return lo if v < lo
  return hi if v > hi
  v
end

class TitleScene
  def initialize
    @t = 0
  end

  def update
    @t += 1
    if btnp(1) || btnp(:mouse_l)
      run GameScene.new
    end
  end

  def draw
    cls(0)
    bg(:cave, dim: 0.35, tint: [85, 170, 230])

    # デモ魚
    fx = 60 + (@t % 140)
    spr(:clown, fx, 162)
    spr(:jelly, 180, 148 + (sin(@t * 0.08) * 6.0).to_i)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 12)
    print_text("PIXEL AQUARIUM", 86, 32, 10)
    print_text("FEED, GROW & BREED RARE FISH!", 41, 46, 12)

    rectfill(24, 78, 208, 56, 0)
    rect(24, 78, 208, 56, 5)
    print_text("CLICK / Z : DROP FISH FOOD", 42, 88, 7)
    print_text("SHOP BAR  : ADD FISH & JELLY", 42, 101, 10)
    print_text("WELL-FED FISH BREED & DROP GOLD!", 34, 114, 11)

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO RELAX", 53, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @gold = 25
    @breeds = 0
    @fishes = []
    @foods = []
    @bubbles = []
    @coins = []
    @popups = []
    @weeds = []

    i = 0
    while i < 10
      @weeds << { x: 16 + i * 24 + rand(8), h: 24 + rand(22), phase: rand() * 6.0 }
      i += 1
    end

    add_fish(:clown, 80.0, 110.0)
    add_fish(:tetra, 160.0, 90.0)
    add_fish(:jelly, 128.0, 140.0)
  end

  def add_fish(kind, x, y)
    return if @fishes.size >= 24
    @fishes << {
      kind: kind, x: x, y: y,
      vx: (rand() < 0.5 ? 0.6 : -0.6), vy: (rand() - 0.5) * 0.3,
      fed: 0, phase: rand() * 6.0, coin_cd: 180 + rand(180)
    }
  end

  def drop_food(x, y)
    i = 0
    while i < 3
      @foods << { x: clamp_v(x + (rand() - 0.5) * 14.0, 12.0, 244.0), y: clamp_v(y, 26.0, 200.0), vy: 0.35 }
      i += 1
    end
  end

  def update
    @t += 1

    # 泡生成
    if @t % 12 == 0
      @bubbles << { x: 16.0 + rand() * 224.0, y: 214.0, vy: -0.55 - rand() * 0.4, r: 1 + rand(2) }
    end
    if btnp(2)
      i = 0
      while i < 10
        @bubbles << { x: 20.0 + rand() * 216.0, y: 214.0, vy: -0.7 - rand() * 0.6, r: 1 + rand(2) }
        i += 1
      end
    end

    # 操作
    if btnp(1)
      drop_food(40.0 + rand() * 176.0, 42.0)
    end
    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 224
        if mx < 86 && @gold >= 10
          @gold -= 10
          add_fish(rand(2) == 0 ? :clown : :tetra, 40.0 + rand() * 176.0, 60.0 + rand() * 100.0)
        elsif mx >= 86 && mx < 170 && @gold >= 20
          @gold -= 20
          add_fish(:jelly, 40.0 + rand() * 176.0, 60.0 + rand() * 100.0)
        elsif mx >= 170 && @gold >= 35
          @gold -= 35
          add_fish(:rare, 40.0 + rand() * 176.0, 60.0 + rand() * 100.0)
        end
      elsif my > 20
        # コイン回収チェック
        got_coin = false
        @coins.each do |c|
          dx = mx - c[:x]
          dy = my - c[:y]
          if dx * dx + dy * dy < 14.0 * 14.0
            c[:got] = true
            got_coin = true
            @gold += c[:val]
            @popups << { x: c[:x].to_i, y: c[:y].to_i, text: "+#{c[:val]}G", col: 10, life: 24 }
          end
        end
        @coins.reject! { |c| c[:got] }
        drop_food(mx.to_f, my.to_f) unless got_coin
      end
    end

    # エサ更新
    @foods.each do |fd|
      fd[:y] += fd[:vy]
      fd[:x] += sin(@t * 0.1 + fd[:y] * 0.1) * 0.2
    end
    @foods.reject! { |fd| fd[:y] > 214.0 }

    # 魚更新
    new_babies = []
    @fishes.each do |f|
      # 近くのエサを探す
      nearest = nil
      best_d2 = 90.0 * 90.0
      @foods.each do |fd|
        dx = fd[:x] - f[:x]
        dy = fd[:y] - f[:y]
        d2 = dx * dx + dy * dy
        if d2 < best_d2
          best_d2 = d2
          nearest = fd
        end
      end

      if nearest
        dx = nearest[:x] - f[:x]
        dy = nearest[:y] - f[:y]
        d = sqrt(dx * dx + dy * dy)
        if d < 8.0
          nearest[:y] = 999.0
          f[:fed] += 1
          @gold += 3
          @popups << { x: f[:x].to_i, y: f[:y].to_i - 8, text: "YUM!", col: 11, life: 18 }
          if f[:fed] >= 3
            f[:fed] = 0
            @breeds += 1
            baby_kind = f[:kind]
            baby_kind = :rare if rand(5) == 0
            new_babies << [baby_kind, f[:x], f[:y]]
            @popups << { x: f[:x].to_i, y: f[:y].to_i - 16, text: "BREED!", col: 14, life: 30 }
          end
        elsif d > 0.1
          f[:vx] = dx / d * 1.1
          f[:vy] = dy / d * 0.9
        end
      else
        if f[:kind] == :jelly
          f[:vy] = sin(@t * 0.06 + f[:phase]) * 0.45
          f[:vx] *= 0.99
          f[:vx] = (rand() < 0.5 ? 0.3 : -0.3) if f[:vx].abs < 0.15
        else
          f[:vy] = sin(@t * 0.05 + f[:phase]) * 0.25
        end
      end

      f[:x] += f[:vx]
      f[:y] += f[:vy]
      if f[:x] < 14.0
        f[:x] = 14.0; f[:vx] = f[:vx].abs
      elsif f[:x] > 242.0
        f[:x] = 242.0; f[:vx] = -f[:vx].abs
      end
      f[:y] = clamp_v(f[:y], 32.0, 202.0)

      f[:coin_cd] -= 1
      if f[:coin_cd] <= 0
        f[:coin_cd] = 240 + rand(180)
        val = f[:kind] == :rare ? 10 : (f[:kind] == :jelly ? 6 : 4)
        @coins << { x: f[:x], y: f[:y], vy: 0.3, val: val, got: false }
      end
    end
    new_babies.each { |nb| add_fish(nb[0], nb[1], nb[2]) }

    @coins.each { |c| c[:y] += c[:vy] if c[:y] < 210.0 }
    @bubbles.each do |b|
      b[:y] += b[:vy]
      b[:x] += sin(@t * 0.1 + b[:y] * 0.1) * 0.2
    end
    @bubbles.reject! { |b| b[:y] < 22.0 }
    @popups.each do |pp|
      pp[:y] -= 0.4
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }
  end

  def draw
    cls(0)
    bg(:cave, dim: 0.35, tint: [85, 170, 230])

    # 砂底
    rectfill(0, 212, 256, 12, 4)
    line(0, 212, 256, 212, 15)

    # 水草
    @weeds.each do |w|
      sway = (sin(@t * 0.04 + w[:phase]) * 4.0).to_i
      line(w[:x], 212, w[:x] + sway, 212 - w[:h], 3)
      line(w[:x] + 1, 212, w[:x] + sway + 1, 212 - w[:h], 11)
    end

    # エサ
    @foods.each do |fd|
      rectfill(fd[:x].to_i - 1, fd[:y].to_i - 1, 3, 3, 9)
    end

    # コイン
    @coins.each do |c|
      circfill(c[:x].to_i, c[:y].to_i, 3, 10)
      pset(c[:x].to_i, c[:y].to_i, 7)
    end

    # 魚
    @fishes.each do |f|
      spr(f[:kind], f[:x].to_i - 8, f[:y].to_i - 8, f[:vx] < 0)
    end

    # 泡
    @bubbles.each do |b|
      circ(b[:x].to_i, b[:y].to_i, b[:r], 7)
    end

    @popups.each { |pp| print_text(pp[:text], pp[:x] - pp[:text].length * 3, pp[:y], pp[:col]) }

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 12)
    print_text("GOLD:#{@gold}G", 6, 6, 10)
    print_text("FISH:#{@fishes.size}/24", 88, 6, 12)
    print_text("BREED:#{@breeds}", 180, 6, 14)

    # 下部ショップバー
    rectfill(0, 224, 256, 32, 0)
    line(0, 224, 256, 224, 5)
    rectfill(4, 228, 78, 24, 1)
    rect(4, 228, 78, 24, @gold >= 10 ? 9 : 5)
    print_text("FISH 10G", 14, 236, @gold >= 10 ? 10 : 5)

    rectfill(88, 228, 78, 24, 1)
    rect(88, 228, 78, 24, @gold >= 20 ? 14 : 5)
    print_text("JELLY 20G", 96, 236, @gold >= 20 ? 14 : 5)

    rectfill(172, 228, 80, 24, 1)
    rect(172, 228, 80, 24, @gold >= 35 ? 11 : 5)
    print_text("RARE 35G", 182, 236, @gold >= 35 ? 11 : 5)
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #060914
2: #7E2553
3: #008751
4: #8A4836
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
B: #00E436
C: #29ADFF
E: #FF77A8
F: #FFCCAA

@SPRITE :clown 16x16 pal:1
................
................
......00000.....
....00997790....
..00999977990...
.0909999779090..
.0909999779990..
..00999977990...
....00997790....
......00000.....
................
................
................
................
................
................

@SPRITE :tetra 16x16 pal:1
................
................
.......0000.....
.....00CCCC0....
...00CC77CCC0...
..080CCCCCCC00..
..080CCC888CC0..
...00CC888880...
.....0000000....
................
................
................
................
................
................
................

@SPRITE :jelly 16x16 pal:1
................
.....000000.....
...00EEEEEE00...
..0EE77EEEEEE0..
..0EEEEEEEEEE0..
...0000000000...
....0E0.0E00E0..
....0E0.0E0.0E0.
.....0E0.0E0.0..
......0...0.....
................
................
................
................
................
................

@SPRITE :rare 16x16 pal:1
................
......00000.....
....00AAAA00....
..00AA77AAAA0...
.0A0AAAA22AAA0..
.0A0AAA2222AA0..
..00AA2222220...
....00AAAA00....
......00000.....
................
................
................
................
................
................
................
