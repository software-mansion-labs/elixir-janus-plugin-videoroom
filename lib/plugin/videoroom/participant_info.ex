defmodule Janus.Plugin.VideoRoom.ParticipantInfo do
  @moduledoc """
  Struct holding info about Participants.

  Contains following fields:
  - `id` - unique ID of a publisher
  - `display` - display name of active publisher, if any
  - `audio_codec` - audio codec used by a publisher, if any
  - `video_codec` - video codec used by a publisher, if any
  - `simulcast` - `true` if the publisher uses simulcast (VP8 and H.264 only)
  - `talking` - boolean indicating whether the publisher is talking or not (present only if the room is configured to measure audio levels)
  """
  @type t() :: %__MODULE__{
          id: String.t(),
          display_name: String.t(),
          video_codec: String.t(),
          audio_codec: String.t(),
          using_simulcast?: boolean(),
          talking?: boolean()
        }

  @codecs [:opus, :g722, :pcmu, :pcma, :isac32, :isac16] ++ [:vp8, :vp9, :h264, :av1, :h265]
  @codec_mapping @codecs |> Enum.into(%{}, &{to_string(&1), &1})

  @key_mapping %{
    "id" => :id,
    "display" => :display_name,
    "video_codec" => :video_codec,
    "audio_codec" => :audio_codec,
    "simulcast" => :using_simulcast?,
    "talking" => :talking?
  }

  @enforce_keys :id
  defstruct [:id, :display_name, :video_codec, :audio_codec, :using_simulcast?, :talking?]

  @spec from_response(map()) :: t()
  def from_response(response) do
    known_keys = @key_mapping |> Map.keys()

    fields =
      response
      |> Map.take(known_keys)
      |> Bunch.KVEnum.map_keys(fn key -> @key_mapping[key] end)
      |> Enum.map(fn
        {codec_key, codec} when codec_key in [:audio_codec, :video_codec] ->
          {codec_key, Map.get(@codec_mapping, String.downcase(codec), codec)}

        other ->
          other
      end)

    struct!(__MODULE__, fields)
  end
end
