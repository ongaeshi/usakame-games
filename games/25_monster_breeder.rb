# ==============================================================================
# 25. MONSTER BREEDER
# ------------------------------------------------------------------------------
# 特訓・進化分岐(8種)でドット絵相棒を育て大会制覇を目指す育成ゲー
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   クリック / ← → + Z : 特訓メニュー選択 (ATK / DEF / SPD / REST / BATTLE)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "25. MONSTER BREEDER"
)

MON_FORMS = {
  baby:    { name: "SLIME CUB",    sp: :mon_baby,  col: 11 },
  atk2:    { name: "FLAME CUB",    sp: :mon_atk,   col: 8 },
  def2:    { name: "SHELL PUP",    sp: :mon_def,   col: 12 },
  spd2:    { name: "WIND FOX",     sp: :mon_spd,   col: 10 },
  atk3:    { name: "REX BLAZE",    sp: :mon_rex,   col: 9 },
  def3:    { name: "IRON TITAN",   sp: :mon_titan, col: 6 },
  spd3:    { name: "STAR GRIFFIN", sp: :mon_grif,  col: 14 },
  king:    { name: "COSMIC KING",  sp: :mon_king,  col: 10 }
}

CUPS = [
  { name: "BRONZE CUP",   hp: 28, atk: 6,  col: 9 },
  { name: "SILVER CUP",   hp: 45, atk: 9,  col: 6 },
  { name: "GOLD CUP",     hp: 68, atk: 13, col: 10 },
  { name: "CHAMPION CUP", hp: 96, atk: 17, col: 14 }
]

$breeder_cups ||= 0

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
    bg(:forest, dim: 0.42, tint: [190, 235, 190])

    spr(:mon_baby, 68, 166)
    spr(:mon_atk, 108, 166)
    spr(:mon_rex, 148, 166)
    spr(:mon_king, 184, 166)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 11)
    print_text("MONSTER BREEDER", 83, 32, 10)
    print_text("TRAIN, EVOLVE & WIN THE CUP!", 44, 46, 11)

    rectfill(24, 78, 208, 58, 0)
    rect(24, 78, 208, 58, 5)
    print_text("CLICK / ARROWS+Z : TRAIN STATS", 34, 88, 7)
    print_text("8 EVOLUTION FORMS BY STAT BUILD", 34, 102, 10)
    if $breeder_cups > 0
      print_text("CUPS WON: #{$breeder_cups}", 86, 118, 14)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO RAISE", 53, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @form = :baby
    @hp = 30
    @max_hp = 30
    @atk = 6
    @def_v = 4
    @spd = 5
    @exp = 0
    @cup_idx = 0
    @sel = 0

    @mode = :train
    @e_hp = 30
    @e_max_hp = 30
    @e_atk = 6
    @bat_cd = 0
    @popups = []
    @sparks = []
    @won_all = false
  end

  def check_evolution
    if @form == :baby && @exp >= 35
      if @atk >= @def_v && @atk >= @spd
        @form = :atk2
      elsif @def_v >= @atk && @def_v >= @spd
        @form = :def2
      else
        @form = :spd2
      end
      @max_hp += 12; @hp = @max_hp
      @popups << { x: 128, y: 74, text: "EVOLVED: #{MON_FORMS[@form][:name]}!", col: 10, life: 50 }
    elsif (@form == :atk2 || @form == :def2 || @form == :spd2) && @exp >= 85
      if (@atk - @def_v).abs <= 3 && (@atk - @spd).abs <= 3
        @form = :king
      elsif @atk >= @def_v && @atk >= @spd
        @form = :atk3
      elsif @def_v >= @atk && @def_v >= @spd
        @form = :def3
      else
        @form = :spd3
      end
      @max_hp += 20; @hp = @max_hp
      @popups << { x: 128, y: 74, text: "FINAL: #{MON_FORMS[@form][:name]}!", col: 14, life: 55 }
    end
  end

  def do_action(idx)
    if idx == 0
      @atk += 2 + rand(2)
      @exp += 12
      @popups << { x: 128, y: 90, text: "ATK UP!", col: 8, life: 26 }
    elsif idx == 1
      @def_v += 2 + rand(2)
      @max_hp += 4
      @hp += 4
      @exp += 12
      @popups << { x: 128, y: 90, text: "DEF & HP UP!", col: 12, life: 26 }
    elsif idx == 2
      @spd += 2 + rand(2)
      @exp += 12
      @popups << { x: 128, y: 90, text: "SPD UP!", col: 10, life: 26 }
    elsif idx == 3
      @hp = @max_hp
      @popups << { x: 128, y: 90, text: "FULL REST!", col: 11, life: 26 }
    else
      start_battle
      return
    end
    check_evolution
  end

  def start_battle
    @mode = :battle
    cup = CUPS[@cup_idx]
    @e_hp = cup[:hp]
    @e_max_hp = cup[:hp]
    @e_atk = cup[:atk]
    @bat_cd = 24
  end

  def update
    @t += 1
    @popups.each do |pp|
      pp[:y] -= 0.4
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }
    @sparks.each do |s|
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }

    if @mode == :train
      @sel = (@sel - 1) % 5 if btnp(:left)
      @sel = (@sel + 1) % 5 if btnp(:right)
      do_action(@sel) if btnp(1) || btnp(2)

      if btnp(:mouse_l)
        mx = mouse_x; my = mouse_y
        if my >= 210 && my <= 246
          i = 0
          while i < 5
            bx = 4 + i * 50
            if mx >= bx && mx <= bx + 48
              @sel = i
              do_action(i)
            end
            i += 1
          end
        end
      end
    elsif @mode == :battle
      @bat_cd -= 1
      if @bat_cd <= 0
        @bat_cd = 26
        # 自モン攻撃
        dmg = @atk + (@spd / 4).to_i + rand(0..2)
        @e_hp -= dmg
        @popups << { x: 184, y: 106, text: "-#{dmg}", col: 10, life: 22 }
        if @e_hp <= 0
          @mode = :train
          @hp = @max_hp
          @exp += 20
          $breeder_cups += 1
          @popups << { x: 128, y: 74, text: "#{CUPS[@cup_idx][:name]} WON!", col: 10, life: 50 }
          @cup_idx += 1 if @cup_idx < CUPS.size - 1
          check_evolution
          return
        end

        # 敵反撃
        edmg = @e_atk - (@def_v / 3).to_i
        edmg = 1 if edmg < 1
        @hp -= edmg
        @popups << { x: 72, y: 106, text: "-#{edmg}", col: 8, life: 22 }
        if @hp <= 0
          @hp = @max_hp
          @mode = :train
          @popups << { x: 128, y: 74, text: "DEFEATED... TRAIN MORE!", col: 8, life: 45 }
        end
      end
    end
  end

  def draw
    cls(0)
    bg(@mode == :battle ? :city : :forest, dim: 0.45, tint: [190, 230, 190])

    # 草原 / アリーナ床
    rectfill(0, 152, 256, 54, 3)
    line(0, 152, 256, 152, 11)

    mf = MON_FORMS[@form]
    if @mode == :train
      bob = (sin(@t * 0.1) * 3.0).to_i
      spr_ext(mf[:sp], 128, 134 + bob, 0.0, 2.0, 2.0, false, false)
      # ステータスボックス
      rectfill(12, 28, 118, 56, 0)
      rect(12, 28, 118, 56, mf[:col])
      print_text(mf[:name], 18, 34, mf[:col])
      print_text("HP:#{@hp}/#{@max_hp}", 18, 46, 11)
      print_text("ATK:#{@atk} DEF:#{@def_v}", 18, 58, 7)
      print_text("SPD:#{@spd} EXP:#{@exp}", 18, 70, 10)
    else
      cup = CUPS[@cup_idx]
      spr_ext(mf[:sp], 72, 134, 0.0, 1.5, 1.5, false, false)
      spr_ext(:mon_titan, 184, 134, 0.0, 1.5, 1.5, true, false)

      print_text(mf[:name], 36, 86, mf[:col])
      bw1 = (@hp * 48 / @max_hp).to_i
      rectfill(48, 98, 48, 4, 0)
      rectfill(48, 98, bw1, 4, 11)

      print_text(cup[:name], 144, 86, cup[:col])
      bw2 = (@e_hp * 48 / @e_max_hp).to_i
      rectfill(160, 98, 48, 4, 0)
      rectfill(160, 98, bw2, 4, 8)
    end

    @sparks.each { |s| rectfill(s[:x].to_i, s[:y].to_i, 2, 2, s[:col]) }
    @popups.each { |pp| print_text(pp[:text], pp[:x] - pp[:text].length * 3, pp[:y].to_i, pp[:col]) }

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("NEXT: #{CUPS[@cup_idx][:name]}", 8, 6, CUPS[@cup_idx][:col])
    print_text("CUPS:#{$breeder_cups}", 192, 6, 10)

    # 下部コマンドバー
    rectfill(0, 206, 256, 50, 0)
    line(0, 206, 256, 206, 5)
    cmds = [
      { lbl: "ATK+", col: 8 },
      { lbl: "DEF+", col: 12 },
      { lbl: "SPD+", col: 10 },
      { lbl: "REST", col: 11 },
      { lbl: "CUP!", col: 14 }
    ]
    i = 0
    while i < 5
      c = cmds[i]
      bx = 4 + i * 50
      sel = (@sel == i)
      rectfill(bx, 214, 48, 32, sel ? 1 : 0)
      rect(bx, 214, 48, 32, sel ? 7 : c[:col])
      print_text(c[:lbl], bx + 10, 226, c[:col])
      i += 1
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #090A14
3: #008751
5: #5F574F
6: #C2C3C7
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
B: #00E436
C: #29ADFF
E: #FF77A8

@SPRITE :mon_baby 16x16 pal:1
................
.....000000.....
...00BBBBBB00...
..0BB77BBBBBB0..
..0B7B0BBB0BB0..
.0BBBB0BBB0BBB0.
.0BBBBBBBBBBBB0.
..0BB333333BB0..
...0033333300...
.....000000.....
................
................
................
................
................
................

@SPRITE :mon_atk 16x16 pal:1
....00....00....
...0990..0990...
...0880000880...
..088888888880..
..088078870880..
..088888888880..
...088AAAA880...
..088088880880..
...00.0880.00...
......0000......
................
................
................
................
................
................

@SPRITE :mon_def 16x16 pal:1
................
....00000000....
..00CCCCCCCC00..
.0CC66CCCC66CC0.
.0CC07CCCC70CC0.
.0CCCCCCCCCCCC0.
.0C66CCCCCC66C0.
..00CCCCCCCC00..
...0110000110...
...000....000...
................
................
................
................
................
................

@SPRITE :mon_spd 16x16 pal:1
..00........00..
.0AA0......0AA0.
.0A7A000000A7A0.
..0AAAAAAAAAA0..
..0AA07AA70AA0..
...0AAAAAAAA0...
..0770AAAA0770..
....0AA00AA0....
....000..000....
................
................
................
................
................
................
................

@SPRITE :mon_rex 16x16 pal:1
...000....000...
..099900009990..
..098888888890..
.09880788708890.
.09888888888890.
..008707070780..
...099AAAA990...
..090999999090..
...0099009900...
....000..000....
................
................
................
................
................
................

@SPRITE :mon_titan 16x16 pal:1
..000000000000..
.06666666666660.
.06556666665560.
.06588566588560.
.06555555555560.
.0666CCCCCCC660.
066066CCCC660660
0660.066660.0660
.00..0550550.00.
.....000.000....
................
................
................
................
................
................

@SPRITE :mon_grif 16x16 pal:1
.00..........00.
0770..0000..0770
07E700EEEE00E770
.0770E0770E0770.
..000EEEEEE000..
....0EEAAEE0....
...0EE0EE0EE0...
....0E0..0E0....
................
................
................
................
................
................
................
................

@SPRITE :mon_king 16x16 pal:1
.....00..00.....
....0AA00AA0....
...0AAAAAAAA0...
..00CCCCCCCC00..
.0CC70CCCC07CC0.
.0CCCCCCCCCCCC0.
..0CCAAAAAAACC0.
.0C0CCCCCCCC0C0.
..00CC0000CC00..
....00....00....
................
................
................
................
................
................
