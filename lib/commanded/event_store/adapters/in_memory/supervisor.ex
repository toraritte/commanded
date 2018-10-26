defmodule Commanded.EventStore.Adapters.InMemory.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(_arg) do
    Supervisor.start_link(__MODULE__, :nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_arg) do
    children = [
      InMemory,
      {DynamicSupervisor,
        strategy: :one_for_one,
        name: Commanded.EventStore.Adapters.InMemory.SubscriptionsSupervisor
      },
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.init(children, opts)
  end
end
