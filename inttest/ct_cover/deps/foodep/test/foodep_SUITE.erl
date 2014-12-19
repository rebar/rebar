-module(foodep_SUITE).

-compile(export_all).

-include_lib("ct.hrl").

all() ->
    [foodep_test].

foodep_test(Config) ->
    true =:= foodep:foodep(),
    ok.
