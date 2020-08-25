defmodule VideoRoomTest.Helper do
  alias Janus.Plugin.VideoRoom.Errors

  def error_message(error_code, videoroom \\ "event", error \\ "error message") do
    %{
      "error_code" => error_code,
      "videoroom" => videoroom,
      "error" => error
    }
  end

  defmacro test_connection_error(fun, args) do
    quote do
      test "returns an error on connection error" do
        error = {:error, :important_error}
        with_mock Janus.Session,
          execute_request: fn _, _message ->
            error
          end do
          assert ^error = apply(unquote(fun), unquote(args))
        end
      end
    end
  end

  defmacro test_no_such_room(fun, args) do
    quote do
      test "returns an error when room does not exist" do
        code = Errors.code(:no_such_room)
        with_mock Janus.Session,
          execute_request: fn _, _message ->
            {:ok, error_message(code)}
          end do
          assert {:error, Errors.error(code)} == apply(unquote(fun), unquote(args))
        end
      end
    end
  end
end
