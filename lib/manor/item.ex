defmodule Manor.Item do
  @moduledoc """
  An inventory item.

  Keys and coins are *resources* (counters on `Manor.Resources`, spent by
  core rules); items are the things you carry, combine in the workshop, and
  occasionally substitute for resources (a lockpick can stand in for a key).

  The player's inventory is deliberately **not** a struct — it is a plain
  counted bag, `%{Manor.Item.id() => count}`, living inside `Manor.Game`.
  """

  @enforce_keys [:id, :name, :description]
  defstruct [:id, :name, :description]

  @type id :: atom()
  @type t :: %__MODULE__{id: id(), name: String.t(), description: String.t()}
end
