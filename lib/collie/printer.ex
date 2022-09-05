defmodule Collie.Printer do
  def pr_str(ast, print_readably \\ true)

  def pr_str({:list, ast, _}, print_readable), do: pr_seq(ast, "(", ")", print_readable)

  def pr_str({:function, ast, _}, _) when is_function(ast), do: "#<function>"

  def pr_str({:symbol, name, _}, _), do: name

  def pr_str({:vector, ast, _}, print_readable), do: pr_seq(ast, "[", "]", print_readable)

  def pr_str({:atom, pid, _}, print_readable),
    do: "(atom #{pr_str(Collie.Atom.deref({:atom, pid}), print_readable)})"

  def pr_str({:hashmap, ast, _}, print_readable) when is_map(ast) do
    ast
    |> Map.to_list()
    |> Enum.map(&Tuple.to_list/1)
    |> List.foldr([], &append(&1, &2))
    |> pr_seq("{", "}", print_readable)
  end

  def pr_str({type, ast, _}, _) when type in [:float, :integer, :boolean], do: "#{ast}"

  def pr_str({:nil_type, nil, _}, _), do: "nil"

  def pr_str({:atom, ast, _}, _), do: ":#{ast}"

  def pr_str({:string, ast, _}, true), do: inspect(ast)

  def pr_str({:string, ast, _}, false), do: ast

  defp pr_seq(ast, start_sep, end_sep, print_readable) do
    joined =
      ast
      |> Enum.map(&pr_str(&1, print_readable))
      |> Enum.join(" ")

    "#{start_sep}#{joined}#{end_sep}"
  end

  defp append(first, second) when is_list(first) and is_list(second) do
    first
    |> Enum.reverse()
    |> Enum.reduce(second, &[&1 | &2])
  end
end
