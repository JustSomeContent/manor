defmodule Manor.CLI do
  @moduledoc """
  The thin, impure edge: read a line, parse it, call the supervised run,
  print the frame, recurse. Launched from `iex -S mix` (with the
  application booted — Part 8) via:

      Manor.CLI.play("day-1", seed: 42)

  The loop is a plain tail-recursive function in *your* IEx process; the
  run lives in its own supervised GenServer. A crash while rendering or
  parsing kills this loop, not the run — `attach/1` reconnects.
  """

  alias Manor.{Game, Render}
  alias Manor.CLI.Parser
  alias Manor.Game.Server

  @doc """
  Start a fresh named run and attach to it.

  ## Part 9 hints
  `Manor.start_run/2`, treating `{:error, {:already_started, _}}` as "fine,
  attach anyway".
  """
  @spec play(String.t(), keyword()) :: :ok
  def play(name, opts \\ []) when is_binary(name) and is_list(opts) do
    # TODO(Part 9)
    raise Manor.NotImplemented, part: 9, fun: "Manor.CLI.play/2"
  end

  @doc """
  Attach to a live run: render, read, dispatch, repeat.

  ## Part 9 hints
  A private tail-recursive `loop(name, game)`: `IO.puts(Render.render(game))`
  (yes, `IO.puts` takes iodata directly), stop when `Game.over?/1`, else
  `IO.gets("> ")` → `Parser.parse/1` → a `case`: `:quit` returns, `:look`
  re-fetches `Server.view/1`, `:help` prints the command list, a command
  tuple goes to a private `dispatch/2` (one clause per command shape,
  delegating to `Server.move/2` and friends — errors print and loop with
  the old state). `IO.gets` can return `nil` on EOF; `|| "quit"` handles it.

  Suppress the unused-alias warnings by actually using all four aliases —
  they are exactly the modules this loop needs.
  """
  @spec attach(String.t()) :: :ok
  def attach(name) when is_binary(name) do
    # TODO(Part 9)
    _ = {Game, Render, Parser, Server}
    raise Manor.NotImplemented, part: 9, fun: "Manor.CLI.attach/1"
  end
end
