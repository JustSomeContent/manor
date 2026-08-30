defmodule Manor.CLI do
  @moduledoc """
  The thin, impure edge: read a line, parse it, call the supervised run,
  print the frame, recurse. Launched from `iex -S mix` (with the
  application booted — Part 8) via:

      Manor.CLI.play("day-1", seed: 42)

  The loop is a plain tail-recursive function in *your* IEx process; the
  run lives in its own supervised GenServer. A crash while rendering or
  parsing kills this loop, not the run — `attach/1` reconnects.
  """

  alias Manor.{Game, Mansion, Render}
  alias Manor.CLI.Parser
  alias Manor.Game.Server

  @doc """
  Start a fresh named run and attach to it.

  ## Part 9 hints
  `Manor.start_run/2`, treating `{:error, {:already_started, _}}` as "fine,
  attach anyway".
  """
  @spec play(String.t(), keyword()) :: :ok
  def play(name, opts \\ []) when is_binary(name) and is_list(opts) do
    case Manor.start_run(name, opts) do
      {:ok, _pid} -> attach(name)
      {:error, {:already_started, _pid}} -> attach(name)
    end
  end

  @doc """
  Attach to a live run: render, read, dispatch, repeat.

  ## Part 9 hints
  A private tail-recursive `loop(name, game)`: `IO.puts(Render.render(game))`
  (yes, `IO.puts` takes iodata directly), stop when `Game.over?/1`, else
  `IO.gets("> ")` → `Parser.parse/1` → a `case`: `:quit` returns, `:look`
  re-fetches `Server.view/1`, `:help` prints the command list, a command
  tuple goes to a private `dispatch/2` (one clause per command shape,
  delegating to `Server.move/2` and friends — errors print and loop with
  the old state). `IO.gets` returns `:eof` / `{:error, _}` when the
  terminal is gone; treat any non-binary as "quit".

  Suppress the unused-alias warnings by actually using all four aliases —
  they are exactly the modules this loop needs.
  """
  @spec attach(String.t()) :: :ok
  def attach(name) when is_binary(name) do
    loop(name, Server.view(name))
  end

  # One frame per state change. Everything informational (help, look,
  # rejections) prints below the frame and re-prompts without redrawing —
  # a redraw after every input buries the very line the player asked for.
  defp loop(name, game) do
    IO.puts(Render.render(game))

    if Game.over?(game) do
      :ok
    else
      prompt_loop(name, game)
    end
  end

  defp prompt_loop(name, game) do
    # IO.gets returns :eof / {:error, _} (not nil, whatever the hint said);
    # anything non-binary means the terminal is gone — treat it as quit.
    input =
      case IO.gets("> ") do
        line when is_binary(line) -> line
        _eof_or_error -> "quit"
      end

    case Parser.parse(input) do
      {:ok, :quit} ->
        :ok

      {:ok, :look} ->
        IO.puts(room_details(game))
        prompt_loop(name, game)

      {:ok, :help} ->
        IO.puts(help())
        prompt_loop(name, game)

      {:ok, command} ->
        case dispatch(name, command) do
          {:ok, new_game} ->
            loop(name, new_game)

          {:error, reason} ->
            IO.puts(["(rejected: ", inspect(reason), ")"])
            prompt_loop(name, game)
        end

      {:error, :unknown_command} ->
        IO.puts("(unknown command — try help)")
        prompt_loop(name, game)
    end
  end

  defp room_details(%Game{} = game) do
    {:ok, placed} = Mansion.fetch(game.mansion, game.player)

    [
      ["You are in the ", Kernel.to_string(placed.room), ".\n"],
      category_details(game, placed.room.category),
      inventory_line(game)
    ]
  end

  defp category_details(game, :shop) do
    [
      "The shop sells (buy <id>):\n"
      | for offer <- game.config.shop_offers do
          [
            "  ",
            Atom.to_string(offer.id),
            " — ",
            offer.label,
            " — ",
            Integer.to_string(offer.price),
            " coins\n"
          ]
        end
    ]
  end

  defp category_details(game, :workshop) do
    [
      "The workshop combines (combine <a> <b>):\n"
      | for %{inputs: {a, b}, output: output} <- game.config.recipes do
          ["  ", Atom.to_string(a), " + ", Atom.to_string(b), " → ", Atom.to_string(output), "\n"]
        end
    ]
  end

  defp category_details(_game, _category), do: []

  defp inventory_line(%Game{inventory: inventory}) when map_size(inventory) == 0 do
    "You carry nothing."
  end

  defp inventory_line(%Game{inventory: inventory}) do
    items =
      inventory
      |> Enum.sort()
      |> Enum.map(fn {id, count} -> [Atom.to_string(id), " ×", Integer.to_string(count)] end)
      |> Enum.intersperse(", ")

    ["You carry: ", items, "."]
  end

  defp help do
    """
    Commands:
      n / s / e / w   — move (or north / south / east / west)
      1, 2, 3         — pick a draft candidate, while drafting
      look            — this room's details: shop stock, recipes, your items
      buy <id>        — in a shop ("look" shows the ids and prices)
      combine <a> <b> — in the workshop
      quit            — leave; the day keeps running, Manor.CLI.attach/1 returns
    """
    |> String.trim_trailing()
  end

  defp dispatch(name, {:move, direction}), do: Server.move(name, direction)
  defp dispatch(name, {:choose, index}), do: Server.choose(name, index)
  defp dispatch(name, {:buy, offer_id}), do: Server.buy(name, offer_id)
  defp dispatch(name, {:combine, a, b}), do: Server.combine(name, a, b)
end
