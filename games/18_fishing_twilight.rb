# ==============================================================================
# 18. FISHING TWILIGHT
# ------------------------------------------------------------------------------
# 夕焼け湖畔で伝説魚を釣り上げる図鑑コンプ釣りゲーム
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   Z / Space / 左クリック : キャスト / ヒット時フッキング / 長押しリール巻取り
#   B / X                  : 魚図鑑 (BOOK) 表示切替
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "18. FISHING TWILIGHT"
)

WATER_Y = 148

FISH_DB = [
  { name: "CARP",      col: 9,  diff: 1, pts: 50,  wt: 30 },
  { name: "BASS",      col: 11, diff: 1, pts: 70,  wt: 26 },
  { name: "TROUT",     col: 12, diff: 2, pts: 110, wt: 20 },
  { name: "GOLD KOI",  col: 10, diff: 2, pts: 150, wt: 14 },
  { name: "EEL",       col: 2,  diff: 3, pts: 220, wt: 10 },
  { name: "CATFISH",   col: 5,  diff: 3, pts: 280, wt: 8 },
  { name: "MOON FIN",  col: 14, diff: 4, pts: 450, wt: 5 },
  { name: "LAKE KING", col: 8,  diff: 5, pts: 900, wt: 3 }
]

$fish_caught ||= [false, false, false, false, false, false, false, false]
$fish_best ||= 0

def clamp_v(v, lo, hi)
  return lo if v < lo
  return hi if v > hi
  v
end

def draw_twilight_lake(t)
  bg(:mountain, dim: 0.28, tint: [255, 155, 115])
  # 夕日
  circfill(188, 94, 22, 9)
  circfill(188, 92, 16, 10)

  # 湖面
  rectfill(0, WATER_Y, 256, 256 - WATER_Y, 1)
  line(0, WATER_Y, 256, WATER_Y, 9)

  # 水面反射キラキラ
  i = 0
  while i < 10
    ry = WATER_Y + 6 + i * 10
    rw = 26 - i * 2
    rx = 188 + (sin(t * 0.06 + i) * 6.0).to_i - rw / 2
    line(rx, ry, rx + rw, ry, i < 4 ? 10 : 9)
    i += 1
  end

  # 木の桟橋
  rectfill(0, WATER_Y - 12, 68, 6, 4)
  rectfill(16, WATER_Y - 6, 6, 24, 4)
  rectfill(54, WATER_Y - 6, 6, 24, 4)
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
    draw_twilight_lake(@t)
    spr(:angler, 44, WATER_Y - 28)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 9)
    print_text("FISHING TWILIGHT", 80, 32, 10)
    print_text("COMPLETE ALL 8 LAKE SPECIES!", 44, 46, 7)

    rectfill(24, 76, 208, 56, 0)
    rect(24, 76, 208, 56, 5)
    print_text("Z / CLICK : CAST, HOOK & REEL", 40, 86, 7)
    print_text("X         : VIEW FISH BOOK", 40, 99, 12)
    if $fish_best > 0
      print_text("BEST SCORE: #{$fish_best}", 74, 114, 10)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO FISH", 56, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @score = 0
    @state = :idle
    @bob_x = 136.0
    @bob_y = WATER_Y.to_f
    @wait_t = 0
    @bite_t = 0
    @cur_fish = nil

    @reel_pos = 50.0
    @reel_zone = 40.0
    @reel_prog = 20.0
    @show_book = false

    @splashes = []
    @popups = []
    @swimmers = []
    i = 0
    while i < 5
      @swimmers << { x: 80.0 + rand() * 150.0, y: WATER_Y + 18.0 + rand() * 68.0, vx: (rand() < 0.5 ? 0.4 : -0.4) }
      i += 1
    end
  end

  def pick_fish
    total = 0
    FISH_DB.each { |f| total += f[:wt] }
    r = rand(total)
    acc = 0
    FISH_DB.each_with_index do |f, idx|
      acc += f[:wt]
      return idx if r < acc
    end
    0
  end

  def add_splash(x, y, col = 7, cnt = 8)
    i = 0
    while i < cnt
      @splashes << {
        x: x, y: y,
        vx: (rand() - 0.5) * 2.4, vy: -1.0 - rand() * 1.8,
        col: col, life: 18
      }
      i += 1
    end
  end

  def update
    @t += 1

    @swimmers.each do |sw|
      sw[:x] += sw[:vx]
      sw[:vx] = -sw[:vx] if sw[:x] < 72.0 || sw[:x] > 244.0
    end

    @splashes.each do |sp|
      sp[:x] += sp[:vx]
      sp[:y] += sp[:vy]
      sp[:vy] += 0.14
      sp[:life] -= 1
    end
    @splashes.reject! { |sp| sp[:life] <= 0 }
    @popups.each do |pp|
      pp[:y] -= 0.5
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }

    if btnp(5)
      @show_book = !@show_book
      return
    end
    return if @show_book

    action_press = btnp(4) || btnp(:mouse_l)
    action_hold = btn(4) || btn(:mouse_l)

    if @state == :idle
      if action_press
        @state = :wait
        @bob_x = 120.0 + rand() * 90.0
        @bob_y = WATER_Y.to_f + 4.0
        @wait_t = 45 + rand(70)
        add_splash(@bob_x, @bob_y, 7, 6)
      end
    elsif @state == :wait
      @wait_t -= 1
      if @wait_t <= 0
        @state = :bite
        @bite_t = 45
        @cur_fish = pick_fish
        add_splash(@bob_x, @bob_y, 10, 10)
      elsif action_press
        @state = :idle
      end
    elsif @state == :bite
      @bite_t -= 1
      if action_press
        @state = :reel
        @reel_pos = 50.0
        @reel_zone = 45.0
        @reel_prog = 25.0
      elsif @bite_t <= 0
        @state = :idle
        @popups << { x: @bob_x.to_i, y: @bob_y.to_i - 12, text: "GOT AWAY...", col: 6, life: 28 }
      end
    elsif @state == :reel
      f = FISH_DB[@cur_fish]
      # リールカーソル操作
      if action_hold
        @reel_pos += 2.6
      else
        @reel_pos -= 2.1
      end
      @reel_pos = clamp_v(@reel_pos, 4.0, 96.0)

      # ターゲットゾーンが左右に揺れる
      @reel_zone += sin(@t * (0.06 + f[:diff] * 0.015)) * (0.9 + f[:diff] * 0.35)
      @reel_zone = clamp_v(@reel_zone, 16.0, 84.0)

      if (@reel_pos - @reel_zone).abs <= 16.0
        @reel_prog += 0.85
        add_splash(@bob_x, @bob_y, 12, 1) if @t % 4 == 0
      else
        @reel_prog -= 0.45
      end

      if @reel_prog >= 100.0
        @state = :caught
        @caught_t = 70
        is_new = !$fish_caught[@cur_fish]
        $fish_caught[@cur_fish] = true
        @score += f[:pts]
        $fish_best = @score if @score > $fish_best
        add_splash(@bob_x, @bob_y, f[:col], 16)
        lbl = is_new ? "NEW! #{f[:name]}" : "#{f[:name]} +#{f[:pts]}"
        @popups << { x: 128, y: 90, text: lbl, col: 10, life: 60 }
      elsif @reel_prog <= 0.0
        @state = :idle
        @popups << { x: @bob_x.to_i, y: @bob_y.to_i - 12, text: "LINE SNAPPED!", col: 8, life: 30 }
      end
    elsif @state == :caught
      @caught_t -= 1
      if @caught_t <= 0 || action_press
        @state = :idle
      end
    end
  end

  def draw
    cls(0)
    draw_twilight_lake(@t)

    # 水中の魚影
    @swimmers.each do |sw|
      rectfill(sw[:x].to_i - 4, sw[:y].to_i - 1, 8, 3, 0)
    end

    # 釣り人 & 竿
    spr(:angler, 44, WATER_Y - 28)
    rod_x = 62
    rod_y = WATER_Y - 24
    line(54, WATER_Y - 18, rod_x, rod_y, 4)

    if @state == :wait || @state == :bite || @state == :reel
      by = @bob_y.to_i + (@state == :bite ? rand(-2..2) : (sin(@t * 0.1) * 1.5).to_i)
      line(rod_x, rod_y, @bob_x.to_i, by, 7)
      circfill(@bob_x.to_i, by, 3, 8)
      pset(@bob_x.to_i, by - 1, 7)
      if @state == :bite
        print_text("!! HIT !!", @bob_x.to_i - 24, by - 16, 10)
      end
    end

    if @state == :reel
      # リールバーUI
      rectfill(58, 198, 140, 28, 0)
      rect(58, 198, 140, 28, 7)
      # ターゲットゾーン
      zx = 64 + (@reel_zone - 16.0) * 1.28
      rectfill(zx.to_i, 202, 40, 10, 11)
      # カーソル
      px = 64 + @reel_pos * 1.28
      rectfill(px.to_i - 2, 201, 4, 12, 10)
      # 進捗バー
      pw = (@reel_prog * 1.28).to_i
      rectfill(64, 216, pw, 5, 12)
      print_text("HOLD Z/CLICK TO REEL!", 64, 186, 10)
    end

    @splashes.each { |sp| rectfill(sp[:x].to_i, sp[:y].to_i, 2, 2, sp[:col]) }
    @popups.each { |pp| print_text(pp[:text], pp[:x] - pp[:text].length * 3, pp[:y], pp[:col]) }

    # HUD
    caught_cnt = $fish_caught.count { |c| c }
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("SCR:#{@score}", 6, 6, 7)
    print_text("BOOK:#{caught_cnt}/8", 88, 6, 10)
    print_text("[X] BOOK", 198, 6, 12)

    if @state == :idle && !@show_book
      print_text("PRESS Z OR CLICK TO CAST!", 53, 232, 10)
    end

    if @show_book
      rectfill(24, 34, 208, 192, 0)
      rect(24, 34, 208, 192, 10)
      print_text("LAKE FISH ENCYCLOPEDIA", 62, 44, 10)
      FISH_DB.each_with_index do |f, idx|
        fy = 66 + idx * 18
        got = $fish_caught[idx]
        circfill(40, fy + 3, 4, got ? f[:col] : 5)
        print_text(got ? f[:name] : "???", 52, fy, got ? 7 : 5)
        print_text(got ? "#{f[:pts]}PT" : "---", 168, fy, got ? 10 : 5)
      end
      print_text("PRESS X TO CLOSE", 80, 212, 12)
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #0A0814
4: #8A4836
7: #FFF1E8
8: #FF004D
A: #FFEC27
C: #29ADFF
F: #FFCCAA

@SPRITE :angler 16x16 pal:1
................
....00000000....
...0444444440...
..000000000000..
....07777770....
...0770770770...
....00FFFF00....
...0888888880...
...0CCCCCCCC0...
...0CCCCCCCC0...
....04400440....
....04400440....
....000..000....
................
................
................
