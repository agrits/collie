defmodule Collie.Rest do
  @moduledoc """
  Responsible for bootstraping Collie with syntax dedicated for building REST apps
  """
  alias Collie.Lexer

  @allowed_methods ~w(GET HEAD POST DELETE PUT PATCH OPTIONS TRACE CONNECT DEFAULT)

  @spec handler(String.t(), map()) :: list
  def handler(name, method_handlers) do
    method_handlers_code =
      method_handlers
      |> Enum.map_join("\n", &method_handler_to_case/1)

    """
    (module #{name})

    (export
        ([init 2]))

    (defn init
    ($req $_state)
    (
        (handle_req
            (maps:get :method $req) $req)))

    (defn handle_req
      (
        #{method_handlers_code}
        #{if "DEFAULT" not in Map.keys(method_handlers), do: default()}
      )
    )

    (defn reply_json
    ($req $body $status)
    (
        (cowboy_req:reply $status {<<"content-type">> <<"application/json">>} (jsone:encode $body) $req)))

    (defn from_body ($req $key)
    (
      (= [:ok $body $_] (cowboy_req:read_urlencoded_body $req))
      (lists:keyfind $key 1 $body)
    ))

    (defn from_url ($req $key)
      (
        (cowboy_req:binding $key $req)
      )
    )
    """
    |> Lexer.read_str()
    |> elem(1)
  end

  @spec app(String.t(), pos_integer(), list(), any()) :: list()
  def app(name, port, routes, before_start) do
    routes_code =
      routes
      |> Enum.map_join("\n", fn {{:string, route, _}, {:atom, handler_module, _}} ->
        "[#{inspect(route)}, :#{handler_module}, {}]"
      end)

    before_start_code =
      before_start
      |> Enum.map_join(
        "\n",
        fn
          {:symbol, f, _} -> "(#{f})"
          {:erlang_remote, m, f, _} -> "(#{m}:#{f})"
        end
      )

    """
    (module #{name})

    (export
        ([start 2]))

    (defn start ($_ $_) (
            #{before_start_code}
            (= $dispatch (cowboy_router:compile ([:_, (
                #{routes_code}
                )])))
            (cowboy:start_clear  :todo_listener, ([:port #{port}]), {:env {:dispatch $dispatch}})
            [:ok (self)]
        ))
    """
    |> Lexer.read_str()
    |> elem(1)
  end

  defp default() do
    """
    ($_ $req)
        (
            (cowboy_req:reply 404 $req))
    """
  end

  defp method_handler_to_case({{:symbol, method, _}, {:symbol, handler_fun, _}})
       when method in @allowed_methods do
    """
    (<<"#{method}">> $req)
    (
        (#{handler_fun} $req)
    )
    """
  end

  defp method_handler_to_case(_), do: ""
end
