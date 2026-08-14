defmodule Manor.Game.Server do
  @moduledoc """
  The OTP shell around the pure core: one GenServer per run.

  Every mutating callback is the same four lines — delegate to `Manor.Game`,
  reply, and keep the *old* state on error. The server contains **zero game
  rules**; diff this against `Manor.RunServer` to see exactly what
  `GenServer` standardized (and against `Manor.Game` to see what OTP never
  needed to know).

  Everything is `call`, nothing is `cast`: every command has a result the
  caller needs (`{:error, :locked_no_key}` must reach the player), and
  `call` gives backpressure for free. (Try rewriting `move/2` as a cast
  once, in IEx, and ask yourself where the error went.)

  Runs are registered by name in `Manor.RunRegistry` via `{:via, ...}`
  tuples, so callers address `"day-1"`, never a PID — and user-supplied
  names never leak atoms.
  """

  use GenServer, restart: :temporary

  alias Manor.{Game, Grid, RunConfig}

  ## Client API

  @doc """
  Start a server for a fresh run. Options: `:name` (string, required) and
  `:config` (`Manor.RunConfig.t`, required).

  ## Part 8 hints
  `GenServer.start_link(__MODULE__, config, name: via(name))` where
  `via(name)` is a private one-liner returning
  `{:via, Registry, {Manor.RunRegistry, name}}`.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) when is_list(opts) do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.Game.Server.start_link/1")
  end

  @doc "Each client function is one `GenServer.call/2` through the via tuple."
  @spec move(String.t(), Grid.direction()) :: {:ok, Game.t()} | {:error, Game.error()}
  def move(name, _direction) when is_binary(name) do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.Game.Server.move/2")
  end

  @spec choose(String.t(), pos_integer()) :: {:ok, Game.t()} | {:error, Game.error()}
  def choose(name, _index) when is_binary(name) do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.Game.Server.choose/2")
  end

  @spec buy(String.t(), atom()) :: {:ok, Game.t()} | {:error, Game.error()}
  def buy(name, _offer_id) when is_binary(name) do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.Game.Server.buy/2")
  end

  @spec combine(String.t(), Manor.Item.id(), Manor.Item.id()) ::
          {:ok, Game.t()} | {:error, Game.error()}
  def combine(name, _a, _b) when is_binary(name) do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.Game.Server.combine/3")
  end

  @spec view(String.t()) :: Game.t()
  def view(name) when is_binary(name) do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.Game.Server.view/1")
  end

  ## Server callbacks

  @doc """
  ## Part 8 hints
  `init/1` gets the config and returns `{:ok, Game.new(config)}` — the
  whole state is the pure game value.

  For `handle_call/3`: one clause for `:view` replying with the state, and
  one clause for command tuples. The command clause is the four-line motif
  from the module doc: `Manor.Game.command/2`, then `{:reply, {:ok, new}, new}`
  or `{:reply, error, game}` — error keeps the OLD state. A malformed
  message will crash in `Game.command/2`'s pattern match; that is
  let-it-crash working as intended, not a case to handle.
  """
  @impl GenServer
  def init(%RunConfig{} = _config) do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.Game.Server.init/1")
  end

  @impl GenServer
  def handle_call(_request, _from, _game) do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.Game.Server.handle_call/3")
  end
end
