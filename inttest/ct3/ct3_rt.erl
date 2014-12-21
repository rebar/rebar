-module(ct3_rt).

-compile(export_all).


files() ->
    [{create, "ebin/foo.app", app(foo)},
     {copy, "../../rebar", "rebar"},
     {copy, "foo-cover.spec", "cover.spec"},
     {copy, "rebar.config", "rebar.config"},
     {copy, "foo.test.spec", "foo.test.spec"},
     {copy, "foo.test.spec", "deps/bar/bar.test.spec"},
     {copy, "foo_SUITE.erl", "test/foo_SUITE.erl"},
     {copy, "foo.erl", "src/foo.erl"},
     {copy, "bar.erl", "deps/bar/src/bar.erl"},
     {copy, "bar_SUITE.erl", "deps/bar/test/bar_SUITE.erl"},
     {copy, "bar-cover.spec", "deps/bar/cover.spec"},
     {create, "deps/bar/ebin/bar.app", app(bar)}



    ].

run(_Dir) ->
    {ok, _} = retest:sh("./rebar compile -vvv"),
    {ok, _} = retest:sh("./rebar ct skip_deps=true -vvv"),
    ok.

%%
%% Generate the contents of a simple .app file
%%
app(Name) ->
    App = {application, Name,
           [{description, atom_to_list(Name)},
            {vsn, "1"},
            {modules, [Name]},
            {registered, []},
            {applications, [kernel, stdlib]}]},
    io_lib:format("~p.\n", [App]).
