defmodule Janus.Plugin.VideoRoom.IntegrationTest do
  use ExUnit.Case, async: false

  alias Janus.{Connection, Session}
  alias Janus.Plugin.VideoRoom
  alias Janus.Plugin.VideoRoom.TestFixtures

  @moduletag :integration
  @moduletag capture_log: true

  @test_room_id 4242
  @plugin_admin_key Application.fetch_env!(
                      :elixir_janus_plugin_videoroom,
                      :janus_plugin_admin_key
                    )

  defmodule Handler do
    use Janus.Handler
  end

  setup_all do
    {:ok, connection} =
      Connection.start_link(
        Application.fetch_env!(:elixir_janus_plugin_videoroom, :transport),
        Application.fetch_env!(:elixir_janus_plugin_videoroom, :transport_opts),
        Handler,
        {},
        []
      )

    {:ok, session} = Session.start_link(connection, 5000)
    [session: session]
  end

  setup %{session: session} do
    {:ok, handle} = VideoRoom.new_handle(session)
    VideoRoom.destroy(session, @test_room_id, handle)

    properties = %VideoRoom.CreateRoomProperties{}

    assert {:ok, @test_room_id} =
             VideoRoom.create(session, @test_room_id, properties, handle, @plugin_admin_key)

    on_exit(fn ->
      VideoRoom.destroy(session, @test_room_id, handle)
      VideoRoom.destroy_handle(session, handle)
    end)

    [admin_handle: handle]
  end

  test "happy path", %{session: session} do
    assert {:ok, pub_handle} = VideoRoom.new_handle(session)

    join_config = %VideoRoom.PublisherJoinConfig{
      room_id: @test_room_id
    }

    assert {:ok, %VideoRoom.PublisherJoinedResponse{} = response} =
             VideoRoom.join(session, join_config, pub_handle)

    assert response.room_id == @test_room_id
    publisher_id = response.publisher_id

    publisher_config = %VideoRoom.PublisherConfig{display_name: "pub1"}

    assert {:ok, _sdp_answer} =
             VideoRoom.publish(session, publisher_config, pub_handle, TestFixtures.sdp_offer())

    assert :ok = VideoRoom.end_of_candidates(session, pub_handle)

    publisher_reconfig = %VideoRoom.PublisherConfig{display_name: "Pub1", relay_data?: false}
    assert :ok = VideoRoom.configure_publisher(session, publisher_reconfig, pub_handle)

    assert {:ok, sub_handle} = VideoRoom.new_handle(session)
    assert {:ok, [publisher]} = VideoRoom.list_participants(session, @test_room_id, sub_handle)
    assert publisher.id == publisher_id
    assert publisher.display_name == publisher_reconfig.display_name

    subscribe_config = %VideoRoom.SubscriberJoinConfig{
      room_id: @test_room_id,
      feed_id: publisher_id
    }

    assert {:ok, _sdp_offer} = VideoRoom.subscribe(session, subscribe_config, sub_handle)
    assert :ok = VideoRoom.start_subscription(session, TestFixtures.sdp_answer(), sub_handle)
    assert :ok = VideoRoom.pause(session, sub_handle)
    assert :ok = VideoRoom.resume(session, sub_handle)

    assert :ok = VideoRoom.leave(session, sub_handle)
    assert :ok = VideoRoom.unpublish(session, pub_handle)
    assert :ok = VideoRoom.leave(session, pub_handle)
    assert :ok = VideoRoom.destroy_handle(session, pub_handle)
    assert :ok = VideoRoom.destroy_handle(session, sub_handle)
  end

  test "Publish without join", %{session: session} do
    assert {:ok, pub_handle} = VideoRoom.new_handle(session)
    publisher_config = %VideoRoom.PublisherConfig{display_name: "pub1"}

    # premature publish
    assert {:error, {:janus_videoroom_error_join_first, 424, _description}} =
             VideoRoom.publish(session, publisher_config, pub_handle, TestFixtures.sdp_offer())

    assert :ok = VideoRoom.destroy_handle(session, pub_handle)
  end

  test "record happy path", %{session: session, admin_handle: handle} do
    assert :ok = VideoRoom.enable_recording(session, @test_room_id, true, handle)
    assert :ok = VideoRoom.enable_recording(session, @test_room_id, false, handle)
  end
end
