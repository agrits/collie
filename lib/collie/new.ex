defmodule Collie.New do
  @moduledoc """
  Responsible for creating new collie applications
  """

  @doc """
  Create new collie app
  """
  @spec create(String.t()) :: :ok | {:error, any()}
  def create(name) do
    with :ok <- rebar_new_app(name),
         :ok <- clean_lib(name),
         :ok <- touch_file(name) do
      write_initial_content(name)
    end
  end

  defp write_initial_content(name) do
    with {:ok, f} <- File.open("#{name}/src/#{name}_app.cll", [:write]),
         :ok <- IO.write(f, hello_content(name)) do
      File.close(f)
    end
  end

  defp touch_file(name) do
    case System.cmd("touch", ["#{name}/src/#{name}_app.cll"]) do
      {_, 0} ->
        :ok

      {message, eror_code} ->
        {:error, {eror_code, message}}
    end
  end

  defp clean_lib(name) do
    case System.cmd("rm", ["#{name}/src/#{name}_app.erl", "#{name}/src/#{name}_sup.erl"]) do
      {_, 0} ->
        :ok

      {message, eror_code} ->
        {:error, {eror_code, message}}
    end
  end

  defp rebar_new_app(name) do
    case System.cmd("rebar3", ["new", "app", name]) do
      {_, 0} ->
        :ok

      {message, eror_code} ->
        {:error, {eror_code, message}}
    end
  end

  defp hello_content(name) do
    """
    (module #{name}_app)
    (export ([start 0]))

    (defn start () ((io:fwrite("~p", ["Hello, world!"]))))
    """
  end
end
