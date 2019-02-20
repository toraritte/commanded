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
