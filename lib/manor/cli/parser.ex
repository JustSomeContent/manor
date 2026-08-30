defmodule Manor.CLI.Parser do
  @moduledoc """
  Pure text-to-command parsing. No IO in here — the parser has its own unit
  tests precisely because it never touches a terminal.

  One rule above all: **never `String.to_atom/1` on user input.** The atom
  table is never garbage collected, so unbounded atom creation is a leak an
  attacker (or a cat on a keyboard) can exploit. `String.to_existing_atom/1`
  only admits words some module already compiled in — and this boundary is
  one of the few places `rescue` is legitimate in the whole app.
  """

  alias Manor.Game

  @type parsed :: Game.command() | :look | :help | :quit

  @doc """
  Parse one input line. The grammar:

      n | north | s | south | e | east | w | west   -> {:move, direction}
      1 | 2 | 3 | ...                               -> {:choose, n}   (positive only)
      buy <offer>                                   -> {:buy, atom}
      combine <a> <b>                               -> {:combine, a, b}
      look | help | quit                            -> :look | :help | :quit
      anything else                                 -> {:error, :unknown_command}

  ## Part 9 hints
  `String.trim/1` + `String.downcase/1` first, then a private multi-clause
  `do_parse/1`. Binary pattern matching (`<<"buy ", rest::binary>>`) for
  prefixed commands, `String.split/1` for `combine`, `Integer.parse/1` for
  draft choices (`{n, ""}` — reject trailing junk like `"12 monkeys"`).
  Wrap `String.to_existing_atom/1` in a tiny private helper whose `rescue`
  turns `ArgumentError` into the error tuple. Order clauses from most to
  least specific.
  """
  @spec parse(String.t()) :: {:ok, parsed()} | {:error, :unknown_command}
  def parse(line) when is_binary(line) do
    line |> String.trim() |> String.downcase() |> do_parse()
  end

  defp do_parse("n"), do: {:ok, {:move, :north}}
  defp do_parse("north"), do: {:ok, {:move, :north}}
  defp do_parse("s"), do: {:ok, {:move, :south}}
  defp do_parse("south"), do: {:ok, {:move, :south}}
  defp do_parse("e"), do: {:ok, {:move, :east}}
  defp do_parse("east"), do: {:ok, {:move, :east}}
  defp do_parse("w"), do: {:ok, {:move, :west}}
  defp do_parse("west"), do: {:ok, {:move, :west}}
  defp do_parse("look"), do: {:ok, :look}
  defp do_parse("help"), do: {:ok, :help}
  defp do_parse("quit"), do: {:ok, :quit}

  defp do_parse(<<"buy ", rest::binary>>) do
    with {:ok, offer_id} <- existing_atom(String.trim(rest)) do
      {:ok, {:buy, offer_id}}
    end
  end

  defp do_parse(<<"combine ", rest::binary>>) do
    with [a, b] <- String.split(rest),
         {:ok, item_a} <- existing_atom(a),
         {:ok, item_b} <- existing_atom(b) do
      {:ok, {:combine, item_a, item_b}}
    else
      _ -> {:error, :unknown_command}
    end
  end

  defp do_parse(line) do
    case Integer.parse(line) do
      {index, ""} when index > 0 -> {:ok, {:choose, index}}
      _ -> {:error, :unknown_command}
    end
  end

  defp existing_atom(word) do
    {:ok, String.to_existing_atom(word)}
  rescue
    ArgumentError -> {:error, :unknown_command}
  end
end
