defmodule Manor.Mansion do
  @moduledoc """
  The mansion: a sparse map of built cells.

  `rooms` maps `{col, rank}` to a `Manor.PlacedRoom`. **An unbuilt cell is
  an absent key** — `Map.fetch/2` returning `:error` *is* the draft trigger.
  No nil-filled grid, no sentinel values.

  A passage between two cells is *derived, not stored*: it exists iff both
  adjacent rooms have a door on the shared edge, and is locked if either
  side is locked. Each room owns only its own edges; `passage/3` computes
  the shared truth.
  """

  alias Manor.{Grid, PlacedRoom, Room}
  require Manor.Grid

  @enforce_keys [:rooms]
  defstruct [:rooms]

  @type t :: %__MODULE__{rooms: %{Grid.coord() => PlacedRoom.t()}}

  @type passage ::
          {:built, :open | :locked, Grid.coord()}
          | {:unbuilt, :open | :locked, Grid.coord()}
          | :wall

  @doc """
  A fresh mansion with only the entrance placed at `Grid.entrance/0`.

  ## Part 2 hints
  One map literal with one key.
  """
  @spec new(Room.t()) :: t()
  def new(%Room{} = entrance_template) do
    entrance = PlacedRoom.new(entrance_template, Grid.entrance())
    %__MODULE__{rooms: %{Grid.entrance() => entrance}}
  end

  @doc """
  The placed room at `coord`, or `:error` when the cell is unbuilt.

  ## Part 2 hints
  This is `Map.fetch/2` wearing a domain hat — and that's the point.
  """
  @spec fetch(t(), Grid.coord()) :: {:ok, PlacedRoom.t()} | :error
  def fetch(%__MODULE__{rooms: rooms}, coord), do: Map.fetch(rooms, coord)

  @doc "Whether the cell at `coord` has been built."
  @spec built?(t(), Grid.coord()) :: boolean()
  def built?(%__MODULE__{rooms: rooms}, coord), do: Map.has_key?(rooms, coord)

  @doc """
  Place a room instance into its cell.

  ## Part 2 hints
  The instance already knows its `coord`. Refuse `{:error, :occupied}` on
  collision — `built?/2` first, or pattern match on `fetch/2`.
  """
  @spec place(t(), PlacedRoom.t()) :: {:ok, t()} | {:error, :occupied}
  def place(%__MODULE__{} = mansion, %PlacedRoom{coord: coord} = placed) do
    case(built?(mansion, coord)) do
      true -> {:error, :occupied}
      false -> {:ok, %{mansion | rooms: Map.put(mansion.rooms, coord, placed)}}
    end
  end

  @doc """
  Replace the placed room at `coord` by applying `fun` to it. The cell must
  be built — a missing cell is a bug and should crash.

  ## Part 2 hints
  `Map.update!/3`. The `!` is the design decision.
  """
  @spec update!(t(), Grid.coord(), (PlacedRoom.t() -> PlacedRoom.t())) :: t()
  def update!(%__MODULE__{} = mansion, coord, fun) when is_function(fun, 1) do
    %{mansion | rooms: Map.update!(mansion.rooms, coord, fun)}
  end

  @doc """
  Permanently unlock the edge leaving `coord` in `direction` — on *both*
  sides when the neighbor is built, so the passage reads `:open` from
  either room afterward.

  ## Part 2 hints
  Our side first via `update!/3` + `PlacedRoom.unlock/2`. Then a `with`
  over `Grid.step/2` and `built?/2` for the neighbor's side, whose `else`
  is "fine, just the one side then".
  """
  @spec unlock(t(), Grid.coord(), Grid.direction()) :: t()
  def unlock(%__MODULE__{} = mansion, coord, direction) when Grid.is_direction(direction) do
    mansion = update!(mansion, coord, &PlacedRoom.unlock(&1, direction))

    with {:ok, neighbor} <- Grid.step(coord, direction), true <- built?(mansion, neighbor) do
      update!(mansion, neighbor, &PlacedRoom.unlock(&1, Grid.opposite(direction)))
    else
      _ -> mansion
    end
  end

  @doc """
  What lies in `direction` from `coord`, from the current room's perspective.

  Returns one uniform shape per case:

    * `{:built, lock, dest}` — a mutual doorway into a built room
    * `{:unbuilt, lock, dest}` — our door opens onto an empty cell (a draft
      trigger); `lock` is our own door's state
    * `:wall` — no door on our side, the neighbor lacks a matching door, or
      the edge of the grid

  A passage between two built rooms is `:locked` if *either* side is locked.

  The cell at `coord` must itself be built — the player can only ever stand
  in a built room, so an unbuilt origin is a bug: assert it with
  `{:ok, here} = fetch(...)` and let it crash loudly.

  ## Part 2 hints
  This is the one function in Part 2 that earns a nested `case`. Classify
  in layers: our door and `Grid.step/2` first (a `case` over the tuple of
  both handles wall/off-grid in two patterns), then the neighbor via
  `fetch/2`, then the neighbor's opposite door.
  """
  @spec passage(t(), Grid.coord(), Grid.direction()) :: passage()
  def passage(%__MODULE__{} = mansion, coord, direction) when Grid.is_direction(direction) do
    {:ok, here} = fetch(mansion, coord)

    case {PlacedRoom.door(here, direction), Grid.step(coord, direction)} do
      {nil, _} ->
        :wall

      {_our_door, {:error, :off_grid}} ->
        :wall

      {our_door, {:ok, dest}} ->
        case fetch(mansion, dest) do
          :error ->
            {:unbuilt, our_door, dest}

          {:ok, there} ->
            case PlacedRoom.door(there, Grid.opposite(direction)) do
              nil -> :wall
              their_door -> {:built, combine_locks(our_door, their_door), dest}
            end
        end
    end
  end

  defp combine_locks(:open, :open), do: :open
  defp combine_locks(_, _), do: :locked

  @doc """
  May `template` be drafted into a cell entered while moving `direction`?
  It must have a door facing back through the doorway you came in by.

  ## Part 2 hints
  Compose two functions you already have.
  """
  @spec can_connect?(Room.t(), Grid.direction()) :: boolean()
  def can_connect?(%Room{} = template, direction) when Grid.is_direction(direction) do
    Room.has_door?(template, Grid.opposite(direction))
  end
end
