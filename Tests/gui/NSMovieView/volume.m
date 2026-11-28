#import "Testing.h"
#import "../../../Source/config.h"
#ifdef HAVE_LIBAVCODEC_AVCODEC_H
#import "../../../Source/GSMovieView.h"
#import "../../../Source/GSAudioPlayer.h"

/* Exercise the real playback and subtitle transitions without media I/O. */
@interface VolumeMovieView : GSMovieView

- (GSAudioPlayer *) audioPlayer;

@end

@implementation VolumeMovieView

- (id) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self != nil)
    {
      _formatCtx = avformat_alloc_context();
      _stream = avformat_new_stream(_formatCtx, NULL);
      _stream->codecpar->codec_type = AVMEDIA_TYPE_SUBTITLE;
      _stream->codecpar->codec_id = AV_CODEC_ID_SUBRIP;
      _stream->time_base = (AVRational){1, 1000};
      _audioStreamIndex = -1;
      [_audioPlayer prepareSubtitlesWithFormatContext: _formatCtx];
    }
  return self;
}

- (GSAudioPlayer *) audioPlayer
{
  return _audioPlayer;
}

- (void) feed
{
}

- (void) videoThreadEntry
{
}

- (BOOL) _seekPlaybackToTimeAfterStop: (int64_t)timestamp
{
  return YES;
}

- (BOOL) seekToTime: (int64_t)timestamp
{
  return YES;
}

@end

static void
checkVolume(VolumeMovieView *view, float volume, BOOL muted)
{
  PASS([view volume] == volume && [view isMuted] == muted,
    "playback transitions preserve the movie view's volume and mute");
  PASS([[view audioPlayer] volume] == volume
    && [[view audioPlayer] isMuted] == muted,
    "playback transitions preserve the audio player's volume and mute");
}

#endif

int
main(void)
{
  START_SET("Movie playback volume")
#ifdef HAVE_LIBAVCODEC_AVCODEC_H
  VolumeMovieView *view = [[VolumeMovieView alloc]
    initWithFrame: NSMakeRect(0, 0, 320, 240)];
  unsigned int i;

  for (i = 0; i < 3; i++)
    {
      float volume = i == 2 ? 0.0 : 0.25;
      BOOL muted = i != 0;

      [view setVolume: volume];
      [view setMuted: muted];
      [view start: nil];
      checkVolume(view, volume, muted);
      PASS([view setSubtitleStreamIndex: 0], "enable subtitles during playback");
      checkVolume(view, volume, muted);
      PASS([view setSubtitleStreamIndex: -1], "disable subtitles during playback");
      checkVolume(view, volume, muted);
      [view stop: nil];
      [view start: nil];
      checkVolume(view, volume, muted);
      [view stop: nil];
    }
  RELEASE(view);
#else
  SKIP("FFmpeg support is not configured")
#endif
  END_SET("Movie playback volume")
  return 0;
}
