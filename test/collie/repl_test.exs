defmodule Collie.ReplTest do
  use ExUnit.Case, async: false
  @moduletag :skip_ci
  import ExUnit.CaptureIO

  test "shows prompt" do
    assert "user> \n" == get_commands_output([], false)
  end

  test "gets user input, evaluates it and prints" do
    assert "3" == get_commands_output(["(+ 2 1)"])
  end

  test "evaluates continuous commands" do
    assert "3.0\n4" ==
             get_commands_output([
               "(/ 6 2)",
               "(* 2 2)"
             ])
  end

  test "handles bindings" do
    assert "1\n4" ==
             get_commands_output([
               "(= $a (- 3 2))",
               "(+ $a 3)"
             ])
  end

  test "shows errors" do
    assert "%ArithmeticError{message: \"bad argument in arithmetic expression\"}" ==
             get_commands_output([
               "(/ 1 0)"
             ])

    assert "%RuntimeError{message: \"If you want to call a function: (a <arg1, arg2, ..., argN>)\"}" ==
             get_commands_output([
               "a"
             ])

    assert "%ErlangError{original: {:unbound_var, :\".a\"}}" ==
             get_commands_output([
               "$.a"
             ])
  end

  test "evaluates if" do
    assert ":success" == get_commands_output(["(if (== 1 1) :success)"])
    assert ":fail" == get_commands_output(["(if (== 1 2) :success true :fail)"])
  end

  test "evaluates case" do
    assert "1\n:first" == get_commands_output(["(= $a 1)", "(case $a (1 :first) (2 :second))"])
    assert "2\n:second" == get_commands_output(["(= $a 2)", "(case $a (1 :first) (2 :second))"])
  end

  defp get_commands_output(expressions, trim_prompt? \\ true) do
    output =
      capture_io(fn ->
        port = init_repl()

        for e <- expressions do
          send_and_receive_cmd(port, e)
        end
      end)

    if trim_prompt? do
      trim_prompt(output)
    else
      output
    end
  end

  defp init_repl() do
    port =
      Port.open({:spawn, "collie repl"}, [
        :stream,
        :binary,
        :exit_status,
        :hide,
        :use_stdio,
        :stderr_to_stdout
      ])

    receive do
      {_, {:data, msg}} -> IO.puts(msg)
    end

    port
  end

  defp send_and_receive_cmd(port, cmd) do
    Port.command(port, "#{cmd}\n")

    receive do
      {_, {:data, msg}} -> IO.puts(msg)
    end
  end

  defp trim_prompt(s), do: String.trim(String.replace(s, "user> \n", ""))
end
