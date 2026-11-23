# ==============================================================================
# 31. PRISM LASER
# ------------------------------------------------------------------------------
# 鏡とプリズムでRGBレーザーを混色・誘導する光学パズル（全12面）
# 256x256 / 1ファイル完結 / 基本API + bg() + スプライト + マウス/キーボード
#
# 【操作方法】
#   マウスクリック / Z(Space) : 鏡・プリズムを回転
#   矢印キー / WASD           : カーソル移動
#   X / Enter                 : レベルリセット（クリア時は次へ）
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2,
  title: "31. PRISM LASER"
)

# 8x8 グリッド (盤面は 16, 32 から 224x192 => 8列 x 7行、1セル 28x28px? いや 8x7 = 28px だと 224x196)
# 盤面: 8列 x 7行, セルサイズ 28px -> x: 16..240, y: 30..226
GRID_W = 8
GRID_H = 7
CELL   = 28
OX     = 16
OY     = 30

# 方向: 0=右, 1=下, 2=左, 3=上
DX = [1, 0, -1, 0]
DY = [0, 1, 0, -1]

# 色ビットマスク: R=1, G=2, B=4
COL_R = 1
COL_G = 2
COL_B = 4
COL_Y = 3
COL_M = 5
COL_C = 6
COL_W = 7

COLOR_NAMES = {
  1 => "RED",
  2 => "GRN",
  4 => "BLU",
  3 => "YLW",
  5 => "MAG",
  6 => "CYN",
  7 => "WHT"
}

# パレット1上の色番号対応
# 8: 純赤, B: 純緑, C: 純青, A: 黄, E: マゼンタ, 6: シアン, 7: 白
MASK_TO_PAL = {
  1 => 8,
  2 => 11,
  4 => 12,
  3 => 10,
  5 => 14,
  6 => 6,
  7 => 7
}

# セル種別
# :empty, :wall, :emitter, :target, :mirror, :splitter
# mirror rot: 0 = '/', 1 = '\'
# splitter rot: 0 = T下(左右から来たら下へも分岐/上下なら反射), 1, 2, 3
# シンプルかつ直感的なスプリッター:
#   rot 0: '/' 型ハーフミラー (透過 + '/' 反射)
#   rot 1: '\' 型ハーフミラー (透過 + '\' 反射)

def make_levels
  [
    # Level 1: 基本の鏡反射
    {
      name: "FIRST REFLECTION",
      items: [
        { x: 0, y: 3, type: :emitter, dir: 0, col: COL_R },
        { x: 5, y: 3, type: :mirror,  rot: 1, locked: false }, # '/' にすると上へ
        { x: 5, y: 1, type: :target,  req: COL_R }
      ]
    },
    # Level 2: 2枚の鏡で障害物を迂回
    {
      name: "CORNER BOUNCE",
      items: [
        { x: 0, y: 1, type: :emitter, dir: 0, col: COL_G },
        { x: 3, y: 0, type: :wall },
        { x: 3, y: 1, type: :wall },
        { x: 3, y: 2, type: :wall },
        { x: 2, y: 1, type: :mirror,  rot: 0 },
        { x: 2, y: 5, type: :mirror,  rot: 0 },
        { x: 6, y: 5, type: :target,  req: COL_G }
      ]
    },
    # Level 3: ハーフプリズムで2分岐
    {
      name: "BEAM SPLITTER",
      items: [
        { x: 0, y: 3, type: :emitter, dir: 0, col: COL_C },
        { x: 3, y: 3, type: :splitter, rot: 1 },
        { x: 7, y: 3, type: :target,  req: COL_C },
        { x: 3, y: 6, type: :target,  req: COL_C }
      ]
    },
    # Level 4: R + G = YELLOW 混色入門
    {
      name: "ADDITIVE YELLOW",
      items: [
        { x: 0, y: 2, type: :emitter, dir: 0, col: COL_R },
        { x: 4, y: 6, type: :emitter, dir: 3, col: COL_G },
        { x: 4, y: 2, type: :splitter, rot: 1 },
        { x: 7, y: 2, type: :target,  req: COL_Y }
      ]
    },
    # Level 5: R + B = MAGENTA & 壁越え
    {
      name: "MAGENTA PRISM",
      items: [
        { x: 0, y: 5, type: :emitter, dir: 0, col: COL_R },
        { x: 7, y: 1, type: :emitter, dir: 2, col: COL_B },
        { x: 2, y: 5, type: :mirror,  rot: 1 },
        { x: 2, y: 1, type: :splitter, rot: 0 },
        { x: 4, y: 1, type: :target,  req: COL_M }, # 右からB、左からR? いや (2,1)でRが右へ、Bは(4,1)を通り抜けないので(4,1)より左へ行くか、targetを(2,0)?
        # 修正: Bを(7,1)から左へ。targetを(5,3)にする
      ]
    },
    # Level 6: 3色分離と混色
    {
      name: "CYAN & YELLOW",
      items: [
        { x: 0, y: 1, type: :emitter, dir: 0, col: COL_R },
        { x: 0, y: 3, type: :emitter, dir: 0, col: COL_G },
        { x: 0, y: 5, type: :emitter, dir: 0, col: COL_B },
        { x: 3, y: 3, type: :splitter, rot: 0 },
        { x: 3, y: 1, type: :splitter, rot: 1 },
        { x: 3, y: 5, type: :splitter, rot: 0 },
        { x: 6, y: 1, type: :target,  req: COL_Y },
        { x: 6, y: 5, type: :target,  req: COL_C }
      ]
    },
    # Level 7: ホワイトレーザー (R+G+B)
    {
      name: "PURE WHITE",
      items: [
        { x: 1, y: 0, type: :emitter, dir: 1, col: COL_R },
        { x: 3, y: 0, type: :emitter, dir: 1, col: COL_G },
        { x: 5, y: 0, type: :emitter, dir: 1, col: COL_B },
        { x: 1, y: 4, type: :mirror,  rot: 0 },
        { x: 3, y: 4, type: :splitter, rot: 0 },
        { x: 5, y: 4, type: :splitter, rot: 0 },
        { x: 7, y: 4, type: :target,  req: COL_W }
      ]
    },
    # Level 8: クロス・ラボ
    {
      name: "CROSS OPTICS",
      items: [
        { x: 0, y: 2, type: :emitter, dir: 0, col: COL_R },
        { x: 4, y: 0, type: :emitter, dir: 1, col: COL_B },
        { x: 2, y: 2, type: :splitter, rot: 0 },
        { x: 4, y: 2, type: :splitter, rot: 1 },
        { x: 2, y: 5, type: :mirror,  rot: 0 },
        { x: 4, y: 5, type: :splitter, rot: 0 },
        { x: 7, y: 5, type: :target,  req: COL_M },
        { x: 7, y: 2, type: :target,  req: COL_R }
      ]
    },
    # Level 9: ジグザグ・プリズム
    {
      name: "ZIGZAG MATRIX",
      items: [
        { x: 0, y: 0, type: :emitter, dir: 0, col: COL_G },
        { x: 0, y: 6, type: :emitter, dir: 0, col: COL_B },
        { x: 3, y: 3, type: :wall },
        { x: 4, y: 3, type: :wall },
        { x: 2, y: 0, type: :mirror,  rot: 0 },
        { x: 2, y: 4, type: :mirror,  rot: 0 },
        { x: 5, y: 4, type: :splitter, rot: 1 },
        { x: 5, y: 6, type: :splitter, rot: 0 },
        { x: 5, y: 1, type: :target,  req: COL_G },
        { x: 7, y: 4, type: :target,  req: COL_C }
      ]
    },
    # Level 10: トリプル・ターゲット
    {
      name: "TRI-SPECTRUM",
      items: [
        { x: 0, y: 3, type: :emitter, dir: 0, col: COL_R },
        { x: 3, y: 0, type: :emitter, dir: 1, col: COL_G },
        { x: 6, y: 6, type: :emitter, dir: 3, col: COL_B },
        { x: 3, y: 3, type: :splitter, rot: 0 },
        { x: 6, y: 3, type: :splitter, rot: 1 },
        { x: 3, y: 6, type: :target,  req: COL_G },
        { x: 7, y: 3, type: :target,  req: COL_W },
        { x: 6, y: 0, type: :target,  req: COL_B }
      ]
    },
    # Level 11: 迷宮の結晶
    {
      name: "CRYSTAL MAZE",
      items: [
        { x: 0, y: 1, type: :emitter, dir: 0, col: COL_R },
        { x: 0, y: 5, type: :emitter, dir: 0, col: COL_G },
        { x: 7, y: 3, type: :emitter, dir: 2, col: COL_B },
        { x: 2, y: 3, type: :wall },
        { x: 5, y: 1, type: :wall },
        { x: 3, y: 1, type: :splitter, rot: 0 },
        { x: 3, y: 5, type: :splitter, rot: 1 },
        { x: 5, y: 5, type: :mirror,  rot: 0 },
        { x: 5, y: 3, type: :splitter, rot: 0 },
        { x: 3, y: 3, type: :splitter, rot: 1 },
        { x: 3, y: 0, type: :target,  req: COL_R },
        { x: 7, y: 5, type: :target,  req: COL_Y },
        { x: 1, y: 3, type: :target,  req: COL_B }
      ]
    },
    # Level 12: グランド・フィナーレ
    {
      name: "PRISM FINALE",
      items: [
        { x: 0, y: 1, type: :emitter, dir: 0, col: COL_R },
        { x: 0, y: 3, type: :emitter, dir: 0, col: COL_G },
        { x: 0, y: 5, type: :emitter, dir: 0, col: COL_B },
        { x: 2, y: 1, type: :splitter, rot: 0 },
        { x: 2, y: 3, type: :splitter, rot: 1 },
        { x: 2, y: 5, type: :splitter, rot: 0 },
        { x: 4, y: 1, type: :splitter, rot: 1 },
        { x: 4, y: 3, type: :splitter, rot: 0 },
        { x: 4, y: 5, type: :splitter, rot: 1 },
        { x: 7, y: 1, type: :target,  req: COL_Y },
        { x: 7, y: 3, type: :target,  req: COL_W },
        { x: 7, y: 5, type: :target,  req: COL_C }
      ]
    }
  ]
end

# Level 5 の配置を確実に解けるよう補正:
# R(0,5)->右 -> (2,5)鏡'/'(rot=0)で上へ -> (2,1)スプリッタ'\'(rot=1)または'/'(rot=0)で右へ
# B(7,1)->左 -> (2,1)を直進? いいえ、(4,1)にtargetがあるとBが右から当たるがRは(2,1)から右へ行くので(4,1)にRとB両方が当たる！
# あ、target はレーザーを遮らない（透過する）仕様にすれば (4,1) に左からR、右からBが同時に当たって MAGENTA になる！
# しかもそれならLevel 5は超わかりやすい！

class PrismLaserGame
  def initialize
    @levels = make_levels
    @state = :title
    @level_idx = 0
    @frame = 0
    @cur_x = 3
    @cur_y = 3
    @prev_mouse = false
    @sparks = []
    @clear_timer = 0
    @cleared_levels = Array.new(@levels.size, false)
    load_level(0)
  end

  def load_level(idx)
    @level_idx = idx % @levels.size
    lvl = @levels[@level_idx]
    @grid = Array.new(GRID_H) { Array.new(GRID_W, nil) }
    @targets = []
    @emitters = []
    lvl[:items].each do |it|
      cell = {
        x: it[:x],
        y: it[:y],
        type: it[:type],
        dir: it[:dir] || 0,
        col: it[:col] || 0,
        rot: it[:rot] || 0,
        req: it[:req] || 0,
        hit_mask: 0
      }
      @grid[it[:y]][it[:x]] = cell
      @targets << cell if cell[:type] == :target
      @emitters << cell if cell[:type] == :emitter
    end
    @beams = []
    @clear_timer = 0
    @just_cleared = false
    recalc_lasers
  end

  def recalc_lasers
    @beams = []
    @targets.each { |t| t[:hit_mask] = 0 }

    # 3原色ごとに独立してビームをトレース（無限ループ防止のため (x, y, dir) 訪問管理）
    [COL_R, COL_G, COL_B].each do |c_bit|
      queue = []
      visited = {}

      @emitters.each do |em|
        if (em[:col] & c_bit) != 0
          queue << [em[:x], em[:y], em[:dir]]
        end
      end

      while queue.size > 0
        qitem = queue.shift
        cx = qitem[0]
        cy = qitem[1]
        dir = qitem[2]
        key = (cy * 32 + cx) * 4 + dir
        next if visited.has_key?(key)
        visited[key] = true

        # 直進できる限り1本の長いビームにまとめる
        sx = cx
        sy = cy
        loop do
          nx = cx + DX[dir]
          ny = cy + DY[dir]
          if nx < 0 || nx >= GRID_W || ny < 0 || ny >= GRID_H
            @beams << { x0: sx, y0: sy, x1: cx + DX[dir] * 0.6, y1: cy + DY[dir] * 0.6, col: c_bit }
            break
          end

          cell = @grid[ny][nx]
          if cell.nil?
            cx = nx
            cy = ny
            nkey = (cy * 32 + cx) * 4 + dir
            if visited.has_key?(nkey)
              @beams << { x0: sx, y0: sy, x1: cx, y1: cy, col: c_bit }
              break
            end
            visited[nkey] = true
            next
          end

          @beams << { x0: sx, y0: sy, x1: nx, y1: ny, col: c_bit }
          case cell[:type]
          when :wall, :emitter
            break
          when :target
            cell[:hit_mask] |= c_bit
            queue << [nx, ny, dir]
            break
          when :mirror
            ndir = cell[:rot] == 0 ? (dir ^ 3) : (dir ^ 1)
            queue << [nx, ny, ndir]
            break
          when :splitter
            queue << [nx, ny, dir]
            ndir = cell[:rot] == 0 ? (dir ^ 3) : (dir ^ 1)
            queue << [nx, ny, ndir]
            break
          end
        end
      end
    end

    # クリア判定
    all_ok = @targets.size > 0
    @targets.each do |t|
      if t[:hit_mask] != t[:req]
        all_ok = false
        break
      end
    end
    if all_ok && !@just_cleared
      @just_cleared = true
      @clear_timer = 1
      @cleared_levels[@level_idx] = true
      @targets.each do |t|
        px = OX + t[:x] * CELL + CELL * 0.5
        py = OY + t[:y] * CELL + CELL * 0.5
        12.times do
          ang = rand * Math::PI * 2.0
          spd = 1.0 + rand * 2.5
          @sparks << {
            x: px, y: py,
            vx: cos(ang) * spd, vy: sin(ang) * spd,
            life: 25 + rand(15), max_life: 40,
            col: MASK_TO_PAL[t[:req]] || 7
          }
        end
      end
    end
  end

  def rotate_at(gx, gy)
    return if @just_cleared
    return if gx < 0 || gx >= GRID_W || gy < 0 || gy >= GRID_H
    cell = @grid[gy][gx]
    return if cell.nil?
    if cell[:type] == :mirror || cell[:type] == :splitter
      cell[:rot] = (cell[:rot] + 1) % 2
      px = OX + gx * CELL + CELL * 0.5
      py = OY + gy * CELL + CELL * 0.5
      6.times do
        ang = rand * Math::PI * 2.0
        @sparks << {
          x: px, y: py,
          vx: cos(ang) * 1.5, vy: sin(ang) * 1.5,
          life: 14, max_life: 14, col: 7
        }
      end
      recalc_lasers
    end
  end

  def update
    @frame += 1

    # パーティクル更新
    @sparks.each do |s|
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:vx] *= 0.94
      s[:vy] *= 0.94
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }

    m_click = btnp(:mouse_l)

    if @state == :title
      if @frame > 5 && (btnp(4) || btnp(5) || m_click)
        @state = :play
        load_level(0)
      end
      return
    end

    if @state == :all_clear
      if btnp(4) || btnp(5) || m_click
        @state = :play
        load_level(0)
      end
      return
    end

    if @just_cleared
      @clear_timer += 1
      if btnp(4) || btnp(5) || m_click || @clear_timer > 95
        if @level_idx == @levels.size - 1
          @state = :all_clear
        else
          load_level(@level_idx + 1)
        end
      end
      return
    end

    # カーソル移動
    @cur_x = (@cur_x - 1) % GRID_W if btnp(0)
    @cur_x = (@cur_x + 1) % GRID_W if btnp(1)
    @cur_y = (@cur_y - 1) % GRID_H if btnp(2)
    @cur_y = (@cur_y + 1) % GRID_H if btnp(3)

    if btnp(4)
      rotate_at(@cur_x, @cur_y)
    end
    if btnp(5)
      load_level(@level_idx)
    end

    if m_click
      mx = mouse_x
      my = mouse_y
      # ヘッダーのレベル切替ボタン
      if my < 24
        if mx < 56
          load_level(@level_idx - 1)
        elsif mx > 200
          load_level(@level_idx + 1)
        end
      elsif mx >= OX && mx < OX + GRID_W * CELL && my >= OY && my < OY + GRID_H * CELL
        gx = ((mx - OX) / CELL).to_i
        gy = ((my - OY) / CELL).to_i
        @cur_x = gx
        @cur_y = gy
        rotate_at(gx, gy)
      end
    end
  end

  def draw
    cls(0)
    pal_bank(1)
    bg(:space, dim: 0.72, scroll_x: @frame * 0.12, loop_x: true)

    if @state == :title
      draw_title
      blend(:normal)
      pal_bank(0)
      return
    end

    if @state == :all_clear
      draw_all_clear
      blend(:normal)
      pal_bank(0)
      return
    end

    draw_board
    draw_beams
    draw_cells
    draw_sparks
    draw_hud

    blend(:normal)
    pal_bank(0)
  end

  def draw_title
    # タイトル画面でも背景に美しいRGBプリズムレーザーをデモ描画
    blend(:add)
    cx = 128
    cy = 104
    t = @frame * 0.03
    line(16, cy - 30, cx, cy, 8, 6, 0.45)
    line(16, cy - 30, cx, cy, 8, 2, 0.95)
    line(16, cy + 30, cx, cy, 12, 6, 0.45)
    line(16, cy + 30, cx, cy, 12, 2, 0.95)

    # プリズムから虹色3本出力
    [
      [cy - 42 + sin(t) * 6, 8],
      [cy + sin(t + 1.0) * 4, 11],
      [cy + 42 - sin(t) * 6, 12]
    ].each do |pair|
      ty = pair[0]
      c = pair[1]
      line(cx, cy, 240, ty, c, 7, 0.4)
      line(cx, cy, 240, ty, c, 2, 0.95)
    end
    blend(:normal)

    # 半透明ガラスプリズム
    trifill(cx - 22, cy + 20, cx + 22, cy + 20, cx, cy - 22, 6, 0.45)
    tri(cx - 22, cy + 20, cx + 22, cy + 20, cx, cy - 22, 7, 2, 0.9)

    print_text("PRISM LASER", 95, 34, 7)
    print_text("RGB ADDITIVE OPTICS PUZZLE", 50, 52, 6)
    rectfill(44, 174, 168, 42, 0, 0.72)
    rect(44, 174, 168, 42, 6, 1, 0.8)
    print_text("CLICK / Z : ROTATE MIRROR", 54, 183, 7)
    print_text("PRESS Z OR CLICK TO START", 54, 199, 10)
  end

  def draw_all_clear
    blend(:add)
    8.times do |i|
      ang = @frame * 0.02 + i * Math::PI / 4.0
      c = [8, 11, 12, 10, 14, 6, 7, 8][i]
      line(128, 118, 128 + cos(ang) * 120, 118 + sin(ang) * 120, c, width: 5, alpha: 0.45)
    end
    blend(:normal)
    rectfill(32, 74, 192, 92, 0, alpha: 0.82)
    rect(32, 74, 192, 92, 7)
    print_text("ALL 12 LEVELS", 72, 90, 10, size: 16)
    print_text("CLEARED!", 92, 110, 7, size: 16)
    print_text("PRESS Z OR CLICK TO REPLAY", 50, 140, 6)
  end

  def draw_board
    rectfill(OX - 2, OY - 2, GRID_W * CELL + 4, GRID_H * CELL + 4, 0, alpha: 0.55)
    rect(OX - 2, OY - 2, GRID_W * CELL + 4, GRID_H * CELL + 4, 1, alpha: 0.9)
    (0..GRID_W).each do |x|
      px = OX + x * CELL
      line(px, OY, px, OY + GRID_H * CELL, 1, alpha: 0.45)
    end
    (0..GRID_H).each do |y|
      py = OY + y * CELL
      line(OX, py, OX + GRID_W * CELL, py, 1, alpha: 0.45)
    end
  end

  def draw_beams
    blend(:add)
    pulse = 0.85 + sin(@frame * 0.18) * 0.15
    @beams.each do |b|
      x0 = OX + b[:x0] * CELL + CELL * 0.5
      y0 = OY + b[:y0] * CELL + CELL * 0.5
      x1 = OX + b[:x1] * CELL + CELL * 0.5
      y1 = OY + b[:y1] * CELL + CELL * 0.5
      pal_c = MASK_TO_PAL[b[:col]] || 7
      line(x0, y0, x1, y1, pal_c, 6, 0.42 * pulse)
      line(x0, y0, x1, y1, pal_c, 2, 0.95)
    end
    blend(:normal)
  end

  def draw_cells
    (0...GRID_H).each do |gy|
      (0...GRID_W).each do |gx|
        cell = @grid[gy][gx]
        next if cell.nil?
        cx = OX + gx * CELL + CELL * 0.5
        cy = OY + gy * CELL + CELL * 0.5

        case cell[:type]
        when :wall
          rectfill(OX + gx * CELL + 3, OY + gy * CELL + 3, CELL - 6, CELL - 6, 5)
          rect(OX + gx * CELL + 3, OY + gy * CELL + 3, CELL - 6, CELL - 6, 6, alpha: 0.6)
        when :emitter
          pal_c = MASK_TO_PAL[cell[:col]] || 7
          rectfill(cx - 8, cy - 8, 16, 16, 1)
          rect(cx - 8, cy - 8, 16, 16, pal_c, 2)
          # 発射方向のノズル
          nx = cx + DX[cell[:dir]] * 10
          ny = cy + DY[cell[:dir]] * 10
          line(cx, cy, nx, ny, pal_c, 4)
          circfill(cx, cy, 4, pal_c)
        when :target
          req_c = MASK_TO_PAL[cell[:req]] || 7
          matched = (cell[:hit_mask] == cell[:req])
          if matched
            blend(:add)
            circfill(cx, cy, 12, req_c, 0.45)
            blend(:normal)
          end
          # ダイヤモンド多角形ターゲット
          pts = [[cx, cy - 10], [cx + 10, cy], [cx, cy + 10], [cx - 10, cy]]
          polygonfill(pts, req_c, matched ? 0.95 : 0.35)
          poly(pts, matched ? 7 : req_c, 2)
          # 目標色ラベル (1文字)
          lbl = (COLOR_NAMES[cell[:req]] || "?")[0, 1]
          print_text(lbl, cx - 2, cy - 3, matched ? 0 : 7)
        when :mirror
          # 全反射ミラー (不透明シルバー板)
          if cell[:rot] == 0
            line(cx - 9, cy + 9, cx + 9, cy - 9, 6, 4)
            line(cx - 9, cy + 9, cx + 9, cy - 9, 7, 1)
          else
            line(cx - 9, cy - 9, cx + 9, cy + 9, 6, 4)
            line(cx - 9, cy - 9, cx + 9, cy + 9, 7, 1)
          end
        when :splitter
          # 半透明ガラスプリズム (ハーフミラー)
          if cell[:rot] == 0
            trifill(cx - 9, cy + 9, cx + 9, cy - 9, cx + 9, cy + 9, 6, 0.45)
            line(cx - 9, cy + 9, cx + 9, cy - 9, 7, 2, 0.9)
          else
            trifill(cx - 9, cy - 9, cx + 9, cy + 9, cx - 9, cy + 9, 6, 0.45)
            line(cx - 9, cy - 9, cx + 9, cy + 9, 7, 2, 0.9)
          end
        end
      end
    end

    # 選択カーソル
    sx = OX + @cur_x * CELL
    sy = OY + @cur_y * CELL
    rect(sx + 1, sy + 1, CELL - 2, CELL - 2, 10, width: 2, alpha: 0.85)
  end

  def draw_sparks
    blend(:add)
    @sparks.each do |s|
      a = s[:life].to_f / s[:max_life]
      circfill(s[:x], s[:y], 2.2, s[:col], alpha: a)
    end
    blend(:normal)
  end

  def draw_hud
    rectfill(0, 0, 256, 26, 0, alpha: 0.85)
    line(0, 26, 256, 26, 1)
    lvl = @levels[@level_idx]
    print_text("< PREV", 6, 8, 6)
    title_str = format("LV.%02d %s", @level_idx + 1, lvl[:name])
    print_text(title_str, 58, 8, 7)
    print_text("NEXT >", 214, 8, 6)

    # 下部ステータス
    done_cnt = @targets.count { |t| t[:hit_mask] == t[:req] }
    print_text(format("TARGETS: %d/%d", done_cnt, @targets.size), 16, 236, done_cnt == @targets.size ? 11 : 6)
    print_text("Z/CLICK:ROT  X:RESET", 124, 236, 5)

    if @just_cleared
      rectfill(42, 104, 172, 42, 0, alpha: 0.85)
      rect(42, 104, 172, 42, 10, width: 2)
      print_text("PRISM LINKED!", 76, 114, 10, size: 16)
      print_text("CLICK OR Z FOR NEXT", 68, 134, 7)
    end
  end
end

run PrismLaserGame.new

__END__
@PALETTE 1
1: #1C2340
5: #505870
6: #20FFFF
7: #FFFFFF
8: #FF2020
10: #FFFF20
11: #20FF20
12: #2050FF
14: #FF40FF
