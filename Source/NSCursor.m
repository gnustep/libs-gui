/* 
   NSCursor.m

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

#include <AppKit/NSCursor.h>
#include <gnustep/base/Stack.h>

// Class variables
static Stack *gnustep_gui_cursor_stack;
static NSCursor *gnustep_gui_current_cursor;
static BOOL gnustep_gui_hidden_until_move;

@implementation NSCursor

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSCursor class])
    {
      // Initial version
      [self setVersion:1];

      // Initialize class variables
      gnustep_gui_cursor_stack = [[Stack alloc] initWithCapacity: 2];
      gnustep_gui_hidden_until_move = YES;
      gnustep_gui_current_cursor = [NSCursor arrowCursor];
    }
}

//
// Setting the Cursor
//
+ (void)hide
{
}

+ (void)pop
{
  // The object we pop is the current cursor
  if (![gnustep_gui_cursor_stack isEmpty])
    gnustep_gui_current_cursor = [gnustep_gui_cursor_stack popObject];

  // If the stack isn't empty then get the new current cursor
  // Otherwise the cursor will stay the same
  if (![gnustep_gui_cursor_stack isEmpty])
    gnustep_gui_current_cursor = [gnustep_gui_cursor_stack topObject];

  [self currentCursorHasChanged];
}

+ (void)setHiddenUntilMouseMoves:(BOOL)flag
{
  gnustep_gui_hidden_until_move = flag;
}

+ (BOOL)isHiddenUntilMouseMoves
{
  return gnustep_gui_hidden_until_move;
}

+ (void)unhide
{
}

//
// Getting the Cursor
//
+ (NSCursor *)arrowCursor
{
  return nil;
}

+ (NSCursor *)currentCursor
{
  return gnustep_gui_current_cursor;
}

+ (NSCursor *)IBeamCursor
{
  return nil;
}

//
// Instance methods
//

//
// Initializing a New NSCursor Object
//
- init
{
  return [self initWithImage: nil];
}

- (id)initWithImage:(NSImage *)newImage
{
  [super init];

  cursor_image = newImage;
  is_set_on_mouse_entered = NO;
  is_set_on_mouse_exited = NO;

  return self;
}

//
// Defining the Cursor
//
- (NSPoint)hotSpot
{
  return hot_spot;
}

- (NSImage *)image
{
  return cursor_image;
}

- (void)setHotSpot:(NSPoint)spot
{
  hot_spot = spot;
}

- (void)setImage:(NSImage *)newImage
{
  cursor_image = newImage;
}

//
// Setting the Cursor
//
- (BOOL)isSetOnMouseEntered
{
  return is_set_on_mouse_entered;
}

- (BOOL)isSetOnMouseExited
{
  return is_set_on_mouse_exited;
}

// Hmm, how is this mouse entered/exited suppose to work?
// Is it simply what the doc says?
// If the cursor is set when the mouse enters
// then how does it get unset when the mouse exits?
- (void)mouseEntered:(NSEvent *)theEvent
{
  if (is_set_on_mouse_entered)
    [self set];
}

- (void)mouseExited:(NSEvent *)theEvent
{
  if (is_set_on_mouse_exited)
    [self set];
}

- (void)pop
{
  [NSCursor pop];
}

- (void)push
{
  [gnustep_gui_cursor_stack pushObject: self];
  gnustep_gui_current_cursor = self;
  [NSCursor currentCursorHasChanged];
}

- (void)set
{
  gnustep_gui_current_cursor = self;
  [NSCursor currentCursorHasChanged];
}

- (void)setOnMouseEntered:(BOOL)flag
{
  is_set_on_mouse_entered = flag;
}

- (void)setOnMouseExited:(BOOL)flag
{
  is_set_on_mouse_exited = flag;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end

//
// Methods implemented by the backend
//
@implementation NSCursor (GNUstepBackend)

+ (void)currentCursorHasChanged
{}

@end
