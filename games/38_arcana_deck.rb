# ==============================================================================
# 38. ARCANA DECK
# ------------------------------------------------------------------------------
# 日本語UI×カード発光演出で戦うデッキ構築ローグライトRPG
# 640x480 / 1ファイル完結 / 基本API + bg() + スプライト + マウス/キーボード
#
# 【操作方法】
#   ← / → / マウス移動 : カード・報酬選択
#   Z / Space / クリック : カード使用・決定
#   X / Enter            : ターン終了
# ==============================================================================

config(
  width: 640,
  height: 480,
  scale: 2,
  sprite_scale: 2.0,
  text_size: 16,
  title: "38. ARCANA DECK"
)

SW = 640
SH = 480

CARDS = {
  strike:  { name: "ざんげき",     cost: 1, col: 8,  desc: "敵に 6 ダメージ",       dmg: 6,  blk: 0, draw: 0, heal: 0 },
  defend:  { name: "ガード",       cost: 1, col: 12, desc: "ブロック +5",           dmg: 0,  blk: 5, draw: 0, heal: 0 },
  bolt:    { name: "まほうのや",   cost: 1, col: 14, desc: "敵に 8 ダメージ",       dmg: 8,  blk: 0, draw: 0, heal: 0 },
  twin:    { name: "にれんぎり",   cost: 1, col: 9,  desc: "敵に 4x2 ダメージ",     dmg: 8,  blk: 0, draw: 0, heal: 0 },
  iron:    { name: "てっぺき",     cost: 2, col: 12, desc: "ブロック +12",          dmg: 0,  blk: 12, draw: 0, heal: 0 },
  focus:   { name: "まりょくしゅうちゅう", cost: 0, col: 11, desc: "カード2枚ドロー", dmg: 0,  blk: 0, draw: 2, heal: 0 },
  drain:   { name: "きゅうけつのやいば",   cost: 1, col: 2,  desc: "5ダメージ & HP+3", dmg: 5,  blk: 0, draw: 0, heal: 3 },
  meteor:  { name: "アルカナメテオ", cost: 2, col: 10, desc: "敵に 16 ダメージ!",     dmg: 16, blk: 0, draw: 0, heal: 0 }
}

REWARD_POOL = [:bolt, :twin, :iron, :focus, :drain, :meteor]

def shuffle_arr(arr)
  res = arr.dup
  i = res.size - 1
  while i > 0
    j = rand(i + 1)
    tmp = res[i]
    res[i] = res[j]
    res[j] = tmp
    i -= 1
  end
  res
end

class ArcanaDeckGame
  def initialize
    @state = :title
    @frame = 0
    reset_run
  end

  def reset_run
    @hp = 45
    @max_hp = 45
    @block = 0
    @mana = 3
    @max_mana = 3
    @floor = 1
    @max_floor = 8
    @deck = [:strike, :strike, :strike, :strike, :strike, :defend, :defend, :defend, :defend, :bolt]
    @hand = []
    @draw_pile = []
    @discard_pile = []
    @sel_idx = 0
    @fx_list = []
    @sparks = []
    @shake = 0.0
    @log = "アルカナの迷宮へようこそ！"
    @rewards = []
    start_battle
  end

  def start_battle
    if @floor == @max_floor
      @enemy = { name: "しんえんのりゅう", sp: :dragon, hp: 65, max_hp: 65, atk: 12, blk: 0, intent: :attack }
    elsif @floor % 2 == 0
      @enemy = { name: "くろきし", sp: :knight, hp: 26 + @floor * 4, max_hp: 26 + @floor * 4, atk: 8 + @floor, blk: 0, intent: :attack }
    else
      @enemy = { name: "クリスタルスライム", sp: :slime, hp: 18 + @floor * 3, max_hp: 18 + @floor * 3, atk: 6 + @floor, blk: 0, intent: :attack }
    end
    @block = 0
    @draw_pile = shuffle_arr(@deck)
    @discard_pile = []
    @hand = []
    start_turn
  end

  def start_turn
    @mana = @max_mana
    @block = 0
    draw_cards(5)
    @sel_idx = 0
    roll_intent
  end

  def roll_intent
    r = rand(3)
    if r == 0
      @enemy[:intent] = :attack
      @enemy[:next_val] = @enemy[:atk]
    elsif r == 1
      @enemy[:intent] = :heavy
      @enemy[:next_val] = (@enemy[:atk] * 1.4).to_i
    else
      @enemy[:intent] = :guard
      @enemy[:next_val] = 6 + @floor
    end
  end

  def draw_cards(n)
    n.times do
      break if @hand.size >= 7
      if @draw_pile.empty?
        break if @discard_pile.empty?
        @draw_pile = shuffle_arr(@discard_pile)
        @discard_pile = []
      end
      @hand << @draw_pile.pop
    end
  end

  def play_card(idx)
    return if idx < 0 || idx >= @hand.size
    cid = @hand[idx]
    c = CARDS[cid]
    return if @mana < c[:cost]

    @mana -= c[:cost]
    @hand.delete_at(idx)
    @discard_pile << cid
    @sel_idx = [@sel_idx, @hand.size - 1].min
    @sel_idx = 0 if @sel_idx < 0

    if c[:dmg] > 0
      dmg = c[:dmg]
      if @enemy[:blk] > 0
        absorbed = [dmg, @enemy[:blk]].min
        @enemy[:blk] -= absorbed
        dmg -= absorbed
      end
      @enemy[:hp] -= dmg
      @shake = 5.0
      @fx_list << { x0: 180.0, y0: 210.0, x1: 460.0, y1: 190.0, col: c[:col], life: 16, max_life: 16 }
      14.times do
        a = rand * 6.28
        @sparks << { x: 460.0, y: 190.0, vx: cos(a) * 3.5, vy: sin(a) * 3.5, life: 20, max_life: 20, col: c[:col] }
      end
    end
    if c[:blk] > 0
      @block += c[:blk]
      10.times do
        a = rand * 6.28
        @sparks << { x: 170.0, y: 200.0, vx: cos(a) * 2.5, vy: sin(a) * 2.5, life: 18, max_life: 18, col: 12 }
      end
    end
    if c[:heal] > 0
      @hp = [@hp + c[:heal], @max_hp].min
    end
    if c[:draw] > 0
      draw_cards(c[:draw])
    end

    @log = "#{c[:name]} を発動！"

    if @enemy[:hp] <= 0
      @enemy[:hp] = 0
      if @floor >= @max_floor
        @state = :victory
      else
        @state = :reward
        pool = shuffle_arr(REWARD_POOL)
        @rewards = [pool[0], pool[1], pool[2]]
        @sel_idx = 0
      end
    end
  end

  def end_turn
    # 手札を捨て札へ
    while @hand.size > 0
      @discard_pile << @hand.pop
    end
    # 敵の行動
    if @enemy[:intent] == :guard
      @enemy[:blk] += @enemy[:next_val]
      @log = "#{@enemy[:name]} は身を守った！"
    else
      dmg = @enemy[:next_val]
      if @block > 0
        ab = [dmg, @block].min
        @block -= ab
        dmg -= ab
      end
      @hp -= dmg
      @shake = 6.0 if dmg > 0
      @log = "#{@enemy[:name]} の攻撃！ #{dmg} ダメージ！"
      if @hp <= 0
        @hp = 0
        @state = :gameover
        return
      end
    end
    start_turn
  end

  def update
    @frame += 1
    @shake *= 0.85

    @fx_list.each { |f| f[:life] -= 1 }
    @fx_list.reject! { |f| f[:life] <= 0 }
    @sparks.each do |s|
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }

    if @state == :title
      if @frame > 5 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        reset_run
        @state = :battle
      end
      return
    end

    if @state == :gameover || @state == :victory
      if btnp(4) || btnp(5) || btnp(:mouse_l)
        reset_run
        @state = :battle
      end
      return
    end

    if @state == :reward
      @sel_idx = (@sel_idx - 1) % 3 if btnp(0)
      @sel_idx = (@sel_idx + 1) % 3 if btnp(1)
      if btnp(4)
        @deck << @rewards[@sel_idx]
        @floor += 1
        @hp = [@hp + 5, @max_hp].min
        start_battle
        @state = :battle
        return
      end
      if btnp(:mouse_l)
        mx = mouse_x
        my = mouse_y
        if my >= 160 && my <= 310
          3.times do |i|
            cx = 110 + i * 150
            if mx >= cx && mx <= cx + 120
              @deck << @rewards[i]
              @floor += 1
              @hp = [@hp + 5, @max_hp].min
              start_battle
              @state = :battle
              return
            end
          end
        end
      end
      return
    end

    # バトル中操作
    if @hand.size > 0
      @sel_idx = (@sel_idx - 1) % @hand.size if btnp(0)
      @sel_idx = (@sel_idx + 1) % @hand.size if btnp(1)
    end

    if btnp(4) && @hand.size > 0
      play_card(@sel_idx)
      return
    end

    if btnp(5)
      end_turn
      return
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      # ターン終了ボタン (510, 260, 110, 36)
      if mx >= 510 && mx <= 620 && my >= 260 && my <= 296
        end_turn
        return
      end
      # 手札クリック
      n = @hand.size
      if n > 0 && my >= 325 && my <= 465
        cw = 84
        gap = 8
        total_w = n * cw + (n - 1) * gap
        start_x = (SW - total_w) / 2
        n.times do |i|
          x = start_x + i * (cw + gap)
          if mx >= x && mx <= x + cw
            @sel_idx = i
            play_card(i)
            break
          end
        end
      end
    end
  end

  def draw
    cls(0)
    sx = @shake > 0.2 ? (rand * 2.0 - 1.0) * @shake : 0.0
    sy = @shake > 0.2 ? (rand * 2.0 - 1.0) * @shake : 0.0
    camera(sx, sy)

    bg(:cave, 0, 0, dim: 0.45)

    # 味方＆敵キャラクター描画 (sprite_scale: 2.0 なので 32x32)
    spr(:hero, 150, 184)
    spr(@enemy[:sp], 444, 178)

    # 魔法エフェクト (加算合成)
    blend(:add)
    @fx_list.each do |f|
      al = f[:life].to_f / f[:max_life]
      line(f[:x0], f[:y0], f[:x1], f[:y1], f[:col], 8, al * 0.7)
      line(f[:x0], f[:y0], f[:x1], f[:y1], 7, 2, al)
    end
    @sparks.each do |s|
      circfill(s[:x], s[:y], 3.0, s[:col], s[:life].to_f / s[:max_life])
    end
    blend(:normal)

    camera()
    draw_ui
  end

  def draw_ui
    if @state == :title
      rectfill(100, 90, 440, 270, 0, 0.88)
      rect(100, 90, 440, 270, 10, 2)
      print_text("ARCANA DECK", 232, 116, 10, 16)
      print_text("デッキ構築ローグライトカードバトル", 184, 150, 7, 16)
      print_text("クリック / Z : カード使用・選択", 190, 198, 12, 16)
      print_text("X / Enter    : ターン終了", 190, 226, 11, 16)
      print_text("クリックまたは Z で冒険開始！", 196, 290, 10, 16)
      return
    end

    # 上部ステータスバー
    rectfill(0, 0, SW, 42, 0, 0.78)
    line(0, 42, SW, 42, 6, 1, 0.5)
    print_text(format("階層 %d/%d", @floor, @max_floor), 16, 12, 10, 16)
    print_text(format("HP %d/%d", @hp, @max_hp), 140, 12, 11, 16)
    print_text(format("防御 %d", @block), 280, 12, 12, 16)
    print_text(format("マナ %d/%d", @mana, @max_mana), 400, 12, 14, 16)
    print_text(format("山札:%d", @draw_pile.size), 540, 12, 6, 16)

    # 敵ステータス
    rectfill(370, 96, 210, 68, 0, 0.75)
    rect(370, 96, 210, 68, 8, 1)
    print_text(@enemy[:name], 382, 104, 7, 16)
    print_text(format("HP %d/%d", @enemy[:hp], @enemy[:max_hp]), 382, 124, 8, 16)
    int_txt = @enemy[:intent] == :guard ? format("次の行動: 防御+%d", @enemy[:next_val]) : format("次の行動: 攻撃 %d", @enemy[:next_val])
    print_text(int_txt, 382, 142, 10, 16)

    # バトルログ
    rectfill(20, 260, 470, 34, 0, 0.72)
    print_text(@log, 32, 269, 7, 16)

    # ターン終了ボタン
    rectfill(510, 260, 110, 36, 1, 0.9)
    rect(510, 260, 110, 36, 10, 2)
    print_text("ターン終了", 525, 270, 10, 16)

    # 手札描画
    n = @hand.size
    if n > 0 && @state == :battle
      cw = 84
      ch = 128
      gap = 8
      total_w = n * cw + (n - 1) * gap
      start_x = (SW - total_w) / 2
      n.times do |i|
        cid = @hand[i]
        c = CARDS[cid]
        x = start_x + i * (cw + gap)
        sel = (i == @sel_idx)
        y = sel ? 324 : 338
        playable = (@mana >= c[:cost])

        if sel && playable
          blend(:add)
          rectfill(x - 4, y - 4, cw + 8, ch + 8, c[:col], 0.38)
          blend(:normal)
        end

        rectfill(x, y, cw, ch, playable ? 1 : 0, 0.88)
        rect(x, y, cw, ch, sel ? 10 : c[:col], sel ? 2 : 1)
        circfill(x + 14, y + 14, 9, c[:col])
        print_text(c[:cost].to_s, x + 11, y + 10, 7, 8)
        print_text(c[:name], x + 6, y + 34, 7, 8)
        print_text(c[:desc], x + 6, y + 60, 6, 8)
      end
    end

    # モーダルオーバーレイ
    if @state == :title
      rectfill(100, 90, 440, 270, 0, 0.86)
      rect(100, 90, 440, 270, 10, 2)
      print_text("ARCANA DECK", 232, 116, 10, 16)
      print_text("デッキ構築ローグライトカードバトル", 184, 150, 7, 16)
      print_text("クリック / Z : カード使用・選択", 190, 198, 12, 16)
      print_text("X / Enter    : ターン終了", 190, 226, 11, 16)
      print_text("クリックまたは Z で冒険開始！", 196, 290, 10, 16)
    elsif @state == :reward
      rectfill(70, 90, 500, 260, 0, 0.88)
      rect(70, 90, 500, 260, 10, 2)
      print_text("勝利！ 新しいカードを1枚選択", 190, 112, 10, 16)
      3.times do |i|
        c = CARDS[@rewards[i]]
        cx = 110 + i * 150
        sel = (i == @sel_idx)
        if sel
          blend(:add)
          rectfill(cx - 4, 156, 128, 158, c[:col], 0.35)
          blend(:normal)
        end
        rectfill(cx, 160, 120, 150, 1, 0.92)
        rect(cx, 160, 120, 150, sel ? 10 : c[:col], sel ? 2 : 1)
        print_text(format("[%d] %s", c[:cost], c[:name]), cx + 8, 174, 7, 8)
        print_text(c[:desc], cx + 8, 210, 6, 8)
      end
    elsif @state == :gameover
      rectfill(160, 150, 320, 160, 0, 0.9)
      rect(160, 150, 320, 160, 8, 2)
      print_text("力尽きた…", 272, 180, 8, 16)
      print_text(format("到達階層: %d / %d", @floor, @max_floor), 240, 220, 7, 16)
      print_text("Z / クリック でリトライ", 224, 260, 10, 16)
    elsif @state == :victory
      rectfill(140, 140, 360, 180, 0, 0.9)
      rect(140, 140, 360, 180, 10, 2)
      print_text("迷宮完全制覇！", 256, 172, 10, 16)
      print_text("深淵の龍を打ち倒した！", 224, 212, 7, 16)
      print_text("Z / クリック で再挑戦", 232, 264, 11, 16)
    end
  end
end

run ArcanaDeckGame.new

__END__
@PALETTE 1
1: #161830
2: #7E2553
3: #008751
7: #FFF1E8
8: #FF2048
9: #FFA300
A: #FFEC27
B: #00E436
C: #29ADFF
E: #FF77A8
F: #FFCCAA

@SPRITE :hero 16x16 pal:1
................
.....111111.....
....1CCCCCC1....
...1C777777C1...
...11FFFFFF11...
....1F0FF0F1....
....11FFFF11....
...1188CC8811...
..1CC88CC88CC1..
..1C.1CCCC1.771.
.....111111.....
....1C1..1C1....
....11....11....
................
................
................

@SPRITE :slime 16x16 pal:1
................
................
.....111111.....
...11BBBBBB11...
..1BB77BBBBBB1..
..1B77BBBBBBB1..
.1BBBBBBBBBBBB1.
.1BBB0BBBB0BBB1.
.1BBBBBBBBBBBB1.
.1BBB333333BBB1.
..133333333331..
...1133333311...
................
................
................
................

@SPRITE :knight 16x16 pal:1
.....111111.....
....15555551....
...1566666651...
...1500550051...
....15588551....
...1155555511...
..155885588551..
..15.555555.51..
.....551155.....
....151..151....
....11....11....
................
................
................
................
................

@SPRITE :dragon 16x16 pal:1
..11........11..
.1881.1111.1881.
.18881888818881.
..188888888881..
...188A88A881...
..118888888811..
.18888888888881.
188.188AA881.881
18..18888881..81
....18811881....
...1881..1881...
...11......11...
................
................
................
................
