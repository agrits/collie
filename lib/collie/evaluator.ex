defmodule Collie.Evaluator do
  @moduledoc """
  Responsible for evaluting Erlang AST
  """

  @doc """
  Evaluates Erlang AST with env
  """
  @spec eval(ast :: list(), env :: list()) :: {any(), list()}
  def eval(ast, env) do
    ast
    |> :erl_eval.exprs(env)
    |> case do
      {:value, val, new_env} -> {val, new_env}
    end
  end
end
