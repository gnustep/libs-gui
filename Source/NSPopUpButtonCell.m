/*
   NSPopUpButtonCell.m

   Copyright (C) 1999 Free Software Foundation, Inc.
   
   Author:  Michael Hanni <mhanni@sprintmail.com>
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

#include <gnustep/gui/config.h>  
#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/PSOperators.h>

@implementation NSPopUpButtonCell
+ (void) initialize
{
  if (self == [NSPopUpButtonCell class])
    [self setVersion: 1];
}

- (id)init
{
  return [super init];   
}

- (id)representedObject
{
  if (cell_image)
    {
      return cell_image;
    }

  return contents;
}

- (void) drawWithFrame: (NSRect)cellFrame
                inView: (NSView*)view  
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
  NSColor	*backColor;
  NSImage	*toDraw = nil;
  NSRect rect = cellFrame;
  NSRect arect = cellFrame;
  NSPoint point;

  NSDrawButton(cellFrame, cellFrame);
  
  arect.size.width -= 3;
  arect.size.height -= 3;
  arect.origin.x += 1;
  arect.origin.y += 2;
 
  if (cell_highlighted)
    {
      backColor = [NSColor selectedMenuItemColor];
    }
  else
    {
      backColor = [NSColor controlColor];
    }
  [backColor set];
  NSRectFill(arect);

  if (cell_image)
    {
      NSSize size;
      NSPoint position;

      [cell_image setBackgroundColor: backColor];
      size = [cell_image size];
      position.x = MAX(NSMidX(cellFrame) - (size.width/2.),0.);
      position.y = MAX(NSMidY(cellFrame) - (size.height/2.),0.);
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if ([control_view isFlipped])
	position.y += size.height;
      [cell_image compositeToPoint: position operation: NSCompositeCopy];

      rect.size.width = 5;                         // calc image rect
      rect.size.height = 11;
      rect.origin.x = cellFrame.origin.x + cellFrame.size.width - 8;
      rect.origin.y = cellFrame.origin.y + 3;
    }
  else
    {
      [cell_font set];

      point.y = rect.origin.y + (rect.size.height/2) - 4;
      point.x = rect.origin.x + xDist;
      rect.origin = point;  

      if (cell_highlighted)
	{
	  [[NSColor selectedMenuItemTextColor] set];
	}
      else
	{
	  [[NSColor controlTextColor] set];
	}
  
      // Draw the title.

      DPSmoveto(ctxt, rect.origin.x, rect.origin.y);
      DPSshow(ctxt, [contents cString]);

      rect.size.width = 15;                         // calc image rect
      rect.size.height = cellFrame.size.height;
      rect.origin.x = cellFrame.origin.x + cellFrame.size.width - (6 + 11);
      rect.origin.y = cellFrame.origin.y;
    }

  if ([view isKindOfClass:[NSMenuView class]])
    {
      NSPopUpButton *popb = [[(NSMenuView *)view menu] popupButton];

      if ([[[popb selectedItem] representedObject] isEqual: contents])
        {
          if ([popb pullsDown] == NO)
            toDraw = [NSImage imageNamed:@"common_Nibble"];
          else
            toDraw = [NSImage imageNamed:@"common_3DArrowDown"];
	}
      else if ([[[popb selectedItem] representedObject] isEqual: cell_image])
        {
          if ([popb pullsDown] == NO)
            toDraw = [NSImage imageNamed:@"common_UpAndDownArrowSmall.tiff"];
          else
            toDraw = [NSImage imageNamed:@"common_DownArrowSmall"];
	}
    }
  else if ([view isKindOfClass:[NSPopUpButton class]])
    {
      if ([[[(NSPopUpButton *)view selectedItem] representedObject]
	isEqual: contents])
        {
          if ([(NSPopUpButton *)view pullsDown] == NO)
            toDraw = [NSImage imageNamed:@"common_Nibble"];
          else
            toDraw = [NSImage imageNamed:@"common_3DArrowDown"];
	}
      else if ([[[(NSPopUpButton *)view selectedItem] representedObject] isEqual: cell_image])
        {
          if ([(NSPopUpButton *)view pullsDown] == NO)
            toDraw = [NSImage imageNamed:@"common_UpAndDownArrowSmall"];
          else
            toDraw = [NSImage imageNamed:@"common_DownArrowSmall"];
	}
    }
  if (toDraw != nil)
    {
      NSSize size;
      NSPoint position;

      [toDraw setBackgroundColor: backColor];
      size = [toDraw size];
      position.x = MAX(NSMidX(rect) - (size.width/2.),0.);
      position.y = MAX(NSMidY(rect) - (size.height/2.),0.);
      /*
       * Images are always drawn with their bottom-left corner at the origin
       * so we must adjust the position to take account of a flipped view.
       */
      if ([control_view isFlipped])
	position.y += size.height;
      [toDraw compositeToPoint: position operation: NSCompositeCopy];
    }
}
@end
