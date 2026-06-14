class Game
  attr_dr

  def initialize args; end

  def start 
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
      attack_duration: 0.5.seconds,
      attacked_tick: nil,
    }
    state.hook = {
      x: (state.player.x / 2) - 4,
      y: (state.player.y / 2) - 4,
      w: 64,
      h: 32,
      r: 255,
      g: 0,
      b: 0,
      a: 100,
      direction: 1,
      active: false,
      hit_target: nil
    }
  end

  def tick
    input
    calc
    render
  end

  def input
    state.player.move_direction = 0
    state.player.move_direction -= 1 if inputs.keyboard.left
    state.player.move_direction += 1 if inputs.keyboard.right
    state.player_attack_input = inputs.keyboard.key_down.space
  end

  def calc
    calc_gravity
    calc_player_movement
    calc_hook_movement

    state.player.attacked_tick = Kernel.tick_count if state.player_attack_input && !player_attacking?
    state.player.attacked_tick = nil if state.player.attacked_tick && !player_attacking?

    calc_collisions
  end

  def render
    outputs.background_color = [40,40,40]
    outputs.solids << state.player
    outputs.solids << state.hook if player_attacking?
    outputs.watch "PLAYER_ATTACKING: #{player_attacking?}"
  end

  def calc_gravity
    state.player.y -= 2.5
  end

  def calc_player_movement
    target_dx = state.player.move_direction * state.player.max_speed

    if state.player.dx < target_dx
      state.player.dx = [state.player.dx + state.player.acceleration, target_dx].min
    elsif state.player.dx > target_dx
      state.player.dx = [state.player.dx - state.player.deceleration, target_dx].max
    end
    state.player.x += state.player.dx

    state.player.face_direction = player_direction?
  end

  def calc_hook_movement
    state.hook.direction = state.player.face_direction

    if state.hook.direction > 0
      hook_side_x = state.player.x + (state.player.w)
    elsif state.hook.direction < 0
      hook_side_x = state.player.x - (state.player.w * 2)
    end

    center_of_player_y = state.player.y + (state.player.h / 2 - state.hook.h / 2)
    
    state.hook.x = hook_side_x
    state.hook.y = center_of_player_y
  end

  def calc_collisions
    state.player.x = 0 if state.player.x <= 0
    state.player.x = Grid.w - state.player.w if state.player.x >= Grid.w - state.player.w
    state.player.y = Grid.h if state.player.y <= (0 - state.player.h)
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
    return false unless state.player.attacked_tick
    state.player.attacked_tick.elapsed_time <= state.player.attack_duration
  end
end