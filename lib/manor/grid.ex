defmodule Manor.Grid do
  @moduledoc """
  Pure geometry of the 5×9 mansion grid. No game rules live here.

  Coordinates are plain `{col, rank}` tuples, 1-based. The entrance sits at
  the center of rank 1; "north" means `rank + 1`, toward the goal at rank 9.

  There is deliberately no `%Coord{}` struct: tuples are natural map keys,
  pattern-match in function heads, and compare structurally. The *module*
  still owns the type and the functions — modules organize functions over
  data; they are not classes.
  """

  @columns 5
  @ranks 9

  @type col :: 1..5
  @type rank :: 1..9
  @type coord :: {col(), rank()}
  @type direction :: :north | :east | :south | :west

  @doc "Guard-safe test that `term` is one of the four directions. PROVIDED."
  defguard is_direction(term) when term in [:north, :east, :south, :west]

  @doc "The fixed entrance coordinate: center column, rank 1. PROVIDED."
  @spec entrance() :: coord()
  def entrance, do: {div(@columns, 2) + 1, 1}

  @doc "The rank the player is trying to reach. PROVIDED."
  @spec goal_rank() :: 9
  def goal_rank, do: @ranks

  @doc """
  Whether a `{col, rank}` tuple falls inside the 5×9 grid.

  ## Part 1 hints
  Ranges in guards: `col in 1..5`. One clause for two-tuples, a catch-all
  for anything else.
  """
  @spec in_bounds?(term()) :: boolean()
  def in_bounds?({col, rank}) when col in 1..@columns and rank in 1..@ranks, do: true
  def in_bounds?(_), do: false

  @doc """
  The neighboring coordinate one cell in `direction`, or `{:error, :off_grid}`
  when it would leave the grid.

      iex> Manor.Grid.step({3, 1}, :north)
      {:ok, {3, 2}}

      iex> Manor.Grid.step({3, 9}, :north)
      {:error, :off_grid}

  ## Part 1 hints
  One clause per direction; validate the result with `in_bounds?/1`.
  """
  @spec step(coord(), direction()) :: {:ok, coord()} | {:error, :off_grid}
  def step({col, rank}, direction) when is_direction(direction) do
    candidate_coord =
      case direction do
        :north -> {col, rank + 1}
        :east -> {col + 1, rank}
        :south -> {col, rank - 1}
        :west -> {col - 1, rank}
      end

    if in_bounds?(candidate_coord), do: {:ok, candidate_coord}, else: {:error, :off_grid}
  end

  @doc """
  The opposite direction. A room drafted while walking `:north` must have a
  door facing `:south` to connect back.

  These `iex>` lines are *doctests* — Part 6 turns them on as real tests:

      iex> Manor.Grid.opposite(:north)
      :south

      iex> Manor.Grid.opposite(:east)
      :west
  """
  @spec opposite(direction()) :: direction()
  def opposite(:north), do: :south
  def opposite(:south), do: :north
  def opposite(:east), do: :west
  def opposite(:west), do: :east

  @doc """
  Every coordinate on the grid, column-major, for renderers and tests.

  ## Part 1 hints
  A `for` comprehension over two generators — or wait for Part 4's
  comprehension lesson and write it with `Enum.flat_map/2` today.
  """
  @spec all_coords() :: [coord()]
  def all_coords do
    for rank <- 1..@ranks, col <- 1..@columns, do: {col, rank}
  end
end
