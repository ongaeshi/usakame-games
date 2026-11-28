# ==============================================================================
# 28. WORLD GLIDER
# ------------------------------------------------------------------------------
# 内蔵全BG世界を風に乗って輪くぐり滑空するチル＆スコアデモ
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ↑ / ↓ / マウス上下 : 滑空高度操作
#   Z / クリック : 風ブースト加速
#   X                    : オートパイロット切替
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "28. WORLD GLIDER"
)

WORLDS = [
  { name: "AZURE SKY",     bg: :sky,      tint: [220, 240, 255] },
  { name: "HIGHLAND",      bg: :mountain, tint: [255, 210, 175] },
  { name: "DEEP FOREST",   bg: :forest,   tint: [185, 240, 200] },
  { name: "CRYSTAL CAVE",  bg: :cave,     tint: [145, 200, 255] },
  { name: "TWILIGHT CITY", bg: :city,     tint: [195, 185, 255] },
  { name: "STARLIGHT",     bg: :space,    tint: [220, 210, 255] },
  { name: "CYBER GRID",    bg: :cyber,    tint: [145, 245, 255] },
  { name: "DREAM MATRIX",  bg: :training, tint: [175, 235, 215] }
]

$glider_best ||= 0

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
    bg(:sky, dim: 0.25, scroll_x: @t * 0.4, mirror_x: true)

    gy = 164 + (sin(@t * 0.06) * 8.0).to_i
    spr(:glider, 120, gy)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 12)
    print_text("WORLD GLIDER", 92, 32, 10)
    print_text("SOAR THROUGH ALL 8 WORLDS!", 47, 46, 12)

    rectfill(24, 78, 208, 56, 0)
    rect(24, 78, 208, 56, 5)
    print_text("UP/DOWN / MOUSE : STEER GLIDER", 36, 88, 7)
    print_text("Z / CLICK       : WIND BOOST", 36, 101, 10)
    print_text("X               : CHILL AUTOPILOT", 36, 114, 11)

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO SOAR", 56, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @py = 128.0
    @vy = 0.0
    @scroll_x = 0.0
    @spd = 2.2
    @boost_t = 0
    @auto = false
    @idle_t = 0

    @score = 0
    @combo = 0
    @world_idx = 0
    @rings = []
    @winds = []
    @popups = []
    @sparks = []
    @next_ring_x = 220.0

    i = 0
    while i < 12
      @winds << { x: rand() * 256.0, y: 24.0 + rand() * 220.0, len: 10 + rand(18) }
      i += 1
    end
  end

  def update
    @t += 1
    @boost_t -= 1 if @boost_t > 0

    if btnp(2)
      @auto = !@auto
    end

    manual = false
    if btn(:up)
      @vy -= 0.25; manual = true
    elsif btn(:down)
      @vy += 0.25; manual = true
    end

    if btnp(1) || btnp(:mouse_l)
      @boost_t = 20
      manual = true
    end

    if manual
      @idle_t = 0
      @auto = false if btn(:up) || btn(:down)
    else
      @idle_t += 1
      @auto = true if @idle_t > 180
    end

    if @auto && !@rings.empty?
      target = @rings.first
      @rings.each do |r|
        if r[:x] > 48.0 && !r[:got]
          target = r
          break
        end
      end
      dy = target[:y] - @py
      @vy += clamp_v(dy * 0.03, -0.22, 0.22)
    end

    @vy *= 0.88
    @py = clamp_v(@py + @vy, 30.0, 236.0)

    cur_spd = @boost_t > 0 ? 4.2 : @spd
    @scroll_x += cur_spd
    @world_idx = (@scroll_x / 420.0).to_i % WORLDS.size

    @next_ring_x -= cur_spd
    if @next_ring_x <= 270.0
      @rings << { x: 276.0, y: 52.0 + rand() * 156.0, got: false }
      @next_ring_x += 78.0 + rand() * 28.0
    end

    @rings.each do |r|
      r[:x] -= cur_spd
      if !r[:got] && (r[:x] - 60.0).abs < 12.0 && (r[:y] - @py).abs < 20.0
        r[:got] = true
        @combo += 1
        pts = 100 + @combo * 20
        @score += pts
        $glider_best = @score if @score > $glider_best
        @popups << { x: 68, y: @py.to_i - 12, text: "+#{pts}", col: 10, life: 24 }
        i = 0
        while i < 8
          ang = rand() * Math::PI * 2.0
          @sparks << { x: 60.0, y: @py, vx: cos(ang) * 2.0, vy: sin(ang) * 2.0, col: 10, life: 14 }
          i += 1
        end
      elsif !r[:got] && r[:x] < 40.0
        @combo = 0
      end
    end
    @rings.reject! { |r| r[:x] < -24.0 }

    @winds.each do |w|
      w[:x] -= cur_spd * 1.4
      if w[:x] < -30.0
        w[:x] = 264.0
        w[:y] = 24.0 + rand() * 220.0
      end
    end

    @sparks.each do |s|
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }
    @popups.each do |pp|
      pp[:y] -= 0.5
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }
  end

  def draw
    cls(0)
    w = WORLDS[@world_idx]
    bg(w[:bg], dim: 0.32, tint: w[:tint], scroll_x: @scroll_x * 0.45, mirror_x: true)

    # 風線
    @winds.each do |wd|
      line(wd[:x].to_i, wd[:y].to_i, wd[:x].to_i + wd[:len], wd[:y].to_i, 7)
    end

    # スカイリング
    @rings.each do |r|
      col = r[:got] ? 11 : 10
      oval(r[:x].to_i, r[:y].to_i, 7, 18, col)
      oval(r[:x].to_i, r[:y].to_i, 6, 17, col)
    end

    # グライダー
    deg = @vy * 8.0
    spr_ext(:glider, 60, @py.to_i, deg, 1.0, 1.0, false, false)

    @sparks.each { |s| rectfill(s[:x].to_i, s[:y].to_i, 2, 2, s[:col]) }
    @popups.each { |pp| print_text(pp[:text], pp[:x], pp[:y], pp[:col]) }

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text(w[:name], 6, 6, 12)
    print_text("SCR:#{@score}", 112, 6, 7)
    print_text(@auto ? "AUTO[X]" : "x#{@combo}", 204, 6, @auto ? 11 : 10)
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #080A14
7: #FFF1E8
8: #FF004D
A: #FFEC27
C: #29ADFF

@SPRITE :glider 16x16 pal:1
................
................
......0000......
....00777700....
...077CCCC770...
..07CCCCCCCC70..
.00077888877000.
....00000000....
......0AA0......
.......00.......
................
................
................
................
................
................
