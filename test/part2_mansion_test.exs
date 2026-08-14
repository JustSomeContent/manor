defmodule Manor.Part2MansionTest do
  use ExUnit.Case, async: true

  alias Manor.{Fixtures, Grid, Mansion, PlacedRoom}

  @moduletag part: 2

  defp mansion_with(placements) do
    Enum.reduce(placements, Mansion.new(Fixtures.entrance()), fn {id, overrides, coord},
                                                                 mansion ->
      {:ok, mansion} = Mansion.place(mansion, PlacedRoom.new(Fixtures.room(id, overrides), coord))
      mansion
    end)
  end

  describe "2.5 new/1, fetch/2, built?/2" do
    test "2.5-R1 a new mansion has exactly the entrance, at the entrance" do
      mansion = Mansion.new(Fixtures.entrance())

      assert {:ok, %PlacedRoom{room: %{category: :entrance}}} =
               Mansion.fetch(mansion, Grid.entrance())

      assert Mansion.built?(mansion, Grid.entrance())
    end

    test "2.5-R2 every other cell is unbuilt — fetch returns :error, not nil" do
      mansion = Mansion.new(Fixtures.entrance())
      refute Mansion.built?(mansion, {3, 2})
      assert Mansion.fetch(mansion, {3, 2}) == :error
    end
  end

  describe "2.6 place/2" do
    test "2.6-R1 placing builds the cell" do
      mansion = mansion_with([{:hall, [], {3, 2}}])
      assert {:ok, %PlacedRoom{room: %{id: :hall}}} = Mansion.fetch(mansion, {3, 2})
    end

    test "2.6-R2 placing into a built cell is refused" do
      mansion = mansion_with([{:hall, [], {3, 2}}])
      intruder = PlacedRoom.new(Fixtures.room(:garden), {3, 2})
      assert Mansion.place(mansion, intruder) == {:error, :occupied}
    end
  end

  describe "2.7 can_connect?/2" do
    test "2.7-R1 walking north needs a south door on the newcomer" do
      assert Mansion.can_connect?(Fixtures.room(:hall), :north)
      refute Mansion.can_connect?(Fixtures.room(:tower, doors: %{north: :open}), :north)
    end

    test "2.7-R2 a locked connecting door still connects" do
      cellar = Fixtures.room(:cellar, doors: %{south: :locked})
      assert Mansion.can_connect?(cellar, :north)
    end
  end

  describe "2.9 passage/3" do
    test "2.9-R1 mutual open doors make an open passage" do
      mansion = mansion_with([{:hall, [], {3, 2}}])
      assert Mansion.passage(mansion, Grid.entrance(), :north) == {:built, :open, {3, 2}}
      assert Mansion.passage(mansion, {3, 2}, :south) == {:built, :open, Grid.entrance()}
    end

    test "2.9-R2 no door on our side is a wall, even if the neighbor has one" do
      mansion = mansion_with([{:hall, [], {3, 2}}])
      # The entrance has no south door; rank 1's south is also the grid edge.
      assert Mansion.passage(mansion, Grid.entrance(), :south) == :wall
      # Hall has no east door.
      assert Mansion.passage(mansion, {3, 2}, :east) == :wall
    end

    test "2.9-R3 a door into a doorless neighbor wall is a wall" do
      # Hall at {3,2} has a north door; tower at {3,3} has only a north door — no mutual edge.
      mansion = mansion_with([{:hall, [], {3, 2}}, {:tower, [doors: %{north: :open}], {3, 3}}])
      assert Mansion.passage(mansion, {3, 2}, :north) == :wall
    end

    test "2.9-R4 our door onto an unbuilt cell reports :unbuilt with our lock state" do
      mansion =
        mansion_with([
          {:hall, [], {3, 2}},
          {:cellar, [doors: %{south: :locked, north: :locked}], {3, 3}}
        ])

      assert Mansion.passage(mansion, {3, 2}, :north) == {:built, :locked, {3, 3}}
      assert Mansion.passage(mansion, {3, 3}, :north) == {:unbuilt, :locked, {3, 4}}
    end

    test "2.9-R5 locked on either side locks the passage" do
      mansion = mansion_with([{:cellar, [doors: %{south: :locked}], {3, 2}}])
      assert Mansion.passage(mansion, Grid.entrance(), :north) == {:built, :locked, {3, 2}}
    end

    test "2.9-R6 the grid edge is a wall even with a door pointing at it" do
      mansion = mansion_with([{:edge, [doors: %{west: :open, east: :open}], {2, 1}}])
      # {2,1}'s west neighbor {1,1} is merely unbuilt; but from an edge cell,
      # a door pointing off-grid is a wall. Walk it over and check.
      mansion = mansion_with_edge_cell(mansion)
      assert Mansion.passage(mansion, {1, 1}, :west) == :wall
    end

    defp mansion_with_edge_cell(mansion) do
      {:ok, mansion} =
        Mansion.place(
          mansion,
          PlacedRoom.new(Fixtures.room(:corner, doors: %{west: :open, east: :open}), {1, 1})
        )

      mansion
    end
  end

  describe "2.8 unlock/3" do
    test "2.8-R1 unlocking opens the shared edge from both sides" do
      mansion = mansion_with([{:cellar, [doors: %{south: :locked}], {3, 2}}])
      mansion = Mansion.unlock(mansion, Grid.entrance(), :north)

      assert Mansion.passage(mansion, Grid.entrance(), :north) == {:built, :open, {3, 2}}
      assert Mansion.passage(mansion, {3, 2}, :south) == {:built, :open, Grid.entrance()}
    end
  end
end
