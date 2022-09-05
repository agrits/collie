defmodule Collie.Transpiler do
  def write_to_file(code) do
    with {:ok, f} <- File.open("output.erl", [:write]) do
      transpiled =
        code
        |> transpile()

      IO.write(f, transpiled)
      File.close(f)
    end
  end

  def transpile(forms) do
    forms
    |> :erl_syntax.form_list()
    |> :erl_prettypr.format()
  end
end
