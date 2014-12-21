-module(bar).

-compile(export_all).


foo(Int) ->
    io:format("fooooo ~p ~n", [Int]).
