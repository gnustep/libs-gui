/* 
   NSTableHeaderCell.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Nicola Pero <n.pero@mi.flashnet.it>
   Date: 1999
   
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

#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSImage.h>

// Cache the colors
static NSColor *bgCol;
static NSColor *hbgCol;
static NSColor *clearCol = nil;

@implementation NSTableHeaderCell
{
}
// Default appearance of NSTableHeaderCell
- (id) initTextCell: (NSString *)aString
{
  [super initTextCell: aString];

  _text_align = NSCenterTextAlignment;
  ASSIGN (_text_color, [NSColor windowFrameTextColor]);
  [self setBackgroundColor: [NSColor controlShadowColor]];
  _cell.is_bordered = NO;
  _cell.is_bezeled = NO;
  _draws_background = YES;

  return self;
}
// Override drawInteriorWithFrame:inView: to be able 
// to display images as NSCell does
- (void) drawInteriorWithFrame: (NSRect)cellFrame 
			inView: (NSView*)controlView
{
  switch (_cell_type)
    {
    case NSTextCellType:
      [super drawInteriorWithFrame: cellFrame inView: controlView];
      break;
      
    case NSImageCellType:
      //
      // Taken (with modifications) from NSCell
      //

      // Initialize static colors if needed
      if (clearCol == nil)
	{
	  bgCol = RETAIN([NSColor selectedControlColor]);
	  hbgCol = RETAIN([NSColor controlBackgroundColor]);
	  clearCol = RETAIN([NSColor clearColor]);
	}
      // Prepare to draw
      cellFrame = [self drawingRectForBounds: cellFrame];
      [controlView lockFocus];
      // Deal with the background
      if ([self isOpaque])
	{
	  NSColor *bg;
	  
	  if (_cell.is_highlighted)
	    bg = bgCol;
	  else
	    bg = hbgCol;
	  [bg set];
	  NSRectFill (cellFrame);
	  if (_cell_image)
	    [_cell_image setBackgroundColor: bg];
	}
      else
	{
	  if (_cell_image)
	    [_cell_image setBackgroundColor: clearCol];
	}
      // Draw the image
      if (_cell_image)
	{
	  NSSize size;
	  NSPoint position;
	  
	  size = [_cell_image size];
	  position.x = MAX (NSMidX (cellFrame) - (size.width/2.), 0.);
	  position.y = MAX (NSMidY (cellFrame) - (size.height/2.), 0.);
	  if ([controlView isFlipped])
	    position.y += size.height;
	  [_cell_image compositeToPoint: position operation: NSCompositeCopy];
	}
      // End the drawing
      [controlView unlockFocus];
      break;
      
    case NSNullCellType:
      break;
    }
}
@end
