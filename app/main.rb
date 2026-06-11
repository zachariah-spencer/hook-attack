require_relative "game"

module Main
  def tick args
    $game ||= Game.new args
    $game.args = args
    $game.tick
  end
end
