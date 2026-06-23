class Game
  attr_dr


  DIFFICULTY_RAMP_DURATION = 105.seconds
  EASY_TO_MEDIUM_DIFFICULTY_DURATION = 35.seconds
  MEDIUM_TO_HARD_DIFFICULTY_DURATION = 70.seconds

  EASY_MIN_ROCK_SPAWN_DELAY = 0.22.seconds
  EASY_MAX_ROCK_SPAWN_DELAY = 0.42.seconds
  EASY_MIN_DOWN_ROCK_SPAWN_COUNTDOWN = 12
  EASY_MAX_DOWN_ROCK_SPAWN_COUNTDOWN = 16
  EASY_MIN_SPECIAL_ROCK_SPAWN_COUNTDOWN = 8
  EASY_MAX_SPECIAL_ROCK_SPAWN_COUNTDOWN = 12
  EASY_MIN_SHOP_ROCK_SPAWN_COUNTDOWN = 14
  EASY_MAX_SHOP_ROCK_SPAWN_COUNTDOWN = 18
  EASY_MIN_ROCK_FALL_SPEED = 3.8
  EASY_MAX_ROCK_FALL_SPEED = 5.3

  MEDIUM_MIN_ROCK_SPAWN_DELAY = 0.18.seconds
  MEDIUM_MAX_ROCK_SPAWN_DELAY = 0.34.seconds
  MEDIUM_MIN_DOWN_ROCK_SPAWN_COUNTDOWN = 7
  MEDIUM_MAX_DOWN_ROCK_SPAWN_COUNTDOWN = 10
  MEDIUM_MIN_SPECIAL_ROCK_SPAWN_COUNTDOWN = 7
  MEDIUM_MAX_SPECIAL_ROCK_SPAWN_COUNTDOWN = 10
  MEDIUM_MIN_SHOP_ROCK_SPAWN_COUNTDOWN = 18
  MEDIUM_MAX_SHOP_ROCK_SPAWN_COUNTDOWN = 20
  MEDIUM_MIN_ROCK_FALL_SPEED = 4.6
  MEDIUM_MAX_ROCK_FALL_SPEED = 6.2

  HARD_MIN_ROCK_SPAWN_DELAY = 0.14.seconds
  HARD_MAX_ROCK_SPAWN_DELAY = 0.26.seconds
  HARD_MIN_DOWN_ROCK_SPAWN_COUNTDOWN = 4
  HARD_MAX_DOWN_ROCK_SPAWN_COUNTDOWN = 7
  HARD_MIN_SPECIAL_ROCK_SPAWN_COUNTDOWN = 6
  HARD_MAX_SPECIAL_ROCK_SPAWN_COUNTDOWN = 9
  HARD_MIN_SHOP_ROCK_SPAWN_COUNTDOWN = 20
  HARD_MAX_SHOP_ROCK_SPAWN_COUNTDOWN = 40
  HARD_MIN_ROCK_FALL_SPEED = 5.2
  HARD_MAX_ROCK_FALL_SPEED = 7.2

  MIN_ROCK_SPAWN_X = 32
  MAX_ROCK_SPAWN_X = (Grid.w - 32)
  MIN_GOLD_SPAWN_DELAY = 0.75.seconds
  MAX_GOLD_SPAWN_DELAY = 1.5.seconds
  GOLD_ATTRACTION_RADIUS = 350
  GOLD_ATTRACTION_STRENGTH = 10.0
  MAX_HOOK_DURATION = 0.4.seconds
  MAX_HOOK_LENGTH = 256.0
  GRAPPLE_DURATION = 0.25.seconds
  MAX_PLAYER_FALL_SPEED = 2.5
  PLAYER_FALL_ACCELERATION = 0.8
  PLAYER_FAST_FALL_RECOVERY = 0.33
  PLAYER_JUMP_VELOCITY = 22.0
  PLAYER_BOOSTED_JUMP_VELOCITY = PLAYER_JUMP_VELOCITY * 1.5
  COMBO_RESET_DURATION = 2.0.seconds
  COMBO_PARTICLE_DURATION = 1.0.seconds
  COMBO_PARTICLE_FLOAT_DISTANCE = 64
  BOMB_ROCK_EXPLOSION_RADIUS = 1280.0
  DEFAULT_HOOK_SIZE = 16
  WIDE_HOOK_SIZE = 64
  MIN_POWERUP_SPAWN_DELAY = 20.seconds
  MAX_POWERUP_SPAWN_DELAY = 35.seconds
  POWERUP_FALL_SPEED = 4.5
  SPECIAL_ROCK_TYPES = [:up_rock, :bomb_rock, :gold_rock]
  POWERUP_TYPES = [:up_rock, :wide_hook, :gold_rush, :eagle]

  def initialize args
  end

  def start 
    state.input_active = true
    state.run_started_tick = nil
    state.run_ended_tick = nil
    state.longest_run_time = DR.read_file("data/save.txt").to_f || 0.0
    state.paused_tick = nil
    state.total_time_paused = 0.0
    state.shop_open_tick = nil
    state.shop_close_tick = nil
    state.shop_alpha = 0
    state.player = initial_player
    state.gold_modifier = 1.0
    state.shop_leave_button_color = {
      r: 20,
      g: 20,
      b: 20,
    }

    state.camera = {
      x: 640.0,
      y: 360.0,
      screen_x: 640,
      screen_y: 360,
      zoom: 1.0,
      zoom_start: 1.0,
      zoom_target: 1.0,
      zoom_started_tick: nil,
      zoom_in_duration: 0,
      zoom_out_duration: 0,
      shake_x: 0.0,
      shake_y: 0.0,
      shake_time: 0.0,
      shake_duration: 1,
      shake_strength: 0,
    }

    state.hook = initial_hook
    difficulty = calc_current_difficulty_levers
    state.rock_manager = {
      rocks: [],
      rock_spawned_at: 0,
      next_rock_spawn_delay: Numeric.rand(difficulty.min_rock_spawn_delay..difficulty.max_rock_spawn_delay),
      next_rock_spawn_x: Numeric.rand(MIN_ROCK_SPAWN_X..MAX_ROCK_SPAWN_X),
      next_rock_dy: Numeric.rand(difficulty.min_rock_fall_speed..difficulty.max_rock_fall_speed),
      next_special_rock_spawn_countdown: Numeric.rand(difficulty.min_special_rock_spawn_countdown..difficulty.max_special_rock_spawn_countdown),
      next_down_rock_spawn_countdown: Numeric.rand(difficulty.min_down_rock_spawn_countdown..difficulty.max_down_rock_spawn_countdown),
      next_shop_rock_spawn_countdown: Numeric.rand(HARD_MIN_SHOP_ROCK_SPAWN_COUNTDOWN..HARD_MAX_SHOP_ROCK_SPAWN_COUNTDOWN),
      only_spawn_up_rocks: false,
    }

    state.powerup_manager = {
      powerups: [],
      powerup_spawn_tick: 0,
      next_powerup_spawn_delay: Numeric.rand(MIN_POWERUP_SPAWN_DELAY..MAX_POWERUP_SPAWN_DELAY),
      next_powerup_spawn_x: Numeric.rand(MIN_ROCK_SPAWN_X..MAX_ROCK_SPAWN_X),
    }

    state.gold_manager = {
      gold: [],
      gold_spawn_tick: 0,
      next_gold_spawn_delay: Numeric.rand(MIN_GOLD_SPAWN_DELAY..MAX_GOLD_SPAWN_DELAY),
      next_gold_spawn_x: Numeric.rand(MIN_ROCK_SPAWN_X..MAX_ROCK_SPAWN_X),
      next_gold_dy: Numeric.rand(EASY_MIN_ROCK_FALL_SPEED..EASY_MAX_ROCK_FALL_SPEED),
    }

    state.shop_items = []
    state.combo_manager = {
      grapple_count: 0,
      last_grapple_active_tick: nil,
      particles: [],
    }

    state.player_offscreen_indicator = {
      x: 50,
      y: Grid.h - 64,
      w: 64,
      h: 64,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: "sprites/triangle/equilateral/blue.png",
      angle: 0,
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
    state.player.move_direction_y = 0
    state.player.move_direction -= 1 if inputs.keyboard.left
    state.player.move_direction += 1 if inputs.keyboard.right
    state.player.move_direction_y -= 1 if inputs.keyboard.down
    state.player.move_direction_y += 1 if inputs.keyboard.up && state.player.carried_by_eagle
    # state.player.move_down = inputs.keyboard.down
    state.player_attack_input_pressed = inputs.keyboard.key_down.space
    state.player_attack_input_released = inputs.keyboard.key_up.space

    return if state.run_started_tick
    state.run_started_tick = Kernel.tick_count if state.player.move_direction != 0 || state.player_attack_input_pressed
  end

  def calc
    unless state.paused_tick
      calc_longest_run_time if state.run_started_tick
      calc_player if state.run_started_tick
      calc_powerups
      calc_hook
      calc_rocks
      calc_gold
      calc_combo
      calc_camera
      calc_collisions if state.run_started_tick
    else
      outputs.watch "PAUSED"
      state.total_time_paused = state.paused_tick.elapsed_time
      calc_shop if state.shop_open_tick
    end
  end

  def render
    outputs.background_color = [40,40,40]
    render_world
    render_ui
  end

  def render_world
    outputs.solids << camera_transform(state.player)
    outputs.solids << camera_transform(state.hook) if player_attacking?
    state.rock_manager.rocks.each { |r| outputs.solids << camera_transform(r) }
    state.gold_manager.gold.each { |g| outputs.solids << camera_transform(g) }
    state.powerup_manager.powerups.each { |p| outputs.solids << camera_transform(p) }
    render_combo_particles
  end

  def render_ui
    outputs.sprites << state.player_offscreen_indicator if state.player.y >= Grid.h
    outputs.labels << start_instructions_label unless state.run_started_tick
    outputs.labels << [run_timer_label, longest_run_time_label, gold_label]
    render_combo_ui
    render_powerup_ui
    render_shop if state.shop_open_tick && state.shop_alpha > 0
  end

  def render_combo_particles
    state.combo_manager.particles.each do |p|
      outputs.labels << camera_transform_combo_particle(p)
    end
  end

  def render_combo_ui
    return unless combo_timer_active?

    outputs.solids << combo_timer_backdrop_rect
    outputs.solids << combo_timer_fill_rect
    outputs.labels << combo_count_label if combo_active?
  end

  def render_powerup_ui
    return if player_finite_powerups.empty?

    player_finite_powerups.each_with_index do |p, i|
      time_left_ticks = remaining_powerup_time(p)
      start_y = Grid.h - 96
      spacing = 32
      outputs.labels << powerup_timer_label(time_left: time_left_ticks, y: start_y - (spacing * i), display_name: p.name)
    end
    

    
  end

  def remaining_powerup_time(p)
    p.duration - p.start_tick.elapsed_time
  end

  def player_finite_powerups
    state.player.powerups.select { |p| p.duration > 0 }
  end

  def add_powerup(powerup_method_name:)
    new_powerup = send(powerup_method_name)
    unless state.player.powerups.any? { |p| p.type == new_powerup.type }
      state.player.powerups << new_powerup
    else
      duplicate_powerup = state.player.powerups.find { |p| p.type == new_powerup.type }
      duplicate_powerup.start_tick = new_powerup.start_tick
    end
  end

  def enable_input
    state.input_active = true
  end

  def disable_input
    state.input_active = false
    state.player.move_direction = 0
  end

  def trigger_camera_shake(strength:, duration:)
    state.camera.shake_strength = strength
    state.camera.shake_duration = duration
    state.camera.shake_time = duration
  end

  def camera_transform(rect)
    camera = state.camera
    zoom = camera.zoom || 1.0

    world_center_x = rect.x + rect.w / 2
    world_center_y = rect.y + rect.h / 2

    screen_center_x = (world_center_x - camera.x) * zoom + camera.screen_x + camera.shake_x
    screen_center_y = (world_center_y - camera.y) * zoom + camera.screen_y + camera.shake_y
    rect.merge(
      x: screen_center_x - rect.w * zoom / 2,
      y: screen_center_y - rect.h * zoom / 2,
      w: rect.w * zoom,
      h: rect.h * zoom,
    )
  end

  def camera_transform_combo_particle(particle)
    camera = state.camera
    zoom = camera.zoom || 1.0
    elapsed = active_tick_count - particle.started_active_tick
    progress = elapsed.fdiv(COMBO_PARTICLE_DURATION).clamp(0, 1)
    screen_x = (particle.x - camera.x) * zoom + camera.screen_x + camera.shake_x
    screen_y = (particle.y + COMBO_PARTICLE_FLOAT_DISTANCE * progress - camera.y) * zoom + camera.screen_y + camera.shake_y

    {
      x: screen_x,
      y: screen_y,
      anchor_x: 0.5,
      anchor_y: 0.5,
      size_px: 64,
      text: particle.text,
      r: 255,
      g: 245,
      b: 120,
      a: 255.lerp(0, progress),
    }
  end

  def calc_combo
    if combo_timer_active? && combo_elapsed_since_last_grapple > COMBO_RESET_DURATION
      state.combo_manager.grapple_count = 0
      state.combo_manager.last_grapple_active_tick = nil
    end

    state.combo_manager.particles.reject! do |p|
      active_tick_count - p.started_active_tick >= COMBO_PARTICLE_DURATION
    end
  end

  def combo_active?
    state.combo_manager.grapple_count >= 2 && state.combo_manager.last_grapple_active_tick
  end

  def combo_timer_active?
    state.combo_manager.grapple_count > 0 && state.combo_manager.last_grapple_active_tick
  end

  def register_combo_grapple
    if combo_timer_active? && combo_elapsed_since_last_grapple <= COMBO_RESET_DURATION
      state.combo_manager.grapple_count += 1
    else
      state.combo_manager.grapple_count = 1
    end

    state.combo_manager.last_grapple_active_tick = active_tick_count
    state.combo_manager.particles << combo_particle(number: state.combo_manager.grapple_count) if combo_active?
  end

  def combo_particle(number:)
    {
      x: state.player.x + state.player.w / 2,
      y: state.player.y + state.player.h + 12,
      text: "#{number.to_s}x",
      started_active_tick: active_tick_count,
    }
  end

  def active_tick_count
    Kernel.tick_count - state.total_time_paused
  end

  def combo_elapsed_since_last_grapple
    active_tick_count - state.combo_manager.last_grapple_active_tick
  end

  def calc_shop
    if !state.shop_close_tick && state.shop_alpha < 255
      ease_percentage = Easing.smooth_stop(start_at: state.shop_open_tick,
                                duration: 0.5.seconds,
                                tick_count: Kernel.tick_count,
                                power: 1)
      state.shop_alpha = state.shop_alpha.lerp(255, ease_percentage)
    elsif state.shop_close_tick && state.shop_close_tick.elapsed_time < 0.5.seconds
      ease_percentage = Easing.smooth_stop(start_at: state.shop_close_tick,
                                duration: 0.5.seconds,
                                tick_count: Kernel.tick_count,
                                power: 1)
      state.shop_alpha = state.shop_alpha.lerp(0, ease_percentage)
    elsif state.shop_close_tick && state.shop_close_tick.elapsed_time >= 0.5.seconds
      state.shop_open_tick = nil
      state.shop_close_tick = nil
      state.paused_tick = nil
    end

    return if state.shop_close_tick
    state.shop_items.each do |b|
      if inputs.mouse.intersect_rect?(b)
        b.g = 200
        b.b = 200

        if inputs.mouse.click && state.player.gold >= b.price
          state.player.gold -= b.price
          state.player.powerups << send("#{b.item_id}_powerup")
          state.shop_close_tick = Kernel.tick_count
        end

      else
        b.g = 20
        b.b = 20
      end
    end

    if inputs.mouse.intersect_rect?(shop_leave_button_rect)
      state.shop_leave_button_color.g = 200
      state.shop_leave_button_color.b = 200

      if inputs.mouse.click
        state.shop_close_tick = Kernel.tick_count
      end

    else
      state.shop_leave_button_color.g = 20
      state.shop_leave_button_color.b = 20
    end
  end

  def render_shop
    outputs.labels << {
      x: Grid.w / 2,
      y: Grid.h - 128,
      anchor_x: 0.5,
      anchor_y: 0.5,
      size_px: 64,
      text: "The Rock Shoppe",
      r: 220,
      g: 220,
      b: 220,
      a: state.shop_alpha
    }
    
    state.shop_items.each do |si|
      outputs.solids << {
        x: si.x,
        y: si.y,
        w: si.w,
        h: si.h,
        r: si.r,
        g: si.g,
        b: si.b,
        a: [state.shop_alpha, 190].min,
      }
      outputs.labels << {
        x: si.x + (si.w / 2),
        y: si.y + (si.w / 2) + 32,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_px: 32,
        r: 220,
        g: 220,
        b: 220,
        a: state.shop_alpha,
        text: "#{si.display_name}"
      }
      outputs.labels << {
        x: si.x + (si.w / 2),
        y: si.y + (si.w / 2) - 32,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_px: 32,
        r: 220,
        g: 220,
        b: 220,
        a: state.shop_alpha,
        text: "#{si.price}"
      }
    end

      outputs.solids << shop_leave_button_rect
      outputs.labels << {
        x: Grid.w / 2 - 28,
        y: Grid.h / 2 - 196 - 16,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_px: 24,
        r: 220,
        g: 220,
        b: 220,
        a: state.shop_alpha,
        text: "Exit the Shoppe"
      }
  end

  def shop_leave_button_rect
    {
        x: Grid.w / 2 - 128 - 28,
        y: Grid.h / 2 - 256,
        w: 256,
        h: 96,
        r: state.shop_leave_button_color.r,
        g: state.shop_leave_button_color.g,
        b: state.shop_leave_button_color.b,
        a: [state.shop_alpha, 190].min,
    }
  end

  def shop_item(item_id:, price:, display_name:, x:, y:)
    {
      x: x,
      y: y,
      w: 256,
      h: 256,
      r: 20,
      g: 20,
      b: 20,
      item_id: item_id,
      display_name: display_name,
      price: price,
    }
  end

  def calc_longest_run_time
    ticks_factoring_pause_elapsed = state.run_started_tick.elapsed_time - state.total_time_paused
    return if (ticks_factoring_pause_elapsed / 60).round(1) <= state.longest_run_time
    elapsed_seconds = ticks_factoring_pause_elapsed / 60
    state.longest_run_time = elapsed_seconds.round(1)
  end

  def calc_camera
    calc_camera_shake
    calc_camera_zoom
  end

  def calc_camera_shake
    if state.camera.shake_time > 0.0
      current_strength = state.camera.shake_strength * state.camera.shake_time / state.camera.shake_duration
      angle = Numeric.rand * Math::PI * 2
      distance = Numeric.rand * current_strength

      state.camera.shake_x = Math.sin(angle) * distance
      state.camera.shake_y = Math.cos(angle) * distance

      state.camera.shake_time -= 1.0
    else
      state.camera.shake_x = 0
      state.camera.shake_y = 0
    end
  end

  def calc_camera_zoom
    return unless state.camera.zoom_started_tick
    elapsed = state.camera.zoom_started_tick.elapsed_time

    zoom_in_end_tick = state.camera.zoom_in_duration
    zoom_out_end_tick = zoom_in_end_tick + state.camera.zoom_out_duration

    if elapsed < zoom_in_end_tick
      progress = elapsed.fdiv(state.camera.zoom_in_duration)
      state.camera.zoom = state.camera.zoom_start.lerp(state.camera.zoom_target, progress)
    elsif elapsed < zoom_out_end_tick
      zoom_out_elapsed = elapsed - zoom_in_end_tick
      progress = zoom_out_elapsed.fdiv(state.camera.zoom_out_duration)
      state.camera.zoom = state.camera.zoom_target.lerp(1.0, progress)
    else
      state.camera.zoom = 1.0
      state.camera.zoom_started_tick = nil
    end
  end

  def trigger_camera_zoom(target:, zoom_in_duration:, zoom_out_duration:)
    state.camera.zoom_start = state.camera.zoom
    state.camera.zoom_target = target
    state.camera.zoom_started_tick = Kernel.tick_count
    state.camera.zoom_in_duration = zoom_in_duration
    state.camera.zoom_out_duration = zoom_out_duration

  end

  def calc_player
    unless state.player.carried_by_eagle
      # calc velocity
      target_dx = state.player.move_direction * state.player.max_speed
      

      if state.player.dx < target_dx
        state.player.dx = [state.player.dx + state.player.acceleration, target_dx].min
      elsif state.player.dx > target_dx
        state.player.dx = [state.player.dx - state.player.deceleration, target_dx].max
      end

      applied_player_fall_speed = state.player.move_direction_y == -1 ? (MAX_PLAYER_FALL_SPEED * 1.5) : MAX_PLAYER_FALL_SPEED
      if state.player.dy < -MAX_PLAYER_FALL_SPEED
        state.player.dy = [state.player.dy + PLAYER_FAST_FALL_RECOVERY, -applied_player_fall_speed].min
      else
        state.player.dy = [state.player.dy - PLAYER_FALL_ACCELERATION, -applied_player_fall_speed].max
      end
    else
      eagle_speed = state.player.max_speed * 1.75

      if state.player.dx < state.player.move_direction * eagle_speed
        state.player.dx = [state.player.dx + (state.player.acceleration * 1.5), state.player.move_direction * eagle_speed].min
      elsif state.player.dx > state.player.move_direction * eagle_speed
        state.player.dx = [state.player.dx - (state.player.deceleration * 1.5), state.player.move_direction * eagle_speed].max
      end

      if state.player.dy < state.player.move_direction_y * eagle_speed
        state.player.dy = [state.player.dy + (state.player.acceleration * 1.5), state.player.move_direction_y * eagle_speed].min
      elsif state.player.dy > state.player.move_direction_y * eagle_speed
        state.player.dy = [state.player.dy - (state.player.deceleration * 1.5), state.player.move_direction_y * eagle_speed].max
      end
    end
    # calc facing direction
    state.player.face_direction = player_direction?

    # apply velocity
    state.player.x += state.player.dx
    state.player.y += state.player.dy

    calc_end_game if state.player.y <= -state.player.h

    # calc attacking
    if state.player_attack_input_pressed && !player_attacking?
      state.player.attacked_tick = Kernel.tick_count 
      state.hook.direction = state.player.face_direction
    end
    state.player.attacked_tick = nil if state.player.attacked_tick && !player_attacking? || state.player_attack_input_released

    calc_player_offscreen_indicator

    # everything after this is handling when a player is mid-grapple after connecting the hook with a rock
    return unless state.player.grappling_tick
    grapple_to_rock
  end

  def calc_player_offscreen_indicator
    if state.player.y >= Grid.h
      # x position
      state.player_offscreen_indicator.x = 
        state.player.x + state.player.w / 2 - state.player_offscreen_indicator.w / 2

      # angle
      center_x = state.player_offscreen_indicator.x + state.player_offscreen_indicator.w / 2
      progress = center_x.fdiv(1280).clamp(0, 1)
      angle = (30.0).lerp(-30.0, progress)
      state.player_offscreen_indicator.angle = angle

      # scale
      distance_above = state.player.y - Grid.h
      progress = distance_above.fdiv(1024).clamp(0, 1)
      size = 64.lerp(16, progress)
      state.player_offscreen_indicator.w = size
      state.player_offscreen_indicator.h = size
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

    state.gold_manager.gold.each do |g|
      if state.player.intersect_rect?(g)
        state.gold_manager.gold.delete(g)
        state.player.gold += 1 * state.gold_modifier
      end
    end

    state.powerup_manager.powerups.each do |p|
      if state.player.intersect_rect?(p)
        state.powerup_manager.powerups.delete(p)
        add_powerup(powerup_method_name: "#{p.type}_powerup")
      end
    end

    state.hook.b = state.hook.active ? 255 : 0

    if state.player.carried_by_eagle
      rocks_hit = state.rock_manager.rocks.select do |rock|
        state.player.intersect_rect?(rock)
      end

      rocks_hit.each do |rock|
        handle_rock_effect(rock)
      end
    end

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
      trigger_camera_zoom(target: 1.05, zoom_in_duration: GRAPPLE_DURATION, zoom_out_duration: 20)
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

  def calc_gold
    if state.gold_manager.gold_spawn_tick.elapsed_time >= state.gold_manager.next_gold_spawn_delay
      state.gold_manager.gold << gold(spawn_x: state.gold_manager.next_gold_spawn_x, fall_speed: state.gold_manager.next_gold_dy)
      reset_gold_spawn_variables
    end

    state.gold_manager.gold.each do |g|
      player_x = state.player.x + state.player.w / 2
      player_y = state.player.y + state.player.h / 2
      gold_x = g.x + g.w / 2
      gold_y = g.y + g.h / 2

      offset_x = player_x - gold_x
      offset_y = player_y - gold_y
      distance = Math.sqrt(offset_x**2 +offset_y**2)

      g.y -= g.dy

      next if distance.zero? || distance >= GOLD_ATTRACTION_RADIUS || !state.run_started_tick

      proximity = 1.0 - distance / GOLD_ATTRACTION_RADIUS
      pull = GOLD_ATTRACTION_STRENGTH * proximity**2

      g.x += offset_x / distance * pull
      g.y += offset_y / distance * pull
    end

    state.gold_manager.gold.reject! { |g| g.y < -16 }
  end

  def reset_gold_spawn_variables
    state.gold_manager.gold_spawn_tick = Kernel.tick_count
    state.gold_manager.next_gold_spawn_delay = Numeric.rand(MIN_GOLD_SPAWN_DELAY..MAX_GOLD_SPAWN_DELAY)
    state.gold_manager.next_gold_spawn_x = Numeric.rand(MIN_ROCK_SPAWN_X..MAX_ROCK_SPAWN_X)
    state.gold_manager.next_gold_dy = Numeric.rand(EASY_MIN_ROCK_FALL_SPEED..EASY_MAX_ROCK_FALL_SPEED)
  end

  def select_rock_type_to_spawn
    return :up_rock if state.rock_manager.only_spawn_up_rocks
    
    difficulty = calc_current_difficulty_levers
    state.rock_manager.next_shop_rock_spawn_countdown -= 1
    state.rock_manager.next_special_rock_spawn_countdown -= 1
    state.rock_manager.next_down_rock_spawn_countdown -= 1

    if state.rock_manager.next_shop_rock_spawn_countdown <= 0
      state.rock_manager.next_shop_rock_spawn_countdown = Numeric.rand(HARD_MIN_SHOP_ROCK_SPAWN_COUNTDOWN..HARD_MAX_SHOP_ROCK_SPAWN_COUNTDOWN)
      return :shop_rock
    end

    if state.rock_manager.next_down_rock_spawn_countdown <= 0
      state.rock_manager.next_down_rock_spawn_countdown = Numeric.rand(difficulty.min_down_rock_spawn_countdown..difficulty.max_down_rock_spawn_countdown)
      return :down_rock
    end

    if state.rock_manager.next_special_rock_spawn_countdown <= 0
      state.rock_manager.next_special_rock_spawn_countdown = Numeric.rand(difficulty.min_special_rock_spawn_countdown..difficulty.max_special_rock_spawn_countdown)
      return SPECIAL_ROCK_TYPES.sample
    end
      
    :basic_rock 
  end

  def reset_rock_spawn_variables
    difficulty = calc_current_difficulty_levers
    state.rock_manager.rock_spawned_at = Kernel.tick_count
    state.rock_manager.next_rock_spawn_delay = Numeric.rand(difficulty.min_rock_spawn_delay..difficulty.max_rock_spawn_delay)
    state.rock_manager.next_rock_spawn_x = Numeric.rand(MIN_ROCK_SPAWN_X..MAX_ROCK_SPAWN_X)
    state.rock_manager.next_rock_dy = Numeric.rand(difficulty.min_rock_fall_speed..difficulty.max_rock_fall_speed)
  end

  def calc_powerups
    if state.powerup_manager.powerup_spawn_tick.elapsed_time >= state.powerup_manager.next_powerup_spawn_delay
      next_powerup_type = POWERUP_TYPES.sample
      state.powerup_manager.powerups << send("#{next_powerup_type}_powerup", spawn_x: state.powerup_manager.next_powerup_spawn_x)
      state.powerup_manager.powerup_spawn_tick = Kernel.tick_count
      state.powerup_manager.next_powerup_spawn_delay = Numeric.rand(MIN_POWERUP_SPAWN_DELAY..MAX_POWERUP_SPAWN_DELAY)
      state.powerup_manager.next_powerup_spawn_x = Numeric.rand(MIN_ROCK_SPAWN_X..MAX_ROCK_SPAWN_X)
    end

    state.powerup_manager.powerups.each { |p| p.y -= POWERUP_FALL_SPEED }
    state.powerup_manager.powerups.reject! { |p| p.y <= 0 - p.h }

    state.player.powerups.each do |p|
      unless p.active
        p.active = true
        case p.type
        when :wide_hook
          state.hook.h = WIDE_HOOK_SIZE
        when :up_rock
          state.rock_manager.only_spawn_up_rocks = true
        when :gold_rush
          state.gold_modifier = 2.0
        when :eagle
          state.player.carried_by_eagle = true
        end
      else
        if remaining_powerup_time(p) <= 0
          case p.type
          when :wide_hook
            state.hook.h = DEFAULT_HOOK_SIZE
          when :up_rock
            state.rock_manager.only_spawn_up_rocks = false
          when :gold_rush
            state.gold_modifier = 1.0
          when :eagle
            state.player.carried_by_eagle = false
          end
          state.player.powerups.delete(p)
        end
      end

      
    end
  end

  def handle_rock_effect(target_rock)
    case target_rock.type
    when :basic
      state.player.dy += PLAYER_JUMP_VELOCITY
      trigger_camera_shake(strength: 12, duration: 30)
    when :bomb
      state.player.dy += PLAYER_JUMP_VELOCITY
      trigger_camera_shake(strength: 30, duration: 120)
      state.rock_manager.rocks.reject! do |other_r|
        other_r != target_rock && Geometry.distance(target_rock, other_r) <= BOMB_ROCK_EXPLOSION_RADIUS
      end
    when :down
      state.player.dy += -PLAYER_JUMP_VELOCITY / 2
      trigger_camera_shake(strength: 50, duration: 20)
    when :up
      state.player.dy += PLAYER_BOOSTED_JUMP_VELOCITY
      trigger_camera_shake(strength: 50, duration: 20)
    when :shop
      open_shop
      state.player.dy += PLAYER_JUMP_VELOCITY
      trigger_camera_shake(strength: 12, duration: 30)
    when :gold
      state.player.dy += PLAYER_JUMP_VELOCITY
      trigger_camera_shake(strength: 12, duration: 30)
      state.player.gold += 5 * state.gold_modifier
    when :default
      state.player.dy += PLAYER_JUMP_VELOCITY
      trigger_camera_shake(strength: 12, duration: 30)
    end
    register_combo_grapple
    state.rock_manager.rocks.delete(target_rock)
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

  def open_shop
    state.paused_tick = Kernel.tick_count
    state.shop_open_tick = Kernel.tick_count
    state.shop_items.clear
    padding = 64
    item_option_width = 256
    start_x = (Grid.w / 2) - (item_option_width) - padding
    2.times.each_with_index do |i|
      new_item_option = send("#{POWERUP_TYPES.sample}_powerup")
      state.shop_items << shop_item(item_id: new_item_option.type, price: Numeric.rand(25..100), display_name: new_item_option.name, x: start_x + ((item_option_width + padding) * i), y: (Grid.h / 2) - (256 / 2))
    end
  end

  def calc_current_difficulty_levers
    if state.run_started_tick
      elapsed = state.run_started_tick.elapsed_time
    else
      elapsed = 0.0
    end

    if elapsed < EASY_TO_MEDIUM_DIFFICULTY_DURATION
      t = elapsed.fdiv(EASY_TO_MEDIUM_DIFFICULTY_DURATION).clamp(0, 1)

      {
        min_rock_spawn_delay: EASY_MIN_ROCK_SPAWN_DELAY.lerp(MEDIUM_MIN_ROCK_SPAWN_DELAY, t),
        max_rock_spawn_delay: EASY_MAX_ROCK_SPAWN_DELAY.lerp(MEDIUM_MAX_ROCK_SPAWN_DELAY, t),
        min_down_rock_spawn_countdown: EASY_MIN_DOWN_ROCK_SPAWN_COUNTDOWN.lerp(MEDIUM_MIN_DOWN_ROCK_SPAWN_COUNTDOWN, t).round,
        max_down_rock_spawn_countdown: EASY_MAX_DOWN_ROCK_SPAWN_COUNTDOWN.lerp(MEDIUM_MAX_DOWN_ROCK_SPAWN_COUNTDOWN, t).round,
        min_special_rock_spawn_countdown: EASY_MIN_SPECIAL_ROCK_SPAWN_COUNTDOWN.lerp(MEDIUM_MIN_SPECIAL_ROCK_SPAWN_COUNTDOWN, t).round,
        max_special_rock_spawn_countdown: EASY_MAX_SPECIAL_ROCK_SPAWN_COUNTDOWN.lerp(MEDIUM_MAX_SPECIAL_ROCK_SPAWN_COUNTDOWN, t).round,
        min_rock_fall_speed: EASY_MIN_ROCK_FALL_SPEED.lerp(MEDIUM_MIN_ROCK_FALL_SPEED, t),
        max_rock_fall_speed: EASY_MAX_ROCK_FALL_SPEED.lerp(MEDIUM_MAX_ROCK_FALL_SPEED, t),
      }
    else
      t = (elapsed - EASY_TO_MEDIUM_DIFFICULTY_DURATION).fdiv(MEDIUM_TO_HARD_DIFFICULTY_DURATION).clamp(0, 1)

      {
        min_rock_spawn_delay: MEDIUM_MIN_ROCK_SPAWN_DELAY.lerp(HARD_MIN_ROCK_SPAWN_DELAY, t),
        max_rock_spawn_delay: MEDIUM_MAX_ROCK_SPAWN_DELAY.lerp(HARD_MAX_ROCK_SPAWN_DELAY, t),
        min_down_rock_spawn_countdown: MEDIUM_MIN_DOWN_ROCK_SPAWN_COUNTDOWN.lerp(HARD_MIN_DOWN_ROCK_SPAWN_COUNTDOWN, t).round,
        max_down_rock_spawn_countdown: MEDIUM_MAX_DOWN_ROCK_SPAWN_COUNTDOWN.lerp(HARD_MAX_DOWN_ROCK_SPAWN_COUNTDOWN, t).round,
        min_special_rock_spawn_countdown: MEDIUM_MIN_SPECIAL_ROCK_SPAWN_COUNTDOWN.lerp(HARD_MIN_SPECIAL_ROCK_SPAWN_COUNTDOWN, t).round,
        max_special_rock_spawn_countdown: MEDIUM_MAX_SPECIAL_ROCK_SPAWN_COUNTDOWN.lerp(HARD_MAX_SPECIAL_ROCK_SPAWN_COUNTDOWN, t).round,
        min_rock_fall_speed: MEDIUM_MIN_ROCK_FALL_SPEED.lerp(HARD_MIN_ROCK_FALL_SPEED, t),
        max_rock_fall_speed: MEDIUM_MAX_ROCK_FALL_SPEED.lerp(HARD_MAX_ROCK_FALL_SPEED, t),
      }
    end
  end

  def calc_end_game
    enable_input
    state.hook.hit_target = nil
    state.run_started_tick = nil
    state.total_time_paused = 0
    state.run_ended_tick = Kernel.tick_count
    state.player = initial_player
    state.hook = initial_hook
    reset_combo
  end

  def reset_combo
    state.combo_manager.grapple_count = 0
    state.combo_manager.last_grapple_active_tick = nil
    state.combo_manager.particles.clear
  end

  def shutdown
    DR.write_file "data/save.txt", "#{state.longest_run_time}" if state.longest_run_time
  end

  def initial_hook
    {
      x: (state.player.x / 2) - 4,
      y: (state.player.y / 2) - 4,
      w: 16,
      h: DEFAULT_HOOK_SIZE,
      r: 255,
      g: 0,
      b: 0,
      a: 255,
      direction: 1,
      active: false,
      hit_target: nil
    }
  end

  def initial_player
    {
      x: Grid.w / 2 - 16,
      y: Grid.h - 64,
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
      gold: 0,
      powerups: [],
      carried_by_eagle: false,
    }
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

  def gold_rock(spawn_x:, fall_speed:)
    {
      x: spawn_x,
      y: 720,
      w: 16,
      h: 16,
      r: 230,
      g: 230,
      b: 80,
      dy: fall_speed,
      type: :gold,
    }
  end

  def shop_rock(spawn_x:, fall_speed:)
    {
      x: spawn_x,
      y: 720,
      w: 16,
      h: 16,
      r: 120,
      g: 255,
      b: 120,
      dy: fall_speed,
      type: :shop,
    }
  end

  def gold(spawn_x:, fall_speed:)
    {
      x: spawn_x,
      y: 720,
      w: 8,
      h: 8,
      r: 255,
      g: 255,
      b: 80,
      dy: fall_speed * 1.5,
      type: :shop
    }
  end

  def start_instructions_label
    {
      x: Grid.w / 2,
      y: Grid.h / 2,
      anchor_x: 0.5,
      anchor_y: 0.5,
      size_px: 96,
      text: "Press A or D to Play",
      r: 140,
      g: 255,
      b: 140,
    }
  end

  def run_timer_label
    ticks_factoring_pause_elapsed = (state.run_started_tick ? state.run_started_tick.elapsed_time : 0) - state.total_time_paused
    ticks_elapsed = ticks_factoring_pause_elapsed
    timer_value_seconds = ticks_elapsed / 60
    
    {
      x: Grid.w / 2,
      y: Grid.h - 32,
      anchor_x: 0.5,
      anchor_y: 0.5,
      size_px: 64,
      text: "#{timer_value_seconds.round(1)}",
      r: 140,
      g: 255,
      b: 140,
    }
  end

  def longest_run_time_label
      {
      x: 32,
      y: Grid.h - 32,
      anchor_x: 0.5,
      anchor_y: 0.5,
      size_px: 32,
      text: "#{state.longest_run_time}",
      r: 140,
      g: 255,
      b: 140,
    }
  end

  def gold_label
      {
      x: Grid.w - 32,
      y: Grid.h - 32,
      anchor_x: 0.5,
      anchor_y: 0.5,
      size_px: 32,
      text: "#{state.player.gold.round(0)}",
      r: 255,
      g: 255,
      b: 100,
    }
  end

  def powerup_timer_label(time_left:, y:, display_name:)
    {
      x: Grid.w / 2,
      y: y,
      anchor_x: 0.5,
      anchor_y: 0.5,
      size_px: 32,
      text: "#{display_name} - #{(time_left / 60).round(1)}",
      r: 140,
      g: 255,
      b: 250,
    }
  end

  def combo_reset_time_remaining
    return 0 unless combo_timer_active?

    (COMBO_RESET_DURATION - combo_elapsed_since_last_grapple).clamp(0, COMBO_RESET_DURATION)
  end

  def combo_reset_progress
    combo_reset_time_remaining.fdiv(COMBO_RESET_DURATION).clamp(0, 1)
  end

  def combo_timer_backdrop_rect
    {
      x: Grid.w / 2 - 80,
      y: Grid.h - 78,
      w: 160,
      h: 10,
      r: 20,
      g: 20,
      b: 20,
      a: 180,
    }
  end

  def combo_timer_fill_rect
    combo_timer_backdrop_rect.merge(
      w: 160 * combo_reset_progress,
      r: 255,
      g: 220,
      b: 80,
      a: 220,
    )
  end

  def combo_count_label
    {
      x: Grid.w / 2,
      y: Grid.h - 96,
      anchor_x: 0.5,
      anchor_y: 0.5,
      size_px: 24,
      text: "Combo #{state.combo_manager.grapple_count}",
      r: 255,
      g: 245,
      b: 120,
      a: 255,
    }
  end

  def wide_hook_powerup(spawn_x: 0)
    {
      x: spawn_x,
      y: 720,
      w: 32,
      h: 32,
      r: 255,
      g: 0,
      b: 255,
      name: "Wide Hook",
      start_tick: Kernel.tick_count,
      type: :wide_hook,
      duration: 10.0.seconds,
      active: false,
    }
  end

  def up_rock_powerup(spawn_x: 0)
    {
      x: spawn_x,
      y: 720,
      w: 32,
      h: 32,
      r: 0,
      g: 255,
      b: 255,
      name: "Boost Rock Avalanche",
      start_tick: Kernel.tick_count,
      type: :up_rock,
      duration: 10.0.seconds,
      active: false,
    }
  end

  def gold_rush_powerup(spawn_x: 0)
    {
      x: spawn_x,
      y: 720,
      w: 32,
      h: 32,
      r: 255,
      g: 255,
      b: 0,
      name: "Gold Rush!(2x $)",
      start_tick: Kernel.tick_count,
      type: :gold_rush,
      duration: 15.seconds,
      active: false,
    }
  end

  def eagle_powerup(spawn_x: 0)
    {
      x: spawn_x,
      y: 720,
      w: 32,
      h: 32,
      r: 255,
      g: 105,
      b: 180,
      name: "Eagle",
      start_tick: Kernel.tick_count,
      type: :eagle,
      duration: 10.seconds,
      active: false,
    }
  end
end
