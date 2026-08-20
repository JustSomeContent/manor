defmodule Manor.Game do
  @moduledoc """
  The whole game, as one immutable value and the pure functions that
  advance it. This is the *functional core* — no processes, no IO, no
  hidden state. Part 8 wraps it in a GenServer without changing a line.

  ## Phases

  The `phase` field is a tagged sum type:

    * `:awaiting_command` — the player may move, buy, or combine
    * `{:drafting, %Manor.Game.Draft{}}` — a draft must be resolved first
    * `{:ended, :won | :out_of_steps}` — the day is over

  One field, three modes: "game over *and* draft pending" is
  unrepresentable, and every public function dispatches on the phase with
  multi-clause heads instead of if/else pyramids.

  ## Error philosophy

  `{:error, reason}` means the command was **rejected and the state is
  unchanged** — the caller still holds the same game and may try something
  else. Running out of steps and winning are not errors; they are legal
  transitions returned as `{:ok, game}` with an `{:ended, _}` phase.

  ## How this module grows

  You build it across three parts. Part 3: `new/1`, `move/2` through built
  rooms (walls, locks-with-keys, day-end, win), `over?/1`, `status/1`,
  `transcript/1`, and `command/2` (the test drivers speak command tuples
  from Part 3 on; clauses for not-yet-written functions just delegate to
  their skeletons). Part 4: the drafting flow (`move/2` into unbuilt
  cells, `candidates/1`, `choose_draft/2`). Part 5: effects wired into
  entering and placing, lockpicks as key substitutes, `buy/2`,
  `combine/3`. Part 6: `summary/1`.
  """

  alias Manor.PlacedRoom
  alias Manor.{DraftPool, Grid, Mansion, Resources, RNG, Room, RunConfig}
  alias Manor.Game.Draft

  import Manor.Grid, only: [is_direction: 1]

  @enforce_keys [:config, :mansion, :player, :resources, :inventory, :pool, :rng, :phase]
  defstruct [
    :config,
    :mansion,
    :player,
    :resources,
    :inventory,
    :pool,
    :rng,
    :phase,
    turn: 0,
    log: []
  ]

  @type phase :: :awaiting_command | {:drafting, Draft.t()} | {:ended, :won | :out_of_steps}

  @type t :: %__MODULE__{
          config: RunConfig.t(),
          mansion: Mansion.t(),
          player: Grid.coord(),
          resources: Resources.t(),
          inventory: %{Manor.Item.id() => pos_integer()},
          pool: DraftPool.t(),
          rng: RNG.t(),
          phase: phase(),
          turn: non_neg_integer(),
          log: [term()]
        }

  @type error ::
          :game_over
          | :draft_pending
          | :no_draft_pending
          | :wall
          | :locked_no_key
          | :invalid_choice
          | :not_in_shop
          | :not_in_workshop
          | :unknown_offer
          | :unknown_recipe
          | {:insufficient, Resources.kind()}
          | {:missing_item, Manor.Item.id()}

  @doc """
  A fresh day from a config: entrance placed, player standing in it.

  ## Part 3 hints
  Everything the struct needs comes from the config or a constructor you
  already have (`Mansion.new/1`, `DraftPool.new/1`, `RNG.new/1`). Empty
  inventory, `:awaiting_command`, turn 0, empty log.
  """
  @spec new(RunConfig.t()) :: t()
  def new(%RunConfig{} = config) do
    %__MODULE__{
      config: config,
      mansion: Mansion.new(config.entrance),
      player: Grid.entrance(),
      resources: config.starting_resources,
      inventory: %{},
      pool: DraftPool.new(config.rooms),
      rng: RNG.new(config.seed),
      phase: :awaiting_command
    }
  end

  @doc """
  Attempt to walk one cell in `direction`.

  The rulebook, in order: a passage must exist; a locked one must be paid
  for (a key — or, from Part 5, a lockpick — either permanently unlocks the
  door); the step is spent; then you either enter the built room or the
  move becomes a draft (`{:drafting, _}` phase — resolve it with
  `choose_draft/2`).

  Attempting a viable move with zero steps ends the day: that returns
  `{:ok, game}` with phase `{:ended, :out_of_steps}` — see the module doc.

  ## Part 3 hints
  Two rejection clauses matching the phase, then the real one: a `with`
  chain over three private helpers — passage lookup (`Mansion.passage/3`,
  turning `:wall` into `{:error, :wall}`), lock payment, step payment —
  then a `case` on the passage kind: `{:built, _, dest}` enters (Part 3),
  `{:unbuilt, _, dest}` begins a draft (Part 4). Let the day-end path
  return a non-matching tuple like `{:day_over, game}` from the step
  helper and convert it to `{:ok, game}` in the `with`'s `else`.

  Entering a room (a private helper you'll reuse from `choose_draft/2`):
  record the entry on the placed room (`Mansion.update!/3`), set the
  player, log `{:moved, dest}`, bump the turn, and end the day as
  `{:ended, :won}` if the room's category is `:goal`. Part 5 extends this
  same helper with effect triggers.
  """
  @spec move(t(), Grid.direction()) :: {:ok, t()} | {:error, error()}
  def move(%__MODULE__{phase: {:drafting, _}}, _direction), do: {:error, :draft_pending}
  def move(%__MODULE__{phase: {:ended, _}}, _direction), do: {:error, :game_over}

  def move(%__MODULE__{phase: :awaiting_command} = game, direction)
      when is_direction(direction) do
    with {:ok, passage} <- passage_from_player(game, direction),
         {:ok, game} <- pass_lock(game, direction, passage),
         {:ok, game} <- pay_step(game) do
      case passage do
        {:unbuilt, _lock, dest} -> {:ok, begin_draft(game, dest, direction)}
        {:built, _lock, dest} -> {:ok, enter_room(game, dest)}
      end
    else
      {:day_over, game} -> {:ok, game}
      {:error, _reason} = error -> error
    end
  end

  defp passage_from_player(game, direction) do
    case Mansion.passage(game.mansion, game.player, direction) do
      :wall -> {:error, :wall}
      passage -> {:ok, passage}
    end
  end

  defp pass_lock(game, _direction, {_kind, :open, _dest}), do: {:ok, game}

  defp pass_lock(game, direction, {_kind, :locked, _dest}) do
    case Resources.spend(game.resources, :keys, 1) do
      {:ok, resources} ->
        {:ok, unlock_ahead(%{game | resources: resources}, direction, :key)}

      {:error, {:insufficient, :keys}} ->
        # Part 5 slots the lockpick fallback here
        {:error, :locked_no_key}
    end
  end

  defp unlock_ahead(game, direction, opened_with) do
    %{game | mansion: Mansion.unlock(game.mansion, game.player, direction)}
    |> log_entry({:unlocked, opened_with})
  end

  defp pay_step(game) do
    case Resources.spend(game.resources, :steps, 1) do
      {:ok, resources} ->
        {:ok, %{game | resources: resources}}

      {:error, {:insufficient, :steps}} ->
        {:day_over,
         %{game | phase: {:ended, :out_of_steps}} |> log_entry({:day_over, :out_of_steps})}
    end
  end

  defp enter_room(game, dest) do
    mansion = Mansion.update!(game.mansion, dest, &PlacedRoom.record_entry/1)
    game = %{game | mansion: mansion, player: dest} |> log_entry({:moved, dest})

    {:ok, placed} = Mansion.fetch(game.mansion, dest)

    game
    # part 5 inserts effect triggers before this
    |> Map.update!(:turn, &(&1 + 1))
    |> check_win(placed)
  end

  defp check_win(game, %PlacedRoom{room: %Room{category: :goal}}) do
    %{game | phase: {:ended, :won}} |> log_entry({:won, game.player})
  end

  defp check_win(game, %PlacedRoom{}), do: game

  defp log_entry(game, entry), do: %{game | log: [entry | game.log]}

  @doc """
  The candidate templates of the pending draft.

  ## Part 4 hints
  Two clauses; the happy one pattern-matches the draft straight out of the
  phase tuple.
  """
  @spec candidates(t()) :: {:ok, [Room.t()]} | {:error, :no_draft_pending}
  def candidates(%__MODULE__{phase: {:drafting, draft}}), do: {:ok, draft.candidates}
  def candidates(%__MODULE__{}), do: {:error, :no_draft_pending}

  @doc """
  Resolve the pending draft by choosing candidate `index` (1-based).

  Pays the room's gem cost, stamps and places the instance (the door you
  walked in through is propped open, even on a room that keeps it locked
  for latecomers), removes the template from the pool, and walks you in.
  From Part 5 it also runs `:on_place` effects between placing and
  entering.

  ## Part 4 hints
  Phase-dispatch clauses again ({:ended, _} → `:game_over`, no draft →
  `:no_draft_pending`). The happy clause: a `with` over index validation
  (`{:error, :invalid_choice}` outside `1..length(candidates)`) and gem
  payment, then `PlacedRoom.new/2` |> `PlacedRoom.unlock/2` (with
  `Grid.opposite(draft.entered_via)`), `Mansion.place/2` asserted with
  `{:ok, mansion} = ...` (occupied is impossible here — why?),
  `DraftPool.remove/2`, phase back to `:awaiting_command`, log
  `{:placed, id, coord}`, and the same enter-room helper `move/2` uses.

  And where does the draft come from in the first place? Extend `move/2`'s
  unbuilt branch: filter-worthy candidates are those that can connect back
  (`Mansion.can_connect?/2`) *and* are allowed at the destination
  (`Room.allowed_at?/2`); `DraftPool.draw/4` with `config.draft_size`,
  falling back to `[config.fallback]` when nothing fits; wrap in a
  `%Draft{}` inside the phase, log `{:drafting, dest}`, and don't forget
  the rng came back changed.
  """
  @spec choose_draft(t(), pos_integer()) :: {:ok, t()} | {:error, error()}
  def choose_draft(%__MODULE__{phase: {:ended, _}}, _index), do: {:error, :game_over}

  def choose_draft(%__MODULE__{phase: {:drafting, draft}} = game, index)
      when is_integer(index) do
    with {:ok, template} <- pick_candidate(draft.candidates, index),
         {:ok, resources} <- pay_gems(game.resources, template.gem_cost) do
      placed =
        template
        |> PlacedRoom.new(draft.dest)
        |> PlacedRoom.unlock(Grid.opposite(draft.entered_via))

      {:ok, mansion} = Mansion.place(game.mansion, placed)

      game = %{
        game
        | resources: resources,
          mansion: mansion,
          pool: DraftPool.remove(game.pool, template.id),
          phase: :awaiting_command
      }

      game = log_entry(game, {:placed, template.id, draft.dest})
      {:ok, enter_room(game, draft.dest)}
    end
  end

  def choose_draft(%__MODULE__{}, _indx), do: {:error, :no_draft_pending}

  defp begin_draft(game, dest, direction) do
    eligible? = fn room ->
      Mansion.can_connect?(room, direction) and Room.allowed_at?(room, dest)
    end

    {candidates, rng} = DraftPool.draw(game.pool, game.rng, eligible?, game.config.draft_size)
    candidates = if candidates == [], do: [game.config.fallback], else: candidates

    draft = %Draft{dest: dest, entered_via: direction, candidates: candidates}

    %{game | rng: rng, phase: {:drafting, draft}}
    |> log_entry({:drafting, dest})
  end

  defp pick_candidate(candidates, index) do
    if index in 1..length(candidates) do
      {:ok, Enum.at(candidates, index - 1)}
    else
      {:error, :invalid_choice}
    end
  end

  defp pay_gems(resources, 0), do: {:ok, resources}
  defp pay_gems(resources, cost), do: Resources.spend(resources, :gems, cost)

  @doc """
  Buy a shop offer by id. Only works while standing in a `:shop` room.

  ## Part 5 hints
  Phase-dispatch clauses, then a `with`: room category check (a private
  helper both this and `combine/3` want), offer lookup by id
  (`{:error, :unknown_offer}`), `Resources.spend/3` in coins, then
  `Manor.Effect.apply_action/2` on the offer's `grants` — the shop reuses
  the effect vocabulary. Log `{:bought, offer_id}`.
  """
  @spec buy(t(), atom()) :: {:ok, t()} | {:error, error()}
  def buy(%__MODULE__{} = _game, offer_id) when is_atom(offer_id) do
    # TODO(Part 5)
    Manor.NotImplemented.todo!(part: 5, fun: "Manor.Game.buy/2")
  end

  @doc """
  Combine two inventory items in a `:workshop` room.

  Note there is no rollback code for "first item taken, second missing":
  on any error the *caller's* game value was never touched — immutability
  is the transaction.

  ## Part 5 hints
  Category check, `Manor.Recipe.find/3` (`:error` → `:unknown_recipe`),
  then take each input from the counted bag (a private `take_item/2`
  returning `{:error, {:missing_item, id}}` when absent — `combine cog cog`
  with one cog must fail on the *second* take), grant the output via
  `Effect.apply_action/2`, log `{:crafted, output}`.
  """
  @spec combine(t(), Manor.Item.id(), Manor.Item.id()) :: {:ok, t()} | {:error, error()}
  def combine(%__MODULE__{} = _game, a, b) when is_atom(a) and is_atom(b) do
    # TODO(Part 5)
    Manor.NotImplemented.todo!(part: 5, fun: "Manor.Game.combine/3")
  end

  @typedoc "A parsed player command, as produced by `Manor.CLI.Parser` and `Manor.Strategy` bots."
  @type command ::
          {:move, Grid.direction()}
          | {:choose, pos_integer()}
          | {:buy, atom()}
          | {:combine, Manor.Item.id(), Manor.Item.id()}

  @doc """
  Apply a parsed command — one entry point for scripted drivers.

  ## Part 3 hints
  Pure dispatch: one clause per command shape, each a one-line delegation
  to the target function. No `case` needed anywhere. Delegating to a
  still-skeletal function is fine — the clause only runs when that shape
  is actually sent, and by then you'll have written it.
  """
  @spec command(t(), command()) :: {:ok, t()} | {:error, error()}
  def command(%__MODULE__{} = game, {:move, direction}), do: move(game, direction)
  def command(%__MODULE__{} = game, {:choose, index}), do: choose_draft(game, index)
  def command(%__MODULE__{} = game, {:buy, offer_id}), do: buy(game, offer_id)
  def command(%__MODULE__{} = game, {:combine, id_1, id_2}), do: combine(game, id_1, id_2)

  @doc """
  Whether the day is over (won or out of steps).

  ## Part 3 hints
  Two heads, matching the phase. No `if`.
  """
  @spec over?(t()) :: boolean()
  def over?(%__MODULE__{phase: {:ended, _}}), do: true
  def over?(%__MODULE__{}), do: false

  @doc "The day's status, derived from the phase — never stored twice."
  @spec status(t()) :: :active | :won | :out_of_steps
  def status(%__MODULE__{phase: {:ended, reason}}), do: reason
  def status(%__MODULE__{}), do: :active

  @doc """
  The action log, oldest first.

  ## Part 3 hints
  Internally the log is newest-first, because prepending to a list is O(1)
  and appending is O(n). This function is where the reversal happens —
  once, at the edge.
  """
  @spec transcript(t()) :: [term()]
  def transcript(%__MODULE__{log: log}), do: Enum.reverse(log)

  @doc """
  An end-of-day report.

  ## Part 6 hints
  `status/1`, the turn counter, `map_size/1` of the mansion minus the
  entrance, and the purse.
  """
  @spec summary(t()) :: %{
          outcome: :active | :won | :out_of_steps,
          turns: non_neg_integer(),
          rooms_placed: non_neg_integer(),
          resources: Resources.t()
        }
  def summary(%__MODULE__{} = _game) do
    # TODO(Part 6)
    Manor.NotImplemented.todo!(part: 6, fun: "Manor.Game.summary/1")
  end
end
