%%% @doc Environment cleanup handling test
%%%
%%% This test checks if environment is cleaned up properly after a test.

-module(env_test).
-compile(export_all).

-include_lib("eunit/include/eunit.hrl").

files() ->
    [
     {copy, "../../rebar", "rebar"},
     {copy, "rebar.config", "rebar.config"},

     %% Main and included configuration file.
     {copy, "sys.config", "config/sys.config"},
     {copy, "extra.config", "priv/extra.config"},

     %% Dummy applications with a shared dependency.
     {create, "deps/app_a/ebin/app_a.app", app(app_a, [])},
     {copy, "deps.rebar.config", "deps/app_a/rebar.config"},
     {create, "deps/app_b/ebin/app_b.app", app(app_b, [])},
     {copy, "deps.rebar.config", "deps/app_b/rebar.config"},

     %% Tests that start shared dependency app.
     {template, "eunit.erl", "deps/app_a/test/app_a_eunit.erl",
      dict:from_list([{module, "app_a_eunit"}])},
     {template, "eunit.erl", "deps/app_b/test/app_b_eunit.erl",
      dict:from_list([{module, "app_b_eunit"}])},

     %% Files for shared dependency dummy app.
     {copy, "shareddep_app.erl", "deps/shareddep/src/shareddep_app.erl"},
     {copy, "shareddep.app.src", "deps/shareddep/src/shareddep.app.src"},
     {copy, "shareddep_sup.erl", "deps/shareddep/src/shareddep_sup.erl"}
    ].

run(_Dir) ->
    %% Compile shareddep
    ?assertMatch({ok, _}, retest_sh:run("./rebar compile", [])),
    %% Run tests with configuration
    Env = [{"ERL_FLAGS", "-config config/sys"}],
    ?assertMatch({ok, _}, retest_sh:run("./rebar eunit", [{env, Env}])),
    ok.

%%
%% Generate the contents of a simple .app file
%%
app(Name, Modules) ->
    App = {application, Name,
           [{description, atom_to_list(Name)},
            {vsn, "1"},
            {modules, Modules},
            {registered, []},
            {applications, [kernel, stdlib]}]},
    io_lib:format("~p.\n", [App]).
