defmodule Manor.Render do
  @moduledoc """
  A pure renderer: the game state in, printable text out.

  There is no dirty-rectangle bookkeeping and no "what changed since last
  frame" — rendering is a *function of state*, so the loop just calls it
  again. That is the immutability dividend.

  `render/1` returns **iodata** (nested lists of strings), flattened to a
  binary exactly once at the edge by `to_string/1`. Building the frame by
  `<>`-ing strings in a reduce is the StringBuilder mistake in reverse —
  the Part 9 tests check the iodata discipline.

  ## The target frame

  Each cell is 5 characters wide and 3 tall; rank 9 renders at the top so
  north is up; cells in a row are joined with one space (29 columns total).
  Doors are gaps in the middle of an edge, `▒` when locked; the player is
  `@` beside the room's 2-character code; unbuilt cells are `· · ·` rows:

      ┌─ ─┐ ┌───┐ · · ·
      │HA │ ▒CE │ · · ·
      └─ ─┘ └─ ─┘ · · ·

  After the grid: a status bar (via `String.Chars` for `Manor.Resources` —
  see `inspect_impls.ex`), a `"> "`-prefixed line describing the latest
  log entry, and a phase-dependent prompt (the command list, the numbered
  draft candidates like `1) Vault [rare] doors n*,s — 2 gems`, or the
  day-over line).
  """

  alias Manor.{Game, Grid}

  # We define our own to_string/1, so Kernel's auto-import must step aside.
  import Kernel, except: [to_string: 1]

  @doc "The full frame as a binary: `IO.iodata_to_binary/1`, called exactly once."
  @spec to_string(Game.t()) :: String.t()
  def to_string(%Game{} = _game) do
    # TODO(Part 9)
    raise Manor.NotImplemented, part: 9, fun: "Manor.Render.to_string/1"
  end

  @doc """
  The full frame as iodata: grid, status bar, last event, prompt.

  ## Part 9 hints
  A flat list of the pieces with `"\\n"` between them. Keep every helper
  returning iodata; concatenate by *listing*, never by `<>`.
  """
  @spec render(Game.t()) :: iodata()
  def render(%Game{} = _game) do
    # TODO(Part 9)
    raise Manor.NotImplemented, part: 9, fun: "Manor.Render.render/1"
  end

  @doc """
  The 5×9 grid as iodata, rank 9 first.

  ## Part 9 hints
  Comprehend over ranks `9..1//-1`; each rank is three text rows built by
  taking `Enum.at/2` row-slices of the five cells and interspersing `" "`.
  `Enum.intersperse/2` is the list-flavored `Enum.join/2` — join returns a
  binary, and one join here will fail the iodata test.
  """
  @spec grid(Game.t()) :: iodata()
  def grid(%Game{} = _game) do
    # TODO(Part 9)
    raise Manor.NotImplemented, part: 9, fun: "Manor.Render.grid/1"
  end

  @doc """
  One cell as a list of three 5-character rows.

  ## Part 9 hints
  `Mansion.fetch/2`: `:error` is the dotted unbuilt cell. A built cell is
  three rows — `["┌─", edge, "─┐"]` on top, `[edge, code, marker, edge]`
  in the middle, mirrored bottom — where a private `edge/2` maps the
  `PlacedRoom.door/2` result: `nil` → `"─"` or `"│"`, `:open` → `" "`,
  `:locked` → `"▒"`.
  """
  @spec cell(Game.t(), Grid.coord()) :: [iodata()]
  def cell(%Game{} = _game, _coord) do
    # TODO(Part 9)
    raise Manor.NotImplemented, part: 9, fun: "Manor.Render.cell/2"
  end

  @doc """
  Resources and turn counter, e.g.
  `"Steps 17 | Keys 1 | Gems 3 | Coins 5        Turn 12"`.

  ## Part 9 hints
  Lean on the `String.Chars` protocol you implement for `Manor.Resources`
  in `inspect_impls.ex` — here that's `Kernel.to_string(game.resources)`
  (qualified, since this module shadows `to_string/1`).
  """
  @spec status_bar(Game.t()) :: iodata()
  def status_bar(%Game{} = _game) do
    # TODO(Part 9)
    raise Manor.NotImplemented, part: 9, fun: "Manor.Render.status_bar/1"
  end

  @doc """
  One log entry as prose. Pattern matching as translation — every entry
  shape the core can log gets a clause:

      {:moved, coord}              -> "Moved to {3, 2}."
      {:drafting, coord}           -> "An unbuilt room at {3, 3} — draft!"
      {:placed, id, coord}         -> "Built the garden."
      {:granted, kind, n}          -> "+1 gems"
      {:received, item}            -> "Received: lockpick."
      {:bought, offer}             -> "Bought trail mix."
      {:crafted, item}             -> "Crafted: spyglass!"
      {:unlocked, :key}            -> "The key turns. The door stays open."
      {:unlocked, :lockpick}       -> "The lockpick snaps, but the door is open."
      {:won, coord}                -> "The Antechamber. You made it."
      {:day_over, :out_of_steps}   -> "Your legs give out. The day is over."
  """
  @spec describe(term()) :: iodata()
  def describe(_entry) do
    # TODO(Part 9)
    raise Manor.NotImplemented, part: 9, fun: "Manor.Render.describe/1"
  end
end
