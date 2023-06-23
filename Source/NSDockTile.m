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
#import "AppKit/NSView.h"
#import "AppKit/NSImage.h"
#import "AppKit/NSImageRep.h"
#import "AppKit/NSCustomImageRep.h"
#import "AppKit/NSFont.h"
#import "AppKit/NSStringDrawing.h"
#import "AppKit/NSAttributedString.h"
#import "AppKit/NSBezierPath.h"

#import "GNUstepGUI/GSDisplayServer.h"

@implementation NSDockTile

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      GSDisplayServer *server = GSCurrentServer();
      NSSize size = [server iconSize]; 
      NSRect rect = NSMakeRect(0,0,size.width,size.height);
      
      _size = size;
      _contentView = [[NSView alloc] initWithFrame: rect];
      _badgeLabel = nil;
      _owner = nil;
      _showsApplicationBadge = YES;
      _appIconImage = [NSImage imageNamed: @"NSApplicationIcon"];
    }
  return self;
}

- (oneway void) release
{
  RELEASE(_contentView);
  RELEASE(_badgeLabel);
  RELEASE(_appIconImage);
  [super release];
}

- (NSView *) contentView
{
  return _contentView;
}

- (void) setContentView: (NSView *)contentView
{
  ASSIGN(_contentView, contentView);
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
}

- (NSString *) badgeLabel
{
  return _badgeLabel;
}

- (void) setBadgeLabel: (NSString *)label
{
  NSImage *tempImage;
  NSImageRep *rep;

  ASSIGNCOPY(_badgeLabel, label);

  tempImage = [[NSImage alloc] initWithSize: [_appIconImage size]];

  rep = [[NSCustomImageRep alloc] initWithDrawSelector: @selector(draw) delegate: self];
  [rep setSize: [_appIconImage size]];
  [tempImage addRepresentation: rep];
  RELEASE(rep);

  [NSApp setApplicationIconImage: tempImage];
}

- (void) display
{
  [_contentView setNeedsDisplay: YES];

  if (_showsApplicationBadge)
    {
    }
}

- (void)draw
{
  NSMutableDictionary *attrs;
  NSPoint text_location;
  NSRect disc_rect;
  NSSize disc_size;
  NSSize textSize;
  int pad;
  NSBezierPath *p;
  NSPoint point;
  CGFloat radius;
  NSSize imageSize;

  if (_showsApplicationBadge && _badgeLabel)
    {
      NSColor *badgeBackColor;
      NSColor *badgeDecorationColor;
      NSColor *badgeTextColor;
      NSString *displayString;

      badgeBackColor = [NSColor redColor];
      badgeDecorationColor = [NSColor lightGrayColor];
      badgeTextColor = [NSColor whiteColor];

      displayString = _badgeLabel;
      if ([_badgeLabel length] > 5)
	displayString = [NSString stringWithFormat:@"%@\u2026%@",[_badgeLabel substringToIndex:2],  [_badgeLabel substringFromIndex:[_badgeLabel  length]-2]];

      [_appIconImage compositeToPoint: NSZeroPoint operation: NSCompositeCopy];

      attrs = [[NSMutableDictionary alloc] init];
      [attrs setObject: [NSFont boldSystemFontOfSize: imageSize.width/5]  forKey: NSFontAttributeName];
      [attrs setObject: badgeTextColor  forKey: NSForegroundColorAttributeName];

      textSize = [displayString sizeWithAttributes: attrs];

      imageSize = [_appIconImage size];
      pad = imageSize.width / 10;
      disc_size = textSize;
      if (disc_size.width < 12)
	disc_size.width = 12;
      disc_size.height += pad;
      disc_size.width += pad;

      disc_rect = NSMakeRect(imageSize.width - disc_size.width,
			     imageSize.height - disc_size.height,
			     disc_size.width,
			     disc_size.height);

      text_location = NSMakePoint(imageSize.width -  disc_size.width + (disc_size.width - textSize.width)/2,
				  imageSize.height - disc_size.height + (disc_size.height - textSize.height)/2);


      radius = disc_rect.size.height / 2.0;
      point = disc_rect.origin;
      point.x += radius;
      point.y += radius - 0.5;

      // left half-circle
      p = [NSBezierPath bezierPath];
      [p appendBezierPathWithArcWithCenter: point
				    radius: radius
				startAngle: 90.0
				  endAngle: 270.0];

      // line to first point and right halfcircle
      point.x += disc_rect.size.width - disc_rect.size.height;
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

      [displayString drawAtPoint: text_location  withAttributes: attrs];

      RELEASE(attrs);
    }
}

@end
