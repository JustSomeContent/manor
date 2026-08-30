defmodule Manor.MixProject do
  use Mix.Project

  def project do
    [
      app: :manor,
      version: "0.1.0",
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Manor",
      docs: [main: "Manor", extras: ["README.md"], groups_for_modules: doc_groups()],
      # The project ships mix tasks, so Mix itself belongs in the PLT.
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  def application do
    # The tree boots with the app everywhere except :test, where the part-8
    # suite starts its own Registry/DynamicSupervisor per test — two owners
    # of a globally-named process can't coexist.
    if Mix.env() == :test do
      [extra_applications: [:logger]]
    else
      [
        extra_applications: [:logger],
        mod: {Manor.Application, []}
      ]
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # The core lab ran on zero dependencies, on purpose. These arrived with
  # the Annex parts — tooling only, nothing at runtime:
  defp deps do
    [
      # Annex B: property-based testing
      {:stream_data, "~> 1.1", only: [:dev, :test]},
      # Annex C: documentation site (mix docs)
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      # Annex D: static analysis (mix dialyzer, mix credo --strict)
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp doc_groups do
    [
      "Pure core":
        ~r/Manor\.(Game|Grid|Mansion|PlacedRoom|Room|Resources|RNG|DraftPool|Effect|Recipe|Special|Item)/,
      Content: ~r/Manor\.(Catalog|RunConfig)/,
      "OTP shell": ~r/Manor\.(Application|RunServer|Stats|Game\.Server)/,
      "Edge & bots": ~r/Manor\.(CLI|Render|Strategy|Autoplay|Benchmark)/
    ]
  end
end
