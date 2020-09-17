defmodule Janus.Plugin.VideoRoom.PublisherJoinedResponse do
  alias Janus.Plugin.VideoRoom
  alias Janus.Plugin.VideoRoom.ParticipantInfo

  @type t() :: %__MODULE__{
          room_id: VideoRoom.room_id(),
          description: String.t(),
          private_id: String.t(),
          publishers: [ParticipantInfo.t()],
          attendees: [ParticipantInfo.t()] | nil
        }

  defstruct [
    :room_id,
    :description,
    :private_id,
    :publishers,
    :attendees
  ]

  @key_mapping %{
    "room" => :room_id,
    "description" => :description,
    "private_id" => :private_id,
    "publishers" => :publishers,
    "attendees" => :attendees
  }

  @spec from_response(map()) :: t()
  def from_response(response) do
    known_keys = @key_mapping |> Map.keys()

    fields =
      response
      |> Map.take(known_keys)
      |> Bunch.KVEnum.map_keys(fn key -> @key_mapping[key] end)
      |> Enum.map(fn
        {participant_key, participants} when participant_key in [:publishers, :atendees] ->
          {participant_key, Enum.map(participants, &ParticipantInfo.from_response/1)}

        other ->
          other
      end)

    struct!(__MODULE__, fields)
  end
end
