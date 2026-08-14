defmodule Manor do
  @moduledoc """
  The public front door.

  `hello/0` is Part 0's smoke test. Everything else arrives in Part 8:
  named, supervised, concurrent runs addressed by string id — no PIDs in
  sight from the caller's side.
  """

  alias Manor.Game

  @doc """
  The Part 0 warm-up: returns `:welcome`.

  ## Part 0 hints
  This exists so you experience the full red → green → compare loop once,
  end to end, on something trivial. Run `mix test`, read the failure, fix
  it, rerun.
  """
  @spec hello() :: :welcome
  def hello do
    :welcome
  end

  @spec start_run(any(), any()) :: none()
  @doc """
  Start a supervised run named `name` (any string) with the given options
  (`:seed` required — see `Manor.RunConfig.default/1`).

  ## Part 8 hints
  `Manor.RunConfig.default/1` for the config, then
  `DynamicSupervisor.start_child(Manor.RunSupervisor, {Manor.Game.Server, opts})`.
  Duplicate names come back as `{:error, {:already_started, pid}}` for free —
  the Registry enforces uniqueness, not you.
  """
  @spec start_run(String.t(), keyword()) :: DynamicSupervisor.on_start_child()
  def start_run(name, opts) when is_binary(name) and is_list(opts) do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.start_run/2")
  end

  @doc """
  Stop a run by name. `{:error, :no_such_run}` when it isn't there.

  ## Part 8 hints
  `Registry.lookup/2` gives `[{pid, value}]` or `[]`; pattern-match both,
  and hand the pid to `DynamicSupervisor.terminate_child/2`.
  """
  @spec stop_run(String.t()) :: :ok | {:error, :no_such_run}
  def stop_run(name) when is_binary(name) do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.stop_run/1")
  end

  @doc """
  The names of all live runs.

  ## Part 8 hints
  `Registry.select/2` with a match spec — a deliberate one-time taste of
  Erlang match specs; the shape you want is
  `[{{:"$1", :_, :_}, [], [:"$1"]}]`.
  """
  @spec runs() :: [String.t()]
  def runs do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.runs/0")
  end

  @doc """
  Snapshot of a named run's full game state.

  ## Part 8 hints
  `Registry.lookup/2` again; on a hit, `GenServer.call(pid, :view)`.
  """
  @spec view(String.t()) :: {:ok, Game.t()} | {:error, :no_such_run}
  def view(name) when is_binary(name) do
    # TODO(Part 8)
    Manor.NotImplemented.todo!(part: 8, fun: "Manor.view/1")
  end
end
