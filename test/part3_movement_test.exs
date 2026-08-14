defmodule Manor.Part3MovementTest do
  use ExUnit.Case, async: true

  alias Manor.{Fixtures, Game, Grid, Mansion, Resources}
  alias Manor.Game.Draft

  import Manor.GameHelpers

  @moduletag part: 3

  # A hand-built wing: entrance -> hall -> garden going north, and a locked
  # cellar east of the hall. No RNG anywhere — that's Part 4's problem.
  defp wing do
    Game.new(Fixtures.config())
    |> place!(Fixtures.room(:hall, doors: %{north: :open, south: :open, east: :open}), {3, 2})
    |> place!(Fixtures.room(:garden, effects: []), {3, 3})
    |> place!(Fixtures.room(:cellar, doors: %{west: :locked}), {4, 2})
  end

  describe "3.1 Game.new/1" do
    test "3.1-R1 the day starts in the entrance, awaiting a command" do
      game = Game.new(Fixtures.config())

      assert game.player == Grid.entrance()
      assert game.phase == :awaiting_command
      assert game.turn == 0
      assert game.inventory == %{}
      assert game.log == []
      assert %Resources{steps: 40, keys: 1, gems: 2, coins: 0} = game.resources
      assert Mansion.built?(game.mansion, Grid.entrance())
    end
  end

  describe "3.2 move/2 through built rooms" do
    test "3.2-R1 an open passage moves the player and costs one step" do
      game = wing()
      assert {:ok, moved} = Game.move(game, :north)

      assert moved.player == {3, 2}
      assert moved.resources.steps == game.resources.steps - 1
      assert moved.turn == game.turn + 1
    end

    test "3.2-R2 entering bumps the room's entered_count" do
      {:ok, moved} = Game.move(wing(), :north)
      assert {:ok, placed} = Mansion.fetch(moved.mansion, {3, 2})
      assert placed.entered_count == 1
    end

    test "3.2-R3 a wall is refused and the game is exactly unchanged" do
      game = wing()
      assert Game.move(game, :south) == {:error, :wall}
    end

    test "3.2-R4 the move lands in the log" do
      {:ok, moved} = Game.move(wing(), :north)
      assert {:moved, {3, 2}} in moved.log
    end
  end

  describe "3.3 locked doors" do
    test "3.3-R1 a locked door spends a key and stays open forever" do
      game = wing() |> play!([{:move, :north}])

      assert {:ok, at_cellar} = Game.move(game, :east)
      assert at_cellar.player == {4, 2}
      assert at_cellar.resources.keys == game.resources.keys - 1

      # Walk back and forth: no second key needed.
      back_and_forth = play!(at_cellar, [{:move, :west}, {:move, :east}])
      assert back_and_forth.resources.keys == at_cellar.resources.keys
    end

    test "3.3-R2 locked with no key is refused, and nothing was spent" do
      game = wing() |> set_resources(keys: 0) |> play!([{:move, :north}])
      steps_before = game.resources.steps

      assert Game.move(game, :east) == {:error, :locked_no_key}
      assert game.resources.steps == steps_before
    end
  end

  describe "3.4 running out of steps" do
    test "3.4-R1 a viable move with zero steps ends the day as {:ok, _}" do
      game = wing() |> set_resources(steps: 0)

      assert {:ok, over} = Game.move(game, :north)
      assert over.phase == {:ended, :out_of_steps}
      assert over.player == Grid.entrance()
    end

    test "3.4-R2 bumping a wall with zero steps does NOT end the day" do
      game = wing() |> set_resources(steps: 0)
      assert Game.move(game, :south) == {:error, :wall}
    end
  end

  describe "3.5 phase dispatch" do
    test "3.5-R1 no moving while a draft is pending" do
      draft = %Draft{dest: {3, 3}, entered_via: :north, candidates: [Fixtures.room(:hall)]}
      game = %{wing() | phase: {:drafting, draft}}
      assert Game.move(game, :north) == {:error, :draft_pending}
    end

    test "3.5-R2 no moving after the day ended" do
      game = %{wing() | phase: {:ended, :out_of_steps}}
      assert Game.move(game, :north) == {:error, :game_over}
    end
  end

  describe "3.6 winning by entering a goal room" do
    test "3.6-R1 stepping into a :goal room ends the day as won" do
      game =
        Game.new(Fixtures.config())
        |> place!(Fixtures.room(:goal, category: :goal, doors: %{south: :open}), {3, 2})

      assert {:ok, won} = Game.move(game, :north)
      assert won.phase == {:ended, :won}
      assert Game.over?(won)
      assert Game.status(won) == :won
    end
  end

  describe "3.7 transcript/1" do
    test "3.7-R1 the transcript reads oldest-first" do
      game = wing() |> play!([{:move, :north}, {:move, :north}])
      moves = for {:moved, coord} <- Game.transcript(game), do: coord
      assert moves == [{3, 2}, {3, 3}]
    end
  end
end
