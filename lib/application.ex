defmodule Commanded.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    """
    TODO: 2018-10-26_1437

    (1) Removing `EventStore.child_spec/0` breaks the external adapters
        `commanded/commanded-eventstore-adapter` and
        `commanded/commanded-extreme-adapter`,
        and the internal `InMemory` in partial.

        => Make them more OTP compliant as well.

    (2) The `InMemory` adapter is updated, but it is not started with
        the application anymore.

        => `InMemory` should be an external application so that
           it could be required only for testing.
    """
    children =
      Registration.child_spec() ++
      PubSub.child_spec() ++
      [
        {Task.Supervisor, name: Commanded.Commands.TaskDispatcher},
        Commanded.Aggregates.Supervisor,
        Commanded.Subscriptions,
      ]

    opts = [strategy: :one_for_one, name: Commanded.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
