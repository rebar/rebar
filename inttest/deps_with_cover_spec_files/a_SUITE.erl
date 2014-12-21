-module(a_SUITE).

-compile(export_all).

all() -> [foo].

foo(Config) ->
    io:format("Test: ~p\n", [Config]).
