defmodule Collie.TranspilerTest do
  use ExUnit.Case

  alias Collie.{Lexer, Parser, Transpiler}

  test "transpilers Collie code to Erlang code" do
    code = """
    (module hello)
    (export ([start 0]))

    (defn start () ((io:fwrite "Hello, world!\\n")))
    """

    output =
      '-module(hello).\n\n-export([start/0]).\n\nstart() -> io:fwrite(\"Hello, world!\\n\").'

    {:ok, ast} =
      code
      |> String.trim()
      |> Lexer.read_str()

    {:ok, parsed} = Parser.parse_forms(ast)

    assert {:ok, output} == Transpiler.transpile(parsed)
  end
end
