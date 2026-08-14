defmodule Manor.DraftPool do
  @moduledoc """
  The pool of room templates still available to draft this day.

  Rarity sets the draw weight. `draw/4` samples an *offer* without removing
  anything — unchosen candidates implicitly return because they never left.
  Only `remove/2` (called when a room is actually chosen) shrinks the pool.
  Each template exists once per run.
  """

  alias Manor.{RNG, Room}

  @enforce_keys [:available]
  defstruct [:available]

  @type t :: %__MODULE__{available: [Room.t()]}

  @rarity_weights %{commonplace: 8, standard: 4, unusual: 2, rare: 1}

  @doc "The draw weight for a rarity. PROVIDED."
  @spec weight(Room.rarity()) :: pos_integer()
  def weight(rarity), do: Map.fetch!(@rarity_weights, rarity)

  @doc "A pool holding every template in `templates`. PROVIDED."
  @spec new([Room.t()]) :: t()
  def new(templates) when is_list(templates), do: %__MODULE__{available: templates}

  @doc """
  Sample up to `count` distinct eligible templates, rarity-weighted,
  **without** removing them from the pool.

  ## Part 4 hints
  `Enum.filter/2` with the caller's `eligible?`, then `Manor.RNG.take_weighted/4`
  with a weight function built from `weight/1` — capture syntax reads well
  here.
  """
  @spec draw(t(), RNG.t(), (Room.t() -> boolean()), pos_integer()) :: {[Room.t()], RNG.t()}
  def draw(%__MODULE__{} = _pool, _rng, eligible?, count)
      when is_function(eligible?, 1) and is_integer(count) and count > 0 do
    # TODO(Part 4)
    raise Manor.NotImplemented, part: 4, fun: "Manor.DraftPool.draw/4"
  end

  @doc """
  Remove the chosen template from the pool. Unknown ids are a no-op.

  ## Part 4 hints
  `Enum.reject/2`.
  """
  @spec remove(t(), Room.id()) :: t()
  def remove(%__MODULE__{} = _pool, _room_id) do
    # TODO(Part 4)
    raise Manor.NotImplemented, part: 4, fun: "Manor.DraftPool.remove/2"
  end
end
