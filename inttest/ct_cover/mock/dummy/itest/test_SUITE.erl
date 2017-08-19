-module(test_SUITE).

-export([all/0, simple_test/1, app_config_file_test/1]).

-include_lib("ct.hrl").

all() ->
    [simple_test,
     app_config_file_test].

simple_test(Config) ->
    io:format("Test: ~p\n", [Config]).

app_config_file_test(_Config) ->
    application:start(dummy),
    {ok, bar} = application:get_env(dummy, foo),
    application:stop(dummy).
