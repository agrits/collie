defmodule Collie.CompilerTest do
  use ExUnit.Case, async: false

  require IEx

  alias Collie.Compiler

  describe "compile/2" do
    setup do
      File.mkdir_p!(tmp_path())

      dest = "#{tmp_path()}/hello.cll"

      on_exit(fn -> File.rm_rf(tmp_path()) end)

      {:ok, dest: dest}
    end

    test "transpiles and compiles file", %{dest: dest} do
      code = """
      (module hello)
      (export ([start 0]))

      (defn start () ((io:fwrite "Hello, world!\\n")))
      """

      File.write!(dest, code)

      assert {:ok, beam_filename} = Compiler.compile(dest)
      assert hd(String.split(dest, ".")) <> ".beam" == beam_filename
    end
  end

  defp tmp_path() do
    Path.expand("../../src/lib/tmp", __DIR__)
  end
end
