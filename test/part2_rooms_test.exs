defmodule Manor.Part2RoomsTest do
  use ExUnit.Case, async: true

  alias Manor.{Fixtures, PlacedRoom, Room}

  @moduletag part: 2

  describe "2.1 Room.has_door?/2" do
    test "2.1-R1 present doors, open or locked, count as doors" do
      vault = Fixtures.room(:vault, doors: %{south: :open, north: :locked})
      assert Room.has_door?(vault, :south)
      assert Room.has_door?(vault, :north)
    end

    test "2.1-R2 an absent key is a wall" do
      vault = Fixtures.room(:vault, doors: %{south: :open})
      refute Room.has_door?(vault, :east)
    end
  end

  describe "2.2 Room.allowed_at?/2" do
    test "2.2-R1 ordinary rooms may go anywhere except the goal rank" do
      hall = Fixtures.room(:hall)
      assert Room.allowed_at?(hall, {3, 2})
      assert Room.allowed_at?(hall, {1, 8})
      refute Room.allowed_at?(hall, {3, 9})
    end

    test "2.2-R2 goal rooms only at rank 9" do
      goal = Fixtures.room(:goal, category: :goal)
      assert Room.allowed_at?(goal, {3, 9})
      refute Room.allowed_at?(goal, {3, 8})
    end

    test "2.2-R3 the entrance is never drafted" do
      refute Room.allowed_at?(Fixtures.entrance(), {3, 2})
    end
  end

  describe "2.3 PlacedRoom.new/2 and door/2" do
    test "2.3-R1 stamping copies the template's doors and starts unvisited" do
      template = Fixtures.room(:vault, doors: %{south: :open, north: :locked})
      placed = PlacedRoom.new(template, {2, 4})

      assert placed.coord == {2, 4}
      assert placed.room == template
      assert placed.entered_count == 0
      assert PlacedRoom.door(placed, :south) == :open
      assert PlacedRoom.door(placed, :north) == :locked
      assert PlacedRoom.door(placed, :east) == nil
    end
  end

  describe "2.4 PlacedRoom.unlock/2 and record_entry/1" do
    test "2.4-R1 unlocking a locked door opens the instance, not the template" do
      template = Fixtures.room(:vault, doors: %{north: :locked})
      placed = template |> PlacedRoom.new({2, 4}) |> PlacedRoom.unlock(:north)

      assert PlacedRoom.door(placed, :north) == :open
      assert template.doors == %{north: :locked}
    end

    test "2.4-R2 unlocking a wall or an open door is a harmless no-op" do
      placed = PlacedRoom.new(Fixtures.room(:hall), {3, 2})
      assert PlacedRoom.unlock(placed, :east) == placed
      assert PlacedRoom.unlock(placed, :north) == placed
    end

    test "2.4-R3 record_entry/1 counts entries" do
      placed = PlacedRoom.new(Fixtures.room(:hall), {3, 2})

      assert placed
             |> PlacedRoom.record_entry()
             |> PlacedRoom.record_entry()
             |> Map.fetch!(:entered_count) == 2
    end
  end
end
