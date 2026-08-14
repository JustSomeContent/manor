defmodule Manor.Part7RunServerTest do
  use ExUnit.Case, async: true

  alias Manor.{Fixtures, RunServer}

  @moduletag part: 7

  describe "7.1 start/1 and peek/1" do
    test "7.1-R1 a spawned server holds a fresh run" do
      server = RunServer.start(Fixtures.config())

      assert is_pid(server)
      assert {:ok, game} = RunServer.peek(server)
      assert game.player == Manor.Grid.entrance()
    end
  end

  describe "7.2 turn/2" do
    test "7.2-R1 a command advances the state the *server* holds" do
      server = RunServer.start(Fixtures.config())

      assert {:ok, moved} = RunServer.turn(server, {:move, :north})
      assert {:drafting, _} = moved.phase

      # The next peek sees the drafting state — the server remembered.
      assert {:ok, peeked} = RunServer.peek(server)
      assert peeked == moved
    end

    test "7.2-R2 a rejected command leaves the server's state untouched" do
      server = RunServer.start(Fixtures.config())
      {:ok, before} = RunServer.peek(server)

      assert {:error, :wall} = RunServer.turn(server, {:move, :south})
      assert {:ok, after_error} = RunServer.peek(server)
      assert after_error == before
    end
  end

  describe "7.3 a dead server answers, not hangs" do
    test "7.3-R1 turn/2 against a corpse is {:error, :server_down}" do
      server = RunServer.start(Fixtures.config())
      ref = Process.monitor(server)
      Process.exit(server, :kill)
      assert_receive {:DOWN, ^ref, :process, _pid, :killed}

      assert RunServer.turn(server, {:move, :north}) == {:error, :server_down}
      assert RunServer.peek(server) == {:error, :server_down}
    end
  end

  describe "7.4 servers are islands" do
    test "7.4-R1 two runs advance independently, even interleaved" do
      server_a = RunServer.start(Fixtures.config(seed: 1))
      server_b = RunServer.start(Fixtures.config(seed: 2))

      {:ok, _} = RunServer.turn(server_a, {:move, :north})
      {:ok, _} = RunServer.turn(server_b, {:move, :north})
      {:ok, a_after} = RunServer.turn(server_a, {:choose, 1})
      {:ok, b_peek} = RunServer.peek(server_b)

      assert a_after.player == {3, 2}
      assert {:drafting, _} = b_peek.phase
    end
  end
end
