defmodule Manor.GameHelpers do
  @moduledoc """
  Scripted drivers and state surgery for tests. **Provided.**

  The surgery helpers (`place!/3`, `set_resources/2`, …) exist so movement
  tests can hand-build exact mansions instead of depending on the RNG —
  keep them out of `lib/`; reaching into state like this is a test-only
  privilege.
  """

  alias Manor.{Game, Mansion, PlacedRoom, Resources, Room}

  @doc "Fold a list of commands over a game, raising on the first rejection."
  @spec play!(Game.t(), [Game.command()]) :: Game.t()
  def play!(game, commands) do
    Enum.reduce(commands, game, fn command, game ->
      case Game.command(game, command) do
        {:ok, game} -> game
        {:error, reason} -> raise "command #{inspect(command)} rejected: #{inspect(reason)}"
      end
    end)
  end

  @doc "Fold commands, halting on the first rejection: `{:ok, game}` or `{:error, reason, game_so_far}`."
  @spec play(Game.t(), [Game.command()]) :: {:ok, Game.t()} | {:error, term(), Game.t()}
  def play(game, commands) do
    Enum.reduce_while(commands, {:ok, game}, fn command, {:ok, game} ->
      case Game.command(game, command) do
        {:ok, game} -> {:cont, {:ok, game}}
        {:error, reason} -> {:halt, {:error, reason, game}}
      end
    end)
  end

  @doc "Force a template into a cell, bypassing the draft. Raises on occupied cells."
  @spec place!(Game.t(), Room.t(), Manor.Grid.coord()) :: Game.t()
  def place!(%Game{} = game, %Room{} = template, coord) do
    {:ok, mansion} = Mansion.place(game.mansion, PlacedRoom.new(template, coord))
    %{game | mansion: mansion}
  end

  @doc "Overwrite resource counts, e.g. `set_resources(game, steps: 0)`."
  @spec set_resources(Game.t(), keyword()) :: Game.t()
  def set_resources(%Game{} = game, counts) do
    %{
      game
      | resources: struct!(Resources, Map.merge(Map.from_struct(game.resources), Map.new(counts)))
    }
  end

  @doc "Drop items straight into the inventory."
  @spec give_item(Game.t(), Manor.Item.id(), pos_integer()) :: Game.t()
  def give_item(%Game{} = game, item_id, count \\ 1) do
    %{game | inventory: Map.update(game.inventory, item_id, count, &(&1 + count))}
  end

  @doc "Teleport the player (the cell must be built)."
  @spec force_player(Game.t(), Manor.Grid.coord()) :: Game.t()
  def force_player(%Game{} = game, coord) do
    true = Mansion.built?(game.mansion, coord)
    %{game | player: coord}
  end

  @doc "Poll `fun` until truthy or `timeout` ms elapse. For registry-cleanup races in Part 8."
  @spec wait_until((-> boolean()), non_neg_integer()) :: :ok
  def wait_until(fun, timeout \\ 500)
  def wait_until(_fun, timeout) when timeout <= 0, do: raise("condition never became true")

  def wait_until(fun, timeout) do
    if fun.() do
      :ok
    else
      Process.sleep(10)
      wait_until(fun, timeout - 10)
    end
  end
end
