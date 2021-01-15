# Elixir Janus Plugin VideoRoom

This package implements functionality to communicate with [Janus VideoRoom plugin](https://janus.conf.meetecho.com/docs/videoroom.html).

It takes advantage of transport layer provided by another package [Elixir Janus](https://github.com/software-mansion-labs/elixir-janus).

## Disclaimer

Package is experimental and is not yet released to hex.

## Example

```elixir
# this example uses `Janus.Transport.WS` package for connection's transport and arbitrary `CustomHandler` module that implements `Janus.Handler` behaviour.
iex> alias Janus.{Connection, Session}
iex> alias Janus.Transport.WS
iex> alias Janus.Plugin.VideoRoom
iex> {:ok, connection} = Connection.start_link(WS, {"ws://gateway-domain:8188", WS.Adapters.WebSockex, []}, CustomHandler, {}, [])
iex> {:ok, session} = Session.start_link(connection)
iex> {:ok, room_id} = VideoRoom.create(session, "room id", %CreateRoomProperties{description: "test videoroom"}, "some admin key", "some room secret")
```

## Installation

```elixir
def deps do
  [
    {:elixir_janus_plugin_videoroom, github: "software-mansion-labs/elixir-janus-plugin-videoroom"}
  ]
end
```

## Testing

By default, the tests contacting Janus Gateway are disabled. To run them, use `mix test --include integration`

To run the instance for tests you can use Docker image:

```bash
docker run --rm -e GATEWAY_IP=127.0.0.1 -e WEBSOCKETS_ENABLED=true -e RTP_PORT_RANGE=10000-10099 -p 8188:8188 -p 10000-10099:10000-10099/udp -ti swmansion/janus-gateway:0.10.3-4
```

## Copyright and License

Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=elixir-janus-plugin-videoroom)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=elixir-janus-plugin-videoroom)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=elixir-janus-plugin-videoroom)

Licensed under the [Apache License, Version 2.0](LICENSE)
