# ==============================================================================
# 20. RHYTHM SMITH
# ------------------------------------------------------------------------------
# 視覚リング目押しで赤熱の剣を叩き名剣を鍛える鍛冶クラフト
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   Z / Space / 左クリック : リングが重なる瞬間にハンマー打撃!
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "20. RHYTHM SMITH"
)

BLADES = [
  { name: "IRON DAGGER",    spd: 1.25, col: 6 },
  { name: "STEEL KATANA",   spd: 1.55, col: 7 },
  { name: "FLAME BLADE",    spd: 1.85, col: 9 },
  { name: "STAR RAPIER",    spd: 2.15, col: 12 },
  { name: "DRAGONSLAYER",   spd: 2.45, col: 10 }
]

ANVIL_X = 128.0
ANVIL_Y = 152.0
TARGET_R = 20.0

$smith_best ||= 0

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
    bg(:cave, dim: 0.45, tint: [255, 130, 95])

    spr(:smith, 88, 152)
    rectfill(112, 168, 32, 12, 5)
    circ(128, 152, 20, 10)
    circ(128, 152, 20 + ((60 - (@t % 60)) / 2), 9)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 9)
    print_text("RHYTHM SMITH", 92, 32, 10)
    print_text("HAMMER ON THE RING TO FORGE!", 44, 46, 7)

    rectfill(24, 78, 208, 56, 0)
    rect(24, 78, 208, 56, 5)
    print_text("Z / SPACE / CLICK : STRIKE ANVIL", 32, 88, 10)
    print_text("FORGE 5 LEGENDARY BLADES!", 32, 102, 7)
    if $smith_best > 0
      print_text("HIGH SCORE: #{$smith_best}", 74, 117, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO FORGE", 53, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @blade_idx = 0
    @strike = 0
    @strikes_per_blade = 6
    @score = 0
    @combo = 0
    @quality = 0

    @ring_r = 74.0
    @hammer_t = 0
    @shake_t = 0
    @flash_t = 0
    @pause_t = 0
    @sparks = []
    @popups = []
    @finished = false
    @fin_timer = 0
  end

  def add_sparks(x, y, col, cnt)
    i = 0
    while i < cnt
      ang = -Math::PI + rand() * Math::PI
      spd = 1.4 + rand() * 2.8
      @sparks << { x: x, y: y, vx: cos(ang) * spd, vy: sin(ang) * spd - 1.0, col: col, life: 20 }
      i += 1
    end
  end

  def next_ring
    @strike += 1
    if @strike >= @strikes_per_blade
      @pause_t = 65
      rank = @quality >= 520 ? "S" : (@quality >= 400 ? "A" : (@quality >= 280 ? "B" : "C"))
      @popups << { x: 128, y: 88, text: "RANK #{rank}! (#{@quality})", col: 10, life: 60 }
    else
      @ring_r = 74.0
    end
  end

  def update
    @t += 1
    @shake_t -= 1 if @shake_t > 0
    @flash_t -= 1 if @flash_t > 0
    @hammer_t -= 1 if @hammer_t > 0

    @sparks.each do |s|
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:vy] += 0.14
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }
    @popups.each do |pp|
      pp[:y] -= 0.5
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }

    if @finished
      @fin_timer += 1
      if @fin_timer > 30 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    if @pause_t > 0
      @pause_t -= 1
      if @pause_t == 0
        @blade_idx += 1
        if @blade_idx >= BLADES.size
          @finished = true
          @fin_timer = 0
        else
          @strike = 0
          @quality = 0
          @ring_r = 74.0
        end
      end
      return
    end

    b = BLADES[@blade_idx]
    @ring_r -= b[:spd]

    if btnp(4) || btnp(5) || btnp(:mouse_l)
      @hammer_t = 10
      diff = (@ring_r - TARGET_R).abs
      if diff <= 5.5
        @combo += 1
        pts = 100 + @combo * 20
        @score += pts
        @quality += 100
        $smith_best = @score if @score > $smith_best
        @shake_t = 8
        @flash_t = 3
        add_sparks(ANVIL_X, ANVIL_Y, 10, 18)
        @popups << { x: 128, y: 112, text: "PERFECT! +#{pts}", col: 10, life: 28 }
      elsif diff <= 13.0
        @combo += 1
        pts = 50 + @combo * 10
        @score += pts
        @quality += 60
        $smith_best = @score if @score > $smith_best
        @shake_t = 4
        add_sparks(ANVIL_X, ANVIL_Y, 9, 10)
        @popups << { x: 128, y: 112, text: "GOOD +#{pts}", col: 12, life: 24 }
      else
        @combo = 0
        add_sparks(ANVIL_X, ANVIL_Y, 5, 6)
        @popups << { x: 128, y: 112, text: "MISS!", col: 8, life: 24 }
      end
      next_ring
    elsif @ring_r < 6.0
      @combo = 0
      @popups << { x: 128, y: 112, text: "TOO LATE!", col: 8, life: 24 }
      next_ring
    end
  end

  def draw
    cls(0)
    shk_x = @shake_t > 0 ? rand(-2..2) : 0
    shk_y = @shake_t > 0 ? rand(-2..2) : 0
    bg(:cave, dim: 0.45, tint: [255, 125, 90], scale: 1.04, scroll_x: shk_x * 0.3, y: shk_y * 0.3)

    camera(shk_x, shk_y)

    # 鍛冶炉 & 金床
    rectfill(96, 174, 64, 18, 5)
    rect(96, 174, 64, 18, 6)
    # 赤熱の剣
    b = BLADES[@blade_idx < BLADES.size ? @blade_idx : BLADES.size - 1]
    rectfill(104, 166, 48, 6, @hammer_t > 0 ? 7 : 9)
    rect(104, 166, 48, 6, 8)

    spr(:smith, 76, 154)

    # タイミングリング
    if @pause_t <= 0 && !@finished
      circ(ANVIL_X.to_i, ANVIL_Y.to_i, TARGET_R.to_i, 7)
      circ(ANVIL_X.to_i, ANVIL_Y.to_i, TARGET_R.to_i - 1, 10)
      diff = (@ring_r - TARGET_R).abs
      rcol = diff <= 5.5 ? 11 : (diff <= 13.0 ? 10 : 9)
      circ(ANVIL_X.to_i, ANVIL_Y.to_i, @ring_r.to_i, rcol)
    end

    @sparks.each { |s| rectfill(s[:x].to_i, s[:y].to_i, 2, 2, s[:col]) }
    @popups.each { |pp| print_text(pp[:text], pp[:x] - pp[:text].length * 3, pp[:y].to_i, pp[:col]) }

    camera()
    clip()

    if @flash_t > 0
      rect(0, 0, 256, 256, 10)
      rect(1, 1, 254, 254, 10)
    end

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text(b[:name], 6, 6, b[:col])
    print_text("SCR:#{@score}", 118, 6, 7)
    print_text("x#{@combo}", 206, 6, 10)

    # 打撃進捗ドット
    i = 0
    while i < @strikes_per_blade
      col = i < @strike ? 10 : 5
      circfill(98 + i * 12, 214, 4, col)
      i += 1
    end

    if @finished
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 10)
      print_text("MASTERWORK COMPLETE!", 68, 96, 10)
      print_text("SCORE : #{@score}", 74, 114, 7)
      print_text("BEST  : #{$smith_best}", 74, 128, 12)
      if (@fin_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO REFORGE", 47, 148, 10)
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
F: #FFCCAA

@SPRITE :smith 16x16 pal:1
................
.....000000.....
....07777770....
...0770770770...
....00FFFF00....
...0448888440...
..060444444040..
..060444444000..
...004444440....
....04400440....
....000..000....
................
................
................
................
................
