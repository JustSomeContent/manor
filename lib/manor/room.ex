defmodule Manor.Room do
  @moduledoc """
  An immutable room *template* — a catalog entry.

  A `Room` never appears on the grid directly; drafting stamps it into a
  `Manor.PlacedRoom` instance. Templates carry no coordinate and no
  per-placement state, which makes "a template with a position" an
  unrepresentable state.

  Doors are a direction-keyed map: `%{north: :open, south: :locked}`.
  **An absent key is a wall.** One field encodes wall/open/locked without a
  second collection to keep in sync.

  The struct itself is PROVIDED (read it — it is the data contract for the
  whole game); the functions are yours.
  """

  alias Manor.Grid
  # `alias` only shortens the name; using the `is_direction/1` *guard* (a
  # macro) in our own guards needs the module compiled-and-required first.
  require Manor.Grid

  @enforce_keys [:id, :name, :code, :category, :rarity, :doors]
  defstruct [
    :id,
    :name,
    :code,
    :category,
    :rarity,
    :doors,
    gem_cost: 0,
    effects: [],
    special: nil
  ]

  @type id :: atom()
  @type rarity :: :commonplace | :standard | :unusual | :rare
  @type category ::
          :entrance | :hallway | :bedroom | :green | :shop | :workshop | :dead_end | :goal
  @type door :: :open | :locked

  @type t :: %__MODULE__{
          id: id(),
          name: String.t(),
          code: String.t(),
          category: category(),
          rarity: rarity(),
          doors: %{Grid.direction() => door()},
          gem_cost: non_neg_integer(),
          effects: [Manor.Effect.t()],
          special: module() | nil
        }

  @doc """
  Whether the template has a door (open or locked) on the given edge.

  ## Part 2 hints
  `Map.has_key?/2` — one line.
  """
  @spec has_door?(t(), Grid.direction()) :: boolean()
  def has_door?(%__MODULE__{} = _room, direction) when Grid.is_direction(direction) do
    # TODO(Part 2)
    Manor.NotImplemented.todo!(part: 2, fun: "Manor.Room.has_door?/2")
  end

  @doc """
  Whether this template may be drafted into the cell at `coord`.

  The rule set is small on purpose: `:goal` rooms only at the top rank,
  nothing *else* at the top rank, and the `:entrance` never drafted at all.

  ## Part 2 hints
  Three clauses, no `if`: match `category: :entrance` first, then
  `category: :goal` against the rank, then everything else. Pattern-match
  the rank straight out of the coordinate tuple.
  """
  @spec allowed_at?(t(), Grid.coord()) :: boolean()
  def allowed_at?(%__MODULE__{} = _room, {_col, _rank} = _coord) do
    # TODO(Part 2)
    Manor.NotImplemented.todo!(part: 2, fun: "Manor.Room.allowed_at?/2")
  end
end
