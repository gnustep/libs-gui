/*
   NSEPSImageRep.m

   EPS image representation.

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Author:  Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996
   
   This file is part of the GNUstep Application Kit Library.

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

#include <AppKit/NSEPSImageRep.h>

@implementation NSEPSImageRep 

// Initializing a New Instance 
+ (id) imageRepWithData: (NSData *)epsData
{
  //[self notImplemented: _cmd];
  return nil;
}

+ (NSArray *) imageRepsWithData: (NSData *)epsData
{
  //[self notImplemented: _cmd];
  return nil;
}

- (id) initWithData: (NSData *)epsData
{
  [self notImplemented: _cmd];
  return self;
}

// Getting Image Data 
- (NSRect) boundingBox
{
  NSRect rect;
  [self notImplemented: _cmd];
  return rect;
}

- (NSData *) EPSRepresentation
{
  [self notImplemented: _cmd];
  return nil;
}

// Drawing the Image 
- (void) prepareGState
{
  [self notImplemented: _cmd];
}

// NSCoding protocol
- (void) encodeWithCoder: aCoder
{
  [self notImplemented: _cmd];
}

- initWithCoder: aDecoder
{
  [self notImplemented: _cmd];
  return self;
}

@end


