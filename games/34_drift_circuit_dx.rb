# ==============================================================================
# 34. DRIFT CIRCUIT DX
# ------------------------------------------------------------------------------
# 【05進化版】太線路面・半透明ゴースト・ナイトレース対応の本格ドリフト（3コース）
# 320x240 / 1ファイル完結 / 基本API + bg() + スプライト + キーボード入力
#
# 【操作方法】
#   ↑ / W           : アクセル
#   ↓ / S           : ブレーキ / バック
#   ← / → (A / D)   : ステアリング（タイトルでコース選択）
#   Z / Space       : ドリフト（離すとターボ加速！）
#   X / Enter       : タイトルへ戻る / ナイトモード切替
# ==============================================================================

config(
  width: 320,
  height: 240,
  scale: 2,
  title: "34. DRIFT CIRCUIT DX"
)

SW = 320
SH = 240

COURSES = [
  {
    name: "GP CIRCUIT",
    bg: :training,
    tint: [60, 140, 80],
    night: false,
    pts: [
      [160.0, 206.0], [250.0, 206.0], [282.0, 178.0], [274.0, 126.0],
      [210.0, 114.0], [218.0, 68.0],  [268.0, 48.0],  [230.0, 34.0],
      [92.0, 34.0],   [44.0, 56.0],   [42.0, 114.0],  [104.0, 134.0],
      [50.0, 168.0],  [66.0, 206.0]
    ],
    half_w: 19.0
  },
  {
    name: "CYBER NIGHT",
    bg: :cyber,
    tint: [140, 180, 255],
    night: true,
    pts: [
      [160.0, 208.0], [274.0, 208.0], [286.0, 160.0], [254.0, 130.0],
      [284.0, 88.0],  [266.0, 40.0],  [180.0, 38.0],  [158.0, 84.0],
      [112.0, 38.0],  [42.0, 46.0],   [38.0, 118.0],  [86.0, 152.0],
      [42.0, 194.0],  [84.0, 208.0]
    ],
    half_w: 18.0
  },
  {
    name: "TOUGE PASS",
    bg: :mountain,
    tint: [180, 150, 120],
    night: false,
    pts: [
      [160.0, 206.0], [268.0, 206.0], [284.0, 154.0], [202.0, 146.0],
      [182.0, 112.0], [276.0, 96.0],  [272.0, 42.0],  [140.0, 38.0],
      [110.0, 84.0],  [56.0, 44.0],   [36.0, 94.0],   [98.0, 134.0],
      [40.0, 174.0],  [72.0, 206.0]
    ],
    half_w: 18.0
  }
]

$dx_best_times ||= [nil, nil, nil]
$dx_best_ghosts ||= [nil, nil, nil]

def clamp_v(v, lo, hi)
  return lo if v < lo
  return hi if v > hi
  v
end

def dist_pt_seg_sq(px, py, ax, ay, bx, by)
  vx = bx - ax
  vy = by - ay
  wx = px - ax
  wy = py - ay
  len2 = vx * vx + vy * vy
  t = len2 > 0.0001 ? (wx * vx + wy * vy) / len2 : 0.0
  t = clamp_v(t, 0.0, 1.0)
  cx = ax + vx * t
  cy = ay + vy * t
  (px - cx) ** 2 + (py - cy) ** 2
end

def on_track?(pts, half_w, px, py)
  min_d2 = 999999.0
  n = pts.size
  i = 0
  while i < n
    p1 = pts[i]
    p2 = pts[(i + 1) % n]
    d2 = dist_pt_seg_sq(px, py, p1[0], p1[1], p2[0], p2[1])
    min_d2 = d2 if d2 < min_d2
    i += 1
  end
  min_d2 <= half_w * half_w
end

def fmt_time(frames)
  return "--:--.--" if frames.nil?
  total_cs = (frames * 100 / 60).to_i
  cs = total_cs % 100
  total_s = total_cs / 100
  s = total_s % 60
  m = total_s / 60
  format("%02d:%02d.%02d", m, s, cs)
end

class DriftCircuitDX
  def initialize
    @state = :title
    @frame = 0
    @course_idx = 0
    @night_override = nil
    reset_race
  end

  def course
    COURSES[@course_idx]
  end

  def is_night?
    return @night_override unless @night_override.nil?
    course[:night]
  end

  def reset_race
    c = course
    @px = 148.0
    @py = 206.0
    @vx = 0.0
    @vy = 0.0
    @ang = 0.0
    @speed = 0.0
    @drift_charge = 0
    @boost_t = 0
    @lap = 1
    @race_frames = 0
    @wp_idx = 1
    @finished = false
    @finish_t = 0
    @new_best = false
    @shake_t = 0
    @skids = []
    @sparks = []
    @ghost_rec = []

    # AIライバル2台
    @rivals = [
      { wp: 1, t: 0.2, spd: 2.05, pal: 2, x: 140.0, y: 200.0, ang: 0.0 },
      { wp: 1, t: 0.05, spd: 1.92, pal: 3, x: 132.0, y: 212.0, ang: 0.0 }
    ]
  end

  def update
    @frame += 1

    if @state == :title
      if btnp(0)
        @course_idx = (@course_idx - 1) % COURSES.size
        @night_override = nil
      elsif btnp(1)
        @course_idx = (@course_idx + 1) % COURSES.size
        @night_override = nil
      elsif btnp(5)
        @night_override = !is_night?
      elsif @frame > 5 && (btnp(4) || btnp(:mouse_l))
        reset_race
        @state = :race
      end
      return
    end

    if @finished
      @finish_t += 1
      if @finish_t > 20 && (btnp(4) || btnp(:mouse_l))
        reset_race
      elsif btnp(5)
        @state = :title
      end
      return
    end

    if btnp(5)
      @state = :title
      return
    end

    @race_frames += 1
    @shake_t -= 1 if @shake_t > 0
    c = course
    pts = c[:pts]

    # ハンドル・アクセル・ドリフト
    steer = 0.0
    steer -= 1.0 if btn(0)
    steer += 1.0 if btn(1)
    accel = 0.0
    accel += 1.0 if btn(2)
    accel -= 0.6 if btn(3)
    drifting = btn(4) && @speed > 1.2

    turn_rate = drifting ? 0.072 : 0.052
    @ang += steer * turn_rate * (@speed >= 0.0 ? 1.0 : -1.0)

    on_road = on_track?(pts, c[:half_w], @px, @py)
    max_spd = @boost_t > 0 ? 4.3 : (on_road ? 2.95 : 1.55)
    if @boost_t > 0
      @boost_t -= 1
      @speed = [@speed + 0.25, max_spd].min
    else
      @speed += accel * 0.14
      @speed *= on_road ? 0.965 : 0.90
      @speed = clamp_v(@speed, -1.2, max_spd)
    end

    grip = drifting ? 0.075 : 0.26
    tx = cos(@ang) * @speed
    ty = sin(@ang) * @speed
    @vx += (tx - @vx) * grip
    @vy += (ty - @vy) * grip

    @px = clamp_v(@px + @vx, 12.0, SW - 12.0)
    @py = clamp_v(@py + @vy, 24.0, SH - 12.0)

    # ドリフトチャージ＆火花
    if drifting && steer.abs > 0.1
      @drift_charge += 1
      if @frame % 2 == 0
        @skids << { x: @px, y: @py, life: 70, max_life: 70 }
        @skids.shift if @skids.size > 110
        spark_col = @drift_charge >= 42 ? 14 : (@drift_charge >= 18 ? 9 : 12)
        2.times do
          @sparks << {
            x: @px - cos(@ang) * 5.0 + (rand - 0.5) * 4.0,
            y: @py - sin(@ang) * 5.0 + (rand - 0.5) * 4.0,
            vx: -@vx * 0.4 + (rand - 0.5) * 1.4,
            vy: -@vy * 0.4 + (rand - 0.5) * 1.4,
            life: 14, max_life: 14, col: spark_col
          }
        end
      end
    else
      if @drift_charge >= 18
        @boost_t = @drift_charge >= 42 ? 36 : 20
        @shake_t = 6
      end
      @drift_charge = 0
    end

    # ゴースト記録
    @ghost_rec << [@px.to_i, @py.to_i, (@ang * 180.0 / Math::PI).to_i]

    # ウェイポイント進行＆ラップ判定
    nxt = pts[@wp_idx]
    d_wp = sqrt((nxt[0] - @px) ** 2 + (nxt[1] - @py) ** 2)
    if d_wp < 36.0
      @wp_idx = (@wp_idx + 1) % pts.size
      if @wp_idx == 1
        if @lap < 3
          @lap += 1
        else
          @finished = true
          @finish_t = 0
          best = $dx_best_times[@course_idx]
          if best.nil? || @race_frames < best
            $dx_best_times[@course_idx] = @race_frames
            $dx_best_ghosts[@course_idx] = @ghost_rec
            @new_best = true
          end
        end
      end
    end

    # ライバル更新
    @rivals.each do |r|
      p0 = pts[r[:wp]]
      p1 = pts[(r[:wp] + 1) % pts.size]
      dx = p1[0] - p0[0]
      dy = p1[1] - p0[1]
      seg_len = sqrt(dx * dx + dy * dy)
      r[:t] += r[:spd] / [seg_len, 1.0].max
      if r[:t] >= 1.0
        r[:t] -= 1.0
        r[:wp] = (r[:wp] + 1) % pts.size
      end
      r[:x] = p0[0] + dx * r[:t]
      r[:y] = p0[1] + dy * r[:t]
      r[:ang] = atan2(dy, dx)
    end

    # スパーク＆スキッド更新
    @skids.each { |s| s[:life] -= 1 }
    @skids.reject! { |s| s[:life] <= 0 }
    @sparks.each do |s|
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }
  end

  def draw_track
    c = course
    pts = c[:pts]
    closed = pts + [pts[0]]
    w = (c[:half_w] * 2.0).to_i

    # 縁石（太線 polyline で一発描画！）
    curb_col = is_night? ? 12 : 8
    polyline(closed, curb_col, w + 6, 0.9)
    # 路面アスファルト（太線 polyline）
    polyline(closed, 5, w, 1.0)
    # センターライン
    polyline(closed, is_night? ? 1 : 6, 2, 0.35)

    # スタート/フィニッシュチェッカー
    sy = (pts[0][1] - c[:half_w]).to_i
    ey = (pts[0][1] + c[:half_w]).to_i
    sx = pts[0][0].to_i
    while sy < ey
      col = ((sy / 4) % 2 == 0) ? 7 : 0
      rectfill(sx - 4, sy, 4, 4, col)
      rectfill(sx, sy, 4, 4, col == 7 ? 0 : 7)
      sy += 4
    end
  end

  def draw_headlight(x, y, ang)
    ca = cos(ang)
    sa = sin(ang)
    len = 74.0
    spread = 24.0
    x1 = x + ca * len - sa * spread
    y1 = y + sa * len + ca * spread
    x2 = x + ca * len + sa * spread
    y2 = y + sa * len - ca * spread
    trifill(x, y, x1, y1, x2, y2, 10, 0.34)
  end

  def draw
    cls(0)
    shk_x = @shake_t > 0 ? rand(-2..2) : 0
    shk_y = @shake_t > 0 ? rand(-2..2) : 0
    camera(shk_x, shk_y)

    c = course
    bg(c[:bg], 0, 0, dim: is_night? ? 0.65 : 0.45, tint: c[:tint])

    draw_track

    # 半透明フェードするタイヤ痕
    @skids.each do |sk|
      a = (sk[:life].to_f / sk[:max_life]) * 0.65
      rectfill(sk[:x] - 1, sk[:y] - 1, 3, 3, 0, a)
    end

    # ナイトレース時は乗算暗闇オーバーレイ
    if is_night?
      blend(:mul)
      rectfill(0, 0, SW, SH, 1, 0.72)
      blend(:normal)
    end

    # ライバル車
    @rivals.each do |r|
      if is_night?
        blend(:add)
        draw_headlight(r[:x], r[:y], r[:ang])
        blend(:normal)
      end
      spr_ext(:car, r[:x].to_i, r[:y].to_i, r[:ang] * 180.0 / Math::PI, 1.0, 1.0, false, false, r[:pal])
    end

    # 本物の半透明ゴーストカー (alpha: 0.45)
    ghost = $dx_best_ghosts[@course_idx]
    if @state == :race && ghost && @race_frames < ghost.size
      g = ghost[@race_frames]
      spr_ext(:car, g[0], g[1], g[2].to_f, 1.0, 1.0, false, false, 11, 0.45)
    end

    # 自車（タイトル時はデモ走行）
    if @state == :title
      pts = c[:pts]
      idx = (@frame / 14) % pts.size
      p1 = pts[idx]
      p2 = pts[(idx + 1) % pts.size]
      ang = atan2(p2[1] - p1[1], p2[0] - p1[0])
      if is_night?
        blend(:add)
        draw_headlight(p1[0], p1[1], ang)
        blend(:normal)
      end
      spr_ext(:car, p1[0].to_i, p1[1].to_i, ang * 180.0 / Math::PI, 1.0, 1.0, false, false)
    else
      if is_night?
        blend(:add)
        draw_headlight(@px, @py, @ang)
        blend(:normal)
      end
      spr_ext(:car, @px.to_i, @py.to_i, @ang * 180.0 / Math::PI, 1.0, 1.0, false, false)
    end

    # 加算スパーク＆ターボ炎
    blend(:add)
    if @boost_t > 0
      fx = @px - cos(@ang) * 9.0
      fy = @py - sin(@ang) * 9.0
      circfill(fx, fy, 5.0 + rand * 2.0, 10, 0.75)
      circfill(fx, fy, 3.0, 8, 0.9)
    end
    @sparks.each do |sp|
      a = sp[:life].to_f / sp[:max_life]
      circfill(sp[:x], sp[:y], 2.2, sp[:col], a)
    end
    blend(:normal)

    camera()

    if @state == :title
      draw_title
    else
      draw_hud
    end
  end

  def draw_title
    rectfill(42, 34, 236, 56, 0, 0.82)
    rect(42, 34, 236, 56, 10, 2)
    print_text("DRIFT CIRCUIT DX", 96, 44, 10, 16)
    print_text("SMOOTH POLYLINE & NIGHT HEADLIGHT", 61, 68, 12, 8)

    rectfill(52, 138, 216, 74, 0, 0.84)
    rect(52, 138, 216, 74, 6, 1)
    print_text(format("< COURSE %d/3: %s >", @course_idx + 1, course[:name]), 82, 148, 7, 8)
    mode_str = is_night? ? "NIGHT (HEADLIGHTS ON)" : "DAYLIGHT"
    print_text(format("X: MODE [%s]", mode_str), 76, 162, is_night? ? 12 : 10, 8)
    print_text(format("BEST: %s", fmt_time($dx_best_times[@course_idx])), 106, 176, 6, 8)
    print_text("PRESS Z OR CLICK TO RACE!", 85, 194, 11, 8)
  end

  def draw_hud
    rectfill(0, 0, SW, 18, 0, 0.82)
    line(0, 18, SW, 18, 5)
    print_text(format("LAP %d/3", @lap), 8, 5, 10, 8)
    print_text(format("TIME %s", fmt_time(@race_frames)), 74, 5, 7, 8)
    print_text(format("BEST %s", fmt_time($dx_best_times[@course_idx])), 174, 5, 12, 8)
    print_text(course[:name], 254, 5, 6, 8)

    if @drift_charge > 0
      bw = clamp_v(@drift_charge, 0, 56)
      bcol = @drift_charge >= 42 ? 14 : (@drift_charge >= 18 ? 9 : 12)
      rectfill(8, SH - 14, 60, 8, 0, 0.8)
      rectfill(10, SH - 12, bw, 4, bcol)
      print_text("TURBO", 72, SH - 14, bcol, 8)
    end

    if @finished
      rectfill(58, 74, 204, 92, 0, 0.88)
      rect(58, 74, 204, 92, 10, 2)
      print_text("RACE COMPLETE!", 104, 84, 10, 16)
      print_text(format("TIME : %s", fmt_time(@race_frames)), 98, 110, 7, 8)
      print_text(format("BEST : %s", fmt_time($dx_best_times[@course_idx])), 98, 122, 12, 8)
      print_text("NEW RECORD + GHOST SAVED!", 82, 136, 11, 8) if @new_best
      print_text("Z:RETRY   X:COURSE SELECT", 85, 150, 6, 8)
    end
  end
end

run DriftCircuitDX.new

__END__
@PALETTE 1
0: #0C0A14
5: #404452
7: #FFF1E8
8: #FF004D
9: #FFA300
A: #FFEC27
C: #29ADFF
E: #FF77A8

@PALETTE 2
8: #29ADFF
9: #8CF4FF

@PALETTE 3
8: #00E436
9: #FFEC27

@PALETTE 11
0: #184868
5: #48A8E0
7: #B8F4FF
8: #48D8FF

@SPRITE :car 16x16 pal:1
................
................
................
..000000000000..
.05507777088890.
088801CC108888A0
088801CC10888880
088801CC108888A0
.05507777088890.
..000000000000..
................
................
................
................
................
................
