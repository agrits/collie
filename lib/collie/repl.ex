defmodule Collie.Repl do
  @moduledoc """
  REPL for Collie language
  """

  alias Collie.{Parser, Lexer, Evaluator, Reader, Printer}

  @doc """
  REPL loop. Continuously gets user's input, evaluates it and prints.
  """
  @spec loop(env :: list()) :: no_return
  def loop(env \\ [], iterations \\ :infinite) do
    e_ =
      try do
        with str <- Reader.read_line(),
             {:ok, forms} <- Lexer.read_str(str),
             {:ok, ast} <- Parser.parse_forms(forms),
             {val, new_env} <- Evaluator.eval(ast, env) do
          Printer.print_val(val)
          new_env
        end
      rescue
        e ->
          IO.puts(inspect(e))
          env
      end

    case iterations do
      :infinite -> loop(e_)
      n when n > 1 -> loop(e_, iterations - 1)
    end
  end
end
