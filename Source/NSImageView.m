/*
   NSImageView.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: January 1998
   Updated by: Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: May 1999
   
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

#include <AppKit/NSDragging.h>
#include <AppKit/NSImageCell.h>
#include <AppKit/NSImageView.h>

@implementation NSImageView

+ (Class) cellClass
{
  return [NSImageCell class];
}

- (id) init
{
  return [self initWithFrame: NSZeroRect];
}

- (id) initWithFrame: (NSRect)aFrame
{
  [super initWithFrame: aFrame];

  // allocate the image cell
  [self setCell: [[NSImageCell alloc] init]];

  // set the default values
  [self setImageAlignment: NSImageAlignCenter];
  [self setImageFrameStyle: NSImageFrameNone];
  [self setImageScaling: NSScaleProportionally];
  [self setEditable: YES];

  return self;
}

- (void) setImage: (NSImage *)image
{
  [[self cell] setImage: image];
}

- (void) setImageAlignment: (NSImageAlignment)align
{
  [[self cell] setImageAlignment: align];
}

- (void) setImageScaling: (NSImageScaling)scaling
{
  [[self cell] setImageScaling: scaling];
}

- (void) setImageFrameStyle: (NSImageFrameStyle)style
{
  [[self cell] setImageFrameStyle: style];
}

- (void) setEditable: (BOOL)flag
{
  [[self cell] setEditable: flag];
}

- (NSImage *) image
{
  return [[self cell] image];
}

- (NSImageAlignment) imageAlignment
{
  return [[self cell] imageAlignment];
}

- (NSImageScaling) imageScaling
{
  return [[self cell] imageScaling];
}

- (NSImageFrameStyle) imageFrameStyle
{
  return [[self cell] imageFrameStyle];
}

- (BOOL) isEditable
{
  return [[self cell] isEditable];
}

@end

@implementation NSImageView (NSDraggingDestination)

- (unsigned int) draggingEntered: (id <NSDraggingInfo>)sender
{
  // FIX - should highlight to show that we are a valid target
  return NSDragOperationNone;
}

- (void) draggingExited: (id <NSDraggingInfo>)sender
{
  // FIX - should remove highlighting
}

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)sender
{
  if ([self isEditable])
    return YES;
  else
    return NO;
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>)sender
{
  // FIX - should copy image data into image cell here
  return NO;
}

- (void) concludeDragOperation: (id <NSDraggingInfo>)sender
{
  // FIX - should update refresh image here
}

@end

