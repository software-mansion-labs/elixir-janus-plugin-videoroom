defmodule Janus.Plugin.VideoRoom.Errors do
  @moduledoc false

  @errors %{
    # code to atom
    421 => :janus_videoroom_error_no_message,
    422 => :janus_videoroom_error_invalid_json,
    423 => :janus_videoroom_error_invalid_request,
    424 => :janus_videoroom_error_join_first,
    425 => :janus_videoroom_error_already_joined,
    426 => :janus_videoroom_error_no_such_room,
    427 => :janus_videoroom_error_room_exists,
    428 => :janus_videoroom_error_no_such_feed,
    429 => :janus_videoroom_error_missing_element,
    430 => :janus_videoroom_error_invalid_element,
    431 => :janus_videoroom_error_invalid_sdp_type,
    432 => :janus_videoroom_error_publishers_full,
    433 => :janus_videoroom_error_unauthorized,
    434 => :janus_videoroom_error_already_published,
    435 => :janus_videoroom_error_not_published,
    436 => :janus_videoroom_error_id_exists,
    437 => :janus_videoroom_error_invalid_sdp,
    499 => :janus_videoroom_error_unknown_error,

    # atom to code
    janus_videoroom_error_no_message: 421,
    janus_videoroom_error_invalid_json: 422,
    janus_videoroom_error_invalid_request: 423,
    janus_videoroom_error_join_first: 424,
    janus_videoroom_error_already_joined: 425,
    janus_videoroom_error_no_such_room: 426,
    janus_videoroom_error_room_exists: 427,
    janus_videoroom_error_no_such_feed: 428,
    janus_videoroom_error_missing_element: 429,
    janus_videoroom_error_invalid_element: 430,
    janus_videoroom_error_invalid_sdp_type: 431,
    janus_videoroom_error_publishers_full: 432,
    janus_videoroom_error_unauthorized: 433,
    janus_videoroom_error_already_published: 434,
    janus_videoroom_error_not_published: 435,
    janus_videoroom_error_id_exists: 436,
    janus_videoroom_error_invalid_sdp: 437,
    janus_videoroom_error_unknown_error: 499
  }

  @spec code(atom()) :: integer()
  def code(error) do
    Map.fetch!(@errors, error)
  end

  @spec handle(any()) :: {:error, {atom(), integer(), String.t()}}
  def handle({:ok, %{"error" => reason, "error_code" => code, "videoroom" => "event"}}) do
    {:error, {Map.get(@errors, code, :unknown_janus_videoroom_error), code, reason}}
  end

  def handle({:error, _reason} = error) do
    error
  end
end
