# ==============================================================================
# 12. ORBIT TD
# ------------------------------------------------------------------------------
# 中央惑星を守る全方位リング軌道タワーディフェンス
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   マウスクリック / 矢印+Z : 軌道スロットにタレット建設 / LvUP強化
#   下部ボタン / X          : タレット種別切替 (LASER / FROST / CANNON)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "12. ORBIT TD"
)

CX = 128.0
CY = 126.0

TOWER_TYPES = [
  { id: :laser,  name: "LASER",  cost: 15, range: 64.0, cd: 16, dmg: 2, col: 12 },
  { id: :frost,  name: "FROST",  cost: 20, range: 58.0, cd: 38, dmg: 1, col: 7  },
  { id: :cannon, name: "CANNON", cost: 25, range: 76.0, cd: 42, dmg: 5, col: 9  }
]

$orbit_best_wave ||= 0

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

    circ(CX.to_i, 166, 44, 1)
    circ(CX.to_i, 166, 72, 1)
    spr(:planet, CX.to_i - 16, 150)

    rectfill(26, 24, 204, 40, 0)
    rect(26, 24, 204, 40, 12)
    print_text("ORBIT TD", 104, 32, 10)
    print_text("360-DEGREE PLANETARY DEFENSE", 44, 46, 12)

    rectfill(24, 76, 208, 56, 0)
    rect(24, 76, 208, 56, 5)
    print_text("CLICK SLOT / Z : BUILD & UPGRADE", 32, 86, 7)
    print_text("CLICK TAB / X  : SWITCH TURRET", 32, 99, 10)
    if $orbit_best_wave > 0
      print_text("BEST WAVE: #{$orbit_best_wave}", 86, 114, 11)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO DEFEND", 50, 224, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @wave = 1
    @hp = 10
    @gold = 45
    @score = 0
    @sel_type = 0
    @cur_slot = 0

    @slots = []
    # 内周6スロット + 外周6スロット
    [42.0, 72.0].each_with_index do |r, ring_idx|
      i = 0
      while i < 6
        ang = i * Math::PI / 3.0 + (ring_idx == 1 ? Math::PI / 6.0 : 0.0)
        @slots << {
          x: CX + cos(ang) * r,
          y: CY + sin(ang) * r,
          tower: nil
        }
        i += 1
      end
    end

    # 初期タレット1基
    @slots[0][:tower] = { type: 0, lvl: 1, cd: 0 }

    @enemies = []
    @beams = []
    @rings = []
    @particles = []
    @popups = []

    @wave_rem = 6
    @spawn_cd = 30
    @dead = false
    @dead_timer = 0
  end

  def spawn_enemy
    ang = rand() * Math::PI * 2.0
    dist = 148.0
    kind = @wave >= 3 && rand(4) == 0 ? :heavy : (rand(3) == 0 ? :fast : :raider)
    hp = kind == :heavy ? (10 + @wave * 3) : (kind == :fast ? (3 + @wave) : (5 + @wave * 2))
    spd = kind == :fast ? 0.58 : (kind == :heavy ? 0.25 : 0.38)
    @enemies << {
      x: CX + cos(ang) * dist, y: CY + sin(ang) * dist,
      hp: hp, max_hp: hp, spd: spd, slow: 0, kind: kind, alive: true
    }
  end

  def build_or_upgrade(slot_idx)
    sl = @slots[slot_idx]
    return if sl.nil?
    if sl[:tower].nil?
      cost = TOWER_TYPES[@sel_type][:cost]
      if @gold >= cost
        @gold -= cost
        sl[:tower] = { type: @sel_type, lvl: 1, cd: 0 }
        @rings << { x: sl[:x], y: sl[:y], r: 3.0, max_r: 14.0, col: 10 }
      end
    else
      tw = sl[:tower]
      up_cost = 15 * tw[:lvl]
      if tw[:lvl] < 3 && @gold >= up_cost
        @gold -= up_cost
        tw[:lvl] += 1
        @rings << { x: sl[:x], y: sl[:y], r: 3.0, max_r: 18.0, col: 11 }
        @popups << { x: sl[:x], y: sl[:y] - 8.0, text: "LV#{tw[:lvl]}!", col: 10, life: 26 }
      end
    end
  end

  def update
    @t += 1
    if @dead
      @dead_timer += 1
      if @dead_timer > 30 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    # キー操作
    @cur_slot = (@cur_slot - 1) % @slots.size if btnp(:left)
    @cur_slot = (@cur_slot + 1) % @slots.size if btnp(:right)
    @cur_slot = (@cur_slot + 6) % @slots.size if btnp(:up) || btnp(:down)
    @sel_type = (@sel_type + 1) % TOWER_TYPES.size if btnp(2)
    build_or_upgrade(@cur_slot) if btnp(1)

    # マウス操作
    if btnp(:mouse_l)
      mx = mouse_x.to_f
      my = mouse_y.to_f
      if my >= 224.0
        i = 0
        while i < 3
          bx = 8.0 + i * 82.0
          if mx >= bx && mx <= bx + 76.0
            @sel_type = i
          end
          i += 1
        end
      else
        @slots.each_with_index do |sl, idx|
          dx = mx - sl[:x]
          dy = my - sl[:y]
          if dx * dx + dy * dy < 12.0 * 12.0
            @cur_slot = idx
            build_or_upgrade(idx)
            break
          end
        end
      end
    end

    # スポーン
    if @wave_rem > 0
      @spawn_cd -= 1
      if @spawn_cd <= 0
        spawn_enemy
        @wave_rem -= 1
        @spawn_cd = 48 - @wave * 3
        @spawn_cd = 18 if @spawn_cd < 18
      end
    elsif @enemies.empty?
      @wave += 1
      $orbit_best_wave = @wave if @wave > $orbit_best_wave
      @gold += 15 + @wave * 3
      @wave_rem = 5 + @wave * 2
      @spawn_cd = 45
      @popups << { x: CX, y: CY - 24.0, text: "WAVE #{@wave}!", col: 10, life: 36 }
    end

    # タワー攻撃
    @slots.each do |sl|
      tw = sl[:tower]
      next if tw.nil?
      td = TOWER_TYPES[tw[:type]]
      tw[:cd] -= 1 if tw[:cd] > 0
      next if tw[:cd] > 0

      range = td[:range] + (tw[:lvl] - 1) * 10.0
      target = nil
      best_d = 9999.0
      @enemies.each do |e|
        next unless e[:alive]
        dx = e[:x] - sl[:x]
        dy = e[:y] - sl[:y]
        d = sqrt(dx * dx + dy * dy)
        if d <= range && d < best_d
          best_d = d
          target = e
        end
      end
      next if target.nil?

      tw[:cd] = td[:cd] - (tw[:lvl] - 1) * 2
      dmg = td[:dmg] + (tw[:lvl] - 1)

      if td[:id] == :frost
        @rings << { x: sl[:x], y: sl[:y], r: 6.0, max_r: range, col: 12 }
        @enemies.each do |e|
          dx = e[:x] - sl[:x]
          dy = e[:y] - sl[:y]
          if dx * dx + dy * dy <= range * range
            e[:slow] = 90
            e[:hp] -= dmg
          end
        end
      elsif td[:id] == :cannon
        @beams << { x1: sl[:x], y1: sl[:y], x2: target[:x], y2: target[:y], col: 9, life: 7 }
        @rings << { x: target[:x], y: target[:y], r: 4.0, max_r: 22.0, col: 9 }
        @enemies.each do |e|
          dx = e[:x] - target[:x]
          dy = e[:y] - target[:y]
          if dx * dx + dy * dy <= 24.0 * 24.0
            e[:hp] -= dmg
          end
        end
      else
        @beams << { x1: sl[:x], y1: sl[:y], x2: target[:x], y2: target[:y], col: 12, life: 6 }
        target[:hp] -= dmg
      end
    end

    # 敵移動 & 死亡判定
    @enemies.each do |e|
      if e[:hp] <= 0
        e[:alive] = false
        @gold += e[:kind] == :heavy ? 8 : 4
        @score += e[:kind] == :heavy ? 120 : 50
        i = 0
        while i < 6
          ang = rand() * Math::PI * 2.0
          @particles << { x: e[:x], y: e[:y], vx: cos(ang) * 1.8, vy: sin(ang) * 1.8, col: 10, life: 14 }
          i += 1
        end
        next
      end

      e[:slow] -= 1 if e[:slow] > 0
      spd = e[:slow] > 0 ? e[:spd] * 0.45 : e[:spd]
      dx = CX - e[:x]
      dy = CY - e[:y]
      d = sqrt(dx * dx + dy * dy)
      if d < 16.0
        e[:alive] = false
        @hp -= 1
        @rings << { x: CX, y: CY, r: 8.0, max_r: 28.0, col: 8 }
        if @hp <= 0
          @dead = true
          @dead_timer = 0
        end
      else
        e[:x] += dx / d * spd
        e[:y] += dy / d * spd
      end
    end
    @enemies.reject! { |e| !e[:alive] }

    @beams.each { |b| b[:life] -= 1 }
    @beams.reject! { |b| b[:life] <= 0 }
    @rings.each { |r| r[:r] += 2.2 }
    @rings.reject! { |r| r[:r] >= r[:max_r] }
    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }
    @popups.each do |pp|
      pp[:y] -= 0.5
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }
  end

  def draw
    cls(0)
    bg(:space, dim: 0.45, scroll_x: @t * 0.08, mirror_x: true)

    # 軌道リング
    circ(CX.to_i, CY.to_i, 42, 1)
    circ(CX.to_i, CY.to_i, 72, 1)

    # 中央惑星
    spr(:planet, CX.to_i - 16, CY.to_i - 16)

    # スロット & タワー
    @slots.each_with_index do |sl, idx|
      sx = sl[:x].to_i
      sy = sl[:y].to_i
      if sl[:tower].nil?
        circ(sx, sy, 5, idx == @cur_slot ? 10 : 5)
      else
        tw = sl[:tower]
        td = TOWER_TYPES[tw[:type]]
        circfill(sx, sy, 6, 1)
        circ(sx, sy, 6, td[:col])
        print_text("#{tw[:lvl]}", sx - 2, sy - 3, 7)
        circ(sx, sy, 8, 10) if idx == @cur_slot
      end
    end

    # ビーム
    @beams.each do |b|
      line(b[:x1].to_i, b[:y1].to_i, b[:x2].to_i, b[:y2].to_i, b[:col])
    end

    # 敵
    @enemies.each do |e|
      col = e[:slow] > 0 ? 12 : (e[:kind] == :heavy ? 8 : (e[:kind] == :fast ? 10 : 14))
      r = e[:kind] == :heavy ? 5 : 3
      circfill(e[:x].to_i, e[:y].to_i, r, col)
      pset(e[:x].to_i, e[:y].to_i, 7)
    end

    @rings.each { |r| circ(r[:x].to_i, r[:y].to_i, r[:r].to_i, r[:col]) }
    @particles.each { |p| rectfill(p[:x].to_i, p[:y].to_i, 2, 2, p[:col]) }
    @popups.each { |pp| print_text(pp[:text], pp[:x].to_i - pp[:text].length * 3, pp[:y].to_i, pp[:col]) }

    # HUD
    rectfill(0, 0, 256, 18, 0)
    line(0, 18, 256, 18, 5)
    print_text("W:#{@wave}", 6, 5, 12)
    print_text("GOLD:#{@gold}G", 54, 5, 10)
    print_text("SCR:#{@score}", 124, 5, 7)
    print_text("HP:#{@hp}", 212, 5, @hp <= 3 ? 8 : 11)

    # 下部タレット選択バー
    rectfill(0, 222, 256, 34, 0)
    line(0, 222, 256, 222, 5)
    i = 0
    while i < 3
      td = TOWER_TYPES[i]
      bx = 8 + i * 82
      sel = (i == @sel_type)
      rectfill(bx, 226, 76, 24, sel ? 1 : 0)
      rect(bx, 226, 76, 24, sel ? 10 : td[:col])
      print_text(td[:name], bx + 6, 230, td[:col])
      print_text("#{td[:cost]}G", bx + 48, 230, 10)
      print_text("SLOT[Z/CLK]", bx + 6, 240, 6)
      i += 1
    end

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("PLANET SHATTERED!", 76, 96, 8)
      print_text("WAVE  : #{@wave}", 76, 114, 12)
      print_text("SCORE : #{@score}", 76, 128, 7)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 148, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #060812
1: #1D2B53
3: #008751
7: #FFF1E8
A: #FFEC27
B: #00E436
C: #29ADFF

@SPRITE :planet 32x32 pal:1
................................
..........000000000000..........
........00CCCCCCCCCCCC00........
......00CCCCCCCCCCBBBBCC00......
.....0CCCCBBBBBBBBBBBBBBCC0.....
....0CCCBBBB3333BBBBBBBBCCC0....
...0CCBBBB3333333BBBBCCCCCCC0...
..0CCBBBB333333BBBBCCCCCCCCCC0..
..0CCBBBBBBBBBBBBCCCCCCCCCCCC0..
.0CCCBBBBBBBBBBCCCCCCCCCCCCCCC0.
.0CCCCCBBBBBBCCCCCCCCCCBBBBCCC0.
.0CCCCCCCBBCCCCCCCCCCBBBBBBBCC0.
.0CCCCCCCCCCCCCCCCCBBBBBBBBBBC0.
.0CCCCCCCCCCCCCCCCBBBB3333BBBC0.
.0CCCCCCCCCCCCCCCBBBB333333BBC0.
.0CCCCCCCCCCCCCCCBBBB333333BBC0.
.0CCCCCCCCCCCCCCCCBBBB3333BBBC0.
.0CCCCCCC77CCCCCCCCBBBBBBBBBBC0.
.0CCCCCC7777CCCCCCCCBBBBBBBBCC0.
.0CCCCCCCCCCCCCCCCCCCBBBBBBCCC0.
..0CCCCCCCCCCCCCCCCCCCCCCCCCC0..
..0CCCCCCCCCCCCCCCCCCCCCCCCCC0..
...0CCCCCCCC1111CCCCCCCCCCCC0...
....0CCCCC11111111CCCCCCCCC0....
.....0CC111111111111CCCCCC0.....
......0011111111111111CC00......
........0011111111111100........
..........000000000000..........
................................
................................
................................
................................
