/** <title>NSImageView</title>

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

#include "AppKit/NSDragging.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSImageCell.h"
#include "AppKit/NSImageView.h"
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSWindow.h"

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
      [self setVersion: 2];
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
  if (flag)
    {
      [self registerForDraggedTypes: [NSImage imagePasteboardTypes]];
    }
  else
    {
      [self unregisterDraggedTypes];
    }
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
  if (([sender draggingSource] != self) && ([self isEditable]) && 
      ([NSImage canInitWithPasteboard: [sender draggingPasteboard]]))
    {
      [_cell setHighlighted: YES];
      return NSDragOperationCopy;
    }
  else
    {
      return NSDragOperationNone;
    }
}

- (void) draggingExited: (id <NSDraggingInfo>)sender
{
  [_cell setHighlighted: NO];
}

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)sender
{
  if (([sender draggingSource] != self) && ([self isEditable]))
    {
      return YES;
    }
  else
    {
      return NO;
    }
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>)sender
{
  NSImage *image;

  image = [[NSImage alloc] initWithPasteboard: [sender draggingPasteboard]];
  if (image == nil)
    {
      return NO;
    }
  else 
    {
      [self setImage: image];
      [self sendAction: _action to: _target];
      RELEASE(image);
      return YES;
    }
}

- (void) concludeDragOperation: (id <NSDraggingInfo>)sender
{
  [_cell setHighlighted: NO];
}

- (void) mouseDown: (NSEvent*)theEvent
{
  if ([self isEditable])
    {
      NSPasteboard *pboard;
      NSImage *anImage = [self image];

      if (anImage != nil)
        {
	  pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
	  [pboard declareTypes: [NSArray arrayWithObject: NSTIFFPboardType] 
		  owner: self];
	  if ([pboard setData: [anImage TIFFRepresentation]
		      forType: NSTIFFPboardType])
	    {
	      [_window dragImage: anImage
		       at: [theEvent locationInWindow]
		       offset: NSMakeSize(0, 0)
		       event: theEvent
		       pasteboard: pboard
		       source: self
		       slideBack: YES];
	      return;
	    }
	}
    }
  [super mouseDown: theEvent];
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
  return NSDragOperationCopy;
}

//
//  Target and Action
//
//  Target and action are handled by NSImageView itself, not its own cell.
//
- (id) target
{
  return _target;
}

- (void) setTarget: (id)anObject
{
  _target = anObject;
}

- (SEL) action
{
  return _action;
}

- (void) setAction: (SEL)aSelector
{
  _action = aSelector;
}

//
//  NSCoding Protocol
//
- (void) encodeWithCoder: (NSCoder *)aCoder
{
  [super encodeWithCoder: aCoder];
  [aCoder encodeConditionalObject: _target];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_action];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  self = [super initWithCoder: aDecoder];

  if ([aDecoder allowsKeyedCoding])
    {
      //NSArray *dragType = [aDecoder decodeObjectForKey: @"NSDragTypes"];

      if ([aDecoder containsValueForKey: @"NSEditable"])
        {
	  [self setEditable: [aDecoder decodeBoolForKey: @"NSEditable"]];
	}
    }
  else
    {
      if ([aDecoder versionForClassName: @"NSImageView"] >= 2)
	{
	  _target = [aDecoder decodeObject];
	  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_action];
	}
    }
  return self;
}

@end

