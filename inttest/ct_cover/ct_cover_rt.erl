-module(ct_cover_rt).

-compile(export_all).


files() ->
    [{copy, "../../rebar", "rebar"},
     {copy, "src", "src"},
     {copy, "test", "test"},
     {copy, "deps", "deps"},
     {copy, "rebar.config", "rebar.config"}].


run(_Dir) ->
    {ok, _} = retest:sh("./rebar compile ct -vv"),
    ok.
