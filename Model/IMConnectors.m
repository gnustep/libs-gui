/*
   IMConnectors.m

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include <string.h>

#include <Foundation/NSObjCRuntime.h>
#import <AppKit/NSActionCell.h>
#include <AppKit/GMArchiver.h>
#include "AppKit/IMCustomObject.h"
#include "IMConnectors.h"

#ifndef GNUSTEP_BASE_LIBRARY
/* Define here so we can compile on OPENSTEP and MacOSX.
although this function will never be used there */
BOOL
GSSetInstanceVariable(id obj, NSString *iVarName, const void *data)
{
}
#endif

@implementation IMConnector

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [archiver encodeObject:source withName:@"source"];
  [archiver encodeObject:destination withName:@"destination"];
  [archiver encodeObject:label withName:@"label"];
}

- (id)initWithModelUnarchiver:(GMUnarchiver*)unarchiver
{
  source = [unarchiver decodeObjectWithName:@"source"];
  destination = [unarchiver decodeObjectWithName:@"destination"];
  label = [unarchiver decodeObjectWithName:@"label"];
  return self;
}

- (id)source			{ return source; }
- (id)destination		{ return destination; }
- (id)label			{ return label; }

@end /* IMConnector */


@implementation IMControlConnector:IMConnector

- (void)establishConnection
{
  id _source = [source nibInstantiate];
  id _destination = [destination nibInstantiate];
  SEL action = NSSelectorFromString (label);

  if ([_source respondsToSelector:@selector(setTarget:)])
    {
//    NSLog (@"%@: setting target to %@", _source, _destination);
      [_source setTarget:_destination];
    }
  else
    {
      [_destination retain];
      GSSetInstanceVariable (_source, @"target", &_destination);
    }

  if ([_source respondsToSelector:@selector(setAction:)])
    {
//    NSLog (@"%@: setting action to %@",
//	    _source, NSStringFromSelector(action));
      [_source setAction:action];
    }
  else
    GSSetInstanceVariable (_source, @"action", &action);
}

@end /* IMControlConnector:IMConnector */


@implementation IMOutletConnector

- (void)establishConnection
{
  id _source = [source nibInstantiate];
  id _destination = [destination nibInstantiate];
  NSString* setMethodName = [[@"set" stringByAppendingString:
				    [label capitalizedString]]
				    stringByAppendingString:@":"];
  SEL setSelector = NSSelectorFromString (setMethodName);

//  NSLog (@"establish connection: source %@, destination %@, label %@",
//	  _source, _destination, label);

  if (setSelector && [_source respondsToSelector:setSelector])
    [_source performSelector:setSelector withObject:_destination];
  else
    {
      [_destination retain];
      GSSetInstanceVariable(_source, label, &_destination);
    }
}

@end /* IMOutletConnector */
