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
static Class _concreteClass;					// actual class of GSContext		
static NSMutableArray *contextList;				// list of drawing destinations



@implementation GSContext 

//
// Class methods
//
+ (void)initialize
{
	if (self == (_concreteClass = [GSContext class]))
		{
		contextList = [[NSMutableArray arrayWithCapacity:2] retain];
		NSDebugLog(@"Initialize GSContext class\n");
		[self setVersion:1];								// Initial version
		}
}

+ (void) setConcreteClass: (Class)c		{ _concreteClass = c; }
+ (Class) concreteClass					{ return _concreteClass; }

+ allocWithZone: (NSZone*)z
{
	return NSAllocateObject(_concreteClass, 0, z);
}

+ contextWithInfo: (NSDictionary *)info;
{
GSContext *context;

	NSAssert(_concreteClass, @"Error: No concrete GSContext is set\n");
	context = [[_concreteClass allocWithZone: _globalGSZone] 
							   initWithContextInfo: info];
	[context autorelease];

	return context;
}

+ (GSContext *) currentContext			{ return nil;}

+ (void) setCurrentContext: (GSContext *)context
{
	[self subclassResponsibility:_cmd];
}

+ (void) destroyContext:(GSContext *) context		
{													// if concrete class is not 
	if(_concreteClass != [GSContext class])			// a GSContext invoke it's 
		[_concreteClass destroyContext: context];	// equivalent method first
	else
		[self _destroyContext: context];			
}													
													// private method which
+ (void) _destroyContext:(GSContext *) context		// removes context from the
{													// list so that it gets
int top;											// deallocated with the
													// next autorelease pool
	[contextList removeObject: context];			 
													// if not last context set 
	if((top = [contextList count]) > 0)				// next in list as current
		[_concreteClass setCurrentContext:[contextList objectAtIndex:top - 1]];
}													

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
	[_concreteClass setCurrentContext: self];

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
	[_concreteClass destroyContext: self];			// deallocated with the  
}													// next autorelease pool
   
- (void) dealloc
{
	DESTROY(context_data);

	[super dealloc];
}

@end
