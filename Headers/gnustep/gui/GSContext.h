/* 
   GSContext.h

   Abstract superclass for all types of Contexts (drawing destinations).  

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@gnu.org>
   Date: Nov 1998
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Nov 1998
   
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

#ifndef _GSContext_h_INCLUDE
#define _GSContext_h_INCLUDE

#include <Foundation/NSObject.h>
#include <stdarg.h>

@class NSMutableData;
@class NSDictionary;

//
// Backing Store Types
//
typedef enum _NSBackingStoreType {
	NSBackingStoreRetained,
	NSBackingStoreNonretained,
	NSBackingStoreBuffered

} NSBackingStoreType;

//
// Compositing operators
//
typedef enum _NSCompositingOperation {
	NSCompositeClear,
	NSCompositeCopy,
	NSCompositeSourceOver,
	NSCompositeSourceIn,
	NSCompositeSourceOut,
	NSCompositeSourceAtop,
	NSCompositeDataOver,
	NSCompositeDataIn,
	NSCompositeDataOut,
	NSCompositeDataAtop,
	NSCompositeXOR,
	NSCompositePlusDarker,
	NSCompositeHighlight,
	NSCompositePlusLighter

} NSCompositingOperation;

//
// Window ordering
//
typedef enum _NSWindowOrderingMode {
	NSWindowAbove,
	NSWindowBelow,
	NSWindowOut

} NSWindowOrderingMode;



@interface GSContext : NSObject
{
	NSDictionary  *context_info;
	NSMutableData *context_data;
@public
    void *be_reserved;
}

//
// Setting and Identifying the concrete class
//
+ (void) setConcreteClass: (Class)c;
+ (Class) concreteClass;

//
// Setting and Identifying the Current Context
//
+ (GSContext *)currentContext;
+ (void)setCurrentContext:(GSContext *)context;

+ contextWithInfo: (NSDictionary *)info;
- initWithContextInfo: (NSDictionary *)info;

//
// Testing the Drawing Destination
//
- (BOOL)isDrawingToScreen;

//
// Accessing Context Data
//
- (NSMutableData *)mutableData;

//
// Destroy the Context
//
+ (void) destroyContext:(GSContext *) context;
+ (void) _destroyContext:(GSContext *) context;				// private use only		
- (void) destroy;

@end

#endif /* _GSContext_h_INCLUDE */
