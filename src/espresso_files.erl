-module(espresso_files).

-export([
    read/1
]).

read(Path) ->
    {ok, Binary} = file:read_file(Path),
    Binary.
