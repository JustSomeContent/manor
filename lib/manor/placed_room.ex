defmodule Manor.PlacedRoom do
  @moduledoc """
  A room *instance* occupying one grid cell.

  Placement copies the template's doors onto the instance: unlocking a door
  edits **this copy**, never the catalog. The embedded template itself is a
  shared immutable reference — on the BEAM that copy is effectively free
  (structural sharing), which is why we embed the whole `Manor.Room` instead
  of threading a catalog lookup through every caller.

  Struct PROVIDED; functions yours.
  """

  alias Manor.{Grid, Room}
  require Manor.Grid

  @enforce_keys [:room, :coord, :doors]
  defstruct [:room, :coord, :doors, entered_count: 0]

  @type t :: %__MODULE__{
          room: Room.t(),
          coord: Grid.coord(),
          doors: %{Grid.direction() => Room.door()},
          entered_count: non_neg_integer()
        }

  @doc """
  Stamp a template into an instance at `coord`.

  ## Part 2 hints
  Struct literal + copying `template.doors`. `@enforce_keys` will tell you
  if you forget a field.
  """
  @spec new(Room.t(), Grid.coord()) :: t()
  def new(%Room{} = template, coord) do
    %__MODULE__{room: template, coord: coord, doors: template.doors, entered_count: 0}
  end

  @doc """
  The door state on an edge of this instance: `:open`, `:locked`, or `nil`
  (wall).

  ## Part 2 hints
  `Map.get/2` returns `nil` for missing keys — for once, exactly what we
  want to expose.
  """
  @spec door(t(), Grid.direction()) :: Room.door() | nil
  def door(%__MODULE__{doors: doors}, direction) when Grid.is_direction(direction) do
    Map.get(doors, direction)
  end

  @doc """
  Permanently unlock the door on `direction`, if there is one.

  Unlocking a wall or an already-open door is a no-op — callers shouldn't
  have to care.

  ## Part 2 hints
  Pattern match the doors map with a pinned key: `%{^direction => :locked}`
  in a `case` — the other patterns fall through to "return it unchanged".
  """
  @spec unlock(t(), Grid.direction()) :: t()
  def unlock(%__MODULE__{} = placed, direction) when Grid.is_direction(direction) do
    case placed.doors do
      %{^direction => :locked} -> %{placed | doors: Map.put(placed.doors, direction, :open)}
      _ -> placed
    end
  end

  @doc """
  Record one entry into this room.

  ## Part 2 hints
  Struct update syntax: `%{placed | entered_count: ...}`.
  """
  @spec record_entry(t()) :: t()
  def record_entry(%__MODULE__{} = placed) do
    %{placed | entered_count: placed.entered_count + 1}
  end
end
