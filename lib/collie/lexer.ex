defmodule Collie.Lexer do
  @moduledoc """
  Used for splitting code into tokens
  """
  alias Collie.Types
  @pattern ~r/[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"?|;.*|[^\s\[\]{}('"`,;)]*)/

  @doc """
  Takes in Collie code and turns it into internal AST representation.
  """
  @spec read_str(code :: binary()) :: {:ok, forms :: list()}
  def read_str(code) do
    forms =
      code
      |> String.split("\n")
      |> read_lines()

    {:ok, forms}
  end

  defp read_lines(lines) do
    lines
    |> Enum.with_index()
    |> Enum.reverse()
    |> Enum.reduce([], fn {s, line_number}, acc -> tokenize(s, line_number) ++ acc end)
    |> case do
      [] -> nil
      tokens -> read_forms(tokens)
    end
  end

  defp tokenize(s, line_number) do
    @pattern
    |> Regex.scan(s, capture: :all_but_first)
    |> List.flatten()
    |> List.delete_at(-1)
    |> Enum.reject(fn token -> String.starts_with?(token, ";") or token == "" end)
    |> Enum.map(fn token -> {token, line_number} end)
  end

  defp read_forms(tokens, acc \\ []) do
    case read_form(tokens) do
      {form, [_ | _] = tail} -> read_forms(tail, [form | acc])
      {form, []} -> Enum.reverse([form | acc])
    end
  end

  defp read_form([{token, line_number} = next | rest], acc \\ []) do
    case token do
      "(" -> read_list(rest, line_number, acc)
      "<<" -> read_binary(rest, line_number, acc)
      "{" -> read_hashmap(rest, line_number, acc)
      "[" -> read_vec(rest, line_number, acc)
      _ -> {read_atom(next), rest}
    end
  end

  defp read_list(tokens, line_number, acc) do
    {ast, tail} = read_seq(tokens, acc, ")")
    {Types.list(ast, line_number), tail}
  end

  defp read_binary(tokens, line_number, acc) do
    {ast, tail} = read_seq(tokens, acc, ">>")
    {Types.binary(ast, line_number), tail}
  end

  defp read_vec(tokens, line_number, acc) do
    {ast, tail} = read_seq(tokens, acc, "]")
    {Types.vector(ast, line_number), tail}
  end

  defp read_hashmap(tokens, line_number, acc) do
    {token, tail} = read_seq(tokens, acc, "}")

    m =
      token
      |> Enum.chunk_every(2)
      |> Enum.map(&List.to_tuple/1)
      |> Enum.into(%{})

    {Types.hashmap(m, line_number), tail}
  end

  defp read_seq(tokens, acc, end_sep)

  defp read_seq([], _, _) do
    raise("Unexpected EOF.")
  end

  defp read_seq([{token, _} | rest] = tokens, acc, end_sep) do
    case token do
      t when t == end_sep ->
        {Enum.reverse(acc), rest}

      t when t == "|" ->
        {new_token, tail} = read_form(rest)
        {Enum.reverse([{:tail, new_token} | acc]), tl(tail)}

      _ ->
        {new_token, tail} = read_form(tokens)
        read_seq(tail, [new_token | acc], end_sep)
    end
  end

  defp read_atom({"true", line_number}), do: Types.atom(true, line_number)
  defp read_atom({"false", line_number}), do: Types.atom(false, line_number)
  defp read_atom({"nil", line_number}), do: Types.atom(nil, line_number)
  defp read_atom({":" <> rest, line_number}), do: Types.atom(String.to_atom(rest), line_number)

  defp read_atom({".$" <> rest, line_number}),
    do: Types.varcall(String.to_atom(rest), line_number)

  defp read_atom({"$" <> rest, line_number}), do: Types.var(String.to_atom(rest), line_number)

  defp read_atom({token, line_number}) do
    cond do
      String.match?(token, ~r/^"(?:\\.|[^\\"])*"$/) ->
        token
        |> Code.string_to_quoted()
        |> elem(1)
        |> Types.string(line_number)

      String.starts_with?(token, "\"") ->
        raise("expected '\"', got EOF")

      true ->
        case Float.parse(token) do
          {f, ""} ->
            if round(f) == f,
              do: Types.integer(round(f), line_number),
              else: Types.float(f, line_number)

          _ ->
            case String.split(token, ":") do
              [lib, f] -> Types.erlang_remote(lib, f, line_number)
              _ -> Types.symbol(token, line_number)
            end
        end
    end
  end
end
