# ==============================================================================
# 37. SLINGSHOT FORTRESS
# ------------------------------------------------------------------------------
# 3種砲弾で物理城砦を崩落させるワイド画面カタパルト破壊パズル（全8面）
# 480x270 / 1ファイル完結 / 基本API + bg() + スプライト + マウス/キーボード
#
# 【操作方法】
#   マウスドラッグ / 矢印キー : 発射角度・パワー調整
#   リリース / Z (Space)      : 発射（飛行中にZ/クリックで特殊能力発動！）
#   X                 : レベルリセット
# ==============================================================================

config(
  width: 480,
  height: 270,
  scale: 2,
  title: "37. SLINGSHOT FORTRESS"
)

SW = 480
SH = 270
GROUND_Y = 242.0
SLING_X = 76.0
SLING_Y = 204.0
GRAV = 0.16

def make_fort_levels
  [
    # Level 1: 木の門
    {
      name: "WOODEN GATE",
      ammo: [:iron, :iron, :bomb],
      blocks: [
        [320, 224, 14, 36, :wood], [368, 224, 14, 36, :wood],
        [344, 200, 66, 12, :wood], [344, 176, 14, 36, :glass]
      ],
      goblins: [[344, 232], [344, 186]]
    },
    # Level 2: ツインタワー
    {
      name: "TWIN TOWERS",
      ammo: [:split, :iron, :bomb],
      blocks: [
        [296, 222, 14, 40, :wood], [332, 222, 14, 40, :wood], [314, 196, 52, 12, :wood],
        [384, 222, 14, 40, :wood], [420, 222, 14, 40, :wood], [402, 196, 52, 12, :wood],
        [314, 178, 24, 24, :glass], [402, 178, 24, 24, :glass]
      ],
      goblins: [[314, 232], [402, 232], [358, 232]]
    },
    # Level 3: TNT火薬庫
    {
      name: "POWDER KEG",
      ammo: [:iron, :split, :bomb],
      blocks: [
        [300, 222, 14, 40, :stone], [372, 222, 14, 40, :stone],
        [336, 196, 88, 12, :wood],
        [336, 228, 22, 22, :tnt],
        [316, 174, 14, 32, :wood], [356, 174, 14, 32, :wood],
        [336, 152, 56, 12, :stone]
      ],
      goblins: [[336, 180], [412, 232], [336, 138]]
    },
    # Level 4: ガラスの温室
    {
      name: "CRYSTAL DOME",
      ammo: [:split, :split, :iron],
      blocks: [
        [286, 222, 12, 40, :glass], [334, 222, 12, 40, :glass], [382, 222, 12, 40, :glass],
        [310, 196, 58, 10, :glass], [358, 196, 58, 10, :glass],
        [310, 174, 12, 34, :glass], [358, 174, 12, 34, :glass],
        [334, 152, 62, 10, :wood]
      ],
      goblins: [[310, 232], [358, 232], [334, 182]]
    },
    # Level 5: 石造りの要塞
    {
      name: "STONE BASTION",
      ammo: [:bomb, :iron, :bomb, :split],
      blocks: [
        [276, 222, 16, 40, :stone], [332, 222, 16, 40, :stone], [388, 222, 16, 40, :stone],
        [304, 196, 72, 12, :stone], [360, 196, 72, 12, :stone],
        [304, 172, 14, 36, :wood], [360, 172, 14, 36, :wood],
        [332, 148, 72, 12, :wood], [332, 228, 20, 20, :tnt]
      ],
      goblins: [[304, 232], [360, 232], [332, 180], [332, 134]]
    },
    # Level 6: 3段ピラミッド
    {
      name: "HIGH PYRAMID",
      ammo: [:split, :bomb, :iron, :bomb],
      blocks: [
        [288, 224, 14, 36, :wood], [336, 224, 14, 36, :wood], [384, 224, 14, 36, :wood], [432, 224, 14, 36, :wood],
        [312, 200, 62, 12, :wood], [408, 200, 62, 12, :wood],
        [360, 176, 14, 36, :tnt],
        [324, 176, 14, 36, :glass], [396, 176, 14, 36, :glass],
        [360, 152, 84, 12, :stone]
      ],
      goblins: [[312, 232], [360, 232], [408, 232], [360, 138]]
    },
    # Level 7: 連鎖爆破城
    {
      name: "CHAIN REACTOR",
      ammo: [:iron, :bomb, :split],
      blocks: [
        [280, 222, 14, 40, :stone], [340, 222, 14, 40, :wood], [400, 222, 14, 40, :stone],
        [310, 228, 22, 22, :tnt], [370, 228, 22, 22, :tnt],
        [310, 196, 72, 12, :wood], [370, 196, 72, 12, :wood],
        [340, 172, 14, 36, :glass], [340, 148, 60, 12, :stone]
      ],
      goblins: [[310, 182], [370, 182], [340, 134], [432, 232]]
    },
    # Level 8: 魔王の黒城
    {
      name: "DARK CITADEL",
      ammo: [:bomb, :split, :bomb, :iron],
      blocks: [
        [270, 222, 16, 40, :stone], [322, 222, 16, 40, :stone], [374, 222, 16, 40, :stone], [426, 222, 16, 40, :stone],
        [296, 196, 66, 12, :stone], [348, 196, 66, 12, :wood], [400, 196, 66, 12, :stone],
        [296, 172, 14, 36, :wood], [348, 172, 14, 36, :tnt], [400, 172, 14, 36, :wood],
        [348, 148, 118, 12, :stone],
        [348, 124, 24, 24, :glass]
      ],
      goblins: [[296, 232], [348, 232], [400, 232], [348, 182], [348, 104]]
    }
  ]
end

class SlingshotFortressGame
  def initialize
    @levels = make_fort_levels
    @state = :title
    @frame = 0
    @lvl_idx = 0
    @score = 0
    load_level(0)
  end

  def load_level(idx)
    @lvl_idx = idx % @levels.size
    lvl = @levels[@lvl_idx]
    @ammo = lvl[:ammo].dup
    @blocks = lvl[:blocks].map do |b|
      mat = b[4]
      hp = mat == :stone ? 3 : (mat == :glass ? 1 : 2)
      { x: b[0].to_f, y: b[1].to_f, w: b[2].to_f, h: b[3].to_f, mat: mat, hp: hp, vx: 0.0, vy: 0.0, rot: 0.0, vrot: 0.0, dead: false }
    end
    @goblins = lvl[:goblins].map do |g|
      { x: g[0].to_f, y: g[1].to_f, vx: 0.0, vy: 0.0, alive: true }
    end
    @shots = []
    @sparks = []
    @blasts = []
    @aim_ang = -0.65
    @aim_pwr = 8.2
    @dragging = false
    @shake = 0.0
    @clear_t = 0
    @fail_t = 0
  end

  def fire_shot(kind, vx, vy)
    @shots << {
      kind: kind, x: SLING_X, y: SLING_Y, vx: vx, vy: vy,
      r: kind == :iron ? 6.0 : 5.0, used_skill: false, trail: [], life: 240, dead: false
    }
  end

  def explode(ex, ey, rad, power)
    @shake = 6.5
    @blasts << { x: ex, y: ey, r: 6.0, max_r: rad, life: 16, max_life: 16 }
    18.times do
      a = rand * 6.28
      spd = 1.2 + rand * 3.5
      @sparks << { x: ex, y: ey, vx: cos(a) * spd, vy: sin(a) * spd - 0.5, life: 20 + rand(12), max_life: 32, col: [8, 9, 10][rand(3)] }
    end

    @blocks.each do |b|
      next if b[:dead]
      dx = b[:x] - ex
      dy = b[:y] - ey
      d = sqrt(dx * dx + dy * dy)
      if d < rad + 18.0
        f = (1.0 - d / (rad + 22.0)).clamp(0.2, 1.0) * power
        b[:vx] += (dx / [d, 1.0].max) * f
        b[:vy] += (dy / [d, 1.0].max) * f - 2.0
        b[:vrot] += (rand - 0.5) * 0.25
        b[:hp] -= (f > 3.5 ? 2 : 1)
        if b[:hp] <= 0
          b[:dead] = true
          @score += 50
          explode(b[:x], b[:y], 48.0, 5.5) if b[:mat] == :tnt
        end
      end
    end

    @goblins.each do |g|
      next unless g[:alive]
      dx = g[:x] - ex
      dy = g[:y] - ey
      d = sqrt(dx * dx + dy * dy)
      if d < rad + 14.0
        g[:alive] = false
        @score += 200
        10.times do
          a = rand * 6.28
          @sparks << { x: g[:x], y: g[:y], vx: cos(a) * 2.2, vy: sin(a) * 2.2, life: 18, max_life: 18, col: 11 }
        end
      end
    end
  end

  def update
    @frame += 1
    @shake *= 0.85

    if @state == :title
      if @frame > 5 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        @state = :play
        load_level(0)
      end
      return
    end

    if @state == :all_clear
      if btnp(1) || btnp(2) || btnp(:mouse_l)
        @score = 0
        @state = :play
        load_level(0)
      end
      return
    end

    # クリア判定
    alive_gobs = @goblins.count { |g| g[:alive] }
    if alive_gobs == 0
      @clear_t += 1
      if @clear_t > 65 || (@clear_t > 15 && (btnp(1) || btnp(:mouse_l)))
        @score += @ammo.size * 150
        if @lvl_idx == @levels.size - 1
          @state = :all_clear
        else
          load_level(@lvl_idx + 1)
        end
      end
      update_fx
      return
    end

    # 失敗判定
    if @ammo.empty? && @shots.empty?
      @fail_t += 1
      if @fail_t > 90 || btnp(1) || btnp(2) || btnp(:mouse_l)
        load_level(@lvl_idx)
      end
      update_fx
      return
    end

    if btnp(2)
      load_level(@lvl_idx)
      return
    end

    # 飛行中の砲弾へのスキル発動 (Z / クリック)
    active_shot = @shots.first
    if active_shot
      if btnp(1) || btnp(:mouse_l)
        if !active_shot[:used_skill]
          active_shot[:used_skill] = true
          if active_shot[:kind] == :split
            [-0.22, 0.22].each do |da|
              spd = sqrt(active_shot[:vx] ** 2 + active_shot[:vy] ** 2)
              ang = atan2(active_shot[:vy], active_shot[:vx]) + da
              @shots << {
                kind: :iron, x: active_shot[:x], y: active_shot[:y],
                vx: cos(ang) * spd, vy: sin(ang) * spd,
                r: 4.5, used_skill: true, trail: [], life: 160, dead: false
              }
            end
          elsif active_shot[:kind] == :bomb
            active_shot[:dead] = true
            explode(active_shot[:x], active_shot[:y], 58.0, 6.2)
          end
        end
      end
    elsif @ammo.size > 0
      # 照準操作（キーボード）
      @aim_ang = (@aim_ang - 0.03).clamp(-1.35, -0.15) if btn(:up)
      @aim_ang = (@aim_ang + 0.03).clamp(-1.35, -0.15) if btn(:down)
      @aim_pwr = (@aim_pwr - 0.15).clamp(4.0, 12.0) if btn(:left)
      @aim_pwr = (@aim_pwr + 0.15).clamp(4.0, 12.0) if btn(:right)

      # マウスドラッグ照準
      if btn(:mouse_l)
        mx = mouse_x
        my = mouse_y
        if my > 24 && my < GROUND_Y
          @dragging = true
          dx = SLING_X - mx
          dy = SLING_Y - my
          if dx > 5.0
            @aim_ang = atan2(dy, dx).clamp(-1.35, -0.1)
            @aim_pwr = (sqrt(dx * dx + dy * dy) * 0.14).clamp(4.0, 12.0)
          else
            @aim_ang = atan2(my - SLING_Y, mx - SLING_X).clamp(-1.35, -0.1)
            @aim_pwr = (sqrt((mx - SLING_X) ** 2 + (my - SLING_Y) ** 2) * 0.055).clamp(4.0, 12.0)
          end
        end
      elsif @dragging
        @dragging = false
        kind = @ammo.shift
        fire_shot(kind, cos(@aim_ang) * @aim_pwr, sin(@aim_ang) * @aim_pwr)
      end

      if btnp(1)
        kind = @ammo.shift
        fire_shot(kind, cos(@aim_ang) * @aim_pwr, sin(@aim_ang) * @aim_pwr)
      end
    end

    # 砲弾物理更新
    @shots.each do |s|
      next if s[:dead]
      s[:vy] += GRAV
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1
      s[:trail] << [s[:x], s[:y]] if @frame % 2 == 0
      s[:trail].shift if s[:trail].size > 16

      if s[:y] + s[:r] >= GROUND_Y
        s[:y] = GROUND_Y - s[:r]
        s[:vy] = -s[:vy] * 0.45
        s[:vx] *= 0.72
        if s[:kind] == :bomb && !s[:used_skill]
          s[:used_skill] = true
          s[:dead] = true
          explode(s[:x], s[:y], 56.0, 6.0)
        end
      end

      # ブロック衝突
      @blocks.each do |b|
        next if b[:dead]
        hw = b[:w] * 0.5 + s[:r]
        hh = b[:h] * 0.5 + s[:r]
        if (s[:x] - b[:x]).abs < hw && (s[:y] - b[:y]).abs < hh
          if s[:kind] == :bomb
            s[:dead] = true
            explode(s[:x], s[:y], 58.0, 6.2)
            break
          end
          spd = sqrt(s[:vx] ** 2 + s[:vy] ** 2)
          b[:vx] += s[:vx] * 0.55
          b[:vy] += s[:vy] * 0.45 - 0.6
          b[:vrot] += (rand - 0.5) * 0.2
          dmg = spd > 5.0 ? 2 : 1
          b[:hp] -= dmg
          s[:vx] *= 0.45
          s[:vy] *= -0.35
          if b[:hp] <= 0
            b[:dead] = true
            @score += 50
            explode(b[:x], b[:y], 48.0, 5.5) if b[:mat] == :tnt
            6.times do
              a = rand * 6.28
              @sparks << { x: b[:x], y: b[:y], vx: cos(a) * 2.0, vy: sin(a) * 2.0, life: 16, max_life: 16, col: b[:mat] == :glass ? 12 : 4 }
            end
          end
          break
        end
      end

      # ゴブリン直撃
      @goblins.each do |g|
        next unless g[:alive]
        if (s[:x] - g[:x]) ** 2 + (s[:y] - g[:y]) ** 2 < (s[:r] + 9.0) ** 2
          g[:alive] = false
          @score += 200
          @shake = 3.5
          8.times do
            a = rand * 6.28
            @sparks << { x: g[:x], y: g[:y], vx: cos(a) * 2.2, vy: sin(a) * 2.2, life: 16, max_life: 16, col: 11 }
          end
        end
      end

      s[:dead] = true if s[:life] <= 0 || s[:x] > SW + 20 || s[:x] < -20 || (s[:vx].abs < 0.2 && s[:vy].abs < 0.2 && s[:y] > GROUND_Y - 10)
    end
    @shots.reject! { |s| s[:dead] }

    # ブロック崩落物理
    @blocks.each do |b|
      next if b[:dead]
      b[:vy] += GRAV * 0.7
      b[:x] += b[:vx]
      b[:y] += b[:vy]
      b[:rot] += b[:vrot]
      b[:vx] *= 0.92
      b[:vrot] *= 0.9

      if b[:y] + b[:h] * 0.5 >= GROUND_Y
        if b[:vy] > 3.8 && b[:mat] == :glass
          b[:dead] = true
        end
        b[:y] = GROUND_Y - b[:h] * 0.5
        b[:vy] = 0.0
        b[:vx] *= 0.78
        b[:vrot] *= 0.7
      end

      # 他ブロックに乗る簡易支持
      @blocks.each do |o|
        next if o == b || o[:dead]
        if (b[:x] - o[:x]).abs < (b[:w] + o[:w]) * 0.45
          top_o = o[:y] - o[:h] * 0.5
          bot_b = b[:y] + b[:h] * 0.5
          if bot_b >= top_o && bot_b <= top_o + 10.0 && b[:vy] >= 0.0 && b[:y] < o[:y]
            b[:y] = top_o - b[:h] * 0.5
            b[:vy] = 0.0
            b[:vx] *= 0.82
          end
        end
      end

      # ブロックがゴブリンを押し潰す
      if b[:vx].abs > 1.2 || b[:vy].abs > 1.5
        @goblins.each do |g|
          next unless g[:alive]
          if (b[:x] - g[:x]).abs < b[:w] * 0.5 + 6.0 && (b[:y] - g[:y]).abs < b[:h] * 0.5 + 6.0
            g[:alive] = false
            @score += 200
          end
        end
      end
    end
    @blocks.reject! { |b| b[:dead] }

    update_fx
  end

  def update_fx
    @sparks.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:vy] += 0.08
      p[:life] -= 1
    end
    @sparks.reject! { |p| p[:life] <= 0 }
    @blasts.each do |bl|
      bl[:r] += (bl[:max_r] - bl[:r]) * 0.25
      bl[:life] -= 1
    end
    @blasts.reject! { |bl| bl[:life] <= 0 }
  end

  def draw
    cls(0)
    sx = @shake > 0.2 ? (rand * 2.0 - 1.0) * @shake : 0.0
    sy = @shake > 0.2 ? (rand * 2.0 - 1.0) * @shake : 0.0
    camera(sx, sy)

    bg(:mountain, 0, 0, dim: 0.35)

    # 地面
    rectfill(0, GROUND_Y, SW, SH - GROUND_Y, 3)
    rectfill(0, GROUND_Y, SW, 4, 11)

    # カタパルト
    line(SLING_X - 4, GROUND_Y, SLING_X - 4, SLING_Y, 4, 4)
    line(SLING_X + 4, GROUND_Y, SLING_X + 4, SLING_Y, 4, 4)

    # 弾道予測ガイド (polyline)
    if @state == :play && @shots.empty? && @ammo.size > 0
      pts = []
      px = SLING_X
      py = SLING_Y
      pvx = cos(@aim_ang) * @aim_pwr
      pvy = sin(@aim_ang) * @aim_pwr
      22.times do |i|
        pvy += GRAV
        px += pvx
        py += pvy
        pts << [px, py] if i % 2 == 0
      end
      polyline(pts, 7, 1, 0.55)
      # 構えた砲弾
      col = @ammo[0] == :bomb ? 8 : (@ammo[0] == :split ? 12 : 6)
      circfill(SLING_X, SLING_Y, 5, col)
    end

    # 回転する物理ブロック (quadfill)
    @blocks.each do |b|
      hw = b[:w] * 0.5
      hh = b[:h] * 0.5
      ca = cos(b[:rot])
      sa = sin(b[:rot])
      corners = [[-hw, -hh], [hw, -hh], [hw, hh], [-hw, hh]].map do |c|
        [b[:x] + c[0] * ca - c[1] * sa, b[:y] + c[0] * sa + c[1] * ca]
      end
      col = b[:mat] == :stone ? 5 : (b[:mat] == :glass ? 12 : (b[:mat] == :tnt ? 8 : 4))
      al = b[:mat] == :glass ? 0.6 : 0.95
      quadfill(corners[0][0], corners[0][1], corners[1][0], corners[1][1], corners[2][0], corners[2][1], corners[3][0], corners[3][1], col, al)
      quad(corners[0][0], corners[0][1], corners[1][0], corners[1][1], corners[2][0], corners[2][1], corners[3][0], corners[3][1], b[:mat] == :tnt ? 10 : 0, 1)
      if b[:mat] == :tnt
        print_text("TNT", b[:x] - 9, b[:y] - 3, 10, 8)
      end
    end

    # ゴブリン
    @goblins.each do |g|
      next unless g[:alive]
      spr(:goblin, g[:x] - 8, g[:y] - 8)
    end

    # 砲弾＆軌跡
    @shots.each do |s|
      polyline(s[:trail], 7, 2, 0.45) if s[:trail].size >= 2
      col = s[:kind] == :bomb ? 8 : (s[:kind] == :split ? 12 : 6)
      circfill(s[:x], s[:y], s[:r], col)
      circ(s[:x], s[:y], s[:r], 7)
    end

    # 加算爆風＆火花
    blend(:add)
    @blasts.each do |bl|
      al = bl[:life].to_f / bl[:max_life]
      circfill(bl[:x], bl[:y], bl[:r], 9, al * 0.65)
      circfill(bl[:x], bl[:y], bl[:r] * 0.5, 10, al * 0.85)
    end
    @sparks.each do |p|
      circfill(p[:x], p[:y], 2.0, p[:col], p[:life].to_f / p[:max_life])
    end
    blend(:normal)

    camera()
    draw_hud
  end

  def draw_hud
    rectfill(0, 0, SW, 22, 0, 0.78)
    line(0, 22, SW, 22, 6, 1, 0.5)
    lvl = @levels[@lvl_idx]
    print_text(format("LV.%d %s", @lvl_idx + 1, lvl[:name]), 8, 7, 7, 8)
    print_text(format("SCORE %05d", @score), 160, 7, 10, 8)

    # 残弾表示
    print_text("AMMO:", 254, 7, 6, 8)
    @ammo.each_with_index do |a, i|
      col = a == :bomb ? 8 : (a == :split ? 12 : 6)
      circfill(294 + i * 14, 11, 4, col)
      circ(294 + i * 14, 11, 4, 7)
    end
    print_text("X:RESET", 426, 7, 6, 8)

    if @state == :title
      rectfill(96, 52, 288, 138, 0, 0.85)
      rect(96, 52, 288, 138, 10, 2)
      print_text("SLINGSHOT FORTRESS", 144, 64, 10, 16)
      print_text("PHYSICS CASTLE DESTRUCTION (8 STAGES)", 129, 88, 7, 8)
      print_text("DRAG / ARROWS : AIM & POWER", 159, 112, 12, 8)
      print_text("Z / CLICK     : FIRE & AIR SKILL", 144, 128, 11, 8)
      print_text("PRESS Z OR CLICK TO SIEGE!", 162, 158, 10, 8)
    elsif @clear_t > 0
      rectfill(140, 96, 200, 56, 0, 0.86)
      rect(140, 96, 200, 56, 11, 2)
      print_text("FORTRESS CRUSHED!", 164, 112, 11, 8)
      print_text("CLICK OR Z FOR NEXT", 183, 128, 7, 8)
    elsif @state == :all_clear
      rectfill(116, 80, 248, 92, 0, 0.9)
      rect(116, 80, 248, 92, 10, 2)
      print_text("ALL 8 FORTRESSES", 160, 94, 10, 16)
      print_text("CONQUERED!", 192, 114, 11, 16)
      print_text(format("FINAL SCORE: %05d", @score), 186, 140, 7, 8)
    end
  end
end

run SlingshotFortressGame.new

__END__
@PALETTE 1
0: #101418
3: #007848
B: #38C858
7: #FFF1E8
8: #FF2048

@SPRITE :goblin 16x16 pal:1
................
....00....00....
...0BB0000BB0...
...0BBBBBBBB0...
..0BBBBBBBBBB0..
..0BB70BB07BB0..
..0BB00BB00BB0..
...0BBBBBBBB0...
...0B077770B0...
....00000000....
...0333333330...
...03.0330.30...
......0330......
.....00..00.....
................
................
