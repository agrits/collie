defmodule Collie.Writer do
  @moduledoc """
  Responsible for writing Erlang result code to files.
  """

  @type filename :: String.t()

  @doc """
  Write code to file
  """
  @spec write(content :: binary(), output_filename :: filename()) ::
          {:ok, filename()} | {:error, File.posix() | :badarg | :terminated}
  def write(content, output_filename) do
    with {:ok, f} <- File.open(output_filename <> ".erl", [:write]) do
      IO.write(f, content)
      File.close(f)
      {:ok, output_filename <> ".erl"}
    end
  end
end
