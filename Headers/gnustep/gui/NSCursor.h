/* 
   NSCursor.h

   Holds an image to use as a cursor

   Copyright (C) 1996 Free Software Foundation, Inc.

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSCursor
#define _GNUstep_H_NSCursor

#include <Foundation/NSCoder.h>

@class NSImage;
@class NSEvent;

@interface NSCursor : NSObject <NSCoding>
{
  // Attributes
  NSImage *cursor_image;
  NSPoint hot_spot;
  BOOL is_set_on_mouse_entered;
  BOOL is_set_on_mouse_exited;

  void *cid;
}

//
// Initializing a New NSCursor Object
//
- (id)initWithImage:(NSImage *)newImage;

//
// Defining the Cursor
//
- (NSPoint)hotSpot;
- (NSImage *)image;
- (void)setHotSpot:(NSPoint)spot;
- (void)setImage:(NSImage *)newImage;

//
// Setting the Cursor
//
+ (void)hide;
+ (void)pop;
+ (void)setHiddenUntilMouseMoves:(BOOL)flag;
+ (BOOL)isHiddenUntilMouseMoves;
+ (void)unhide;
- (BOOL)isSetOnMouseEntered;
- (BOOL)isSetOnMouseExited;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)pop;
- (void)push;
- (void)set;
- (void)setOnMouseEntered:(BOOL)flag;
- (void)setOnMouseExited:(BOOL)flag;

//
// Getting the Cursor
//
+ (NSCursor *)arrowCursor;
+ (NSCursor *)currentCursor;
+ (NSCursor *)IBeamCursor;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

/* Cursor types */
typedef enum {
  GSArrowCursor,
  GSIBeamCursor
} GSCursorTypes;

#endif // _GNUstep_H_NSCursor
