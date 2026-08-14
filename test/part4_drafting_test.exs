defmodule Manor.Part4DraftingTest do
  use ExUnit.Case, async: true

  alias Manor.{DraftPool, Fixtures, Game, RNG}
  alias Manor.Game.Draft

  import Manor.GameHelpers

  @moduletag part: 4

  # Effect-free rooms only: effects arrive in Part 5.
  defp plain_rooms do
    [
      Fixtures.room(:hall),
      Fixtures.room(:parlor, rarity: :standard),
      Fixtures.room(:study, rarity: :unusual),
      Fixtures.room(:vault, rarity: :rare, gem_cost: 2, doors: %{south: :open, north: :locked}),
      Fixtures.room(:tower, doors: %{north: :open})
    ]
  end

  defp fresh(overrides \\ []) do
    Game.new(Fixtures.config(Keyword.merge([rooms: plain_rooms()], overrides)))
  end

  describe "4.4 DraftPool.draw/4" do
    test "4.4-R1 only eligible templates are offered" do
      pool = DraftPool.new(plain_rooms())
      {offered, _rng} = DraftPool.draw(pool, RNG.new(1), &(&1.rarity == :rare), 3)
      assert Enum.map(offered, & &1.id) == [:vault]
    end

    test "4.4-R2 drawing offers at most the requested count, all distinct" do
      pool = DraftPool.new(plain_rooms())
      {offered, _rng} = DraftPool.draw(pool, RNG.new(1), fn _ -> true end, 3)
      assert length(offered) == 3
      assert offered == Enum.uniq(offered)
    end

    test "4.4-R3 drawing does not shrink the pool — only choosing does" do
      pool = DraftPool.new(plain_rooms())
      {_offered, _rng} = DraftPool.draw(pool, RNG.new(1), fn _ -> true end, 3)
      assert length(pool.available) == length(plain_rooms())
    end
  end

  describe "4.5 DraftPool.remove/2" do
    test "4.5-R1 removing takes exactly that template out" do
      pool = plain_rooms() |> DraftPool.new() |> DraftPool.remove(:hall)
      refute Enum.any?(pool.available, &(&1.id == :hall))
      assert length(pool.available) == length(plain_rooms()) - 1
    end
  end

  describe "4.6 moving into an unbuilt cell begins a draft" do
    test "4.6-R1 the phase flips to drafting; the step is spent; you have not moved" do
      game = fresh()
      assert {:ok, drafting} = Game.move(game, :north)

      assert {:drafting, %Draft{dest: {3, 2}, entered_via: :north, candidates: candidates}} =
               drafting.phase

      assert drafting.player == game.player
      assert drafting.resources.steps == game.resources.steps - 1
      assert length(candidates) in 1..3
    end

    test "4.6-R2 every candidate can connect back through the door you entered by" do
      {:ok, drafting} = Game.move(fresh(), :north)
      {:drafting, %Draft{candidates: candidates}} = drafting.phase

      # Moving north, the connecting door faces south. :tower (north-only) must never appear.
      assert Enum.all?(candidates, &Map.has_key?(&1.doors, :south))
    end

    test "4.6-R3 candidates/1 answers only while drafting" do
      game = fresh()
      assert Game.candidates(game) == {:error, :no_draft_pending}

      {:ok, drafting} = Game.move(game, :north)
      assert {:ok, [_ | _]} = Game.candidates(drafting)
    end
  end

  describe "4.7 choose_draft/2" do
    test "4.7-R1 choosing places the room, walks you in, and shrinks the pool" do
      {:ok, drafting} = Game.move(fresh(), :north)
      {:ok, [first | _]} = Game.candidates(drafting)

      assert {:ok, entered} = Game.choose_draft(drafting, 1)

      assert entered.phase == :awaiting_command
      assert entered.player == {3, 2}
      assert {:ok, placed} = Manor.Mansion.fetch(entered.mansion, {3, 2})
      assert placed.room.id == first.id
      assert placed.entered_count == 1
      refute Enum.any?(entered.pool.available, &(&1.id == first.id))
    end

    test "4.7-R2 an out-of-range index is refused and you are still drafting" do
      {:ok, drafting} = Game.move(fresh(), :north)
      assert Game.choose_draft(drafting, 99) == {:error, :invalid_choice}
      assert {:drafting, _} = drafting.phase
    end

    test "4.7-R3 a room you cannot afford is refused — pick another instead" do
      pricey = Fixtures.room(:vault, gem_cost: 2, doors: %{south: :open})
      draft = %Draft{dest: {3, 2}, entered_via: :north, candidates: [pricey]}
      drafting = %{fresh(gems: 0) | phase: {:drafting, draft}}

      assert Game.choose_draft(drafting, 1) == {:error, {:insufficient, :gems}}
      # The rejection changed nothing: the caller's game is still mid-draft.
      assert {:drafting, _} = drafting.phase
    end

    test "4.7-R4 choosing outside a draft is refused" do
      assert Game.choose_draft(fresh(), 1) == {:error, :no_draft_pending}
    end

    test "4.7-R5 the connecting door is propped open even on a lock-happy room" do
      # Force a draft where the only candidate locks its south door.
      rooms = [Fixtures.room(:cellar, doors: %{south: :locked})]
      {:ok, drafting} = Game.move(fresh(rooms: rooms), :north)
      {:ok, entered} = Game.choose_draft(drafting, 1)

      # Walking back south must not need a key.
      assert {:ok, back} = Game.move(entered, :south)
      assert back.player == Manor.Grid.entrance()
      assert back.resources.keys == entered.resources.keys
    end
  end

  describe "4.8 the fallback closet" do
    test "4.8-R1 when nothing fits, the closet is the only offer" do
      # Only :tower (north-door-only) in the pool: moving north can never connect.
      {:ok, drafting} =
        Game.move(fresh(rooms: [Fixtures.room(:tower, doors: %{north: :open})]), :north)

      {:ok, candidates} = Game.candidates(drafting)
      assert Enum.map(candidates, & &1.id) == [:closet]
    end
  end

  describe "4.9 determinism, end to end" do
    test "4.9-R1 same seed and commands produce structurally identical games" do
      commands = [{:move, :north}, {:choose, 1}, {:move, :north}, {:choose, 1}]

      game_a = play!(fresh(seed: 777), commands)
      game_b = play!(fresh(seed: 777), commands)

      assert game_a == game_b
    end
  end
end
