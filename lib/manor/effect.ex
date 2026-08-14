defmodule Manor.Effect do
  @moduledoc """
  Room effects as *data*, interpreted by pure functions.

  An effect is a `{trigger, action}` tuple carried on a room template:

      effects: [
        {:on_place, {:grant, :steps, 2}},   # Bedroom: +2 steps when drafted
        {:on_enter, {:grant, :gems, 1}},    # Garden: +1 gem each entry
        {:per_turn, {:grant, :coins, 1}}    # Terrace: +1 coin every turn while placed
      ]

  This is a tiny DSL and this module is its evaluator: adding an effect
  kind means adding one interpreter clause, not a new module. Shop offers
  reuse the same `action` vocabulary, so buying is "pay coins, then run an
  action". Rooms that need *computed* logic instead of static grants use
  the `Manor.Special` behaviour — the decision rule is data for the many,
  behaviour for the bespoke few.
  """

  alias Manor.{PlacedRoom, Resources}

  @type trigger :: :on_place | :on_enter | :per_turn
  @type action ::
          {:grant, Resources.kind(), pos_integer()}
          | {:grant_item, Manor.Item.id()}
  @type t :: {trigger(), action()}

  @doc """
  Run every effect on `placed`'s template that fires on `trigger`.

  ## Part 5 hints
  Filter the template's effects to the trigger, then fold with
  `apply_action/2`. A comprehension with a pinned pattern in the generator
  (`for {^trigger, action} <- ...`) filters and destructures in one move.
  """
  @spec apply_trigger(Manor.Game.t(), PlacedRoom.t(), trigger()) :: Manor.Game.t()
  def apply_trigger(_game, %PlacedRoom{} = _placed, trigger)
      when trigger in [:on_place, :on_enter, :per_turn] do
    # TODO(Part 5)
    Manor.NotImplemented.todo!(part: 5, fun: "Manor.Effect.apply_trigger/3")
  end

  @doc """
  Interpret one action against the game state. One clause per action kind —
  a missing clause on a new action is a loud `FunctionClauseError`, which is
  a design signal, not a defect.

  Both actions should append to the game's log: `{:granted, kind, n}` and
  `{:received, item_id}` respectively.

  ## Part 5 hints
  `Manor.Resources.grant/3` for one clause; `Map.update/4` on the counted
  inventory bag for the other. Update the game with `Map.update!/3` (avoid
  `%Manor.Game{}` struct syntax here — this module compiles before Game).
  Guarding a clause with `Resources.is_kind/1`? Guards are macros — you'll
  need `require Manor.Resources` up top.
  """
  @spec apply_action(Manor.Game.t(), action()) :: Manor.Game.t()
  def apply_action(_game, _action) do
    # TODO(Part 5)
    Manor.NotImplemented.todo!(part: 5, fun: "Manor.Effect.apply_action/2")
  end
end
