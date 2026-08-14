defmodule Manor.Fixtures do
  @moduledoc """
  The mini-catalog the test suite plays on. **Provided.**

  Tests run against these rooms — never against `Manor.Catalog` — so you
  can rebalance the real game freely without breaking part tests. Every
  fixture room is deliberately boring: doors north/south unless a test
  needs otherwise, effects only where a test exercises them.
  """

  alias Manor.{Recipe, Resources, Room, RunConfig}

  @doc "A room template with test-friendly defaults; override any field."
  @spec room(Room.id(), keyword()) :: Room.t()
  def room(id, overrides \\ []) do
    defaults = [
      id: id,
      name: id |> Atom.to_string() |> String.capitalize(),
      code: id |> Atom.to_string() |> String.slice(0, 2) |> String.upcase(),
      category: :hallway,
      rarity: :commonplace,
      doors: %{north: :open, south: :open}
    ]

    struct!(Room, Keyword.merge(defaults, overrides))
  end

  def entrance,
    do:
      room(:entrance,
        category: :entrance,
        doors: %{north: :open, east: :open, west: :open},
        code: "EN"
      )

  def closet,
    do:
      room(:closet,
        category: :dead_end,
        doors: %{north: :open, east: :open, south: :open, west: :open},
        code: "CL"
      )

  @doc "The standard fixture room set (see module doc)."
  def rooms do
    [
      room(:hall),
      room(:garden,
        category: :green,
        rarity: :standard,
        effects: [{:on_enter, {:grant, :gems, 1}}]
      ),
      room(:bedroom, category: :bedroom, effects: [{:on_place, {:grant, :steps, 2}}]),
      room(:terrace,
        category: :green,
        rarity: :standard,
        effects: [{:per_turn, {:grant, :coins, 1}}]
      ),
      room(:shop, category: :shop, rarity: :standard),
      room(:workshop, category: :workshop, rarity: :standard),
      room(:vault,
        category: :dead_end,
        rarity: :rare,
        doors: %{south: :open, north: :locked},
        gem_cost: 2,
        effects: [{:on_place, {:grant, :gems, 4}}]
      ),
      room(:cellar, category: :dead_end, doors: %{south: :locked}),
      room(:observatory,
        category: :dead_end,
        rarity: :unusual,
        doors: %{south: :open},
        special: Manor.Rooms.Observatory
      ),
      room(:tower, category: :dead_end, doors: %{north: :open}),
      room(:goal,
        category: :goal,
        rarity: :rare,
        doors: %{south: :open, east: :open, west: :open},
        code: "GO"
      )
    ]
  end

  def recipes do
    [
      %Recipe{inputs: {:shovel, :cog}, output: :lockpick},
      %Recipe{inputs: {:cog, :cog}, output: :spyglass}
    ]
  end

  def shop_offers do
    [
      %{id: :trail_mix, label: "Trail Mix", price: 2, grants: {:grant, :steps, 4}},
      %{id: :spare_key, label: "Spare Key", price: 3, grants: {:grant, :keys, 1}},
      %{id: :cog, label: "Brass Cog", price: 1, grants: {:grant_item, :cog}}
    ]
  end

  @doc """
  A ready RunConfig on the mini-catalog. Overrides: `:seed`, `:rooms`,
  plus resource counts `:steps`/`:keys`/`:gems`/`:coins`.
  """
  @spec config(keyword()) :: RunConfig.t()
  def config(overrides \\ []) do
    %RunConfig{
      seed: Keyword.get(overrides, :seed, 42),
      starting_resources: %Resources{
        steps: Keyword.get(overrides, :steps, 40),
        keys: Keyword.get(overrides, :keys, 1),
        gems: Keyword.get(overrides, :gems, 2),
        coins: Keyword.get(overrides, :coins, 0)
      },
      rooms: Keyword.get(overrides, :rooms, rooms()),
      entrance: entrance(),
      fallback: closet(),
      recipes: recipes(),
      shop_offers: shop_offers()
    }
  end
end
