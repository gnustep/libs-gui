/* 
   NSNibConnector.h

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@branstorm.co.uk>
   Date: 1999
   
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

#ifndef _GNUstep_H_NSNibConnector
#define _GNUstep_H_NSNibConnector

#ifndef GNUSTEP
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSObject.h>
#endif

@interface NSNibConnector : NSObject <NSCoding>
{
  id		_src;
  id		_dst;
  NSString	*_tag;
}

- (id) destination;
- (void) establishConnection;
- (NSString*) label;
- (void) replaceObject: (id)anObject withObject: (id)anotherObject;
- (id) source;
- (void) setDestination: (id)anObject;
- (void) setLabel: (NSString*)label;
- (void) setSource: (id)anObject;
@end

@interface NSNibControlConnector : NSNibConnector
- (void) establishConnection;
@end

@interface NSNibOutletConnector : NSNibConnector
- (void) establishConnection;
@end

#endif

