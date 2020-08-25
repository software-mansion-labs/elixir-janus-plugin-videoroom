defmodule Janus.Plugin.VideoRoom do
  alias Janus.Session

  @admin_key :admin_key
  @secret_key :secret

  @no_such_room_error 426
  @room_already_exists_error 427
  @no_such_feed_error 428

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

  @type room_id :: String.t()
  @type room :: map
  @type room_properties :: struct
  @type handle_id :: String.t()
  @type admin_key :: String.t() | nil
  @type room_secret :: String.t() | nil

  @type action :: String.t()
  @type allowed :: list(String.t())

  @type participant :: map

  @spec create_room(
          Janus.Session.t(),
          room_id,
          room_properties,
          handle_id,
          admin_key,
          room_secret
        ) :: {:ok, String.t()} | {:error, any}
  def create_room(
        session,
        room_id,
        room_properties,
        handle_id,
        admin_key \\ nil,
        room_secret \\ nil
      ) do
    message = configure(room_id, room_properties, handle_id, admin_key, room_secret, "create")

    case Session.execute_request(session, message) do
      {:ok, %{"videoroom" => "created", "room" => id}} ->
        {:ok, id}

      {:ok, %{"error_code" => @room_already_exists_error, "videoroom" => "event"}} ->
        {:error, :already_exists}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec edit(Janus.Session.t(), room_id, room_properties, handle_id, room_secret) ::
          {:ok, room_id} | {:error, any}
  def edit(
        session,
        room_id,
        room_properties,
        handle_id,
        room_secret \\ nil
      ) do
    message = configure(room_id, room_properties, handle_id, nil, room_secret, "edit")

    with {:ok, %{"videoroom" => "edited", "room" => id}} <-
           Session.execute_request(session, message) do
      {:ok, id}
    else
      {:ok, %{"error" => _message, "error_code" => @no_such_room_error, "videoroom" => "event"}} ->
        {:error, :no_such_room}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp configure(room_id, room_properties, handle_id, admin_key, room_secret, request) do
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
    |> new_janus_message(handle_id)
  end

  @spec destroy(Janus.Session.t(), room_id, handle_id, room_secret) ::
          {:ok, room_id} | {:error, any}
  def destroy(session, room_id, handle_id, room_secret \\ nil) do
    message =
      %{room: room_id, request: "destroy"}
      |> put_if_not_nil(@secret_key, room_secret)
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "destroyed", "room" => id}} <-
           Session.execute_request(session, message) do
      {:ok, id}
    else
      {:ok, %{"error" => _message, "error_code" => @no_such_room_error, "videoroom" => "event"}} ->
        {:error, :no_such_room}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec exists(Janus.Session.t(), room_id, handle_id) :: {:ok, boolean} | {:error, any}
  def exists(session, room_id, handle_id) do
    message =
      %{room: room_id, request: "exists"}
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "success", "room" => ^room_id, "exists" => exists}} <-
           Session.execute_request(session, message) do
      {:ok, exists}
    else
      {:error, _reason} = error -> error
    end
  end

  @spec list(Janus.Session.t(), handle_id) :: {:ok, list(room)} | {:error, any}
  def list(session, handle_id) do
    message =
      %{request: "list"}
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "success", "rooms" => rooms}} <-
           Session.execute_request(session, message) do
      {:ok, rooms}
    else
      {:error, _reason} = error -> error
    end
  end

  @spec allowed(Janus.Session.t(), room_id, action, allowed, handle_id, room_secret) ::
          {:ok, allowed} | {:error, any}
  def allowed(
        session,
        room_id,
        action,
        allowed_list,
        handle_id,
        room_secret \\ nil
      ) do
    message =
      %{request: "allowed", allowed: allowed_list, room: room_id, action: action}
      |> put_if_not_nil(@secret_key, room_secret)
      |> new_janus_message(handle_id)

    with {:ok,
          %{
            "videoroom" => "success",
            "room" => ^room_id,
            "allowed" => resulting_allowed_list
          }} <- Session.execute_request(session, message) do
      {:ok, resulting_allowed_list}
    else
      {:ok, %{"error" => _message, "error_code" => @no_such_room_error, "videoroom" => "event"}} ->
        {:error, :no_such_room}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec kick(Janus.Session.t(), room_id, user_id :: String.t(), handle_id, room_secret) ::
          :ok | {:error, any}
  def kick(session, room_id, user_id, handle_id, room_secret \\ nil) do
    message =
      %{request: "kick", id: user_id, room: room_id}
      |> put_if_not_nil(@secret_key, room_secret)
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "success"}} <- Session.execute_request(session, message) do
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

  @spec list_participants(Janus.Session.t(), room_id, handle_id) ::
          {:ok, list(participant)} | {:error, any}
  def list_participants(session, room_id, handle_id) do
    message =
      %{request: "listparticipants", room: room_id}
      |> new_janus_message(handle_id)

    with {:ok,
          %{
            "videoroom" => "participants",
            room: ^room_id,
            participants: participants
          }} <-
           Session.execute_request(session, message) do
      {:ok, participants}
    else
      {:ok, %{"error" => _message, "error_code" => @no_such_room_error, "videoroom" => "event"}} ->
        {:error, :no_such_room}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp new_janus_message(body, handle_id) do
    %{
      janus: "message",
      handle_id: handle_id,
      body: body
    }
  end

  defp put_if_not_nil(map, key, value)
  defp put_if_not_nil(map, _key, nil), do: map
  defp put_if_not_nil(map, key, value), do: Map.put(map, key, value)
end
