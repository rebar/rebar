-module(non_recursive_cmds_rt).

-export([files/0,
         run/1]).

-include_lib("eunit/include/eunit.hrl").

-define(REBAR_NON_RECURSIVE_CMDS, "REBAR_NON_RECURSIVE_CMDS").

files() ->
    [
     {copy, "../../rebar", "rebar"},

     %% Base application
     {create, "ebin/foo_base.app", app(foo_base, [foo_base])},
     {template, "a.erl", "src/foo_base.erl",
      dict:from_list([{module, foo_base}])},
     {copy, "rebar.config", "rebar.config"},

     %% Dep application
     {create, "repo/foo_dep/ebin/foo_dep.app", app(foo_dep, [foo_dep])},
     {template, "a.erl", "repo/foo_dep/src/foo_dep.erl",
      dict:from_list([{module, foo_dep}])}
    ].

apply_cmds([], _Params) ->
    ok;
apply_cmds([Cmd | Rest], Params) ->
    io:format("Running: ~s (~p)\n", [Cmd, Params]),
    {ok, _} = retest_sh:run(Cmd, Params),
    apply_cmds(Rest, Params).

run(_Dir) ->
    %% Initialize foo_dep as a git repo so that it can be fetched properly
    GitCmds = ["git init",
               "git add -A",
               "git config user.email 'rebar@example.com'",
               "git config user.name 'rebar'",
               "git commit -a -m 'Initial Commit'"],
    ok = apply_cmds(GitCmds, [{dir, "repo/foo_dep"}]),

    DepBeam = "deps/foo_dep/ebin/foo_dep.beam",

    %% Override list of built-in recursive_cmds. Pass in one *-deps command
    %% to test that rebar_deps commands are not removed.
    true = os:putenv(?REBAR_NON_RECURSIVE_CMDS, "compile,get-deps"),

    {ok, _} = retest_sh:run("./rebar get-deps", []),
    {ok, _} = retest_sh:run("./rebar compile", []),

    %% Due to removing 'compile' from recursive_cmds none of the deps
    %% should be compiled
    ?assertEqual(false, filelib:is_regular(DepBeam)),

    {ok, _} = retest_sh:run("./rebar -r compile", []),
    %% After explicitly compiling recursively, all deps should be compiled.
    ?assertEqual(true, filelib:is_regular(DepBeam)),

    %% Clean just the base project
    {ok, _} = retest_sh:run("./rebar clean", []),
    ?assertEqual(true, filelib:is_regular(DepBeam)),

    %% Recursively clean (all) projects
    {ok, _} = retest_sh:run("./rebar -r clean", []),
    ?assertEqual(false, filelib:is_regular(DepBeam)),

    %% Set REBAR_NON_RECURSIVE_CMDS to something else and check again
    true = os:putenv(?REBAR_NON_RECURSIVE_CMDS, "foobar"),
    {ok, _} = retest_sh:run("./rebar compile", []),
    ?assertEqual(true, filelib:is_regular(DepBeam)),

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
