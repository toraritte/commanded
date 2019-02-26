defmodule Commanded.Aggregates.Supervisor do
  @moduledoc """
  Supervises `Commanded.Aggregates.Aggregate` instance processes.
  """

  use DynamicSupervisor

  require Logger

  alias Commanded.Aggregates.Aggregate
  alias Commanded.Registration

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_child([aggregate_module, aggregate_uuid, opts]) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {aggregate_module, [aggregate_uuid, opts]}
    )
  end

  def start_registered_child(args, via_tuple) do
    __MODULE__.start_child(args ++ [[name: via_tuple]])
  end

  # 2019-02-25_1315 TODO How to start gen_statem aggregates with the right state?
  @doc """
  After a system shutdown or accidental one.

  The stuff below is  not very relevant, because event
  metadata  will  be  saved  to  the  eventstore,  but
  aggregates should probably have their own mechanisms
  to save their internal data and state.

  -------

  Commands  can  be   dispatched  with  metadata,  but
  only  event  handlers  can  access  it.  Aggregates'
  `execute/2` or `apply/2`, or custom command handlers
  don't have access  to it, even though  the passed on
  `ExecutionContext` carries the metadata. The process:

  1. `use    Commanded.Commands.Router`    will    import
     `Commanded.Commands.Router.dispatch/2`.  Registering
     commands   using  this   `dispatch/2`  will   invoke
     `register/2`.

  2. `register/2`    defines    `dispatch/2`    in    the
     user-defined router,  and it  can be invoked  with a
     `:metadata` option.  This, along with  other options
     will be  saved in a  `Payload` struct, and  given as
     input to `Dispatcher.dispatch/1`.

  3. `Dispatcher.dispatch/1`  makes  a `Pipeline`  struct
      from  `Payload`, and  invokes `Dispatcher.execute/2`
      with both structs.

  4. `execute/2`  uses   the  `Pipeline`   and  `Payload`
     structs  to  create  an  `ExecutionContext`  struct,
     that also  has a  metadata field. This  context gets
     passed to the running  aggregate instance by calling
     `Aggregate.execute/4`.

  5. `Aggregate.execute/4` is a  `GenServer` call passing
     the tuple `{:execute_command, context}`.

  6. `handle_call`     callback     routes    this     to
     `execute_command/2`, extracts command  from it to do
     the rest, but never touches metadata.
  """

  @doc """
  Open an aggregate instance process for the given aggregate module and unique
  indentity.

  Returns `{:ok, aggregate_uuid}` when a process is sucessfully started, or is
  already running.
  """
  def open_aggregate(aggregate_module, aggregate_uuid) when is_binary(aggregate_uuid) do
    Logger.debug(fn ->
      "Locating aggregate process for `#{inspect(aggregate_module)}` with UUID " <>
        inspect(aggregate_uuid)
    end)

    via_tuple = Aggregate.via_name(aggregate_module, aggregate_uuid)

    case start_registered_child([aggregate_module, aggregate_uuid], via_tuple) do
      {:ok, _pid} ->
        {:ok, aggregate_uuid}

      {:ok, _pid, _info} ->
        {:ok, aggregate_uuid}

      {:error, {:already_started, _pid}} ->
        {:ok, aggregate_uuid}

      reply ->
        reply
    end
  end

  def open_aggregate(_aggregate_module, aggregate_uuid),
    do: {:error, {:unsupported_aggregate_identity_type, aggregate_uuid}}

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
