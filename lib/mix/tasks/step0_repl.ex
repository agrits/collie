defmodule Mix.Tasks.Step0Repl do
  def run(_), do: Collie.Steps.Step0Repl.loop()
end
