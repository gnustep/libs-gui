#import "Testing.h"
#import <AppKit/NSMovieView.h>

/* NSMovieView playback state: its rate, volume, mute, loop mode and the play
   flags, and their round-trips.  (NSMovieView wraps QuickTime, so these check
   GNUstep's own behaviour.)  These are plain properties and do not need a
   window server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSMovieView *v = AUTORELEASE([[NSMovieView alloc]
    initWithFrame: NSMakeRect(0, 0, 200, 150)]);

  /* defaults */
  PASS([v rate] == 1.0, "the default rate is 1.0");
  PASS([v volume] == 1.0, "the default volume is 1.0");
  PASS([v isMuted] == NO, "playback is not muted by default");
  PASS([v loopMode] == NSQTMovieNormalPlayback,
    "the default loop mode is normal playback");
  PASS([v playsSelectionOnly] == NO,
    "the whole movie plays by default, not just the selection");
  PASS([v playsEveryFrame] == YES, "every frame is played by default");
  PASS([v isEditable] == NO, "a movie view is not editable by default");
  PASS([v isPlaying] == NO, "a new movie view is not playing");
  PASS([v movie] == nil, "a new movie view has no movie");

  /* round-trips */
  [v setRate: 0.5];
  PASS([v rate] == 0.5, "the rate round-trips");
  [v setMuted: YES];
  PASS([v isMuted] == YES, "the mute flag round-trips");
  [v setLoopMode: NSQTMovieLoopingPlayback];
  PASS([v loopMode] == NSQTMovieLoopingPlayback, "the loop mode round-trips");
  [v setPlaysSelectionOnly: YES];
  PASS([v playsSelectionOnly] == YES, "plays-selection-only round-trips");
  [v setPlaysEveryFrame: NO];
  PASS([v playsEveryFrame] == NO, "plays-every-frame round-trips");
  [v setEditable: YES];
  PASS([v isEditable] == YES, "the editable flag round-trips");

  /* setting the volume drives the mute flag */
  [v setVolume: 0.7];
  PASS([v volume] == (float)0.7 && [v isMuted] == NO,
    "a positive volume round-trips and unmutes");
  [v setVolume: 0.0];
  PASS([v volume] == 0.0 && [v isMuted] == YES,
    "a zero volume mutes playback");

  DESTROY(arp);
  return 0;
}
