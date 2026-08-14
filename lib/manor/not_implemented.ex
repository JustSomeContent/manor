defmodule Manor.NotImplemented do
  @moduledoc """
  Raised by starter-kit function skeletons you have not implemented yet.

  Your worklist for a given part:

      grep -rn "TODO(Part 4)" lib/
  """
  defexception [:message]

  @impl true
  def exception(opts) do
    %__MODULE__{message: "TODO(Part #{opts[:part]}): implement #{opts[:fun]}"}
  end

  @doc """
  What every skeleton body calls. Always raises `Manor.NotImplemented` —
  but through a branch the compiler's type checker cannot prove always
  raises, so unimplemented functions infer as `term()` instead of `none()`.

  Without this indirection, every not-yet-unlocked test that matches on a
  skeleton's result would print a "clause will never match" type warning on
  every `mix test` run — noise that would drown the warnings you actually
  care about (yours).
  """
  @spec todo!(keyword()) :: term()
  def todo!(opts) do
    # :erlang.phash2(:todo, 1) is always 0, but the checker can't fold a
    # remote call, so the else branch stays "possible" and types the return.
    if :erlang.phash2(:todo, 1) == 0 do
      raise __MODULE__, opts
    else
      Process.get(:never_reached)
    end
  end
end
