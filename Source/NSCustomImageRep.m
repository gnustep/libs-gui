/*
   NSCustomImageRep.m

   Custom image representation.

   Copyright (C) 1996 Free Software Foundation, Inc.
   
   Author:  Adam Fedor <fedor@colorado.edu>
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
   
   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
   */ 

#include <gnustep/gui/config.h>
#include <AppKit/NSCustomImageRep.h>

@implementation NSCustomImageRep

- (id) initWithDrawSelector: (SEL)aSelector
		   delegate: (id)anObject
{
  [super init];

  /* WARNING: Retaining the delegate may or may not create a cyclic graph */
  _delegate = RETAIN(anObject);
  _selector = aSelector;
  return self;
}

- (void) dealloc
{
  RELEASE(_delegate);
  [super dealloc];
}

// Identifying the Object 
- (id) delegate
{
  return _delegate;
}

- (SEL) drawSelector
{
  return _selector;
}

- (BOOL) draw
{
  [_delegate performSelector: _selector withObject: self];
  return YES;
}

// NSCoding protocol
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  
  [aCoder encodeObject: _delegate];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_selector];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_delegate];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_selector];
  return self;
}

@end
