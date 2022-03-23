/** <title>NSMovieView</title>

   <abstract>Encapsulate a view for Quicktime movies</abstract>

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

#ifndef _GNUstep_H_NSMovieView
#define _GNUstep_H_NSMovieView
#import <GNUstepBase/GSVersionMacros.h>

#import <AppKit/NSView.h>

@class NSMovie;

typedef enum {
  NSQTMovieNormalPlayback,
  NSQTMovieLoopingPlayback,
  NSQTMovieLoopingBackAndForthPlayback
} NSQTMovieLoopMode;

@interface NSMovieView : NSView
{
  @protected
    NSMovie *_movie;
    CGFloat  _rate;
    CGFloat  _volume;
    struct NSMovieViewFlags {
      unsigned int muted: 1;
      unsigned int loopMode: 3;
      unsigned int plays_selection_only: 1;
      unsigned int plays_every_frame: 1;
      unsigned int is_controller_visible: 1;
      unsigned int editable: 1;
      unsigned int reserved: 24;
    } _flags;
}

/**
 * Set the NSMovie object to play
 */
- (void) setMovie: (NSMovie*)movie;

/**
 * the NSMovie object this view is to display
 */
- (NSMovie*) movie;

/**
 * Start playback
 */
- (void) start: (id)sender;

/**
 * Stop playback
 */
- (void) stop: (id)sender;

/**
 * Returns YES if movie is playing
 */
- (BOOL) isPlaying;

/**
 * Goes to the poster frame for the movie
 */
- (void) gotoPosterFrame: (id)sender;

/**
 * Goes to the beginning of the NSMovie
 */
- (void) gotoBeginning: (id)sender;

/**
 * Goes to the end of the NSMovie
 */
- (void) gotoEnd: (id)sender;

/**
 * Steps one frame forward
 */
- (void) stepForward: (id)sender;

/**
 * Steps one frame backward
 */
- (void) stepBack: (id)sender;

/**
 * A range from 0.0 to 1.0 (or more) determine the rate at which
 * the movie will be played.  More than 1.0 means faster than normal
 */
- (void) setRate: (float)rate;

/**
 * The current rate the movie is being played at
 */
- (float) rate;

/**
 * A range from 0.0 (mute) to 1.0 (full) volume.
 */
- (void) setVolume: (float)volume;

/**
 * Current volume
 */
- (float) volume;

/**
 * Mute the volume
 */
- (void) setMuted: (BOOL)mute;

/**
 * Returns YES if movie is muted
 */
- (BOOL) isMuted;

/**
 * Sets the loop mode
 */
- (void) setLoopMode: (NSQTMovieLoopMode)mode;

/**
 * Returns the loop mode
 */
- (NSQTMovieLoopMode) loopMode;

/**
 * If this flag is true then NSMovieView only plays the selected portion of the movie
 */
- (void) setPlaysSelectionOnly: (BOOL)flag;

/**
 * Returns YES if the view is playing a selection
 */
- (BOOL) playsSelectionOnly;

/**
 * The view plays every single frame in the movie
 */
- (void) setPlaysEveryFrame: (BOOL)flag;

/**
 * Returns YES if the view plays every frame.
 */
- (BOOL) playsEveryFrame;

/**
 * Shows the controller with the play, stop, pause, and slider
 */
- (void) showController: (BOOL)show adjustingSize: (BOOL)adjustSize;

/**
 * Returns the movie controller
 */
- (void*) movieController;

/**
 * Returns YES if the controller is visible
 */
- (BOOL) isControllerVisible;

/**
 * NSRect for the NSMovie
 */
- (NSRect) movieRect;

/**
 * Resizes the view for the given magnification factor
 */
- (void) resizeWithMagnification: (float)magnification;

/**
 * Resizes the view for the given magnification factor, returns NSSize
 */
- (NSSize) sizeForMagnification: (float)magnification;

/**
 * Makes the NSMovieView editable
 */
- (void) setEditable: (BOOL)editable;


/**
 * return YES if editable
 */
- (BOOL) isEditable;

/**
 * Cut existing selection
 */
- (void) cut: (id)sender;

/**
 * Copy existing selection
 */
- (void) copy: (id)sender;

/**
 * Paste info into movie
 */
- (void) paste: (id)sender;

/**
 * Clear existing selection
 */
- (void) clear: (id)sender;

/**
 * Undo previous action
 */
- (void) undo: (id)sender;

/**
 * Select the entire movie
 */
- (void) selectAll: (id)sender;

@end

#endif /* _GNUstep_H_NSMovieView */
