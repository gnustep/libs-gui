/*
   IMConnectors.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: November 1997
   
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

/* These classes were inspired by IBConnectors classes from objcX, "an
   Objective-C class library for a window system". The code was originally
   written by Scott Francis, Paul Kunz, Imran Qureshi and Libing Wang. */

#ifndef _GNUstep_H_IMConnectors
#define _GNUstep_H_IMConnectors

#import <Foundation/NSObject.h>

@interface IMConnector : NSObject
{
  id source;
  id destination;
  NSString* label;
}

- source;
- destination;
- label;
@end

@interface IMControlConnector:IMConnector
- (void)establishConnection;
@end

@interface IMOutletConnector : IMConnector
- (void)establishConnection;
@end

#endif /* _GNUstep_H_IMConnectors */
