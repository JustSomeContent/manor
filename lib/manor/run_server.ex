defmodule Manor.RunServer do
  @moduledoc """
  Part 7's hand-rolled stateful server: nothing but `spawn`, `send`,
  `receive`, and recursion.

  "Mutable state" on the BEAM is a pure function recursing with a new
  argument — the game lives *in the loop's argument*, nowhere else. Part 8
  rewrites this as a GenServer; keep this module around to diff against.
  """

  alias Manor.{Game, RunConfig}

  @timeout 5_000

  @doc """
  Spawn a server owning one fresh run.

  ## Part 7 hints
  `spawn/1` with a closure that builds the game and enters a private
  `loop/1`. (Plain `spawn`, not `spawn_link` — the crash drills in the lab
  sheet ask you to try both and watch what each does to your IEx shell.)

  The loop: `receive` two message shapes — `{{:turn, command}, from, ref}`
  and `{:peek, from, ref}` — reply with `send(from, {ref, reply})`, and
  recurse with the *new* state on success but the *old* state on
  `{:error, _}` (delegate the actual rules to `Manor.Game.command/2`;
  this process owns state, never logic).
  """
  @spec start(RunConfig.t()) :: pid()
  def start(%RunConfig{} = _config) do
    # TODO(Part 7)
    Manor.NotImplemented.todo!(part: 7, fun: "Manor.RunServer.start/1")
  end

  @doc """
  Apply a command synchronously and return the result.

  ## Part 7 hints
  This is request/reply built by hand: `make_ref/0`, send
  `{{:turn, command}, self(), ref}`, then `receive` matching the **pinned**
  ref (`{^ref, reply}` — what goes wrong without the pin?). Monitor the
  server first (`Process.monitor/1`) so a dead server answers
  `{:error, :server_down}` via its `{:DOWN, ...}` message instead of
  hanging until the `after #{@timeout}` timeout — and remember to
  demonitor with `[:flush]` on every path. Share this plumbing with
  `peek/1` through a private helper.
  """
  @spec turn(pid(), Game.command()) ::
          {:ok, Game.t()} | {:error, Game.error() | :timeout | :server_down}
  def turn(server, _command) when is_pid(server) do
    # TODO(Part 7)
    Manor.NotImplemented.todo!(part: 7, fun: "Manor.RunServer.turn/2")
  end

  @doc "Synchronous snapshot of the server's current game state."
  @spec peek(pid()) :: {:ok, Game.t()} | {:error, :timeout | :server_down}
  def peek(server) when is_pid(server) do
    # TODO(Part 7)
    Manor.NotImplemented.todo!(part: 7, fun: "Manor.RunServer.peek/1")
  end
end
