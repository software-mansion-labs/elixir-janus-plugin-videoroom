defmodule ElixirJanusPluginVideoroom.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_janus_plugin_videoroom,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:elixir_janus, github: "software-mansion-labs/elixir-janus"},
      {:jason, "~> 1.0"}
    ]
  end
end
