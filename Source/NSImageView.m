/*
   NSImageView.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: January 1998
   
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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <AppKit/NSImageView.h>

@implementation NSImageView

- (void)setImage:(NSImage *)image
{
}

- (void)setImageAlignment:(NSImageAlignment)align
{
}

- (void)setImageScaling:(NSImageScaling)scaling
{
}

- (void)setImageFrameStyle:(NSImageFrameStyle)style
{
}

- (void)setEditable:(BOOL)flag
{
}

- (NSImage *)image			{ return nil; }
- (NSImageAlignment)imageAlignment	{ return 0; }
- (NSImageScaling)imageScaling		{ return 0; }
- (NSImageFrameStyle)imageFrameStyle	{ return 0; }
- (BOOL)isEditable			{ return 0; }

@end
