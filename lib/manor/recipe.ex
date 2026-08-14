defmodule Manor.Recipe do
  @moduledoc """
  A workshop recipe: two input items combine into one output item.

  Recipes are unordered — `combine shovel cog` and `combine cog shovel`
  name the same recipe. Struct PROVIDED; the lookup is yours.
  """

  alias Manor.Item

  @enforce_keys [:inputs, :output]
  defstruct [:inputs, :output]

  @type t :: %__MODULE__{inputs: {Item.id(), Item.id()}, output: Item.id()}

  @doc """
  Find the recipe whose inputs are `a` and `b`, in either order.

  Returns `{:ok, recipe} | :error` (mirroring `Map.fetch/2`'s shape).

  ## Part 5 hints
  `Enum.find/2` plus a private `matches?/3`. Repeated variables in a
  pattern must be equal — `matches?(%{inputs: {a, b}}, a, b)` is a whole
  clause with no body logic at all. Two such clauses and a catch-all.
  """
  @spec find([t()], Item.id(), Item.id()) :: {:ok, t()} | :error
  def find(recipes, a, b) when is_list(recipes) and is_atom(a) and is_atom(b) do
    # TODO(Part 5)
    Manor.NotImplemented.todo!(part: 5, fun: "Manor.Recipe.find/3")
  end
end
