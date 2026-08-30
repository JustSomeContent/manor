defmodule Mix.Tasks.Manor.Bench do
  @moduledoc """
  Benchmark a strategy over many simulated days:

      mix manor.bench --strategy greedy --runs 100
      mix manor.bench --strategy random --runs 50 --max-commands 300
      mix manor.bench --strategy Elixir.Manor.Strategy.Greedy

  Short names resolve under `Manor.Strategy.*`; anything with a dot is
  taken as a full module name. Seeds run 1..N, so two invocations with
  the same arguments compare apples to apples.
  """

  @shortdoc "Benchmark a bot over N seeded days (--strategy NAME --runs N)"

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, _rest} =
      OptionParser.parse!(argv,
        strict: [strategy: :string, runs: :integer, max_commands: :integer]
      )

    Mix.Task.run("app.start")

    strategy = resolve!(opts[:strategy] || "greedy")
    runs = opts[:runs] || 50
    max_commands = opts[:max_commands] || 400

    Manor.Benchmark.report(strategy, seeds: 1..runs, max_commands: max_commands)
  end

  defp resolve!(name) do
    module =
      if String.contains?(name, ".") do
        String.to_existing_atom("Elixir." <> String.trim_leading(name, "Elixir."))
      else
        Module.concat(Manor.Strategy, String.capitalize(name))
      end

    Code.ensure_loaded!(module)

    if function_exported?(module, :next_command, 1) do
      module
    else
      Mix.raise("#{inspect(module)} does not implement Manor.Strategy")
    end
  end
end
