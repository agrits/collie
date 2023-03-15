-module(todo_handler).

-export([init/2]).

init(Req, _state) ->
    handle_req(maps:get(method, Req), Req).

handle_req(<<"GET">>, Req) -> get_todos(Req);
handle_req(<<"POST">>, Req) -> add_todo(Req);
handle_req(_, Req) -> cowboy_req:reply(404, Req).

reply_json(Req, Body, Status) ->
    cowboy_req:reply(Status,
                     #{<<"content-type">> => <<"application/json">>},
                     jsone:encode(Body),
                     Req).

from_body(Req, Key) ->
    {ok, Body, _} = cowboy_req:read_urlencoded_body(Req),
    lists:keyfind(Key, 1, Body).

from_url(Req, Key) -> cowboy_req:binding(Key, Req).

add_todo(Req) ->
    {_, Item} = from_body(Req, <<"item">>),
    C = db_utils:db_connection(),
    {ok, L} = eredis:q(C, ["RPUSH", "items", Item]),
    {ok, reply_json(Req, #{count => L}, #{index => 201})}.

get_todos(Req) ->
    C = db_utils:db_connection(),
    {ok, Items} = eredis:q(C,
                           ["LRANGE", "items", "0", "-1"]),
    {ok, reply_json(Req, #{todos => Items}, 200)}.