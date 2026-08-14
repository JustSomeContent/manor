defmodule Manor.Part6GameApiTest do
  use ExUnit.Case, async: true

  alias Manor.{Fixtures, Game, Resources, RunConfig}

  import Manor.GameHelpers

  @moduletag part: 6

  # Doctests are docs that can't rot: the iex> examples in Manor.Grid's
  # @doc strings run as tests from here on.
  doctest Manor.Grid

  describe "6.1 RunConfig.default/1" do
    test "6.1-R1 defaults: 40 steps, 1 key, 2 gems, 0 coins, full catalog" do
      config = RunConfig.default(seed: 7)

      assert %Resources{steps: 40, keys: 1, gems: 2, coins: 0} = config.starting_resources
      assert config.seed == 7
      assert config.rooms == Manor.Catalog.rooms()
      assert config.entrance.category == :entrance
      assert config.fallback.id == :closet
    end

    test "6.1-R2 any resource can be overridden" do
      config = RunConfig.default(seed: 7, steps: 5, gems: 0)
      assert %Resources{steps: 5, keys: 1, gems: 0} = config.starting_resources
    end

    test "6.1-R3 unknown options raise — Keyword.validate! guards the boundary" do
      assert_raise ArgumentError, fn -> RunConfig.default(seed: 7, stpes: 50) end
    end
  end

  describe "6.2 Game.command/2" do
    test "6.2-R1 every command shape dispatches to its rule" do
      game = Game.new(Fixtures.config())

      assert {:ok, _} = Game.command(game, {:move, :north})
      assert {:error, :no_draft_pending} = Game.command(game, {:choose, 1})
      assert {:error, :not_in_shop} = Game.command(game, {:buy, :trail_mix})
      assert {:error, :not_in_workshop} = Game.command(game, {:combine, :cog, :cog})
    end
  end

  describe "6.3 summary/1" do
    test "6.3-R1 a fresh day summarizes as active and empty" do
      summary = Game.new(Fixtures.config()) |> Game.summary()

      assert summary.outcome == :active
      assert summary.turns == 0
      assert summary.rooms_placed == 0
      assert %Resources{} = summary.resources
    end
  end

  describe "6.4 a whole day, purely" do
    test "6.4-R1 the golden run: eight drafts straight up the middle wins" do
      commands =
        Enum.flat_map(1..8, fn _rank -> [{:move, :north}, {:choose, 1}] end)

      game = play!(Game.new(Fixtures.config(seed: 53)), commands)

      assert game.phase == {:ended, :won}

      summary = Game.summary(game)
      assert summary.outcome == :won
      assert summary.turns == 8
      assert summary.rooms_placed == 8
    end

    test "6.4-R2 the same seed replays the same day, summary and all" do
      commands = Enum.flat_map(1..8, fn _ -> [{:move, :north}, {:choose, 1}] end)

      summary_a = play!(Game.new(Fixtures.config(seed: 53)), commands) |> Game.summary()
      summary_b = play!(Game.new(Fixtures.config(seed: 53)), commands) |> Game.summary()

      assert summary_a == summary_b
    end
  end
end
