# ==============================================================================
# 33. SHADOW THIEF
# ------------------------------------------------------------------------------
# 警備員の視界コーンとサーチライトを影に潜んで抜けるステルス潜入（全5面）
# 320x240 / 1ファイル完結 / 基本API + bg() + スプライト + キーボード入力
#
# 【操作方法】
#   矢印キー : 移動（壁・影に隠れる）
#   Z       : デコイ小石を投げる（警備員を誘導）
#   X       : シャドウダッシュ（高速移動＋瞬間隠密）
# ==============================================================================

config(
  width: 320,
  height: 240,
  scale: 2,
  title: "33. SHADOW THIEF"
)

SW = 320
SH = 240
TOP_H = 20

def make_stages
  [
    # Stage 1: 基本潜入
    {
      name: "MUSEUM WING",
      start: [28.0, 196.0],
      exit: [284.0, 46.0],
      walls: [
        [0, TOP_H, 320, 8], [0, 232, 320, 8], [0, TOP_H, 8, 220], [312, TOP_H, 8, 220],
        [80, 76, 16, 108], [160, 28, 16, 108], [232, 92, 16, 108]
      ],
      gems: [[44, 52], [128, 198], [204, 54], [276, 196]],
      guards: [
        { pts: [[124, 60], [124, 175]], spd: 0.9, fov: 0.55, dist: 78.0 },
        { pts: [[198, 185], [198, 70]], spd: 0.9, fov: 0.55, dist: 78.0 },
        { pts: [[272, 85], [272, 170]], spd: 0.85, fov: 0.55, dist: 72.0 }
      ]
    },
    # Stage 2: サーチライト中庭
    {
      name: "COURTYARD",
      start: [28.0, 128.0],
      exit: [286.0, 128.0],
      walls: [
        [0, TOP_H, 320, 8], [0, 232, 320, 8], [0, TOP_H, 8, 220], [312, TOP_H, 8, 220],
        [72, 60, 28, 36], [72, 156, 28, 36],
        [156, 102, 28, 44],
        [228, 58, 28, 36], [228, 158, 28, 36]
      ],
      gems: [[86, 128], [170, 50], [170, 206], [242, 128]],
      guards: [
        { pts: [[124, 48], [124, 204]], spd: 1.15, fov: 0.58, dist: 84.0 },
        { pts: [[204, 204], [204, 48]], spd: 1.15, fov: 0.58, dist: 84.0 },
        { pts: [[272, 60], [272, 196]], spd: 1.0, fov: 0.55, dist: 76.0 }
      ]
    },
    # Stage 3: 二重回廊
    {
      name: "TWIN CORRIDOR",
      start: [30.0, 48.0],
      exit: [286.0, 202.0],
      walls: [
        [0, TOP_H, 320, 8], [0, 232, 320, 8], [0, TOP_H, 8, 220], [312, TOP_H, 8, 220],
        [56, 28, 14, 150], [120, 80, 14, 152], [188, 28, 14, 150], [250, 80, 14, 152]
      ],
      gems: [[32, 204], [90, 50], [156, 204], [220, 50], [286, 50]],
      guards: [
        { pts: [[88, 70], [88, 206]], spd: 1.1, fov: 0.52, dist: 74.0 },
        { pts: [[154, 195], [154, 55]], spd: 1.15, fov: 0.52, dist: 76.0 },
        { pts: [[220, 65], [220, 205]], spd: 1.2, fov: 0.55, dist: 78.0 },
        { pts: [[282, 165], [282, 65]], spd: 1.0, fov: 0.55, dist: 72.0 }
      ]
    },
    # Stage 4: 中央金庫室
    {
      name: "CENTRAL VAULT",
      start: [26.0, 204.0],
      exit: [290.0, 48.0],
      walls: [
        [0, TOP_H, 320, 8], [0, 232, 320, 8], [0, TOP_H, 8, 220], [312, TOP_H, 8, 220],
        [110, 80, 100, 14], [110, 160, 100, 14],
        [110, 80, 14, 34], [196, 140, 14, 34],
        [52, 112, 22, 30], [248, 112, 22, 30]
      ],
      gems: [[160, 126], [34, 48], [288, 204], [160, 48], [160, 204]],
      guards: [
        { pts: [[86, 48], [234, 48]], spd: 1.25, fov: 0.55, dist: 85.0 },
        { pts: [[234, 204], [86, 204]], spd: 1.25, fov: 0.55, dist: 85.0 },
        { pts: [[134, 126], [186, 126]], spd: 0.9, fov: 0.6, dist: 70.0 },
        { pts: [[282, 74], [282, 180]], spd: 1.1, fov: 0.55, dist: 76.0 }
      ]
    },
    # Stage 5: 屋上ペントハウス
    {
      name: "PENTHOUSE",
      start: [160.0, 208.0],
      exit: [160.0, 44.0],
      walls: [
        [0, TOP_H, 320, 8], [0, 232, 320, 8], [0, TOP_H, 8, 220], [312, TOP_H, 8, 220],
        [60, 68, 48, 16], [212, 68, 48, 16],
        [60, 168, 48, 16], [212, 168, 48, 16],
        [136, 118, 48, 16]
      ],
      gems: [[34, 48], [286, 48], [34, 204], [286, 204], [160, 88]],
      guards: [
        { pts: [[44, 100], [44, 150]], spd: 1.1, fov: 0.6, dist: 86.0 },
        { pts: [[276, 150], [276, 100]], spd: 1.1, fov: 0.6, dist: 86.0 },
        { pts: [[112, 50], [208, 50]], spd: 1.35, fov: 0.58, dist: 88.0 },
        { pts: [[208, 148], [112, 148]], spd: 1.35, fov: 0.58, dist: 88.0 }
      ]
    }
  ]
end

class ShadowThiefGame
  def initialize
    @stages = make_stages
    @state = :title
    @frame = 0
    @stage_idx = 0
    @total_gems = 0
    load_stage(0)
  end

  def load_stage(idx)
    @stage_idx = idx % @stages.size
    st = @stages[@stage_idx]
    @px = st[:start][0]
    @py = st[:start][1]
    @dir = -Math::PI / 2.0
    @stamina = 100.0
    @dash_t = 0
    @alert = 0.0
    @decoys = []
    @sparks = []
    @walls = st[:walls]
    @exit_pt = st[:exit]
    @gems = st[:gems].map { |g| { x: g[0].to_f, y: g[1].to_f, got: false } }
    @guards = st[:guards].map do |gd|
      p0 = gd[:pts][0]
      p1 = gd[:pts][1]
      ang = atan2(p1[1] - p0[1], p1[0] - p0[0])
      {
        x: p0[0].to_f, y: p0[1].to_f,
        pts: gd[:pts], target_i: 1,
        spd: gd[:spd], fov: gd[:fov], dist: gd[:dist],
        ang: ang, lure_x: nil, lure_y: nil, lure_t: 0,
        cone: []
      }
    end
    @guards.each { |g| compute_cone(g) }
  end

  def point_in_wall?(x, y, pad = 0.0)
    @walls.each do |w|
      if x >= w[0] - pad && x <= w[0] + w[2] + pad && y >= w[1] - pad && y <= w[1] + w[3] + pad
        return true
      end
    end
    false
  end

  def raycast(ox, oy, ang, max_dist)
    dx = cos(ang)
    dy = sin(ang)
    step = 4.0
    d = 4.0
    while d < max_dist
      rx = ox + dx * d
      ry = oy + dy * d
      if point_in_wall?(rx, ry, 0.0)
        # 2pxバックで精密化
        return [ox + dx * (d - 2.0), oy + dy * (d - 2.0), d - 2.0]
      end
      d += step
    end
    [ox + dx * max_dist, oy + dy * max_dist, max_dist]
  end

  def compute_cone(g)
    pts = [[g[:x], g[:y]]]
    rays = 14
    i = 0
    while i <= rays
      a = g[:ang] - g[:fov] + (g[:fov] * 2.0) * (i.to_f / rays)
      hit = raycast(g[:x], g[:y], a, g[:dist])
      pts << [hit[0], hit[1]]
      i += 1
    end
    g[:cone] = pts
  end

  def can_see_player?(g)
    return false if @dash_t > 0
    dx = @px - g[:x]
    dy = @py - g[:y]
    d = sqrt(dx * dx + dy * dy)
    return false if d > g[:dist]
    ang_to_p = atan2(dy, dx)
    diff = (ang_to_p - g[:ang] + Math::PI * 3.0) % (Math::PI * 2.0) - Math::PI
    return false if diff.abs > g[:fov]
    hit = raycast(g[:x], g[:y], ang_to_p, d)
    hit[2] >= d - 4.0
  end

  def update
    @frame += 1

    if @state == :title
      @guards.each do |g|
        g[:ang] = sin(@frame * 0.02) * 0.6
        compute_cone(g)
      end
      if @frame > 5 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        @state = :play
        load_stage(0)
      end
      return
    end

    if @state == :busted || @state == :all_clear
      if btnp(1) || btnp(2) || btnp(:mouse_l)
        if @state == :all_clear
          load_stage(0)
        else
          load_stage(@stage_idx)
        end
        @state = :play
      end
      return
    end

    # 移動
    mx = 0.0
    my = 0.0
    mx -= 1.0 if btn(:left)
    mx += 1.0 if btn(:right)
    my -= 1.0 if btn(:up)
    my += 1.0 if btn(:down)

    if mx != 0.0 || my != 0.0
      len = sqrt(mx * mx + my * my)
      mx /= len
      my /= len
      @dir = atan2(my, mx)
    end

    # シャドウダッシュ (X)
    if btnp(2) && @stamina >= 40.0
      @stamina -= 40.0
      @dash_t = 16
      8.times do
        @sparks << { x: @px, y: @py, vx: (rand - 0.5) * 1.5, vy: (rand - 0.5) * 1.5, life: 16, col: 13 }
      end
    end
    @dash_t -= 1 if @dash_t > 0
    @stamina = [@stamina + 0.35, 100.0].min

    spd = @dash_t > 0 ? 3.2 : 1.65
    nx = @px + mx * spd
    @px = nx unless point_in_wall?(nx, @py, 5.0)
    ny = @py + my * spd
    @py = ny unless point_in_wall?(@px, ny, 5.0)

    # デコイ小石 (Z)
    if btnp(1) && @decoys.size < 2
      dx = @px + cos(@dir) * 44.0
      dy = @py + sin(@dir) * 44.0
      if !point_in_wall?(dx, dy, 4.0)
        @decoys << { x: dx, y: dy, life: 150, ring: 0 }
        # 近くの警備員を誘導
        @guards.each do |g|
          dist = sqrt((g[:x] - dx) ** 2 + (g[:y] - dy) ** 2)
          if dist < 110.0
            g[:lure_x] = dx
            g[:lure_y] = dy
            g[:lure_t] = 140
          end
        end
      end
    end

    @decoys.each do |dc|
      dc[:life] -= 1
      dc[:ring] = (dc[:ring] + 1) % 30
    end
    @decoys.reject! { |dc| dc[:life] <= 0 }

    # 宝石回収
    got_all = true
    @gems.each do |gm|
      if !gm[:got]
        d = sqrt((gm[:x] - @px) ** 2 + (gm[:y] - @py) ** 2)
        if d < 12.0
          gm[:got] = true
          @total_gems += 1
          10.times do
            ang = rand * 6.28
            @sparks << { x: gm[:x], y: gm[:y], vx: cos(ang) * 1.8, vy: sin(ang) * 1.8, life: 20, col: 10 }
          end
        else
          got_all = false
        end
      end
    end

    # 脱出判定
    if got_all
      de = sqrt((@exit_pt[0] - @px) ** 2 + (@exit_pt[1] - @py) ** 2)
      if de < 14.0
        if @stage_idx == @stages.size - 1
          @state = :all_clear
        else
          load_stage(@stage_idx + 1)
        end
        return
      end
    end

    # 警備員更新＆視界判定
    seen = false
    @guards.each do |g|
      tx = g[:pts][g[:target_i]][0].to_f
      ty = g[:pts][g[:target_i]][1].to_f
      if g[:lure_t] > 0
        g[:lure_t] -= 1
        tx = g[:lure_x]
        ty = g[:lure_y]
      end

      dx = tx - g[:x]
      dy = ty - g[:y]
      dist = sqrt(dx * dx + dy * dy)
      if dist > 3.0
        g[:x] += (dx / dist) * g[:spd]
        g[:y] += (dy / dist) * g[:spd]
        target_ang = atan2(dy, dx)
        diff = (target_ang - g[:ang] + Math::PI * 3.0) % (Math::PI * 2.0) - Math::PI
        g[:ang] += diff * 0.14
      elsif g[:lure_t] <= 0
        g[:target_i] = (g[:target_i] + 1) % g[:pts].size
      end
      compute_cone(g)
      seen = true if can_see_player?(g)
    end

    if seen
      @alert = [@alert + 4.5, 100.0].min
      @state = :busted if @alert >= 100.0
    else
      @alert = [@alert - 1.5, 0.0].max
    end

    @sparks.each do |s|
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }
  end

  def draw
    cls(0)
    bg(:city, 0, 0, dim: 0.72)

    # 乗算モードで夜の暗闇ベースを作る
    blend(:mul)
    rectfill(0, TOP_H, SW, SH - TOP_H, 1, 0.78)
    blend(:normal)

    # 壁描画
    @walls.each do |w|
      rectfill(w[0], w[1], w[2], w[3], 1)
      rect(w[0], w[1], w[2], w[3], 5)
    end

    # 脱出ゲート
    got_all = @gems.all? { |gm| gm[:got] }
    ex = @exit_pt[0]
    ey = @exit_pt[1]
    if got_all
      blend(:add)
      circfill(ex, ey, 11 + sin(@frame * 0.2) * 2.0, 11, 0.5)
      blend(:normal)
      circ(ex, ey, 8, 11)
      print_text("EXIT", ex - 11, ey - 3, 7, 8)
    else
      circ(ex, ey, 8, 5)
      print_text("LOCK", ex - 11, ey - 3, 5, 8)
    end

    # 宝石
    @gems.each do |gm|
      next if gm[:got]
      blend(:add)
      circfill(gm[:x], gm[:y], 8, 12, 0.35)
      blend(:normal)
      spr(:gem, gm[:x] - 8, gm[:y] - 8)
    end

    # デコイ波紋
    @decoys.each do |dc|
      circ(dc[:x], dc[:y], 4 + dc[:ring], 10, 1.0 - dc[:ring] / 30.0)
      circfill(dc[:x], dc[:y], 2, 7)
    end

    # 視界コーン (加算半透明ポリゴン)
    blend(:add)
    @guards.each do |g|
      cone_col = @alert > 20.0 ? 8 : 10
      polygonfill(g[:cone], cone_col, 0.32)
      # サーチライトの輪郭線
      if g[:cone].size >= 2
        line(g[:x], g[:y], g[:cone][1][0], g[:cone][1][1], cone_col, 1, 0.5)
        line(g[:x], g[:y], g[:cone][g[:cone].size - 1][0], g[:cone][g[:cone].size - 1][1], cone_col, 1, 0.5)
      end
    end
    blend(:normal)

    # 警備員 & プレイヤー
    @guards.each do |g|
      spr(:guard, g[:x] - 8, g[:y] - 8, cos(g[:ang]) < 0)
      if g[:lure_t] > 0
        print_text("?", g[:x] - 2, g[:y] - 16, 10, 8)
      end
    end

    p_alpha = @dash_t > 0 ? 0.45 : 1.0
    spr(:thief, @px - 8, @py - 8, cos(@dir) < 0, nil, 0.0, 1.0, p_alpha)
    if @alert > 5.0
      print_text("!", @px - 2, @py - 18, 8, 8)
    end

    # スパーク
    blend(:add)
    @sparks.each do |s|
      circfill(s[:x], s[:y], 2, s[:col], s[:life] / 20.0)
    end
    blend(:normal)

    draw_hud
  end

  def draw_hud
    rectfill(0, 0, SW, TOP_H, 0, 0.85)
    line(0, TOP_H, SW, TOP_H, 5)
    st = @stages[@stage_idx]
    print_text(format("ST%d %s", @stage_idx + 1, st[:name]), 6, 6, 7, 8)

    got_cnt = @gems.count { |g| g[:got] }
    print_text(format("GEM %d/%d", got_cnt, @gems.size), 130, 6, 12, 8)

    print_text("DASH", 190, 6, 13, 8)
    rectfill(218, 7, 36, 6, 1)
    rectfill(218, 7, (36 * (@stamina / 100.0)).to_i, 6, @stamina >= 40 ? 13 : 5)

    print_text("ALRT", 260, 6, @alert > 50 ? 8 : 6, 8)
    rectfill(286, 7, 28, 6, 1)
    rectfill(286, 7, (28 * (@alert / 100.0)).to_i, 6, 8)

    if @state == :title
      rectfill(44, 58, 232, 124, 0, 0.86)
      rect(44, 58, 232, 124, 12, 2)
      print_text("SHADOW THIEF", 112, 70, 7, 16)
      print_text("STEALTH IN THE DARKNESS", 91, 92, 12, 8)
      print_text("ARROWS:MOVE  Z:DECOY  X:DASH", 76, 114, 7, 8)
      print_text("COLLECT GEMS & REACH EXIT!", 82, 130, 10, 8)
      print_text("PRESS Z OR CLICK TO INFILTRATE", 70, 152, 11, 8)
    elsif @state == :busted
      rectfill(72, 82, 176, 74, 0, 0.9)
      rect(72, 82, 176, 74, 8, 2)
      print_text("SPOTTED!", 128, 94, 8, 16)
      print_text("PRESS Z TO RETRY STAGE", 94, 126, 7, 8)
    elsif @state == :all_clear
      rectfill(56, 74, 208, 90, 0, 0.9)
      rect(56, 74, 208, 90, 10, 2)
      print_text("MASTER THIEF!", 108, 86, 10, 16)
      print_text(format("ALL 5 STAGES CLEARED (%d GEMS)", @total_gems), 73, 114, 7, 8)
      print_text("PRESS Z TO PLAY AGAIN", 97, 136, 11, 8)
    end
  end
end

run ShadowThiefGame.new

__END__
@PALETTE 1
1: #181A2E
4: #6B4226
5: #4A5268
8: #FF2848
C: #38B8FF
D: #9068FF

@SPRITE :thief 16x16 pal:1
................
.....111111.....
....1DDDDDD1....
...1DDDDDDDD1...
...1D111111D1...
...11F7117F11...
....11111111....
....11DDDD11....
...1DDDDDDDD1...
...1D1DDDD1D1...
...11.DDDD.11...
......1DD1......
.....1D11D1.....
.....11..11.....
................
................

@SPRITE :guard 16x16 pal:1
................
.....155551.....
....15555551....
....11111111....
....1FFFFFF1....
....10F11F01....
.....111111.....
....11888811....
...1558888551...
...15.1111.51...
......1551......
.....151151.....
.....15..51.....
.....11..11.....
................
................

@SPRITE :gem 16x16 pal:1
................
................
......1111......
.....1CCCC1.....
....1C77CCC1....
...1CC7CCCCC1...
...1CCCCCCCC1...
....1CC11CC1....
.....1C11C1.....
......1CC1......
.......11.......
................
................
................
................
................
