defmodule Collie.ReaderTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Collie.Reader

  describe "read_file/1" do
    setup do
      File.mkdir_p!(tmp_path())
      dest = "#{tmp_path()}/file.txt"
      File.write!(dest, "hello")
      on_exit(fn -> File.rm_rf(tmp_path()) end)
      {:ok, dest: dest}
    end

    test "reads file contents", %{dest: dest} do
      assert {:ok, "hello"} == Reader.read_file(dest)
    end
  end

  describe "read_line/0" do
    test "reads user input and trims it" do
      assert "hello" ==
               capture_io([input: "hello\n\n", capture_prompt: false], fn ->
                 IO.write(Reader.read_line())
               end)
    end
  end

  defp tmp_path() do
    Path.expand("../../tmp", __DIR__)
  end
end
