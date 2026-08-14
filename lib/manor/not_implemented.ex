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
end
