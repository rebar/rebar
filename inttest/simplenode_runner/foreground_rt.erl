%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
-module(foreground_rt).
-compile(export_all).

%% Tests to start a release in foreground

files() ->
    [{copy, "../../rebar", "rebar"},
     {copy, join_dir("v1"), "v1"},
     {copy,
      "../../priv/templates/simplenode.runner",
      "v1/rel/files/test_node"
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
    ok = system_in_foreground().

system_in_foreground() ->
    %%
    RefConsole = async_run_cmd("console"),
    {ok,[{0,_}]} = retest:sh_expect(RefConsole, "Eshell"),
    ok = ping_with_retries(5, 1000),
    {ok,[_,"ok"]} = run_cmd("stop"),
    %%
    RefCleanConsole = async_run_cmd("console_clean"),
    {ok,[{0,_}]} = retest:sh_expect(RefCleanConsole, "Eshell"),
    ok = ping_with_retries(5, 1000),
    {ok,[_,"ok"]} = run_cmd("stop"),
    %%
    RefConsoleBoot = async_run_cmd("console_boot", ["start_clean"]),
    {ok,[{0,_}]} = retest:sh_expect(RefConsoleBoot, "Eshell"),
    ok = ping_with_retries(5, 1000),
    {ok,[_,"ok"]} = run_cmd("stop"),
    %%
    RefForeground = async_run_cmd("foreground"),
    %% foreground does not output a shell, pinging it is enough
    {ok,[{0,_}]} = retest:sh_expect(RefForeground, "Exec:"),
    ok = ping_with_retries(5, 1000),
    {ok,[_,"ok"]} = run_cmd("stop"),
    %%
    %% XXX Hack around timeout in retest_sh:stop/1: as we shut down all
    %% processes already, waiting for the ports to send something will time out.
    %% NOTE: we cannot keep the processes running in order to let
    %% retest_sh:stop/1 clean them up, as only one node is allowed to run at a
    %% time.
    erlang:erase(RefConsole),
    erlang:erase(RefCleanConsole),
    erlang:erase(RefConsoleBoot),
    erlang:erase(RefForeground),
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
