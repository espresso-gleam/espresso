% Originally from this stackoverflow post, modified to work with espresso gleam modules.
% https://stackoverflow.com/questions/66682534/how-to-connect-cowboy-erlang-websocket-to-webflow-io-generated-webpage
-module(gleam_websocket_native).
-export([init/2, websocket_init/1, websocket_handle/2, websocket_info/2, module_name/0]).

module_name() ->
    ?MODULE.

init(Req, Handler) ->
    %Perform websocket setup
    {cowboy_websocket, Req, Handler}.

websocket_init(Handler) ->
    {ok, Handler}.

websocket_handle({text, Msg}, Handler) ->
    case Handler(Msg) of
        {reply, Value} -> {reply, {text, Value}, Handler};
        {ping, Value} -> {reply, {pong, Value}, Handler};
        {pong, Value} -> {reply, {ping, Value}, Handler};
        {close, Value} -> {reply, {close, Value}, Handler}
    end;
%Ignore
websocket_handle(_Other, State) ->
    {ok, State}.

websocket_info({text, Text}, State) ->
    {reply, {text, Text}, State};
websocket_info(_Other, State) ->
    {ok, State}.
