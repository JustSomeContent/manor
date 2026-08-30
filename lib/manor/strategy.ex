defmodule Manor.Strategy do
  @moduledoc """
  A bot: a module that looks at a game and names the next command.

  This is the honest home for a behaviour — a pluggable module fulfilling a
  role, chosen at runtime (`Manor.Autoplay.run(Manor.Strategy.Greedy, ...)`).
  Compare with `Manor.Effect`, where plain data won: effects are *content*,
  strategies are *logic*.
  """

  alias Manor.Game

  @doc "The next command to attempt. Called only while the game is not over."
  @callback next_command(Game.t()) :: Game.command()
end

defmodule Manor.Strategy.Random do
  @moduledoc """
  The chaos bot: random draft choices, random walks. **PROVIDED.**

  Note it uses the process-dictionary `:rand` API — the one the pure core
  bans. A strategy is a *caller* of the core, not part of it, so hidden
  process state is acceptable here; tests that want determinism seed the
  test process with `:rand.seed/2` first. Feel the difference.
  """

  @behaviour Manor.Strategy

  alias Manor.Game

  @impl Manor.Strategy
  def next_command(%Game{phase: {:drafting, draft}}) do
    {:choose, :rand.uniform(length(draft.candidates))}
  end

  def next_command(%Game{}) do
    {:move, Enum.random([:north, :east, :south, :west])}
  end
end

defmodule Manor.Strategy.Greedy do
  @moduledoc """
  The summit bot: always tries to climb.

  Drafting, it prefers affordable candidates that keep a north door (an
  onward exit); walking, it prefers unexplored doorways over rooms it has
  already seen, and north over everything.
  """

  @behaviour Manor.Strategy

  alias Manor.{Game, Mansion, Resources, Room}

  @impl Manor.Strategy
  def next_command(%Game{phase: {:drafting, draft}} = game) do
    gems = Resources.get(game.resources, :gems)
    affordable? = fn room -> room.gem_cost <= gems end

    index =
      Enum.find_index(draft.candidates, &(affordable?.(&1) and Room.has_door?(&1, :north))) ||
        Enum.find_index(draft.candidates, affordable?) ||
        0

    {:choose, index + 1}
  end

  def next_command(%Game{} = game) do
    passages =
      for direction <- [:north, :east, :west, :south],
          passage = Mansion.passage(game.mansion, game.player, direction),
          passage != :wall,
          do: {direction, passage}

    frontier = Enum.find(passages, fn {d, p} -> d != :south and match?({:unbuilt, _, _}, p) end)
    north = Enum.find(passages, fn {d, _p} -> d == :north end)
    fallback = List.first(passages)

    case frontier || north || fallback do
      {direction, _passage} -> {:move, direction}
      nil -> {:move, :north}
    end
  end
end
