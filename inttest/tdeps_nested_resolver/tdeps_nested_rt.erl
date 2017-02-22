%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et

-module(tdeps_nested_rt).

-export([run/1,
         files/0]).

files() ->
    [
     %% ROOT application
     {copy, "root/apps", "."},
     {copy, "root/rebar.config", "rebar.config"},
     {copy, "../../rebar", "rebar"},
     {copy, "repo", "repo"}
    ].

apply_cmds([], _Params) ->
    ok;
apply_cmds([Cmd | Rest], Params) ->
    io:format("Running: ~s (~p)\n", [Cmd, Params]),
    {ok, _} = retest_sh:run(Cmd, Params),
    apply_cmds(Rest, Params).

run(_Dir) ->
    GitCmds = ["git init",
               "git add -A",
               "git config user.email 'tdeps@example.com'",
               "git config user.name 'tdeps'",
               "git commit -a -m 'Initial Commit'"],
    Git01Tag = ["git tag -am 0.1 0.1"],
    ok = apply_cmds(GitCmds++Git01Tag, [{dir, "repo/b"}]),
    ok = apply_cmds(GitCmds++Git01Tag, [{dir, "repo/a"}]),
    {ok, _} = retest_sh:run("./rebar -v get-deps", []),
    {ok, _} = retest_sh:run("./rebar -v update-deps", []),
    ok.
