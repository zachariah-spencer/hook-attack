class Game
  attr_dr

  def initialize args; end

  def start 
    state.player = {
      x: 50,
      y: 50,
      w: 32,
      h: 32,
      r: 255,
      g: 0,
      b: 0,
      dx: 0,
      dy: 0,
      direction: 1, 
      acceleration: 0.6,
      deceleration: 0.35,
      max_speed: 5.0,
      attacking: false,
      attacked_tick: -100
    }
  end

  def tick
    input
    calc
    render
  end

  def input
    state.player_move_direction = 0
    state.player_move_direction -= 1 if inputs.keyboard.left
    state.player_move_direction += 1 if inputs.keyboard.right
    state.player_attack = inputs.keyboard.key_down.space
  end

  def calc
    calc_gravity
    calc_player_movement

    state.player.attacked_tick = Kernel.tick_count if state.player_attack
    if state.player.attacked_tick.elapsed_time <= 0.5.seconds
      outputs.watch "ATTACKING"
    end

    calc_collisions
  end

  def render
    outputs.background_color = [40,40,40]
    outputs.solids << state.player
    outputs.watch "PLAYER X: #{state.player.x}"
    outputs.watch "PLAYER DIRECTION: #{state.player.direction}"
    outputs.watch "PLAYER DX: #{state.player.dx}"
  end

  def calc_gravity
    state.player.y -= 5.0
  end

  def calc_player_movement
    target_dx = state.player_move_direction * state.player.max_speed

    if state.player.dx < target_dx
      state.player.dx = [state.player.dx + state.player.acceleration, target_dx].min
    elsif state.player.dx > target_dx
      state.player.dx = [state.player.dx - state.player.deceleration, target_dx].max
    end
    state.player.x += state.player.dx

    state.player.direction = player_direction?
  end

  def player_direction?
    if state.player_move_direction > 0
      1
    elsif state.player_move_direction < 0
      -1
    else
      state.player.direction
    end
  end

  def calc_collisions
    state.player.x = 0 if state.player.x <= 0
    state.player.x = Grid.w - state.player.w if state.player.x >= Grid.w - state.player.w
    state.player.y = Grid.h if state.player.y <= (0 - state.player.h)
  end
end