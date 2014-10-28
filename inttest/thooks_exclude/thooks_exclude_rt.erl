-module(thooks_exclude_rt).

-include_lib("eunit/include/eunit.hrl").
-compile(export_all).

files() ->
    [
     {copy, "../../rebar", "rebar"},
     {copy, "rebar.config", "rebar.config"},
     {copy, "fish.erl", "src/fish.erl"},
     {create, "ebin/fish.app", app(fish, [fish])}
    ].

run(_Dir) ->
    run_ignore_pre_hooks(),
    run_ignore_post_hooks(),
    run_ignore_hooks().

run_ignore_pre_hooks() ->
    clean(),
    ?assertMatch({ok, _},
      retest_sh:run("./rebar -v --ignore-pre-hooks clean compile", [])),
    ensure_command_ran_never("preclean"),
    ensure_command_ran_never("precompile"),
    ensure_command_ran_only_once("postclean"),
    ensure_command_ran_only_once("postcompile"),
    ok.

run_ignore_post_hooks() ->
    clean(),
    ?assertMatch({ok, _},
      retest_sh:run("./rebar -v --ignore-post-hooks clean compile", [])),
    ensure_command_ran_only_once("preclean"),
    ensure_command_ran_only_once("precompile"),
    ensure_command_ran_never("postclean"),
    ensure_command_ran_never("postcompile"),
    ok.

run_ignore_hooks() ->
    clean(),
    ?assertMatch({ok, _},
      retest_sh:run("./rebar -v --ignore-hooks clean compile", [])),
    ensure_command_ran_never("preclean"),
    ensure_command_ran_never("precompile"),
    ensure_command_ran_never("postclean"),
    ensure_command_ran_never("postcompile"),
    ok.

clean() ->
    delete("preclean.out"),
    delete("precompile.out"),
    delete("postclean.out"),
    delete("postcompile.out").

delete(File) ->
    case file:delete(File) of
        ok -> ok;
        {error, enoent} -> ok
    end.

ensure_command_ran_never(Command) ->
    File = Command ++ ".out",
    ?assertNot(filelib:is_file(File)).

ensure_command_ran_only_once(Command) ->
    File = Command ++ ".out",
    ?assert(filelib:is_regular(File)),
    %% ensure that this command only ran once (not for each module)
    {ok, Content} = file:read_file(File),
    ?assertEqual(Command ++ "\n", binary_to_list(Content)).

%%
%% Generate the contents of a simple .app file
%%
app(Name, Modules) ->
    App = {application, Name,
           [{description, atom_to_list(Name)},
            {vsn, "1"},
            {modules, Modules},
            {registered, []},
            {applications, [kernel, stdlib]}]},
    io_lib:format("~p.\n", [App]).
