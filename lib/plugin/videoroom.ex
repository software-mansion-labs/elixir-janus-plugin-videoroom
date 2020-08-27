defmodule Janus.Plugin.VideoRoom do
  @moduledoc """
  Provides abstraction layer for communicating with Janus's VideoRoom plugin.
  """
  alias Janus.Session
  alias Janus.Plugin.VideoRoom.Errors

  @admin_key :admin_key
  @secret_key :secret

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

  @type audio_codec :: :opus | :g722 | :pcmu | :pcma | :isac32 | :isac16
  @type video_codec :: :vp8 | :vp9 | :h264 | :av1 | :h265
  @type t :: %__MODULE__{
          description: binary() | nil,
          is_private: boolean() | nil,
          secret: binary() | nil,
          pin: binary() | nil,
          require_pvtid: boolean() | nil,
          publishers: non_neg_integer() | nil,
          bitrate: non_neg_integer() | nil,
          bitrate_cap: boolean() | nil,
          fir_freq: non_neg_integer() | nil,
          audiocodec: list(audio_codec) | nil,
          videocodec: list(video_codec) | nil,
          vp9_profile: binary() | nil,
          h264_profile: binary() | nil,
          opus_fec: boolean() | nil,
          video_svc: boolean() | nil,
          audiolevel_ext: boolean() | nil,
          audiolevel_event: boolean() | nil,
          audio_active_packets: non_neg_integer() | nil,
          # Float between 0 and 127
          # 127 means complete silence
          # 0 loud
          # default is 25
          audio_level_average: float() | nil,
          videoorient_ext: boolean() | nil,
          playoutdelay_ext: boolean() | nil,
          transport_wide_cc_ext: boolean() | nil,
          record: boolean() | nil,
          rec_dir: boolean() | nil,
          lock_record: boolean() | nil,
          notify_joining: boolean() | nil,
          require_e2ee: boolean() | nil
        }

  @type room_id :: String.t()
  @type room :: map
  @type room_properties :: struct
  @type handle_id :: String.t()
  @type admin_key :: String.t() | nil
  @type room_secret :: String.t() | nil
  @type action :: String.t()
  @type allowed :: list(String.t())

  @type participant :: map

  @doc """
  Sends request to create a new room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - new room's id, if set to nil gateway will create one
  * `room_properties` - map containing necessary information about room
  * `handle_id` - an id of caller's handle
  * `admin_key` - optional admin key if gateway requires it
  * `room_secret` - optional room secret when requested room has to be protected
  """
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

    with {:ok, %{"videoroom" => "created", "room" => id}} <-
           Session.execute_request(session, message) do
      {:ok, id}
    end
    |> handle_videoroom_error()
  end

  @doc """
  Sends request to edit given room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - an id of targeted room
  * `room_properties` - map containing room information to be updated
  * `handle_id` - an id of caller's handle
  * `room_secret` - optional room secret when requested room is protected
  """
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
    end
    |> handle_videoroom_error()
  end

  defp configure(room_id, room_properties, handle_id, admin_key, room_secret, request) do
    room_properties =
      room_properties
      |> Map.from_struct()
      |> Map.put(@admin_key, admin_key)
      |> Map.put(@secret_key, room_secret)
      |> Map.update!(:audiocodec, &listify_codec/1)
      |> Map.update!(:videocodec, &listify_codec/1)
      |> Enum.filter(fn {_key, value} -> value != nil end)
      |> Enum.into(%{})

    %{
      request: request,
      room: room_id
    }
    |> Map.merge(room_properties)
    |> new_janus_message(handle_id)
  end

  defp listify_codec(list)
  defp listify_codec(nil), do: nil
  defp listify_codec(list), do: Enum.join(list, ",")

  @doc """
  Sends request to destroy given room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - an id of targeted room
  * `handle_id` - an id of caller's handle
  * `room_secret` - optional room secret when requested room is protected
  """
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
    end
    |> handle_videoroom_error()
  end

  @doc """
  Sends request to check if given room exists.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - an id of queried room
  * `handle_id` - an id of caller's handle
  """
  @spec exists(Janus.Session.t(), room_id, handle_id) :: {:ok, boolean} | {:error, any}
  def exists(session, room_id, handle_id) do
    message =
      %{room: room_id, request: "exists"}
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "success", "room" => ^room_id, "exists" => exists}} <-
           Session.execute_request(session, message) do
      {:ok, exists}
    end
    |> handle_videoroom_error()
  end

  @doc """
  Sends request to list all existing rooms.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `handle_id` - an id of caller's handle
  """
  @spec list(Janus.Session.t(), handle_id) :: {:ok, list(room)} | {:error, any}
  def list(session, handle_id) do
    message =
      %{request: "list"}
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "success", "rooms" => rooms}} <-
           Session.execute_request(session, message) do
      {:ok, rooms}
    end
    |> handle_videoroom_error()
  end

  @doc """
  Sends request to modify list of people allowed into given room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - id of targeted room
  * `action` - one of "enable|disable|add|remove"
  * `allowed` - list of tokens
  * `handle_id` - id of caller's handle
  * `room_secret` - optional room secret when requested room is protected

  ## Returns
  on success returns tuple `{:ok, allowed}` where `allowed` is an updated list of users' tokens allowed into requested room
  """
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
    end
    |> handle_videoroom_error()
  end

  @doc """
  Sends request to kick given user out of the room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - id of targeted room
  * `user_id` - id of user to kick
  * `handle_id` - id of caller's handle
  * `room_secret` - optional room secret when requested room is protected
  """
  @spec kick(Janus.Session.t(), room_id, user_id :: String.t(), handle_id, room_secret) ::
          :ok | {:error, any}
  def kick(session, room_id, user_id, handle_id, room_secret \\ nil) do
    message =
      %{request: "kick", id: user_id, room: room_id}
      |> put_if_not_nil(@secret_key, room_secret)
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "success"}} <- Session.execute_request(session, message) do
      :ok
    end
    |> handle_videoroom_error()
  end

  @doc """
  Sends request to list participants of given room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - id of targeted room
  * `handle_id` - id of caller's handle
  """
  @spec list_participants(Janus.Session.t(), room_id, handle_id) ::
          {:ok, list(participant)} | {:error, any}
  def list_participants(session, room_id, handle_id) do
    message =
      %{request: "listparticipants", room: room_id}
      |> new_janus_message(handle_id)

    with {:ok,
          %{
            "videoroom" => "participants",
            "room" => ^room_id,
            "participants" => participants
          }} <-
           Session.execute_request(session, message) do
      {:ok, participants}
    end
    |> handle_videoroom_error()
  end

  defp new_janus_message(body, handle_id) do
    %{
      janus: "message",
      handle_id: handle_id,
      body: body
    }
  end

  defp handle_videoroom_error({:ok, %{"error" => _message, "error_code" => code, "videoroom" => "event"}}) do
    Errors.error(code)
  end

  defp handle_videoroom_error({:ok, _} = result), do: result
  defp handle_videoroom_error(:ok), do: :ok
  defp handle_videoroom_error({:error, _reason} = error), do: error


  defp put_if_not_nil(map, key, value)
  defp put_if_not_nil(map, _key, nil), do: map
  defp put_if_not_nil(map, key, value), do: Map.put(map, key, value)
end
