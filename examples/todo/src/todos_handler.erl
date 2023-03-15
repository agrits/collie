-module(todos_handler).

-export([init/2]).

init(Req, _state) ->
    handle_req(maps:get(method, Req), Req).

handle_req(<<"DELETE">>, Req) -> delete_todo(Req);
handle_req(<<"GET">>, Req) -> get_todo(Req);
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

get_todo(Req) ->
    Id = from_url(Req, id),
    C = db_utils:db_connection(),
    {ok, Item} = eredis:q(C, ["LINDEX", "items", Id]),
    {ok, reply_json(Req, #{todo => Item}, 200)}.

delete_todo(Req) ->
    C = db_utils:db_connection(),
    Id = from_url(Req, id),
    {ok, Item} = eredis:q(C, ["LINDEX", "items", Id]),
    {ok, Count} = eredis:q(C, ["LREM", "items", "1", Item]),
    {ok, reply_json(Req, #{count => Count}, 200)}.