# ==============================================================================
# 26. FIREWORKS DIRECTOR
# ------------------------------------------------------------------------------
# 柳・菊・冠菊・ハート型花火を連発できる夜空の花火師トイ
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   夜空をクリック / Z : 指定位置へ花火打ち上げ!
#   下部ボタン / ← →   : 花火の種類切替 (菊 / 柳 / ハート / 冠菊 / 連発)
#   X                  : オート花火大会モード切替
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "26. FIREWORKS DIRECTOR"
)

WATER_Y = 196

SHELL_TYPES = [
  { id: :chrys,  name: "KIKU",   col: 10 },
  { id: :willow, name: "YANAGI", col: 9 },
  { id: :heart,  name: "HEART",  col: 14 },
  { id: :ring,   name: "RING",   col: 12 },
  { id: :finale, name: "SALVO",  col: 8 }
]

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
    bg(:city, dim: 0.45, tint: [140, 160, 225])
    rectfill(0, WATER_Y, 256, 60, 1)
    line(0, WATER_Y, 256, WATER_Y, 12)

    # デモ花火
    r = (@t % 45)
    i = 0
    while i < 12
      ang = i * Math::PI / 6.0
      fx = 128 + (cos(ang) * r).to_i
      fy = 160 + (sin(ang) * r * 0.6).to_i
      circfill(fx, fy, 1, i % 2 == 0 ? 10 : 14)
      i += 1
    end

    rectfill(24, 24, 208, 40, 0)
    rect(24, 24, 208, 40, 14)
    print_text("FIREWORKS DIRECTOR", 74, 32, 10)
    print_text("NIGHT SKY PYROTECHNICS TOY!", 47, 46, 12)

    rectfill(24, 78, 208, 56, 0)
    rect(24, 78, 208, 56, 5)
    print_text("CLICK SKY / Z : LAUNCH SHELL!", 40, 88, 7)
    print_text("ARROWS / BAR  : 5 SHELL STYLES", 40, 101, 10)
    print_text("X             : AUTO SHOW MODE", 40, 114, 14)

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO START", 53, 224, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0
    @sel = 0
    @auto = true
    @launched = 0
    @rockets = []
    @sparks = []
    @flash_t = 0
    launch_shell(128.0, 84.0, 0)
  end

  def launch_shell(tx, ty, kind_idx)
    @launched += 1
    if kind_idx == 4
      i = 0
      while i < 5
        rx = 36.0 + i * 46.0
        ry = 60.0 + rand() * 50.0
        @rockets << { x: rx, y: WATER_Y.to_f, ty: ry, vy: -4.2 - rand() * 0.8, kind: rand(4), col: [8, 10, 11, 12, 14][rand(5)] }
        i += 1
      end
    else
      col = [8, 9, 10, 11, 12, 14][rand(6)]
      col = 14 if kind_idx == 2
      col = 10 if kind_idx == 1
      @rockets << { x: tx, y: WATER_Y.to_f, ty: ty, vy: -4.4, kind: kind_idx, col: col }
    end
  end

  def detonate(rk)
    @flash_t = 2
    x = rk[:x]; y = rk[:y]; col = rk[:col]
    kind = rk[:kind]
    if kind == 0
      # 菊
      i = 0
      while i < 36
        ang = i * Math::PI * 2.0 / 36.0
        spd = 1.6 + (i % 2) * 0.9
        @sparks << { x: x, y: y, vx: cos(ang) * spd, vy: sin(ang) * spd, col: i % 2 == 0 ? col : 7, grav: 0.035, life: 42 }
        i += 1
      end
    elsif kind == 1
      # 柳
      i = 0
      while i < 40
        ang = rand() * Math::PI * 2.0
        spd = 0.6 + rand() * 2.0
        @sparks << { x: x, y: y, vx: cos(ang) * spd, vy: sin(ang) * spd - 0.5, col: i % 3 == 0 ? 9 : 10, grav: 0.06, life: 60 }
        i += 1
      end
    elsif kind == 2
      # ハート
      i = 0
      while i < 36
        t = i * Math::PI * 2.0 / 36.0
        hx = 16.0 * (sin(t) ** 3)
        hy = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
        @sparks << { x: x, y: y, vx: hx * 0.14, vy: hy * 0.14, col: i % 2 == 0 ? 14 : 8, grav: 0.018, life: 48 }
        i += 1
      end
    else
      # 冠菊リング
      [1.4, 2.5].each_with_index do |spd, ri|
        i = 0
        while i < 24
          ang = i * Math::PI * 2.0 / 24.0
          @sparks << { x: x, y: y, vx: cos(ang) * spd, vy: sin(ang) * spd, col: ri == 0 ? 7 : col, grav: 0.028, life: 40 }
          i += 1
        end
      end
    end
  end

  def update
    @t += 1
    @flash_t -= 1 if @flash_t > 0

    @sel = (@sel - 1) % SHELL_TYPES.size if btnp(:left)
    @sel = (@sel + 1) % SHELL_TYPES.size if btnp(:right)
    @auto = !@auto if btnp(2)

    if btnp(1)
      launch_shell(40.0 + rand() * 176.0, 50.0 + rand() * 80.0, @sel)
    end

    if btnp(:mouse_l)
      mx = mouse_x; my = mouse_y
      if my >= 232
        i = 0
        while i < SHELL_TYPES.size
          bx = 3 + i * 50
          @sel = i if mx >= bx && mx <= bx + 48
          i += 1
        end
      elsif my > 20 && my < WATER_Y
        launch_shell(mx.to_f, my.to_f, @sel)
      end
    end

    if @auto && @t % 38 == 0
      launch_shell(36.0 + rand() * 184.0, 48.0 + rand() * 84.0, rand(SHELL_TYPES.size))
    end

    @rockets.each do |rk|
      rk[:y] += rk[:vy]
      @sparks << { x: rk[:x], y: rk[:y] + 2.0, vx: (rand() - 0.5) * 0.3, vy: 0.5, col: 9, grav: 0.02, life: 8 }
      if rk[:y] <= rk[:ty]
        rk[:done] = true
        detonate(rk)
      end
    end
    @rockets.reject! { |rk| rk[:done] }

    @sparks.each do |s|
      s[:x] += s[:vx]
      s[:y] += s[:vy]
      s[:vy] += s[:grav]
      s[:vx] *= 0.97
      s[:life] -= 1
    end
    @sparks.reject! { |s| s[:life] <= 0 }
  end

  def draw
    cls(0)
    bg(:city, dim: @flash_t > 0 ? 0.35 : 0.5, tint: [135, 155, 220])

    # 水面
    rectfill(0, WATER_Y, 256, 232 - WATER_Y, 1)
    line(0, WATER_Y, 256, WATER_Y, 12)

    # 花火 & 水面反射
    @rockets.each do |rk|
      rectfill(rk[:x].to_i - 1, rk[:y].to_i - 2, 2, 4, 7)
    end
    @sparks.each do |s|
      sx = s[:x].to_i
      sy = s[:y].to_i
      if s[:life] > 14
        circfill(sx, sy, 1, s[:col])
      else
        pset(sx, sy, s[:col])
      end
      # 水面反射
      if sy < WATER_Y
        ry = WATER_Y + ((WATER_Y - sy) / 4)
        if ry < 230
          rx = sx + (sin(@t * 0.15 + ry) * 2.0).to_i
          pset(rx, ry, s[:col])
        end
      end
    end

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("SHELLS:#{@launched}", 6, 6, 10)
    print_text("STYLE:#{SHELL_TYPES[@sel][:name]}", 86, 6, SHELL_TYPES[@sel][:col])
    print_text(@auto ? "AUTO:ON[X]" : "AUTO:OFF", 190, 6, @auto ? 11 : 6)

    # 下部パレット
    rectfill(0, 232, 256, 24, 0)
    line(0, 232, 256, 232, 5)
    i = 0
    while i < SHELL_TYPES.size
      st = SHELL_TYPES[i]
      bx = 3 + i * 50
      sel = (i == @sel)
      rectfill(bx, 235, 48, 18, sel ? 1 : 0)
      rect(bx, 235, 48, 18, sel ? 7 : st[:col])
      print_text(st[:name], bx + 4, 240, st[:col])
      i += 1
    end
  end
end

run TitleScene.new
