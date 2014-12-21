%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
-module(deps_with_cover_spec_files_rt).

-compile(export_all).

files() ->
    [
     %% A application
     {create, "ebin/a.app", app(a, [a])},
     {copy, "a.rebar.config", "rebar.config"},
     {copy, "a.erl", "src/a.erl"},
     {copy, "a_SUITE.erl", "test/a_SUITE.erl"},
     {copy, "cover.spec", "repo/a/cover.spec"},
     {copy, "../../rebar", "rebar"},

     %% B application
     {create, "repo/b/ebin/b.app", app(b, [])},
     {copy, "b.rebar.config", "repo/b/rebar.config"},
     {copy, "cover.spec", "repo/b/cover.spec"},

     %% C application
     {create, "repo/c/ebin/c.app", app(c, [])},
     {copy, "cover.spec", "repo/c/cover.spec"}
    ].

apply_cmds([], _Params) ->
    ok;
apply_cmds([Cmd | Rest], Params) ->
    io:format("Running: ~s (~p)\n", [Cmd, Params]),
    {ok, _} = retest_sh:run(Cmd, Params),
    apply_cmds(Rest, Params).

run(_Dir) ->
    %% Initialize the b/c apps as git repos so that dependencies pull
    %% properly
    GitCmds = ["git init",
               "git add -A",
               "git config user.email 'deps_with_cover_spec_files@example.com'",
               "git config user.name 'deps_with_cover_spec_files'",
               "git commit -a -m 'Initial Commit'"],
    apply_cmds(GitCmds, [{dir, "repo/b"}]),
    apply_cmds(GitCmds, [{dir, "repo/c"}]),
    {ok, _} = retest_sh:run("./rebar get-deps", []),
    %% Remove the repos, so cover.spec files are not found when running the tests.
    apply_cmds(["rm -rf a b c"], [{dir, "repo"}]),
    %% This should fail if more than 1 cover.spec file is found.
    {ok, _} = retest:sh("./rebar compile ct -vv"),
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
