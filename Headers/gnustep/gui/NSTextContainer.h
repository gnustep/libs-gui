/*
   NSTextContainer.h

   Text container for text system

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef _GNUstep_H_NSTextContainer
#define _GNUstep_H_NSTextContainer

#ifdef STRICT_OPENSTEP
#error "The OpenStep specification does not define an NSTextContainer class."
#endif

#import <Foundation/Foundation.h>
#import <AppKit/NSTextView.h>

typedef enum {
  NSLineSweepLeft,
  NSLineSweepRight,
  NSLineSweepDown,
  NSLineSweepUp
} NSLineSweepDirection;

typedef enum {
  NSLineMoveLeft,
  NSLineMoveRight,
  NSLineMoveDown,
  NSLineMoveUp,
  NSLineDoesntMove
} NSLineMovementDirection;

@interface NSTextContainer : NSObject
{
  id _layoutManager;
  id _textView;

  NSRect _containerRect;
  float _lineFragmentPadding;

  BOOL _observingFrameChanges;
  BOOL _widthTracksTextView;
  BOOL _heightTracksTextView;
}

/*
 * Creating an instance
 */
- (id) initWithContainerSize: (NSSize)aSize;

/*
 * Managing text components
 */
- (void) setLayoutManager: (NSLayoutManager *)aLayoutManager;
- (NSLayoutManager *) layoutManager;
- (void) replaceLayoutManager: (NSLayoutManager *)aLayoutManager;
- (void) setTextView: (NSTextView *)aTextView;
- (NSTextView *) textView;

/*
 * Controlling size
 */
- (void) setContainerSize: (NSSize)aSize;
- (NSSize) containerSize;
- (void) setWidthTracksTextView: (BOOL)flag;
- (BOOL) widthTracksTextView;
- (void) setHeightTracksTextView: (BOOL)flag;
- (BOOL) heightTracksTextView;

/*
 * Setting line fragment padding
 */
- (void) setLineFragmentPadding: (float)aFloat;
- (float) lineFragmentPadding;

/*
 * Calculating text layout
 */
- (NSRect) lineFragmentRectForProposedRect: (NSRect)proposedRect
			    sweepDirection: (NSLineSweepDirection)sweepDir
			 movementDirection: (NSLineMovementDirection)moveDir
			     remainingRect: (NSRect *)remainingRect;
- (BOOL) isSimpleRectangularTextContainer;

/*
 * Mouse hit testing
 */
- (BOOL) containsPoint: (NSPoint)aPoint;

@end

#endif /* _GNUstep_H_NSTextContainer */
