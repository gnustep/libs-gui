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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <string.h>

#import <AppKit/NSActionCell.h>
#include <extensions/GMArchiver.h>
#include <extensions/objc-runtime.h>
#include "AppKit/IMCustomObject.h"
#include "IMConnectors.h"

static void
object_set_instance_variable (id anObject,
			      const char* variableName,
			      const void* value)
{
  struct objc_class* class;
  struct objc_ivar_list* ivars;
  int i;

  if (!anObject)
    return;

//  NSLog (@"%@: setting ivar '%s' to %x", anObject, variableName, value);
  class = [anObject class];
  ivars = class->ivars;
  if (!ivars)
    return;

  for (i = 0; i < ivars->ivar_count; i++) {
    struct objc_ivar ivar = ivars->ivar_list[i];

    if (ivar.ivar_name && !strcmp (ivar.ivar_name, variableName)) {
      /* We found it! */
      *((void**)(((char*)anObject) + ivar.ivar_offset)) = value;
      break;
    }
  }
}

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

  if ([_source respondsToSelector:@selector(setTarget:)]) {
//    NSLog (@"%@: setting target to %@", _source, _destination);
    [_source setTarget:_destination];
  }
  else
    object_set_instance_variable (_source, "target", [_destination retain]);

  if ([_source respondsToSelector:@selector(setAction:)]) {
//    NSLog (@"%@: setting action to %@",
//	    _source, NSStringFromSelector(action));
    [_source setAction:action];
  }
  else
    object_set_instance_variable (_source, "action", action);
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
    object_set_instance_variable(_source, [label cString], [_destination retain]);
}

@end /* IMOutletConnector */
