# ==============================================================================
# 15. DICE DUNGEON
# ------------------------------------------------------------------------------
# 出目を装備スロットにはめて戦うダイス構築ローグライト
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   マウスクリック / ←→+Z : ダイス選択 → 装備スロットへセット
#   X / Enter / END TURN  : ターン終了 (敵の予兆行動を実行)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "15. DICE DUNGEON"
)

ENEMY_LIST = [
  { name: "GOBLIN",   hp: 16, atk: 5,  sp: :goblin },
  { name: "GARGOYLE", hp: 24, atk: 7,  sp: :gargoyle },
  { name: "LICH",     hp: 30, atk: 9,  sp: :lich }
]

$dice_best_floor ||= 0

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
    bg(:cave, dim: 0.48, tint: [185, 145, 210])

    spr(:hero, 72, 166)
    spr(:goblin, 168, 166)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 10)
    print_text("DICE DUNGEON", 92, 32, 10)
    print_text("SOCKET DICE INTO GEAR SLOTS!", 41, 46, 12)

    rectfill(24, 78, 208, 62, 0)
    rect(24, 78, 208, 62, 5)
    print_text("CLICK DIE -> CLICK GEAR SLOT", 40, 88, 7)
    print_text("SWORD: DMG | SHIELD: BLOCK", 40, 101, 12)
    print_text("STAFF (ODD): 2x MAGIC DMG!", 40, 114, 14)
    if $dice_best_floor > 0
      print_text("BEST FLOOR: #{$dice_best_floor}", 82, 127, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO DELVE", 53, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @floor = 1
    @hp = 30
    @max_hp = 30
    @armor = 0
    @bonus_dmg = 0

    @dice = []
    @sel_die = 0
    @slots_used = [false, false, false]
    @popups = []
    @shake_t = 0
    @dead = false
    @dead_timer = 0

    spawn_enemy
    roll_dice
  end

  def spawn_enemy
    ed = ENEMY_LIST[(@floor - 1) % ENEMY_LIST.size]
    hp = ed[:hp] + (@floor - 1) * 5
    @enemy = {
      name: ed[:name], sp: ed[:sp],
      hp: hp, max_hp: hp,
      intent_atk: ed[:atk] + (@floor / 2).to_i,
      intent_type: :atk
    }
  end

  def roll_dice
    @dice = [rand(1..6), rand(1..6), rand(1..6)]
    @slots_used = [false, false, false]
    @sel_die = 0
  end

  def apply_die_to_slot(die_idx, slot_idx)
    return if die_idx.nil? || die_idx >= @dice.size || @dice[die_idx].nil?
    return if @slots_used[slot_idx]

    val = @dice[die_idx]
    if slot_idx == 2 && val % 2 == 0
      @popups << { x: 184, y: 170, text: "ODD ONLY!", col: 8, life: 24 }
      return
    end

    @dice[die_idx] = nil
    @slots_used[slot_idx] = true

    if slot_idx == 0
      # SWORD
      dmg = val + @bonus_dmg + (val == 6 ? 3 : 0)
      @enemy[:hp] -= dmg
      @shake_t = 6
      @popups << { x: 184, y: 74, text: val == 6 ? "CRIT -#{dmg}!" : "-#{dmg}", col: 10, life: 28 }
    elsif slot_idx == 1
      # SHIELD
      @armor += val + 1
      @popups << { x: 64, y: 74, text: "+#{val + 1} DEF", col: 12, life: 28 }
    else
      # STAFF (ODD)
      dmg = val * 2 + @bonus_dmg
      @enemy[:hp] -= dmg
      @shake_t = 6
      @popups << { x: 184, y: 74, text: "ZAP -#{dmg}!", col: 14, life: 28 }
    end

    # 次の未使用ダイスを選択
    @sel_die = nil
    @dice.each_with_index do |d, i|
      if d && @sel_die.nil?
        @sel_die = i
      end
    end

    if @enemy[:hp] <= 0
      @floor += 1
      $dice_best_floor = @floor if @floor > $dice_best_floor
      @hp += 5
      @hp = @max_hp if @hp > @max_hp
      @bonus_dmg += 1 if @floor % 2 == 0
      @armor = 0
      @popups << { x: 128, y: 60, text: "VICTORY! +5 HP", col: 11, life: 36 }
      spawn_enemy
      roll_dice
    end
  end

  def end_turn
    dmg = @enemy[:intent_atk] - @armor
    dmg = 0 if dmg < 0
    @armor = 0
    if dmg > 0
      @hp -= dmg
      @shake_t = 10
      @popups << { x: 64, y: 74, text: "-#{dmg} HP!", col: 8, life: 30 }
    else
      @popups << { x: 64, y: 74, text: "BLOCKED!", col: 12, life: 26 }
    end

    if @hp <= 0
      @hp = 0
      @dead = true
      @dead_timer = 0
    else
      @enemy[:intent_atk] = ENEMY_LIST[(@floor - 1) % ENEMY_LIST.size][:atk] + (@floor / 2).to_i + rand(0..2)
      roll_dice
    end
  end

  def update
    @t += 1
    @shake_t -= 1 if @shake_t > 0
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

    if btnp(5)
      end_turn
      return
    end

    # キー操作: ←/→でダイス切替、Zで空きスロットへ自動セット
    if btnp(0)
      @sel_die = ((@sel_die || 0) - 1) % 3
    elsif btnp(1)
      @sel_die = ((@sel_die || 0) + 1) % 3
    elsif btnp(4)
      if @sel_die && @dice[@sel_die]
        # 奇数ならSTAFF優先、それ以外はSWORD/SHIELD
        if @dice[@sel_die] % 2 != 0 && !@slots_used[2]
          apply_die_to_slot(@sel_die, 2)
        elsif !@slots_used[0]
          apply_die_to_slot(@sel_die, 0)
        elsif !@slots_used[1]
          apply_die_to_slot(@sel_die, 1)
        end
      else
        end_turn
      end
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      # ダイスクリック
      if my >= 134 && my <= 162
        i = 0
        while i < 3
          dx = 68 + i * 44
          if mx >= dx && mx <= dx + 28 && @dice[i]
            @sel_die = i
          end
          i += 1
        end
      end

      # スロットクリック
      if my >= 174 && my <= 214
        i = 0
        while i < 3
          sx = 14 + i * 78
          if mx >= sx && mx <= sx + 72
            apply_die_to_slot(@sel_die, i)
          end
          i += 1
        end
      end

      # END TURN ボタン
      if mx >= 80 && mx <= 176 && my >= 224 && my <= 246
        end_turn
      end
    end
  end

  def draw
    cls(0)
    shk_x = @shake_t > 0 ? rand(-2..2) : 0
    shk_y = @shake_t > 0 ? rand(-2..2) : 0
    bg(:cave, dim: 0.5, tint: [175, 135, 200], scale: 1.04, scroll_x: shk_x * 0.3, y: shk_y * 0.3)

    camera(shk_x, shk_y)

    # アリーナステージ
    rectfill(0, 114, 256, 12, 1)
    line(0, 114, 256, 114, 5)

    # 勇者
    spr(:hero, 56, 94)
    print_text("HP:#{@hp}/#{@max_hp}", 36, 70, 11)
    print_text("DEF:#{@armor}", 46, 80, 12) if @armor > 0

    # 敵 & 予兆
    spr(@enemy[:sp], 176, 94)
    print_text(@enemy[:name], 162, 54, 8)
    print_text("INTENT: ATK #{@enemy[:intent_atk]}", 138, 64, 9)
    bw = (@enemy[:hp] * 44 / @enemy[:max_hp]).to_i
    bw = 1 if bw < 1 && @enemy[:hp] > 0
    rectfill(162, 76, 44, 5, 0)
    rectfill(162, 76, bw, 5, 8)
    print_text("#{@enemy[:hp]}/#{@enemy[:max_hp]}", 170, 84, 7)

    # ダイストレイ
    i = 0
    while i < 3
      dx = 68 + i * 44
      dy = 136
      if @dice[i]
        sel = (@sel_die == i)
        rectfill(dx, dy, 26, 26, 7)
        rect(dx, dy, 26, 26, sel ? 10 : 0)
        rect(dx - 1, dy - 1, 28, 28, 10) if sel
        print_text("#{@dice[i]}", dx + 10, dy + 9, 0)
      else
        rect(dx, dy, 26, 26, 5)
      end
      i += 1
    end

    # 装備スロット
    slots = [
      { name: "SWORD",  sub: "DMG+VAL", col: 8 },
      { name: "SHIELD", sub: "DEF+VAL", col: 12 },
      { name: "STAFF",  sub: "ODD 2x",  col: 14 }
    ]
    i = 0
    while i < 3
      sl = slots[i]
      sx = 14 + i * 78
      used = @slots_used[i]
      rectfill(sx, 174, 72, 40, used ? 0 : 1)
      rect(sx, 174, 72, 40, used ? 5 : sl[:col])
      print_text(sl[:name], sx + 8, 182, used ? 5 : sl[:col])
      print_text(used ? "USED" : sl[:sub], sx + 8, 196, used ? 5 : 7)
      i += 1
    end

    # END TURN ボタン
    rectfill(80, 224, 96, 20, 2)
    rect(80, 224, 96, 20, 10)
    print_text("END TURN [X]", 92, 230, 10)

    @popups.each { |pp| print_text(pp[:text], pp[:x] - pp[:text].length * 3, pp[:y].to_i, pp[:col]) }

    camera()
    clip()

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("FLOOR:#{@floor}", 8, 6, 10)
    print_text("ATK+#{@bonus_dmg}", 92, 6, 9)
    print_text("BEST:F#{$dice_best_floor}", 184, 6, 12)

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("FALLEN IN DUNGEON!", 74, 96, 8)
      print_text("FLOOR : #{@floor}", 78, 114, 10)
      print_text("BEST  : #{$dice_best_floor}", 78, 128, 12)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 148, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #0A0814
1: #1D2B53
2: #7E2553
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

@SPRITE :hero 16x16 pal:1
................
.....000000.....
....07777770....
...0770770770...
...0777777770...
....00FFFF00....
...0888888880...
..060CCCCCC060..
..060CCAA0C060..
...00CCCCCC00...
....01100110....
....01100110....
....000..000....
................
................
................

@SPRITE :goblin 16x16 pal:1
................
..00........00..
..0B00000000B0..
...0BBBBBBBB0...
..0BB88BB88BB0..
..0BBBBBBBBBB0..
...00B7777B00...
....04444440....
...0440440440...
....04400440....
....000..000....
................
................
................
................
................

@SPRITE :gargoyle 16x16 pal:1
................
.00..........00.
0550..0000..0550
0565005555005650
.05505588550550.
..000555555000..
....05566550....
...0555555550...
....05500550....
....000..000....
................
................
................
................
................
................

@SPRITE :lich 16x16 pal:1
......0000......
.....0AAAA0.....
....02222220....
...0770770770...
...0778778770...
....07777770....
...0222EE2220...
..0220EEEE0220..
...0022AA2200...
....02200220....
....000..000....
................
................
................
................
................
