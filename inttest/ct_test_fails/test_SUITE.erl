-module(test_SUITE).

-export([all/0, simple_test/1]).

all() ->
    [simple_test].

simple_test(Config) ->
    io:format("Test: ~p\n", [Config]),
    ok = not_ok.
