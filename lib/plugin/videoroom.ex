defmodule Janus.Plugin.VideoRoom do
  @moduledoc """
  This module provides an API to manipulate and read properties of Janus Gateway's VideoRoom plugin's rooms.
  """
  alias Janus.Session
  alias Janus.Plugin.VideoRoom.Errors
  alias Janus.Plugin.VideoRoom.{CreateRoomProperties, EditRoomProperties}

  @admin_key :admin_key
  @room_secret_key :secret

  @type room_id :: String.t()
  @type room :: map
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

    message = configure(room_id, room_properties, handle_id, admin_key, "create")

    with {:ok, %{"videoroom" => "created", "room" => id}} <-
           Session.execute_request(session, message) do
      {:ok, id}
    else
      error ->
        Errors.handle(error)
    end
  end

  @doc """
  Sends request to edit given room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - an id of targeted room
  * `room_properties` - struct containing room information to be updated, see `t:Janus.Plugin.VideoRoom.EditRoomProperties.t/0`
  * `handle_id` - an id of caller's handle
  * `room_secret` - optional room secret when requested room is protected
  """
  @spec edit(
          Janus.Session.t(),
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
    message = configure(room_id, room_properties, handle_id, nil, "edit", room_secret)

    with {:ok, %{"videoroom" => "edited", "room" => id}} <-
           Session.execute_request(session, message) do
      {:ok, id}
    else
      error ->
        Errors.handle(error)
    end
  end

  defp configure(room_id, room_properties, handle_id, admin_key, request, room_secret \\ nil) do
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
  Sends request to destroy given room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - an id of targeted room
  * `handle_id` - an id of caller's handle
  * `room_secret` - optional room secret when requested room is protected
  """
  @spec destroy(Janus.Session.t(), room_id, Session.plugin_handle_id(), room_secret) ::
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
      error ->
        Errors.handle(error)
    end
  end

  @doc """
  Sends request to check if given room exists.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - an id of queried room
  * `handle_id` - an id of caller's handle
  """
  @spec exists(Janus.Session.t(), room_id, Session.plugin_handle_id()) ::
          {:ok, boolean} | {:error, any}
  def exists(session, room_id, handle_id) do
    message =
      %{room: room_id, request: "exists"}
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "success", "room" => ^room_id, "exists" => exists}} <-
           Session.execute_request(session, message) do
      {:ok, exists}
    else
      error ->
        Errors.handle(error)
    end
  end

  @doc """
  Sends request to list all existing rooms.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `handle_id` - an id of caller's handle
  """
  @spec list(Janus.Session.t(), Session.plugin_handle_id()) :: {:ok, list(room)} | {:error, any}
  def list(session, handle_id) do
    message =
      %{request: "list"}
      |> new_janus_message(handle_id)

    with {:ok, %{"videoroom" => "success", "rooms" => rooms}} <-
           Session.execute_request(session, message) do
      {:ok, rooms}
    else
      error ->
        Errors.handle(error)
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
          Janus.Session.t(),
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
      error ->
        Errors.handle(error)
    end
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
  @spec kick(
          Janus.Session.t(),
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
      error ->
        Errors.handle(error)
    end
  end

  @doc """
  Sends request to list participants of given room.

  ## Arguments
  * `session` - valid `Janus.Session` process to send request through
  * `room_id` - id of targeted room
  * `handle_id` - id of caller's handle
  """
  @spec list_participants(Janus.Session.t(), room_id, Session.plugin_handle_id()) ::
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
      error ->
        Errors.handle(error)
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
