defmodule Collie.ParserTest do
  use ExUnit.Case

  alias Collie.Parser

  @operations ~w(+ - * / == > < <= =< /= rem div or and not xor band bor bxor bnot)

  describe "parse_forms/1" do
    test "atom" do
      test_construct({:atom, :A, 1}, {:atom, 1, :A})
    end

    test "float" do
      test_construct({:float, 1.0, 1}, {:float, 1, 1.0})
    end

    test "integer" do
      test_construct({:float, 2, 1}, {:float, 1, 2})
    end

    test "string" do
      test_construct({:string, "a", 1}, {:string, 1, String.to_charlist("a")})
    end

    test "binary" do
      test_construct(
        {:binary, [{:string, "a", 1}], 1},
        {:bin, 1, [{:bin_element, 1, {:string, 1, 'a'}, :default, :default}]}
      )
    end

    test "binc" do
      test_construct(
        {:list, [{:symbol, "binc", 1}, {:binary, [{:string, "a", 1}], 1}], 1},
        {:bin, 1, [{:bin_element, 1, {:string, 1, 'a'}, :default, [:binary]}]}
      )

      test_construct(
        {:list, [{:symbol, "binc", 1}, {:string, "a", 1}], 1},
        {:bin, 1, [{:bin_element, 1, {:string, 1, 'a'}, :default, [:binary]}]}
      )
    end

    test "var" do
      test_construct({:var, :A, 1}, {:var, 1, :A_})
      test_construct({:var, :a, 1}, {:var, 1, :A})
      test_construct({:var, :_, 1}, {:var, 1, :_})
    end

    test "hashmap" do
      test_construct(
        {:hashmap, %{{:atom, :a, 0} => {:atom, :b, 0}}, 0},
        {:map, 0, [{:map_field_assoc, 0, {:atom, 0, :a}, {:atom, 0, :b}}]}
      )
    end

    test "vector" do
      test_construct({:vector, [{:atom, :a, 1}], 1}, {:tuple, 1, [{:atom, 1, :a}]})
    end

    test "list" do
      test_construct({:list, [{:atom, :a, 1}], 1}, {:cons, 1, {:atom, 1, :a}, {nil, 1}})
      test_construct({:list, [{:tail, {:atom, :a, 1}}], 1}, {:atom, 1, :a})
    end

    test "varcall" do
      test_construct(
        {:list, [{:varcall, :a, 1}, {:atom, :b, 1}], 1},
        {:call, 1, {:atom, 1, :A}, [{:atom, 1, :b}]}
      )
    end

    test "call" do
      test_construct(
        {:list, [{:symbol, "A", 1}, {:atom, :b, 1}], 1},
        {:call, 1, {:atom, 1, :A}, [{:atom, 1, :b}]}
      )
    end

    test "operation" do
      for op <- @operations do
        test_construct(
          {:list, [{:symbol, op, 1}, {:integer, 1, 1}, {:integer, 2, 1}], 1},
          {:op, 1, String.to_atom(op), {:integer, 1, 1}, {:integer, 1, 2}}
        )
      end
    end

    test "lambda" do
      test_construct(
        {:list,
         [{:symbol, "lambda", 1}, {:list, [{:atom, :a, 1}], 1}, {:list, [{:atom, :b, 1}], 1}], 1},
        {:fun, 1, {:clauses, [{:clause, 1, [{:atom, 1, :a}], [], [{:atom, 1, :b}]}]}}
      )
    end

    test "export" do
      test_construct(
        {:list,
         [
           {:symbol, "export", 1},
           {:list, [{:vector, [{:symbol, "A", 1}, {:integer, 0, 1}], 1}], 1}
         ], 1},
        {:attribute, 1, :export, [A: 0]}
      )
    end

    test "match" do
      test_construct(
        {:list, [{:symbol, "=", 1}, {:atom, :a, 1}, {:atom, :a, 1}], 1},
        {:match, 1, {:atom, 1, :a}, {:atom, 1, :a}}
      )
    end

    test "compile" do
      test_construct(
        {:list, [{:symbol, "compile", 1}, {:atom, :a, 1}], 1},
        {:attribute, 1, :compile, {:a}}
      )
    end

    test "module" do
      test_construct(
        {:list, [{:symbol, "module", 1}, {:symbol, "A", 1}], 1},
        {:attribute, 1, :module, :A}
      )
    end

    test "erlang_remote" do
      test_construct(
        {:list, [{:erlang_remote, "a", "b", 1}], 1},
        {:call, 1, {:remote, 1, {:atom, 1, :a}, {:atom, 1, :b}}, []}
      )
    end

    test "if" do
      test_construct(
        {:list, [{:symbol, "if", 1}, {:atom, nil, 1}, {:atom, :a, 1}], 1},
        {:if, 1, [{:clause, 1, [], [{:atom, 1, nil}], [{:atom, 1, :a}]}]}
      )
    end

    test "case" do
      test_construct(
        {:list,
         [{:symbol, "case", 1}, {:atom, nil, 1}, {:list, [{:atom, nil, 1}, {:atom, :a, 1}], 1}],
         1},
        {:case, 1, {:atom, 1, nil}, [{:clause, 1, [{:atom, 1, nil}], [], [{:atom, 1, :a}]}]}
      )
    end

    test "defn" do
      test_construct(
        {:list,
         [
           {:symbol, "defn", 1},
           {:symbol, "A", 1},
           {:list, [{:var, :a, 1}], 1},
           {:list, [{:var, :a, 1}], 1}
         ], 1},
        {:function, 1, :A, 1, [{:clause, 1, [{:var, 1, :A}], [], [{:var, 1, :A}]}]}
      )

      test_construct(
        {:list,
         [
           {:symbol, "defn", 1},
           {:symbol, "A", 1},
           {:list, [], 1},
           {:list, [], 1}
         ], 1},
        {:function, 1, :A, 0, [{:clause, 1, [], [], []}]}
      )
    end

    test "raises when unexpected symbol received" do
      assert_raise RuntimeError, fn -> Parser.parse_forms([{:symbol, "A", 1}]) end
    end
  end

  defp test_construct(payload, result) do
    assert {:ok, [{:cons, 0, result, {nil, 0}}]} == Parser.parse_forms([{:list, [payload], 0}])
  end
end
