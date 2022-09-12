defmodule Collie.ReaderTest do
  use ExUnit.Case
  alias Collie.Reader

  describe "read_str/1" do
    test "should correctly tokenize symbols" do
      assert [{:symbol, _, 0}, {:symbol, _, 1}] = Reader.read_str("+\nabc")
    end

    test "should correctly tokenize numbers" do
      assert [{:float, 1.2, 0}, {:integer, 1, 1}] = Reader.read_str("1.2\n1")
    end

    test "should correctly tokenize booleans" do
      assert [{:boolean, false, 0}, {:boolean, true, 1}] = Reader.read_str("false\ntrue")
    end

    test "should correctly tokenize collections" do
      assert [{:vector, _, 0}, {:hashmap, _, 1}, {:list, _, 2}, {:list, _, 3}] =
               Reader.read_str("[1 2 3]\n{2 3 4 5}\n(1 2 3)\n()")
    end

    test "should correctly tokenize combinations of types" do
      assert [
               {:list,
                [
                  {:symbol, "abc", 0},
                  {:list, [{:symbol, "+", 0}, {:integer, 1, 0}, {:string, "abc", 0}], 0},
                  {:vector, [{:boolean, true, 1}, {:atom, nil, 1}, {:var, :x, 1}], 1}
                ], 0}
             ] = Reader.read_str("(abc (+ 1 \"abc\") \n [true nil $x])")
    end
  end
end
