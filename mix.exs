defmodule Manor.MixProject do
  use Mix.Project

  def project do
    [
      app: :manor,
      version: "0.1.0",
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
      # TODO(Part 8): uncomment to boot the supervision tree with the app.
      # mod: {Manor.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Zero dependencies, on purpose: the whole lab is stdlib + OTP.
  # The Annex parts add stream_data / ex_doc / dialyxir / credo when you get there.
  defp deps do
    []
  end
end
