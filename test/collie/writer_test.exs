defmodule Collie.WriterTest do
  use ExUnit.Case

  setup do
    File.mkdir_p!(tmp_path())
    on_exit(fn -> File.rm_rf(tmp_path()) end)
    {:ok, dest: tmp_path()}
  end

  test "writes to file", %{dest: dest} do
    file_dest = "#{dest}/file"
    assert {:ok, "#{file_dest}.erl"} == Collie.Writer.write("hello", file_dest)
    assert "hello" == File.read!("#{file_dest}.erl")
  end

  defp tmp_path() do
    Path.expand("../../tmp", __DIR__)
  end
end
