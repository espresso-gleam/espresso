-module(espresso_atoms).

-export([
    decode_atom/1
]).

decode_atom(Data) when is_atom(Data) -> {ok, Data};
decode_atom(Data) -> gleam_stdlib:decode_error_msg(<<"Atom">>, Data).
