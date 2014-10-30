%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
%% -------------------------------------------------------------------
%%
%% rebar: Erlang Build Tools
%%
%% Copyright (c) 2009, 2010 Dave Smith (dizzyd@dizzyd.com)
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.
%% -------------------------------------------------------------------
-module(rebar_proto_compiler).
-author('luis.rascao@gmail.com').

-export([compile/2,
         clean/2]).

%% for internal use only
-export([info/2]).

-include("rebar.hrl").

%% ===================================================================
%% Public API
%% ===================================================================

-spec compile(rebar_config:config(), file:filename()) -> ok.
compile(Config, _AppFile) ->
    %% get the complete gpb options list
    ProtoOpts = rebar_config:get(Config, proto_opts, []),
    %% now go thourgh each of the proto entries
    lists:foreach(fun({proto_dir, ProtoDir, RecursiveDir, GpbOpts}) ->
        %% get the directory where the proto files are located
        case find_proto_files(RecursiveDir, ProtoDir) of
            [] ->
                ok;
            ProtoFiles ->
                %% Check for gpb library -- if it's not present, fail
                %% since we have .proto files that need building
                case gpb_is_present() of
                    true ->
                        [compile_proto(Proto, GpbOpts) || Proto <- ProtoFiles];
                    false ->
                        ?ERROR("Gpb library not present in code path!\n",
                               []),
                        ?FAIL
                end,
                ok
        end
    end, ProtoOpts).

-spec clean(rebar_config:config(), file:filename()) -> ok.
clean(Config, _AppFile) ->
    %% get the complete proto options list
    ProtoOpts = rebar_config:get(Config, proto_opts, []),
    %% now go thourgh each of the proto entries
    lists:foreach(fun({proto_dir, ProtoDir, RecursiveDir, GpbOpts}) ->
        {ModPrefix, ModSuffix, ErlTarget, HrlTarget} = gpb_file_opts(GpbOpts),
        %% get a lists of generated files
        GeneratedFiles = proto_generated_files(ProtoDir, RecursiveDir,
                            ModPrefix, ModSuffix,
                            ErlTarget, HrlTarget),
        ok = rebar_file_utils:delete_each(GeneratedFiles)
    end, ProtoOpts).

%% ===================================================================
%% Internal functions
%% ===================================================================

get_gpb_opt({_, undefined, OptErl, _}, Acc) ->
    Acc ++ io_lib:format("        {~s, true | false},\n", [OptErl]);
get_gpb_opt({_, OptType, OptErl, _}, Acc) when is_tuple(OptType) ->
    Acc ++ io_lib:format("        {~s, ~p},\n", [OptErl, OptType]);
get_gpb_opt({_, _, OptErl, _}, Acc) ->
    Acc ++ io_lib:format("        {~s, \"\"},\n", [OptErl]).

get_gpb_opts() ->
    "    [\n" ++
    lists:foldl(fun get_gpb_opt/2, "", gpb_compile:opt_specs()) ++
    "    ]".

info(help, compile) ->
    info_help("Build Protobuf (ProtoDir/*.proto) sources");
info(help, clean) ->
    info_help("Delete Protobuf (*.proto) results").

info_help(Description) ->
    case gpb_is_present() of
        true ->
            ?CONSOLE(
               "~s.~n"
               "~n"
               "Valid rebar.config options:~n"
               "    %% several proto tuples can be defined,~n"
               "    %% each in a separate dir and options~n"
               "    {proto_opts, ~n"
               "        [{proto_dir, ProtoDir, recursive | non_recursive,
                          GpbOptions}]~n"
               "    }~n"
               "~n"
               "Valid Gpb options: (see gpb_compile:opt_specs/0 documentation)~n"
               "~s~n",
               [Description, get_gpb_opts()]);
        false ->
            ?CONSOLE(
                "~s.~n"
                "~n"
                "Gpb library is not present, for protobuf support add "
                "the following dep to your rebar.config:~n"
                "   {gpb, [], {git, \"git://github.com/tomas-abrahamsson/gpb\",
                            {branch, \"master\"}}}"
                "  ~n",
                [Description])
    end.

find_proto_files(non_recursive, ProtoDir) ->
    rebar_utils:find_files(ProtoDir, ".proto$", false);
find_proto_files(recursive, ProtoDir) ->
    rebar_utils:find_files(ProtoDir, "^[^._].*\\.proto$", true).

compile_proto(Proto, GpbOpts) ->
    %% at this stage we are interested in the proto
    %% module suffix and prefix
    %% since they influence the name of the generated files
    {ModPrefix, ModSuffix, ErlTarget, HrlTarget} = gpb_file_opts(GpbOpts),
    %% Compile each proto file
    case needs_compile(Proto,
                        erl_file(Proto, ModPrefix, ModSuffix), ErlTarget,
                        hrl_file(Proto, ModPrefix, ModSuffix), HrlTarget) of
        true ->
            case gpb_compile:file(Proto, GpbOpts) of
                {error, ErrorMsg} ->
                    ?ERROR("Protobuf compile of ~s failed: ~p\n",
                       [Proto, ErrorMsg]),
                    ?FAIL;
                ok ->
                    ?CONSOLE("Compiled ~s\n", [Proto]),
                    ok
            end;
        false ->
            ok
     end.

gpb_file_opts(GpbOpts) ->
    %% at this stage we are interested in the proto module suffix and prefix
    %% since they influence the name of the generated files
    ModSuffix = proplists:get_value(module_name_suffix, GpbOpts, ""),
    ModPrefix = proplists:get_value(module_name_prefix, GpbOpts, ""),
    Target = proplists:get_value(o, GpbOpts, undefined),
    ErlTarget = proplists:get_value(o_erl, GpbOpts, Target),
    HrlTarget = proplists:get_value(o_hrl, GpbOpts, Target),
    {ModPrefix, ModSuffix, ErlTarget, HrlTarget}.

gpb_is_present() ->
    code:which(gpb_compile) =/= non_existing.

erl_file(Proto, ModPrefix, ModSuffix) ->
    ModPrefix ++ filename:basename(Proto, ".proto") ++ ModSuffix ++ ".erl".

hrl_file(Proto, ModPrefix, ModSuffix) ->
    ModPrefix ++ filename:basename(Proto, ".proto") ++ ModSuffix ++ ".hrl".

needs_compile(Proto, Erl, ErlTarget, Hrl, HrlTarget) ->
    ActualErl = filename:join([ErlTarget, filename:basename(Erl)]),
    ActualHrl = filename:join([HrlTarget, filename:basename(Hrl)]),
    (filelib:last_modified(ActualErl) < filelib:last_modified(Proto)) or
    (filelib:last_modified(ActualHrl) < filelib:last_modified(Proto)).

proto_generated_files(ProtoDir, RecursiveDir, ModPrefix, ModSuffix, SrcDir, IncDir) ->
    lists:foldl(
        fun(ProtoFile, Acc) ->
            Base = ModPrefix ++
                   filename:rootname(filename:basename(ProtoFile)) ++
                   ModSuffix,
            [filename:join([IncDir, Base ++ ".hrl"]) |
             filelib:wildcard(filename:join([SrcDir, Base ++ ".erl"]))] ++ Acc
        end,
        [],
        find_proto_files(RecursiveDir, ProtoDir)).

