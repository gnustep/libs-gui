/** <title>NSMovie</title>

   <abstract>Encapsulate a Quicktime movie</abstract>

   Copyright <copy>(C) 2003 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2003

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSURL.h>
#include "AppKit/NSMovie.h"
#include "AppKit/NSMovieView.h"
#include "AppKit/NSPasteboard.h"

@implementation NSMovieView

- (void) setMovie: (NSMovie*)movie
{
  ASSIGN(_movie, movie);
}

- (NSMovie*) movie
{
  return _movie;
}

- (void) start: (id)sender
{
  //FIXME
}

- (void) stop: (id)sender
{
  //FIXME
}

- (BOOL) isPlaying
{
  //FIXME
  return NO;  
}

- (void) gotoPosterFrame: (id)sender;
{
  //FIXME
}

- (void) gotoBeginning: (id)sender;
{
  //FIXME
}

- (void) gotoEnd: (id)sender;
{
  //FIXME
}

- (void) stepForward: (id)sender;
{
  //FIXME
}

- (void) stepBack: (id)sender;
{
  //FIXME
}

- (void) setRate: (float)rate;
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
  //FIXME
  _flags.is_controller_visible = show; 
}

- (void*) movieController
{
  //FIXME
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

- (void) resizeWithMagnification: (float)magnification;
{
  //FIXME
}
- (NSSize) sizeForMagnification: (float)magnification;
{
  //FIXME
  return NSMakeSize(0, 0);
}

- (void) setEditable: (BOOL)editable;
{
  _flags.editable = editable;
}

- (BOOL) isEditable
{
  return _flags.editable;
}

- (void) cut: (id)sender
{
  //FIXME
}

- (void) copy: (id)sender
{
  //FIXME
}

- (void) paste: (id)sender
{
  //FIXME
}

- (void) clear: (id)sender
{
  //FIXME
}

- (void) undo: (id)sender
{
  //FIXME
}

- (void) selectAll: (id)sender
{
  //FIXME
}

@end
