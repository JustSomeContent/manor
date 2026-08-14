defmodule Manor.Part4RngTest do
  use ExUnit.Case, async: true

  alias Manor.RNG

  @moduletag part: 4

  describe "4.1 uniform/2" do
    test "4.1-R1 same seed, same sequence — determinism by construction" do
      rng_a = RNG.new(1234)
      rng_b = RNG.new(1234)

      {rolls_a, _} = roll_many(rng_a, 10)
      {rolls_b, _} = roll_many(rng_b, 10)

      assert rolls_a == rolls_b
    end

    test "4.1-R2 forgetting to thread the state repeats the same roll" do
      rng = RNG.new(99)
      {roll_one, _dropped} = RNG.uniform(rng, 1_000_000)
      {roll_two, _dropped} = RNG.uniform(rng, 1_000_000)
      # The classic bug, demonstrated: identical rolls from an unthreaded state.
      assert roll_one == roll_two
    end

    test "4.1-R3 rolls stay in 1..n" do
      {rolls, _} = roll_many(RNG.new(7), 50)
      assert Enum.all?(rolls, &(&1 in 1..6))
    end

    defp roll_many(rng, count) do
      Enum.map_reduce(1..count, rng, fn _, rng -> RNG.uniform(rng, 6) end)
    end
  end

  describe "4.2 weighted/2" do
    test "4.2-R1 all the weight on one key always picks it" do
      {pick, _rng} = RNG.weighted(RNG.new(5), %{only: 10})
      assert pick == :only
    end

    test "4.2-R2 heavier keys win more often" do
      {picks, _rng} =
        Enum.map_reduce(1..200, RNG.new(11), fn _, rng ->
          RNG.weighted(rng, %{common: 90, rare: 10})
        end)

      counts = Enum.frequencies(picks)
      assert counts.common > counts.rare
    end
  end

  describe "4.3 take_weighted/4" do
    test "4.3-R1 picks are distinct" do
      items = Enum.to_list(1..10)
      {taken, _rng} = RNG.take_weighted(RNG.new(3), items, fn _ -> 1 end, 5)
      assert length(taken) == 5
      assert taken == Enum.uniq(taken)
    end

    test "4.3-R2 asking for more than exists returns everything" do
      {taken, _rng} = RNG.take_weighted(RNG.new(3), [:a, :b], fn _ -> 1 end, 5)
      assert Enum.sort(taken) == [:a, :b]
    end

    test "4.3-R3 asking for zero returns nothing and an advanced-or-equal state" do
      {taken, _rng} = RNG.take_weighted(RNG.new(3), [:a, :b], fn _ -> 1 end, 0)
      assert taken == []
    end
  end
end
