/* -*- C++ -*-
   NSSecureTextField.m

   Secure Text field control class for hidden text entry

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Lyndon Tremblay <humasect@coolmail.com>
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

//
// NOTE:
//
// All selecting methods have been overriden to do nothing, I don't know if this
// will hinder overall behavior of the specs, as I have never used the real thing.
//

#include <gnustep/gui/config.h>

#include <AppKit/NSSecureTextField.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSFont.h>

@implementation NSSecureTextField

/*
==============
+initialize
==============
*/
+ (void)initialize
{
  if (self == [NSSecureTextField class]) {
	[self setVersion:1];
	[self setCellClass: [NSSecureTextFieldCell class]];
  }
}

/*
==============
-initWithFrame:
==============
*/
- (id)initWithFrame:(NSRect)frameRect
{
  [super initWithFrame: frameRect];
  [_cell setEchosBullets:YES];

  return self;
}

/*
==============
-isSelectable:
==============
*/
- (BOOL)isSelectable
{
  return NO;
}


@end /* NSSecureTextField */

@implementation NSSecureTextFieldCell

/*
==============
+initialize
==============
*/
+ (void)initialize
{
  if (self == [NSSecureTextFieldCell class])
	[self setVersion:1];
}

/*
==============
-copyWithZone:
==============
*/
- (id)copyWithZone:(NSZone *)zone
{
  //Prevent the cell's text value from being copied.
  NSSecureTextFieldCell *c = [super copyWithZone:zone];
  [c setStringValue:@""];
  [c setEchosBullets:i_echosBullets];
  return c;
}

/*
===============
-echosBullets
===============
*/
- (BOOL)echosBullets
{
  return i_echosBullets;
}

/*
================
+setEchosBullets:
================
*/
- (void)setEchosBullets:(BOOL)flag
{
  i_echosBullets = flag;
}

/*
===============
-setSelectable:
===============
*/
- (void)setSelectable:(BOOL)flag
{
  _cell.is_selectable = NO;
}

/*
=============
-selectText:
=============
*/
- (void)selectText:(id)sender
{
}

/*
===============
-drawInteriorWithFrame:
===============
*/
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
  NSString *string = [self stringValue];
  unsigned length = [string length];



  [self setType:NSNullCellType];
  [super drawInteriorWithFrame:cellFrame inView:controlView];
  [self setType:NSTextCellType];

  if (length && i_echosBullets) {
	NSImage *image = [NSImage imageNamed:@"common_Diamond"];
	NSSize size = [image size];
	NSPoint position;
	float stringWidth;


	stringWidth = [[self font] widthOfString:string];
	switch ([self alignment]) {
	case NSRightTextAlignment:
	  position.x = (NSWidth(cellFrame) - (stringWidth)) - 1;
	  break;
	case NSCenterTextAlignment:
	  position.x = NSMidX(cellFrame) - (stringWidth/2);
	  break;
	default:
	  position.x = 1;
	  break;
	}

	position.y = MAX(NSMidY(cellFrame) - (size.height/2), 0);
	if ([controlView isFlipped])
	  position.y += size.height;

	while (--length) {
	  [image compositeToPoint:position operation:NSCompositeCopy];
	  position.x += size.width+1;
	}
  }
  //[self _drawText:stars inFrame:cellFrame];
}

@end
