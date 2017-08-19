-module(a).

-export([hello/0]).

-include_lib("b/include/b.hrl").

hello() ->
    io:format("~s\n", [?HELLO]).
