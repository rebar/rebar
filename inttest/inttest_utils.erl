%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
-module(inttest_utils).

-export([ rebar_setup/1
        , rebar_setup/2
        , rebar_setup/0
        ]).

rebar_setup({win32, nt}, Dir) ->
    [{copy, filename:join(Dir, "rebar.cmd"), "rebar.cmd"}];
rebar_setup({_, _}, _) -> [].

rebar_setup(Dir) ->
    [{copy,
      filename:join(Dir, "rebar"), "rebar"}] ++ rebar_setup(os:type(), Dir).

rebar_setup() ->
    rebar_setup("../..").
