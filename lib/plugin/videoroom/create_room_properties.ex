defmodule Janus.Plugin.VideoRoom.CreateRoomProperties do
  @moduledoc """
  This modules represents structure of properties for room's `create` request.
  """

  defstruct [
    :description,
    :is_private,
    :secret,
    :pin,
    :require_pvtid,
    :publishers,
    :bitrate,
    :bitrate_cap,
    :fir_freq,
    :audiocodec,
    :videocodec,
    :vp9_profile,
    :h264_profile,
    :opus_fec,
    :video_svc,
    :audiolevel_ext,
    :audiolevel_event,
    :audio_active_packets,
    :audio_level_average,
    :videoorient_ext,
    :playoutdelay_ext,
    :transport_wide_cc_ext,
    :record,
    :rec_dir,
    :lock_record,
    :notify_joining,
    :require_e2ee
  ]

  @type audio_codec :: :opus | :g722 | :pcmu | :pcma | :isac32 | :isac16
  @type video_codec :: :vp8 | :vp9 | :h264 | :av1 | :h265

  @type t :: %__MODULE__{
          description: binary() | nil,
          is_private: boolean() | nil,
          secret: binary() | nil,
          pin: binary() | nil,
          require_pvtid: boolean() | nil,
          publishers: non_neg_integer() | nil,
          bitrate: non_neg_integer() | nil,
          bitrate_cap: boolean() | nil,
          fir_freq: non_neg_integer() | nil,
          audiocodec: audio_codec | nil,
          videocodec: video_codec | nil,
          vp9_profile: binary() | nil,
          h264_profile: binary() | nil,
          opus_fec: boolean() | nil,
          video_svc: boolean() | nil,
          audiolevel_ext: boolean() | nil,
          audiolevel_event: boolean() | nil,
          audio_active_packets: non_neg_integer() | nil,
          # Float between 0 and 127
          # 127 means complete silence
          # 0 loud
          # default is 25
          audio_level_average: float() | nil,
          videoorient_ext: boolean() | nil,
          playoutdelay_ext: boolean() | nil,
          transport_wide_cc_ext: boolean() | nil,
          record: boolean() | nil,
          rec_dir: boolean() | nil,
          lock_record: boolean() | nil,
          notify_joining: boolean() | nil,
          require_e2ee: boolean() | nil
        }
end
