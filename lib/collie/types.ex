defmodule Collie.Types do
  def vector(ast, line_number), do: {:vector, ast, line_number}

  def list(ast, line_number), do: {:list, ast, line_number}

  def symbol(ast, line_number), do: {:symbol, ast, line_number}

  def hashmap(ast, line_number), do: {:hashmap, ast, line_number}

  def boolean(ast, line_number), do: {:boolean, ast, line_number}

  def integer(ast, line_number), do: {:integer, ast, line_number}

  def float(ast, line_number), do: {:float, ast, line_number}

  def string(ast, line_number), do: {:string, ast, line_number}

  def atom(ast, line_number), do: {:atom, ast, line_number}

  def erlang_remote(lib, f, line_number), do: {:erlang_remote, lib, f, line_number}

  def var(ast, line_number), do: {:var, ast, line_number}
end
