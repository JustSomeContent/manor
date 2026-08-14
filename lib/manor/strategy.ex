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

  alias Manor.Game

  @doc """
  ## Part 9 hints
  Two phase clauses, like Random.

  Drafting: `Enum.find_index/2` for the first affordable candidate
  (`gem_cost <= gems`) with a north door, `||` the first affordable one,
  `||` index 0; `{:choose, index + 1}`.

  Walking: collect `{direction, Manor.Mansion.passage(...)}` for the four
  directions (a comprehension with a filter dropping `:wall` reads well),
  then prefer — in order — a non-south `{:unbuilt, _, _}` (the frontier!),
  a built `:north`, any first passage; `{:move, :north}` as the desperate
  fallback (it will be rejected; the bot survives rejection).
  """
  @impl Manor.Strategy
  def next_command(%Game{} = _game) do
    # TODO(Part 9)
    Manor.NotImplemented.todo!(part: 9, fun: "Manor.Strategy.Greedy.next_command/1")
  end
end
