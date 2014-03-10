%% -*- erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ts=4 sw=4 et
%% -------------------------------------------------------------------
%%
%% rebar: Erlang Build Tools
%%
%% Copyright (c) 2013 Drew Varner (drew.varner@ninefx.com)
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
-module(rebar_plain_src_utils).

-export([is_plain_src_dir/0,
         is_plain_src_dir/1]).

is_plain_src_dir() ->
    is_plain_src_dir(rebar_utils:get_cwd()).

is_plain_src_dir(Dir) ->
    SrcDir = filename:join([Dir, "src"]),
    Src = filename:join([SrcDir, "*.erl"]),
    IsPlainSrcDir = length(filelib:wildcard(Src)) > 0 andalso
                    not (rebar_rel_utils:is_rel_dir(Dir) orelse
                    rebar_app_utils:is_app_dir(Dir)),
    case IsPlainSrcDir of
        true -> {true, Dir};
        false -> false
    end.

    