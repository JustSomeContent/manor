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
    # TODO(Part 9)
    Manor.NotImplemented.todo!(part: 9, fun: "Manor.CLI.Parser.parse/1")
  end
end
