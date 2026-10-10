/* Implementation of class NSDockTile
   Copyright (C) 2019-2023 Free Software Foundation, Inc.

   By: Gregory John Casamento <greg.casamento@gmail.com>
       Riccardo Mottola <rm@gnu.org>

   Date: Sat Nov 16 21:11:06 EST 2019

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import "AppKit/NSApplication.h"
#import "AppKit/NSDockTile.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSView.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSFont.h"
#import "AppKit/NSStringDrawing.h"
#import "AppKit/NSAttributedString.h"
#import "AppKit/NSBezierPath.h"


#import "GNUstepGUI/GSTheme.h"
#import "GNUstepGUI/GSDisplayServer.h"
#import "GSDockTileBadge.h"
#import "GSIconManager.h"

@interface NSView (GSDockTileAppIcon)
- (void) setImage: (NSImage *)image;
@end

static void
clearDockTileRect(NSSize size)
{
  NSRectFillUsingOperation(NSMakeRect(0, 0, size.width, size.height),
			   NSCompositeClear);
}

void
GSDrawDockTileBadge(NSString *badgeLabel, NSRect tileRect)
{
  NSMutableDictionary *attrs;
  NSPoint textLocation;
  NSRect discRect;
  NSSize discSize;
  NSSize textSize;
  int pad;
  NSBezierPath *p;
  NSPoint point;
  CGFloat radius;
  NSColor *badgeBackColor;
  NSColor *badgeDecorationColor;
  NSColor *badgeTextColor;
  NSString *displayString;
  CGFloat badgeScale;

  if (badgeLabel == nil)
    {
      return;
    }

  badgeBackColor = [[GSTheme theme] badgeBackgroundColor];
  badgeDecorationColor = [[GSTheme theme] badgeDecorationColor];
  badgeTextColor = [[GSTheme theme] badgeTextColor];
  badgeScale = MIN(tileRect.size.width, tileRect.size.height);

  displayString = badgeLabel;
  if ([badgeLabel length] > 5)
    {
      displayString = [NSString stringWithFormat: @"%@\u2026%@",
	[badgeLabel substringToIndex: 2],
	[badgeLabel substringFromIndex: [badgeLabel length] - 2]];
    }

  attrs = [[NSMutableDictionary alloc] init];
  [attrs setObject: [NSFont boldSystemFontOfSize: badgeScale / 5]
	    forKey: NSFontAttributeName];
  [attrs setObject: badgeTextColor
	    forKey: NSForegroundColorAttributeName];

  textSize = [displayString sizeWithAttributes: attrs];

  pad = badgeScale / 10;
  discSize = textSize;
  if (discSize.width < 12)
    {
      discSize.width = 12;
    }
  discSize.height += pad;
  discSize.width += pad;

  discRect = NSMakeRect(NSMaxX(tileRect) - discSize.width,
			NSMaxY(tileRect) - discSize.height,
			discSize.width,
			discSize.height);

  textLocation = NSMakePoint(NSMinX(discRect)
    + (discSize.width - textSize.width) / 2,
    NSMinY(discRect) + (discSize.height - textSize.height) / 2);

  radius = discRect.size.height / 2.0;
  point = discRect.origin;
  point.x += radius;
  point.y += radius - 0.5;

  // left half-circle
  p = [NSBezierPath bezierPath];
  [p appendBezierPathWithArcWithCenter: point
				radius: radius
			    startAngle: 90.0
			      endAngle: 270.0];

  // line to first point and right halfcircle
  point.x += discRect.size.width - discRect.size.height;
  [p appendBezierPathWithArcWithCenter: point
				radius: radius
			    startAngle: 270.0
			      endAngle: 90.0];
  [p closePath];

  [badgeBackColor set];
  [p fill];

  [p setLineWidth: 1.5];
  [badgeDecorationColor set];
  [p stroke];

  [displayString drawAtPoint: textLocation withAttributes: attrs];

  RELEASE(attrs);
}

@implementation NSDockTile

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      GSDisplayServer *server = GSCurrentServer();
      NSSize size = [server iconSize]; 
      
      _size = size;
      _contentView = nil;
      _badgeLabel = nil;
      _owner = nil;
      _showsApplicationBadge = YES;
      _appIconImage = [NSImage imageNamed: @"NSApplicationIcon"];
      RETAIN(_appIconImage);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_contentView);
  RELEASE(_badgeLabel);
  RELEASE(_appIconImage);
  [super dealloc];
}

- (NSView *) contentView
{
  return _contentView;
}

- (void) setContentView: (NSView *)contentView
{
  ASSIGN(_contentView, contentView);
  [self display];
}

- (NSSize) size
{
  return _size;
}

- (id) owner
{
  return _owner;
}

- (void) setOwner: (id)owner
{
  _owner = owner; // weak...
}

- (BOOL) showsApplicationBadge
{
  return _showsApplicationBadge;
}

- (void) setShowsApplicationBadge: (BOOL)flag
{
  _showsApplicationBadge = flag;
  [self display];
}

- (NSString *) badgeLabel
{
  return _badgeLabel;
}

- (void) setBadgeLabel: (NSString *)label
{
  ASSIGNCOPY(_badgeLabel, label);
  [self display];
}

- (void) display
{
  NSImage *image = nil;
  NSEnumerator *iterator;
  NSWindow *window;
  NSView *appIconView;

  [_contentView setNeedsDisplay: YES];
  iterator = [[NSApp windows] objectEnumerator];
  while ((window = [iterator nextObject]) != nil)
    {
      if ([window styleMask] & NSMiniWindowMask)
	{
	  [[window contentView] setNeedsDisplay: YES];
	}
    }

  image = [[NSImage alloc] initWithSize: _size];
  [image lockFocus];
  [self draw];
  [image unlockFocus];

  /* Keep the application's local icon window in sync with the dock tile. */
  appIconView = [[NSApp iconWindow] contentView];
  if (appIconView != nil && [appIconView respondsToSelector: @selector(setImage:)])
    {
      [appIconView setImage: image];
    }

  GSUpdateIconManager(image, _showsApplicationBadge ? _badgeLabel : nil);
  RELEASE(image);
}

- (void)draw
{
  clearDockTileRect(_size);

  if (_contentView != nil
      && _contentView != [[NSApp iconWindow] contentView]
      && [_contentView canDraw])
    {
      [_contentView displayRectIgnoringOpacity: [_contentView bounds]
                                      inContext: [NSGraphicsContext currentContext]];
    }
  else
    {
      NSImage *appIcon = [NSApp applicationIconImage];

      if (appIcon == nil)
	{
	  appIcon = _appIconImage;
	}
      [appIcon drawInRect: NSMakeRect(0, 0, _size.width, _size.height)
	       fromRect: NSZeroRect
	      operation: NSCompositeSourceOver
	       fraction: 1.0];
    }

  if (_showsApplicationBadge && _badgeLabel)
    {
      GSDrawDockTileBadge(_badgeLabel, NSMakeRect(0, 0, _size.width, _size.height));
    }
}

@end
