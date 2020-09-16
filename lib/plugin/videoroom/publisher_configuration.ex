defmodule Janus.Plugin.VideoRoom.PublisherConfiguration do
  @moduledoc """
  Struct with configuration of a publisher

  Contains following fields:
  - `:audio` - true|false, whether or not audio should be relayed; true by default
  - `:video` - <true|false, whether or not video should be relayed; true by default
  - `:data` - <true|false, whether or not data should be relayed; true by default
  - `:audiocodec` - audio codec to prefer among the negotiated ones; optional
  - `:videocodec` - video codec to prefer among the negotiated ones; optional
  - `:bitrate` - bitrate cap to return via REMB; optional, overrides the global room value if present
  - `:record` - true|false, whether this publisher should be recorded or not; optional
  - `:filename` - if recording, the base path/file to use for the recording files; optional
  - `:display` - new display name to use in the room; optional
  - `:audio_level_average` - if provided, overrided the room audio_level_average for this user; optional
  - `:audio_active_packets` - if provided, overrided the room audio_active_packets for this user; optional
  """

  alias Janus.Plugin.VideoRoom

  @type t() :: %__MODULE__{
          relay_audio: boolean(),
          relay_video: boolean(),
          relay_data: boolean(),
          audio_codec: VideoRoom.audio_codec() | nil,
          video_codec: VideoRoom.video_codec() | nil,
          bitrate: pos_integer() | nil,
          record?: boolean() | nil,
          file_name: String.t() | nil,
          display: String.t() | nil,
          audio_level_average: pos_integer() | nil,
          audio_active_packets: pos_integer() | nil
        }

  @struct_to_janus_keys %{
    :relay_audio => :audio,
    :relay_video => :video,
    :relay_data => :data,
    :audio_codec => :audiocodec,
    :video_codec => :videocodec,
    :record? => :record,
    :file_name => :filename
  }

  defstruct [
    :audio_codec,
    :video_codec,
    :bitrate,
    :record?,
    :file_name,
    :display,
    :audio_level_average,
    :audio_active_packets,
    relay_audio: true,
    relay_video: true,
    relay_data: true
  ]

  @spec to_janus_message(t()) :: map()
  def to_janus_message(configuration) do
    configuration
    |> Map.from_struct()
    |> Bunch.KVEnum.map_keys(&Map.get(@struct_to_janus_keys, &1, &1))
    |> Bunch.KVEnum.filter_by_values(&(&1 != nil))
    |> Map.new()
  end
end
