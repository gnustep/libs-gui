/* 
   GSContext.m

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

#include <gnustep/gui/config.h>

#include <Foundation/NSString.h> 
#include <Foundation/NSArray.h> 
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSData.h>

#include "AppKit/GSContext.h"


NSZone *_globalGSZone = NULL;					// The memory zone where all 
												// global objects are allocated 
												// from (Contexts are also 
												// allocated from this zone)
//
//  Class variables
//
static Class contextConcreteClass;				// actual class of GSContext's		
static NSMutableArray *contextList;				// list of drawing destinations
static GSContext *_currentGSContext = nil;		// the current context



@implementation GSContext 

//
// Class methods
//
+ (void)initialize
{
	if (self == (contextConcreteClass = [GSContext class]))
		{
		contextList = [[NSMutableArray arrayWithCapacity:2] retain];
		NSDebugLog(@"Initialize GSContext class\n");
		[self setVersion:1];								// Initial version
		}
}

+ (void) setConcreteClass: (Class)c			{ contextConcreteClass = c; }
+ (Class) concreteClass						{ return contextConcreteClass; }

+ allocWithZone: (NSZone*)z
{
	return NSAllocateObject(contextConcreteClass, 0, z);
}

+ contextWithInfo: (NSDictionary *)info;
{
GSContext *context;

	NSAssert(contextConcreteClass, @"Error: No default GSContext is set\n");
	context = [[contextConcreteClass allocWithZone: _globalGSZone] 
							 		 initWithContextInfo: info];
	[context autorelease];

	return context;
}

+ (GSContext *) currentContext			{ return _currentGSContext; }

+ (void) setCurrentContext: (GSContext *)context
{
	_currentGSContext = context;
}

+ (void) destroyContext:(GSContext *) context		// remove context from the
{													// list so that it gets  
	[contextList removeObject: context];			// deallocated with the  
}													// next autorelease pool

//
// Instance methods
//
- init
{
	return [self initWithContextInfo: nil];
}

- initWithContextInfo: (NSDictionary *)info
{													// designated initializer 	
	[super init];									// for GSContext class
	[contextList addObject: self];
	[GSContext setCurrentContext: self];

	if(info)
		context_info = [info retain];

	return self;
}

- (BOOL)isDrawingToScreen
{
	return NO;
}

- (NSMutableData *)mutableData
{
	return context_data;
}

- (void) destroy									// remove self from context
{													// list so that self gets  
	[GSContext destroyContext: self];				// deallocated with the  
}													// next autorelease pool
   
- (void) dealloc
{
	DESTROY(context_data);

	[super dealloc];
}

@end
