-module(test_SUITE).

-compile(export_all).

-include_lib("ct.hrl").

all() ->
    [simple_test,
     app_config_file_test,
     check_path].

simple_test(Config) ->
    io:format("Test: ~p\n", [Config]).

app_config_file_test(_Config) ->
    application:start(a1),
    {ok, bar} = application:get_env(a1, foo),
    application:stop(a1).

%% check if -erl_args in ct_extra_params of rebar.config is working
%% if it is, path before -erl_args is converted to absolute
%% and path after -erl_args is not
check_path(_Config) ->
    Path = code:get_path(),
    false = lists:member("converted", Path),
    true = lists:member("unconverted", Path).
