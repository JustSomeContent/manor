defmodule Manor.Part9RenderTest do
  use ExUnit.Case, async: true

  alias Manor.{Fixtures, Game, Render, Resources}

  import Manor.GameHelpers

  @moduletag part: 9

  defp small_game do
    Game.new(Fixtures.config())
    |> place!(Fixtures.room(:hall, code: "HA"), {3, 2})
    |> place!(Fixtures.room(:cellar, code: "CE", doors: %{west: :locked, south: :open}), {4, 2})
  end

  describe "9.1 iodata discipline" do
    test "9.1-R1 render/1 returns iodata (lists, not one big binary)" do
      rendered = Render.render(small_game())
      assert is_list(rendered)
      assert is_binary(IO.iodata_to_binary(rendered))
    end

    test "9.1-R2 grid/1 too" do
      assert is_list(Render.grid(small_game()))
    end
  end

  describe "9.2 the grid, golden" do
    test "9.2-R1 rank 1 renders the entrance with the player inside" do
      lines = small_game() |> Render.to_string() |> String.split("\n")

      assert Enum.slice(lines, 24, 3) == [
               "· · · · · · ┌─ ─┐ · · · · · ·",
               "· · · · · ·  EN@  · · · · · ·",
               "· · · · · · └───┘ · · · · · ·"
             ]
    end

    test "9.2-R2 rank 2 shows the hall, the locked cellar door, and no player marker" do
      lines = small_game() |> Render.to_string() |> String.split("\n")

      assert Enum.slice(lines, 21, 3) == [
               "· · · · · · ┌─ ─┐ ┌───┐ · · ·",
               "· · · · · · │HA │ ▒CE │ · · ·",
               "· · · · · · └─ ─┘ └─ ─┘ · · ·"
             ]
    end

    test "9.2-R3 the frame is 27 grid lines, all equally wide" do
      lines = small_game() |> Render.to_string() |> String.split("\n") |> Enum.take(27)
      assert length(lines) == 27
      assert lines |> Enum.map(&String.length/1) |> Enum.uniq() == [29]
    end
  end

  describe "9.3 protocols at work" do
    test "9.3-R1 String.Chars for Resources drives the status bar" do
      assert to_string(%Resources{steps: 17, keys: 1, gems: 3, coins: 5}) ==
               "Steps 17 | Keys 1 | Gems 3 | Coins 5"

      status = small_game() |> Render.status_bar() |> IO.iodata_to_binary()
      assert status =~ "Steps 40 | Keys 1 | Gems 2 | Coins 0"
      assert status =~ "Turn 0"
    end

    test "9.3-R2 String.Chars for Room reads like a card" do
      assert to_string(Fixtures.room(:garden, rarity: :standard)) == "Garden (standard)"
    end

    test "9.3-R3 the custom Inspect keeps IEx terse" do
      rendered = inspect(small_game())
      assert rendered =~ "#Manor.Game<"
      assert rendered =~ "steps: 40"
      refute rendered =~ "mansion"
    end
  end

  describe "9.4 describe/1" do
    test "9.4-R1 every log entry becomes prose" do
      assert IO.iodata_to_binary(Render.describe({:moved, {3, 2}})) == "Moved to {3, 2}."
      assert IO.iodata_to_binary(Render.describe({:granted, :gems, 2})) == "+2 gems"
      assert IO.iodata_to_binary(Render.describe({:crafted, :lockpick})) == "Crafted: lockpick!"
      assert IO.iodata_to_binary(Render.describe({:day_over, :out_of_steps})) =~ "over"
    end
  end

  describe "9.5 the draft prompt" do
    test "9.5-R1 candidates are listed, numbered, with doors and cost" do
      {:ok, drafting} =
        Game.new(
          Fixtures.config(
            rooms: [Fixtures.room(:vault, gem_cost: 2, doors: %{south: :open, north: :locked})]
          )
        )
        |> Game.move(:north)

      frame = Render.to_string(drafting)
      assert frame =~ "1) Vault [commonplace] doors n*,s — 2 gems"
    end
  end
end
