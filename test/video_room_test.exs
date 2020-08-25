defmodule Janus.Plugin.VideoRoomTest do
  use ExUnit.Case
  import Mock
  alias Janus.Plugin.VideoRoom

  @id 1
  @room_name "room_name"

  describe "create_room sends create room request through connection" do
    test "returning ok tuple with room id when call succeeds" do
      description = "A room description"

      with_mock Janus.Session,
        execute_request: fn _, message ->
          assert message[:body][:room] == @room_name
          assert message[:body][:description] == description
          {:ok, %{"videoroom" => "created", "room" => @id}}
        end do
        room_props = %VideoRoom{description: description}

        assert {:ok, @id} ==
                 VideoRoom.create_room(Janus.Session, @room_name, room_props,  1, 1)
      end
    end

    test "returning an error when room already_exists" do
      with_mock Janus.Session,
        execute_request: fn _, _message ->
          {:ok, %{"error_code" => 427, "videoroom" => "event"}}
        end do
        assert {:error, :already_exists} ==
                 VideoRoom.create_room(Janus.Session, @room_name, %VideoRoom{}, 1, 1)
      end
    end

    test "returning error when Connection returns an error" do
      error = {:error, :important_error}

      with_mock Janus.Session,
        execute_request: fn _, _message ->
          error
        end do
        assert error ==
                 VideoRoom.create_room(Janus.Session, @room_name, %VideoRoom{}, 1, 1)
      end
    end
  end
end
