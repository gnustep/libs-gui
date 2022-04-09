/** <title>NSMovie</title>

   <abstract>Encapsulate a Quicktime movie</abstract>

   Copyright <copy>(C) 2003 Free Software Foundation, Inc.</copy>

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

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSURL.h>

#import "AppKit/NSMovie.h"
#import "AppKit/NSMovieView.h"
#import "AppKit/NSPasteboard.h"

enum
  {
    MOVIE_SHOULD_PLAY = 1,
    MOVIE_SHOULD_PAUSE
  };

#define BUFFER_SIZE 4096

@interface NSMovie (NSMovieViewPrivate)
- (id<GSVideoSource>) _source;
- (id<GSVideoSink>) _sink;
@end

@implementation NSMovie (NSMovieViewPrivate)
- (id< GSVideoSource >) _source
{
  return _source;
}

- (id< GSVideoSink >) _sink
{
  return _sink;
}
@end

@interface NSMovieView (PrivateMethods)
- (void) _stream;
- (void) _finished: (NSNumber *)finishedPlaying;
@end

@implementation NSMovieView (PrivateMethods)
- (void) _stream
{
  NSUInteger bytesRead;
  BOOL success = NO;
  void *buffer;
  id <GSVideoSink> sink = [[self movie] _sink];
  id <GSVideoSource> source = [[self movie] _source];
  
  // Exit with success = NO if device could not be open.
  if ([sink open])
    {
      // Allocate space for buffer and start writing.
      buffer = NSZoneMalloc(NSDefaultMallocZone(), BUFFER_SIZE);
      do
        {
          do
            {
              // If not MOVIE_SHOULD_PLAY block thread
              [_readLock lockWhenCondition: MOVIE_SHOULD_PLAY];
              if (_shouldStop)
                {
                  [_readLock unlock];
                  break;
                }
              bytesRead = [source readBytes: buffer
                                     length: BUFFER_SIZE];
              [_readLock unlock];
              [_playbackLock lock];
              success = [sink playBytes: buffer length: bytesRead];
              [_playbackLock unlock];
            } while ((!_shouldStop) && (bytesRead > 0) && success);
          
          [source setCurrentTime: 0.0];
        } while (_shouldLoop == YES && _shouldStop == NO);
      
      [sink close];
      NSZoneFree (NSDefaultMallocZone(), buffer);
    }
  
  RETAIN(self);
  [self performSelectorOnMainThread: @selector(_finished:)
                         withObject: [NSNumber numberWithBool: success]
                      waitUntilDone: YES];
  RELEASE(self);
}

- (void) _finished: (NSNumber *)finishedPlaying
{
  DESTROY(_readLock);
  DESTROY(_playbackLock);
}
@end

@implementation NSMovieView

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _movie = nil;
      _rate = 1.0;
      _volume = 1.0;
      
      _flags.muted = NO;
      _flags.loopMode = NSQTMovieNormalPlayback;
      _flags.plays_selection_only = NO;
      _flags.plays_every_frame = YES;
      _flags.is_controller_visible = NO;
      _flags.editable = NO;
      _flags.reserved = 0;
    }
  return self;
}

- (void) setMovie: (NSMovie *)movie
{
  ASSIGN(_movie, movie);

  if (_movie != nil)
    {
      [[movie _sink] setMovieView: self];
    }
}

- (NSMovie*) movie
{
  return _movie;
}

- (void) start: (id)sender
{
  /*
  // If the locks exists this instance is already playing
  if (_readLock != nil && _playbackLock != nil)
    {
      return;
    }
  
  _readLock = [[NSConditionLock alloc] initWithCondition: MOVIE_SHOULD_PAUSE];
  _playbackLock = [[NSLock alloc] init];
  
  if ([_readLock tryLock] != YES)
    {
      return;
    }
  
  _shouldStop = NO;
  [NSThread detachNewThreadSelector: @selector(_stream)
                           toTarget: self
                         withObject: nil];

  [_readLock unlockWithCondition: MOVIE_SHOULD_PLAY];
}

- (void) stop: (id)sender
{
    if (_readLock == nil)
    {
      return;
    }
  
  if ([_readLock tryLock] != YES)
    {
      return;
    }
  _shouldStop = YES;

  // Set to MOVIE_SHOULD_PLAY so that thread isn't blocked.
  [_readLock unlockWithCondition: MOVIE_SHOULD_PLAY];
  */
}

- (BOOL) isPlaying
{
  if (_readLock == nil)
    {
      return NO;
    }
  if ([_readLock condition] == MOVIE_SHOULD_PLAY)
    {
      return YES;
    }
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
