defmodule Collie.Compiler do
  @moduledoc """
  Responsible for compiling Collie source code to BEAM code.
  """
  alias Collie.{Bootstrap, Reader, Parser, Transpiler, Writer, Lexer}

  @typedoc """
  Name of input file, e.g. "input.cll"
  """
  @type input_filename :: String.t()

  @typedoc """
  Name of output file, without extension, e.g. "output"
  """
  @type output_filename :: String.t()

  @doc """
  Compiles Collie source code and returns output file name.

  ## Examples
  iex> Collie.Compiler.compile("input.cll")
  {:ok, "output.beam"}
  """
  @spec compile(input_filename :: input_filename(), output_filename :: output_filename() | nil) ::
          {:ok, output_filename_with_extension :: String.t()} | {:error, any()}
  def compile(input_filename, output_filename \\ nil)

  def compile(input_filename, nil) do
    output_filename = input_filename |> String.split(".") |> Enum.drop(-1) |> Enum.join(".")
    compile(input_filename, output_filename)
  end

  def compile(input_filename, output_filename) do
    Bootstrap.elixir_libs()

    with {:ok, content} <- Reader.read_file(input_filename),
         {:ok, forms} <- Lexer.read_str(content),
         {:ok, erlang_ast} <- Parser.parse_forms(forms),
         {:ok, erlang_code} <- Transpiler.transpile(erlang_ast),
         {:ok, _} <- Writer.write(erlang_code, output_filename),
         :ok <- compile_transpiled() |> IO.inspect() do
      {:ok, output_filename <> ".beam"}
    end
  end

  defp compile_transpiled() do
    case System.cmd("rebar3", ["compile"]) do
      {_output, 0} ->
        :ok

      {message, eror_code} ->
        {:error, {eror_code, message}}
    end
  end
end
