config(
  title: "FISHING ODYSSEY DX",
  width: 480,
  height: 270,
  save_id: "fishing_odyssey_dx",
  save_salt: "p3g48h5c"
)

$cfg = {
  w: 480,
  h: 270,
  water_y: 148,
  rod_max_lv: 5,
  bite_min: 45,
  bite_max: 110,
  hook_window: 50,
  reel_goal: 100.0
}

$seas = [
  { name: "TWILIGHT LAKE", bg: :mountain, tint: "#FF9B73", dim: 0.32, water_col: 1, dark: 0.0, unlock_g: 0 },
  { name: "CORAL REEF", bg: :sky, tint: "#80F0FF", dim: 0.30, water_col: 12, dark: 0.0, unlock_g: 120 },
  { name: "NIGHT HARBOR", bg: :city, tint: "#5070B8", dim: 0.48, water_col: 1, dark: 0.72, unlock_g: 300 },
  { name: "ABYSS TRENCH", bg: :cave, tint: "#584090", dim: 0.52, water_col: 0, dark: 0.86, unlock_g: 600 }
]

$fish_db = [
  { id: 0, sea: 0, name: "RIVER CARP", col: 9, diff: 1, price: 25, base_cm: 45 },
  { id: 1, sea: 0, name: "LAKE BASS", col: 11, diff: 1, price: 35, base_cm: 38 },
  { id: 2, sea: 0, name: "RAINBOW TROUT", col: 12, diff: 2, price: 55, base_cm: 52 },
  { id: 3, sea: 0, name: "GOLDEN KOI", col: 10, diff: 3, price: 95, base_cm: 68 },
  { id: 4, sea: 0, name: "LAKE EMPEROR", col: 8, diff: 4, price: 180, base_cm: 120 },

  { id: 5, sea: 1, name: "CLOWNFISH", col: 9, diff: 1, price: 40, base_cm: 14 },
  { id: 6, sea: 1, name: "BLUE TANG", col: 12, diff: 2, price: 65, base_cm: 28 },
  { id: 7, sea: 1, name: "LIONFISH", col: 14, diff: 2, price: 90, base_cm: 36 },
  { id: 8, sea: 1, name: "MANTA RAY", col: 13, diff: 3, price: 150, base_cm: 240 },
  { id: 9, sea: 1, name: "CORAL DRAGON", col: 11, diff: 4, price: 260, base_cm: 180 },

  { id: 10, sea: 2, name: "HARBOR EEL", col: 2, diff: 2, price: 75, base_cm: 90 },
  { id: 11, sea: 2, name: "NEON SQUID", col: 14, diff: 2, price: 110, base_cm: 42 },
  { id: 12, sea: 2, name: "MOON BREAM", col: 7, diff: 3, price: 145, base_cm: 55 },
  { id: 13, sea: 2, name: "SWORDFISH", col: 12, diff: 4, price: 240, base_cm: 290 },
  { id: 14, sea: 2, name: "STAR MARLIN", col: 10, diff: 5, price: 380, base_cm: 350 },

  { id: 15, sea: 3, name: "LANTERN FISH", col: 10, diff: 3, price: 140, base_cm: 25 },
  { id: 16, sea: 3, name: "GHOST SHARK", col: 6, diff: 3, price: 210, base_cm: 160 },
  { id: 17, sea: 3, name: "VAMPIRE SQUID", col: 8, diff: 4, price: 320, base_cm: 75 },
  { id: 18, sea: 3, name: "OARFISH", col: 14, diff: 4, price: 480, base_cm: 520 },
  { id: 19, sea: 3, name: "LEVIATHAN", col: 10, diff: 5, price: 900, base_cm: 880 }
]

class TitleScene
  def initialize
    @dex = save_get("dex", {})
    @gold = save_get("gold", 0).to_i
    @rod_lv = save_get("rod_lv", 1).to_i
    @tick = 0
  end

  def update
    @tick += 1
    if btnp(4) || btnp(5) || btnp(:mouse_l)
      run FishingScene.new
    end
  end

  def draw
    cls(0)
    bg(:mountain, dim: 0.35, tint: "#FF9870", scroll_x: @tick * 0.15, mirror_x: true)
    rectfill(0, 160, 480, 110, 1, 0.85)
    line(0, 160, 480, 160, 9, 2)
    spr(:angler, 90, 136)

    print_text("FISHING ODYSSEY DX", 240, 36, 10, 16, 1.0, :center, 0, 2)
    print_text("4 SEAS & 20-SPECIES ENCYCLOPEDIA", 240, 62, 7, 8, 1.0, :center, 0)

    caught_cnt = @dex.keys.size
    print_text("DEX: #{caught_cnt}/20   GOLD: #{@gold}G   ROD LV:#{@rod_lv}", 240, 96, 12, 8, 1.0, :center, 0)

    rectfill(140, 184, 200, 28, 1, 0.9)
    rect(140, 184, 200, 28, 10, 2)
    print_text("PRESS Z / CLICK TO SAIL", 240, 194, 10, 8, 1.0, :center, 0)

    print_text("Z/CLICK/WHEEL: CAST, HOOK & REEL | X: FISH DEX | LEFT/RIGHT: SEA", 240, 240, 7, 8, 1.0, :center, 0)
  end
end

class FishingScene
  def initialize
    @gold = save_get("gold", 0).to_i
    @rod_lv = save_get("rod_lv", 1).to_i
    @dex = save_get("dex", {})
    @unlocked_seas = save_get("seas", [0])
    @sea_idx = 0

    @lightmap = create_surface($cfg[:w], $cfg[:h], :gpu)
    @state = :idle # :idle, :waiting, :bite, :reeling, :caught, :dex
    @tick = 0

    @bob_x = 260.0
    @bob_y = $cfg[:water_y].to_f
    @wait_t = 0
    @bite_t = 0

    @fish = nil
    @fish_cm = 0
    @fish_crown = false
    @bar_y = 50.0
    @bar_vy = 0.0
    @fish_y = 50.0
    @fish_vy = 0.0
    @prog = 35.0
    @msg = ""
    @msg_t = 0
    @swim_fish = []
    init_swim_fish
  end

  def init_swim_fish
    @swim_fish = []
    i = 0
    while i < 5
      @swim_fish << {
        x: 120.0 + rand(320),
        y: $cfg[:water_y] + 22.0 + rand(80),
        vx: (rand() < 0.5 ? -1.0 : 1.0) * (0.4 + rand() * 0.6),
        col: [9, 10, 11, 12, 14][rand(5)]
      }
      i += 1
    end
  end

  def update
    @tick += 1
    @msg_t -= 1 if @msg_t > 0

    # Ambient swimming fish
    @swim_fish.each do |sf|
      sf[:x] += sf[:vx]
      if sf[:x] < 90.0
        sf[:vx] = sf[:vx].abs
      elsif sf[:x] > 460.0
        sf[:vx] = -sf[:vx].abs
      end
    end

    if @state == :dex
      if btnp(5) || btnp(4) || btnp(:mouse_l)
        @state = :idle
      end
      return
    end

    if @state == :idle
      update_idle
    elsif @state == :waiting
      @wait_t -= 1
      if @wait_t <= 0
        pick_fish
        @state = :bite
        @bite_t = $cfg[:hook_window]
      elsif btnp(4) || btnp(:mouse_l)
        @state = :idle
      end
    elsif @state == :bite
      @bite_t -= 1
      if btnp(4) || btnp(:mouse_l) || mouse_wheel != 0.0
        @state = :reeling
        @bar_y = 50.0
        @bar_vy = 0.0
        @fish_y = 50.0
        @fish_vy = 0.0
        @prog = 35.0
      elsif @bite_t <= 0
        @msg = "ESCAPED..."
        @msg_t = 50
        @state = :idle
      end
    elsif @state == :reeling
      update_reeling
    elsif @state == :caught
      if btnp(4) || btnp(5) || btnp(:mouse_l)
        @state = :idle
      end
    end
  end

  def update_idle
    if btnp(0)
      change_sea(-1)
    elsif btnp(1)
      change_sea(1)
    end

    if btnp(5)
      @state = :dex
      return
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my <= 26
        if mx >= 260 && mx <= 360
          upgrade_rod
          return
        elsif mx >= 370 && mx <= 474
          @state = :dex
          return
        elsif mx < 240
          change_sea(1)
          return
        end
      end
    end

    if btnp(4) || btnp(:mouse_l)
      @state = :waiting
      @bob_x = 180.0 + rand(220)
      @bob_y = $cfg[:water_y].to_f
      @wait_t = $cfg[:bite_min] + rand($cfg[:bite_max] - $cfg[:bite_min])
    end
  end

  def change_sea(dir)
    n_idx = (@sea_idx + dir + $seas.size) % $seas.size
    if !@unlocked_seas.index(n_idx).nil?
      @sea_idx = n_idx
    else
      cost = $seas[n_idx][:unlock_g]
      if @gold >= cost
        @gold -= cost
        @unlocked_seas << n_idx
        @sea_idx = n_idx
        save_set("gold", @gold)
        save_set("seas", @unlocked_seas)
        @msg = "UNLOCKED #{$seas[n_idx][:name]}!"
        @msg_t = 70
      else
        @msg = "NEED #{cost}G FOR #{$seas[n_idx][:name]}"
        @msg_t = 60
      end
    end
  end

  def upgrade_rod
    return if @rod_lv >= $cfg[:rod_max_lv]
    cost = @rod_lv * 100
    if @gold >= cost
      @gold -= cost
      @rod_lv += 1
      save_set("gold", @gold)
      save_set("rod_lv", @rod_lv)
      @msg = "ROD UPGRADED TO LV.#{@rod_lv}!"
      @msg_t = 60
    else
      @msg = "NEED #{cost}G TO UPGRADE ROD"
      @msg_t = 50
    end
  end

  def pick_fish
    pool = []
    $fish_db.each do |f|
      pool << f if f[:sea] == @sea_idx
    end
    @fish = pool[rand(pool.size)]
    scale_f = 0.75 + rand() * 0.65
    @fish_cm = (@fish[:base_cm] * scale_f).to_i
    @fish_cm = 1 if @fish_cm < 1
    @fish_crown = (scale_f >= 1.28)
  end

  def update_reeling
    # Catch bar physics (Z / Click / Wheel moves bar up)
    wh = mouse_wheel
    if btn(4) || btn(:mouse_l) || wh != 0.0
      @bar_vy -= 0.42
      @bar_vy -= 0.8 if wh != 0.0
    else
      @bar_vy += 0.28
    end
    @bar_vy = @bar_vy.clamp(-3.5, 3.5)
    @bar_y = (@bar_y + @bar_vy).clamp(0.0, 100.0)

    # Fish erratic movement
    diff = @fish[:diff]
    if @tick % (22 - diff * 2) == 0
      @fish_vy = (rand() * 2.0 - 1.0) * (1.2 + diff * 0.45)
    end
    @fish_y = (@fish_y + @fish_vy).clamp(4.0, 96.0)
    @fish_vy = -@fish_vy if @fish_y <= 4.0 || @fish_y >= 96.0

    bar_half = 12.0 + @rod_lv * 2.5
    if (@fish_y - @bar_y).abs <= bar_half
      @prog += 0.55 + @rod_lv * 0.12
    else
      @prog -= 0.32
    end

    if @prog >= $cfg[:reel_goal]
      catch_success
    elsif @prog <= 0.0
      @msg = "LINE SNAPPED!"
      @msg_t = 60
      @state = :idle
    end
  end

  def catch_success
    @state = :caught
    val = @fish[:price] + (@fish_crown ? @fish[:price] / 2 : 0)
    @gold += val
    save_set("gold", @gold)

    fid = @fish[:id].to_s
    rec = @dex[fid]
    best_cm = rec ? rec["cm"].to_i : 0
    was_crown = rec ? rec["crown"] : false
    @dex[fid] = {
      "cm" => [@fish_cm, best_cm].max,
      "crown" => was_crown || @fish_crown
    }
    save_set("dex", @dex)
  end

  def draw
    cls(0)
    sea = $seas[@sea_idx]
    bg(sea[:bg], dim: sea[:dim], tint: sea[:tint], scroll_x: @tick * 0.12, mirror_x: true)

    wy = $cfg[:water_y]
    # Water
    rectfill(0, wy, 480, 270 - wy, sea[:water_col], 0.85)
    line(0, wy, 480, wy, 7, 2, 0.7)

    # Swimming fish
    @swim_fish.each do |sf|
      spr(:fish, sf[:x], sf[:y], sf[:vx] < 0)
    end

    # Pier & Angler
    rectfill(0, wy - 10, 96, 8, 4)
    rectfill(24, wy - 2, 6, 30, 4)
    rectfill(72, wy - 2, 6, 30, 4)
    spr(:angler, 68, wy - 26)

    # Fishing line & bobber
    if @state == :waiting || @state == :bite || @state == :reeling
      rod_x = 84
      rod_y = wy - 22
      by = @bob_y + (@state == :bite ? sin(@tick * 0.6) * 4.0 : sin(@tick * 0.1) * 1.5)
      line(rod_x, rod_y, @bob_x, by, 7, 1, 0.75)
      circfill(@bob_x, by, 3, @state == :bite ? 10 : 8)
      if @state == :bite
        print_text("HIT! Z / CLICK!", @bob_x, by - 16, 10, 8, 1.0, :center, 0)
      end
    end

    # Night Harbor / Abyss Trench :gpu Lightmap!
    if sea[:dark] > 0.0
      render_to(@lightmap) do
        cls(0, sea[:dark])
        blend(:erase)
        # Angler lantern
        circfill(76, wy - 18, 72, 0, 0.45)
        circfill(76, wy - 18, 42, 0, 0.95)
        # Bobber / lure glow
        if @state != :idle
          circfill(@bob_x, @bob_y, 56, 0, 0.5)
          circfill(@bob_x, @bob_y, 28, 0, 0.9)
        end
        # Bioluminescent fish
        @swim_fish.each do |sf|
          circfill(sf[:x] + 8, sf[:y] + 8, 22, 0, 0.65)
        end
        blend(:normal)
      end
      draw_surface(@lightmap, 0, 0)
    end

    draw_hud

    if @state == :reeling
      draw_reeling_ui
    elsif @state == :caught
      draw_caught_modal
    elsif @state == :dex
      draw_dex_modal
    end
  end

  def draw_hud
    rectfill(0, 0, 480, 26, 0, 0.85)
    sea = $seas[@sea_idx]
    print_text("< #{sea[:name]} >", 110, 8, 10, 8, 1.0, :center, 0)
    print_text("GOLD:#{@gold}G", 230, 8, 10, 8, 1.0, :center, 0)

    ucost = @rod_lv >= $cfg[:rod_max_lv] ? "MAX" : "#{@rod_lv * 100}G"
    rectfill(274, 4, 90, 18, 1)
    rect(274, 4, 90, 18, 12, 1)
    print_text("ROD LV#{@rod_lv}(#{ucost})", 319, 9, 12, 8, 1.0, :center, 0)

    rectfill(374, 4, 98, 18, 1)
    rect(374, 4, 98, 18, 11, 1)
    print_text("DEX #{@dex.keys.size}/20 (X)", 423, 9, 11, 8, 1.0, :center, 0)

    if @msg_t > 0
      print_text(@msg, 240, 42, 10, 8, 1.0, :center, 0)
    end
  end

  def draw_reeling_ui
    bx = 420
    by = 50
    bh = 160
    rectfill(bx, by, 26, bh, 0, 0.85)
    rect(bx, by, 26, bh, 7, 2)

    # Green catch bar
    bar_half = (12.0 + @rod_lv * 2.5) * 1.5
    cy = by + bh - (@bar_y / 100.0 * bh)
    rectfill(bx + 3, (cy - bar_half).clamp(by + 2, by + bh - 6), 20, (bar_half * 2).to_i, 11, 0.75)

    # Fish marker
    fy = by + bh - (@fish_y / 100.0 * bh)
    circfill(bx + 13, fy, 5, @fish[:col])
    circ(bx + 13, fy, 5, 7)

    # Progress bar
    rectfill(bx + 30, by, 8, bh, 1)
    ph = (@prog / $cfg[:reel_goal] * bh).to_i
    rectfill(bx + 30, by + bh - ph, 8, ph, 10)
    rect(bx + 30, by, 8, bh, 7)

    print_text("HOLD Z/WHEEL!", 420, 36, 10, 8, 1.0, :center, 0)
  end

  def draw_caught_modal
    rectfill(120, 74, 240, 110, 0, 0.92)
    rect(120, 74, 240, 110, 10, 2)
    crown = @fish_crown ? " [CROWN!]" : ""
    print_text("CAUGHT: #{@fish[:name]}!", 240, 90, @fish[:col], 8, 1.0, :center, 0)
    print_text("SIZE: #{@fish_cm}cm#{crown}", 240, 112, 7, 8, 1.0, :center, 0)
    val = @fish[:price] + (@fish_crown ? @fish[:price] / 2 : 0)
    print_text("VALUE: +#{val}G", 240, 130, 10, 8, 1.0, :center, 0)
    print_text("PRESS Z / CLICK", 240, 156, 12, 8, 1.0, :center, 0)
  end

  def draw_dex_modal
    rectfill(24, 30, 432, 224, 0, 0.94)
    rect(24, 30, 432, 224, 11, 2)
    print_text("FISH ENCYCLOPEDIA (#{@dex.keys.size}/20)", 240, 40, 10, 8, 1.0, :center, 0)

    i = 0
    while i < $fish_db.size
      f = $fish_db[i]
      col_i = i / 10
      row_i = i % 10
      x = 40 + col_i * 212
      y = 60 + row_i * 17
      rec = @dex[f[:id].to_s]
      if rec
        cr = rec["crown"] ? "*" : ""
        print_text("#{f[:name]} #{rec["cm"]}cm#{cr}", x, y, f[:col], 8, 1.0, :left, 0)
      else
        print_text("??? (SEA #{f[:sea] + 1})", x, y, 5, 8, 1.0, :left, 0)
      end
      i += 1
    end
    print_text("PRESS X / Z / CLICK TO CLOSE", 240, 236, 7, 8, 1.0, :center, 0)
  end
end

run TitleScene.new

__END__
@PALETTE 1
0: #000000
1: #182038
4: #AB5236
7: #FFF1E8
8: #FF2E54
9: #FF9922
A: #FFEC27
C: #29ADFF
F: #FFCCAA

@SPRITE :angler 16x16 pal:1
................
.....44444......
....4444444.....
...44FFFFF44....
....1F0FF0F1....
....1FFFFFF1....
.....188881.....
....18888881....
...1888888881...
....11111111....
....111..111....
....111..111....
....444..444....
................
................
................

@SPRITE :fish 16x16 pal:1
................
................
................
................
......1111......
....11CCCC11....
..11CC7CCCCC11..
.1C1CCCCCCCCCC1.
.1CC1CCCCCCCC1..
..11CCCCCCCC11..
....11CCCC11....
......1111......
................
................
................
................
