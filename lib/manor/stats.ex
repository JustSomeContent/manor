defmodule Manor.Stats do
  @moduledoc """
  Annex A: the stats vault — state that survives crashed runs.

  A GenServer owning a named ETS table. Day records arrive by an
  *explicit call* at day's end from the CLI loop — never from a server's
  `terminate/2`, which simply does not run on a `:kill` or a hard crash;
  a vault relying on it would lose exactly the days it exists to keep.
  Reads (`report/0`) go straight to the table with no message
  round-trip: ETS's reads-without-messages superpower.

  A run crashing mid-day loses that day and nothing else — the table's
  owner never crashed. Kill a run in IEx and watch `report/0` not blink.
  """

  use GenServer

  alias Manor.Game

  @table :manor_stats

  ## Client

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
  end

  @doc "Record a finished (or retired) day — explicit, from the driver."
  @spec record(Game.t()) :: :ok
  def record(%Game{} = game) do
    drafted = for {:placed, id, _coord} <- Game.transcript(game), do: id
    entry = Map.put(Game.summary(game), :drafted, drafted)
    GenServer.call(__MODULE__, {:record, entry})
  end

  @doc "Read the vault — straight from ETS, no message to the owner."
  @spec report() :: map()
  def report do
    entries = for {_id, entry} <- :ets.tab2list(@table), do: entry
    days = length(entries)
    wins = Enum.filter(entries, &(&1.outcome == :won))

    %{
      days: days,
      wins: length(wins),
      win_rate: if(days > 0, do: Float.round(length(wins) / days, 3), else: 0.0),
      best_day: wins |> Enum.map(& &1.turns) |> Enum.min(fn -> nil end),
      most_drafted:
        entries
        |> Enum.flat_map(& &1.drafted)
        |> Enum.frequencies()
        |> Enum.sort_by(fn {_id, count} -> -count end)
        |> Enum.take(5)
    }
  end

  @spec reset() :: :ok
  def reset, do: GenServer.call(__MODULE__, :reset)

  ## Server

  @impl GenServer
  def init(:ok) do
    table = :ets.new(@table, [:set, :protected, :named_table, read_concurrency: true])
    {:ok, %{table: table, next_id: 0}}
  end

  @impl GenServer
  def handle_call({:record, entry}, _from, state) do
    :ets.insert(@table, {state.next_id, entry})
    {:reply, :ok, %{state | next_id: state.next_id + 1}}
  end

  def handle_call(:reset, _from, state) do
    :ets.delete_all_objects(@table)
    {:reply, :ok, %{state | next_id: 0}}
  end
end
