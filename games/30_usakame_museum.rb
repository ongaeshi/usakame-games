# ==============================================================================
# 30. USAKAME MUSEUM
# ------------------------------------------------------------------------------
# 30本完結記念・過去作スプライトが並ぶ歩けるインタラクティブ展示室
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ← / → / ↑ / ↓ (WASD) : 展示室内を歩く
#   Z / Space / クリック   : 展示パネルの詳細を見る / 祝砲クラッカー
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "30. USAKAME MUSEUM"
)

EXHIBITS = [
  { x: 52.0,  y: 78.0,  sp: :ex_climber, title: "CAT A: ACTION (01-05)", desc: "GRAPPLE, PARRY & DRIFT!", col: 9 },
  { x: 128.0, y: 78.0,  sp: :ex_ship,    title: "CAT B: STG & PHYS (06-10)", desc: "STAR DIVER & PINBALL!", col: 12 },
  { x: 204.0, y: 78.0,  sp: :ex_knight,  title: "CAT C: TACTICS (11-15)", desc: "AUTO CHESS & ALCHEMY!", col: 10 },
  { x: 52.0,  y: 158.0, sp: :ex_sushi,   title: "CAT D: SPORTS (16-20)", desc: "HOCKEY, GOLF & SUSHI!", col: 14 },
  { x: 128.0, y: 158.0, sp: :ex_monster, title: "CAT E: SIM & RPG (21-25)", desc: "AQUARIUM, SAND & BREEDER!", col: 11 },
  { x: 204.0, y: 158.0, sp: :ex_art,     title: "CAT F: ART & TOY (26-30)", desc: "FIREWORKS, BLOOM & VJ!", col: 7 }
]

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
    if btnp(4) || btnp(:mouse_l)
      run GameScene.new
    end
  end

  def draw
    cls(0)
    bg(:training, dim: 0.55, tint: [215, 185, 140])

    spr(:visitor, 120, 168)

    rectfill(20, 24, 216, 42, 0)
    rect(20, 24, 216, 42, 10)
    print_text("USAKAME MUSEUM", 86, 32, 10)
    print_text("30 GAMES GRAND EXHIBITION!", 50, 48, 7)

    rectfill(24, 80, 208, 56, 0)
    rect(24, 80, 208, 56, 5)
    print_text("ARROWS / WASD : WALK GALLERY", 40, 90, 7)
    print_text("APPROACH      : READ PLAQUE", 40, 103, 12)
    print_text("Z / CLICK     : PARTY CONFETTI!", 40, 116, 10)

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO ENTER", 53, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @px = 128.0
    @py = 204.0
    @facing_left = false
    @visited = [false, false, false, false, false, false]
    @confetti = []
    @celebrated = false
  end

  def spawn_confetti(x, y)
    i = 0
    while i < 18
      ang = rand() * Math::PI * 2.0
      spd = 1.2 + rand() * 2.4
      @confetti << {
        x: x, y: y, vx: cos(ang) * spd, vy: sin(ang) * spd - 1.0,
        col: [8, 9, 10, 11, 12, 14][rand(6)], life: 36
      }
      i += 1
    end
  end

  def update
    @t += 1
    spd = 2.0
    if btn(0)
      @px -= spd; @facing_left = true
    end
    if btn(1)
      @px += spd; @facing_left = false
    end
    @py -= spd if btn(2)
    @py += spd if btn(3)

    @px = clamp_v(@px, 16.0, 240.0)
    @py = clamp_v(@py, 36.0, 216.0)

    if btnp(4) || btnp(:mouse_l)
      spawn_confetti(@px, @py - 8.0)
    end

    EXHIBITS.each_with_index do |ex, idx|
      dx = @px - ex[:x]
      dy = @py - ex[:y]
      if dx * dx + dy * dy < 24.0 * 24.0 && !@visited[idx]
        @visited[idx] = true
        spawn_confetti(ex[:x], ex[:y] - 8.0)
      end
    end

    if !@celebrated && @visited.all? { |v| v }
      @celebrated = true
      spawn_confetti(128.0, 120.0)
    end

    @confetti.each do |c|
      c[:x] += c[:vx]
      c[:y] += c[:vy]
      c[:vy] += 0.08
      c[:life] -= 1
    end
    @confetti.reject! { |c| c[:life] <= 0 }
  end

  def draw
    cls(0)
    bg(:training, dim: 0.58, tint: [200, 175, 135])

    # レッドカーペット
    rectfill(112, 32, 32, 186, 2)
    line(112, 32, 112, 218, 10)
    line(144, 32, 144, 218, 10)
    rectfill(36, 112, 184, 18, 2)
    line(36, 112, 220, 112, 10)
    line(36, 130, 220, 130, 10)

    # 展示台座 & スプライト
    active_ex = nil
    EXHIBITS.each_with_index do |ex, idx|
      ex_x = ex[:x].to_i
      ex_y = ex[:y].to_i
      rectfill(ex_x - 14, ex_y - 14, 28, 28, 0)
      rect(ex_x - 14, ex_y - 14, 28, 28, @visited[idx] ? 10 : ex[:col])
      bob = (sin(@t * 0.08 + idx) * 2.0).to_i
      spr(ex[:sp], ex_x - 8, ex_y - 8 + bob)

      dx = @px - ex[:x]
      dy = @py - ex[:y]
      active_ex = ex if dx * dx + dy * dy < 26.0 * 26.0
    end

    # 来館者うさ
    spr(:visitor, @px.to_i - 8, @py.to_i - 8, @facing_left)

    @confetti.each { |c| rectfill(c[:x].to_i, c[:y].to_i, 2, 2, c[:col]) }

    # HUD
    v_cnt = @visited.count { |v| v }
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 10)
    print_text("USAKAME 30 MUSEUM", 6, 6, 10)
    print_text("VISITED:#{v_cnt}/6", 174, 6, v_cnt == 6 ? 11 : 12)

    # 下部展示解説パネル
    rectfill(0, 220, 256, 36, 0)
    line(0, 220, 256, 220, 10)
    if active_ex
      print_text(active_ex[:title], 10, 226, active_ex[:col])
      print_text(active_ex[:desc], 10, 239, 7)
    elsif @celebrated
      print_text("30 GAMES COMPLETE! THANK YOU!", 32, 232, 10)
    else
      print_text("WALK TO AN EXHIBIT TO INSPECT!", 34, 232, 6)
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #0A0814
1: #1D2B53
2: #7E2553
4: #8A4836
5: #5F574F
6: #C2C3C7
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
B: #00E436
C: #29ADFF
E: #FF77A8
F: #FFCCAA

@SPRITE :visitor 16x16 pal:1
................
.....000000.....
....07777770....
...0770770770...
...0777777770...
....00FFFF00....
...0CCCCCCCC0...
..0CC0CCCC0CC0..
....0CCCCCC0....
....01100110....
....000..000....
................
................
................
................
................

@SPRITE :ex_climber 16x16 pal:1
................
.....000000.....
....07777770....
...0770770770...
....00FFFF00....
...0888888880...
....011AA110....
....01100110....
....000..000....
................
................
................
................
................
................
................

@SPRITE :ex_ship 16x16 pal:1
.......00.......
......0770......
.....0CCCC0.....
....0CC77CC0....
...0CCC77CCC0...
..011CCCCCC110..
.0110.0990.0110.
..00...00...00..
................
................
................
................
................
................
................
................

@SPRITE :ex_knight 16x16 pal:1
................
.....000000.....
....06666660....
...0677777760...
...0600660060...
...0CCCCCCCC0...
..060CCAA0C060..
....01100110....
....000..000....
................
................
................
................
................
................
................

@SPRITE :ex_sushi 16x16 pal:1
................
................
....00000000....
...0888788880...
..088888788880..
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
................

@SPRITE :ex_monster 16x16 pal:1
...000....000...
..099900009990..
..098888888890..
.09880788708890.
.09888888888890.
..008707070780..
...099AAAA990...
....009900990...
................
................
................
................
................
................
................
................

@SPRITE :ex_art 16x16 pal:1
.......00.......
......0AA0......
.....0A7AA0.....
.0000AA7AAA0000.
0AAAAAAAAAAAAAA0
.0AAA0A7AA0AAA0.
..0AAAAAAAAAAAA.
...0AAAAAAAAA0..
..0AAAA00AAAA0..
..000......000..
................
................
................
................
................
................
