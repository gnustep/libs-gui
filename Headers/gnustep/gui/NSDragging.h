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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSDragging
#define _GNUstep_H_NSDragging

#include <AppKit/stdappkit.h>

@class NSDragOperation;
@class NSWindow;
@class NSPoint;
@class NSPasteBoard;
@class NSImage;

@interface NSObject (NSDraggingDestination)

//
// Before the Image is Released
//
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender;
- (void)draggingExited:(id <NSDraggingInfo>)sender;

//
// After the Image is Released
//
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;

@end

@protocol NSDraggingInfo

//
// Dragging-session Information
//
- (NSWindow *)draggingDestinationWindow;
- (NSPoint)draggingLocation;
- (NSPasteboard *)draggingPasteBoard;
- (int)draggingSequenceNumber;
- (id)draggingSource;
- (NSDragOperation)draggingSourceOperationMask;

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

@interface NSObject (NSDraggingSource)

//
// Querying the Source
//
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal;
- (BOOL)ignoreModifierKeysWhileDragging;

//
// Informing the Source
//
- (void)draggedImage:(NSImage *)image
             beganAt:(NSPoint)screenPoint;
- (void)draggedImage: (NSImage*)image
             endedAt: (NSPoint)screenPoint
           deposited: (BOOL)didDeposit;

@end

#endif // _GNUstep_H_NSDragging
