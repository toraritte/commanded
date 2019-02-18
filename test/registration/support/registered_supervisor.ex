defmodule Commanded.Registration.RegisteredSupervisor do
  use DynamicSupervisor

  alias Commanded.Registration
  alias Commanded.Registration.RegisteredServer

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child(args) do
    DynamicSupervisor.start_child(__MODULE__, {Commanded.Registration.RegisteredServer, args})
  end

  def start_registered_child(name, via_tuple) do
    __MODULE__.start_child([name, [name: via_tuple]])
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
