/* 
   NSObjectProtocols.h

   Various informal protocols.

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@gnu.org>
   Date: Jul 1999
   
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

@implementation NSObject (NSDraggingDestination)

//
// Before the Image is Released
//
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
  return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
  return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
}

//
// After the Image is Released
//
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
  return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
  return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
}

@end

@implementation NSObject (NSDraggingSource)

//
// Querying the Source
//
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
  return NSDragOperationNone;
}

- (BOOL)ignoreModifierKeysWhileDragging
{
  return NO;
}

//
// Informing the Source
//
- (void)draggedImage:(NSImage *)image
             beganAt:(NSPoint)screenPoint
{
}

- (void)draggedImage: (NSImage*)image
             endedAt: (NSPoint)screenPoint
           deposited: (BOOL)didDeposit
{
}

@end
