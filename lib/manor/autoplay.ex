defmodule Manor.Autoplay do
  @moduledoc """
  Drive a whole day headlessly with a `Manor.Strategy` bot — no processes,
  no IO, just the pure core folded over the bot's commands.

  This doubles as the lab's integration harness: "a random bot with seed X
  never crashes the core in 500 commands" exercises every rule at once.
  """

  alias Manor.{Game, RunConfig}

  @doc """
  Run `strategy` against a fresh day until the day ends or `max_commands`
  have been attempted. Returns the final game.

  ## Part 9 hints
  Tail recursion with a countdown. A rejected command (`{:error, _}` —
  the bot walked into a wall) still counts against the budget and the
  game carries on unchanged; that is the error philosophy paying rent.
  `Game.over?/1` is the other exit.
  """
  @spec run(module(), RunConfig.t(), non_neg_integer()) :: Game.t()
  def run(strategy, %RunConfig{} = _config, max_commands)
      when is_atom(strategy) and is_integer(max_commands) and max_commands >= 0 do
    # TODO(Part 9)
    Manor.NotImplemented.todo!(part: 9, fun: "Manor.Autoplay.run/3")
  end
end
