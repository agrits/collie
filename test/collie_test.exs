defmodule CollieTest do
  use ExUnit.Case
  doctest Collie

  test "greets the world" do
    assert Collie.hello() == :world
  end
end
