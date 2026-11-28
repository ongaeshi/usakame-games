config(
  title: "CHROMA CHAIN DUEL",
  width: 480,
  height: 270,
  save_id: "chroma_chain_duel",
  save_salt: "p4g57cd6"
)

$cfg = {
  w: 480,
  h: 270,
  cols: 6,
  rows: 12,
  ts: 16,
  p1_ox: 48,
  p2_ox: 336,
  board_oy: 48,
  gem_colors: 4,
  base_fall_frames: 34,
  chain_pause_frames: 16
}

$rivals = [
  { name: "APPRENTICE", think_iv: 24, bg: :cyber, tint: "#3080C0" },
  { name: "PRISM MAGE", think_iv: 16, bg: :space, tint: "#8040C0" },
  { name: "GRAND MASTER", think_iv: 10, bg: :cyber, tint: "#D03060" }
]

class TitleScene
  def initialize
    @wins = save_get("wins", 0)
    @max_chain = save_get("max_chain", 0)
    @best_score = save_get("best_score", 0)
    @mode = 0 # 0: 1P VS CPU, 1: 2P LOCAL DUEL
    @rival = 0
    @tick = 0
    music(:duel_bgm, true, 0.65)
  end

  def update
    @tick += 1
    if btnp(:up) || btnp(:down)
      @mode = (@mode + 1) % 2
      sfx(:select)
    end
    if btnp(:left)
      @rival = (@rival - 1 + $rivals.size) % $rivals.size
      sfx(:select)
    elsif btnp(:right)
      @rival = (@rival + 1) % $rivals.size
      sfx(:select)
    end

    if btnp(:mouse_l)
      mx = mouse_x
      my = mouse_y
      if my >= 110 && my <= 136 && mx >= 120 && mx <= 360
        @mode = 0
        start_game
        return
      elsif my >= 144 && my <= 170 && mx >= 120 && mx <= 360
        @mode = 1
        start_game
        return
      end
    end

    start_game if btnp(1) || btnp(2)
  end

  def start_game
    sfx(:confirm)
    run DuelScene.new({ two_p: @mode == 1, rival_idx: @rival })
  end

  def draw
    cls(0)
    bg(:cyber, dim: 0.48, tint: "#6838B0", scroll_x: @tick * 0.25, mirror_x: true)

    # Decorative bouncing gems on sides
    gem_xs = [38, 74, 382, 418]
    g = 0
    while g < 4
      gx = gem_xs[g]
      gy = 28 + (sin(@tick * 0.08 + g * 1.2) * 8).to_i
      spr(spr_id(:gem, g), gx, gy, false, nil, 0.0, 1.5)
      g += 1
    end

    print_text("CHROMA CHAIN DUEL", 240, 20, 10, 16, 1.0, :center, 0, 2)
    print_text("4-LINK CASCADE PUZZLE BATTLE", 240, 44, 12, 8, 1.0, :center, 0)

    rank = @wins >= 10 ? "S-CLASS" : (@wins >= 5 ? "A-CLASS" : (@wins >= 2 ? "B-CLASS" : "ROOKIE"))
    print_text("RANK: #{rank}   WINS: #{@wins}   MAX CHAIN: #{@max_chain}   HI: #{@best_score}", 240, 74, 11, 8, 1.0, :center, 0)

    draw_opt(120, 110, 240, 26, "1P VS CPU (#{$rivals[@rival][:name]})", @mode == 0)
    draw_opt(120, 144, 240, 26, "2P LOCAL VERSUS (1P:Z/X  2P:IJKL+U/O)", @mode == 1)

    print_text("LEFT/RIGHT: CPU LEVEL   Z: START BATTLE", 240, 204, 10, 8, 1.0, :center, 0)
    print_text("ARROWS: MOVE/DROP   Z/X: ROTATE   UP: HARD DROP", 240, 232, 6, 8, 1.0, :center, 0)
  end

  def draw_opt(x, y, w, h, txt, sel)
    rectfill(x, y, w, h, sel ? 1 : 0, 0.88)
    rect(x, y, w, h, sel ? 10 : 5, sel ? 2 : 1)
    print_text(txt, x + w / 2, y + 9, sel ? 10 : 7, 8, 1.0, :center, 0)
  end
end

class BoardState
  attr_accessor :grid, :ox, :oy, :player_id, :score, :pending_junk
  attr_accessor :cur_x, :cur_y, :cur_rot, :cur_a, :cur_b, :next_a, :next_b
  attr_accessor :fall_t, :state, :pause_t, :chain, :lost, :think_t, :target_x, :target_rot

  def initialize(ox, oy, player_id)
    @ox = ox
    @oy = oy
    @player_id = player_id
    @cols = $cfg[:cols]
    @rows = $cfg[:rows]
    @grid = []
    r = 0
    while r < @rows
      row = []
      c = 0
      while c < @cols
        row << nil
        c += 1
      end
      @grid << row
      r += 1
    end

    @score = 0
    @pending_junk = 0
    @chain = 0
    @lost = false
    @state = :drop # :drop, :resolve, :fall_anim
    @fall_t = 0
    @pause_t = 0
    @think_t = 0
    @target_x = 2
    @target_rot = 0

    @next_a = rand($cfg[:gem_colors])
    @next_b = rand($cfg[:gem_colors])
    spawn_pair
  end

  def spawn_pair
    @cur_a = @next_a
    @cur_b = @next_b
    @next_a = rand($cfg[:gem_colors])
    @next_b = rand($cfg[:gem_colors])
    @cur_x = 2
    @cur_y = 0
    @cur_rot = 0 # 0: b above a, 1: b right of a, 2: b below a, 3: b left of a
    @fall_t = $cfg[:base_fall_frames]
    @chain = 0

    if @grid[0][2] != nil || @grid[1][2] != nil
      @lost = true
    end
  end

  def pair_cells(cx = @cur_x, cy = @cur_y, rot = @cur_rot)
    dx = 0
    dy = -1
    if rot == 1
      dx = 1
      dy = 0
    elsif rot == 2
      dx = 0
      dy = 1
    elsif rot == 3
      dx = -1
      dy = 0
    end
    [[cx, cy, @cur_a], [cx + dx, cy + dy, @cur_b]]
  end

  def valid_pos?(cx, cy, rot)
    cells = pair_cells(cx, cy, rot)
    i = 0
    while i < cells.size
      x = cells[i][0]
      y = cells[i][1]
      return false if x < 0 || x >= @cols || y >= @rows
      return false if y >= 0 && @grid[y][x] != nil
      i += 1
    end
    true
  end

  def lock_pair
    cells = pair_cells
    i = 0
    while i < cells.size
      x = cells[i][0]
      y = cells[i][1]
      if y >= 0 && y < @rows && x >= 0 && x < @cols
        @grid[y][x] = cells[i][2]
      end
      i += 1
    end
    apply_gravity_instant
    @state = :resolve
    @pause_t = 8
  end

  def apply_gravity_instant
    c = 0
    while c < @cols
      write_r = @rows - 1
      r = @rows - 1
      while r >= 0
        if @grid[r][c] != nil
          val = @grid[r][c]
          @grid[r][c] = nil
          @grid[write_r][c] = val
          write_r -= 1
        end
        r -= 1
      end
      c += 1
    end
  end

  def danger_level
    r = 0
    while r < 4
      c = 0
      while c < @cols
        return true if @grid[r][c] != nil
        c += 1
      end
      r += 1
    end
    false
  end
end

class DuelScene
  def initialize(opts)
    @two_p = opts[:two_p]
    @rival_idx = opts[:rival_idx] || 0
    @rival = $rivals[@rival_idx]
    @w = $cfg[:w]
    @h = $cfg[:h]

    @b1 = BoardState.new($cfg[:p1_ox], $cfg[:board_oy], 0)
    @b2 = BoardState.new($cfg[:p2_ox], $cfg[:board_oy], 1)

    @bolts = []
    @particles = []
    @popups = []
    @shake = 0.0
    @pinch_bgm = false
    @max_chain_run = 0
    @winner = nil
    @state_t = 0

    music(:duel_bgm, true, 0.68)
  end

  def update
    if @winner
      @state_t += 1
      if @state_t > 35 && (btnp(1) || btnp(2) || btnp(:mouse_l))
        run TitleScene.new
      end
      return
    end

    @shake *= 0.82
    @shake = 0.0 if @shake < 0.2

    update_board(@b1, @b2, true)
    update_board(@b2, @b1, @two_p)

    # Dynamic Pinch BGM toggle
    pinch_now = @b1.danger_level || @b2.danger_level
    if pinch_now && !@pinch_bgm
      @pinch_bgm = true
      music(:pinch_bgm, true, 0.72)
    elsif !pinch_now && @pinch_bgm
      @pinch_bgm = false
      music(:duel_bgm, true, 0.68)
    end

    update_fx

    if @b1.lost || @b2.lost
      @winner = @b1.lost ? 2 : 1
      stop_music
      sfx(@winner == 1 ? :clear : :gameover)
      if @winner == 1
        save_set("wins", save_get("wins", 0) + 1)
      end
      mc = save_get("max_chain", 0)
      save_set("max_chain", @max_chain_run) if @max_chain_run > mc
      bs = save_get("best_score", 0)
      save_set("best_score", @b1.score) if @b1.score > bs
      @state_t = 0
    end
  end

  def update_board(b, opp, is_human)
    return if b.lost

    if b.state == :drop
      if is_human
        pid = b.player_id
        if btnp(:left, pid) && b.valid_pos?(b.cur_x - 1, b.cur_y, b.cur_rot)
          b.cur_x -= 1
          sfx(:click, -1, 0.35, 1.0)
        elsif btnp(:right, pid) && b.valid_pos?(b.cur_x + 1, b.cur_y, b.cur_rot)
          b.cur_x += 1
          sfx(:click, -1, 0.35, 1.0)
        end

        if btnp(1, pid)
          nr = (b.cur_rot + 1) % 4
          if b.valid_pos?(b.cur_x, b.cur_y, nr)
            b.cur_rot = nr
            sfx(:click, -1, 0.4, 1.2)
          end
        elsif btnp(2, pid)
          nr = (b.cur_rot + 3) % 4
          if b.valid_pos?(b.cur_x, b.cur_y, nr)
            b.cur_rot = nr
            sfx(:click, -1, 0.4, 1.1)
          end
        end

        if btnp(:up, pid)
          while b.valid_pos?(b.cur_x, b.cur_y + 1, b.cur_rot)
            b.cur_y += 1
          end
          b.lock_pair
          sfx(:step, -1, 0.5, 0.9)
          return
        end

        fast = btn(:down, pid)
        b.fall_t -= (fast ? 8 : 1)
      else
        step_cpu(b)
        b.fall_t -= 2
      end

      if b.fall_t <= 0
        b.fall_t = $cfg[:base_fall_frames]
        if b.valid_pos?(b.cur_x, b.cur_y + 1, b.cur_rot)
          b.cur_y += 1
        else
          b.lock_pair
          sfx(:step, -1, 0.45, 0.9)
        end
      end
    elsif b.state == :resolve
      b.pause_t -= 1
      if b.pause_t <= 0
        cleared = resolve_matches(b, opp)
        if cleared > 0
          b.pause_t = $cfg[:chain_pause_frames]
        else
          # Drop pending junk onto this board before spawning next pair
          drop_junk(b) if b.pending_junk > 0
          b.spawn_pair
          b.state = :drop
        end
      end
    end
  end

  def step_cpu(b)
    b.think_t -= 1
    return if b.think_t > 0
    b.think_t = @rival[:think_iv]

    # Simple greedy column matcher
    if b.cur_y <= 1
      best_x = rand($cfg[:cols])
      best_score = -1
      c = 0
      while c < $cfg[:cols]
        r = 0
        while r < $cfg[:rows] && b.grid[r][c] == nil
          r += 1
        end
        sc = r
        sc += 6 if r < $cfg[:rows] && b.grid[r][c] == b.cur_a
        if sc > best_score
          best_score = sc
          best_x = c
        end
        c += 1
      end
      b.target_x = best_x
    end

    if b.cur_x < b.target_x && b.valid_pos?(b.cur_x + 1, b.cur_y, b.cur_rot)
      b.cur_x += 1
    elsif b.cur_x > b.target_x && b.valid_pos?(b.cur_x - 1, b.cur_y, b.cur_rot)
      b.cur_x -= 1
    end
  end

  def resolve_matches(b, opp)
    cols = $cfg[:cols]
    rows = $cfg[:rows]
    grid = b.grid
    visited = []
    r = 0
    while r < rows
      visited << [false, false, false, false, false, false]
      r += 1
    end

    to_clear = []
    r = 0
    while r < rows
      c = 0
      while c < cols
        col_val = grid[r][c]
        if col_val != nil && col_val != 9 && !visited[r][c]
          group = []
          stack = [[c, r]]
          visited[r][c] = true
          while !stack.empty?
            pt = stack.pop
            px = pt[0]
            py = pt[1]
            group << [px, py]
            dirs = [[1, 0], [-1, 0], [0, 1], [0, -1]]
            di = 0
            while di < 4
              nx = px + dirs[di][0]
              ny = py + dirs[di][1]
              if nx >= 0 && nx < cols && ny >= 0 && ny < rows && !visited[ny][nx] && grid[ny][nx] == col_val
                visited[ny][nx] = true
                stack << [nx, ny]
              end
              di += 1
            end
          end
          if group.size >= 4
            gi = 0
            while gi < group.size
              to_clear << group[gi]
              gi += 1
            end
          end
        end
        c += 1
      end
      r += 1
    end

    return 0 if to_clear.empty?

    b.chain += 1
    @max_chain_run = b.chain if b.chain > @max_chain_run && b.player_id == 0

    # Clear matched gems + adjacent junk gems (val == 9)
    junk_clear = []
    i = 0
    while i < to_clear.size
      pt = to_clear[i]
      cx = pt[0]
      cy = pt[1]
      col_id = grid[cy][cx]
      grid[cy][cx] = nil
      spawn_gem_sparks(b.ox + cx * 16 + 8, b.oy + cy * 16 + 8, col_id)
      dirs = [[1, 0], [-1, 0], [0, 1], [0, -1]]
      di = 0
      while di < 4
        nx = cx + dirs[di][0]
        ny = cy + dirs[di][1]
        if nx >= 0 && nx < cols && ny >= 0 && ny < rows && grid[ny][nx] == 9
          junk_clear << [nx, ny]
        end
        di += 1
      end
      i += 1
    end

    i = 0
    while i < junk_clear.size
      jp = junk_clear[i]
      if grid[jp[1]][jp[0]] == 9
        grid[jp[1]][jp[0]] = nil
        spawn_gem_sparks(b.ox + jp[0] * 16 + 8, b.oy + jp[1] * 16 + 8, 5)
      end
      i += 1
    end

    b.apply_gravity_instant
    pts = to_clear.size * 25 * b.chain * b.chain
    b.score += pts

    # Pitch-rising bell chain SFX!
    pitch = (1.0 + (b.chain - 1) * 0.14).clamp(1.0, 2.5)
    sfx(:bell, -1, 0.88, pitch)
    @shake = 3.0 + b.chain * 1.5 if b.chain >= 2

    # Send junk & cast lightning bolt to opponent
    junk_send = b.chain >= 2 ? (b.chain * 2 + (to_clear.size - 4)) : 1
    if b.pending_junk > 0
      cancel = [b.pending_junk, junk_send].min
      b.pending_junk -= cancel
      junk_send -= cancel
    end
    if junk_send > 0
      opp.pending_junk += junk_send
      @bolts << { x0: b.ox + 48, y0: b.oy + 60, x1: opp.ox + 48, y1: opp.oy + 24, t: 16, col: b.chain >= 2 ? 10 : 12 }
    end

    @popups << { x: b.ox + 48, y: b.oy + 70, txt: "#{b.chain} CHAIN!", col: 10, t: 38 }
    to_clear.size
  end

  def drop_junk(b)
    cnt = [b.pending_junk, 12].min
    b.pending_junk -= cnt
    i = 0
    while i < cnt
      c = (i + rand($cfg[:cols])) % $cfg[:cols]
      if b.grid[0][c] == nil
        b.grid[0][c] = 9
      end
      i += 1
    end
    b.apply_gravity_instant
    sfx(:hit, -1, 0.65, 0.75)
  end

  def spawn_gem_sparks(x, y, col_id)
    cols = [8, 12, 11, 10, 6, 7]
    c = cols[col_id % cols.size]
    i = 0
    while i < 5
      a = rand * Math::PI * 2.0
      sp = 0.8 + rand * 2.0
      @particles << { x: x.to_f, y: y.to_f, vx: cos(a) * sp, vy: sin(a) * sp, col: c, t: 16 }
      i += 1
    end
  end

  def update_fx
    i = @bolts.size - 1
    while i >= 0
      @bolts[i][:t] -= 1
      @bolts.delete_at(i) if @bolts[i][:t] <= 0
      i -= 1
    end
    i = @particles.size - 1
    while i >= 0
      pt = @particles[i]
      pt[:x] += pt[:vx]
      pt[:y] += pt[:vy]
      pt[:t] -= 1
      @particles.delete_at(i) if pt[:t] <= 0
      i -= 1
    end
    i = @popups.size - 1
    while i >= 0
      @popups[i][:y] -= 0.45
      @popups[i][:t] -= 1
      @popups.delete_at(i) if @popups[i][:t] <= 0
      i -= 1
    end
  end

  def draw
    cls(0)
    bg(@rival[:bg], dim: 0.52, tint: @rival[:tint])

    sx = @shake > 0 ? (rand * @shake * 2.0 - @shake) : 0.0
    sy = @shake > 0 ? (rand * @shake * 2.0 - @shake) : 0.0
    camera(sx, sy)

    draw_board(@b1, "1P")
    draw_board(@b2, @two_p ? "2P" : "CPU")
    draw_center_panel
    draw_fx

    camera
    blend(:normal)
    draw_win_overlay if @winner
  end

  def draw_board(b, label)
    bw = $cfg[:cols] * 16
    bh = $cfg[:rows] * 16
    rectfill(b.ox, b.oy, bw, bh, 0, 0.85)
    rect(b.ox - 2, b.oy - 2, bw + 4, bh + 4, b.danger_level ? 8 : 12, 2)

    print_text(label, b.ox + bw / 2, 16, 10, 8, 1.0, :center, 0)
    print_text("SCORE #{b.score}", b.ox + bw / 2, 28, 7, 8, 1.0, :center, 0)

    if b.pending_junk > 0
      print_text("WARN: #{b.pending_junk}", b.ox + bw / 2, b.oy - 12, 8, 8, 1.0, :center, 0)
    end

    r = 0
    while r < $cfg[:rows]
      c = 0
      while c < $cfg[:cols]
        v = b.grid[r][c]
        if v != nil
          gx = b.ox + c * 16
          gy = b.oy + r * 16
          if v == 9
            spr(:junk, gx, gy)
          else
            spr(spr_id(:gem, v), gx, gy)
          end
        end
        c += 1
      end
      r += 1
    end

    if b.state == :drop && !b.lost
      cells = b.pair_cells
      i = 0
      while i < cells.size
        cx = cells[i][0]
        cy = cells[i][1]
        if cy >= 0
          spr(spr_id(:gem, cells[i][2]), b.ox + cx * 16, b.oy + cy * 16)
        end
        i += 1
      end
    end

    # Next pair box
    nx = (b.player_id == 0) ? (b.ox + bw + 12) : (b.ox - 36)
    rectfill(nx, b.oy, 24, 44, 0, 0.85)
    rect(nx, b.oy, 24, 44, 12, 1)
    print_text("NEXT", nx + 12, b.oy + 2, 7, 8, 1.0, :center, 0)
    spr(spr_id(:gem, b.next_b), nx + 4, b.oy + 11)
    spr(spr_id(:gem, b.next_a), nx + 4, b.oy + 27)
  end

  def draw_center_panel
    print_text("VS", 240, 120, 10, 16, 1.0, :center, 0)
    if @pinch_bgm
      print_text("PINCH!", 240, 148, 8, 8, 1.0, :center, 0)
    end
  end

  def draw_fx
    blend(:add)
    i = 0
    while i < @bolts.size
      bt = @bolts[i]
      mx = (bt[:x0] + bt[:x1]) * 0.5 + rand(24) - 12
      my = (bt[:y0] + bt[:y1]) * 0.5 + rand(24) - 12
      line(bt[:x0], bt[:y0], mx, my, bt[:col], 3, 0.9)
      line(mx, my, bt[:x1], bt[:y1], bt[:col], 3, 0.9)
      line(bt[:x0], bt[:y0], mx, my, 7, 1, 1.0)
      line(mx, my, bt[:x1], bt[:y1], 7, 1, 1.0)
      i += 1
    end

    i = 0
    while i < @particles.size
      pt = @particles[i]
      circfill(pt[:x], pt[:y], 2, pt[:col], 0.9)
      i += 1
    end
    blend(:normal)

    i = 0
    while i < @popups.size
      p = @popups[i]
      print_text(p[:txt], p[:x], p[:y], p[:col], 8, 1.0, :center, 0)
      i += 1
    end
  end

  def draw_win_overlay
    rectfill(120, 82, 240, 100, 0, 0.92)
    rect(120, 82, 240, 100, 10, 2)
    msg = @winner == 1 ? "PLAYER 1 WINS!" : (@two_p ? "PLAYER 2 WINS!" : "CPU WINS!")
    print_text(msg, 240, 102, 10, 16, 1.0, :center, 0)
    print_text("MAX CHAIN: #{@max_chain_run}", 240, 134, 11, 8, 1.0, :center, 0)
    print_text("PRESS Z OR X TO RETURN", 240, 156, 7, 8, 1.0, :center, 0)
  end
end

run TitleScene.new
__END__
@PALETTE 1
1: #18182E
5: #505870
6: #B4C4DC
7: #FFFFFF
8: #FF2454
A: #FFE438
B: #30E870
C: #30B8FF

@SPRITE :gem 16x16 pal:1
....11111111....
..118888888811..
.18877888888881.
.18788888888881.
1888888778888881
1888887777888881
1888888778888881
1888888888888881
1888888888888881
1888888888888881
.18888888888881.
.18888888888881.
..118888888811..
....11111111....
................
................
---
....11111111....
..11CCCCCCCC11..
.1CC77CCCCCCCC1.
.1C7CCCCCCCCCC1.
1CCCCCC77CCCCCC1
1CCCCC7777CCCCC1
1CCCCCC77CCCCCC1
1CCCCCCCCCCCCCC1
1CCCCCCCCCCCCCC1
1CCCCCCCCCCCCCC1
.1CCCCCCCCCCCC1.
.1CCCCCCCCCCCC1.
..11CCCCCCCC11..
....11111111....
................
................
---
....11111111....
..11BBBBBBBB11..
.1BB77BBBBBBBB1.
.1B7BBBBBBBBBB1.
1BBBBBB77BBBBBB1
1BBBBB7777BBBBB1
1BBBBBB77BBBBBB1
1BBBBBBBBBBBBBB1
1BBBBBBBBBBBBBB1
1BBBBBBBBBBBBBB1
.1BBBBBBBBBBBB1.
.1BBBBBBBBBBBB1.
..11BBBBBBBB11..
....11111111....
................
................
---
....11111111....
..11AAAAAAAA11..
.1AA77AAAAAAAA1.
.1A7AAAAAAAAAA1.
1AAAAAA77AAAAAA1
1AAAAA7777AAAAA1
1AAAAAA77AAAAAA1
1AAAAAAAAAAAAAA1
1AAAAAAAAAAAAAA1
1AAAAAAAAAAAAAA1
.1AAAAAAAAAAAA1.
.1AAAAAAAAAAAA1.
..11AAAAAAAA11..
....11111111....
................
................

@SPRITE :junk 16x16 pal:1
...1111111111...
..166666666651..
.16776666665551.
1676665556655551
1666651115665551
1666516661565551
1666516661565551
1666651115665551
1666665556655551
1555666666555551
.15555555555551.
..115555555511..
....11111111....
................
................
................

@MUSIC :duel_bgm
ch0 wave=pulse vol=4 T132 L8 O4 e g b > d c < b g e  c e g b a g e c  d f# a > c < b a f# d  e g b > e < b g e4
ch1 wave=tri vol=5 T132 L4 O2 e b c g  d a e b
ch2 wave=noise vol=2 T132 L8 O6 c r c r c r c c  c r c r c r c c

@MUSIC :pinch_bgm
ch0 wave=saw vol=4 T164 L8 O4 e > e < e > e < d > d < d > d  < c > c < c > c < b > b < b > b
ch1 wave=tri vol=6 T164 L8 O2 e e g e d d f d  c c e c b b d b
ch2 wave=noise vol=3 T164 L8 O6 c c c c c c c c  c c c c c c c c
