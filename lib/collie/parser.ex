defmodule Collie.Parser do
  @moduledoc """
  Responsible for Parsing Collie AST to Erlang AST
  """

  @operations ~w(+ - * / == > < <= =< /= rem div or and not xor band bor bxor bnot)

  @doc """
  Parse Collie AST forms to Erlang AST forms
  """
  @spec parse_forms(forms :: list()) :: {:ok, erlang_ast :: list()}
  def parse_forms(forms) when is_list(forms) do
    {:ok, forms |> Enum.map(&parse/1)}
  end

  defp parse({:list, [{:erlang_remote, lib, f, line_number} | args], _}) do
    args_parsed = args |> Enum.map(&parse/1)

    {:call, line_number,
     {:remote, line_number, {:atom, line_number, String.to_atom(lib)},
      {:atom, line_number, String.to_atom(f)}}, args_parsed}
  end

  defp parse({:list, [{:symbol, "case", _}, on | clauses], line_number}) do
    clauses_mapped =
      clauses
      |> Enum.map(&case_clause/1)

    case_ast(line_number, on, clauses_mapped)
  end

  defp parse({:list, [{:symbol, "if", _} | clauses], line_number}) do
    clauses_mapped =
      clauses
      |> Enum.chunk_every(2)
      |> Enum.map(&if_clause/1)

    if_ast(line_number, clauses_mapped)
  end

  defp parse(
         {:list,
          [{:symbol, "defn", _}, {:symbol, name, _}, {_args_type, _, _} = args, body_forms],
          line_number}
       ) do
    parse(
      {:list,
       [
         {:symbol, "defn", line_number},
         {:symbol, name, line_number},
         {:list, [args, body_forms], line_number}
       ], line_number}
    )
  end

  defp parse(
         {:list,
          [{:symbol, "defn", _}, {:symbol, name, _}, {:list, [{_, args, _} | _] = clauses, _}],
          line_number}
       ) do
    clauses_mapped =
      clauses
      |> Enum.chunk_every(2)
      |> Enum.map(&clause/1)

    function(line_number, name, length(args), clauses_mapped)
  end

  defp parse({:list, [{:symbol, "module", _}, {:symbol, name, _}], line_number}) do
    {:attribute, line_number, :module, String.to_atom(name)}
  end

  defp parse({:list, [{:symbol, "compile", _} | names], line_number}) do
    {:attribute, line_number, :compile,
     List.to_tuple(Enum.map(names, fn {:atom, name, _} -> name end))}
  end

  defp parse({:list, [{:symbol, "=", _}, left, right], line_number}) do
    {:match, line_number, parse(left), parse(right)}
  end

  defp parse({:list, [{:symbol, "export", _}, {:list, funs, _}], line_number}) do
    {:attribute, line_number, :export,
     Enum.map(funs, fn {:vector, [{:symbol, name, _}, {:integer, arity, _}], _} ->
       {String.to_atom(name), arity}
     end)}
  end

  defp parse({:list, [{:symbol, "lambda", _}, args, body], line_number}) do
    {:fun, line_number, {:clauses, [clause([args, body])]}}
  end

  defp parse({:list, [{:symbol, "binc", _} | binaries], line_number}) do
    {:bin, line_number,
     Enum.map(
       binaries,
       fn b ->
         case b do
           {:binary, [b], _} ->
             {:bin_element, line_number, parse(b), :default, [:binary]}

           _ ->
             {:bin_element, line_number, parse(b), :default, [:binary]}
         end
       end
     )}
  end

  defp parse({:list, [{:symbol, name, line_number}, left, right], _})
       when name in @operations do
    {:op, line_number, String.to_atom(name), parse(left), parse(right)}
  end

  defp parse({:list, [{:symbol, name, line_number} | args], _}) do
    args_parsed = args |> Enum.map(&parse/1)
    {:call, line_number, {:atom, line_number, String.to_atom(name)}, args_parsed}
  end

  defp parse({:list, [{:varcall, name, line_number} | args], _}) do
    {_, _, name_parsed} = parse({:var, name, line_number})
    args_parsed = args |> Enum.map(&parse/1)
    {:call, line_number, {:atom, line_number, name_parsed}, args_parsed}
  end

  defp parse({:list, [{:tail, tail}], _line_number}), do: parse(tail)

  defp parse({:list, [head | tail], line_number}) do
    {:cons, line_number, parse(head), parse({:list, tail, line_number})}
  end

  defp parse({:list, [], line_number}), do: {nil, line_number}

  defp parse({:vector, ast, line_number}) do
    ast_parsed =
      ast
      |> Enum.map(&parse/1)

    {:tuple, line_number, ast_parsed}
  end

  # defp parse({:atom, pid, line_number}),
  #   do: {:atom, line_number, parse(Collie.Atom.deref({:atom, pid}))}

  defp parse({:hashmap, ast, line_number}) when is_map(ast) do
    ast_parsed =
      ast
      |> Map.to_list()
      |> Enum.map(fn {key, value} ->
        {:map_field_assoc, line_number, parse(key), parse(value)}
      end)

    {:map, line_number, ast_parsed}
  end

  defp parse({:binary, [content], line_number}) do
    {:bin, line_number, [{:bin_element, line_number, parse(content), :default, :default}]}
  end

  defp parse({:var, ast, line_number}) do
    ast_str = Atom.to_string(ast)

    name =
      cond do
        Regex.match?(~r/[A-Z].*/, ast_str) -> :"#{ast_str}_"
        Regex.match?(~r/[a-z].*/, ast_str) -> :"#{String.capitalize(ast_str)}"
        true -> :"#{ast_str}"
      end

    {:var, line_number, name}
  end

  defp parse({type, ast, line_number}) when type in [:float, :integer, :atom],
    do: {type, line_number, ast}

  defp parse({:string, ast, line_number}), do: {:string, line_number, String.to_charlist(ast)}

  defp parse({:symbol, name, _line_number}),
    do: raise("If you want to call a function: (#{name} <arg1, arg2, ..., argN>)")

  defp function(line_number, name, arity, clauses) do
    {:function, line_number, String.to_atom(name), arity, clauses}
  end

  defp if_clause([{_, _, line_number} = condition, body]) do
    {:clause, line_number, [], [parse(condition)], [parse(body)]}
  end

  defp case_clause({_, [pattern, body], line_number}) do
    {:clause, line_number, [parse(pattern)], [], [parse(body)]}
  end

  defp clause([{args_type, args, line_number}, {_, body_forms, _}])
       when args_type in [:list, :vector] do
    {:clause, line_number, Enum.map(args, &parse/1), [], Enum.map(body_forms, &parse/1)}
  end

  defp case_ast(line_number, on, clauses) do
    {:case, line_number, parse(on), clauses}
  end

  defp if_ast(line_number, clauses) do
    {:if, line_number, clauses}
  end
end
