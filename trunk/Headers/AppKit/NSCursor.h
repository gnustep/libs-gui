/* 
   NSCursor.h

   Holds an image to use as a cursor

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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
   51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/ 

#ifndef _GNUstep_H_NSCursor
#define _GNUstep_H_NSCursor
#import <GNUstepBase/GSVersionMacros.h>

#import <Foundation/NSGeometry.h>
#import <Foundation/NSObject.h>

@class NSImage;
@class NSEvent;
@class NSColor;

@interface NSCursor : NSObject <NSCoding>
{
  NSImage	*_cursor_image;
  NSPoint	_hot_spot;
  BOOL		_is_set_on_mouse_entered;
  BOOL		_is_set_on_mouse_exited;
  void		*_cid;
}

/*
 * Initializing a New NSCursor Object
 */
- (id) initWithImage: (NSImage *)newImage;
- (id) initWithImage: (NSImage *)newImage
	     hotSpot: (NSPoint)hotSpot;


#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
- (id)initWithImage:(NSImage *)newImage 
foregroundColorHint:(NSColor *)fg 
backgroundColorHint:(NSColor *)bg
	    hotSpot:(NSPoint)hotSpot;
#endif

/*
 * Defining the Cursor
 */
- (NSPoint) hotSpot;
- (NSImage*) image;
#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
- (void) setHotSpot: (NSPoint)spot;
- (void) setImage: (NSImage *)newImage;
#endif

/*
 * Setting the Cursor
 */
+ (void) hide;
+ (void) pop;
+ (void) setHiddenUntilMouseMoves: (BOOL)flag;
+ (BOOL) isHiddenUntilMouseMoves;
+ (void) unhide;
- (BOOL) isSetOnMouseEntered;
- (BOOL) isSetOnMouseExited;
- (void) mouseEntered: (NSEvent*)theEvent;
- (void) mouseExited: (NSEvent*)theEvent;
- (void) pop;
- (void) push;
- (void) set;
- (void) setOnMouseEntered: (BOOL)flag;
- (void) setOnMouseExited: (BOOL)flag;
 
/*
 * Getting the Cursor
 */
+ (NSCursor*) arrowCursor;
+ (NSCursor*) currentCursor;
+ (NSCursor*) IBeamCursor;

#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
+ (NSCursor*) greenArrowCursor;
#endif

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
+ (NSCursor*) closedHandCursor;
+ (NSCursor*) crosshairCursor;
+ (NSCursor*) disappearingItemCursor;
+ (NSCursor*) openHandCursor;
+ (NSCursor*) pointingHandCursor;
+ (NSCursor*) resizeDownCursor;
+ (NSCursor*) resizeLeftCursor;
+ (NSCursor*) resizeLeftRightCursor;
+ (NSCursor*) resizeRightCursor;
+ (NSCursor*) resizeUpCursor;
+ (NSCursor*) resizeUpDownCursor;
#endif

@end

/* Cursor types */
typedef enum {
  GSArrowCursor,
  GSIBeamCursor,
  GSClosedHandCursor,
  GSCrosshairCursor,
  GSDisappearingItemCursor,
  GSOpenHandCursor,
  GSPointingHandCursor,
  GSResizeDownCursor,
  GSResizeLeftCursor,
  GSResizeLeftRightCursor,
  GSResizeRightCursor,
  GSResizeUpCursor,
  GSResizeUpDownCursor,
} GSCursorTypes;

#endif /* _GNUstep_H_NSCursor */
