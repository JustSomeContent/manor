defmodule Manor.Part8OtpTest do
  # Not async: these tests boot globally-named processes (the Registry and
  # the DynamicSupervisor); two async copies would fight over the names.
  # Purity bought Parts 1-6 `async: true`; here is the bill for state.
  use ExUnit.Case, async: false

  alias Manor.Game.Server

  import Manor.GameHelpers, only: [wait_until: 1]

  @moduletag part: 8

  setup do
    start_supervised!({Registry, keys: :unique, name: Manor.RunRegistry})
    start_supervised!({DynamicSupervisor, name: Manor.RunSupervisor, strategy: :one_for_one})
    :ok
  end

  describe "8.1 the facade" do
    test "8.1-R1 start_run/2 makes a named, viewable, listed run" do
      assert {:ok, pid} = Manor.start_run("monday", seed: 42)
      assert is_pid(pid)
      assert Manor.runs() == ["monday"]
      assert {:ok, game} = Manor.view("monday")
      assert game.player == Manor.Grid.entrance()
    end

    test "8.1-R2 duplicate names are refused by the Registry, not by you" do
      {:ok, pid} = Manor.start_run("monday", seed: 42)
      assert Manor.start_run("monday", seed: 43) == {:error, {:already_started, pid}}
    end

    test "8.1-R3 stop_run/1 tears down; unknown names are a tagged error" do
      {:ok, _pid} = Manor.start_run("monday", seed: 42)
      assert Manor.stop_run("monday") == :ok
      wait_until(fn -> Manor.runs() == [] end)
      assert Manor.stop_run("monday") == {:error, :no_such_run}
      assert Manor.view("monday") == {:error, :no_such_run}
    end
  end

  describe "8.2 the GenServer shell" do
    test "8.2-R1 commands go through by name and errors keep state" do
      {:ok, _pid} = Manor.start_run("day", seed: 42)

      assert {:ok, moved} = Server.move("day", :north)
      assert {:drafting, _} = moved.phase

      assert {:error, :draft_pending} = Server.move("day", :north)
      assert Server.view("day") == moved
    end

    test "8.2-R2 two named runs advance independently" do
      {:ok, _} = Manor.start_run("a", seed: 1)
      {:ok, _} = Manor.start_run("b", seed: 2)

      {:ok, _} = Server.move("a", :north)
      assert Server.view("a").phase != :awaiting_command
      assert Server.view("b").phase == :awaiting_command
      assert Enum.sort(Manor.runs()) == ["a", "b"]
    end
  end

  describe "8.3 crash behavior" do
    test "8.3-R1 a killed run vanishes: Registry cleans up, :temporary means no restart" do
      {:ok, pid} = Manor.start_run("doomed", seed: 42)
      ref = Process.monitor(pid)

      Process.exit(pid, :kill)
      assert_receive {:DOWN, ^ref, :process, ^pid, :killed}

      wait_until(fn -> Manor.runs() == [] end)
      assert %{active: 0} = DynamicSupervisor.count_children(Manor.RunSupervisor)

      # The state died with the process — a fresh start is a fresh day.
      assert {:ok, _new_pid} = Manor.start_run("doomed", seed: 42)
      assert {:ok, game} = Manor.view("doomed")
      assert game.turn == 0
    end

    test "8.3-R2 one run crashing never touches its neighbors" do
      {:ok, doomed} = Manor.start_run("doomed", seed: 1)
      {:ok, _} = Manor.start_run("survivor", seed: 2)
      {:ok, moved} = Server.move("survivor", :north)

      ref = Process.monitor(doomed)
      Process.exit(doomed, :kill)
      assert_receive {:DOWN, ^ref, :process, _pid, :killed}
      wait_until(fn -> Manor.runs() == ["survivor"] end)

      assert Server.view("survivor") == moved
    end
  end
end
