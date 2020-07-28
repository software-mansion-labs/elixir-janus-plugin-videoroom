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

  @admin_key :admin_key
  @secret_key :secret

  @no_such_room_error 426
  @room_already_exists_error 427
  @no_such_feed_error 428

  def create_room(
        connection,
        room_id,
        room_properties,
        session_id,
        handle_id,
        admin_key \\ nil,
        room_secret \\ nil
      ) do
    message =
      configure(room_id, room_properties, session_id, handle_id, admin_key, room_secret, "create")

    case Connection.call(connection, message) do
      {:ok, %{"videoroom" => "created", "room" => id}} ->
        {:ok, id}

      {:ok, %{"error_code" => @room_already_exists_error, "videoroom" => "event"}} ->
        {:error, :already_exists}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def edit(
        connection,
        room_id,
        room_properties,
        session_id,
        handle_id,
        room_secret \\ nil
      ) do
    message = configure(room_id, room_properties, session_id, handle_id, nil, room_secret, "edit")

    with {:ok, %{"videoroom" => "edited", "room" => id}} <- Connection.call(connection, message) do
      {:ok, id}
    else
      {:ok, %{"error" => _message, "error_code" => @no_such_room_error, "videoroom" => "event"}} ->
        {:error, :no_such_room}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp configure(room_id, room_properties, session_id, handle_id, admin_key, room_secret, request) do
    room_properties =
      room_properties
      |> Map.from_struct()
      |> Map.put(@admin_key, admin_key)
      |> Map.put(@secret_key, room_secret)
      |> Enum.filter(fn {_key, value} -> value != nil end)
      |> Enum.into(%{})

    %{
      request: request,
      room: room_id
    }
    |> Map.merge(room_properties)
    |> new_janus_message(session_id, handle_id)
  end

  def destroy(connection, room_id, session_id, handle_id, room_secret \\ nil) do
    message =
      %{room: room_id, request: "destroy"}
      |> put_if_not_nil(@secret_key, room_secret)
      |> new_janus_message(session_id, handle_id)

    with {:ok, %{"videoroom" => "destroyed", "room" => id}} <-
           Connection.call(connection, message) do
      {:ok, id}
    else
      {:ok, %{"error" => _message, "error_code" => @no_such_room_error, "videoroom" => "event"}} ->
        {:error, :no_such_room}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def exists(connection, room_id, session_id, handle_id) do
    message =
      %{room: room_id, request: "exists"}
      |> new_janus_message(session_id, handle_id)

    with {:ok, %{"videoroom" => "success", "room" => ^room_id, "exists" => exists}} <-
           Connection.call(connection, message) do
      {:ok, exists}
    end
  end

  def list(connection, session_id, handle_id) do
    message =
      %{request: "list"}
      |> new_janus_message(session_id, handle_id)

    with {:ok, %{"videoroom" => "success", "rooms" => rooms}} <-
           Connection.call(connection, message) do
      {:ok, rooms}
    end
  end

  def allowed(
        connection,
        room_id,
        action,
        allowed_list,
        session_id,
        handle_id,
        room_secret \\ nil
      ) do
    message =
      %{request: "allowed", allowed: allowed_list, room: room_id, action: action}
      |> put_if_not_nil(@secret_key, room_secret)
      |> new_janus_message(session_id, handle_id)

    with {:ok,
          %{
            "videoroom" => "success",
            "room" => ^room_id,
            "allowed" => resulting_allowed_list
          }} <- Connection.call(connection, message) do
      {:ok, resulting_allowed_list}
    else
      {:ok, %{"error" => _message, "error_code" => @no_such_room_error, "videoroom" => "event"}} ->
        {:error, :no_such_room}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def kick(connection, room_id, user_id, session_id, handle_id, room_secret \\ nil) do
    message =
      %{request: "kick", id: user_id, room: room_id}
      |> put_if_not_nil(@secret_key, room_secret)
      |> new_janus_message(session_id, handle_id)

    with {:ok, %{"videoroom" => "success"}} <- Connection.call(connection, message) do
      :ok
    else
      {:ok, %{"error" => _message, "error_code" => @no_such_feed_error, "videoroom" => "event"}} ->
        {:error, :no_such_user}

      {:ok, %{"error" => _message, "error_code" => @no_such_room_error, "videoroom" => "event"}} ->
        {:error, :no_such_room}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def list_participants(connection, room_id, session_id, handle_id) do
    message =
      %{request: "listparticipants", room: room_id}
      |> new_janus_message(session_id, handle_id)

    with {:ok,
          %{
            "videoroom" => "participants",
            room: ^room_id,
            participants: participants
          }} <-
           Connection.call(connection, message) do
      {:ok, participants}
    else
      {:ok, %{"error" => _message, "error_code" => @no_such_room_error, "videoroom" => "event"}} ->
        {:error, :no_such_room}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp new_janus_message(body, session_id, handle_id) do
    %{
      janus: "message",
      session_id: session_id,
      handle_id: handle_id,
      body: body
    }
  end

  defp put_if_not_nil(map, key, value)
  defp put_if_not_nil(map, _key, nil), do: map
  defp put_if_not_nil(map, key, value), do: Map.put(map, key, value)
end
