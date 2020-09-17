defmodule Janus.Plugin.VideoRoom.SubscriberJoinConfig do
  @moduledoc """
  A struct describing initial subscriber configuration. Used in `join` (with ptype `"subscriber"`)

  Has the following fields:
  - `:room_id` - unique ID of the room to subscribe in,
  - `:feed_id` - unique ID of the publisher to subscribe to; mandatory,
  - `:private_id` - unique ID of the publisher that originated this request; optional, unless mandated by the room configuration,
  - `:close_pc_on_leave?` - true|false, depending on whether or not the PeerConnection should be automatically closed when the publisher leaves; true by default,
  - `:relay_audio?` - true|false, depending on whether or not audio should be relayed; true by default,
  - `:relay_video?` - true|false, depending on whether or not video should be relayed; true by default,
  - `:relay_data?` - true|false, depending on whether or not data should be relayed; true by default,
  - `:offer_audio?` - true|false; whether or not audio should be negotiated; if not set, will behave as true if the publisher has audio,
  - `:offer_video?` - true|false; whether or not video should be negotiated; if not set, will behave as true if the publisher has video,
  - `:offer_data?` - true|false; whether or not datachannels should be negotiated; if not set, will behave as true if the publisher has datachannels,
  - `:simulcast_substream` - substream to receive (0-2), in case simulcasting is enabled; optional,
  - `:simulcast_temporal_layer` - temporal layers to receive (0-2), in case simulcasting is enabled; optional,
  - `:fallback_time` - How much time (in us, default 250000) without receiving packets will make us drop to the substream below,
  - `:spatial_layer` - spatial layer to receive (0-2), in case VP9-SVC is enabled; optional,
  - `:temporal_layer` - temporal layers to receive (0-2), in case VP9-SVC is enabled; optional
  """

  alias Janus.Plugin.VideoRoom

  @type t() :: %__MODULE__{
          room_id: VideoRoom.room_id(),
          feed_id: String.t(),
          private_id: String.t() | nil,
          close_pc_on_leave?: boolean(),
          relay_audio?: boolean(),
          relay_video?: boolean(),
          relay_data?: boolean(),
          offer_audio?: boolean() | nil,
          offer_video?: boolean() | nil,
          offer_data?: boolean() | nil,
          simulcast_substream: non_neg_integer() | nil,
          simulcast_temporal_layer: non_neg_integer() | nil,
          fallback_time_us: pos_integer(),
          spatial_layer: non_neg_integer() | nil,
          temporal_layer: non_neg_integer() | nil
        }

  @enforce_keys [:room_id, :feed_id]

  defstruct @enforce_keys ++
              [
                :private_id,
                :offer_audio?,
                :offer_video?,
                :offer_data?,
                :simulcast_substream,
                :simulcast_temporal_layer,
                :spatial_layer,
                :temporal_layer,
                close_pc_on_leave?: true,
                relay_audio?: true,
                relay_video?: true,
                relay_data?: true,
                fallback_time_us: 250_000
              ]

  @struct_to_janus_keys %{
    :room_id => :room,
    :feed_id => :feed,
    :close_pc_on_leave? => :close_pc,
    :relay_audio? => :audio,
    :relay_video? => :video,
    :relay_data? => :data,
    :offer_audio? => :offer_audio,
    :offer_video? => :offer_video,
    :offer_data? => :offer_data,
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
