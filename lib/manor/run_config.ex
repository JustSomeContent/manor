defmodule Manor.RunConfig do
  @moduledoc """
  Everything that parameterizes one day: the seed, the starting purse, and
  the content. The struct is provided; `default/1` is a Part 6 exercise.

  Bundling content into the config (instead of hard-calling `Manor.Catalog`
  from game logic) is what lets the test suite play on a tiny fixture
  catalog while you rebalance the real one.
  """

  alias Manor.{Catalog, Recipe, Resources, Room}

  @enforce_keys [:seed, :starting_resources, :rooms, :entrance, :fallback, :recipes, :shop_offers]
  defstruct [
    :seed,
    :starting_resources,
    :rooms,
    :entrance,
    :fallback,
    :recipes,
    :shop_offers,
    draft_size: 3
  ]

  @type t :: %__MODULE__{
          seed: integer(),
          starting_resources: Resources.t(),
          rooms: [Room.t()],
          entrance: Room.t(),
          fallback: Room.t(),
          recipes: [Recipe.t()],
          shop_offers: [Catalog.offer()],
          draft_size: pos_integer()
        }

  @doc """
  The standard day: full catalog, 40 steps, 1 key, 2 gems, empty pockets.

  Options: `:seed` (required), plus any override of `:steps`, `:keys`,
  `:gems`, `:coins`.

  ## Part 6 hints
  `Keyword.validate!/2` is modern option hygiene: it fills defaults *and*
  raises on typos (`stpes: 50`) — validate at the boundary, trust inside.
  Then `Keyword.fetch!/2` for the required seed, and the `Manor.Catalog`
  functions for content. (The struct above is provided; note the tests use
  `Manor.Fixtures.config/1` instead of this everywhere except Part 6.)
  """
  @spec default(keyword()) :: t()
  def default(opts) when is_list(opts) do
    opts = Keyword.validate!(opts, [:seed, steps: 40, keys: 1, gems: 2, coins: 0])
    seed = Keyword.fetch!(opts, :seed)

    %__MODULE__{
      seed: seed,
      starting_resources: %Resources{
        steps: opts[:steps],
        keys: opts[:keys],
        gems: opts[:gems],
        coins: opts[:coins]
      },
      rooms: Catalog.rooms(),
      entrance: Catalog.entrance(),
      fallback: Catalog.fallback(),
      recipes: Catalog.recipes(),
      shop_offers: Catalog.shop_offers()
    }
  end
end
