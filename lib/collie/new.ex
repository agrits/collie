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
         :ok <- write_config(name),
         :ok <- touch_file(name),
         :ok <- write_app_src(name) do
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
    case System.cmd("rm", [
           "#{name}/src/#{name}_app.erl",
           "#{name}/src/#{name}_sup.erl"
         ]) do
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

  defp write_config(name) do
    jsone_v = Application.get_env(:collie, :jsone, "1.7.0")
    cowboy_v = Application.get_env(:collie, :cowboy, "2.9.0")

    content = """
    {erl_opts, [debug_info]}.
    {deps, [{jsone, "#{jsone_v}"}, {cowboy, "#{cowboy_v}"}]}.

    {shell, [
      % {config, "config/sys.config"},
        {apps, [#{name}]}
    ]}.
    """

    File.write("#{name}/rebar.config", content)
  end

  defp write_app_src(name) do
    content = """
    {application, #{name},
    [{description, "An OTP application"},
      {vsn, "0.1.0"},
      {registered, []},
      {mod, {#{name}_app, []}},
      {applications,
      [kernel,
        stdlib,
        cowboy
      ]},
      {env,[]},
      {modules, []},

      {licenses, ["Apache-2.0"]},
      {links, []}
    ]}.
    """

    File.write("#{name}/src/#{name}.app.src", content)
  end

  defp hello_content(name) do
    """
    (module #{name}_app)
    (export ([start 0]))

    (defn start () ((io:fwrite("~p", ["Hello, world!"]))))
    """
  end
end
