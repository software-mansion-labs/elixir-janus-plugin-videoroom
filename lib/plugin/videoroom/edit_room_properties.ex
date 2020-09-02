defmodule Janus.Plugin.VideoRoom.EditRoomProperties do
  @moduledoc """
  This modules represents structure of properties for room's `edit` request.

  For more information refer to `https://janus.conf.meetecho.com/docs/videoroom.html`.
  """

  defstruct [
    :new_description,
    :new_is_private,
    :new_secret,
    :new_pin,
    :new_require_pvtid,
    :new_bitrate,
    :new_fir_freq,
    :new_publishers,
    :permanent
  ]

  @type t :: %__MODULE__{
          new_description: binary() | nil,
          new_is_private: boolean() | nil,
          new_secret: binary() | nil,
          new_pin: binary() | nil,
          new_require_pvtid: boolean() | nil,
          new_bitrate: integer() | nil,
          new_fir_freq: integer() | nil,
          new_publishers: integer() | nil,
          permanent: boolean() | nil
        }
end
