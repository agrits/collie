defmodule Collie.Parser do
  def parse_forms(forms) when is_list(forms) do
    forms |> Enum.map(&parse/1)
  end

  def parse({:list, [{:erlang_remote, lib, f, line_number} | args], _}) do
    args_parsed = args |> Enum.map(&parse/1)

    {:call, line_number,
     {:remote, line_number, {:atom, line_number, String.to_atom(lib)},
      {:atom, line_number, String.to_atom(f)}}, args_parsed}
  end

  def parse(
        {:list, [{:symbol, "defn", _}, {:symbol, name, _}, {_args_type, _, _} = args, body],
         line_number}
      ) do
    parse(
      {:list,
       [
         {:symbol, "defn", line_number},
         {:symbol, name, line_number},
         {:list, [args, body], line_number}
       ], line_number}
    )
  end

  def parse(
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

  def parse({:list, [{:symbol, "module", _}, {:symbol, name, _}], line_number}) do
    {:attribute, line_number, :module, String.to_atom(name)}
  end

  def parse({:list, [{:symbol, "=", _}, left, right], line_number}) do
    {:match, line_number, parse(left), parse(right)}
  end

  def parse({:list, [{:symbol, "export", _}, {:list, funs, _}], line_number}) do
    {:attribute, line_number, :export,
     Enum.map(funs, fn {:vector, [{:symbol, name, _}, {:integer, arity, _}], _} ->
       {String.to_atom(name), arity}
     end)}
  end

  def parse({:list, [{:symbol, "lambda", _}, {:list, args, _}, body], line_number}) do
    {:fun, line_number,
     {:clauses, [{:clause, line_number, Enum.map(args, &parse/1), [], [parse(body)]}]}}
  end

  def parse({:list, [{:symbol, name, line_number}, left, right], _})
      when name in ["+", "-", "*", "/"] do
    {:op, line_number, String.to_atom(name), parse(left), parse(right)}
  end

  def parse({:list, [{:symbol, name, line_number} | args], _}) do
    args_parsed = args |> Enum.map(&parse/1)
    {:call, line_number, {:atom, line_number, String.to_atom(name)}, args_parsed}
  end

  def parse({:list, [{:var, _, line_number} = v | args], _}) do
    args_parsed = args |> Enum.map(&parse/1)
    {:call, line_number, parse(v), args_parsed}
  end

  def parse({:list, [head | tail], line_number}) do
    {:cons, line_number, parse(head), parse({:list, tail, line_number})}
  end

  def parse({:list, [], line_number}), do: {nil, line_number}

  def parse({:vector, ast, line_number}) do
    ast_parsed =
      ast
      |> Enum.map(&parse/1)

    {:tuple, line_number, ast_parsed}
  end

  def parse({:atom, pid, line_number}),
    do: {:atom, line_number, parse(Collie.Atom.deref({:atom, pid}))}

  def parse({:hashmap, ast, line_number}) when is_map(ast) do
    ast_parsed =
      ast
      |> Map.to_list()
      |> Enum.map(fn {key, value} ->
        {:map_field_assoc, line_number, parse(key), parse(value)}
      end)

    {:map, line_number, ast_parsed}
  end

  def parse({type, ast, line_number}) when type in [:var],
    do: {:var, line_number, :"_#{ast}"}

  def parse({type, ast, line_number}) when type in [:float, :integer, :boolean, :atom],
    do: {type, line_number, ast}

  def parse({:string, ast, line_number}), do: {:string, line_number, String.to_charlist(ast)}

  def parse({:symbol, name, line_number}),
    do: raise("If you want to call a function: (#{name} <arg1, arg2, ..., argN>)")

  defp function(line_number, name, arity, clauses) do
    {:function, line_number, String.to_atom(name), arity, clauses}
  end

  defp clause([{args_type, args, line_number}, body]) when args_type in [:list, :vector] do
    {:clause, line_number, Enum.map(args, &parse/1), [], [parse(body)]}
  end
end
