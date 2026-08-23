defmodule Manor.Rooms.Observatory do
  @moduledoc """
  The Observatory: on *first* entry only, grants one gem per `:green` room
  placed anywhere in the mansion.

  This can't be a static `{:grant, :gems, n}` effect — `n` depends on the
  mansion at the moment you walk in — which is exactly why it implements
  the `Manor.Special` behaviour instead.
  """

  alias Manor.{Effect, Mansion}

  @behaviour Manor.Special

  @doc """
  ## Part 5 hints
  By the time this runs, the player is standing in the Observatory and its
  `entered_count` is already bumped — so "first entry" is `entered_count == 1`.
  Count `:green` categories over `game.mansion.rooms` values, then reuse
  `Manor.Effect.apply_action/2` — don't hand-edit resources here.
  Granting zero is not a thing: skip the action entirely when no gardens exist.
  """
  @impl Manor.Special
  def on_enter(game) do
    {:ok, placed} = Mansion.fetch(game.mansion, game.player)

    greens =
      game.mansion.rooms
      |> Map.values()
      |> Enum.count(&(&1.room.category == :green))

    if placed.entered_count == 1 and greens > 0 do
      Effect.apply_action(game, {:grant, :gems, greens})
    else
      game
    end
  end
end
