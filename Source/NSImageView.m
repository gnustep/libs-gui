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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include <AppKit/NSDragging.h>
#include <AppKit/NSImageCell.h>
#include <AppKit/NSImageView.h>

/*
 * Class variables
 */
static Class usedCellClass;
static Class imageCellClass;

@implementation NSImageView

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSImageView class])
    {
      [self setVersion: 1];
      imageCellClass = [NSImageCell class];
      usedCellClass = imageCellClass;
    }
}

/*
 * Setting the Cell class
 */
+ (Class) cellClass
{
  return usedCellClass;
}

+ (void) setCellClass: (Class)factoryId
{
  usedCellClass = factoryId ? factoryId : imageCellClass;
}


- (id) init
{
  return [self initWithFrame: NSZeroRect];
}

- (id) initWithFrame: (NSRect)aFrame
{
  [super initWithFrame: aFrame];

  // set the default values
  [self setImageAlignment: NSImageAlignCenter];
  [self setImageFrameStyle: NSImageFrameNone];
  [self setImageScaling: NSScaleProportionally];
  [self setEditable: YES];

  return self;
}

- (void) setImage: (NSImage *)image
{
  [_cell setImage: image];
  [self updateCell: _cell];
}

- (void) setImageAlignment: (NSImageAlignment)align
{
  [_cell setImageAlignment: align];
  [self updateCell: _cell];
}

- (void) setImageScaling: (NSImageScaling)scaling
{
  [_cell setImageScaling: scaling];
  [self updateCell: _cell];
}

- (void) setImageFrameStyle: (NSImageFrameStyle)style
{
  [_cell setImageFrameStyle: style];
  [self updateCell: _cell];
}

- (void) setEditable: (BOOL)flag
{
  [_cell setEditable: flag];
}

- (NSImage *) image
{
  return [_cell image];
}

- (NSImageAlignment) imageAlignment
{
  return [_cell imageAlignment];
}

- (NSImageScaling) imageScaling
{
  return [_cell imageScaling];
}

- (NSImageFrameStyle) imageFrameStyle
{
  return [_cell imageFrameStyle];
}

- (BOOL) isEditable
{
  return [_cell isEditable];
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

