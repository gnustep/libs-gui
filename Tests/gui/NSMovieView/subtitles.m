#import "Testing.h"
#import "../../../Source/config.h"
#ifdef HAVE_LIBAVCODEC_AVCODEC_H
#import "../../../Source/GSAudioPlayer.h"

static void
submit(GSAudioPlayer *player, int stream, int64_t pts, const char *text)
{
  AVPacket *packet = av_packet_alloc();
  av_new_packet(packet, strlen(text));
  memcpy(packet->data, text, strlen(text));
  packet->stream_index = stream;
  packet->pts = pts;
  packet->duration = 2000;
  [player submitSubtitlePacket: packet];
  av_packet_free(&packet);
}
#endif

int main(void)
{
  START_SET("Movie subtitles")
#ifdef HAVE_LIBAVCODEC_AVCODEC_H
  AVFormatContext *format = avformat_alloc_context();
  AVStream *stream = avformat_new_stream(format, NULL);
  stream->codecpar->codec_type = AVMEDIA_TYPE_SUBTITLE;
  stream->codecpar->codec_id = AV_CODEC_ID_SUBRIP;
  stream->time_base = (AVRational){1, 1000};
  av_dict_set(&stream->metadata, "language", "eng", 0);
  AVStream *bitmap = avformat_new_stream(format, NULL);
  bitmap->codecpar->codec_type = AVMEDIA_TYPE_SUBTITLE;
  bitmap->codecpar->codec_id = AV_CODEC_ID_DVD_SUBTITLE;
  GSAudioPlayer *player = [GSAudioPlayer new];
  [player prepareSubtitlesWithFormatContext: format];
  PASS([player subtitleStreamIndex] == -1, "subtitles default to off");
  NSArray *tracks = [player subtitleStreams];
  PASS([tracks count] == 1 && [[tracks[0] objectForKey: @"language"] isEqual: @"eng"],
    "only supported text tracks are listed, with language metadata");
  PASS([player setSubtitleStreamIndex: 0], "select a text track");
  PASS(![player setSubtitleStreamIndex: 1] && [player subtitleStreamIndex] == 0,
    "reject bitmap tracks without disturbing selection");
  PASS(![player setSubtitleStreamIndex: 99], "reject invalid stream index");
  submit(player, 0, 1000, "Hello, world\nSecond line");
  PASS([[player subtitleTextAtTime: 999999] length] == 0, "cue is hidden before start");
  PASS([[player subtitleTextAtTime: 1000000] isEqual: @"Hello, world\nSecond line"],
    "decode SRT/ASS text preserving commas and line breaks");
  submit(player, 0, 2000, "Overlap");
  PASS([[player subtitleTextAtTime: 2000000] isEqual: @"Hello, world\nSecond line\nOverlap"],
    "overlapping cues are displayed together");
  PASS([[player subtitleTextAtTime: 3000000] isEqual: @"Overlap"], "cue end is exclusive");
  PASS([[player subtitleTextAtTime: 4000000] length] == 0,
    "all expired cues disappear");
  submit(player, 0, 5000, "Pending");
  [player seekToTime: 0];
  PASS([[player subtitleTextAtTime: 5000000] length] == 0, "seek clears queued cues");
  submit(player, 0, 1000, "Again");
  [player setSubtitleStreamIndex: -1];
  PASS([[player subtitleTextAtTime: 1000000] length] == 0, "disabling clears cues");
  submit(player, 0, 1000, "Disabled");
  PASS([[player subtitleTextAtTime: 1000000] length] == 0,
    "packets are ignored while disabled");
  [player setSubtitleStreamIndex: 0];
  submit(player, 1, 1000, "Wrong stream");
  PASS([[player subtitleTextAtTime: 1000000] length] == 0,
    "packets from unselected streams are ignored");
  submit(player, 0, 1000, "<i>Styled</i>");
  PASS([[player subtitleTextAtTime: 1000000] isEqual: @"Styled"],
    "ASS override styling is flattened to text");
  [player prepareSubtitlesWithFormatContext: NULL];
  PASS([[player subtitleStreams] count] == 0, "detach clears track metadata");
  [player release];
  avformat_free_context(format);
#else
  SKIP("FFmpeg support is not configured")
#endif
  END_SET("Movie subtitles")
  return 0;
}
