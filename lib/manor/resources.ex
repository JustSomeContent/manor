defmodule Manor.Resources do
  @moduledoc """
  The four spendable resources a day runs on.

  Steps tick down as you move; keys open locked doors; gems pay for rare
  drafts; coins are spent in shops. All four are non-negative counters —
  the *rules* about when they may be spent live in `Manor.Game`, not here.
  """

  defstruct steps: 0, keys: 0, gems: 0, coins: 0

  @type kind :: :steps | :keys | :gems | :coins
  @type t :: %__MODULE__{
          steps: non_neg_integer(),
          keys: non_neg_integer(),
          gems: non_neg_integer(),
          coins: non_neg_integer()
        }

  @kinds [:steps, :keys, :gems, :coins]

  @doc "Guard-safe test that `term` names a resource. PROVIDED."
  defguard is_kind(term) when term in @kinds

  @doc """
  Add `amount` of a resource. Granting never fails.

  ## Part 1 hints
  `Map.update!/3` works on structs (they are maps underneath) — but so does
  building the update around `Map.fetch!/2` + `%{res | ...}`. Pick one and
  say why.
  """
  @spec grant(t(), kind(), pos_integer()) :: t()
  def grant(%__MODULE__{} = resources, kind, amount)
      when is_kind(kind) and is_integer(amount) and amount > 0 do
    Map.update!(resources, kind, &(&1 + amount))
  end

  @doc """
  Spend `amount` of a resource, or refuse with a tagged error when short.

  Spending is all-or-nothing: `{:error, {:insufficient, kind}}` leaves the
  struct untouched (the caller still holds the original — nothing to undo).

  ## Part 1 hints
  A `case` on the current count with a guard clause (`have when have >= amount`),
  or two function heads. No `if` needed.
  """
  @spec spend(t(), kind(), pos_integer()) :: {:ok, t()} | {:error, {:insufficient, kind()}}
  def spend(%__MODULE__{} = resources, kind, amount)
      when is_kind(kind) and is_integer(amount) and amount > 0 do
    case Map.fetch!(resources, kind) do
      have when have >= amount -> {:ok, Map.put(resources, kind, have - amount)}
      _short -> {:error, {:insufficient, kind}}
    end
  end

  @doc """
  Current count of a resource.

  ## Part 1 hints
  Structs are maps; `Map.fetch!/2` is assertive on purpose here — asking
  for a resource that doesn't exist is a bug, not a condition.
  """
  @spec get(t(), kind()) :: non_neg_integer()
  def get(%__MODULE__{} = resources, kind) when is_kind(kind) do
    Map.fetch!(resources, kind)
  end
end
