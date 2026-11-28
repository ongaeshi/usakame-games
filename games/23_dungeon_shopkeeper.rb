# ==============================================================================
# 23. DUNGEON SHOPKEEPER
# ------------------------------------------------------------------------------
# 勇者相手の値付け＆仕入れで商会を育てるアイテム屋経営 (640x480 VGA)
# 640x480 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   マウスクリック / ↑↓ + Z : 値付け交渉 / 仕入れボタン操作
# ==============================================================================

config(
  width: 640,
  height: 480,
  scale: 2,
  sprite_scale: 2.0,
  text_size: 16,
  title: "23. DUNGEON SHOPKEEPER"
)

ITEMS = [
  { id: :potion, name: "ポーション",   base: 50,  col: 8 },
  { id: :sword,  name: "てつのけん",   base: 120, col: 12 },
  { id: :robe,   name: "まほうのローブ", base: 180, col: 14 },
  { id: :elixir, name: "エリクサー",   base: 320, col: 10 }
]

CUSTOMERS = [
  { name: "ゆうしゃウサ", sp: :hero,  msg: "冒険の準備だ！これを売ってくれ！" },
  { name: "まどうし",     sp: :mage,  msg: "魔力を高める品を探しているの。" },
  { name: "せんしカメ",   sp: :guard, msg: "頑丈な装備が欲しいのだが…" }
]

$shop_best_gold ||= 0

def draw_win(x, y, w, h, title = "", col = 6)
  rectfill(x, y, w, h, 0)
  rect(x, y, w, h, col)
  rect(x + 2, y + 2, w - 4, h - 4, col)
  if title != ""
    rectfill(x + 12, y - 8, title.length * 14 + 16, 16, 0)
    print_text(title, x + 20, y - 8, 10, size: 16)
  end
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
    cls(1)
    bg(:city, dim: 0.55, tint: [220, 175, 130])

    spr(:keeper, 296, 260)

    draw_win(80, 48, 480, 100, "", 10)
    print_text("DUNGEON SHOPKEEPER", 180, 68, 10, size: 16)
    print_text("ダンジョン前の道具屋を経営して大富豪を目指せ！", 120, 104, 7, size: 16)

    draw_win(100, 176, 440, 140, "遊び方", 12)
    print_text("・安い時に仕入れて、勇者に高く売ろう！", 124, 208, 7, size: 16)
    print_text("・値引きで評判UP / 強気価格で利益UP！", 124, 236, 11, size: 16)
    if $shop_best_gold > 0
      print_text("最高資産: #{$shop_best_gold} G", 240, 272, 10, size: 16)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO OPEN SHOP", 188, 390, 10, size: 16)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @day = 1
    @max_days = 10
    @gold = 300
    @rep = 50
    @stock = [3, 1, 1, 0]
    @market_mult = [1.0, 1.0, 1.0, 1.0]
    @log = "今日もお店を開店した！"
    @cust = nil
    @want_idx = 0
    @sel_btn = 1
    @finished = false
    @fin_t = 0
    roll_market
    next_customer
  end

  def roll_market
    i = 0
    while i < 4
      @market_mult[i] = [0.7, 0.9, 1.0, 1.2][rand(4)]
      i += 1
    end
  end

  def next_customer
    @cust = CUSTOMERS[rand(CUSTOMERS.size)]
    @want_idx = rand(ITEMS.size)
  end

  def sell_price(mult)
    (ITEMS[@want_idx][:base] * mult).to_i
  end

  def try_sell(mult, rep_delta, chance_base)
    if @stock[@want_idx] <= 0
      @log = "在庫がない！下の市場から仕入れよう。"
      return
    end
    chance = chance_base + (@rep / 4).to_i
    if rand(100) < chance
      price = sell_price(mult)
      @stock[@want_idx] -= 1
      @gold += price
      @rep += rep_delta
      @rep = 100 if @rep > 100
      @rep = 0 if @rep < 0
      @log = "#{ITEMS[@want_idx][:name]} が #{price}G で売れた！"
      advance_turn
    else
      @rep -= 4
      @rep = 0 if @rep < 0
      @log = "「高すぎるよ！」客は帰ってしまった…"
      advance_turn
    end
  end

  def advance_turn
    @day += 1
    if @day > @max_days
      @finished = true
      @fin_t = 0
      $shop_best_gold = @gold if @gold > $shop_best_gold
    else
      roll_market
      next_customer
    end
  end

  def buy_stock(idx)
    price = (ITEMS[idx][:base] * 0.65 * @market_mult[idx]).to_i
    if @gold >= price
      @gold -= price
      @stock[idx] += 1
      @log = "#{ITEMS[idx][:name]} を #{price}G で仕入れた！"
    else
      @log = "ゴールドが足りない！"
    end
  end

  def update
    @t += 1
    if @finished
      @fin_t += 1
      if @fin_t > 30 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    @sel_btn = (@sel_btn - 1) % 3 if btnp(:up)
    @sel_btn = (@sel_btn + 1) % 3 if btnp(:down)
    if btnp(1)
      if @sel_btn == 0
        try_sell(0.85, 6, 100)
      elsif @sel_btn == 1
        try_sell(1.0, 2, 95)
      else
        try_sell(1.35, -3, 60)
      end
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      # 販売ボタン (x: 410..610, y: 150..270)
      if mx >= 410 && mx <= 610
        if my >= 150 && my <= 184
          try_sell(0.85, 6, 100)
        elsif my >= 192 && my <= 226
          try_sell(1.0, 2, 95)
        elsif my >= 234 && my <= 268
          try_sell(1.35, -3, 60)
        elsif my >= 276 && my <= 306
          @log = "次の客を待った。"
          advance_turn
        end
      end

      # 仕入れボタン (下部)
      if my >= 364 && my <= 448
        i = 0
        while i < 4
          bx = 24 + i * 150
          if mx >= bx && mx <= bx + 140
            buy_stock(i)
          end
          i += 1
        end
      end
    end
  end

  def draw
    cls(1)
    bg(:city, dim: 0.6, tint: [215, 170, 125])

    # 上部ステータスバー
    rectfill(0, 0, 640, 44, 0)
    line(0, 44, 640, 44, 6)
    print_text("DAY #{@day}/#{@max_days}", 20, 14, 12, size: 16)
    print_text("GOLD: #{@gold} G", 170, 14, 10, size: 16)
    print_text("評判: #{@rep}%", 380, 14, 11, size: 16)
    print_text("BEST: #{$shop_best_gold}G", 500, 14, 6, size: 16)

    # 接客ウィンドウ
    draw_win(20, 60, 370, 250, "カウンター", 6)
    spr(@cust[:sp], 64, 110)
    spr(:keeper, 290, 110)
    print_text(@cust[:name], 52, 152, 10, size: 16)
    print_text(@cust[:msg], 38, 186, 7, size: 16)

    it = ITEMS[@want_idx]
    print_text("希望品: #{it[:name]}", 38, 224, it[:col], size: 16)
    print_text("所持在庫: #{@stock[@want_idx]} 個", 38, 252, @stock[@want_idx] > 0 ? 11 : 8, size: 16)
    print_text(@log, 38, 282, 10, size: 8)

    # 交渉コマンド
    draw_win(400, 60, 220, 250, "値付け交渉", 10)
    btns = [
      { lbl: "サービス #{sell_price(0.85)}G", col: 11, y: 150 },
      { lbl: "定価販売 #{sell_price(1.0)}G",  col: 7,  y: 192 },
      { lbl: "強気価格 #{sell_price(1.35)}G", col: 9,  y: 234 }
    ]
    btns.each_with_index do |b, idx|
      rectfill(412, b[:y], 196, 34, @sel_btn == idx ? 1 : 0)
      rect(412, b[:y], 196, 34, @sel_btn == idx ? 10 : b[:col])
      print_text(b[:lbl], 426, b[:y] + 9, b[:col], size: 16)
    end
    rectfill(412, 276, 196, 26, 0)
    rect(412, 276, 196, 26, 5)
    print_text("見送る (次の日へ)", 432, 281, 6, size: 16)

    # 下部 仕入れ市場
    draw_win(20, 332, 600, 132, "卸売市場 (クリックで仕入れ)", 12)
    i = 0
    while i < 4
      item = ITEMS[i]
      bx = 32 + i * 148
      cost = (item[:base] * 0.65 * @market_mult[i]).to_i
      is_sale = @market_mult[i] < 0.8
      rectfill(bx, 366, 138, 84, 1)
      rect(bx, 366, 138, 84, is_sale ? 10 : item[:col])
      print_text(item[:name], bx + 10, 376, item[:col], size: 16)
      print_text("#{cost} G", bx + 14, 402, 10, size: 16)
      print_text("在庫:#{@stock[i]}", bx + 14, 426, 7, size: 16)
      print_text("特売!", bx + 86, 402, 11, size: 16) if is_sale
      i += 1
    end

    if @finished
      draw_win(140, 140, 360, 180, "決算結果", 10)
      rank = @gold >= 1200 ? "S" : (@gold >= 800 ? "A" : (@gold >= 500 ? "B" : "C"))
      print_text("10日間の営業終了！", 220, 174, 10, size: 16)
      print_text("最終資産 : #{@gold} G", 220, 210, 7, size: 16)
      print_text("商会ランク : #{rank}", 220, 240, 11, size: 16)
      if (@fin_t / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 196, 282, 12, size: 16)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #0A0814
1: #1D2B53
4: #8A4836
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
B: #00E436
C: #29ADFF
E: #FF77A8
F: #FFCCAA

@SPRITE :keeper 16x16 pal:1
................
.....000000.....
....07777770....
...0770770770...
....00FFFF00....
...033AAAA330...
..033033330330..
...0033333300...
....04400440....
....000..000....
................
................
................
................
................
................

@SPRITE :hero 16x16 pal:1
................
.....000000.....
....07777770....
...0770770770...
....00FFFF00....
...0888888880...
..060CCCCCC060..
...00CCCCCC00...
....01100110....
....000..000....
................
................
................
................
................
................

@SPRITE :mage 16x16 pal:1
......0000......
.....0EEEE0.....
....0EEEEEE0....
...0000000000...
....077FF770....
...0770FF0770...
....00FFFF00....
...0222EE2220...
....022AA220....
....000..000....
................
................
................
................
................
................

@SPRITE :guard 16x16 pal:1
................
.....000000.....
....0BBBBBB0....
...0B77FF77B0...
...0B70FF07B0...
....00FFFF00....
...0555665550...
..055055550550..
....05500550....
....000..000....
................
................
................
................
................
................
