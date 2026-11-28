# ==============================================================================
# 24. COLONY ORBIT
# ------------------------------------------------------------------------------
# 小惑星採掘＆ドローン自動化の宇宙コロニー・クリッカー
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   クリック / Z : 小惑星をレーザー採掘!
#   下部パネル / ←→ + X  : ドローン・レーザー・精製所を強化!
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "24. COLONY ORBIT"
)

CX = 128.0
CY = 114.0

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
    bg(:space, dim: 0.4, scroll_x: @t * 0.15, mirror_x: true)

    circ(128, 174, 34, 1)
    spr(:asteroid, 112, 158)
    dx = 128 + (cos(@t * 0.06) * 34.0).to_i
    dy = 174 + (sin(@t * 0.06) * 34.0).to_i
    spr(:drone, dx - 4, dy - 4)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 12)
    print_text("COLONY ORBIT", 92, 32, 10)
    print_text("ASTEROID MINING INCREMENTAL!", 44, 46, 12)

    rectfill(24, 78, 208, 56, 0)
    rect(24, 78, 208, 56, 5)
    print_text("CLICK / Z : LASER MINE ASTEROID", 34, 88, 7)
    print_text("UPGRADES  : DRONES & REFINERIES", 34, 101, 10)
    print_text("BUILD AN ORBITAL MINING EMPIRE!", 34, 114, 11)

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO LAUNCH", 50, 224, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @ore = 0
    @total_ore = 0
    @click_pwr = 2
    @drones = 1
    @lasers = 0
    @refinery = 1
    @sel_up = 0

    @beams = []
    @sparks = []
    @popups = []
    @hit_scale = 1.0
  end

  def drone_cost
    (15 * (1.35 ** @drones)).to_i
  end

  def laser_cost
    (35 * (1.45 ** @lasers)).to_i
  end

  def ref_cost
    (90 * (1.6 ** (@refinery - 1))).to_i
  end

  def mine_hit(sx, sy, amt, col)
    gain = amt * @refinery
    @ore += gain
    @total_ore += gain
    @hit_scale = 1.16
    @beams << { x1: sx, y1: sy, x2: CX + (rand() - 0.5) * 14.0, y2: CY + (rand() - 0.5) * 14.0, col: col, life: 6 }
    @popups << { x: CX.to_i + rand(-18..18), y: CY.to_i - 18, text: "+#{gain}", col: col, life: 22 }
    i = 0
    while i < 4
      ang = rand() * Math::PI * 2.0
      @sparks << { x: CX, y: CY, vx: cos(ang) * 2.0, vy: sin(ang) * 2.0, col: col, life: 12 }
      i += 1
    end
  end

  def buy_upgrade(idx)
    if idx == 0 && @ore >= drone_cost
      @ore -= drone_cost
      @drones += 1
    elsif idx == 1 && @ore >= laser_cost
      @ore -= laser_cost
      @lasers += 1
      @click_pwr += 3
    elsif idx == 2 && @ore >= ref_cost
      @ore -= ref_cost
      @refinery += 1
    end
  end

  def update
    @t += 1
    @hit_scale += (1.0 - @hit_scale) * 0.25

    @sel_up = (@sel_up - 1) % 3 if btnp(:left)
    @sel_up = (@sel_up + 1) % 3 if btnp(:right)
    buy_upgrade(@sel_up) if btnp(2)

    if btnp(1)
      mine_hit(24.0, 48.0, @click_pwr, 10)
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 214
        i = 0
        while i < 3
          bx = 6 + i * 82
          if mx >= bx && mx <= bx + 78
            @sel_up = i
            buy_upgrade(i)
          end
          i += 1
        end
      elsif my > 20
        mine_hit(mx.to_f, my.to_f, @click_pwr, 10)
      end
    end

    # ドローン自動採掘
    if @drones > 0 && @t % 30 == 0
      i = 0
      cnt = @drones > 8 ? 8 : @drones
      while i < cnt
        ang = @t * 0.03 + i * (Math::PI * 2.0 / cnt)
        dx = CX + cos(ang) * 48.0
        dy = CY + sin(ang) * 48.0
        @beams << { x1: dx, y1: dy, x2: CX, y2: CY, col: 12, life: 5 }
        i += 1
      end
      gain = @drones * @refinery
      @ore += gain
      @total_ore += gain
    end

    # レーザー衛星自動攻撃
    if @lasers > 0 && @t % 45 == 0
      mine_hit(232.0, 48.0, @lasers * 2, 14)
    end

    @beams.each { |b| b[:life] -= 1 }
    @beams.reject! { |b| b[:life] <= 0 }
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
    bg(:space, dim: 0.42, scroll_x: @t * 0.1, mirror_x: true)

    # 軌道リング
    circ(CX.to_i, CY.to_i, 48, 1)
    circ(CX.to_i, CY.to_i, 74, 1)

    # 小惑星
    spr_ext(:asteroid, CX.to_i, CY.to_i, @t * 0.4, @hit_scale, @hit_scale, false, false)

    # ドローン
    cnt = @drones > 12 ? 12 : @drones
    i = 0
    while i < cnt
      ang = @t * 0.03 + i * (Math::PI * 2.0 / cnt)
      dx = CX + cos(ang) * 48.0
      dy = CY + sin(ang) * 48.0
      spr(:drone, dx.to_i - 4, dy.to_i - 4)
      i += 1
    end

    @beams.each { |b| line(b[:x1].to_i, b[:y1].to_i, b[:x2].to_i, b[:y2].to_i, b[:col]) }
    @sparks.each { |s| rectfill(s[:x].to_i, s[:y].to_i, 2, 2, s[:col]) }
    @popups.each { |pp| print_text(pp[:text], pp[:x] - pp[:text].length * 3, pp[:y], pp[:col]) }

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("ORE:#{@ore}", 6, 6, 10)
    rate = (@drones * 2 + @lasers * 2) * @refinery
    print_text("+#{rate}/s", 104, 6, 12)
    print_text("MULT:x#{@refinery}", 192, 6, 14)

    # 下部アップグレード
    rectfill(0, 210, 256, 46, 0)
    line(0, 210, 256, 210, 5)
    ups = [
      { name: "DRONE",  lv: @drones,   cost: drone_cost, col: 12 },
      { name: "LASER",  lv: @lasers,   cost: laser_cost, col: 14 },
      { name: "REFINE", lv: @refinery, cost: ref_cost,   col: 11 }
    ]
    i = 0
    while i < 3
      u = ups[i]
      bx = 6 + i * 82
      can = @ore >= u[:cost]
      sel = (i == @sel_up)
      rectfill(bx, 215, 78, 36, sel ? 1 : 0)
      rect(bx, 215, 78, 36, can ? u[:col] : 5)
      print_text("#{u[:name]} #{u[:lv]}", bx + 6, 221, can ? u[:col] : 6)
      print_text("#{u[:cost]} ORE", bx + 6, 235, can ? 10 : 5)
      i += 1
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #060812
4: #8A4836
5: #5F574F
6: #C2C3C7
7: #FFF1E8
A: #FFEC27
C: #29ADFF

@SPRITE :asteroid 32x32 pal:1
................................
..........0000000000............
.......000556666655500..........
.....0055667766655555500........
....055666665555445555550.......
...0566CC65555444455566550......
..0566CCCC65555555556CC6550.....
..0566CCCC55555555556CC6550.....
.055655CC5555445555555555550....
.055555555554444555555555550....
.055544555555445555CC5555550....
..0554445555555555CCCC55550.....
..05555555566555555CC555550.....
...05555556666555555555550......
....055555555555555555550.......
.....0055555555555555500........
.......000555555555000..........
..........0000000000............
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................
................................

@SPRITE :drone 8x8 pal:1
...00...
..0CC0..
.0C77C0.
0CCCCCC0
0C0CC0C0
.0CACC0.
..0000..
........
