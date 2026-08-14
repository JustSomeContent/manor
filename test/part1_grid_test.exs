defmodule Manor.Part1GridTest do
  use ExUnit.Case, async: true

  alias Manor.Grid

  @moduletag part: 1

  describe "1.1 constants and bounds" do
    test "1.1-R1 the entrance is the center of rank 1" do
      assert Grid.entrance() == {3, 1}
    end

    test "1.1-R2 the goal rank is 9" do
      assert Grid.goal_rank() == 9
    end

    test "1.1-R3 in_bounds?/1 accepts every cell of the 5x9 grid" do
      for col <- 1..5, rank <- 1..9 do
        assert Grid.in_bounds?({col, rank})
      end
    end

    test "1.1-R4 in_bounds?/1 rejects coordinates outside the grid" do
      refute Grid.in_bounds?({0, 1})
      refute Grid.in_bounds?({6, 1})
      refute Grid.in_bounds?({1, 0})
      refute Grid.in_bounds?({1, 10})
      refute Grid.in_bounds?(:not_a_coord)
    end
  end

  describe "1.2 step/2" do
    test "1.2-R1 north increases the rank" do
      assert Grid.step({3, 1}, :north) == {:ok, {3, 2}}
    end

    test "1.2-R2 south, east, and west move as expected" do
      assert Grid.step({3, 5}, :south) == {:ok, {3, 4}}
      assert Grid.step({3, 5}, :east) == {:ok, {4, 5}}
      assert Grid.step({3, 5}, :west) == {:ok, {2, 5}}
    end

    test "1.2-R3 stepping off the grid is a tagged error" do
      assert Grid.step({3, 9}, :north) == {:error, :off_grid}
      assert Grid.step({3, 1}, :south) == {:error, :off_grid}
      assert Grid.step({5, 5}, :east) == {:error, :off_grid}
      assert Grid.step({1, 5}, :west) == {:error, :off_grid}
    end
  end

  describe "1.3 opposite/1" do
    test "1.3-R1 every direction has its opposite" do
      assert Grid.opposite(:north) == :south
      assert Grid.opposite(:south) == :north
      assert Grid.opposite(:east) == :west
      assert Grid.opposite(:west) == :east
    end
  end

  describe "1.4 all_coords/0" do
    test "1.4-R1 45 coordinates, all in bounds, no duplicates" do
      coords = Grid.all_coords()
      assert length(coords) == 45
      assert Enum.all?(coords, &Grid.in_bounds?/1)
      assert coords == Enum.uniq(coords)
    end
  end
end
