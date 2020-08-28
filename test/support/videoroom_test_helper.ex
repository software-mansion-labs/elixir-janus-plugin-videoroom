defmodule VideoRoomTest.Helper do
  alias Janus.Plugin.VideoRoom.Errors

  def error_message(error_code, videoroom \\ "event", error \\ "error message") do
    %{
      "error_code" => error_code,
      "videoroom" => videoroom,
      "error" => error
    }
  end

  # macro generating test checking that error returned by session was propagated down
  defmacro test_session_error_propagation(fun, args) do
    quote do
      test "propagate error returned from Session" do
        error = {:error, :session_error}

        with_mock Janus.Session,
          execute_request: fn _, _message ->
            error
          end do
          assert ^error = apply(unquote(fun), unquote(args))
        end
      end
    end
  end

  # macro generating test checking if given function returns proper error
  # when Session returns VideoRoom's plugin error with specified error_code
  defmacro test_videoroom_plugin_error(error, fun, args) do
    quote do
      test "returns an error on plugin's #{unquote(error)} error message" do
        code = Errors.code(unquote(error))

        with_mock Janus.Session,
          execute_request: fn _, _message ->
            {:ok, error_message(code)}
          end do
          assert Errors.error(code) == apply(unquote(fun), unquote(args))
        end
      end
    end
  end
end
