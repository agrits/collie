defmodule Collie.LexerTest do
  use ExUnit.Case
  alias Collie.Lexer

  describe "read_str/1" do
    test "should return nil when line is empty" do
      assert {:ok, nil} = Lexer.read_str("")
    end

    test "should correctly tokenize symbols" do
      assert {:ok, [{:symbol, _, 0}, {:symbol, _, 1}]} = Lexer.read_str("+\nabc")
    end

    test "should correctly tokenize atoms" do
      assert {:ok, [{:atom, _, 0}]} = Lexer.read_str(":atom")
    end

    test "should correctly tokenize varcalls" do
      assert {:ok, [{:varcall, :a, 0}]} = Lexer.read_str(".$a")
    end

    test "should correctly tokenize binaries" do
      assert {:ok, [{:binary, [{:string, "abc", 0}], 0}]} = Lexer.read_str("<<\"abc\">>")
    end

    test "should correctly tokenize erlang remote calls" do
      assert {:ok, [{:erlang_remote, "a", "b", 0}]} = Lexer.read_str("a:b")
    end

    test "should correctly tokenize numbers" do
      assert {:ok, [{:float, 1.2, 0}, {:integer, 1, 1}]} = Lexer.read_str("1.2\n1")
    end

    test "should correctly tokenize booleans" do
      assert {:ok, [{:atom, false, 0}, {:atom, true, 1}]} = Lexer.read_str("false\ntrue")
    end

    test "should correctly tokenize collections" do
      assert {:ok, [{:vector, _, 0}, {:hashmap, _, 1}, {:list, _, 2}, {:list, _, 3}]} =
               Lexer.read_str("[1 2 3]\n{2 3 4 5}\n(1 2 3)\n()")
    end

    test "should correctly tokenize lists with tails" do
      assert {:ok, [{:vector, [{:symbol, "a", 0}, {:tail, {:symbol, "b", 0}}], 0}]} ==
               Lexer.read_str("[a | b]")
    end

    test "should correctly tokenize combinations of types" do
      assert {:ok,
              [
                {:list,
                 [
                   {:symbol, "abc", 0},
                   {:list, [{:symbol, "+", 0}, {:integer, 1, 0}, {:string, "abc", 0}], 0},
                   {:vector, [{:atom, true, 1}, {:atom, nil, 1}, {:var, :x, 1}], 1}
                 ], 0}
              ]} = Lexer.read_str("(abc (+ 1 \"abc\") \n [true nil $x])")
    end

    test "errors when unexpected EOL" do
      assert_raise(RuntimeError, fn -> Lexer.read_str("(") end)
      assert_raise(RuntimeError, fn -> Lexer.read_str("\"") end)
    end
  end
end
