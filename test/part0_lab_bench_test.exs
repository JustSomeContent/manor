defmodule Manor.Part0LabBenchTest do
  use ExUnit.Case, async: true

  @moduletag part: 0

  test "0.3-R1 Manor.hello/0 returns :welcome" do
    assert Manor.hello() == :welcome
  end
end
