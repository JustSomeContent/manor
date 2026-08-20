defmodule Manor.RNG do
  @moduledoc """
  A thin *pure* wrapper over Erlang's `:rand` explicit-state API.

  `:rand.uniform/1` reads and writes hidden per-process state — a purity
  leak that makes seeds lie and tests flake. This module only ever touches
  the `_s` ("state") variants: every function takes an RNG state and
  returns a new one alongside its result, so **seed + call sequence fully
  determines every roll**. The one long-lived RNG value lives inside
  `Manor.Game`.
  """

  @type t :: :rand.state()

  @doc "A deterministic generator state from an integer seed. PROVIDED."
  @spec new(integer()) :: t()
  def new(seed) when is_integer(seed) do
    :rand.seed_s(:exsss, {seed, seed, seed})
  end

  @doc """
  A uniform integer in `1..n`, plus the advanced state.

  ## Part 4 hints
  `:rand.uniform_s/2` — mind the argument order, and that it returns a
  `{value, state}` tuple already.
  """
  @spec uniform(t(), pos_integer()) :: {pos_integer(), t()}
  def uniform(rng, n) when is_integer(n) and n > 0, do: :rand.uniform_s(n, rng)

  @doc """
  Pick one key from a map of `key => weight`, proportionally to weight.

  ## Part 4 hints
  Roll `uniform(rng, total_weight)`, then walk the entries subtracting
  weights until the roll lands (a fold, or explicit recursion over
  `Enum.sort/1`-ed entries — sort so the walk order is deterministic).
  """
  @spec weighted(t(), %{key => pos_integer()}) :: {key, t()} when key: term()
  def weighted(rng, weights) when is_map(weights) and map_size(weights) > 0 do
    entries = Enum.sort(weights)
    total = entries |> Enum.map(fn {_key, weight} -> weight end) |> Enum.sum()
    {roll, rng} = uniform(rng, total)
    {pick(entries, roll), rng}
  end

  defp pick([{key, weight} | rest], roll) do
    if roll <= weight, do: key, else: pick(rest, roll - weight)
  end

  @doc """
  Sample up to `count` *distinct* items from `items`, each draw weighted by
  `weight_fun`. Returns the picks and the advanced state.

  Fewer than `count` items in? You get them all.

  ## Part 4 hints
  Tail recursion with an accumulator: pick one (the `weighted/2` idea, but
  walking a list with a weight function), remove it from the candidates,
  recurse with `count - 1`, threading the rng the whole way down. Two base
  cases; remember the prepend-then-`Enum.reverse/1` idiom.
  """
  @spec take_weighted(t(), [item], (item -> pos_integer()), non_neg_integer()) ::
          {[item], t()}
        when item: term()
  def take_weighted(rng, items, weight_fun, count)
      when is_list(items) and is_function(weight_fun, 1) and is_integer(count) and count >= 0 do
    do_take(rng, items, weight_fun, count, [])
  end

  defp do_take(rng, items, _weight_fun, count, taken) when items == [] or count == 0 do
    {Enum.reverse(taken), rng}
  end

  defp do_take(rng, items, weight_fun, count, taken) do
    total = items |> Enum.map(weight_fun) |> Enum.sum()
    {roll, rng} = uniform(rng, total)
    {picked, rest} = split_at_roll(items, weight_fun, roll, [])
    do_take(rng, rest, weight_fun, count - 1, [picked | taken])
  end

  defp split_at_roll([item | rest], weight_fun, roll, skipped) do
    weight = weight_fun.(item)

    if roll <= weight do
      {item, Enum.reverse(skipped, rest)}
    else
      split_at_roll(rest, weight_fun, roll - weight, [item | skipped])
    end
  end
end
