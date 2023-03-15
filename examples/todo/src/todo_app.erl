-module(todo_app).

-export([start/2]).

start(_, _) ->
    db_utils:register_redis(),
    Dispatch = cowboy_router:compile([{'_',
                                       [{"/todo", todo_handler, #{}},
                                        {"/todo/:id", todos_handler, #{}}]}]),
    cowboy:start_clear(todo_listener,
                       [{port, 8080}],
                       #{env => #{dispatch => Dispatch}}),
    {ok, self()}.