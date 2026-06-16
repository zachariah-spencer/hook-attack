class Game
  attr_dr

  MIN_ROCK_SPAWN_DELAY = 0.05.seconds
  MAX_ROCK_SPAWN_DELAY = 0.25.seconds
  MIN_SPECIAL_ROCK_SPAWN_COUNTDOWN = 2
  MAX_SPECIAL_ROCK_SPAWN_COUNTDOWN = 5
  MIN_ROCK_FALL_SPEED = 4.5
  MAX_ROCK_FALL_SPEED = 7.0
  MIN_ROCK_SPAWN_X = 32
  MAX_ROCK_SPAWN_X = (Grid.w - 32)
  MAX_HOOK_DURATION = 0.4.seconds
  MAX_HOOK_LENGTH = 256.0
  GRAPPLE_DURATION = 0.25.seconds
  MAX_PLAYER_FALL_SPEED = 2.5
  PLAYER_FALL_ACCELERATION = 0.8
  PLAYER_FAST_FALL_RECOVERY = 0.33
  PLAYER_JUMP_VELOCITY = 22.0
  PLAYER_BOOSTED_JUMP_VELOCITY = PLAYER_JUMP_VELOCITY * 1.5
  BOMB_ROCK_EXPLOSION_RADIUS = 1280.0
  SPECIAL_ROCK_TYPES = [:down_rock, :up_rock, :bomb_rock]

  def initialize args
  end

  def start 
    state.input_active = true

    state.player = {
      x: 50,
      y: 50,
      w: 32,
      h: 32,
      r: 0,
      g: 255,
      b: 255,
      dx: 0,
      dy: 0,
      face_direction: 1,
      move_direction: 0, 
      acceleration: 0.6,
      deceleration: 0.35,
      max_speed: 5.0,
      attacked_tick: nil,
      grappling_tick: nil,
      grapple_start_x: 0,
    }
    state.hook = {
      x: (state.player.x / 2) - 4,
      y: (state.player.y / 2) - 4,
      w: 16,
      h: 16,
      r: 255,
      g: 0,
      b: 0,
      a: 100,
      direction: 1,
      active: false,
      hit_target: nil
    }

    state.rock_manager = {
      rocks: [],
      rock_spawned_at: 0,
      next_rock_spawn_delay: Numeric.rand(MIN_ROCK_SPAWN_DELAY..MAX_ROCK_SPAWN_DELAY),
      next_rock_spawn_x: Numeric.rand(MIN_ROCK_SPAWN_X..MAX_ROCK_SPAWN_X),
      next_rock_dy: Numeric.rand(MIN_ROCK_FALL_SPEED..MAX_ROCK_FALL_SPEED),
      next_special_rock_spawn_countdown: Numeric.rand(MIN_SPECIAL_ROCK_SPAWN_COUNTDOWN..MAX_SPECIAL_ROCK_SPAWN_COUNTDOWN)
    }
  end

  def tick
    input
    calc
    render
  end

  def input
    return unless state.input_active
    state.player.move_direction = 0
    state.player.move_direction -= 1 if inputs.keyboard.left
    state.player.move_direction += 1 if inputs.keyboard.right
    state.player_attack_input_pressed = inputs.keyboard.key_down.space
    state.player_attack_input_released = inputs.keyboard.key_up.space
  end

  def calc
    calc_player
    calc_hook
    calc_rocks
    calc_collisions
  end

  def render
    outputs.background_color = [40,40,40]
    outputs.solids << state.player
    outputs.solids << state.hook if player_attacking?
    state.rock_manager.rocks.each { |r| outputs.solids << r }

    outputs.watch "HOOK HITBOX ACTIVE? #{state.hook.active}"
    outputs.watch "PLAYER_ATTACKING? #{player_attacking?}"
    outputs.watch "PLAYER_GRAPPLING? #{state.player.grappling_tick}"
  end

  def calc_player
    # calc velocity
    target_dx = state.player.move_direction * state.player.max_speed

    if state.player.dx < target_dx
      state.player.dx = [state.player.dx + state.player.acceleration, target_dx].min
    elsif state.player.dx > target_dx
      state.player.dx = [state.player.dx - state.player.deceleration, target_dx].max
    end

    if state.player.dy < -MAX_PLAYER_FALL_SPEED
      state.player.dy = [state.player.dy + PLAYER_FAST_FALL_RECOVERY, -MAX_PLAYER_FALL_SPEED].min
    else
      state.player.dy = [state.player.dy - PLAYER_FALL_ACCELERATION, -MAX_PLAYER_FALL_SPEED].max
    end

    # calc facing direction
    state.player.face_direction = player_direction?

    # apply velocity
    state.player.x += state.player.dx
    state.player.y += state.player.dy

    # calc attacking
    if state.player_attack_input_pressed && !player_attacking?
      state.player.attacked_tick = Kernel.tick_count 
      state.hook.direction = state.player.face_direction
    end
    state.player.attacked_tick = nil if state.player.attacked_tick && !player_attacking? || state.player_attack_input_released

    # everything after this is handling when a player is mid-grapple after connecting the hook with a rock
    return unless state.player.grappling_tick
    outputs.watch "GRAPPLING TIME ELAPSED: #{state.player.grappling_tick.elapsed_time}"

    grapple_to_rock
    

  end

  def grapple_to_rock
    target_rock = state.hook.hit_target
    target_rock.dy = -state.player.dy

    ease_percentage = Easing.smooth_stop(start_at: state.player.grappling_tick,
                                duration: GRAPPLE_DURATION,
                                tick_count: Kernel.tick_count,
                                power: 3)
    state.player.x = state.player.grapple_start_x.lerp(target_rock.x, ease_percentage) if target_rock

    if state.player.grappling_tick.elapsed_time >= GRAPPLE_DURATION
      handle_rock_effect(target_rock)
      reset_grapple_variables
    end
  end

  def handle_rock_effect(target_rock)
    case target_rock.type
    when :basic
      state.player.dy += PLAYER_JUMP_VELOCITY
    when :bomb
      state.player.dy += PLAYER_JUMP_VELOCITY
      state.rock_manager.rocks.reject! do |other_r|
        other_r != target_rock && Geometry.distance(target_rock, other_r) <= BOMB_ROCK_EXPLOSION_RADIUS
      end
    when :down
      state.player.dy += -PLAYER_JUMP_VELOCITY / 2
    when :up
      state.player.dy += PLAYER_BOOSTED_JUMP_VELOCITY
    when :default
      state.player.dy += PLAYER_JUMP_VELOCITY
    end
    state.rock_manager.rocks.delete(target_rock)
  end

  def reset_grapple_variables
    state.player.grappling_tick = nil
    state.hook.hit_target = nil
    enable_input
  end

  def calc_hook
    state.hook.active = hook_hitbox_active?
    return unless player_attacking?
    center_of_player_y = state.player.y + (state.player.h / 2 - state.hook.h / 2)
    state.hook.y = center_of_player_y

    base_x = 
      if state.hook.direction > 0
        state.player.x + state.player.w
      else
        state.player.x - state.hook.w
      end

    ease_percentage = Easing.smooth_stop(start_at: state.player.attacked_tick,
                                duration: MAX_HOOK_DURATION,
                                tick_count: Kernel.tick_count,
                                power: 1)
    
    hook_offset = 0.lerp(MAX_HOOK_LENGTH * state.hook.direction, ease_percentage)
    state.hook.x = base_x + hook_offset
  end

  def calc_collisions
    state.player.x = 0 if state.player.x <= 0
    state.player.x = Grid.w - state.player.w if state.player.x >= Grid.w - state.player.w
    state.player.y = Grid.h if state.player.y <= (0 - state.player.h)

    state.hook.b = state.hook.active ? 255 : 0

    # everything below this handles hook collisions if the hitbox for it is active
    return unless state.hook.active

    rocks_hit = []
    state.rock_manager.rocks.each { |r| rocks_hit << r if state.hook.intersect_rect?(r) }

    previous_tick_hit_target = state.hook.hit_target
    state.hook.hit_target = find_first_rock_hit(rocks_hit)
    
    if state.hook.hit_target && !previous_tick_hit_target
      disable_input
      state.player.grappling_tick = Kernel.tick_count
      state.player.grapple_start_x = state.player.x
    end
  end

  def calc_rocks
    if state.rock_manager.rock_spawned_at.elapsed_time >= state.rock_manager.next_rock_spawn_delay
      selected_rock_type = select_rock_type_to_spawn
      state.rock_manager.rocks << send(selected_rock_type, spawn_x: state.rock_manager.next_rock_spawn_x, fall_speed: state.rock_manager.next_rock_dy)
      reset_rock_spawn_variables
    end

    state.rock_manager.rocks.each do |r|
      r.y -= r.dy
    end

    state.rock_manager.rocks.reject! { |r| r.y < -32 }
  end

  def select_rock_type_to_spawn
    if state.rock_manager.next_special_rock_spawn_countdown == 0
      state.rock_manager.next_special_rock_spawn_countdown = Numeric.rand(MIN_SPECIAL_ROCK_SPAWN_COUNTDOWN..MAX_SPECIAL_ROCK_SPAWN_COUNTDOWN)
      return SPECIAL_ROCK_TYPES.sample
    else
      state.rock_manager.next_special_rock_spawn_countdown -= 1
      return :basic_rock
    end
  end

  def reset_rock_spawn_variables
    state.rock_manager.rock_spawned_at = Kernel.tick_count
    state.rock_manager.next_rock_spawn_delay = Numeric.rand(MIN_ROCK_SPAWN_DELAY..MAX_ROCK_SPAWN_DELAY)
    state.rock_manager.next_rock_spawn_x = Numeric.rand(MIN_ROCK_SPAWN_X..MAX_ROCK_SPAWN_X)
    state.rock_manager.next_rock_dy = Numeric.rand(MIN_ROCK_FALL_SPEED..MAX_ROCK_FALL_SPEED)
  end

  def find_first_rock_hit(hits_array)
    return nil if hits_array.empty?

    if state.hook.direction > 0
      player_edge_x = state.player.x + state.player.w
      hits_array.min_by { |r| r.x - player_edge_x }
    elsif state.hook.direction < 0
      player_edge_x = state.player.x
      hits_array.min_by { |r| player_edge_x - (r.x + r.w)}
    end
  end

  def player_direction?
    if state.player.move_direction > 0
      1
    elsif state.player.move_direction < 0
      -1
    else
      state.player.face_direction
    end
  end

  def player_attacking?
    return false if state.player.grappling_tick
    return false unless state.player.attacked_tick
    state.player.attacked_tick.elapsed_time <= MAX_HOOK_DURATION
  end

  def hook_hitbox_active?
    !state.player.grappling_tick && player_attacking?
  end

  def enable_input
    state.input_active = true
  end

  def disable_input
    state.input_active = false
    state.player.move_direction = 0
  end

  def basic_rock(spawn_x:, fall_speed:)
    {
      x: spawn_x,
      y: 720,
      w: 16,
      h: 16,
      r: 255,
      g: 255,
      b: 255,
      dy: fall_speed,
      type: :basic,
    }
  end

  def bomb_rock(spawn_x:, fall_speed:)
    {
      x: spawn_x,
      y: 720,
      w: 16,
      h: 16,
      r: 100,
      g: 100,
      b: 100,
      dy: fall_speed,
      type: :bomb,
    }
  end

  def down_rock(spawn_x:, fall_speed:)
    {
      x: spawn_x,
      y: 720,
      w: 16,
      h: 16,
      r: 255,
      g: 20,
      b: 20,
      dy: fall_speed,
      type: :down,
    }
  end

  def up_rock(spawn_x:, fall_speed:)
    {
      x: spawn_x,
      y: 720,
      w: 16,
      h: 16,
      r: 120,
      g: 255,
      b: 255,
      dy: fall_speed,
      type: :up,
    }
  end
end
