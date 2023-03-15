defmodule Collie.CLI do
  @moduledoc """
  Module responsible for workings of escript version of Collie
  """

  alias Collie.{Compiler, New, Repl}

  @spec main(any) :: list({:ok, String.t()} | {:error, any()}) | no_return()
  def main([action | args]) do
    case action do
      "compile" -> Enum.map(args, &Compiler.compile/1)
      "rebar.run" -> exec(System.find_executable("rebar3"), ["shell", "--apps", hd(args)])
      "rebar.get" -> System.cmd("curl", ["-O", "https://s3.amazonaws.com/rebar3/rebar3"])
      "new" -> New.create(hd(args))
      "repl" -> Repl.loop()
    end
  end

  def main([]) do
    IO.puts("""
    Available commands:
    - compile
    - rebar.run
    - rebar.get
    - new
    - repl
    """)
  end

  defp exec(exe, args) do
    port =
      Port.open(
        {:spawn_executable, exe},
        [{:args, args}, :stream, :binary, :exit_status, :hide, :use_stdio, :stderr_to_stdout]
      )

    handle_output(port)
  end

  defp handle_output(port) do
    receive do
      {^port, {:data, data}} ->
        IO.puts(data)
        handle_output(port)

      {^port, {:exit_status, status}} ->
        status
    end
  end
end
