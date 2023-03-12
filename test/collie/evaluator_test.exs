defmodule Collie.EvaluatorTest do
  use ExUnit.Case

  test "evaluates erlang ast" do
    assert {:a, []} == Collie.Evaluator.eval([{:atom, 1, :a}], [])
  end
end
