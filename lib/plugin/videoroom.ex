defmodule Janus.Plugin.VideoRoom do
  @moduledoc """
  This module provides an API to manipulate and read properties of Janus Gateway's VideoRoom plugin's rooms.
  """
  alias Janus.Session
  alias Janus.Plugin.VideoRoom.Errors
  alias Janus.Plugin.VideoRoom.{CreateRoomProperties, EditRoomProperties, PublisherConfiguration}

  @admin_key :admin_key
  @room_secret_key :secret

  @type room_id :: String.t()
  @type room :: map
  @type admin_key :: String.t() | nil
  @type room_secret :: String.t() | nil
  @type action :: String.t()
  @type allowed :: list(String.t())

  @type participant :: map

  @type audio_codec :: :opus | :g722 | :pcmu | :pcma | :isac32 | :isac16
  @type video_codec :: :vp8 | :vp9 | :h264 | :av1 | :h265

  @doc """
  Create a new room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - new room's id, if set to nil gateway will create one
  * `room_properties` - struct containing necessary information about room, see `t:Janus.Plugin.VideoRoom.CreateRoomProperties.t/0`
  * `handle_id` - an id of caller's handle
  * `admin_key` - optional admin key if gateway requires it
  """
  @spec create_room(
          Session.t(),
          room_id,
          CreateRoomProperties.t(),
          Session.plugin_handle_id(),
          admin_key
        ) :: {:ok, String.t()} | {:error, any}
  def create_room(
        session,
        room_id,
        room_properties,
        handle_id,
        admin_key \\ nil
      ) do
    room_properties =
      room_properties
      |> Map.update!(:audiocodec, &join_codecs/1)
      |> Map.update!(:videocodec, &join_codecs/1)

    message = room_configuration(room_id, room_properties, handle_id, admin_key, "create")

    with {:ok, %{"videoroom" => "created", "room" => id}} <-
           Session.execute_request(session, message) do
      {:ok, id}
    else
      error -> Errors.handle(error)
    end
  end

  @doc """
  Edits the given room properties.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - an id of targeted room
  * `room_properties` - struct containing room information to be updated, see `t:Janus.Plugin.VideoRoom.EditRoomProperties.t/0`
  * `handle_id` - an id of caller's handle
  * `room_secret` - optional room secret when requested room is protected
  """
  @spec edit(
          Session.t(),
          room_id,
          EditRoomProperties.t(),
          Session.plugin_handle_id(),
          room_secret()
        ) ::
          {:ok, room_id} | {:error, any}
  def edit(
        session,
        room_id,
        room_properties,
        handle_id,
        room_secret \\ nil
      ) do
    message = room_configuration(room_id, room_properties, handle_id, nil, "edit", room_secret)

    with {:ok, %{"videoroom" => "edited", "room" => id}} <-
           Session.execute_request(session, message) do
      {:ok, id}
    else
      error -> Errors.handle(error)
    end
  end

  defp room_configuration(
         room_id,
         room_properties,
         handle_id,
         admin_key,
         request,
         room_secret \\ nil
       ) do
    room_properties =
      room_properties
      |> Map.from_struct()
      |> Map.put(@admin_key, admin_key)
      |> put_if_not_nil(@room_secret_key, room_secret)
      |> Enum.filter(fn {_key, value} -> value != nil end)
      |> Enum.into(%{})

    %{
      request: request,
      room: room_id
    }
    |> Map.merge(room_properties)
    |> new_janus_message(handle_id)
  end

  defp join_codecs(list)
  defp join_codecs(nil), do: nil
  defp join_codecs(list), do: Enum.join(list, ",")

  @doc """
  Destroys the given room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - an id of targeted room
  * `handle_id` - an id of caller's handle
  * `room_secret` - optional room secret when requested room is protected
  """
  @spec destroy(Session.t(), room_id, Session.plugin_handle_id(), room_secret) ::
          {:ok, room_id} | {:error, any}
  def destroy(session, room_id, handle_id, room_secret \\ nil) do
    message =
      %{room: room_id, request: "destroy"}
      |> put_if_not_nil(@room_secret_key, room_secret)
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "destroyed", "room" => id}} <-
           Session.execute_request(session, message) do
      {:ok, id}
    else
      error -> Errors.handle(error)
    end
  end

  @doc """
  Checks if given room exists.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - an id of queried room
  * `handle_id` - an id of caller's handle
  """
  @spec exists(Session.t(), room_id, Session.plugin_handle_id()) ::
          {:ok, boolean} | {:error, any}
  def exists(session, room_id, handle_id) do
    message =
      %{room: room_id, request: "exists"}
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "success", "room" => ^room_id, "exists" => exists}} <-
           Session.execute_request(session, message) do
      {:ok, exists}
    else
      error -> Errors.handle(error)
    end
  end

  @doc """
  Lists all existing rooms.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `handle_id` - an id of caller's handle
  """
  @spec list(Session.t(), Session.plugin_handle_id()) :: {:ok, list(room)} | {:error, any}
  def list(session, handle_id) do
    message =
      %{request: "list"}
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "success", "list" => rooms}} <-
           Session.execute_request(session, message) do
      {:ok, rooms}
    else
      error -> Errors.handle(error)
    end
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
  @spec allowed(
          Session.t(),
          room_id,
          action,
          allowed,
          Session.plugin_handle_id(),
          room_secret
        ) ::
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
      |> put_if_not_nil(@room_secret_key, room_secret)
      |> new_janus_message(handle_id)

    with {:ok,
          %{
            "videoroom" => "success",
            "room" => ^room_id,
            "allowed" => resulting_allowed_list
          }} <- Session.execute_request(session, message) do
      {:ok, resulting_allowed_list}
    else
      error -> Errors.handle(error)
    end
  end

  @doc """
  Kicks the given user out of the room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - id of targeted room
  * `user_id` - id of user to kick
  * `handle_id` - id of caller's handle
  * `room_secret` - optional room secret when requested room is protected
  """
  @spec kick(
          Session.t(),
          room_id,
          user_id :: String.t(),
          Session.plugin_handle_id(),
          room_secret
        ) ::
          :ok | {:error, any}
  def kick(session, room_id, user_id, handle_id, room_secret \\ nil) do
    message =
      %{request: "kick", id: user_id, room: room_id}
      |> put_if_not_nil(@room_secret_key, room_secret)
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "success"}} <- Session.execute_request(session, message) do
      :ok
    else
      error -> Errors.handle(error)
    end
  end

  @doc """
  Lists participants of the given room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - id of targeted room
  * `handle_id` - id of caller's handle
  """
  @spec list_participants(Session.t(), room_id, Session.plugin_handle_id()) ::
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
    else
      error -> Errors.handle(error)
    end
  end

  @doc """
  Joins the room as a participant, that may start publishing after calling `configure/`

  ## Optional fields

  - `:publisher_id` - unique ID for the publisher; optional, will be chosen by the plugin if missing
  - `:display_name`  - name that should be displayed. optional, but recommended
  - `:token` - invitation token, required only if the room has an ACL
  """
  @spec join(Session.t(), room_id(), Session.plugin_handle_id(), keyword()) ::
          nil | {:error, {:invalid_fields, [...]} | {atom, integer, binary}}
  def join(session, room_id, handle_id, optional_fields) do
    {known_fields, invalid_fields} =
      optional_fields |> Keyword.split([:publisher_id, :display_name, :token])

    message =
      known_fields
      |> Bunch.KVEnum.map_keys(fn
        :publisher_id -> :id
        :display_name -> :name
        other -> other
      end)
      |> Map.new()
      |> Map.merge(%{
        request: "join",
        ptype: "publisher",
        room: room_id
      })
      |> new_janus_message(handle_id)

    with [] <- invalid_fields,
         {:ok, %{"videoroom" => "joined", "room" => ^room_id}} <-
           Session.execute_request(session, message) do
    else
      fields when is_list(fields) -> {:error, {:invalid_fields, fields}}
      error -> Errors.handle(error)
    end
  end

  def publish(session, %PublisherConfiguration{} = config, handle_id, sdp_offer) do
    message =
      config
      |> PublisherConfiguration.to_janus_message()
      |> Map.put(:request, "publish")
      |> new_janus_message(handle_id)
      |> Map.put(:jsep, %{type: "offer", sdp: sdp_offer})

    with {:ok, %{"videoroom" => "event", "configured" => "ok", "jsep" => %{"sdp" => sdp}}} <-
           Session.execute_request(session, message) do
      {:ok, sdp}
    else
      error -> Errors.handle(error)
    end
  end

  def configure(session, %PublisherConfiguration{} = config, handle_id) do
    message =
      config
      |> PublisherConfiguration.to_janus_message()
      |> Map.put(:request, "configure")
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "event", "configured" => "ok"}} <-
           Session.execute_request(session, message) do
      :ok
    else
      error -> Errors.handle(error)
    end
  end

  def leave(session, handle_id) do
    request = %{"videoroom" => "event", request: "leave"} |> new_janus_message(handle_id)

    with {:ok, %{"left" => "ok"}} <- Session.execute_request(session, request) do
    else
      error -> Errors.handle(error)
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
