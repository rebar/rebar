-module(foo_SUITE).

-compile(export_all).

-include_lib("ct.hrl").

all() ->
    [foo_test].

foo_test(Config) ->
    true =:= foo:foo(),
    ok.
