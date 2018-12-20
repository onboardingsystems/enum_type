defmodule EnumType.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :enum_type,
      version: @version,
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "An Elixir friendly Enum module generator that can be used by itself or with Ecto.",
      name: "EnumType",
      package: %{
        licenses: ["Apache 2.0"],
        maintainers: ["Joseph Lindley"],
        links: %{"GitHub" => "https://github.com/onboardingsystems/enum_type"},
        files: ~w(mix.exs README.md lib)
      },
      docs: [source_ref: "v#{@version}", main: "readme",
              canonical: "http://hexdocs.pm/enum_type",
              source_url: "https://github.com/onboardingsystems/enum_type",
              extras: ["README.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.0", only: [:docs, :dev]},
      {:ecto, "~> 3.0", only: [:test]}
    ]
  end
end
