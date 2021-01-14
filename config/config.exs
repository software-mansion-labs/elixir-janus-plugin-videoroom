import Config

if Mix.env() == :test do
  alias Janus.Transport.WS

  config :elixir_janus_plugin_videoroom,
    transport: WS,
    transport_opts: {"ws://localhost:8188", WS.Adapters.WebSockex, timeout: 5000},
    janus_plugin_admin_key: "supersecret"
end
