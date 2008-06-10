/** <title>NSTableHeaderCell</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: 1999
   
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

#include "AppKit/NSTableHeaderCell.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSFont.h"
#include "GNUstepGUI/GSTheme.h"

@implementation NSTableHeaderCell
{
}

// Default appearance of NSTableHeaderCell
- (id) initTextCell: (NSString *)aString
{
  [super initTextCell: aString];

  [self setAlignment: NSCenterTextAlignment];
  [self setTextColor: [NSColor windowFrameTextColor]];
  [self setBackgroundColor: [NSColor controlShadowColor]];
  [self setDrawsBackground: YES];
  [self setFont: [NSFont titleBarFontOfSize: 0]];
  // This is not exactly true 
  _cell.is_bezeled = YES;
  _cell.is_bordered = NO;

  return self;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  NSSize borderSize;

  // This adjustment must match the drawn border
  borderSize = NSMakeSize(1, 1);

  return NSInsetRect(theRect, borderSize.width, borderSize.height);
}

- (void) _drawBorderAndBackgroundWithFrame: (NSRect)cellFrame 
                                    inView: (NSView*)controlView
{
  if (_cell.is_highlighted == YES)
    {
      [[GSTheme theme] drawButton: cellFrame withClip: cellFrame];
    }
  else
    {
      [[GSTheme theme] drawDarkButton: cellFrame withClip: cellFrame];
    }
}

- (void) setHighlighted: (BOOL)flag
{
  _cell.is_highlighted = flag;
  
  if (flag == YES)
    {
      [self setBackgroundColor: [NSColor controlHighlightColor]];
      [self setTextColor: [NSColor controlTextColor]];
    }
  else
    {
      [self setBackgroundColor: [NSColor controlShadowColor]];
      [self setTextColor: [NSColor windowFrameTextColor]];
    }
}

@end
