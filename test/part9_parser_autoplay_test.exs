defmodule Manor.Part9ParserAutoplayTest do
  use ExUnit.Case, async: true

  alias Manor.{Autoplay, Fixtures, Game, Strategy}
  alias Manor.CLI.Parser

  @moduletag part: 9

  describe "9.6 Parser.parse/1" do
    test "9.6-R1 movement, long and short, any case, any padding" do
      assert Parser.parse("n") == {:ok, {:move, :north}}
      assert Parser.parse("  North  ") == {:ok, {:move, :north}}
      assert Parser.parse("w") == {:ok, {:move, :west}}
      assert Parser.parse("EAST") == {:ok, {:move, :east}}
    end

    test "9.6-R2 bare numbers choose drafts" do
      assert Parser.parse("2") == {:ok, {:choose, 2}}
      assert Parser.parse("0") == {:error, :unknown_command}
    end

    test "9.6-R3 buy and combine carry their arguments" do
      assert Parser.parse("buy trail_mix") == {:ok, {:buy, :trail_mix}}
      assert Parser.parse("combine shovel cog") == {:ok, {:combine, :shovel, :cog}}
    end

    test "9.6-R4 look, help, quit" do
      assert Parser.parse("look") == {:ok, :look}
      assert Parser.parse("help") == {:ok, :help}
      assert Parser.parse("quit") == {:ok, :quit}
    end

    test "9.6-R5 junk never raises — and never mints atoms" do
      for junk <- [
            "",
            "xyzzy",
            "buy",
            "combine shovel",
            "buy zqxwv_never_seen",
            "12 monkeys",
            "☂"
          ] do
        assert Parser.parse(junk) == {:error, :unknown_command}
      end
    end
  end

  describe "9.7 strategies and autoplay" do
    test "9.7-R1 the random bot survives 500 commands without crashing the core" do
      :rand.seed(:exsss, {1, 2, 3})
      final = Autoplay.run(Strategy.Random, Fixtures.config(seed: 5), 500)
      assert %Game{} = final
    end

    test "9.7-R2 seeding the *process* makes even the random bot repeatable" do
      :rand.seed(:exsss, {1, 2, 3})
      final_a = Autoplay.run(Strategy.Random, Fixtures.config(seed: 5), 300)

      :rand.seed(:exsss, {1, 2, 3})
      final_b = Autoplay.run(Strategy.Random, Fixtures.config(seed: 5), 300)

      assert final_a == final_b
    end

    test "9.7-R3 the greedy bot climbs to the antechamber" do
      final = Autoplay.run(Strategy.Greedy, Fixtures.config(seed: 42), 200)
      assert Game.status(final) == :won
      {_col, rank} = final.player
      assert rank == 9
    end
  end
end
