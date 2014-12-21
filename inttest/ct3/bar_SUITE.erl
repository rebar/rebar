-module(bar_SUITE).

-include_lib("common_test/include/ct.hrl").

-compile(export_all).

all() -> [foo].

foo(Config) ->
    bar:foo(1),
    io:format("Test: ~p\n", [Config]).
