-module(shareddep_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    %% Read some key from included configuration (sys -> extra config)
    case application:get_env(shareddep, key) of
        {ok, Value} -> io:format(user, "Found configuration in env: ~p", [Value]);
        _ -> throw("Could not read configuration from env!")
    end,
    %% Modify environment by adding another key/value.
    %% Since the eunit suite is ran twice, in the test we assert it is cleaned
    %% up on each consecutive test run.
    application:set_env(shareddep, otherkey, "modified env state"),
    shareddep_sup:start_link().

stop(_State) ->
    ok.
