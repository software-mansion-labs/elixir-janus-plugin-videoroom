defmodule Janus.Plugin.VideoRoom.PublisherConfig do
  @moduledoc """
  Struct with configuration of a publisher sent with `publish` and `configure` requests

  Contains following fields:
  - `:relay_audio?` - true|false, whether or not audio should be relayed; true by default
  - `:relay_video?` - true|false, whether or not video should be relayed; true by default
  - `:relay_data?` - true|false, whether or not data should be relayed; true by default
  - `:audio_codec` - audio codec to prefer among the negotiated ones; optional
  - `:video_codec` - video codec to prefer among the negotiated ones; optional
  - `:bitrate` - bitrate cap to return via REMB; optional, overrides the global room value if present
  - `:request_keyframe?` - only on "configure" request; whether we should send this publisher a keyframe request
  - `:record?` - true|false, whether this publisher should be recorded or not; optional
  - `:file_name` - if recording, the base path/file to use for the recording files; optional
  - `:display_name` - new display name to use in the room; optional
  - `:audio_level_average` - if provided, overrided the room audio_level_average for this user; optional
  - `:audio_active_packets` - if provided, overrided the room audio_active_packets for this user; optional
  """

  alias Janus.Plugin.VideoRoom

  @type t() :: %__MODULE__{
          relay_audio?: boolean(),
          relay_video?: boolean(),
          relay_data?: boolean(),
          audio_codec: VideoRoom.audio_codec() | nil,
          video_codec: VideoRoom.video_codec() | nil,
          bitrate: pos_integer() | nil,
          request_keyframe?: boolean() | nil,
          record?: boolean() | nil,
          file_name: String.t() | nil,
          display_name: String.t() | nil,
          audio_level_average: pos_integer() | nil,
          audio_active_packets: pos_integer() | nil
        }

  @struct_to_janus_keys %{
    :relay_audio? => :audio,
    :relay_video? => :video,
    :relay_data? => :data,
    :audio_codec => :audiocodec,
    :video_codec => :videocodec,
    :record? => :record,
    :request_keyframe? => :keyframe,
    :display_name => :display,
    :file_name => :filename
  }

  defstruct [
    :audio_codec,
    :video_codec,
    :bitrate,
    :record?,
    :file_name,
    :request_keyframe?,
    :display_name,
    :audio_level_average,
    :audio_active_packets,
    relay_audio?: true,
    relay_video?: true,
    relay_data?: true
  ]

  @spec to_janus_message(t()) :: map()
  def to_janus_message(configuration) do
    configuration
    |> Map.from_struct()
    |> Bunch.KVEnum.filter_by_values(&(&1 != nil))
    |> Bunch.KVEnum.map_keys(&Map.get(@struct_to_janus_keys, &1, &1))
    |> Map.new()
  end
end
