defmodule Janus.Plugin.VideoRoom.Errors do
  # TODO: resolve handling errors properly to handle all possible cases

  @errors %{
    # code to atom
    426 => :no_such_room,
    427 => :room_already_exists,
    428 => :no_such_feed,
    # atom to code
    :no_such_room => 426,
    :room_already_exists => 427,
    :no_such_feed => 428
  }

  @spec error(integer()) :: {:error, atom()}
  def error(code) do
    {:error, Map.fetch!(@errors, code)}
  end

  @spec code(atom()) :: integer()
  def code(error) do
    Map.fetch!(@errors, error)
  end

  def handle_videoroom_error(
        {:ok, %{"error" => _message, "error_code" => code, "videoroom" => "event"}}
      ) do
    error(code)
  end

  def handle_videoroom_error({:ok, _} = result), do: result
  def handle_videoroom_error(:ok), do: :ok
  def handle_videoroom_error({:error, _reason} = error), do: error
end
