/* 
   NSDragging.h

   Protocols for drag 'n' drop.

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: 1997
   
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

#ifndef _GNUstep_H_NSDragging
#define _GNUstep_H_NSDragging

#include <Foundation/NSGeometry.h>

@class NSWindow;
@class NSPasteboard;
@class NSImage;

typedef enum _NSDragOperation {
  NSDragOperationNone = 0,
  NSDragOperationCopy = 1,
  NSDragOperationLink = 2,
  NSDragOperationGeneric = 4,
  NSDragOperationPrivate = 8,
  NSDragOperationMove = 16,
  NSDragOperationDelete = 32,
  NSDragOperationAll = 63,
  NSDragOperationEvery = NSDragOperationAll  
} NSDragOperation;

@protocol NSDraggingInfo

//
// Dragging-session Information
//
- (NSWindow *)draggingDestinationWindow;
- (NSPoint)draggingLocation;
- (NSPasteboard *)draggingPasteboard;
- (int)draggingSequenceNumber;
- (id)draggingSource;
- (unsigned int)draggingSourceOperationMask;

//
// Image Information
//
- (NSImage *)draggedImage;
- (NSPoint)draggedImageLocation;

//
// Sliding the Image
//
- (void)slideDraggedImageTo:(NSPoint)screenPoint;

@end

@interface NSObject (NSDraggingDestination)

//
// Before the Image is Released
//
- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender;
- (unsigned int)draggingUpdated:(id <NSDraggingInfo>)sender;
- (void)draggingExited:(id <NSDraggingInfo>)sender;

//
// After the Image is Released
//
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;

#ifndef STRICT_OPENSTEP
- (void)draggingEnded: (id <NSDraggingInfo>)sender;
#endif
@end

@interface NSObject (NSDraggingSource)

//
// Querying the Source
//
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal;
- (BOOL)ignoreModifierKeysWhileDragging;

//
// Informing the Source
//
- (void)draggedImage:(NSImage *)image
             beganAt:(NSPoint)screenPoint;
- (void)draggedImage: (NSImage*)image
             endedAt: (NSPoint)screenPoint
           deposited: (BOOL)didDeposit;

#ifndef STRICT_OPENSTEP
- (void)draggedImage: (NSImage*)image
             endedAt: (NSPoint)screenPoint
	   operation: (NSDragOperation)operation;
- (void)draggedImage: (NSImage*)image
             movedTo: (NSPoint)screenPoint;
#endif 
@end

#endif // _GNUstep_H_NSDragging
