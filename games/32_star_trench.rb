# ==============================================================================
# 32. STAR TRENCH 3D
# ------------------------------------------------------------------------------
# 面塗り3Dポリゴンの渓谷と戦艦を撃ち抜くレールシューター
# 320x240 / 1ファイル完結 / 基本API + bg() + キーボード入力
#
# 【操作方法】
#   矢印キー : 自機操縦（上下左右）
#   Z       : ツインレーザー連射
#   X       : バレルロール＆ロックオンミサイル発射
# ==============================================================================

config(
  width: 320,
  height: 240,
  scale: 2,
  title: "32. STAR TRENCH 3D"
)

SW = 320
SH = 240
CX = 160.0
CY = 108.0
FOV = 180.0
SEG_LEN = 22.0
NUM_SEGS = 14
TRENCH_W = 95.0
TRENCH_H = 68.0

class StarTrenchGame
  def initialize
    @state = :title
    @frame = 0
    @best_score = 0
    reset_game
  end

  def reset_game
    @px = 0.0
    @py = 12.0
    @vx = 0.0
    @vy = 0.0
    @bank = 0.0
    @roll_t = 0
    @hp = 100
    @max_hp = 100
    @energy = 100.0
    @score = 0
    @combo = 0
    @combo_t = 0
    @wave = 1
    @dist = 0.0
    @speed = 2.6
    @fire_cd = 0
    @invuln = 0
    @shake = 0.0
    @flash = 0
    @lasers = []
    @missiles = []
    @enemies = []
    @ebullets = []
    @particles = []
    @gates = []
    @boss = nil
    @spawn_t = 30
    @wave_kills = 0
  end

  def project(x, y, z)
    return nil if z <= 1.5
    s = FOV / z
    [CX + (x - @px * 0.55) * s, CY + (y - @py * 0.45) * s, s]
  end

  def spawn_explosion(x, y, z, col, count = 12)
    count.times do
      ang = rand * Math::PI * 2.0
      spd = 0.8 + rand * 2.8
      @particles << {
        x: x, y: y, z: z,
        vx: cos(ang) * spd, vy: sin(ang) * spd - 0.5, vz: (rand - 0.5) * 1.6,
        life: 20 + rand(15), max_life: 35,
        col: col, size: 3.0 + rand * 4.0
      }
    end
  end

  def spawn_enemy
    kind = [:fighter, :fighter, :turret, :ring][rand(4)]
    ex = (rand * 2.0 - 1.0) * (TRENCH_W - 22.0)
    ey = kind == :turret ? (TRENCH_H - 12.0) : ((rand * 2.0 - 1.0) * (TRENCH_H - 24.0))
    @enemies << {
      kind: kind,
      x: ex, y: ey, z: SEG_LEN * (NUM_SEGS - 1),
      vx: kind == :fighter ? ((rand < 0.5 ? -1.0 : 1.0) * (0.4 + @wave * 0.08)) : 0.0,
      vy: 0.0,
      hp: kind == :turret ? (2 + @wave / 2) : (1 + @wave / 3),
      max_hp: kind == :turret ? (2 + @wave / 2) : (1 + @wave / 3),
      fire_t: 35 + rand(40),
      hit_t: 0,
      rot: rand * 6.28
    }
  end

  def spawn_boss
    @boss = {
      x: 0.0, y: -6.0, z: 220.0, target_z: 135.0,
      hp: 30 + @wave * 15, max_hp: 30 + @wave * 15,
      phase: 0.0, fire_t: 40, hit_t: 0
    }
  end

  def update
    @frame += 1

    if @state == :title
      @dist += 1.4
      if @frame > 5 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        reset_game
        @state = :play
      end
      return
    end

    if @state == :gameover
      @dist += 0.6
      if btnp(1) || btnp(2) || btnp(:mouse_l)
        reset_game
        @state = :play
      end
      return
    end

    # プレイ中更新
    @speed = 2.5 + [@wave * 0.15, 1.5].min
    @dist += @speed
    @invuln -= 1 if @invuln > 0
    @flash -= 1 if @flash > 0
    @shake *= 0.85
    @combo_t -= 1 if @combo_t > 0
    @combo = 0 if @combo_t <= 0
    @energy = [@energy + 0.35, 100.0].min

    # 移動入力
    ax = 0.0
    ay = 0.0
    ax -= 1.0 if btn(:left)
    ax += 1.0 if btn(:right)
    ay -= 1.0 if btn(:up)
    ay += 1.0 if btn(:down)

    @vx = @vx * 0.78 + ax * 1.45
    @vy = @vy * 0.78 + ay * 1.15
    @px = (@px + @vx).clamp(-TRENCH_W + 20.0, TRENCH_W - 20.0)
    @py = (@py + @vy).clamp(-TRENCH_H + 16.0, TRENCH_H - 14.0)
    @bank = @bank * 0.82 + (-ax * 0.55) * 0.18

    if @roll_t > 0
      @roll_t -= 1
    end

    # 通常レーザー (Z)
    @fire_cd -= 1 if @fire_cd > 0
    if btn(1) && @fire_cd <= 0
      @fire_cd = 6
      @lasers << { x: @px - 10.0, y: @py + 2.0, z: 18.0, vz: 10.5 }
      @lasers << { x: @px + 10.0, y: @py + 2.0, z: 18.0, vz: 10.5 }
    end

    # バレルロール + ホーミングミサイル (X)
    if btnp(2) && @energy >= 30.0
      @energy -= 30.0
      @roll_t = 22
      @invuln = 24
      # 敵が居れば最大3体へホーミングミサイル発射
      targets = []
      @enemies.each { |e| targets << e if e[:z] > 25.0 }
      targets << @boss if @boss
      if targets.size > 0
        3.times do |i|
          tgt = targets[i % targets.size]
          @missiles << {
            x: @px + (i - 1) * 12.0, y: @py, z: 16.0,
            target: tgt, trail: [], life: 70
          }
        end
      end
    end

    # レーザー更新 & 衝突
    @lasers.each do |l|
      l[:z] += l[:vz]
      # 敵判定
      @enemies.each do |e|
        next if e[:hp] <= 0
        if (l[:z] - e[:z]).abs < 14.0 && (l[:x] - e[:x]).abs < 16.0 && (l[:y] - e[:y]).abs < 16.0
          e[:hp] -= 1
          e[:hit_t] = 5
          l[:z] = 999.0
          if e[:hp] <= 0
            destroy_enemy(e)
          else
            spawn_explosion(l[:x], l[:y], e[:z], 10, 4)
          end
          break
        end
      end
      # ボス判定
      if @boss && l[:z] < 900.0
        if (l[:z] - @boss[:z]).abs < 18.0 && (l[:x] - @boss[:x]).abs < 34.0 && (l[:y] - @boss[:y]).abs < 24.0
          damage_boss(1, l[:x], l[:y])
          l[:z] = 999.0
        end
      end
    end
    @lasers.reject! { |l| l[:z] > 290.0 }

    # ミサイル更新
    @missiles.each do |m|
      m[:life] -= 1
      m[:trail] << [m[:x], m[:y], m[:z]]
      m[:trail].shift if m[:trail].size > 8
      tgt = m[:target]
      if tgt && tgt[:hp] > 0
        dx = tgt[:x] - m[:x]
        dy = tgt[:y] - m[:y]
        dz = tgt[:z] - m[:z]
        len = sqrt(dx * dx + dy * dy + dz * dz)
        if len > 1.0
          m[:x] += (dx / len) * 6.5
          m[:y] += (dy / len) * 6.5
          m[:z] += (dz / len) * 6.5
        end
        if len < 16.0
          if tgt == @boss
            damage_boss(4, m[:x], m[:y])
          else
            tgt[:hp] -= 4
            destroy_enemy(tgt) if tgt[:hp] <= 0
          end
          m[:life] = 0
        end
      else
        m[:z] += 6.5
      end
    end
    @missiles.reject! { |m| m[:life] <= 0 || m[:z] > 300.0 }

    # 敵出現
    if @boss.nil?
      @spawn_t -= 1
      if @spawn_t <= 0
        spawn_enemy
        @spawn_t = [34 - @wave * 2, 14].max
      end
      if @wave_kills >= 8 + @wave * 3
        spawn_boss
      end
    else
      update_boss
    end

    # 敵更新
    @enemies.each do |e|
      e[:z] -= @speed * 0.9
      e[:x] += e[:vx]
      e[:rot] += 0.08
      e[:hit_t] -= 1 if e[:hit_t] > 0
      if e[:x].abs > TRENCH_W - 18.0
        e[:vx] = -e[:vx]
        e[:x] = e[:x].clamp(-TRENCH_W + 18.0, TRENCH_W - 18.0)
      end
      e[:fire_t] -= 1
      if e[:fire_t] <= 0 && e[:z] > 55.0 && e[:z] < 220.0
        e[:fire_t] = 55 + rand(35)
        dx = @px - e[:x]
        dy = @py - e[:y]
        dz = 16.0 - e[:z]
        len = sqrt(dx * dx + dy * dy + dz * dz)
        if len > 1.0
          @ebullets << { x: e[:x], y: e[:y], z: e[:z], vx: (dx / len) * 2.8, vy: (dy / len) * 2.8, vz: (dz / len) * 2.8 }
        end
      end
      # 体当たり
      if e[:z] < 22.0 && e[:z] > 6.0 && (e[:x] - @px).abs < 16.0 && (e[:y] - @py).abs < 14.0
        hit_player(16)
        e[:hp] = 0
        spawn_explosion(e[:x], e[:y], e[:z], 8, 10)
      end
    end
    @enemies.reject! { |e| e[:hp] <= 0 || e[:z] < 4.0 }

    # 敵弾更新
    @ebullets.each do |b|
      b[:x] += b[:vx]
      b[:y] += b[:vy]
      b[:z] += b[:vz]
      if b[:z] < 20.0 && b[:z] > 8.0 && (b[:x] - @px).abs < 12.0 && (b[:y] - @py).abs < 10.0
        hit_player(12)
        b[:z] = -10.0
      end
    end
    @ebullets.reject! { |b| b[:z] < 2.0 || b[:z] > 300.0 }

    # パーティクル更新
    @particles.each do |p|
      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:z] += p[:vz]
      p[:life] -= 1
    end
    @particles.reject! { |p| p[:life] <= 0 }
  end

  def destroy_enemy(e)
    @combo += 1
    @combo_t = 120
    pts = (e[:kind] == :turret ? 150 : 100) * [1 + @combo / 3, 5].min
    @score += pts
    @best_score = @score if @score > @best_score
    @wave_kills += 1
    @shake = 3.5
    spawn_explosion(e[:x], e[:y], e[:z], e[:kind] == :ring ? 11 : 9, 14)
  end

  def damage_boss(dmg, hx, hy)
    return if @boss.nil?
    @boss[:hp] -= dmg
    @boss[:hit_t] = 4
    spawn_explosion(hx, hy, @boss[:z], 10, 5)
    if @boss[:hp] <= 0
      @score += 1000 * @wave
      @best_score = @score if @score > @best_score
      @shake = 8.0
      @flash = 6
      spawn_explosion(@boss[:x], @boss[:y], @boss[:z], 9, 28)
      spawn_explosion(@boss[:x], @boss[:y], @boss[:z], 10, 18)
      @boss = nil
      @wave += 1
      @wave_kills = 0
      @hp = [@hp + 25, @max_hp].min
    end
  end

  def update_boss
    b = @boss
    b[:phase] += 0.035
    b[:z] += (b[:target_z] - b[:z]) * 0.05
    b[:x] = sin(b[:phase]) * 52.0
    b[:y] = cos(b[:phase] * 1.4) * 20.0 - 8.0
    b[:hit_t] -= 1 if b[:hit_t] > 0
    b[:fire_t] -= 1
    if b[:fire_t] <= 0
      b[:fire_t] = [38 - @wave * 3, 18].max
      (-1..1).each do |i|
        dx = @px - b[:x] + i * 26.0
        dy = @py - b[:y]
        dz = 16.0 - b[:z]
        len = sqrt(dx * dx + dy * dy + dz * dz)
        if len > 1.0
          @ebullets << { x: b[:x], y: b[:y], z: b[:z], vx: (dx / len) * 3.1, vy: (dy / len) * 3.1, vz: (dz / len) * 3.1 }
        end
      end
    end
  end

  def hit_player(dmg)
    return if @invuln > 0
    @hp -= dmg
    @invuln = 36
    @combo = 0
    @shake = 6.0
    @flash = 5
    spawn_explosion(@px, @py, 16.0, 8, 10)
    if @hp <= 0
      @hp = 0
      @state = :gameover
    end
  end

  def draw
    cls(0)
    sx = @shake > 0.2 ? (rand * 2.0 - 1.0) * @shake : 0.0
    sy = @shake > 0.2 ? (rand * 2.0 - 1.0) * @shake : 0.0
    camera(sx, sy)

    bg(:space, dim: 0.45, scroll_x: -@px * 0.25, scroll_y: -@py * 0.2)

    draw_trench
    draw_objects_z_sorted
    draw_player

    if @flash > 0
      blend(:add)
      rectfill(0, 0, SW, SH, 7, @flash * 0.06)
      blend(:normal)
    end

    camera()
    blend(:normal)

    if @state == :title
      draw_title
    elsif @state == :gameover
      draw_gameover
    else
      draw_hud
    end
  end

  def draw_trench
    offset = @dist % SEG_LEN
    i = NUM_SEGS - 1
    while i >= 0
      z1 = i * SEG_LEN + (SEG_LEN - offset) + 4.0
      z0 = z1 - SEG_LEN
      z0 = 3.0 if z0 < 3.0
      if z1 > 4.0
        p0_fl = project(-TRENCH_W, TRENCH_H, z0)
        p0_fr = project(TRENCH_W, TRENCH_H, z0)
        p0_tl = project(-TRENCH_W, -TRENCH_H, z0)
        p0_tr = project(TRENCH_W, -TRENCH_H, z0)

        p1_fl = project(-TRENCH_W, TRENCH_H, z1)
        p1_fr = project(TRENCH_W, TRENCH_H, z1)
        p1_tl = project(-TRENCH_W, -TRENCH_H, z1)
        p1_tr = project(TRENCH_W, -TRENCH_H, z1)

        if p0_fl && p0_fr && p1_fl && p1_fr && p0_tl && p0_tr && p1_tl && p1_tr
          seg_idx = ((@dist / SEG_LEN).to_i + i)
          alt = (seg_idx % 2 == 0)
          shade = 1.0 - (z1 / (NUM_SEGS * SEG_LEN + 20.0)) * 0.72
          shade = 0.2 if shade < 0.2

          # 床ポリゴン
          fl_col = alt ? 1 : 5
          quadfill(p0_fl[0], p0_fl[1], p0_fr[0], p0_fr[1], p1_fr[0], p1_fr[1], p1_fl[0], p1_fl[1], fl_col, shade * 0.85)
          # 左右壁ポリゴン
          wall_col = alt ? 5 : 1
          quadfill(p0_tl[0], p0_tl[1], p0_fl[0], p0_fl[1], p1_fl[0], p1_fl[1], p1_tl[0], p1_tl[1], wall_col, shade * 0.75)
          quadfill(p0_fr[0], p0_fr[1], p0_tr[0], p0_tr[1], p1_tr[0], p1_tr[1], p1_fr[0], p1_fr[1], wall_col, shade * 0.75)

          # ネオンの遠近エッジライン
          line(p0_fl[0], p0_fl[1], p1_fl[0], p1_fl[1], 12, 1, shade * 0.7)
          line(p0_fr[0], p0_fr[1], p1_fr[0], p1_fr[1], 12, 1, shade * 0.7)
          line(p1_tl[0], p1_tl[1], p1_fl[0], p1_fl[1], 13, 1, shade * 0.45)
          line(p1_tr[0], p1_tr[1], p1_fr[0], p1_fr[1], 13, 1, shade * 0.45)
        end
      end
      i -= 1
    end
  end

  def draw_objects_z_sorted
    draw_list = []
    @enemies.each { |e| draw_list << { z: e[:z], type: :enemy, obj: e } }
    draw_list << { z: @boss[:z], type: :boss, obj: @boss } if @boss
    @ebullets.each { |b| draw_list << { z: b[:z], type: :ebullet, obj: b } }
    @particles.each { |p| draw_list << { z: p[:z], type: :part, obj: p } }

    draw_list.sort_by! { |it| -it[:z] }

    draw_list.each do |it|
      case it[:type]
      when :enemy
        draw_enemy_3d(it[:obj])
      when :boss
        draw_boss_3d(it[:obj])
      when :ebullet
        b = it[:obj]
        pt = project(b[:x], b[:y], b[:z])
        if pt
          r = [2.0 * pt[2] * 0.25, 1.5].max
          blend(:add)
          circfill(pt[0], pt[1], r * 1.8, 8, 0.45)
          circfill(pt[0], pt[1], r, 10, 0.95)
          blend(:normal)
        end
      when :part
        p = it[:obj]
        pt = project(p[:x], p[:y], p[:z])
        if pt
          a = p[:life].to_f / p[:max_life]
          sz = p[:size] * pt[2] * 0.16
          blend(:add)
          trifill(pt[0], pt[1] - sz, pt[0] - sz, pt[1] + sz, pt[0] + sz, pt[1] + sz, p[:col], a)
          blend(:normal)
        end
      end
    end

    # 自機レーザーとホーミングミサイル (加算発光)
    blend(:add)
    @lasers.each do |l|
      p0 = project(l[:x], l[:y], l[:z])
      p1 = project(l[:x], l[:y], l[:z] + 18.0)
      if p0 && p1
        line(p0[0], p0[1], p1[0], p1[1], 11, 4, 0.45)
        line(p0[0], p0[1], p1[0], p1[1], 7, 1, 0.95)
      end
    end

    @missiles.each do |m|
      if m[:trail].size >= 2
        pts = []
        m[:trail].each do |tp|
          pr = project(tp[0], tp[1], tp[2])
          pts << [pr[0], pr[1]] if pr
        end
        polyline(pts, 12, 3, 0.65) if pts.size >= 2
      end
      pm = project(m[:x], m[:y], m[:z])
      circfill(pm[0], pm[1], 3, 7, 0.95) if pm
    end
    blend(:normal)
  end

  def draw_enemy_3d(e)
    pt = project(e[:x], e[:y], e[:z])
    return if pt.nil?
    x = pt[0]
    y = pt[1]
    s = pt[2] * 0.55
    flash = e[:hit_t] > 0

    case e[:kind]
    when :fighter
      w = 15.0 * s
      h = 9.0 * s
      col_wing = flash ? 7 : 5
      col_body = flash ? 7 : 8
      # 翼 (左右クアッド)
      quadfill(x - w, y - h, x - w * 0.4, y - h * 0.5, x - w * 0.4, y + h * 0.5, x - w, y + h, col_wing)
      quadfill(x + w, y - h, x + w * 0.4, y - h * 0.5, x + w * 0.4, y + h * 0.5, x + w, y + h, col_wing)
      # 機体コア
      pts = [[x, y - h * 0.7], [x + w * 0.4, y], [x, y + h * 0.7], [x - w * 0.4, y]]
      polygonfill(pts, col_body)
      poly(pts, 7, 1, 0.7)
    when :turret
      w = 12.0 * s
      h = 14.0 * s
      quadfill(x - w, y, x + w, y, x + w * 0.7, y - h, x - w * 0.7, y - h, flash ? 7 : 4)
      quad(x - w, y, x + w, y, x + w * 0.7, y - h, x - w * 0.7, y - h, 9, 1, 0.8)
      circfill(x, y - h * 0.7, w * 0.35, 8)
    when :ring
      r = 13.0 * s
      pts = []
      6.times do |i|
        a = e[:rot] + i * Math::PI / 3.0
        pts << [x + cos(a) * r, y + sin(a) * r]
      end
      polygonfill(pts, flash ? 7 : 3, 0.75)
      poly(pts, 11, 2, 0.9)
    end
  end

  def draw_boss_3d(b)
    pt = project(b[:x], b[:y], b[:z])
    return if pt.nil?
    x = pt[0]
    y = pt[1]
    s = pt[2] * 0.7
    w = 38.0 * s
    h = 20.0 * s
    flash = b[:hit_t] > 0

    # 巨大戦艦の主翼・装甲ポリゴン
    quadfill(x - w, y - h * 0.4, x + w, y - h * 0.4, x + w * 0.75, y + h * 0.6, x - w * 0.75, y + h * 0.6, flash ? 7 : 2)
    quad(x - w, y - h * 0.4, x + w, y - h * 0.4, x + w * 0.75, y + h * 0.6, x - w * 0.75, y + h * 0.6, 14, 2, 0.9)

    # 中央ブリッジ
    trifill(x - w * 0.4, y - h * 0.4, x + w * 0.4, y - h * 0.4, x, y - h * 1.1, flash ? 7 : 5)
    # 発光コア
    blend(:add)
    circfill(x, y + h * 0.1, w * 0.22, 8, 0.6)
    circfill(x, y + h * 0.1, w * 0.12, 10, 0.95)
    blend(:normal)
  end

  def draw_player
    return if @state == :gameover
    return if @invuln > 0 && (@invuln % 4) < 2 && @roll_t == 0

    pt = project(@px, @py, 16.0)
    return if pt.nil?
    x = pt[0]
    y = pt[1]
    ang = @bank + (@roll_t > 0 ? (@roll_t * 0.3) : 0.0)
    ca = cos(ang)
    sa = sin(ang)

    # 3D風ポリゴン自機（左翼・右翼・胴体）
    # ローカル座標を回転
    lw = [[-22.0, 5.0], [-4.0, -3.0], [-5.0, 6.0]]
    rw = [[22.0, 5.0], [4.0, -3.0], [5.0, 6.0]]
    body = [[0.0, -10.0], [6.0, 5.0], [0.0, 8.0], [-6.0, 5.0]]

    rot_pt = proc { |p| [x + p[0] * ca - p[1] * sa, y + p[0] * sa + p[1] * ca] }

    p_lw = lw.map { |p| rot_pt.call(p) }
    p_rw = rw.map { |p| rot_pt.call(p) }
    p_bd = body.map { |p| rot_pt.call(p) }

    trifill(p_lw[0][0], p_lw[0][1], p_lw[1][0], p_lw[1][1], p_lw[2][0], p_lw[2][1], 12)
    trifill(p_rw[0][0], p_rw[0][1], p_rw[1][0], p_rw[1][1], p_rw[2][0], p_rw[2][1], 12)
    polygonfill(p_bd, 7)
    poly(p_bd, 6, 1)

    # エンジン噴射 (加算発光)
    blend(:add)
    er = 4.0 + sin(@frame * 0.6) * 1.5
    circfill(x - 4.0 * ca, y - 4.0 * sa + 5.0, er, 10, 0.8)
    circfill(x + 4.0 * ca, y + 4.0 * sa + 5.0, er, 10, 0.8)
    blend(:normal)

    # 照準レティクル (前方投影)
    if @state == :play
      ret = project(@px, @py, 110.0)
      if ret
        rx = ret[0]
        ry = ret[1]
        polyline([[rx - 8, ry - 4], [rx - 8, ry - 8], [rx - 4, ry - 8]], 11, 1, 0.75)
        polyline([[rx + 4, ry - 8], [rx + 8, ry - 8], [rx + 8, ry - 4]], 11, 1, 0.75)
        polyline([[rx - 8, ry + 4], [rx - 8, ry + 8], [rx - 4, ry + 8]], 11, 1, 0.75)
        polyline([[rx + 4, ry + 8], [rx + 8, ry + 8], [rx + 8, ry + 4]], 11, 1, 0.75)
      end
    end
  end

  def draw_hud
    # 上部HUDバー
    rectfill(0, 0, SW, 18, 0, 0.7)
    print_text(format("SCORE %06d", @score), 8, 5, 7, 8)
    print_text(format("WAVE %d", @wave), 142, 5, 10, 8)
    if @combo >= 2
      print_text(format("x%d COMBO!", @combo), 240, 5, 11, 8)
    end

    # ボスHP
    if @boss
      bw = 140
      bx = (SW - bw) / 2
      rectfill(bx, 22, bw, 6, 0, 0.75)
      fill_w = (bw * (@boss[:hp].to_f / @boss[:max_hp])).to_i
      rectfill(bx, 22, fill_w, 6, 8)
      rect(bx, 22, bw, 6, 7)
      print_text("DREADNOUGHT", bx + 37, 30, 8, 8)
    end

    # 下部シールド＆エネルギー
    rectfill(0, SH - 20, SW, 20, 0, 0.7)
    print_text("SHIELD", 8, SH - 14, 12, 8)
    rectfill(50, SH - 14, 72, 7, 1)
    rectfill(50, SH - 14, (72 * (@hp.to_f / @max_hp)).to_i, 7, @hp > 30 ? 11 : 8)
    rect(50, SH - 14, 72, 7, 7)

    print_text("MISSILE", 130, SH - 14, 10, 8)
    rectfill(178, SH - 14, 48, 7, 1)
    rectfill(178, SH - 14, (48 * (@energy / 100.0)).to_i, 7, @energy >= 30 ? 10 : 5)
    rect(178, SH - 14, 48, 7, 7)

    print_text("Z:SHOT X:ROLL", 234, SH - 14, 6, 8)
  end

  def draw_title
    rectfill(40, 32, 240, 48, 0, 0.75)
    rect(40, 32, 240, 48, 12, 2)
    print_text("STAR TRENCH 3D", 104, 42, 7, 16)
    print_text("3D POLYGON RAIL SHOOTER", 91, 64, 10, 8)

    rectfill(56, 158, 208, 54, 0, 0.78)
    rect(56, 158, 208, 54, 6, 1)
    print_text("ARROWS : STEER", 103, 167, 7, 8)
    print_text("Z:LASER   X:HOMING ROLL", 91, 180, 12, 8)
    print_text("PRESS Z OR CLICK TO LAUNCH", 82, 195, 10, 8)
  end

  def draw_gameover
    rectfill(64, 74, 192, 88, 0, 0.88)
    rect(64, 74, 192, 88, 8, 2)
    print_text("SHIP DESTROYED", 104, 86, 8, 16)
    print_text(format("SCORE: %06d", @score), 121, 112, 7, 8)
    print_text(format("BEST : %06d", @best_score), 121, 124, 10, 8)
    print_text("PRESS Z OR CLICK TO RETRY", 85, 142, 6, 8)
  end
end

run StarTrenchGame.new
