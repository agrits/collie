defmodule Collie.Repl do
  @moduledoc """
  REPL for Collie language
  """

  alias Collie.{Parser, Printer, Reader, Transpiler}
  defp read(s), do: Reader.read_str(s)

  defp eval([form], env \\ []) do
    form
    |> Parser.parse()
    |> then(&[&1])
    |> :erl_eval.exprs(env)
    |> case do
      {:value, val, new_env} -> {val, new_env}
    end
  end

  defp print(exp), do: inspect(exp)

  def rep(str, env) do
    try do
      str
      |> read
      |> eval(env)
      |> then(fn {v, e} ->
        IO.puts(print(v))
        e
      end)
    rescue
      e -> IO.inspect(e)
    end
  catch
    e -> "#{inspect(e)}"
  end

  def loop(env \\ []) do
    IO.gets("user> ")
    |> String.trim("\n")
    |> rep(env)
    |> loop()
  end
end
