# ==============================================================================
# 05. DRIFT CIRCUIT
# ------------------------------------------------------------------------------
# タイヤ痕・火花・ゴースト再生付き見下ろしドリフトレース
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ↑ / W           : アクセル
#   ↓ / S           : ブレーキ / バック
#   ← / → (A / D)   : ステアリング
#   Z / Space       : ドリフト (離すとスパーク量に応じてターボ加速!)
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "05. DRIFT CIRCUIT"
)

$drift_best_time ||= nil
$drift_best_ghost ||= nil

# サーキットのウェイポイント（閉ループ中心線）
TRACK_PTS = [
  [128.0, 214.0],
  [200.0, 214.0],
  [224.0, 186.0],
  [218.0, 134.0],
  [168.0, 118.0],
  [172.0, 74.0],
  [212.0, 50.0],
  [180.0, 34.0],
  [76.0, 34.0],
  [38.0, 56.0],
  [36.0, 116.0],
  [82.0, 140.0],
  [44.0, 174.0],
  [54.0, 210.0]
]
TRACK_HALF_W = 20.0

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
  dx = px - cx
  dy = py - cy
  dx * dx + dy * dy
end

def on_track?(px, py)
  min_d2 = 999999.0
  n = TRACK_PTS.size
  i = 0
  while i < n
    p1 = TRACK_PTS[i]
    p2 = TRACK_PTS[(i + 1) % n]
    d2 = dist_pt_seg_sq(px, py, p1[0], p1[1], p2[0], p2[1])
    min_d2 = d2 if d2 < min_d2
    i += 1
  end
  min_d2 <= TRACK_HALF_W * TRACK_HALF_W
end

def fmt_time(frames)
  return "--:--.--" if frames.nil?
  total_cs = (frames * 100 / 60).to_i
  cs = total_cs % 100
  total_s = total_cs / 100
  s = total_s % 60
  m = total_s / 60
  sprintf("%02d:%02d.%02d", m, s, cs)
end

def draw_circuit
  bg(:training, dim: 0.55, tint: [70, 150, 90])

  n = TRACK_PTS.size
  # 外縁（縁石赤白）
  i = 0
  while i < n
    p1 = TRACK_PTS[i]
    p2 = TRACK_PTS[(i + 1) % n]
    steps = 12
    k = 0
    while k <= steps
      t = k.to_f / steps
      x = (p1[0] + (p2[0] - p1[0]) * t).to_i
      y = (p1[1] + (p2[1] - p1[1]) * t).to_i
      col = (k % 2 == 0) ? 8 : 7
      circfill(x, y, TRACK_HALF_W.to_i + 2, col)
      k += 1
    end
    i += 1
  end

  # アスファルト路面
  i = 0
  while i < n
    p1 = TRACK_PTS[i]
    p2 = TRACK_PTS[(i + 1) % n]
    steps = 12
    k = 0
    while k <= steps
      t = k.to_f / steps
      x = (p1[0] + (p2[0] - p1[0]) * t).to_i
      y = (p1[1] + (p2[1] - p1[1]) * t).to_i
      circfill(x, y, TRACK_HALF_W.to_i, 5)
      k += 1
    end
    i += 1
  end

  # スタート/フィニッシュライン
  sy = 196
  while sy < 232
    col = ((sy / 4) % 2 == 0) ? 7 : 0
    rectfill(124, sy, 4, 4, col)
    rectfill(128, sy, 4, 4, col == 7 ? 0 : 7)
    sy += 4
  end
end

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
    draw_circuit

    # デモ走行車
    idx = (@t / 12) % TRACK_PTS.size
    p1 = TRACK_PTS[idx]
    p2 = TRACK_PTS[(idx + 1) % TRACK_PTS.size]
    ang = atan2(p2[1] - p1[1], p2[0] - p1[0]) * 180.0 / Math::PI
    spr_ext(:car, p1[0].to_i, p1[1].to_i, ang, 1.0, 1.0, false, false)

    rectfill(28, 56, 200, 40, 0)
    rect(28, 56, 200, 40, 10)
    print_text("DRIFT CIRCUIT", 89, 64, 10)
    print_text("3-LAP TIME TRIAL + GHOST", 56, 78, 7)

    rectfill(24, 106, 208, 64, 0)
    rect(24, 106, 208, 64, 5)
    print_text("UP/W: GAS   DOWN/S: BRAKE", 36, 115, 7)
    print_text("LEFT/RIGHT: STEER", 36, 128, 7)
    print_text("HOLD Z/SPACE: DRIFT -> BOOST!", 36, 141, 12)
    if $drift_best_time
      print_text("BEST 3-LAP: #{fmt_time($drift_best_time)}", 56, 155, 10)
    end

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO RACE", 56, 180, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @px = 114.0
    @py = 214.0
    @ang = 0.0
    @vx = 0.0
    @vy = 0.0

    @drifting = false
    @drift_charge = 0
    @boost_timer = 0

    @lap = 1
    @cp_flags = [false, false, false]
    @race_frames = 0
    @finished = false
    @finish_timer = 0
    @new_best = false

    @skids = []
    @sparks = []
    @ghost_rec = []
    @shake_t = 0
  end

  def add_spark(x, y, col)
    ang = @ang + Math::PI + (rand() - 0.5) * 1.2
    spd = 0.8 + rand() * 1.6
    @sparks << { x: x, y: y, vx: cos(ang) * spd, vy: sin(ang) * spd, life: 12 + rand(8), col: col }
  end

  def update
    @t += 1
    @shake_t -= 1 if @shake_t > 0

    if @finished
      @finish_timer += 1
      if @finish_timer > 30 && (btnp(4) || btnp(5) || btnp(:mouse_l))
        run GameScene.new
      end
      return
    end

    @race_frames += 1

    # ステアリング & ドリフト
    turn_rate = 0.055
    was_drift = @drifting
    @drifting = btn(4)

    if @drifting
      turn_rate = 0.085
    end

    @ang -= turn_rate if btn(0)
    @ang += turn_rate if btn(1)

    spd = sqrt(@vx * @vx + @vy * @vy)

    # ドリフトチャージ & 火花
    if @drifting && spd > 1.2 && (btn(0) || btn(1))
      @drift_charge += 1
      if @t % 2 == 0
        @skids << { x: @px.to_i, y: @py.to_i, life: 90 }
        scol = @drift_charge > 45 ? 14 : (@drift_charge > 20 ? 9 : 12)
        add_spark(@px, @py, scol)
      end
    elsif was_drift && !@drifting
      if @drift_charge >= 20
        @boost_timer = @drift_charge >= 45 ? 36 : 22
        @shake_t = 6
        i = 0
        while i < 10
          add_spark(@px, @py, @drift_charge >= 45 ? 14 : 10)
          i += 1
        end
      end
      @drift_charge = 0
    elsif !@drifting
      @drift_charge = 0
    end

    # アクセル
    accel = 0.0
    accel += 0.13 if btn(2)
    accel -= 0.08 if btn(3)
    if @boost_timer > 0
      @boost_timer -= 1
      accel += 0.16
      add_spark(@px, @py, 10) if @t % 2 == 0
    end

    @vx += cos(@ang) * accel
    @vy += sin(@ang) * accel

    # グリップ（横滑り抑制）
    fx = cos(@ang)
    fy = sin(@ang)
    rx = -fy
    ry = fx
    fwd_v = @vx * fx + @vy * fy
    lat_v = @vx * rx + @vy * ry

    grip = @drifting ? 0.90 : 0.72
    lat_v *= grip
    @vx = fx * fwd_v + rx * lat_v
    @vy = fy * fwd_v + ry * lat_v

    # 路面摩擦
    on_road = on_track?(@px, @py)
    drag = on_road ? 0.96 : 0.88
    @vx *= drag
    @vy *= drag

    max_spd = @boost_timer > 0 ? 4.2 : (on_road ? 2.85 : 1.55)
    cur_spd = sqrt(@vx * @vx + @vy * @vy)
    if cur_spd > max_spd
      @vx = @vx / cur_spd * max_spd
      @vy = @vy / cur_spd * max_spd
    end

    @px = clamp_v(@px + @vx, 8.0, 248.0)
    @py = clamp_v(@py + @vy, 24.0, 248.0)

    # ゴースト記録
    @ghost_rec << [@px.to_i, @py.to_i, (@ang * 180.0 / Math::PI).to_i]

    # チェックポイント判定
    @cp_flags[0] = true if @px > 190.0 && @py < 150.0
    @cp_flags[1] = true if @px < 80.0 && @py < 80.0
    @cp_flags[2] = true if @px < 80.0 && @py > 160.0

    # フィニッシュライン通過
    if @px >= 122.0 && @px <= 134.0 && @py >= 190.0 && @py <= 236.0 && @vx > 0.0
      if @cp_flags[0] && @cp_flags[1] && @cp_flags[2]
        @cp_flags = [false, false, false]
        if @lap < 3
          @lap += 1
        else
          @finished = true
          @finish_timer = 0
          if $drift_best_time.nil? || @race_frames < $drift_best_time
            $drift_best_time = @race_frames
            $drift_best_ghost = @ghost_rec
            @new_best = true
          end
        end
      end
    end

    # パーティクル更新
    @skids.each { |sk| sk[:life] -= 1 }
    @skids.reject! { |sk| sk[:life] <= 0 }
    @sparks.each do |sp|
      sp[:x] += sp[:vx]
      sp[:y] += sp[:vy]
      sp[:life] -= 1
    end
    @sparks.reject! { |sp| sp[:life] <= 0 }
  end

  def draw
    cls(0)
    shk_x = @shake_t > 0 ? rand(-2..2) : 0
    shk_y = @shake_t > 0 ? rand(-2..2) : 0
    camera(shk_x, shk_y)

    draw_circuit

    # タイヤ痕
    @skids.each do |sk|
      rectfill(sk[:x] - 1, sk[:y] - 1, 2, 2, 0)
    end

    # ゴーストカー
    if $drift_best_ghost && @race_frames < $drift_best_ghost.size && @t % 2 == 0
      g = $drift_best_ghost[@race_frames]
      spr_ext(:car, g[0], g[1], g[2].to_f, 1.0, 1.0, false, false, 11)
    end

    # 火花
    @sparks.each do |sp|
      rectfill(sp[:x].to_i, sp[:y].to_i, 2, 2, sp[:col])
    end

    # 自車
    deg = @ang * 180.0 / Math::PI
    spr_ext(:car, @px.to_i, @py.to_i, deg, 1.0, 1.0, false, false)

    camera()
    clip()

    # HUD
    rectfill(0, 0, 256, 18, 0)
    line(0, 18, 256, 18, 5)
    print_text("LAP:#{@lap}/3", 6, 5, 10)
    print_text("TIME:#{fmt_time(@race_frames)}", 64, 5, 7)
    print_text("BEST:#{fmt_time($drift_best_time)}", 164, 5, 12)

    # ドリフトチャージバー
    if @drift_charge > 0
      bw = clamp_v(@drift_charge, 0, 50)
      bcol = @drift_charge >= 45 ? 14 : (@drift_charge >= 20 ? 9 : 12)
      rectfill(8, 242, 52, 6, 0)
      rectfill(9, 243, bw, 4, bcol)
    end

    if @finished
      rectfill(30, 82, 196, 86, 0)
      rect(30, 82, 196, 86, 10)
      print_text("RACE COMPLETE!", 86, 94, 10)
      print_text("TIME : #{fmt_time(@race_frames)}", 68, 112, 7)
      print_text("BEST : #{fmt_time($drift_best_time)}", 68, 124, 12)
      if @new_best
        print_text("NEW RECORD + GHOST SAVED!", 53, 138, 11)
      end
      if (@finish_timer / 18) % 2 == 0
        print_text("PRESS Z OR CLICK TO RETRY", 53, 154, 10)
      end
    end
  end
end

run TitleScene.new

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

@PALETTE 11
0: #003344
5: #29ADFF
7: #8CF4FF
8: #29ADFF
A: #8CF4FF
C: #8CF4FF

@SPRITE :car 16x16 pal:1
................
................
................
..000000000000..
.08888877888880.
.08800C77C00880.
.08888C77C88880.
.08888C77C88880.
.08888C77C88880.
.08800C77C00880.
.08888877888880.
..000000000000..
................
................
................
................
