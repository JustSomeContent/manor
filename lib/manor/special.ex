defmodule Manor.Special do
  @moduledoc """
  The behaviour for rooms whose logic can't be expressed as static
  `Manor.Effect` data.

  Most rooms are pure data. The rare room that needs *computed* behavior —
  "grant one gem per garden placed so far" — implements this contract and
  hangs its module on the template's `special:` field. `Manor.Game` calls
  `c:on_enter/1` after data effects run, every time the room is entered;
  the implementation decides for itself whether to act (e.g. only on first
  entry, via the placed room's `entered_count`).

  This is what a behaviour is for: a pluggable module fulfilling a known
  contract, chosen at runtime. Remember the shape — in Part 8 you'll meet
  `GenServer`, which is exactly this idea plus a runtime loop.
  """

  @callback on_enter(Manor.Game.t()) :: Manor.Game.t()
end
