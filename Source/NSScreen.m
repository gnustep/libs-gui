/* 
   NSScreen.m

   Description...

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <gnustep/gui/config.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSInterfaceStyle.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/DPSOperators.h>


static int *
_screen_numbers(void)
{
  int count, *list;
  NSGraphicsContext *ctxt = GSCurrentContext();

  DPScountscreenlist(ctxt, 0, &count);
  if (count == 0)
    return NULL;
  list = NSZoneMalloc(NSDefaultMallocZone(), (count+1)*sizeof(int));
  DPSscreenlist(ctxt, 0, count, list);
  return list;
}

@implementation NSScreen

//
// Class variables
//
static NSScreen *mainScreen = nil;

//
// Class methods
//
+ (void)initialize
{
	if (self == [NSScreen class])
		[self setVersion:1];
}

//
// Creating NSScreen Instances
//
+ (NSScreen *)mainScreen
{
  NSMutableDictionary *dict;
  
  if (mainScreen)
    return mainScreen; 
  
  dict = [NSMutableDictionary dictionary];
  [dict setObject: @"Main" forKey: @"NSScreenKeyName"];
  mainScreen = [[NSScreen alloc] initWithDeviceDescription: dict];
  return mainScreen;
}

+ (NSScreen *)deepestScreen
{
  return [self mainScreen];
}

+ (NSArray *)screens
{
  return [NSArray arrayWithObject: [self mainScreen]];
}

//
// Instance methods
//
- initWithDeviceDescription: (NSDictionary *)dict
{
  int screen;
  float x, y, w, h;
  NSGraphicsContext *ctxt = GSCurrentContext();

  [super init];
  depth = 0;
  frame = NSZeroRect;
  if (dict)
    device_desc = [dict mutableCopy];
  else
    device_desc = [[NSMutableDictionary dictionary] retain];

  if (ctxt == nil)
    {
      NSLog(@"Internal error: No current context\n");
      [self release];
      return nil;
    }

  if ([ctxt isDrawingToScreen] == NO)
    {
      NSLog(@"Internal error: trying to find screen with wrong context\n");
      [self release];
      return nil;
    }

  if (!dict || [dict objectForKey: @"NSScreenKeyName"] == nil
      || [[dict objectForKey: @"NSScreenKeyName"] isEqual: @"Main"])
    {
      /* Assume the main screen is the one we started with */
      int *windows = _screen_numbers();
      screen = 0;
      if (windows)
        screen = windows[0];
      NSZoneFree(NSDefaultMallocZone(), windows);
    }
  else if ([dict objectForKey: @"NSScreenNumber"])
    {
      screen = [[dict objectForKey: @"NSScreenNumber"] intValue];
    }
  /* Special hack to get screen frame since window number of root window
     is same as screen number */
  DPScurrentwindowbounds(ctxt, screen, &x, &y, &w, &h);
  frame = NSMakeRect(x, y, w, h);
  DPScurrentwindowdepth(ctxt, screen, &depth);
  return self;
}

- init
{
  return [self initWithDeviceDescription: NULL];
}

//
// Reading Screen Information
//
- (NSWindowDepth)depth
{
	return depth;
}

- (NSRect)frame
{
	return frame;
}

- (NSDictionary *)deviceDescription					// Make a copy of device 
{													// dictionary and return it
NSDictionary *d = [[NSDictionary alloc] initWithDictionary: device_desc];

	return d;
}

// Mac OS X methods
- (const NSWindowDepth*) supportedWindowDepths
{
  // Skeletal implementation
  NSWindowDepth* retval = NSZoneMalloc([self zone], sizeof(NSWindowDepth)*2);
  retval[1] = depth;
  retval[2] = 0;
  return retval;
}

-(NSRect) visibleFrame
{
  NSRect visFrame = frame;
  switch ([NSApp interfaceStyle])
    {
    case NSMacintoshInterfaceStyle:
      // What is the size of the Mac menubar?
      visFrame.size.height -= 25;
      return visFrame;
    case NSWindows95InterfaceStyle:
    case NSNextStepInterfaceStyle:
    case NSNoInterfaceStyle:
    default:
      return frame;
    }
}

@end
