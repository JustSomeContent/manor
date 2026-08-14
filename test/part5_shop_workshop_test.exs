defmodule Manor.Part5ShopWorkshopTest do
  use ExUnit.Case, async: true

  alias Manor.{Fixtures, Game, Recipe}

  import Manor.GameHelpers

  @moduletag part: 5

  defp in_room(category, overrides \\ []) do
    Game.new(Fixtures.config(overrides))
    |> place!(Fixtures.room(:the_room, category: category), {3, 2})
    |> play!([{:move, :north}])
  end

  describe "5.6 Recipe.find/3" do
    test "5.6-R1 recipes match in either order" do
      recipes = Fixtures.recipes()
      assert {:ok, %Recipe{output: :lockpick}} = Recipe.find(recipes, :shovel, :cog)
      assert {:ok, %Recipe{output: :lockpick}} = Recipe.find(recipes, :cog, :shovel)
    end

    test "5.6-R2 unknown pairs are :error" do
      assert Recipe.find(Fixtures.recipes(), :shovel, :shovel) == :error
    end
  end

  describe "5.7 buy/2" do
    test "5.7-R1 buying spends coins and applies the offer's grant" do
      game = in_room(:shop, coins: 5)

      assert {:ok, bought} = Game.buy(game, :trail_mix)
      assert bought.resources.coins == 5 - 2
      assert bought.resources.steps == game.resources.steps + 4
      assert {:bought, :trail_mix} in bought.log
    end

    test "5.7-R2 item offers land in the inventory" do
      {:ok, bought} = Game.buy(in_room(:shop, coins: 5), :cog)
      assert bought.inventory == %{cog: 1}
    end

    test "5.7-R3 buying outside a shop is refused" do
      assert Game.buy(in_room(:workshop, coins: 5), :trail_mix) == {:error, :not_in_shop}
    end

    test "5.7-R4 unknown offers and empty pockets are distinct refusals" do
      assert Game.buy(in_room(:shop, coins: 5), :caviar) == {:error, :unknown_offer}
      assert Game.buy(in_room(:shop, coins: 0), :trail_mix) == {:error, {:insufficient, :coins}}
    end
  end

  describe "5.8 combine/3" do
    test "5.8-R1 crafting consumes both inputs and grants the output" do
      game = in_room(:workshop) |> give_item(:shovel) |> give_item(:cog)

      assert {:ok, crafted} = Game.combine(game, :shovel, :cog)
      assert crafted.inventory == %{lockpick: 1}
      assert {:crafted, :lockpick} in crafted.log
    end

    test "5.8-R2 a doubled ingredient needs two copies" do
      one_cog = in_room(:workshop) |> give_item(:cog)
      assert Game.combine(one_cog, :cog, :cog) == {:error, {:missing_item, :cog}}

      two_cogs = give_item(one_cog, :cog)
      assert {:ok, crafted} = Game.combine(two_cogs, :cog, :cog)
      assert crafted.inventory == %{spyglass: 1}
    end

    test "5.8-R3 crafting outside the workshop is refused" do
      game = in_room(:shop) |> give_item(:shovel) |> give_item(:cog)
      assert Game.combine(game, :shovel, :cog) == {:error, :not_in_workshop}
    end

    test "5.8-R4 unknown recipes are refused before any item is touched" do
      game = in_room(:workshop) |> give_item(:shovel, 2)
      assert Game.combine(game, :shovel, :shovel) == {:error, :unknown_recipe}
      assert game.inventory == %{shovel: 2}
    end
  end
end
