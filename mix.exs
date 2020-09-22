defmodule Janus.Plugin.VideoRoom.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/software-mansion-labs/elixir-janus-plugin-videoroom"

  def project do
    [
      app: :elixir_janus_plugin_videoroom,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # hex
      description: "Utility package for communicating with Janus VideoRoom plugin",
      package: package(),

      # docs
      name: "Elixir Janus Plugin VideoRoom",
      source_url: @github_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:elixir_janus,
       github: "software-mansion-labs/elixir-janus", branch: "add-async-support", override: true},
      {:jason, "~> 1.0"},
      {:elixir_janus_transport_ws,
       github: "software-mansion-labs/elixir-janus-transport-ws", only: :test},
      {:websockex, "~> 0.4.2", only: :test},
      {:mock, "~> 0.3.0", only: :test},
      {:ex_doc, "~> 0.22", only: [:test, :dev], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["ElixirJanus Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      source_ref: "v#{@version}"
    ]
  end
end
