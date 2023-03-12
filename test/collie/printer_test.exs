defmodule Collie.PrinterTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Collie.Printer

  test "prints val" do
    assert "{:atom, :a, 2}\n" == capture_io(fn -> Printer.print_val({:atom, :a, 2}) end)
  end
end
