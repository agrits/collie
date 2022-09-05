defmodule Collie.Steps.Step1ReadPrint do
  alias Collie.{Printer, Reader}
  defp read(s), do: Reader.read_str(s)

  defp eval(ast, _env \\ "") do
    ast
  end

  defp print(exp), do: Printer.pr_str(exp)

  def rep(str) do
    str
    |> read
    |> eval
    |> print
  catch
    e -> "#{inspect(e)}"
  end

  def loop() do
    IO.gets("user> ")
    |> String.trim("\n")
    |> rep()
    |> IO.puts()

    loop()
  end
end
