-module(interclock).
-export([boot/2, id/1, fork/1]).

-type name() :: term().
-type type() :: 'root' | 'normal'.
-type id() :: itc:id().
-type uuid() :: iodata().

-export_type([name/0, type/0, id/0, uuid/0]).

%%%===================================================================
%%% API
%%%===================================================================
boot(Name, Opts) ->
    Path = proplists:get_value(dir, Opts),
    case {proplists:get_value(type, Opts, normal),
                       proplists:get_value(uuid, Opts),
                       proplists:get_value(id, Opts)} of
        {root, undefined, undefined} ->
            {ClockId, _ClockEvent} = itc:explode(itc:seed()),
            NewUUID = uuid:get_v4(),
            start_process(Name, NewUUID, ClockId, Path, root);
        {normal, ExistingUUID, ClockId} when ClockId =/= undefined,
                                             ExistingUUID =/= undefined ->
            start_process(Name, ExistingUUID, ClockId, Path, normal);
        {normal, _, _} ->
            {error, missing_id}
    end.

id(Name) ->
    interclock_db:id(Name).

fork(Name) ->
    interclock_db:fork(Name).

%%%===================================================================
%%% private
%%%===================================================================
start_process(Name, UUID, Id, Path, Type) ->
    case supervisor:start_child(interclock_sup, [Name, UUID, Id, Path, Type]) of
        {error, Reason} -> {error, Reason};
        {ok, _Pid} -> ok
    end.