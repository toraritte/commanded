defmodule Commanded.Aggregates.AggregateLifespan do
  @moduledoc """
  The `Commanded.Aggregates.AggregateLifespan` behaviour is used to control the
  aggregate `GenServer` process lifespan.

  By default an aggregate instance process will run indefinitely once started.
  You can change this default by implementing the
  `Commanded.Aggregates.AggregateLifespan` behaviour in a module and configuring
  it in your router.

  After a command successfully executes, and creates at least one domain event,
  the `c:after_event/1` function is called passing the last created event.

  When a command is successfully handled but results in no domain events (by
  returning `nil` or an empty list `[]`), the command struct is passed to the
  `c:after_command/1` function.

  Finally, if there is an error executing the command, the error reason is
  passed to the `c:after_error/1` function.

  For all the above, the returned inactivity timeout value is used to shutdown
  the aggregate process if no other messages are received.

  ## Supported return values

    - Non-negative integer - specify an inactivity timeout, in millisconds.
    - `:infinity` - prevent the aggregate instance from shutting down.
    - `:hibernate` - send the process into hibernation.
    - `:stop` - immediately shutdown the aggregate process.

  ### Hibernation

  A hibernated process will continue its loop once a message is in its message
  queue. Hibernating an aggregate causes garbage collection and minimises the
  memory used by the process. Hibernating should not be used aggressively as too
  much time could be spent garbage collecting.

  ## Example

  Define a module that implements the `Commanded.Aggregates.AggregateLifespan`
  behaviour:

      defmodule BankAccountLifespan do
        @behaviour Commanded.Aggregates.AggregateLifespan

        def after_event(%MoneyDeposited{}), do: :timer.hours(1)
        def after_event(%BankAccountClosed{}), do: :stop
        def after_event(_event), do: :infinity

        def after_command(%CloseAccount{}), do: :stop
        def after_command(_command), do: :infinity

        def after_error(:invalid_initial_balance), do: :timer.minutes(5)
        def after_error(_error), do: :stop
      end

  Then specify the module as the `lifespan` option when registering the
  applicable commands in your router:

      defmodule BankRouter do
        use Commanded.Commands.Router

        dispatch [OpenAccount, CloseAccount],
          to: BankAccount,
          lifespan: BankAccountLifespan,
          identity: :account_number
      end

  """

  # 2019-02-25_1010 TODO Move AggregateLifespan to Aggregate (implicit coupling)
  @doc """
  `gen_statem` (and most `gen_` process) has their own
  timers and timer-related actions.

  **Why would it be useful to extract it into a behaviour?**

  1. Because  then  the  same lifespan  module  could  be
     reused  for other  aggregates.

  2.  Respond  to events  from other  aggregates/contexts.

      For  example, shut  down `BankAccount`  if `Billing`
      context sends  out a `CloseAccount` event.  (This is
      exremely contrived, and this  case should be handled
      by `Accounts`  context by  listening to  events like
      this, or something.)

  WRONG.  Any module  implementing  this behaviour  is
  still  strongly coupled,  but  implicitly, which  is
  even worse both 1. and 2. non use-cases.

  The callback  module only works if  every associated
  aggregate (done in  Router, see moduledoc) implement
  the  same events.  **Unless**  it is  also an  event
  handler,  but  that  may complicate  things  because
  ["Commanded guarantees only one instance of an event
  handler will  run, regardless of how  many nodes are
  running"] (https://github.com/commanded/commanded/blob/b7a0ca31686d8a06ad1753dbe2e3f2c1adb64c48/guides/Events.md#event-handlers).

  The implicit coupling:

  In   `AggregateLifespan`  moduledoc   example,  stop
  events are specified, and  catch-all clauses for all
  others. Both Aggregate  and ExecutionContext structs
  hold  references to  lifespan (see  2019-02-25_1052)
  for some reason.

  When     a     command     is     dispatched,     an
  `:execute_command`   message   is    sent   to   the
  aggregate    process,   and    its   `handle_call/3`
  invokes   `Aggregate.execute_command/2`.   It   will
  use  `Kernel.apply/3`   to  call   the  user-defined
  `execute/2`   function   clause,   which   in   turn
  returns  a   list  of   events  (can  be   an  empty
  list).  These returned  events  are  applied to  the
  aggregate's state, and `persist_events/4` is called.
  `Aggregate.execute_command/2` final  return value is
  `persist_events/4`'s on success:

    {{:ok, aggregate_version, pending_events}, state}
    {-------reply----------------------------  state}

  Returning to `handle_call({:execute_command, ...})`,
  events are  extracted from  the returned  reply (see
  above), and these events  are only the ones returned
  by this  aggregate. All lifespan decisions  are base
  on these.

  -------

  It  would probably  to  be more  prudent handle  any
  timeouts  and shutdown  conditions in  the aggregate
  itself.
  """

  @type lifespan :: timeout | :hibernate | :stop

  @doc """
  Aggregate process will be stopped after specified inactivity timeout unless
  `:infinity`, `:hibernate`, or `:stop` are returned.
  """
  @callback after_event(event :: struct) :: lifespan

  @doc """
  Aggregate process will be stopped after specified inactivity timeout unless
  `:infinity`, `:hibernate`, or `:stop` are returned.
  """
  @callback after_command(command :: struct) :: lifespan

  @doc """
  Aggregate process will be stopped after specified inactivity timeout unless
  `:infinity`, `:hibernate`, or `:stop` are returned.
  """
  @callback after_error(any) :: lifespan
end
