defmodule Mix.Tasks.Manor.Play do
  @moduledoc """
  Play a day from the terminal:

      mix manor.play --seed 42

  **Provided.** A Mix task is just a module implementing the `Mix.Task`
  behaviour with a `run/1` — another behaviour sighting in the wild.
  """

  @shortdoc "Play a day of Manor (--seed N, defaults to a fixed 42)"

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, _rest} = OptionParser.parse!(argv, strict: [seed: :integer])

    # Boot the app's supervision tree even if mix.exs's mod: line is
    # still commented out (pre-Part 8 curiosity is allowed).
    Mix.Task.run("app.start")
    ensure_tree()

    Manor.CLI.play("terminal", seed: opts[:seed] || 42)
  end

  defp ensure_tree do
    if Process.whereis(Manor.RunRegistry) == nil do
      Manor.Application.start(:normal, [])
    end

    :ok
  end
end
