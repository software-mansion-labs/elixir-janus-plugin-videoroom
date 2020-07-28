defmodule Janus.Plugin.VideoRoom do
  alias Janus.Connection

  defstruct [
    :description,
    :is_private,
    :secret,
    :pin,
    :require_pvtid,
    :publishers,
    :bitrate,
    :bitrate_cap,
    :fir_freq,
    :audiocodec,
    :videocodec,
    :vp9_profile,
    :h264_profile,
    :opus_fec,
    :video_svc,
    :audiolevel_ext,
    :audiolevel_event,
    :audio_active_packets,
    :audio_level_average,
    :videoorient_ext,
    :playoutdelay_ext,
    :transport_wide_cc_ext,
    :record,
    :rec_dir,
    :lock_record,
    :notify_joining,
    :require_e2ee
  ]

  def create_room(room_name, room_properties, connection, session_id, handle_id, admin_key \\ nil) do
    message = new_room_message(room_name, room_properties, session_id, handle_id, admin_key)

    case Connection.call(connection, message) do
      {:ok, %{"videoroom" => "created", "room" => id}} ->
        {:ok, id}

      {:ok, %{"error_code" => 427, "videoroom" => "event"}} ->
        {:error, :already_exists}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp new_room_message(room_id, room_properties, session_id, handle_id, admin_key) do
    room_properties =
      room_properties
      |> Map.from_struct()
      |> Map.put(:admin_key, admin_key)
      |> Enum.filter(fn {_key, value} -> value != nil end)
      |> Enum.into(%{})

    %{
      janus: "message",
      session_id: session_id,
      handle_id: handle_id,
      body:
        %{
          request: "create",
          room: room_id
        }
        |> Map.merge(room_properties)
    }
  end
end
