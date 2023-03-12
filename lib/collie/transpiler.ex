defmodule Collie.Transpiler do
  @moduledoc """
  Responsible for transpiling Erlang AST to Erlang code
  """

  @doc """
  Transpile Erlang AST representation to Erlang code
  """
  @spec transpile(forms :: list()) :: {:ok, code :: String.t()}
  def transpile(forms) do
    {:ok,
     forms
     |> :erl_syntax.form_list()
     |> :erl_prettypr.format()}
  end
end
