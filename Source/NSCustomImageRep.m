/*
   NSCustomImageRep.m

   Custom image representation.

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Written by:  Adam Fedor <fedor@colorado.edu>
   Date: Mar 1996
   
   This file is part of the GNUstep Application Kit Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   */ 

#include <AppKit/NSCustomImageRep.h>

@implementation NSCustomImageRep

- (id) initWithDrawSelector: (SEL)aSelector
		delegate: (id)anObject
{
  [super init];

  /* WARNING: Retaining the delegate may or may not create a cyclic graph */
  delegate = [anObject retain];
  selector = aSelector;
  return self;
}

- (void) dealloc
{
  [delegate release];
  [super dealloc];
}

// Identifying the Object 
- (id) delegate
{
  return delegate;
}

- (SEL) drawSelector
{
  return selector;
}

- (BOOL) draw
{
  [delegate perform: selector];
  return YES;
}

// NSCoding protocol
- (void) encodeWithCoder: aCoder
{
  [super encodeWithCoder: aCoder];
  
  [aCoder encodeObject: delegate];
// FIXME:  [aCoder encodeSelector: selector];
}

- initWithCoder: aDecoder
{
  self = [super initWithCoder: aDecoder];

  delegate = [[aDecoder decodeObject] retain];
// FIXME:   selector = [aDecoder decodeSelector];
  return self;
}

@end
