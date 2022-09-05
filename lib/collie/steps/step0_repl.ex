defmodule Collie.Steps.Step0Repl do
  defp read(s) do
    s
  end

  defp eval(ast, _env \\ %{}) do
    ast
  end

  defp print(exp) do
    IO.write(exp)
  end

  def loop() do
    IO.gets("user> ")
    |> read()
    |> eval()
    |> print()

    loop()
  end
end
