require_relative "game"

module Main

  def start args
    $game = Game.new args
    $game.args = args
    $game.start
  end

  def tick args
    $game.args = args
    $game.tick
  end
end
