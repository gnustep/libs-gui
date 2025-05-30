/** <title>NSMovieView</title>

   <abstract>Encapsulate a view for Quicktime movies</abstract>

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

#ifndef _GNUstep_H_NSMovieView
#define _GNUstep_H_NSMovieView

#import <AppKit/AppKitDefines.h>
#import <AppKit/NSView.h>

@class NSMovie;

typedef enum {
  NSQTMovieNormalPlayback,
  NSQTMovieLoopingPlayback,
  NSQTMovieLoopingBackAndForthPlayback
} NSQTMovieLoopMode;

APPKIT_EXPORT_CLASS
@interface NSMovieView : NSView
{
  NSMovie* _movie;
  float _rate;
  float _volume;
  BOOL _playing;
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
 * Set the movie to be displayed in the view.
 */
- (void) setMovie: (NSMovie*)movie;

/**
 * Get the current movie displayed in the view.
 */
- (NSMovie*) movie;

/**
 * Start movie playback.
 */
- (IBAction) start: (id)sender;

/**
 * Stop movie playback.
 */
- (IBAction) stop: (id)sender;

/**
 * Check whether the movie is currently playing.
 */
- (BOOL) isPlaying;

/**
 * Go to the movie's poster frame.
 */
- (IBAction) gotoPosterFrame: (id)sender;

/**
 * Move to the beginning of the movie.
 */
- (IBAction) gotoBeginning: (id)sender;

/**
 * Move to the end of the movie.
 */
- (IBAction) gotoEnd: (id)sender;

/**
 * Step forward one frame in the movie.
 */
- (IBAction) stepForward: (id)sender;

/**
 * Step backward one frame in the movie.
 */
- (IBAction) stepBack: (id)sender;

/**
 * Set the playback rate for the movie.
 */
- (void) setRate: (float)rate;

/**
 * Get the current playback rate.
 */
- (float) rate;

/**
 * Set the playback volume.
 */
- (void) setVolume: (float)volume;

/**
 * Get the current playback volume.
 */
- (float) volume;

/**
 * Mute or unmute the playback.
 */
- (void) setMuted: (BOOL)mute;

/**
 * Return whether the playback is muted.
 */
- (BOOL) isMuted;

/**
 * Set the loop mode for playback.
 */
- (void) setLoopMode: (NSQTMovieLoopMode)mode;

/**
 * Get the current loop mode.
 */
- (NSQTMovieLoopMode) loopMode;

/**
 * Set whether only the selected portion should play.
 */
- (void) setPlaysSelectionOnly: (BOOL)flag;

/**
 * Return whether only the selection is played.
 */
- (BOOL) playsSelectionOnly;

/**
 * Set whether to play every frame regardless of timing.
 */
- (void) setPlaysEveryFrame: (BOOL)flag;

/**
 * Return whether every frame is being played.
 */
- (BOOL) playsEveryFrame;

/**
 * Show or hide the movie controller and optionally adjust view size.
 */
- (void) showController: (BOOL)show adjustingSize: (BOOL)adjustSize;

/**
 * Get a pointer to the movie controller.
 */
- (void*) movieController;

/**
 * Check whether the controller is currently visible.
 */
- (BOOL) isControllerVisible;

/**
 * Get the rectangle in which the movie is displayed.
 */
- (NSRect) movieRect;

/**
 * Resize the view based on a magnification factor.
 */
- (void) resizeWithMagnification: (float)magnification;

/**
 * Calculate the size of the view at a given magnification.
 */
- (NSSize) sizeForMagnification: (float)magnification;

/**
 * Set whether the movie view is editable.
 */
- (void) setEditable: (BOOL)editable;

/**
 * Return whether the movie view is editable.
 */
- (BOOL) isEditable;

/**
 * Cut the selected movie content.
 */
- (IBAction) cut: (id)sender;

/**
 * Copy the selected movie content.
 */
- (IBAction) copy: (id)sender;

/**
 * Paste movie content from the pasteboard.
 */
- (IBAction) paste: (id)sender;

/**
 * Clear the selected movie content.
 */
- (IBAction) clear: (id)sender;

/**
 * Undo the last operation.
 */
- (IBAction) undo: (id)sender;

/**
 * Select all content in the movie view.
 */
- (IBAction) selectAll: (id)sender;

@end

#endif /* _GNUstep_H_NSMovieView */
