defmodule Manor.Effect do
  @moduledoc """
  Room effects as *data*, interpreted by pure functions.

  An effect is a `{trigger, action}` tuple carried on a room template:

      effects: [
        {:on_place, {:grant, :steps, 2}},   # Bedroom: +2 steps when drafted
        {:on_enter, {:grant, :gems, 1}},    # Garden: +1 gem each entry
        {:per_turn, {:grant, :coins, 1}},   # Terrace: +1 coin every turn while placed
        {:on_exit, {:drain, :steps, 1}}     # Drafty Hall: leaving costs an extra step
      ]

  This is a tiny DSL and this module is its evaluator: adding an effect
  kind means adding one interpreter clause, not a new module. Shop offers
  reuse the same `action` vocabulary, so buying is "pay coins, then run an
  action". Rooms that need *computed* logic instead of static grants use
  the `Manor.Special` behaviour — the decision rule is data for the many,
  behaviour for the bespoke few.
  """

  require Manor.Resources
  alias Manor.{PlacedRoom, Resources}

  @type trigger :: :on_place | :on_enter | :on_exit | :per_turn
  @type action ::
          {:grant, Resources.kind(), pos_integer()}
          | {:drain, Resources.kind(), pos_integer()}
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
  def apply_trigger(game, %PlacedRoom{room: room}, trigger)
      when trigger in [:on_place, :on_enter, :on_exit, :per_turn] do
    actions = for {^trigger, action} <- room.effects, do: action
    Enum.reduce(actions, game, &apply_action(&2, &1))
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
  def apply_action(game, {:grant, kind, amount}) when Resources.is_kind(kind) do
    game
    |> Map.update!(:resources, &Resources.grant(&1, kind, amount))
    |> log({:granted, kind, amount})
  end

  def apply_action(game, {:drain, kind, amount}) when Resources.is_kind(kind) do
    game
    |> Map.update!(:resources, &Resources.drain(&1, kind, amount))
    |> log({:drained, kind, amount})
  end

  def apply_action(game, {:grant_item, item_id}) when is_atom(item_id) do
    game
    |> Map.update!(:inventory, &Map.update(&1, item_id, 1, fn n -> n + 1 end))
    |> log({:received, item_id})
  end

  defp log(game, entry), do: Map.update!(game, :log, &[entry | &1])
end
