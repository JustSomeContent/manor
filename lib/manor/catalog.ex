defmodule Manor.Catalog do
  @moduledoc """
  The full room, item, recipe, and shop catalog. **Provided — not an
  exercise.** Read it: this file is the game's content, and its literal
  structs pin the data shapes the whole lab builds against.

  A plain data module (functions returning literals) rather than raw module
  attributes as the public API: functions are a contract that could later
  load from a file without touching callers, and struct literals get
  compile-time key checking.

  Lab tests run against the mini-catalog in `test/support/fixtures.ex`, so
  you can tune numbers, add rooms, and rebalance here freely without
  breaking part tests. Please do — it's your mansion.
  """

  alias Manor.{Item, Recipe, Room}

  @type offer :: %{
          id: atom(),
          label: String.t(),
          price: pos_integer(),
          grants: Manor.Effect.action()
        }

  @doc "The entrance hall. Placed at `{3, 1}` when a day begins; never drafted."
  @spec entrance() :: Room.t()
  def entrance do
    %Room{
      id: :entrance_hall,
      name: "Entrance Hall",
      code: "EN",
      category: :entrance,
      rarity: :commonplace,
      doors: %{north: :open, east: :open, west: :open}
    }
  end

  @doc """
  The emergency room offered when no drafted candidate fits. Doors on all
  four edges — a flavor exception, so it can connect from any doorway. It
  never leaves the pool because it was never in it.
  """
  @spec fallback() :: Room.t()
  def fallback do
    %Room{
      id: :closet,
      name: "Closet",
      code: "CL",
      category: :dead_end,
      rarity: :commonplace,
      doors: %{north: :open, east: :open, south: :open, west: :open}
    }
  end

  @doc "Every draftable room template."
  @spec rooms() :: [Room.t()]
  def rooms do
    [
      %Room{
        id: :hallway,
        name: "Hallway",
        code: "HA",
        category: :hallway,
        rarity: :commonplace,
        doors: %{north: :open, south: :open}
      },
      %Room{
        id: :corridor,
        name: "Corridor",
        code: "CO",
        category: :hallway,
        rarity: :commonplace,
        doors: %{north: :open, east: :open, south: :open, west: :open}
      },
      %Room{
        id: :gallery,
        name: "Gallery",
        code: "GA",
        category: :hallway,
        rarity: :standard,
        doors: %{north: :open, east: :open, west: :open}
      },
      %Room{
        id: :bedroom,
        name: "Bedroom",
        code: "BR",
        category: :bedroom,
        rarity: :commonplace,
        doors: %{north: :open, south: :open},
        effects: [{:on_place, {:grant, :steps, 2}}]
      },
      %Room{
        id: :guest_room,
        name: "Guest Room",
        code: "GR",
        category: :bedroom,
        rarity: :standard,
        doors: %{south: :open, east: :open},
        effects: [{:on_place, {:grant, :steps, 3}}]
      },
      %Room{
        id: :den,
        name: "Den",
        code: "DE",
        category: :dead_end,
        rarity: :commonplace,
        doors: %{south: :open},
        effects: [{:on_place, {:grant, :coins, 2}}]
      },
      %Room{
        id: :garden,
        name: "Garden",
        code: "GD",
        category: :green,
        rarity: :standard,
        doors: %{north: :open, south: :open},
        effects: [{:on_enter, {:grant, :gems, 1}}]
      },
      %Room{
        id: :greenhouse,
        name: "Greenhouse",
        code: "GH",
        category: :green,
        rarity: :unusual,
        doors: %{south: :open, east: :open, west: :open},
        effects: [{:on_place, {:grant, :steps, 4}}]
      },
      %Room{
        id: :terrace,
        name: "Terrace",
        code: "TE",
        category: :green,
        rarity: :standard,
        doors: %{south: :open, west: :open},
        effects: [{:per_turn, {:grant, :coins, 1}}]
      },
      %Room{
        id: :commissary,
        name: "Commissary",
        code: "CM",
        category: :shop,
        rarity: :standard,
        doors: %{north: :open, south: :open}
      },
      %Room{
        id: :locksmith,
        name: "Locksmith",
        code: "LK",
        category: :shop,
        rarity: :unusual,
        doors: %{south: :open, east: :open}
      },
      %Room{
        id: :workshop,
        name: "Workshop",
        code: "WS",
        category: :workshop,
        rarity: :unusual,
        doors: %{north: :open, south: :open},
        gem_cost: 1
      },
      %Room{
        id: :observatory,
        name: "Observatory",
        code: "OB",
        category: :dead_end,
        rarity: :unusual,
        doors: %{south: :open},
        gem_cost: 1,
        special: Manor.Rooms.Observatory
      },
      %Room{
        id: :vault,
        name: "Vault",
        code: "VA",
        category: :dead_end,
        rarity: :rare,
        doors: %{south: :open, north: :locked},
        gem_cost: 2,
        effects: [{:on_place, {:grant, :gems, 4}}]
      },
      %Room{
        id: :antechamber,
        name: "Antechamber",
        code: "AN",
        category: :goal,
        rarity: :rare,
        doors: %{south: :open, east: :open, west: :open},
        gem_cost: 2
      }
    ]
  end

  @doc "A draftable template by id. Raises on unknown ids — asking for a room that doesn't exist is a bug."
  @spec room!(Room.id()) :: Room.t()
  def room!(id) do
    case Enum.find(rooms(), &(&1.id == id)) do
      nil -> raise KeyError, key: id, term: __MODULE__
      room -> room
    end
  end

  @doc "Every item, indexed by id."
  @spec items() :: %{Item.id() => Item.t()}
  def items do
    %{
      shovel: %Item{id: :shovel, name: "Shovel", description: "Sturdy. Wants a mechanism."},
      cog: %Item{id: :cog, name: "Brass Cog", description: "One tooth chipped."},
      lockpick: %Item{
        id: :lockpick,
        name: "Lockpick",
        description: "Opens one locked door in place of a key. Single use."
      },
      spyglass: %Item{
        id: :spyglass,
        name: "Spyglass",
        description: "A collector's piece. It has seen the ninth rank; you have not."
      }
    }
  end

  @doc "Workshop recipes."
  @spec recipes() :: [Recipe.t()]
  def recipes do
    [
      %Recipe{inputs: {:shovel, :cog}, output: :lockpick},
      %Recipe{inputs: {:cog, :cog}, output: :spyglass}
    ]
  end

  @doc "What every shop in the mansion sells."
  @spec shop_offers() :: [offer()]
  def shop_offers do
    [
      %{id: :trail_mix, label: "Trail Mix (+4 steps)", price: 2, grants: {:grant, :steps, 4}},
      %{id: :spare_key, label: "Spare Key", price: 3, grants: {:grant, :keys, 1}},
      %{id: :shovel, label: "Shovel", price: 2, grants: {:grant_item, :shovel}},
      %{id: :cog, label: "Brass Cog", price: 1, grants: {:grant_item, :cog}}
    ]
  end
end
