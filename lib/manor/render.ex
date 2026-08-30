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

  alias Manor.{Game, Grid, Mansion, PlacedRoom}

  # We define our own to_string/1, so Kernel's auto-import must step aside.
  import Kernel, except: [to_string: 1]

  @doc "The full frame as a binary: `IO.iodata_to_binary/1`, called exactly once."
  @spec to_string(Game.t()) :: String.t()
  def to_string(%Game{} = game), do: IO.iodata_to_binary(render(game))

  @doc """
  The full frame as iodata: grid, status bar, last event, prompt.

  ## Part 9 hints
  A flat list of the pieces with `"\\n"` between them. Keep every helper
  returning iodata; concatenate by *listing*, never by `<>`.
  """
  @spec render(Game.t()) :: iodata()
  def render(%Game{} = game) do
    [grid(game), "\n", status_bar(game), "\n", message_line(game), "\n", prompt(game)]
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
  def grid(%Game{} = game) do
    for rank <- 9..1//-1 do
      cells = for col <- 1..5, do: cell(game, {col, rank})

      for row_index <- 0..2 do
        line = cells |> Enum.map(&Enum.at(&1, row_index)) |> Enum.intersperse(" ")
        [line, "\n"]
      end
    end
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
  def cell(%Game{} = game, coord) do
    case Mansion.fetch(game.mansion, coord) do
      :error -> ["· · ·", "· · ·", "· · ·"]
      {:ok, placed} -> room_cell(placed, game.player == coord)
    end
  end

  defp room_cell(%PlacedRoom{} = placed, player_here?) do
    marker = if player_here?, do: "@", else: " "

    [
      ["┌─", edge(placed, :north), "─┐"],
      [edge(placed, :west), placed.room.code, marker, edge(placed, :east)],
      ["└─", edge(placed, :south), "─┘"]
    ]
  end

  defp edge(placed, direction) do
    horizontal? = direction in [:north, :south]

    case PlacedRoom.door(placed, direction) do
      nil -> if horizontal?, do: "─", else: "│"
      :open -> " "
      :locked -> "▒"
    end
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
  def status_bar(%Game{} = game) do
    [Kernel.to_string(game.resources), "   Turn ", Integer.to_string(game.turn)]
  end

  defp message_line(%Game{log: []}), do: "> A new day at the manor."
  defp message_line(%Game{log: [latest | _]}), do: ["> ", describe(latest)]

  defp prompt(%Game{phase: :awaiting_command}) do
    "move n/s/e/w · buy <id> · combine <a> <b> · look · help · quit"
  end

  defp prompt(%Game{phase: {:drafting, draft}}), do: draft_prompt(draft)

  defp prompt(%Game{phase: {:ended, :won}} = game) do
    ["A winning day, in ", Integer.to_string(game.turn), " turns."]
  end

  defp prompt(%Game{phase: {:ended, :out_of_steps}}) do
    "The day is spent. Start a fresh run to try again."
  end

  defp draft_prompt(draft) do
    draft.candidates
    |> Enum.with_index(1)
    |> Enum.map(fn {room, index} ->
      [
        Integer.to_string(index),
        ") ",
        room.name,
        " [",
        Atom.to_string(room.rarity),
        "] doors ",
        doors_summary(room),
        " — ",
        Integer.to_string(room.gem_cost),
        " gems"
      ]
    end)
    |> Enum.intersperse("\n")
  end

  defp doors_summary(room) do
    for direction <- [:north, :east, :south, :west],
        state = room.doors[direction],
        state != nil do
      [door_letter(direction), lock_mark(state)]
    end
    |> Enum.intersperse(",")
  end

  defp door_letter(:north), do: "n"
  defp door_letter(:east), do: "e"
  defp door_letter(:south), do: "s"
  defp door_letter(:west), do: "w"

  defp lock_mark(:open), do: ""
  defp lock_mark(:locked), do: "*"

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
  def describe({:moved, coord}), do: ["Moved to ", inspect(coord), "."]
  def describe({:drafting, coord}), do: ["An unbuilt room at ", inspect(coord), " — draft!"]
  def describe({:placed, id, _coord}), do: ["Built the ", humanize(id), "."]
  def describe({:granted, kind, n}), do: ["+", Integer.to_string(n), " ", Atom.to_string(kind)]
  def describe({:received, item}), do: ["Received: ", humanize(item), "."]
  def describe({:bought, offer}), do: ["Bought ", humanize(offer), "."]
  def describe({:crafted, item}), do: ["Crafted: ", humanize(item), "!"]
  def describe({:unlocked, :key}), do: "The key turns. The door stays open."
  def describe({:unlocked, :lockpick}), do: "The lockpick snaps, but the door is open."
  def describe({:won, _coord}), do: "The Antechamber. You made it."
  def describe({:day_over, :out_of_steps}), do: "Your legs give out. The day is over."

  defp humanize(atom), do: atom |> Atom.to_string() |> String.replace("_", " ")
end
