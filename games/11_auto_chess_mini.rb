# ==============================================================================
# 11. AUTO CHESS MINI
# ------------------------------------------------------------------------------
# 4×4盤面で3体合体進化＆シナジーを組むミニ・オートバトラー
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   マウスクリック / 矢印+Z : ショップ購入・盤面配置/入替
#   SPACE / X / FIGHTボタン : バトル開始!
#   R / REROLLボタン        : ショップ入替 (2G)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "11. AUTO CHESS MINI"
)

UNIT_DEFS = [
  { id: :knight, name: "KNIGHT", cost: 2, hp: 48, atk: 7,  range: 1.5, cd: 32, syn: "GUARD",  col: 12 },
  { id: :archer, name: "ARCHER", cost: 2, hp: 26, atk: 8,  range: 4.5, cd: 28, syn: "RANGE",  col: 11 },
  { id: :mage,   name: "MAGE",   cost: 3, hp: 24, atk: 11, range: 3.8, cd: 36, syn: "MAGIC",  col: 14 },
  { id: :ninja,  name: "NINJA",  cost: 3, hp: 30, atk: 10, range: 1.5, cd: 20, syn: "SHADOW", col: 10 }
]

BOARD_X = 64
BOARD_Y = 34
CELL_S = 32

$chess_best_round ||= 0

def find_def(id)
  UNIT_DEFS.each { |d| return d if d[:id] == id }
  UNIT_DEFS[0]
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
    bg(:forest, dim: 0.52, tint: [140, 175, 220])

    spr(:knight, 72, 168)
    spr(:archer, 104, 168)
    spr(:mage, 136, 168)
    spr(:ninja, 168, 168)

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 10)
    print_text("AUTO CHESS MINI", 83, 32, 10)
    print_text("MERGE 3 UNITS TO EVOLVE!", 56, 46, 12)

    rectfill(24, 78, 208, 66, 0)
    rect(24, 78, 208, 66, 5)
    print_text("CLICK SHOP TO BUY & PLACE", 44, 88, 7)
    print_text("3x SAME UNIT = AUTO STAR UP!", 44, 102, 10)
    print_text("2x SAME CLASS = SYNERGY BUFF!", 44, 116, 11)
    if $chess_best_round > 0
      print_text("BEST ROUND: #{$chess_best_round}", 78, 130, 12)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO START", 53, 214, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @round = 1
    @hp = 5
    @gold = 6
    @phase = :prep
    @roster = [] # 配置済みプレイヤーユニット { id, star, gx, gy }
    @battle_units = []
    @projs = []
    @popups = []
    @particles = []
    @shop = []
    @selected_idx = nil
    @cur_gx = 0
    @cur_gy = 2
    @result_timer = 0
    @dead = false
    @dead_timer = 0

    reroll_shop
    # 初期ユニット1体
    @roster << { id: :knight, star: 1, gx: 1, gy: 2 }
  end

  def reroll_shop
    @shop = []
    i = 0
    while i < 3
      d = UNIT_DEFS[rand(UNIT_DEFS.size)]
      @shop << d[:id]
      i += 1
    end
  end

  def check_merges
    merged = true
    while merged
      merged = false
      UNIT_DEFS.each do |d|
        [1, 2].each do |st|
          matches = []
          @roster.each_with_index do |u, idx|
            matches << idx if u[:id] == d[:id] && u[:star] == st
          end
          if matches.size >= 3
            keep = @roster[matches[0]]
            keep[:star] += 1
            # 後ろから2つ削除
            @roster.delete_at(matches[2])
            @roster.delete_at(matches[1])
            @popups << { x: BOARD_X + keep[:gx] * CELL_S + 16, y: BOARD_Y + keep[:gy] * CELL_S, text: "STAR #{keep[:star]}!", col: 10, life: 40 }
            merged = true
            break
          end
        end
        break if merged
      end
    end
  end

  def buy_shop(slot)
    return if slot < 0 || slot >= @shop.size
    id = @shop[slot]
    return if id.nil?
    d = find_def(id)
    return if @gold < d[:cost]

    # 空きマス探索 (gy: 2..3, gx: 0..3)
    placed = nil
    [2, 3].each do |gy|
      [0, 1, 2, 3].each do |gx|
        occ = @roster.any? { |u| u[:gx] == gx && u[:gy] == gy }
        if !occ && placed.nil?
          placed = [gx, gy]
        end
      end
    end
    return if placed.nil?

    @gold -= d[:cost]
    @shop[slot] = nil
    @roster << { id: id, star: 1, gx: placed[0], gy: placed[1] }
    check_merges
  end

  def count_synergies
    counts = {}
    seen = {}
    @roster.each do |u|
      key = "#{u[:id]}_#{u[:star]}"
      unless seen.has_key?(key)
        seen[key] = true
        counts[u[:id]] = (counts[u[:id]] || 0) + 1
      end
    end
    counts
  end

  def start_battle
    return if @roster.empty?
    @phase = :battle
    @selected_idx = nil
    @battle_units = []
    @projs = []
    syn = count_synergies

    @roster.each do |u|
      d = find_def(u[:id])
      mult = u[:star] == 3 ? 3.2 : (u[:star] == 2 ? 1.85 : 1.0)
      hp = (d[:hp] * mult).to_i
      atk = (d[:atk] * mult).to_i
      hp += 16 if (syn[:knight] || 0) >= 2 && u[:id] == :knight
      atk += 4 if (syn[:archer] || 0) >= 2 && u[:id] == :archer
      @battle_units << {
        team: :player, id: u[:id], star: u[:star],
        x: (BOARD_X + u[:gx] * CELL_S + 16).to_f,
        y: (BOARD_Y + u[:gy] * CELL_S + 16).to_f,
        hp: hp, max_hp: hp, atk: atk, range: d[:range] * CELL_S,
        cd_max: d[:cd], cd: rand(12), col: d[:col]
      }
    end

    # 敵ウェーブ生成
    cnt = 1 + @round
    cnt = 6 if cnt > 6
    i = 0
    while i < cnt
      d = UNIT_DEFS[rand(UNIT_DEFS.size)]
      gx = i % 4
      gy = i / 4
      star = @round >= 5 && i == 0 ? 2 : 1
      mult = star == 2 ? 1.7 : 1.0
      hp = ((d[:hp] + @round * 3) * mult).to_i
      atk = ((d[:atk] + @round / 2) * mult).to_i
      @battle_units << {
        team: :enemy, id: d[:id], star: star,
        x: (BOARD_X + gx * CELL_S + 16).to_f,
        y: (BOARD_Y + gy * CELL_S + 16).to_f,
        hp: hp, max_hp: hp, atk: atk, range: d[:range] * CELL_S,
        cd_max: d[:cd], cd: rand(15), col: 8
      }
      i += 1
    end
  end

  def update_battle
    p_alive = 0
    e_alive = 0
    @battle_units.each do |u|
      next if u[:hp] <= 0
      if u[:team] == :player
        p_alive += 1
      else
        e_alive += 1
      end

      # 最も近い敵を探す
      target = nil
      best_d = 999999.0
      @battle_units.each do |other|
        next if other[:hp] <= 0 || other[:team] == u[:team]
        dx = other[:x] - u[:x]
        dy = other[:y] - u[:y]
        d = sqrt(dx * dx + dy * dy)
        if d < best_d
          best_d = d
          target = other
        end
      end
      next if target.nil?

      if best_d > u[:range]
        dx = target[:x] - u[:x]
        dy = target[:y] - u[:y]
        u[:x] += dx / best_d * 0.85
        u[:y] += dy / best_d * 0.85
      else
        u[:cd] -= 1
        if u[:cd] <= 0
          u[:cd] = u[:cd_max]
          if u[:range] > 60.0
            dx = target[:x] - u[:x]
            dy = target[:y] - u[:y]
            @projs << {
              x: u[:x], y: u[:y], vx: dx / best_d * 3.5, vy: dy / best_d * 3.5,
              team: u[:team], dmg: u[:atk], col: u[:col]
            }
          else
            target[:hp] -= u[:atk]
            @popups << { x: target[:x], y: target[:y] - 8.0, text: "-#{u[:atk]}", col: 7, life: 18 }
            @particles << { x: target[:x], y: target[:y], vx: (rand() - 0.5) * 2.0, vy: -1.0, col: 10, life: 10 }
          end
        end
      end
    end

    @projs.each do |pr|
      pr[:x] += pr[:vx]
      pr[:y] += pr[:vy]
      @battle_units.each do |u|
        next if u[:hp] <= 0 || u[:team] == pr[:team]
        dx = pr[:x] - u[:x]
        dy = pr[:y] - u[:y]
        if dx * dx + dy * dy < 10.0 * 10.0
          u[:hp] -= pr[:dmg]
          pr[:x] = -999.0
          @popups << { x: u[:x], y: u[:y] - 8.0, text: "-#{pr[:dmg]}", col: 7, life: 18 }
          break
        end
      end
    end
    @projs.reject! { |pr| pr[:x] < 0.0 || pr[:x] > 256.0 || pr[:y] < 0.0 || pr[:y] > 256.0 }

    if p_alive == 0 || e_alive == 0
      @phase = :result
      @result_timer = 50
      if e_alive == 0
        @gold += 4 + (@round / 2).to_i
        @round += 1
        $chess_best_round = @round if @round > $chess_best_round
        @popups << { x: 128.0, y: 96.0, text: "VICTORY! +GOLD", col: 10, life: 45 }
      else
        @hp -= 1
        @gold += 3
        @popups << { x: 128.0, y: 96.0, text: "DEFEAT! -1 HP", col: 8, life: 45 }
        if @hp <= 0
          @dead = true
          @dead_timer = 0
        end
      end
    end
  end

  def find_unit_at(gx, gy)
    @roster.each_with_index do |u, idx|
      return idx if u[:gx] == gx && u[:gy] == gy
    end
    nil
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

    @popups.each do |pp|
      pp[:y] -= 0.5
      pp[:life] -= 1
    end
    @popups.reject! { |pp| pp[:life] <= 0 }
    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }

    if @phase == :prep
      # キーボード操作
      @cur_gx = (@cur_gx - 1) % 4 if btnp(:left)
      @cur_gx = (@cur_gx + 1) % 4 if btnp(:right)
      @cur_gy = (@cur_gy == 2 ? 3 : 2) if btnp(:up) || btnp(:down)

      if btnp(2)
        start_battle
        return
      end

      if btnp(1)
        # カーソル位置にユニットがいれば選択/移動、なければショップ購入
        idx = find_unit_at(@cur_gx, @cur_gy)
        if @selected_idx
          if idx
            u1 = @roster[@selected_idx]
            u2 = @roster[idx]
            tx = u1[:gx]; ty = u1[:gy]
            u1[:gx] = u2[:gx]; u1[:gy] = u2[:gy]
            u2[:gx] = tx; u2[:gy] = ty
          else
            @roster[@selected_idx][:gx] = @cur_gx
            @roster[@selected_idx][:gy] = @cur_gy
          end
          @selected_idx = nil
        elsif idx
          @selected_idx = idx
        else
          # 購入できるカードを買う
          bought = false
          [0, 1, 2].each do |si|
            if !bought && @shop[si]
              buy_shop(si)
              bought = true
            end
          end
        end
      end

      if btnp(:mouse_l)
        mx = mouse_x
        my = mouse_y
        # 盤面クリック
        if mx >= BOARD_X && mx < BOARD_X + 4 * CELL_S && my >= BOARD_Y + 2 * CELL_S && my < BOARD_Y + 4 * CELL_S
          gx = (mx - BOARD_X) / CELL_S
          gy = (my - BOARD_Y) / CELL_S
          idx = find_unit_at(gx, gy)
          if @selected_idx
            if idx
              u1 = @roster[@selected_idx]
              u2 = @roster[idx]
              tx = u1[:gx]; ty = u1[:gy]
              u1[:gx] = u2[:gx]; u1[:gy] = u2[:gy]
              u2[:gx] = tx; u2[:gy] = ty
            else
              @roster[@selected_idx][:gx] = gx
              @roster[@selected_idx][:gy] = gy
            end
            @selected_idx = nil
          elsif idx
            @selected_idx = idx
          end
        end

        # ショップカードクリック
        if my >= 174 && my <= 216
          i = 0
          while i < 3
            cx = 16 + i * 56
            if mx >= cx && mx < cx + 52
              buy_shop(i)
            end
            i += 1
          end
          # REROLL
          if mx >= 188 && mx <= 246 && my >= 174 && my <= 193 && @gold >= 2
            @gold -= 2
            reroll_shop
          end
          # FIGHT
          if mx >= 188 && mx <= 246 && my >= 197 && my <= 216
            start_battle
          end
        end
      end
    elsif @phase == :battle
      update_battle
    elsif @phase == :result
      @result_timer -= 1
      if @result_timer <= 0
        @phase = :prep
        reroll_shop
      end
    end
  end

  def draw
    cls(0)
    bg(:forest, dim: 0.58, tint: [130, 165, 210])

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("RND:#{@round}", 6, 6, 12)
    print_text("GOLD:#{@gold}G", 68, 6, 10)
    print_text("UNITS:#{@roster.size}/8", 132, 6, 7)
    i = 0
    while i < 5
      circfill(210 + i * 9, 10, 3, i < @hp ? 8 : 5)
      i += 1
    end

    # 4x4 盤面
    gy = 0
    while gy < 4
      gx = 0
      while gx < 4
        cx = BOARD_X + gx * CELL_S
        cy = BOARD_Y + gy * CELL_S
        bg_col = ((gx + gy) % 2 == 0) ? 1 : 0
        rectfill(cx, cy, CELL_S, CELL_S, bg_col)
        rect(cx, cy, CELL_S, CELL_S, gy < 2 ? 2 : 5)
        gx += 1
      end
      gy += 1
    end

    if @phase == :prep
      # 選択カーソル
      rect(BOARD_X + @cur_gx * CELL_S + 1, BOARD_Y + @cur_gy * CELL_S + 1, CELL_S - 2, CELL_S - 2, 12)
      @roster.each_with_index do |u, idx|
        cx = BOARD_X + u[:gx] * CELL_S + 8
        cy = BOARD_Y + u[:gy] * CELL_S + 8
        if idx == @selected_idx
          rect(cx - 4, cy - 4, 24, 24, 10)
        end
        spr(u[:id], cx, cy)
        print_text("*#{u[:star]}", cx + 2, cy - 6, u[:star] > 1 ? 10 : 7)
      end
    else
      @battle_units.each do |u|
        next if u[:hp] <= 0
        ux = u[:x].to_i - 8
        uy = u[:y].to_i - 8
        spr(u[:id], ux, uy, u[:team] == :enemy)
        bw = (u[:hp] * 16 / u[:max_hp]).to_i
        bw = 1 if bw < 1
        rectfill(ux, uy - 4, 16, 2, 0)
        rectfill(ux, uy - 4, bw, 2, u[:team] == :player ? 11 : 8)
      end
      @projs.each do |pr|
        circfill(pr[:x].to_i, pr[:y].to_i, 2, pr[:col])
      end
    end

    @particles.each { |p| rectfill(p[:x].to_i, p[:y].to_i, 2, 2, p[:col]) }
    @popups.each { |pp| print_text(pp[:text], pp[:x].to_i - pp[:text].length * 3, pp[:y].to_i, pp[:col]) }

    # ショップバー
    rectfill(0, 170, 256, 86, 0)
    line(0, 170, 256, 170, 5)
    i = 0
    while i < 3
      cx = 16 + i * 56
      rectfill(cx, 176, 52, 42, 1)
      rect(cx, 176, 52, 42, 5)
      if @shop[i]
        d = find_def(@shop[i])
        spr(d[:id], cx + 18, 180)
        print_text(d[:name], cx + 6, 200, d[:col])
        print_text("#{d[:cost]}G", cx + 20, 209, 10)
      else
        print_text("SOLD", cx + 14, 194, 5)
      end
      i += 1
    end

    # REROLL / FIGHT ボタン
    rectfill(188, 176, 58, 18, @gold >= 2 ? 1 : 0)
    rect(188, 176, 58, 18, 12)
    print_text("ROLL 2G", 196, 181, 12)

    rectfill(188, 199, 58, 19, 3)
    rect(188, 199, 58, 19, 11)
    print_text("FIGHT![X]", 191, 205, 10)

    print_text("CLICK UNIT->CELL TO MOVE | 3x MERGE!", 20, 232, 6)

    if @dead
      rectfill(34, 84, 188, 84, 0)
      rect(34, 84, 188, 84, 8)
      print_text("ARMY DEFEATED!", 86, 96, 8)
      print_text("ROUND : #{@round}", 78, 114, 12)
      print_text("BEST  : #{$chess_best_round}", 78, 128, 10)
      if (@dead_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 148, 10)
      end
    end
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #090A14
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

@SPRITE :knight 16x16 pal:1
................
.....000000.....
....06666660....
...0677777760...
...0600660060...
....06666660....
...0CCCCCCCC0...
..060CCCCCC060..
..060CCAA0C060..
...00CCCCCC00...
....01100110....
....01100110....
....000..000....
................
................
................

@SPRITE :archer 16x16 pal:1
................
.....000000.....
....0BBBBBB0....
...0B77FF77B0...
...0B70FF07B0...
....00FFFF00....
...0333BB3330...
..04033BB33040..
..040333333040..
...0033003300...
....04400440....
....000..000....
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
..0220EEEE0220..
...0022AA2200...
....02200220....
....000..000....
................
................
................
................

@SPRITE :ninja 16x16 pal:1
................
.....000000.....
....01111110....
...011F00F110...
...0111111110...
....00888800....
...0111111110...
..067011AA0110..
......0110......
.....0110110....
....0110.0110...
....000...000...
................
................
................
................
