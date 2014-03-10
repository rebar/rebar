-module({{modid}}_tests).
-include_lib("eunit/include/eunit.hrl").

easy_test() ->
    ?assert({{modid}}:my_func() =:= ok).
