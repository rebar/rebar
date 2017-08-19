-module(foo_SUITE).

-include_lib("common_test/include/ct.hrl").

-export([all/0, simple/1]).

all() -> [simple].

simple(Config) ->
    io:format("Test: ~p\n", [Config]),
    ok.
