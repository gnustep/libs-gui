/* 
   AudioOutputSink.m

   Sink audio data to libao.

   Copyright (C) 2009 Free Software Foundation, Inc.

   Written by:  Stefan Bidigaray <stefanbidi@gmail.com>
   Date: Jun 2009
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#include <Foundation/Foundation.h>
#include <GNUstepGUI/GSVideoSink.h>

@interface VideoOutputSink : NSObject <GSVideoSink>
{
}
@end

@implementation VideoOutputSink

+ (void) initialize
{
}

+ (BOOL)canInitWithData: (NSData *)data
{
  return YES;
}

- (void)dealloc
{
  [super dealloc];
}

- (id)init
{
  self = [super init];
  if (self != nil)
    {
    }
  return self;
}

- (BOOL)open
{
  return YES;
}

- (void)close
{
}

- (BOOL)playBytes: (void *)bytes length: (NSUInteger)length
{
}

/* Functionality not supported by libao */
- (void)setVolume: (float)volume
{
}

- (float)volume
{
  return 1.0;
}

@end

