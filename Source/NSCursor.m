/* 
   NSCursor.m

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <gnustep/gui/config.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/DPSOperators.h>

// Class variables
static NSMutableArray *gnustep_gui_cursor_stack;
static NSCursor *gnustep_gui_current_cursor;
static BOOL gnustep_gui_hidden_until_move;

@implementation NSCursor

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSCursor class])
    {
      // Initial version
      [self setVersion:1];

      // Initialize class variables
      gnustep_gui_cursor_stack = [[NSMutableArray alloc] initWithCapacity: 2];
      gnustep_gui_hidden_until_move = YES;
      [[self arrowCursor] push];
    }
}

- (void *) _cid
{
  return cid;
}

- (void) _setCid: (void *)id
{
  cid = id;
}

/*
 * Setting the Cursor
 */
+ (void) hide
{
  DPShidecursor(GSCurrentContext());
}

+ (void) pop
{
  /*
   * The object we pop is the current cursor
   */
  if ([gnustep_gui_cursor_stack count] > 1)
    {
      [gnustep_gui_cursor_stack removeLastObject];
      gnustep_gui_current_cursor = [gnustep_gui_cursor_stack lastObject];

      if ([gnustep_gui_current_cursor _cid])
	{
	  DPSsetcursorcolor(GSCurrentContext(), 0, 0, 0, 1, 1, 1, 
	    [gnustep_gui_current_cursor _cid]);
	}
    }
}

+ (void) setHiddenUntilMouseMoves: (BOOL)flag
{
  gnustep_gui_hidden_until_move = flag;
}

+ (BOOL) isHiddenUntilMouseMoves
{
  return gnustep_gui_hidden_until_move;
}

+ (void) unhide
{
  DPSshowcursor(GSCurrentContext());  
}

/*
 * Getting the Cursor
 */
+ (NSCursor*) arrowCursor
{
  void		*c;
  NSCursor	*cur = AUTORELEASE([[NSCursor alloc] initWithImage: nil]);

  DPSstandardcursor(GSCurrentContext(), GSArrowCursor, &c);
  [cur _setCid: c];
  return cur;
}

+ (NSCursor*) currentCursor
{
  return gnustep_gui_current_cursor;
}

+ (NSCursor*) IBeamCursor
{
  void		*c;
  NSCursor	*cur = AUTORELEASE([[NSCursor alloc] initWithImage: nil]);

  DPSstandardcursor(GSCurrentContext(), GSIBeamCursor, &c);
  [cur _setCid: c];
  return cur;
}

/*
 * Initializing a New NSCursor Object
 */
- (id) init
{
  return [self initWithImage: nil hotSpot: NSMakePoint(0,15)];
}

- (id) initWithImage: (NSImage *)newImage
{
  return [self initWithImage: newImage
		     hotSpot: NSMakePoint(0,15)];
}

- (id) initWithImage: (NSImage *)newImage hotSpot: (NSPoint)spot
{
  self = [super init];
  if (self != nil)
    {
      cursor_image = newImage;
      hot_spot = spot;
      is_set_on_mouse_entered = NO;
      is_set_on_mouse_exited = NO;
    }
  return self;
}

/*
 * Defining the Cursor
 */
- (NSPoint) hotSpot
{
  return hot_spot;
}

- (NSImage*) image
{
  return cursor_image;
}

- (void) setHotSpot: (NSPoint)spot
{
  hot_spot = spot;
}

- (void) setImage: (NSImage *)newImage
{
  cursor_image = newImage;
}

/*
 * Setting the Cursor
 */
- (BOOL) isSetOnMouseEntered
{
  return is_set_on_mouse_entered;
}

- (BOOL) isSetOnMouseExited
{
  return is_set_on_mouse_exited;
}

- (void) mouseEntered: (NSEvent*)theEvent
{
  if (is_set_on_mouse_entered == YES)
    {
      [self set];
    }
  else if (is_set_on_mouse_exited == NO)
    {
      /*
       * Undocumented behavior - if a cursor is not set on exit or entry,
       * we assume a push-pop situation instead.
       */
      [self push];
    }
}

- (void) mouseExited: (NSEvent*)theEvent
{
  if (is_set_on_mouse_exited == YES)
    {
      [self set];
    }
  else if (is_set_on_mouse_entered == NO)
    {
      /*
       * Undocumented behavior - if a cursor is not set on exit or entry,
       * we assume a push-pop situation instead.
       */
      [self pop];
    }
}

- (void) pop
{
  [NSCursor pop];
}

- (void) push
{
  [gnustep_gui_cursor_stack addObject: self];
  gnustep_gui_current_cursor = self;
  if (cid)
    {
      DPSsetcursorcolor(GSCurrentContext(), 0, 0, 0, 1, 1, 1, cid);
    }
}

- (void) set
{
  gnustep_gui_current_cursor = self;
  if (cid)
    {
      DPSsetcursorcolor(GSCurrentContext(), 0, 0, 0, 1, 1, 1, cid);
    }
}

- (void) setOnMouseEntered: (BOOL)flag
{
  is_set_on_mouse_entered = flag;
}

- (void) setOnMouseExited: (BOOL)flag
{
  is_set_on_mouse_exited = flag;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  return self;
}

@end
