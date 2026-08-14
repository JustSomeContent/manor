defmodule Manor.Part1ResourcesTest do
  use ExUnit.Case, async: true

  alias Manor.Resources

  @moduletag part: 1

  describe "1.5 grant/3" do
    test "1.5-R1 granting adds to the right counter and only that counter" do
      purse = %Resources{steps: 10, keys: 1, gems: 2, coins: 0}

      assert Resources.grant(purse, :gems, 3) ==
               %Resources{steps: 10, keys: 1, gems: 5, coins: 0}
    end

    test "1.5-R2 the original struct is untouched — no mutation happened" do
      purse = %Resources{steps: 10}
      _bigger = Resources.grant(purse, :steps, 5)
      assert purse.steps == 10
    end
  end

  describe "1.6 spend/3" do
    test "1.6-R1 spending decrements and returns {:ok, purse}" do
      purse = %Resources{steps: 10}
      assert {:ok, %Resources{steps: 7}} = Resources.spend(purse, :steps, 3)
    end

    test "1.6-R2 spending down to exactly zero is allowed" do
      assert {:ok, %Resources{keys: 0}} = Resources.spend(%Resources{keys: 1}, :keys, 1)
    end

    test "1.6-R3 overspending is refused with a tagged error naming the resource" do
      purse = %Resources{coins: 2}
      assert Resources.spend(purse, :coins, 3) == {:error, {:insufficient, :coins}}
    end
  end

  describe "1.7 get/2" do
    test "1.7-R1 reads the current count" do
      assert Resources.get(%Resources{gems: 7}, :gems) == 7
      assert Resources.get(%Resources{}, :coins) == 0
    end
  end
end
