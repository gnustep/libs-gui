/** <title>NSTableHeaderCell</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
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

#include "AppKit/NSTableHeaderCell.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/DPSOperators.h"

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

  [self  setAlignment: NSCenterTextAlignment];
  ASSIGN (_text_color, [NSColor windowFrameTextColor]);
  [self setBackgroundColor: [NSColor controlShadowColor]];
  [self setFont: [NSFont titleBarFontOfSize: 0]];
  _cell.is_bezeled = YES;
  _textfieldcell_draws_background = YES;

  return self;
}
- (void) drawWithFrame: (NSRect)cellFrame
		inView: (NSView *)controlView
{
  if (NSIsEmptyRect (cellFrame) || ![controlView window])
    return;

  if (_cell.is_highlighted == YES)
    {
      NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			       NSMinXEdge, NSMaxYEdge};
      NSRectEdge down_sides[] = {NSMaxXEdge, NSMaxYEdge, 
				 NSMinXEdge, NSMinYEdge};
      float grays[] = {NSBlack, NSBlack, 
		       NSWhite, NSWhite};
      NSRect rect;
      NSGraphicsContext *ctxt;

      ctxt = GSCurrentContext();

      if (GSWViewIsFlipped(ctxt) == YES)
	{
	  rect = NSDrawTiledRects(cellFrame, NSZeroRect,
				  down_sides, grays, 4);
	}
      else
	{
	  rect = NSDrawTiledRects(cellFrame, NSZeroRect,
				  up_sides, grays, 4);
	}
      
      DPSsetgray(ctxt, NSLightGray);
      DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect),
		  NSWidth(rect), NSHeight(rect));
    }
  else
    {
      NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			       NSMinXEdge, NSMaxYEdge};
      NSRectEdge down_sides[] = {NSMaxXEdge, NSMaxYEdge, 
				 NSMinXEdge, NSMinYEdge};
      float grays[] = {NSBlack, NSBlack, 
		       NSLightGray, NSLightGray};
      NSRect rect;
      NSGraphicsContext *ctxt;
      
      ctxt = GSCurrentContext();

      if (GSWViewIsFlipped(ctxt) == YES)
	{
	  rect = NSDrawTiledRects(cellFrame, NSZeroRect,
				  down_sides, grays, 4);
	}
      else
	{
	  rect = NSDrawTiledRects(cellFrame, NSZeroRect,
				  up_sides, grays, 4);
	}
      
      DPSsetgray(ctxt, NSDarkGray);
      DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect),
		  NSWidth(rect), NSHeight(rect));
    }
  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

- (NSColor *)textColor
{
  if (_cell.is_highlighted)
    {
      return [NSColor controlTextColor];
    }
  else
    {
      return [NSColor windowFrameTextColor];
    }
}

// Override drawInteriorWithFrame:inView: to be able 
// to display images as NSCell does
- (void) drawInteriorWithFrame: (NSRect)cellFrame 
			inView: (NSView*)controlView
{
  switch (_cell.type)
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
      break;
      
    case NSNullCellType:
      break;
    }
}

- (void)setHighlighted: (BOOL) flag
{
  _cell.is_highlighted = flag;
  
  if (flag == YES)
    {
      [self setBackgroundColor: [NSColor controlColor]];
    }
  else
    {
      [self setBackgroundColor: [NSColor controlShadowColor]];
    }
}

@end
