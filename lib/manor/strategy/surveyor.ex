defmodule Manor.Strategy.Surveyor do
  @moduledoc """
  The mapping bot: benchmark-bred successor to `Manor.Strategy.Greedy`.

  Born from `Manor.Benchmark` baselines (50 seeds): Greedy won 32% of
  days, and every loss was the same death — no pathing beyond adjacent
  cells, so once the local frontier closed it paced until its steps ran
  out (~25 revisits/day), having drafted dead-end rooms it couldn't see
  past and bought nothing, ever.

  Surveyor's three fixes, in priority order each turn:

    1. **Economy** — in a shop, buy a key when keyless or steps when
       tired (chosen by the offer's `grants`, not a hardcoded id); in a
       workshop, craft a lockpick when keyless with parts in the bag.
    2. **Pathing** — walk through an adjacent frontier door if one is
       openable; otherwise BFS across built passages to the *nearest*
       cell with one and take the first step of that path. Locked
       passages count as walkable only while a key or lockpick is held.
    3. **Honesty** — no reachable frontier (or no affordable draft)
       means the day is unwinnable: `:rest`, never a pacing loop.

  Drafting is scored, not first-match: a north door below the goal rank
  is worth the most, every onward exit helps, and a dead end — a room
  whose only door faces the way you came — is punished. Gem cost breaks
  ties downward.
  """

  @behaviour Manor.Strategy

  alias Manor.{Game, Grid, Mansion, Resources}

  @directions [:north, :east, :west, :south]

  @impl Manor.Strategy
  def next_command(%Game{phase: {:drafting, draft}} = game) do
    gems = Resources.get(game.resources, :gems)

    best =
      draft.candidates
      |> Enum.with_index(1)
      |> Enum.filter(fn {room, _index} -> room.gem_cost <= gems end)
      |> Enum.max_by(fn {room, _index} -> draft_score(room, draft) end, fn -> nil end)

    case best do
      {_room, index} -> {:choose, index}
      nil -> :rest
    end
  end

  def next_command(%Game{} = game) do
    cond do
      command = shopping(game) -> command
      command = crafting(game) -> command
      direction = adjacent_frontier(game) -> {:move, direction}
      direction = step_toward_frontier(game) -> {:move, direction}
      true -> :rest
    end
  end

  ## Drafting — score the room's future, not just its north door

  defp draft_score(room, %{dest: {_col, rank}, entered_via: entered_via}) do
    doors = Map.keys(room.doors)
    onward = doors -- [Grid.opposite(entered_via)]

    north_bonus = if :north in doors and rank < Grid.goal_rank(), do: 100, else: 0
    dead_end_penalty = if onward == [], do: -50, else: 0

    north_bonus + 10 * length(onward) + dead_end_penalty - room.gem_cost
  end

  ## Economy — wants are read off the offers' grants, not their ids

  defp shopping(%Game{} = game) do
    if in_category?(game, :shop) do
      coins = Resources.get(game.resources, :coins)

      wanted? = fn
        {:grant, :keys, _n} -> Resources.get(game.resources, :keys) == 0
        {:grant, :steps, _n} -> Resources.get(game.resources, :steps) <= 10
        _grant -> false
      end

      offer = Enum.find(game.config.shop_offers, &(wanted?.(&1.grants) and &1.price <= coins))
      offer && {:buy, offer.id}
    end
  end

  defp crafting(%Game{} = game) do
    if in_category?(game, :workshop) and not can_unlock?(game) and
         Map.get(game.inventory, :shovel, 0) > 0 and Map.get(game.inventory, :cog, 0) > 0 do
      {:combine, :shovel, :cog}
    end
  end

  ## Pathing — nearest frontier by BFS over built, passable edges

  defp adjacent_frontier(%Game{} = game) do
    Enum.find(@directions, fn direction ->
      openable_frontier?(game, game.player, direction)
    end)
  end

  defp step_toward_frontier(%Game{} = game) do
    start =
      for direction <- @directions,
          dest = walkable_dest(game, game.player, direction),
          dest != nil,
          do: {dest, direction}

    seen = MapSet.new([game.player | Enum.map(start, fn {dest, _d} -> dest end)])
    bfs(game, start, seen)
  end

  # Each frontier candidate carries the FIRST step that reached it, so
  # finding the target immediately yields the move to make.
  defp bfs(_game, [], _seen), do: nil

  defp bfs(game, layer, seen) do
    case Enum.find(layer, fn {cell, _first} -> frontier_cell?(game, cell) end) do
      {_cell, first_step} ->
        first_step

      nil ->
        {next_layer, seen} =
          Enum.reduce(layer, {[], seen}, fn {cell, first}, acc ->
            expand(game, cell, first, acc)
          end)

        bfs(game, Enum.reverse(next_layer), seen)
    end
  end

  defp expand(game, cell, first, {layer, seen}) do
    Enum.reduce(@directions, {layer, seen}, fn direction, {layer, seen} ->
      dest = walkable_dest(game, cell, direction)

      if dest != nil and not MapSet.member?(seen, dest) do
        {[{dest, first} | layer], MapSet.put(seen, dest)}
      else
        {layer, seen}
      end
    end)
  end

  defp walkable_dest(game, cell, direction) do
    case Mansion.passage(game.mansion, cell, direction) do
      {:built, :open, dest} -> dest
      {:built, :locked, dest} -> if can_unlock?(game), do: dest
      _wall_or_unbuilt -> nil
    end
  end

  defp frontier_cell?(game, cell) do
    Enum.any?(@directions, &openable_frontier?(game, cell, &1))
  end

  defp openable_frontier?(game, cell, direction) do
    case Mansion.passage(game.mansion, cell, direction) do
      {:unbuilt, :open, _dest} -> true
      {:unbuilt, :locked, _dest} -> can_unlock?(game)
      _built_or_wall -> false
    end
  end

  defp can_unlock?(game) do
    Resources.get(game.resources, :keys) > 0 or Map.get(game.inventory, :lockpick, 0) > 0
  end

  defp in_category?(game, category) do
    {:ok, placed} = Mansion.fetch(game.mansion, game.player)
    placed.room.category == category
  end
end
