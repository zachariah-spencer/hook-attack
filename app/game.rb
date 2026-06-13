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
    state.player_x = 0
    state.player_x -= 1 if inputs.keyboard.left
    state.player_x += 1 if inputs.keyboard.right
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
  end

  def calc_gravity
    state.player.y -= 5
  end

  def calc_player_movement
    state.player.x += state.player_x * 5
  end

  def calc_collisions
    state.player.x = 0 if state.player.x <= 0
    state.player.x = Grid.w - state.player.w if state.player.x >= Grid.w - state.player.w
    state.player.y = Grid.h if state.player.y <= (0 - state.player.h)
  end
end