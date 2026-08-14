defmodule Manor.Part5EffectsTest do
  use ExUnit.Case, async: true

  alias Manor.{Effect, Fixtures, Game, PlacedRoom}
  alias Manor.Game.Draft

  import Manor.GameHelpers

  @moduletag part: 5

  defp fresh(overrides \\ []) do
    Game.new(Fixtures.config(overrides))
  end

  defp draft_directly(game, template, dest \\ {3, 2}, via \\ :north) do
    draft = %Draft{dest: dest, entered_via: via, candidates: [template]}
    drafting = %{game | phase: {:drafting, draft}}
    {:ok, chosen} = Game.choose_draft(drafting, 1)
    chosen
  end

  describe "5.1 Effect.apply_action/2" do
    test "5.1-R1 {:grant, kind, n} raises the counter and logs it" do
      game = Effect.apply_action(fresh(), {:grant, :gems, 3})
      assert game.resources.gems == 2 + 3
      assert {:granted, :gems, 3} in game.log
    end

    test "5.1-R2 {:grant_item, id} adds to the counted bag" do
      game =
        fresh()
        |> Effect.apply_action({:grant_item, :cog})
        |> Effect.apply_action({:grant_item, :cog})

      assert game.inventory == %{cog: 2}
    end
  end

  describe "5.2 Effect.apply_trigger/3" do
    test "5.2-R1 only effects matching the trigger fire" do
      room =
        Fixtures.room(:mixed,
          effects: [
            {:on_place, {:grant, :steps, 2}},
            {:on_enter, {:grant, :gems, 1}}
          ]
        )

      placed = PlacedRoom.new(room, {3, 2})
      game = Effect.apply_trigger(fresh(), placed, :on_enter)

      assert game.resources.gems == 2 + 1
      assert game.resources.steps == 40
    end
  end

  describe "5.3 effects in play" do
    test "5.3-R1 on_place fires once, at drafting" do
      bedroom = Fixtures.room(:bedroom, effects: [{:on_place, {:grant, :steps, 2}}])
      game = draft_directly(fresh(), bedroom)

      # +2 from placing; the draft itself never charges a step (the trigger move did).
      assert game.resources.steps == 40 + 2
    end

    test "5.3-R2 on_enter fires every entry" do
      garden = Fixtures.room(:garden, effects: [{:on_enter, {:grant, :gems, 1}}])

      game =
        fresh()
        |> draft_directly(garden)
        |> play!([{:move, :south}, {:move, :north}])

      # Entered twice: once via the draft, once walking back in.
      assert game.resources.gems == 2 + 2
    end

    test "5.3-R3 per_turn fires for every placed copy, every turn" do
      terrace = Fixtures.room(:terrace, effects: [{:per_turn, {:grant, :coins, 1}}])

      game =
        fresh()
        |> draft_directly(terrace)
        |> play!([{:move, :south}, {:move, :north}])

      # Placed on turn 1; ticks on turns 1, 2 and 3.
      assert game.resources.coins == 3
      assert game.turn == 3
    end
  end

  describe "5.4 the Observatory (a Manor.Special behaviour)" do
    test "5.4-R1 first entry grants one gem per green room placed" do
      garden = Fixtures.room(:garden, category: :green, effects: [])

      observatory =
        Fixtures.room(:observatory, doors: %{south: :open}, special: Manor.Rooms.Observatory)

      game =
        fresh()
        |> draft_directly(garden, {3, 2}, :north)
        |> draft_directly(observatory, {3, 3}, :north)

      assert game.resources.gems == 2 + 1
    end

    test "5.4-R2 later entries grant nothing" do
      garden = Fixtures.room(:garden, category: :green, effects: [])

      observatory =
        Fixtures.room(:observatory,
          doors: %{south: :open, north: :open},
          special: Manor.Rooms.Observatory
        )

      game =
        fresh()
        |> draft_directly(garden, {3, 2}, :north)
        |> draft_directly(observatory, {3, 3}, :north)

      revisited = play!(game, [{:move, :south}, {:move, :north}])
      assert revisited.resources.gems == game.resources.gems
    end
  end

  describe "5.5 lockpicks open doors when keys run dry" do
    test "5.5-R1 a lockpick substitutes for a key and is consumed" do
      game =
        fresh(keys: 0)
        |> place!(Fixtures.room(:cellar, doors: %{south: :open, east: :locked}), {3, 2})
        |> place!(Fixtures.room(:nook, doors: %{west: :locked}), {4, 2})
        |> give_item(:lockpick)
        |> play!([{:move, :north}])

      assert {:ok, through} = Game.move(game, :east)
      assert through.player == {4, 2}
      assert through.inventory == %{}
    end

    test "5.5-R2 a real key is preferred while one remains" do
      game =
        fresh(keys: 1)
        |> place!(Fixtures.room(:cellar, doors: %{south: :open, east: :locked}), {3, 2})
        |> place!(Fixtures.room(:nook, doors: %{west: :locked}), {4, 2})
        |> give_item(:lockpick)
        |> play!([{:move, :north}])

      {:ok, through} = Game.move(game, :east)
      assert through.resources.keys == 0
      assert through.inventory == %{lockpick: 1}
    end
  end
end
