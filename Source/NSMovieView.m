/** <title>NSMovie</title>

   <abstract>Encapsulate a Quicktime movie</abstract>

   Copyright <copy>(C) 2003 Free Software Foundation, Inc.</copy>

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: May 2025
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2003

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#import "config.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSURL.h>

#import "AppKit/NSColor.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSImageRep.h"
#import "AppKit/NSMovie.h"
#import "AppKit/NSMovieView.h"
#import "AppKit/NSPasteboard.h"

#ifdef HAVE_AVCODEC
#import "GSMovieView.h"
#endif

@implementation NSMovieView

#ifdef HAVE_AVCODEC
+ (id) allocWithZone: (NSZone *)zone
{
  if (self == [NSMovieView class])
    {
      return [GSMovieView allocWithZone: zone];
    }
  return [super allocWithZone: zone];
}
#endif

- (instancetype) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self != nil)
    {
      _movie = nil;
      _rate = 1.0;
      _volume = 1.0;
      _flags.muted = NO;
      _flags.loopMode = NSQTMovieNormalPlayback;
      _flags.plays_selection_only = NO;
      _flags.plays_every_frame = YES;
      _flags.is_controller_visible = YES;
      _flags.editable = NO;
    }
  return self;
}

- (void) setMovie: (NSMovie*)movie
{
  ASSIGN(_movie, movie);
}

- (NSMovie*) movie
{
  return _movie;
}

- (IBAction) start: (id)sender
{
}

- (IBAction) stop: (id)sender
{
}

- (BOOL) isPlaying
{
  return NO;
}

- (IBAction) gotoPosterFrame: (id)sender
{
}

- (IBAction) gotoBeginning: (id)sender
{
}

- (IBAction) gotoEnd: (id)sender
{
}

- (IBAction) stepForward: (id)sender
{
}

- (IBAction) stepBack: (id)sender
{
}

- (void) setRate: (float)rate
{
  _rate = rate;
}

- (float) rate
{
  return _rate;
}

- (void) setVolume: (float)volume
{
  _volume = volume;
  if (volume <= 0.0)
    {
      _flags.muted = YES;
    }
  else if (volume > 0.0)
    {
      _flags.muted = NO;
    }
}

- (float) volume
{
  return _volume;
}

- (void) setMuted: (BOOL)mute
{
  _flags.muted = mute;
}

- (BOOL) isMuted
{
  return _flags.muted;
}

- (void) setLoopMode: (NSQTMovieLoopMode)mode
{
  _flags.loopMode = mode;
}

- (NSQTMovieLoopMode) loopMode
{
  return _flags.loopMode;
}

- (void) setPlaysSelectionOnly: (BOOL)flag
{
  _flags.plays_selection_only = flag;
}

- (BOOL) playsSelectionOnly
{
  return _flags.plays_selection_only;
}

- (void) setPlaysEveryFrame: (BOOL)flag
{
  _flags.plays_every_frame = flag;
}

- (BOOL) playsEveryFrame
{
  return _flags.plays_every_frame;
}

- (void) showController: (BOOL)show adjustingSize: (BOOL)adjustSize
{
  _flags.is_controller_visible = show;
}

- (void*) movieController
{
  return NULL;
}

- (BOOL) isControllerVisible
{
  return _flags.is_controller_visible;
}

- (NSRect) movieRect
{
  return [self bounds];
}

- (void) resizeWithMagnification: (float)magnification
{
}

- (NSSize) sizeForMagnification: (float)magnification
{
  return NSMakeSize(0, 0);
}

- (void) setEditable: (BOOL)editable
{
  _flags.editable = editable;
}

- (BOOL) isEditable
{
  return _flags.editable;
}

- (IBAction) cut: (id)sender
{
}

- (IBAction) copy: (id)sender
{
}

- (IBAction) paste: (id)sender
{
}

- (IBAction) clear: (id)sender
{
}

- (IBAction) undo: (id)sender
{
}

- (IBAction) selectAll: (id)sender
{
}

@end
