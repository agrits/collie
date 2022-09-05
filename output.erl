-module(output).

-export([start/0]).

start() -> 
	F = (fun () -> 3 end),
	F().