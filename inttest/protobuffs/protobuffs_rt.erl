%% -*- mode: erlang;erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 ft=erlang et
-module(protobuffs_rt).
-export([files/0,
         run/1]).

-include_lib("eunit/include/eunit.hrl").

-define(MODULES,
        [foo,
         foo_app,
         foo_sup,
         test_pb,
         test3_pb1,
         test4_pb2,
         test5_pb2]).

-define(BEAM_FILES,
        ["foo.beam",
         "foo_app.beam",
         "foo_sup.beam",
         "test_pb.beam",
         "test3_pb1.beam",
         "test4_pb2.beam",
         "test5_pb2.beam"]).

files() ->
    [
     {copy, "../../rebar", "rebar"},
     {copy, "rebar.config", "rebar.config"},
     {copy, "include", "include"},
     {copy, "extra-include", "extra-include"},
     {copy, "src", "src"},
     {copy, "extra-src", "extra-src"},
     {copy, "proto", "proto"},
     {create, "ebin/foo.app", app(foo, ?MODULES)}
    ].

run(_Dir) ->
    ?assertMatch({ok, _}, retest_sh:run("./rebar get-deps", [])),
    ?assertMatch({ok, _}, retest_sh:run("./rebar compile", [])),
    ok = check_beams(true),
    ok = check_debug_info(true),
    ?assertMatch({ok, _}, retest_sh:run("./rebar clean", [])),
    ?assertMatch({ok, _}, retest_sh:run("./rebar compile", [])),
    ok = check_beams(true),
    ok.

check_beams(Exist) ->
    check_files(Exist, fun filelib:is_regular/1).

check_debug_info(HasDebugInfo) ->
    check_files(HasDebugInfo, fun has_debug_info/1).

check_files(Expected, Check) ->
    lists:foreach(
      fun(F) ->
              File = filename:join("ebin", F),
              ?assertEqual(Expected, Check(File))
      end,
      ?BEAM_FILES).

%% NOTE: Copied from dialyzer_utils:get_abstract_code_from_beam/1 and
%% modified for local use. We could have called the function directly,
%% but dialyzer_utils is not an official API to rely on.
has_debug_info(File) ->
    case beam_lib:chunks(File, [abstract_code]) of
        {ok, {_Mod, List}} ->
            case lists:keyfind(abstract_code, 1, List) of
                {abstract_code, {raw_abstract_v1, _Abstr}} ->
                    true;
                _ ->
                    false
            end;
        _ ->
            false
    end.

%%
%% Generate the contents of a simple .app file
%%
app(Name, Modules) ->
    App = {application, Name,
           [{description, atom_to_list(Name)},
            {vsn, "1"},
            {modules, Modules},
            {registered, []},
            {applications, [kernel, stdlib, gpb]}]},
    io_lib:format("~p.\n", [App]).
