defmodule Janus.Plugin.VideoRoom.Errors do

  @errors %{
    # code to atom
    426 => :no_such_room,
    427 => :room_already_exists,
    428 => :no_such_feed,
    # atom to code
    :no_such_room => 426,
    :room_already_exists => 427,
    :no_such_feed => 428,
  }

  @spec error(integer()) :: atom()
  def error(code) do
    Map.fetch!(@errors, code)
  end

  @spec code(atom()) :: integer()
  def code(error) do
    Map.fetch!(@errors, error)
  end
end
