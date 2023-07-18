% original source here:
% https://github.com/gleam-lang/cowboy/blob/83e2f20170e4a73e5499238149313f8329a2f41a/src/gleam_cowboy_native.erl
-module(gleam_cowboy_native).

-import(crypto, [strong_rand_bytes/1]).
-import(base64, [encode/1]).

-export([
    init/2,
    terminate/3,
    start_link/2,
    read_body/1,
    router/1,
    module_name/0,
    static_module/0,
    parse_query_string/1,
    get_files/1
]).

module_name() ->
    ?MODULE.

static_module() ->
    cowboy_static.

router(Routes) ->
    % print out the routes for debugging
    % io:format("Routes: ~p~n", [Routes]),
    cowboy_router:compile(Routes).

start_link(Router, Port) ->
    RanchOptions = #{
        max_connections => 16384,
        num_acceptors => 100,
        socket_opts => [{port, Port}]
    },
    CowboyOptions = #{
        env => #{dispatch => Router},
        stream_handlers => [cowboy_stream_h]
    },
    ranch_listener_sup:start_link(
        {gleam_cowboy, make_ref()},
        ranch_tcp,
        RanchOptions,
        cowboy_clear,
        CowboyOptions
    ).

init(Req, Handler) ->
    Bindings = maps:to_list(cowboy_req:bindings(Req)),
    BinaryKeywordList = lists:map(
        fun({Key, Value}) -> {erlang:list_to_binary(atom_to_list(Key)), Value} end, Bindings
    ),
    {ok, Handler(Req, BinaryKeywordList), Req}.

terminate(_Reason, _Req, _State) ->
    % Code to execute after the request is handled
    % Here we want to delete all the files that were made during the request
    case get(files_to_delete) of
        undefined ->
            ok;
        Files ->
            maps:foreach(
                fun(_FieldName, Filename) ->
                    file:delete(Filename)
                end,
                Files
            )
    end,
    ok.

read_entire_body(Req) ->
    read_entire_body([], Req).

read_entire_body(Body, Req0) ->
    case cowboy_req:read_body(Req0) of
        {ok, Chunk, Req1} -> {list_to_binary([Body, Chunk]), Req1};
        {more, Chunk, Req1} -> read_entire_body([Body, Chunk], Req1)
    end.

parse_query_string(Query) ->
    QS = uri_string:dissect_query(Query),
    ProcessedQS = lists:map(
        fun({K, V}) ->
            {K,
                try
                    list_to_integer(binary_to_list(V))
                catch
                    _:_ -> V
                end}
        end,
        QS
    ),
    maps:from_list(
        ProcessedQS
    ).

read_body(Req) ->
    Multipart = cowboy_req:parse_header(<<"content-type">>, Req),
    case Multipart of
        {<<"multipart">>, <<"form-data">>, _headers} ->
            % TODO parse the "data" i.e. non "file" from the multipart
            {ok, Req1} = multipart(Req),
            {<<"">>, Req1};
        Other ->
            io:format("Not multipart: ~p~n", [Other]),
            read_entire_body(Req)
    end.

% https://ninenines.eu/docs/en/cowboy/2.10/guide/multipart/
multipart(Req0) ->
    case cowboy_req:read_part(Req0) of
        {ok, Headers, Req1} ->
            {ok, Req2} =
                case cow_multipart:form_data(Headers) of
                    {data, FieldName} ->
                        read_multipart_data(FieldName, Req1);
                    {file, FieldName, Filename, _CType} ->
                        Filename1 = generate(24),
                        Ext = filename:extension(Filename),
                        RandomFilename = list_to_binary(
                            io_lib:format("/tmp/~s~s", [Filename1, Ext])
                        ),
                        track_file(FieldName, RandomFilename),
                        {ok, FileDescriptor} = file:open(RandomFilename, [write, raw]),
                        Result = stream_file(Req1, RandomFilename, FileDescriptor),
                        file:close(FileDescriptor),
                        Result
                end,
            multipart(Req2);
        {done, Req3} ->
            {ok, Req3}
    end.

read_multipart_data(FieldName, Req) ->
    % {ok, Chunk, Req1} -> {list_to_binary([Body, Chunk]), Req1};
    % {more, Chunk, Req1} -> read_entire_body([Body, Chunk], Req1)
    case cowboy_req:read_part_body(Req) of
        {ok, Body, Req1} ->
            io:format("Data: ~p~n", [Body]),
            {ok, Req1};
        {more, _Body, Req1} ->
            read_multipart_data(FieldName, Req1)
    end.

stream_file(Req0, RandomFilename, FileDescriptor) ->
    case cowboy_req:read_part_body(Req0) of
        {ok, LastBodyChunk, Req} ->
            case write_binary_to_file(FileDescriptor, LastBodyChunk) of
                ok ->
                    {ok, Req};
                {error, Reason} ->
                    {error, Reason}
            end;
        {more, BodyChunk, Req} ->
            case write_binary_to_file(FileDescriptor, BodyChunk) of
                ok ->
                    stream_file(Req, RandomFilename, FileDescriptor);
                {error, Reason} ->
                    {error, Reason}
            end
    end.

write_binary_to_file(FileDescriptor, BinaryData) ->
    case file:write(FileDescriptor, BinaryData) of
        ok ->
            ok;
        {error, Reason} ->
            file:close(FileDescriptor),
            {error, Reason}
    end.

% returns all the files for the current process
get_files(_Req) ->
    get(files_to_delete).

% Tracks files in process dictionary to be deleted later
% (storing in PD is not the best)
track_file(FieldName, Filename) ->
    case get(files_to_delete) of
        undefined ->
            put(files_to_delete, maps:from_list([{FieldName, Filename}]));
        Files ->
            put(files_to_delete, maps:put(Files, FieldName, Filename))
    end.

% Generate a filesystem safe random string
generate(Length) ->
    generate(Length, []).

generate(0, Acc) ->
    lists:reverse(Acc);
generate(Length, Acc) ->
    RandomChar = random_char(),
    generate(Length - 1, [RandomChar | Acc]).

random_char() ->
    RandomInt = rand:uniform(62),
    case RandomInt of
        N when N < 26 ->
            integer_to_list($a + N);
        N when N < 52 ->
            integer_to_list($A + N - 26);
        N when N < 62 ->
            integer_to_list($0 + N - 52);
        _ ->
            random_char()
    end.
