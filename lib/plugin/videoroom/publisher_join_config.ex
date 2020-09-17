defmodule Janus.Plugin.VideoRoom.PublisherJoinConfig do
  @moduledoc """
  Struct with options provided when joining the room as a publisher

  Contains following fields:
  - `:room` - unique ID of the room to join; required,
  - `:id` - unique ID to register for the publisher; optional, will be chosen by the plugin if missing,
  - `:display_name` - display name for the publisher; optional,
  - `:token` - invitation token, in case the room has an ACL; optional
  """

  alias Janus.Plugin.VideoRoom

  @type t() :: %__MODULE__{
          room_id: VideoRoom.room_id(),
          publisher_id: String.t(),
          display_name: String.t(),
          token: String.t()
        }

  @enforce_keys [:room_id]

  defstruct [
    :publisher_id,
    :display_name,
    :token
    | @enforce_keys
  ]

  @struct_to_janus_keys %{
    :room_id => :room,
    :publisher_id => :id,
    :display_name => :name
  }

  @spec to_janus_message(t()) :: map()
  def to_janus_message(configuration) do
    configuration
    |> Map.from_struct()
    |> Bunch.KVEnum.filter_by_values(&(&1 != nil))
    |> Bunch.KVEnum.map_keys(&Map.get(@struct_to_janus_keys, &1, &1))
    |> Map.new()
  end
end
