defmodule Commanded.Mixfile do
  use Mix.Project

  @version "0.17.1"

  def project do
    [
      app: :commanded,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: description(),
      docs: docs(),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() == :prod,
      name: "Commanded",
      source_url: "https://github.com/commanded/commanded"
    ]
  end

  def application do
    [
      extra_applications: [
        :logger
      ],
      mod: {Commanded.Application, []}
    ]
  end

  defp elixirc_paths(:test),
    do: [
      "lib",
      "test/aggregates/support",
      "test/commands/support",
      "test/event/support",
      "test/event_store/support",
      "test/example_domain",
      "test/helpers",
      "test/process_managers/support",
      "test/pubsub/support",
      "test/registration/support",
      "test/support"
    ]

  defp elixirc_paths(_), do: ["lib", "test/helpers"]

  defp deps do
    [
      """
      NOTE 2018-10-26_1528
      These deps  will always conflict during  `git rebase
      upstream/master`  because   "annotate"  is  branched
      after  the  stupid  "include-*" branches  have  been
      merged, but  I don't  want to  lose the  comments in
      here. Will move them to a saner branch.
      """
      {:elixir_uuid, "~> 1.2"},
      {:poison, "~> 3.1 or ~> 4.0", optional: true},
      {:poison, "~> 3.1 or ~> 4.0"},
      {:ecto, "~> 2.2", runtime: false},
      {:eventstore, "~> 0.15"},

      # Build & test tools
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev},
      {:mix_test_watch, "~> 0.9", only: :dev},
      {:mox, "~> 0.4", only: :test},
      {:postgrex, "~> 0.13", only: :test},

      # Optional dependencies
      @doc """
      NOTE 2018-10-24_2246 for "make-application-more-idiomatic" branch
      Making  `phoenix_pubsub`   permanent  dependency  to
      replace  LocalPubSub.  Its  `child_spec/0`  function
      is  not   compliant  with   Elixir's  `child_spec/1`
      expectation  and it  also  returns a  list of  child
      specs  as  it  is  implemented  using  two  Registry
      processes.  Ben  already  included  an  adapter  for
      PhoenixPubSub  and starting  from version  1.1.1, it
      can be directly started in a supervision tree.

      """
      {:phoenix_pubsub, "~> 1.1", optional: true}
    ]
  end

  defp description do
    """
    Use Commanded to build your own Elixir applications following the CQRS/ES pattern.
    """
  end

  defp docs do
    [
      main: "Commanded",
      canonical: "http://hexdocs.pm/commanded",
      source_ref: "v#{@version}",
      extra_section: "GUIDES",
      extras: [
        "guides/Getting Started.md",
        "guides/Choosing an Event Store.md",
        "guides/Usage.md",
        "guides/Aggregates.md",
        "guides/Commands.md",
        "guides/Events.md",
        "guides/Process Managers.md",
        "guides/Supervision.md",
        "guides/Serialization.md",
        "guides/Read Model Projections.md",
        "guides/Testing.md",
        "guides/Deployment.md",
        "CHANGELOG.md"
      ]
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README*",
        "LICENSE*",
        "CHANGELOG*",
        "test/event_store/support",
        "test/example_domain",
        "test/helpers",
        "test/registration/support",
        "test/support"
      ],
      maintainers: ["Ben Smith"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/commanded/commanded",
        "Docs" => "https://hexdocs.pm/commanded/"
      }
    ]
  end
end
