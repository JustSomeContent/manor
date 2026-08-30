defmodule Manor.AnnexBPropertyTest do
  # Annex B: invariant-thinking over example-thinking. A generator throws
  # hundreds of arbitrary command sequences at the pure core; these
  # properties must hold for every one of them. When one fails, StreamData
  # shrinks to the minimal failing sequence — the bug report writes itself.
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Manor.{Game, Grid, RunConfig}

  @items [:shovel, :cog, :lockpick, :spyglass]
  @offers [:trail_mix, :spare_key, :shovel, :cog]

  defp command_gen do
    frequency([
      {6, member_of([:north, :south, :east, :west]) |> map(&{:move, &1})},
      {3, integer(1..3) |> map(&{:choose, &1})},
      {1, member_of(@offers) |> map(&{:buy, &1})},
      {1,
       tuple({member_of(@items), member_of(@items)}) |> map(fn {a, b} -> {:combine, a, b} end)},
      {1, constant(:rest)}
    ])
  end

  defp play(seed, commands) do
    Enum.reduce(commands, Game.new(RunConfig.default(seed: seed)), fn command, game ->
      case Game.command(game, command) do
        {:ok, next} -> next
        {:error, _reason} -> game
      end
    end)
  end

  property "the core never raises, and resources never go negative" do
    check all seed <- integer(1..10_000),
              commands <- list_of(command_gen(), max_length: 120) do
      final = play(seed, commands)

      assert final.resources.steps >= 0
      assert final.resources.keys >= 0
      assert final.resources.gems >= 0
      assert final.resources.coins >= 0
    end
  end

  property "every placed room sits in bounds, and the player stands in a built cell" do
    check all seed <- integer(1..10_000),
              commands <- list_of(command_gen(), max_length: 120) do
      final = play(seed, commands)

      assert Enum.all?(Map.keys(final.mansion.rooms), &Grid.in_bounds?/1)
      assert Map.has_key?(final.mansion.rooms, final.player)
    end
  end

  property "same seed, same commands, same day — structurally identical" do
    check all seed <- integer(1..10_000),
              commands <- list_of(command_gen(), max_length: 60) do
      assert play(seed, commands) == play(seed, commands)
    end
  end
end
