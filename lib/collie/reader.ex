defmodule Collie.Reader do
  @moduledoc """
  Used for reading source code
  """

  @doc """
  Read source file code.

  ## Examples
  iex> read_file("input.cll")
  {:ok, "(+ 2 2)"}
  """
  @spec read_file(filename :: String.t()) :: {:error, File.posix()} | {:ok, content :: binary()}
  def read_file(filename) do
    File.read(filename)
  end

  @spec read_line() :: binary()
  def read_line() do
    IO.gets("user> ")
    |> String.trim("\n")
  end
end
