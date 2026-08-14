defmodule Manor.Game.Draft do
  @moduledoc """
  A pending draft: the unbuilt cell being drafted into, the direction of
  travel that triggered it, and the candidate templates on offer.

  This struct only ever exists *inside* the game's phase tuple,
  `{:drafting, %Draft{}}` — there is no separate "candidates" field on the
  game to forget to clear.
  """

  alias Manor.{Grid, Room}

  @enforce_keys [:dest, :entered_via, :candidates]
  defstruct [:dest, :entered_via, :candidates]

  @type t :: %__MODULE__{
          dest: Grid.coord(),
          entered_via: Grid.direction(),
          candidates: [Room.t()]
        }
end
