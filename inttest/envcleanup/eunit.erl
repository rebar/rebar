-module({{module}}).
-include_lib("eunit/include/eunit.hrl").

%% This test is run by both app_a and app_b
setup_test() ->
    ?assertEqual(undefined, application:get_env(shareddep, otherkey)),

    %% Start the shared dependency which modifies environment
    ?assertEqual(ok, application:start(shareddep)),

    ?assertEqual({ok, "modified env state"},
                 application:get_env(shareddep, otherkey)).
