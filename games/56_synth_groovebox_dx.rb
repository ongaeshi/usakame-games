config(
  title: "SYNTH GROOVEBOX DX",
  width: 480,
  height: 270,
  save_id: "synth_groovebox_dx",
  save_salt: "p4g56sg4"
)

$cfg = {
  w: 480,
  h: 270,
  steps: 16,
  tracks: 4,
  default_bpm: 128
}

$waves = [:square, :pulse, :pulse12, :triangle, :saw, :organ, :phaser, :sine]

$scales = [
  { name: "C MINOR", notes: [261.6, 293.7, 311.1, 349.2, 392.0, 415.3, 466.2, 523.3] },
  { name: "C PENTA", notes: [261.6, 311.1, 349.2, 392.0, 466.2, 523.3, 622.3, 784.0] },
  { name: "A BLUES", notes: [220.0, 261.6, 293.7, 311.1, 329.6, 392.0, 440.0, 523.3] }
]

$presets = [
  {
    name: "CYBER DRIVE",
    bpm: 132,
    t0: [0, -1, 2, -1, 4, -1, 2, 5, 7, -1, 5, -1, 4, 2, 0, -1],
    t1: [0, 0, -1, 0, 3, 3, -1, 3, 4, 4, -1, 4, 2, -1, 0, -1],
    t2: [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0],
    t3: [0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0]
  },
  {
    name: "NEON TRANCE",
    bpm: 140,
    t0: [4, -1, 4, 7, -1, 5, 4, -1, 2, -1, 2, 5, -1, 4, 2, 0],
    t1: [0, 4, 7, 4, 0, 4, 7, 4, 2, 5, 7, 5, 2, 5, 7, 5],
    t2: [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1],
    t3: [0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1]
  }
]

class GrooveboxScene
  def initialize
    @w = $cfg[:w]
    @h = $cfg[:h]
    @scope_surf = create_surface(160, 48, :gpu)
    clear_surface(@scope_surf, nil)

    @playing = true
    @bpm = $presets[0][:bpm]
    @step = 0
    @step_acc = 0.0
    @pulse = 0.0
    @t = 0.0
    @vj_mode = 0

    @lead_wave_idx = 0
    @bass_wave_idx = 3
    @scale_idx = 0
    @slot_idx = 0
    @vol_master = 0.85
    @vol_sfx = 0.85
    master_vol(@vol_master)
    sfx_vol(@vol_sfx)

    @cur_tr = 0
    @cur_st = 0
    @xy_active = false
    @xy_note = -1
    @scope_hist = []
    i = 0
    while i < 40
      @scope_hist << 0.0
      i += 1
    end

    @grid = [[], [], [], []]
    load_preset(0)
    @status_msg = "READY - CLICK GRID OR DRAG XY PAD!"
    @status_t = 120
  end

  def load_preset(idx)
    p = $presets[idx % $presets.size]
    @bpm = p[:bpm]
    @grid[0] = p[:t0].dup
    @grid[1] = p[:t1].dup
    @grid[2] = p[:t2].dup
    @grid[3] = p[:t3].dup
  end

  def save_to_slot(slot)
    data = {
      bpm: @bpm,
      lw: @lead_wave_idx,
      bw: @bass_wave_idx,
      sc: @scale_idx,
      g0: @grid[0],
      g1: @grid[1],
      g2: @grid[2],
      g3: @grid[3]
    }
    save_set("slot_#{slot}", data)
    sfx(:confirm, -1, 0.7, 1.2)
    @status_msg = "SAVED TO SLOT #{slot + 1}!"
    @status_t = 90
  end

  def load_from_slot(slot)
    data = save_get("slot_#{slot}", nil)
    if data
      @bpm = (data["bpm"] || 128).to_i
      @lead_wave_idx = (data["lw"] || 0).to_i
      @bass_wave_idx = (data["bw"] || 3).to_i
      @scale_idx = (data["sc"] || 0).to_i
      @grid[0] = (data["g0"] || $presets[0][:t0]).map { |v| v.to_i }
      @grid[1] = (data["g1"] || $presets[0][:t1]).map { |v| v.to_i }
      @grid[2] = (data["g2"] || $presets[0][:t2]).map { |v| v.to_i }
      @grid[3] = (data["g3"] || $presets[0][:t3]).map { |v| v.to_i }
      sfx(:powerup, -1, 0.7, 1.1)
      @status_msg = "LOADED SLOT #{slot + 1}!"
    else
      load_preset(slot)
      sfx(:select)
      @status_msg = "LOADED PRESET #{slot + 1}!"
    end
    @status_t = 90
  end

  def update
    @t += 0.045
    @pulse *= 0.86
    @status_t -= 1 if @status_t > 0

    handle_inputs

    if @playing
      # 16th-note step rate: bpm * 4 steps/min => (bpm * 4) / 3600 steps/frame
      @step_acc += (@bpm * 4.0) / 3600.0
      if @step_acc >= 1.0
        @step_acc -= 1.0
        @step = (@step + 1) % $cfg[:steps]
        trigger_step(@step)
      end
    end

    update_scope
  end

  def trigger_step(st)
    notes = $scales[@scale_idx][:notes]
    amp = 0.0

    # Track 0: Lead Synth
    n0 = @grid[0][st]
    if n0 >= 0
      freq = notes[n0 % notes.size] * 1.0
      tone(freq, 0.14, $waves[@lead_wave_idx], 0.42, 0.0)
      amp += 0.35
    end

    # Track 1: Bass / Arp (octave down)
    n1 = @grid[1][st]
    if n1 >= 0
      freq = notes[n1 % notes.size] * 0.5
      tone(freq, 0.16, $waves[@bass_wave_idx], 0.48, 0.0)
      amp += 0.35
    end

    # Track 2: Kick
    if @grid[2][st] > 0
      sfx(:drum_kick, -1, 0.78, 1.0)
      @pulse = 12.0
      amp += 0.55
    end

    # Track 3: Snare / Hat
    if @grid[3][st] > 0
      if (st % 4 == 2)
        sfx(:drum_snare, -1, 0.6, 1.0)
        amp += 0.4
      else
        sfx(:drum_hat, -1, 0.45, 1.15)
        amp += 0.2
      end
    end

    @scope_hist.shift
    @scope_hist << amp.clamp(0.0, 1.2)
  end

  def handle_inputs
    # Keyboard cursor navigation
    @cur_st = (@cur_st - 1 + 16) % 16 if btnp(:left)
    @cur_st = (@cur_st + 1) % 16 if btnp(:right)
    @cur_tr = (@cur_tr - 1 + 4) % 4 if btnp(:up)
    @cur_tr = (@cur_tr + 1) % 4 if btnp(:down)

    if btnp(1)
      toggle_cell(@cur_tr, @cur_st)
    end
    if btnp(2)
      @playing = !@playing
      sfx(:click)
    end

    # Mouse Wheel on sequencer cell changes pitch
    w = mouse_wheel
    if w != 0
      if @cur_tr < 2
        cur = @grid[@cur_tr][@cur_st]
        if cur < 0
          @grid[@cur_tr][@cur_st] = 0
        else
          @grid[@cur_tr][@cur_st] = (cur + (w > 0 ? 1 : -1) + 8) % 8
        end
        sfx(:click, -1, 0.4, 1.0 + @grid[@cur_tr][@cur_st] * 0.08)
      else
        @bpm = (@bpm + (w > 0 ? 4 : -4)).clamp(80, 180)
      end
    end

    mx = mouse_x
    my = mouse_y

    # XY Synth Pad (x: 326..466, y: 84..216)
    if btn(:mouse_l) && mx >= 326 && mx <= 466 && my >= 84 && my <= 216
      notes = $scales[@scale_idx][:notes]
      ni = (((mx - 326) / 140.0) * notes.size).to_i.clamp(0, notes.size - 1)
      slide = ((150 - my) * 0.9).to_f
      if !@xy_active || ni != @xy_note || (@step % 2 == 0 && @step_acc < 0.15)
        @xy_active = true
        @xy_note = ni
        tone(notes[ni], 0.14, $waves[@lead_wave_idx], 0.45, slide)
        @pulse = 8.0 if @pulse < 8.0
      end
    else
      @xy_active = false
      @xy_note = -1
    end

    return unless btnp(:mouse_l)

    # Top transport & mixer buttons
    if my >= 24 && my <= 46
      if mx >= 12 && mx <= 68
        @playing = !@playing
        sfx(:click)
      elsif mx >= 74 && mx <= 138
        @bpm = (@bpm >= 160 ? 96 : @bpm + 8)
        sfx(:select)
      elsif mx >= 144 && mx <= 232
        @lead_wave_idx = (@lead_wave_idx + 1) % $waves.size
        sfx(:select)
      elsif mx >= 238 && mx <= 326
        @scale_idx = (@scale_idx + 1) % $scales.size
        sfx(:select)
      elsif mx >= 332 && mx <= 400
        @vol_master = (@vol_master > 0.2 ? (@vol_master - 0.25) : 1.0).round(2)
        master_vol(@vol_master)
        sfx(:click)
      elsif mx >= 406 && mx <= 468
        @vj_mode = (@vj_mode + 1) % 2
        sfx(:select)
      end
      return
    end

    # Sequencer Grid (x: 56..312, y: 84..212 => 16x4 cells of 16x30)
    if mx >= 56 && mx < 312 && my >= 84 && my < 212
      st = ((mx - 56) / 16).to_i.clamp(0, 15)
      tr = ((my - 84) / 32).to_i.clamp(0, 3)
      @cur_st = st
      @cur_tr = tr
      toggle_cell(tr, st)
      return
    end

    # Bottom Save / Load Slots (y: 230..256)
    if my >= 230 && my <= 258
      if mx >= 16 && mx <= 236
        sl = ((mx - 16) / 55).to_i.clamp(0, 3)
        @slot_idx = sl
        load_from_slot(sl)
      elsif mx >= 246 && mx <= 326
        save_to_slot(@slot_idx)
      elsif mx >= 334 && mx <= 466
        @bass_wave_idx = (@bass_wave_idx + 1) % $waves.size
        sfx(:select)
      end
    end
  end

  def toggle_cell(tr, st)
    if tr < 2
      cur = @grid[tr][st]
      if cur < 0
        @grid[tr][st] = 0
        sfx(:click, -1, 0.5, 1.0)
      else
        nxt = cur + 2
        @grid[tr][st] = nxt >= 8 ? -1 : nxt
        sfx(:click, -1, 0.5, @grid[tr][st] >= 0 ? 1.2 : 0.7)
      end
    else
      @grid[tr][st] = (@grid[tr][st] == 0 ? 1 : 0)
      sfx(:click, -1, 0.5, @grid[tr][st] == 1 ? 1.3 : 0.8)
    end
  end

  def update_scope
    render_to(@scope_surf) do
      cls(0, 0.82)
      blend(:add)
      i = 0
      while i < @scope_hist.size - 1
        x0 = i * 4
        x1 = (i + 1) * 4
        a0 = @scope_hist[i]
        a1 = @scope_hist[i + 1]
        y0 = 24 + (sin(@t * 3.0 + i * 0.6) * (4.0 + a0 * 16.0)).to_i
        y1 = 24 + (sin(@t * 3.0 + (i + 1) * 0.6) * (4.0 + a1 * 16.0)).to_i
        line(x0, y0, x1, y1, 12, 2, 0.9)
        line(x0, y0 + 1, x1, y1 + 1, 14, 1, 0.6)
        i += 1
      end
      blend(:normal)
    end
  end

  def draw
    cls(0)
    draw_vj_backdrop
    draw_ui
  end

  def draw_vj_backdrop
    bg(:cyber, dim: 0.62, scroll_y: -@t * 14.0, mirror_y: true)
    blend(:add)
    if @vj_mode == 0
      # Evolved 29: 3D Neon Warp Tunnel reacting to audio pulse!
      k = 0
      while k < 9
        z = ((k * 22.0 - (@t * 28.0)) % 198.0)
        z += 198.0 if z < 0.0
        z = 10.0 if z < 10.0
        sc = 280.0 / z
        r = (14.0 * sc + @pulse * 1.4).to_i
        rot = @t * 0.45 + k * 0.14
        col = (k % 2 == 0) ? 12 : 14
        i = 0
        while i < 8
          a1 = rot + i * Math::PI * 0.25
          a2 = rot + (i + 1) * Math::PI * 0.25
          x1 = 240 + (cos(a1) * r).to_i
          y1 = 135 + (sin(a1) * r * 0.72).to_i
          x2 = 240 + (cos(a2) * r).to_i
          y2 = 135 + (sin(a2) * r * 0.72).to_i
          line(x1, y1, x2, y2, col, 2, 0.32)
          i += 1
        end
        k += 1
      end
    else
      # Pulsing plasma rings
      k = 0
      while k < 6
        r = ((@t * 36 + k * 32) % 210) + @pulse * 1.5
        circ(240, 135, r, k % 2 == 0 ? 12 : 14, 0.32)
        k += 1
      end
    end
    blend(:normal)
  end

  def draw_ui
    # Header
    rectfill(0, 0, @w, 20, 0, 0.85)
    print_text("SYNTH GROOVEBOX DX", 12, 6, 10, 8, 1.0, :left, 0)
    print_text(@status_t > 0 ? @status_msg : "Z:TOGGLE  X:PLAY/STOP  WHEEL:PITCH", 468, 6, 12, 8, 1.0, :right, 0)

    # Transport buttons (y: 24..46)
    draw_btn(12, 24, 56, 20, @playing ? "PLAY" : "STOP", @playing ? 11 : 8)
    draw_btn(74, 24, 64, 20, "BPM:#{@bpm}", 10)
    draw_btn(144, 24, 88, 20, "W:#{$waves[@lead_wave_idx].to_s.upcase[0, 6]}", 12)
    draw_btn(238, 24, 88, 20, $scales[@scale_idx][:name], 14)
    draw_btn(332, 24, 68, 20, "VOL:#{(@vol_master * 100).to_i}%", 7)
    draw_btn(406, 24, 62, 20, "VJ:#{@vj_mode + 1}", 13)

    # Oscilloscope (:gpu surface) & Beat bar
    rect(12, 50, 162, 28, 12, 1)
    draw_surface(@scope_surf, 13, 51, 1.0, nil, scale_x: 1.0, scale_y: 0.54)
    print_text("4-CH CHIPTUNE DAW + LIVE XY SYNTH", 326, 60, 7, 8, 1.0, :center, 0)

    # 4x16 Step Sequencer Grid
    labels = ["LEAD", "BASS", "KICK", "SNAR"]
    cols = [12, 11, 8, 10]
    tr = 0
    while tr < 4
      gy = 84 + tr * 32
      print_text(labels[tr], 12, gy + 10, cols[tr], 8, 1.0, :left, 0)
      st = 0
      while st < 16
        gx = 56 + st * 16
        v = @grid[tr][st]
        cur_play = (@playing && @step == st)
        sel = (@cur_tr == tr && @cur_st == st)
        bg_c = cur_play ? 2 : ((st / 4) % 2 == 0 ? 1 : 0)
        rectfill(gx + 1, gy + 2, 14, 26, bg_c, 0.88)

        if tr < 2 && v >= 0
          bh = 4 + (v * 3)
          rectfill(gx + 3, gy + 26 - bh, 10, bh, cols[tr])
        elsif tr >= 2 && v > 0
          rectfill(gx + 3, gy + 6, 10, 18, cols[tr])
        end

        rect(gx + 1, gy + 2, 14, 26, sel ? 10 : (cur_play ? 7 : 5), sel ? 2 : 1)
        st += 1
      end
      tr += 1
    end

    # XY Synth Pad (Right)
    rectfill(326, 84, 140, 132, 0, 0.85)
    rect(326, 84, 140, 132, @xy_active ? 10 : 14, 2)
    i = 1
    while i < 8
      line(326 + i * 17, 85, 326 + i * 17, 215, 1, 1, 0.55)
      i += 1
    end
    print_text("XY SYNTH PAD", 396, 92, 14, 8, 1.0, :center, 0)
    print_text("(DRAG TO PLAY)", 396, 104, 6, 8, 1.0, :center, 0)
    if @xy_active
      blend(:add)
      circfill(mouse_x.clamp(334, 458), mouse_y.clamp(92, 208), 14, 10, 0.65)
      blend(:normal)
    end

    # Bottom Slots & Bass Wave
    sl = 0
    while sl < 4
      bx = 16 + sl * 55
      draw_btn(bx, 232, 50, 22, "LOAD #{sl + 1}", @slot_idx == sl ? 10 : 12)
      sl += 1
    end
    draw_btn(246, 232, 80, 22, "SAVE SLOT", 11)
    draw_btn(334, 232, 132, 22, "BASS:#{$waves[@bass_wave_idx].to_s.upcase}", 11)
  end

  def draw_btn(x, y, w, h, txt, col)
    rectfill(x, y, w, h, 0, 0.88)
    rect(x, y, w, h, col, 1)
    print_text(txt, x + w / 2, y + (h - 8) / 2, col, 8, 1.0, :center, 0)
  end
end

run GrooveboxScene.new
__END__
@SFX :drum_kick
wave:triangle freq:145->42 dur:0.11 env:decay vol:0.85

@SFX :drum_snare
wave:noise freq:360->140 dur:0.10 env:decay vol:0.65

@SFX :drum_hat
wave:noise freq:980->720 dur:0.04 env:decay vol:0.45
