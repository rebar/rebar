-module(foo_SUITE).

-include_lib("common_test/include/ct.hrl").

-export([all/0, foo/1]).

all() -> [foo].

foo(Config) ->
    io:format("Test: ~p\n", [Config]).
