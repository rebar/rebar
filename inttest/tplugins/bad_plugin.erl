-module(bad_plugin).

-export([fwibble/2]).

%% this plugin contains numerous DELIBERATE syntax errors

fwibble(Config, _) >
    file:delete("fwibble.test")
