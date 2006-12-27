/* 
   NSButtonImageSource.m

   Copyright (C) 2006 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <rfm@gnu.org>
   Date: 2006
   
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
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.
*/ 

#include "NSButtonImageSource.h"


@implementation NSButtonImageSource

NSMutableDictionary	*sources = nil;

+ (id) buttonImageSourceWithName: (NSString*)name
{
  NSButtonImageSource	*source;

  source = [sources objectForKey: name];
  if (source == nil)
    {
      source = [self alloc];
      source->imageName = [name copy];
      source->images = [NSMutableDictionary new];
      [sources setObject: source forKey: sources->imageName];
      RELEASE(source);
    }
  return source;
}

+ (void) initialize
{
  if (sources == nil)
    {
      sources = [NSMutableDictionary new];
    }
}

- (id) copyWithZone: (NSZone*)zone
{
  return RETAIN(self);
}

- (void) dealloc
{
  RELEASE(images);
  RELEASE(imageName);
  [super dealloc];
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: imageName forKey: @"NSImageName"];
    }
  else
    {
      [NSException raise: NSInvalidArgumentException 
		  format: @"Can't encode %@ with %@.",
	NSStringFromClass([self class]), NSStringFromClass([coder class])];
    }
}

- (id) imageForState: (struct NSButtonState)state
{
}

- (id) initWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      NSString	*name = [coder decodeObjectForKey: @"NSImageName"];

      ASSIGN(self, [[self class] buttonImageSourceWithName: name]);
    }
  else
    {
      NSString	*className = NSStringFromClass([self class]);

      RELEASE(self);
      [NSException raise: NSInvalidArgumentException 
		  format: @"Can't decode %@ with %@.",
	className, NSStringFromClass([coder class])];
    }

  return self;
}

@end

