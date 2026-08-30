defmodule Manor.Benchmark do
  @moduledoc """
  Headless simulation harness: run a `Manor.Strategy` over many seeded
  days in parallel, distill each day's transcript into metrics, and
  aggregate — the instrument for improving bots and tuning mechanics.

  Unlike `Manor.Autoplay` this drives its own fold, because a benchmark
  needs what autoplay throws away: the *rejections*. A bot that walks
  into walls two hundred times a day looks identical to a good bot in
  the final summary — only attempted-vs-succeeded tells them apart.

  Each seed runs in its own process (`Task.async_stream`), and each
  process seeds its own `:rand` from the day's seed, so even strategies
  using the process-dictionary RNG (`Strategy.Random`) replay exactly.

      Manor.Benchmark.run(Manor.Strategy.Greedy, seeds: 1..100)
      # => %{runs: [...], aggregate: %{win_rate: 0.42, ...}}

      mix manor.bench --strategy greedy --runs 100
  """

  alias Manor.{Game, RunConfig}

  @default_seeds 1..50
  @default_max_commands 400

  @type run_metrics :: map()
  @type result :: %{aggregate: map(), runs: [run_metrics()]}

  @doc """
  Benchmark `strategy` over `:seeds` (default `1..50`), each day capped
  at `:max_commands` attempts (default 400). `:config` passes extra
  options through to `RunConfig.default/1` (resources, for instance).
  """
  @spec run(module(), keyword()) :: result()
  def run(strategy, opts \\ []) when is_atom(strategy) and is_list(opts) do
    seeds = Keyword.get(opts, :seeds, @default_seeds)
    max_commands = Keyword.get(opts, :max_commands, @default_max_commands)
    config_opts = Keyword.get(opts, :config, [])

    runs =
      seeds
      |> Task.async_stream(
        fn seed ->
          :rand.seed(:exsss, {seed, 17, 29})
          config = RunConfig.default(Keyword.put(config_opts, :seed, seed))
          {final, counts} = play(strategy, Game.new(config), max_commands, empty_counts())
          metrics(seed, final, counts)
        end,
        ordered: true,
        timeout: 30_000
      )
      |> Enum.map(fn {:ok, metrics} -> metrics end)

    %{runs: runs, aggregate: aggregate(runs)}
  end

  @doc "Run and print the aggregate report in one call."
  @spec report(module(), keyword()) :: result()
  def report(strategy, opts \\ []) do
    result = run(strategy, opts)
    IO.puts(format(strategy, result))
    result
  end

  ## The fold — like Autoplay's, but it counts what it sees

  defp empty_counts, do: %{attempted: 0, rejections: %{}}

  defp play(_strategy, game, 0, counts), do: {game, counts}

  defp play(strategy, game, remaining, counts) do
    if Game.over?(game) do
      {game, counts}
    else
      counts = %{counts | attempted: counts.attempted + 1}

      case Game.command(game, strategy.next_command(game)) do
        {:ok, game} ->
          play(strategy, game, remaining - 1, counts)

        {:error, reason} ->
          rejections = Map.update(counts.rejections, reason, 1, &(&1 + 1))
          play(strategy, game, remaining - 1, %{counts | rejections: rejections})
      end
    end
  end

  ## Per-run metrics, distilled from the final game + its transcript

  defp metrics(seed, %Game{} = game, counts) do
    transcript = Game.transcript(game)
    path = for {:moved, coord} <- transcript, do: coord
    drafted = for {:placed, id, _coord} <- transcript, do: id
    ranks = [1 | for({_col, rank} <- path, do: rank)]

    %{
      seed: seed,
      outcome: outcome(game),
      turns: game.turn,
      max_rank: Enum.max(ranks),
      moves: length(path),
      distinct_cells: path |> Enum.uniq() |> length(),
      revisits: length(path) - (path |> Enum.uniq() |> length()),
      drafted: drafted,
      closets: Enum.count(drafted, &(&1 == :closet)),
      buys: Enum.count(transcript, &match?({:bought, _}, &1)),
      crafts: Enum.count(transcript, &match?({:crafted, _}, &1)),
      unlocks: Enum.count(transcript, &match?({:unlocked, _}, &1)),
      attempted: counts.attempted,
      rejections: counts.rejections,
      rejected: counts.rejections |> Map.values() |> Enum.sum(),
      steps_left: game.resources.steps,
      keys_left: game.resources.keys,
      gems_left: game.resources.gems,
      coins_left: game.resources.coins
    }
  end

  # :exhausted = the command budget ran out with the day still live —
  # the signature of a bot stuck in a loop, distinct from every legal end.
  defp outcome(%Game{} = game) do
    case Game.status(game) do
      :active -> :exhausted
      reason -> reason
    end
  end

  ## Aggregation

  defp aggregate([]), do: %{}

  defp aggregate(runs) do
    n = length(runs)
    outcomes = Enum.frequencies_by(runs, & &1.outcome)
    wins = Enum.filter(runs, &(&1.outcome == :won))

    %{
      runs: n,
      outcomes: outcomes,
      win_rate: Float.round(length(wins) / n, 3),
      avg_turns_won: avg(wins, & &1.turns),
      avg_max_rank: avg(runs, & &1.max_rank),
      avg_rejected: avg(runs, & &1.rejected),
      rejection_reasons: merge_frequencies(runs, & &1.rejections),
      avg_revisits: avg(runs, & &1.revisits),
      avg_closets: avg(runs, & &1.closets),
      avg_buys: avg(runs, & &1.buys),
      avg_gems_left: avg(runs, & &1.gems_left),
      avg_coins_left: avg(runs, & &1.coins_left),
      most_drafted: runs |> Enum.flat_map(& &1.drafted) |> Enum.frequencies() |> top(5)
    }
  end

  defp avg([], _fun), do: nil
  defp avg(runs, fun), do: Float.round(Enum.sum(Enum.map(runs, fun)) / length(runs), 2)

  defp merge_frequencies(runs, fun) do
    runs
    |> Enum.map(fun)
    |> Enum.reduce(%{}, fn freq, acc -> Map.merge(acc, freq, fn _k, a, b -> a + b end) end)
  end

  defp top(frequencies, count) do
    frequencies |> Enum.sort_by(fn {_k, v} -> -v end) |> Enum.take(count)
  end

  ## Report

  @doc "The aggregate as printable iodata."
  @spec format(module(), result()) :: iodata()
  def format(strategy, %{aggregate: agg}) do
    outcomes =
      agg.outcomes
      |> Enum.sort_by(fn {_k, v} -> -v end)
      |> Enum.map(fn {k, v} -> [Atom.to_string(k), " ", Integer.to_string(v)] end)
      |> Enum.intersperse("  ")

    top_drafts =
      agg.most_drafted
      |> Enum.map(fn {id, v} -> [Atom.to_string(id), " ×", Integer.to_string(v)] end)
      |> Enum.intersperse(", ")

    rejections =
      agg.rejection_reasons
      |> Enum.sort_by(fn {_k, v} -> -v end)
      |> Enum.take(4)
      |> Enum.map(fn {k, v} -> [inspect(k), " ×", Integer.to_string(v)] end)
      |> Enum.intersperse(", ")

    [
      "── Benchmark: ",
      inspect(strategy),
      " over ",
      Integer.to_string(agg.runs),
      " days ──\n",
      "  outcomes      ",
      outcomes,
      "\n",
      "  win rate      ",
      inspect(agg.win_rate),
      "\n",
      "  avg turns/win ",
      inspect(agg.avg_turns_won),
      "\n",
      "  avg max rank  ",
      inspect(agg.avg_max_rank),
      "\n",
      "  avg rejected  ",
      inspect(agg.avg_rejected),
      "   (",
      rejections,
      ")\n",
      "  avg revisits  ",
      inspect(agg.avg_revisits),
      "\n",
      "  avg closets   ",
      inspect(agg.avg_closets),
      "   avg buys ",
      inspect(agg.avg_buys),
      "\n",
      "  left over     gems ",
      inspect(agg.avg_gems_left),
      " · coins ",
      inspect(agg.avg_coins_left),
      "\n",
      "  most drafted  ",
      top_drafts,
      "\n"
    ]
  end
end
