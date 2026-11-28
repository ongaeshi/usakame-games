# ==============================================================================
# 29. RETRO SYNTH VISUALIZER
# ------------------------------------------------------------------------------
# 3Dワープトンネル＆プラズマ波を操るデモシーンVJトイ
# 256x256 / 1ファイル完結 / 基本API + BG + スプライト専用
#
# 【操作方法】
#   ← / → / Z / クリック : VJモード切替 (TUNNEL / 3D CUBE / WAVE / VORTEX)
#   ↑ / ↓                : スピード調整
#   X                    : ビートドロップ衝撃波
# ==============================================================================

config(
  width: 256,
  height: 256,
  scale: 2.0,
  title: "29. RETRO SYNTH VISUALIZER"
)

MODES = ["WARP TUNNEL", "3D WIRE CUBE", "SYNTH WAVE", "STAR VORTEX"]

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
    bg(:cyber, dim: 0.45, scroll_y: -@t * 0.6, mirror_y: true)

    i = 0
    while i < 6
      r = ((@t * 2 + i * 24) % 140)
      circ(128, 168, r, i % 2 == 0 ? 12 : 14)
      i += 1
    end

    rectfill(20, 24, 216, 40, 0)
    rect(20, 24, 216, 40, 12)
    print_text("RETRO SYNTH VISUALIZER", 62, 32, 10)
    print_text("3D WIREFRAME & DEMOSCENE VJ TOY", 35, 46, 12)

    rectfill(24, 78, 208, 56, 0)
    rect(24, 78, 208, 56, 5)
    print_text("Z / CLICK / ARROWS : VJ MODES", 38, 88, 7)
    print_text("UP / DOWN          : SPEED", 38, 101, 10)
    print_text("X                  : BEAT DROP!", 38, 114, 14)

    if (@t / 20) % 2 == 0
      print_text("PRESS Z OR CLICK TO LAUNCH VJ", 41, 224, 10)
    end
  end
end

class GameScene
  def initialize
    @t = 0.0
    @mode = 0
    @speed = 1.0
    @pulse = 0.0
    @stars = []
    i = 0
    while i < 48
      @stars << { x: (rand() - 0.5) * 200.0, y: (rand() - 0.5) * 200.0, z: 10.0 + rand() * 190.0 }
      i += 1
    end
  end

  def update
    @t += 0.05 * @speed
    @pulse *= 0.88

    @mode = (@mode - 1) % MODES.size if btnp(:left)
    @mode = (@mode + 1) % MODES.size if btnp(:right) || btnp(1) || btnp(:mouse_l)
    @speed += 0.25 if btnp(:up) && @speed < 3.0
    @speed -= 0.25 if btnp(:down) && @speed > 0.25
    @pulse = 16.0 if btnp(2)

    @stars.each do |s|
      s[:z] -= 2.5 * @speed
      if s[:z] <= 4.0
        s[:x] = (rand() - 0.5) * 200.0
        s[:y] = (rand() - 0.5) * 200.0
        s[:z] = 200.0
      end
    end
  end

  def draw_tunnel
    bg(:cyber, dim: 0.55, scroll_y: -@t * 18.0, mirror_y: true)
    # 8角形トンネルリング
    k = 0
    while k < 10
      z = ((k * 20.0 - (@t * 24.0)) % 200.0)
      z += 200.0 if z < 0.0
      z = 8.0 if z < 8.0
      scale = 260.0 / z
      r = (14.0 * scale + @pulse).to_i
      rot = @t * 0.4 + k * 0.15
      col = k % 2 == 0 ? 12 : 14
      i = 0
      while i < 8
        a1 = rot + i * Math::PI * 0.25
        a2 = rot + (i + 1) * Math::PI * 0.25
        x1 = 128 + (cos(a1) * r).to_i
        y1 = 128 + (sin(a1) * r).to_i
        x2 = 128 + (cos(a2) * r).to_i
        y2 = 128 + (sin(a2) * r).to_i
        line(x1, y1, x2, y2, col)
        i += 1
      end
      k += 1
    end
  end

  def draw_cube
    bg(:space, dim: 0.5)
    @stars.each do |s|
      px = 128 + (s[:x] * 120.0 / s[:z]).to_i
      py = 128 + (s[:y] * 120.0 / s[:z]).to_i
      pset(px, py, 7)
    end

    ax = @t * 0.7
    ay = @t * 1.1
    verts = [
      [-1.0, -1.0, -1.0], [1.0, -1.0, -1.0], [1.0, 1.0, -1.0], [-1.0, 1.0, -1.0],
      [-1.0, -1.0,  1.0], [1.0, -1.0,  1.0], [1.0, 1.0,  1.0], [-1.0, 1.0,  1.0]
    ]
    proj = []
    sz = 46.0 + @pulse
    verts.each do |v|
      x = v[0]; y = v[1]; z = v[2]
      # Y回転
      rx = x * cos(ay) - z * sin(ay)
      rz = x * sin(ay) + z * cos(ay)
      # X回転
      ry = y * cos(ax) - rz * sin(ax)
      rz2 = y * sin(ax) + rz * cos(ax)
      sc = 220.0 / (rz2 * 40.0 + 180.0)
      proj << [128 + (rx * sz * sc).to_i, 128 + (ry * sz * sc).to_i]
    end
    edges = [
      [0,1],[1,2],[2,3],[3,0],
      [4,5],[5,6],[6,7],[7,4],
      [0,4],[1,5],[2,6],[3,7]
    ]
    edges.each_with_index do |e, idx|
      p1 = proj[e[0]]; p2 = proj[e[1]]
      line(p1[0], p1[1], p2[0], p2[1], idx < 4 ? 12 : (idx < 8 ? 14 : 10))
    end
  end

  def draw_wave
    bg(:cyber, dim: 0.6)
    cols = [12, 14, 10, 11]
    w = 0
    while w < 4
      x = 0
      prev_y = 128
      while x <= 256
        y = 128 + (sin(x * 0.04 + @t * 1.5 + w * 0.9) * (32.0 + @pulse)).to_i +
                  (cos(x * 0.02 - @t) * 18.0).to_i
        line(x - 4, prev_y, x, y, cols[w]) if x > 0
        prev_y = y
        x += 4
      end
      w += 1
    end
    # スペアナバー
    i = 0
    while i < 16
      h = (16.0 + sin(@t * 2.5 + i * 0.6).abs * (44.0 + @pulse)).to_i
      rectfill(16 + i * 14, 240 - h, 10, h, i % 2 == 0 ? 12 : 14)
      i += 1
    end
  end

  def draw_vortex
    bg(:space, dim: 0.45)
    i = 0
    while i < 72
      r = i * 1.8 + @pulse
      ang = i * 0.35 + @t * 1.4
      x = 128 + (cos(ang) * r).to_i
      y = 128 + (sin(ang) * r).to_i
      col = [12, 14, 10, 11, 7][i % 5]
      circfill(x, y, 2, col)
      i += 1
    end
  end

  def draw
    cls(0)
    if @mode == 0
      draw_tunnel
    elsif @mode == 1
      draw_cube
    elsif @mode == 2
      draw_wave
    else
      draw_vortex
    end

    # HUD
    rectfill(0, 0, 256, 20, 0)
    line(0, 20, 256, 20, 5)
    print_text("VJ: #{MODES[@mode]}", 6, 6, 10)
    print_text("SPD:#{sprintf('%.2f', @speed)}x", 184, 6, 12)
  end
end

run TitleScene.new
