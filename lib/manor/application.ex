defmodule Manor.Application do
  @moduledoc """
  The application callback: boots the static supervision tree.

  Only two children — the Registry that names runs and the
  DynamicSupervisor that owns them. Runs themselves are started on demand
  (`Manor.start_run/2`), which is exactly what a DynamicSupervisor is for.

  Until Part 8 the `mod:` line in `mix.exs` is commented out, so this
  module compiles but never runs. Uncomment it once `start/2` works and
  `iex -S mix` boots the tree.
  """

  use Application

  @doc """
  ## Part 8 hints
  A child spec list with `{Registry, keys: :unique, name: Manor.RunRegistry}`
  and `{DynamicSupervisor, name: Manor.RunSupervisor, strategy: :one_for_one}`,
  handed to `Supervisor.start_link/2` (`strategy: :one_for_one`, name it
  `Manor.Supervisor`). Then uncomment `mod:` in mix.exs and check the tree
  in IEx with `Supervisor.which_children(Manor.Supervisor)`.
  """
  @impl Application
  def start(_type, _args) do
    # TODO(Part 8)
    raise Manor.NotImplemented, part: 8, fun: "Manor.Application.start/2"
  end
end
