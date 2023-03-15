-module(db_utils).

-export([register_redis/0, db_connection/0]).

register_redis() ->
    {ok, C} = eredis:start_link("127.0.0.1", 6379),
    true = erlang:register(redis, C).

db_connection() -> erlang:whereis(redis).