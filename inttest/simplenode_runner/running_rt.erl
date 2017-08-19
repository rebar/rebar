%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
-module(running_rt).
-compile(export_all).

%% Tests against a running release

files() ->
    [{copy, "../../rebar", "rebar"},
     {copy, join_dir("v1"), "v1"},
     {copy, join_dir("v2"), "v2"},
     {copy,
      "../../priv/templates/simplenode.runner",
      "v1/rel/files/test_node"
     },
     {copy,
      "../../priv/templates/simplenode.runner",
      "v2/rel/files/test_node"
     }
    ].

base_release_dir() ->
    {ok,[_,Vsn]} = retest:sh("erl -version"),
    {match,[ErtsVsn]} = re:run(Vsn, " ([^ ]*)$", [{capture, all_but_first, list}]),
    if ErtsVsn > "5.9.1" -> "otp_after_r15b01";
       true -> "otp_before_r15b01"
    end.

join_dir(Dir) ->
    filename:join([base_release_dir(), Dir]).

run(_Dir) ->
    os:cmd("epmd -daemon"),
    {ok,_} = retest:sh("../rebar compile", [{dir, "v1"}]),
    {ok,_} = retest:sh("../../rebar generate", [{dir, "v1/rel"}]),
    %% create upgrade package
    {ok,_} = retest:sh("../rebar compile", [{dir, "v2"}]),
    {ok,_} = retest:sh("../../rebar generate", [{dir, "v2/rel"}]),
    {ok,_} = retest:sh("../../rebar generate-appups "
                             "previous_release=../../v1/rel/test_node",
                         [{dir, "v2/rel"}]),
    {ok,_} = retest:sh("../../rebar generate-upgrade "
                             "previous_release=../../v1/rel/test_node",
                         [{dir, "v2/rel"}]),
    {ok,_} = retest:sh("cp test_node_2.tar.gz ../../v1/rel/test_node/releases/",
                       [{dir, "v2/rel"}]),
    ok = with_running_system().

with_running_system() ->
    %%
    {ok,[_]} = run_cmd("start"),
    timer:sleep(5000),
    %%
    ok = ping_with_retries(5, 1000),
    %%
    {ok, [_,"ok"]} = run_cmd("eval", ["ok."]),
    %%
    RefAttach = async_run_cmd("attach"),
    {ok,[{0,_}]} = retest:sh_expect(RefAttach, "Attaching to"),
    %%
    RefRemoteConsole = async_run_cmd("remote_console"),
    {ok,[{0,_}]} = retest:sh_expect(RefRemoteConsole, "pong"),
    {ok,[{0,_}]} = retest:sh_expect(RefRemoteConsole, "Eshell"),
    ok = ping_with_retries(5, 1000),
    %%
    {ok,[_,"pong",
         "Unpacked Release" ++ _,
         "Installed Release" ++ _
         |_]} = run_cmd("upgrade", ["test_node_2"]),
    ok = ping_with_retries(5, 1000),
    %%
    {ok,[_,_]} = run_cmd("getpid"),
    %%
    {ok,[_,"ok"]} = run_cmd("stop"),
    ok.

ping_with_retries(0, _Sleep) -> {error,node_not_reachable};
ping_with_retries(Retries, Sleep) ->
    case run_cmd("ping") of
        {ok,_} -> ok;
        _ ->
            timer:sleep(Sleep),
            ping_with_retries(Retries - 1, Sleep)
    end.

run_cmd(Cmd) -> run_cmd1(sync, Cmd).
run_cmd(Cmd, Args) -> run_cmd1(sync, Cmd, Args).

async_run_cmd(Cmd) -> run_cmd1(async, Cmd).
async_run_cmd(Cmd, Args) -> run_cmd1(async, Cmd, Args).

run_cmd1(Async, Cmd) ->
    run_cmd1(Async, Cmd, []).

run_cmd1(Async, Cmd, Args) ->
    Cmd1 = simplenode_runner(Cmd),
    Cmd2 = string:join([Cmd1|Args], " "),
    retest:sh(Cmd2, [async || Async =:= async]).

simplenode_runner(Args) ->
    simplenode_runner_abspath() ++ " " ++ Args.

simplenode_runner_abspath() ->
    filename:absname("v1/rel/test_node/bin/test_node").
