/*
   IBClasses.m

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

#include <stdio.h>

#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <AppKit/GMArchiver.h>

#ifdef __APPLE__
#import <AppKit/NSNibConnector.h>
#import <AppKit/NSNibOutletConnector.h>
#import <AppKit/NSNibControlConnector.h>
#endif

#import "IBClasses.h"
#import "Translator.h"
#import "IMConnectors.h"
#import "AppKit/IMCustomObject.h"

//#define DEBUG

@implementation NSCustomObject (NibToGModel)
- (id)awakeAfterUsingCoder:(NSCoder*)aDecoder
{
#ifdef DEBUG
  NSLog (@"%x awakeAfterUsingCoder NSCustomObject: className = %@, realObject = %@, "
	 @"extension = %@", self, className, realObject, extension);
#endif
  [objects addObject:self];
  return self;
}

- description
{
  return [NSString stringWithFormat:@"className = %@, realObject = %@, extension = %@", className, realObject, extension];
}

- nibInstantiate
{
  return self;
}

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [archiver encodeString:className withName:@"className"];
  if (realObject)
    [archiver encodeObject:realObject withName:@"realObject"];
  if (extension)
    [archiver encodeObject:extension withName:@"extension"];
}

- (Class)classForModelArchiver
{
  return [IMCustomObject class];
}

@end /* NSCustomObject */


@implementation NSCustomView (NibToGModel)

- (id)awakeAfterUsingCoder:(NSCoder*)aDecoder
{
#ifdef DEBUG
  NSLog (@"%x awakeAfterUsingCoder NSCustomView: className = %@, realObject = %@, "
	 @"extension = %@", self, className, realObject, extension);
#endif
  [objects addObject:self];
  return self;
}

- description
{
  return [NSString stringWithFormat:@"className = %@, realObject = %@, extension = %@", className, realObject, extension];
}

- nibInstantiate
{
  return self;
}

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  [archiver encodeString:className withName:@"className"];
  [archiver encodeRect:[self frame] withName:@"frame"];

  if (realObject)
    [archiver encodeObject:realObject withName:@"realObject"];
  if (extension)
    [archiver encodeObject:extension withName:@"extension"];
}

- (Class)classForModelArchiver
{
  return [IMCustomView class];
}

@end

#ifdef __APPLE__
@implementation NSNibConnector (NibToGModel)
#else
@implementation NSIBConnector (NibToGModel)
#endif
- (id)awakeAfterUsingCoder:(NSCoder*)aDecoder
{
#ifdef DEBUG
  NSLog (@"%x awakeAfterUsingCoder %@: source = %@, destination = %@, label = %@",
	  self, NSStringFromClass(isa), source, destination, label);
#endif

#ifdef __APPLE__
  [_source retain];
  [_destination retain];
  [_label retain];
#else
  [source retain];
  [destination retain];
  [label retain];
#endif

  [connections addObject:self];
  return self;
}

- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
#ifdef __APPLE__
  [archiver encodeObject:_source withName:@"source"];
  [archiver encodeObject:_destination withName:@"destination"];
  [archiver encodeObject:_label withName:@"label"];
#else
  [archiver encodeObject:source withName:@"source"];
  [archiver encodeObject:destination withName:@"destination"];
  [archiver encodeObject:label withName:@"label"];
#endif
}

- (Class)classForModelArchiver
{
  return [IMConnector class];
}

@end /* NSIBConnector */

#ifdef __APPLE__
@implementation NSNibOutletConnector (NibToGModel)
#else
@implementation NSIBOutletConnector (NibToGModel)
#endif
- (void)establishConnection
{
}

- (Class)classForModelArchiver
{
  return [IMOutletConnector class];
}

@end /* NSIBOutletConnector */

#ifdef __APPLE__
@implementation NSNibControlConnector (NibToGModel)
#else
@implementation NSIBControlConnector (NibToGModel)
#endif
- (void)establishConnection
{
}

- (Class)classForModelArchiver
{
  return [IMControlConnector class];
}
@end /* NSIBControlConnector */


@implementation NSWindowTemplate (GMArchiverMethods)

#ifdef DEBUG
- (void)encodeWithModelArchiver:(GMArchiver*)archiver
{
  NSLog (@"%@: %@", NSStringFromClass (isa), NSStringFromSelector (_cmd));
  [super encodeWithModelArchiver:archiver];
}
#endif

- (id)replacementObjectForModelArchiver:(GMArchiver*)archiver
{
#ifdef DEBUG
  NSLog (@"realObject = %@", realObject);
#endif
  return realObject;
}

@end

