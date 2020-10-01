defmodule Janus.Plugin.VideoRoom.SubscriberConfig do
  @moduledoc """
  A struct used to re-configure a subscriber

  Any omitted field will not be changed when making a request.

  Contains following fields:
  - `:relay_audio?` - true|false, depending on whether audio should be relayed or not; optional,
  - `:relay_video?` - true|false, depending on whether video should be relayed or not; optional,
  - `:relay_data?` - true|false, depending on whether datachannel messages should be relayed or not; optional,
  - `:simulcast_substream` - substream to receive (0-2), in case simulcasting is enabled; optional,
  - `:simulcast_temporal_layer` - temporal layers to receive (0-2), in case simulcasting is enabled; optional,
  - `:fallback_time_us` - How much time (in us, default 250000) without receiving packets will make us drop to the substream below,
  - `:spatial_layer` - spatial layer to receive (0-2), in case VP9-SVC is enabled; optional,
  - `:temporal_layer` - temporal layers to receive (0-2), in case VP9-SVC is enabled; optional,
  - `:audio_level_average` - if provided, overrides the room audio_level_average for this user; optional,
  - `:audio_active_packets` - if provided, overrides the room audio_active_packets for this user; optional
  """

  @type t() :: %__MODULE__{
          relay_audio?: boolean(),
          relay_video?: boolean(),
          relay_data?: boolean(),
          simulcast_substream: non_neg_integer() | nil,
          simulcast_temporal_layer: non_neg_integer() | nil,
          fallback_time_us: pos_integer(),
          spatial_layer: non_neg_integer() | nil,
          temporal_layer: non_neg_integer() | nil
        }

  defstruct [
    :relay_audio?,
    :relay_video?,
    :relay_data?,
    :simulcast_substream,
    :simulcast_temporal_layer,
    :spatial_layer,
    :temporal_layer,
    :fallback_time_us
  ]

  @struct_to_janus_keys %{
    :relay_audio? => :audio,
    :relay_video? => :video,
    :relay_data? => :data,
    :simulcast_substream => :substream,
    :simulcast_temporal_layer => :temporal,
    :fallback_time_us => :fallback
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
