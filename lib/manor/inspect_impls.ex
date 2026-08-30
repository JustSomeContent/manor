# Protocol implementations for the lab's own types — a Part 9 exercise.
#
# Protocols dispatch on the *data's type* and exist for cross-cutting
# concerns — "how does this print" — never for game rules. (Game rules
# dispatch on *shape* with pattern matching, or on *modules* with
# behaviours; the decision essay is in Part 5 of the lab.)
#
# Implement three things in this file. Until you do, `Manor.Render`'s
# status bar raises Protocol.UndefinedError, and IEx prints games as a
# sixty-line struct dump — feel the before and after.
#
# 1. `String.Chars` for `Manor.Resources`:
#
#        defimpl String.Chars, for: Manor.Resources do
#          def to_string(resources), do: ...
#        end
#
#    Format: "Steps 17 | Keys 1 | Gems 3 | Coins 5". Interpolation is fine
#    here — this is leaf formatting, not a render loop.
#
# 2. `String.Chars` for `Manor.Room` — "Garden (standard)".
#
# 3. A custom `Inspect` for `Manor.Game` so IEx sessions stay terse:
#
#        #Manor.Game<turn: 12, at: {3, 4}, steps: 17, phase: :awaiting_command>
#
#    Use `Inspect.Algebra` at copy-the-recipe depth: `import Inspect.Algebra`,
#    then `concat/1` over string fragments and `to_doc(value, opts)` calls.
#    Collapse `{:drafting, %Draft{}}` to just `:drafting` — the point is a
#    one-line summary, not the whole truth (`view/1` has the whole truth).
#
defimpl String.Chars, for: Manor.Resources do
  def to_string(resources) do
    "Steps #{resources.steps} | Keys #{resources.keys} | " <>
      "Gems #{resources.gems} | Coins #{resources.coins}"
  end
end

defimpl String.Chars, for: Manor.Room do
  def to_string(room), do: "#{room.name} (#{room.rarity})"
end

defimpl Inspect, for: Manor.Game do
  import Inspect.Algebra

  def inspect(game, opts) do
    phase =
      case game.phase do
        {:drafting, _draft} -> :drafting
        other -> other
      end

    concat([
      "#Manor.Game<turn: ",
      to_doc(game.turn, opts),
      ", at: ",
      to_doc(game.player, opts),
      ", steps: ",
      to_doc(game.resources.steps, opts),
      ", phase: ",
      to_doc(phase, opts),
      ">"
    ])
  end
end
