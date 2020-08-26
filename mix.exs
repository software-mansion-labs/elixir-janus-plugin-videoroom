defmodule ElixirJanusPluginVideoroom.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_janus_plugin_videoroom,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]


  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:elixir_janus, github: "software-mansion-labs/elixir-janus"},
      {:jason, "~> 1.0"},
      {:mock, "~> 0.3.0", only: :test},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end
end
