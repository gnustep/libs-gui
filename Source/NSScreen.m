/*
   NSScreen.m

   Description...

   Copyright (C) 1996, 2000 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
 
   Major modifications and updates
   Author: Gregory John Casamento <borgheron@yahoo.com>
   Date: 2000
   
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
#include <Foundation/Foundation.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSInterfaceStyle.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/DPSOperators.h>
#include <AppKit/NSGraphics.h>

static int*
_screenNumbers(int *count)
{
  int			*list;
  NSGraphicsContext	*ctxt = GSCurrentContext();

  DPScountscreenlist(ctxt, 0, count);

  // If the list is empty quit...
  if (*count == 0)
    {
      NSLog(@"Internal error: No screens detected.");
      return NULL; // something is wrong. This shouldn't happen.
    }

  list = NSZoneMalloc(NSDefaultMallocZone(), (*count+1)*sizeof(int));
  DPSscreenlist(ctxt, 0, *count, list);
  return list;
}

@implementation NSScreen

/*
 * Instance methods
 */

// NSScreen does not respond to the init method.
- (id) init
{
  [self doesNotRecognizeSelector: _cmd];
  return nil;
}

// Get all of the infomation for a given screen.
- (id) _initWithScreenNumber: (int)screen
{
  float			x, y, w, h;
  NSGraphicsContext	*ctxt = GSCurrentContext();

  self = [super init];

  // Initialize i-vars
  _depth = 0;
  _frame = NSZeroRect;
  _screenNumber = 0;

  // Check for problems
  if (screen < 0)
    {
      NSLog(@"Internal error: Invalid screen number %d\n",screen);
      RELEASE(self);
      return nil;
    }

  if (ctxt == nil)
    {
      NSLog(@"Internal error: No current context\n");
      RELEASE(self);
      return nil;
    }

  if ([ctxt isDrawingToScreen] == NO)
    {
      NSLog(@"Internal error: trying to find screen with wrong context\n");
      RELEASE(self);
      return nil;
    }

  // Fill in all of the i-vars with appropriate values.
  _screenNumber = screen;
  DPScurrentwindowbounds(ctxt, screen, &x, &y, &w, &h);
  _frame = NSMakeRect(x, y, w, h);
  _depth = GSWindowDepthForScreen(screen);

  return self;
}

- (BOOL) isEqual: (id)anObject
{
  if (anObject == self)
    return YES;
  if ([anObject isKindOfClass: self->isa] == NO)
    return NO;
  if (_screenNumber == ((NSScreen *)anObject)->_screenNumber)
    return YES;
  return NO;
}

/*
 * Reading Screen Information
 */
- (NSWindowDepth) depth
{
  return _depth;
}

- (NSRect) frame
{
  return _frame;
}

- (NSDictionary*) deviceDescription
{
  NSMutableDictionary	*devDesc;
  int			bps = 0;
  NSSize		screenResolution;
  NSString		*colorSpaceName = nil;

  /*
   * Testing of this method on OS4.2 indicates that the
   * dictionary is re-created every time this method is called.
   */

  // Set the screen number in the current object.
  devDesc = [NSMutableDictionary dictionary];
  [devDesc setObject: [NSNumber numberWithInt: _screenNumber]
	      forKey: @"NSScreenNumber"];

  // This is assumed since we are in NSScreen.
  [devDesc setObject: @"YES"  forKey: NSDeviceIsScreen];

  // Add the NSDeviceSize dictionary item
  [devDesc setObject: [NSValue valueWithSize: _frame.size]
	      forKey: NSDeviceSize];

  // Add the NSDeviceResolution dictionary item
  screenResolution.width = 72;  // This is a fixed value for screens.
  screenResolution.height = 72; // All screens I checked under OS4.2 report 72.
  [devDesc setObject: [NSValue valueWithSize: screenResolution]
	      forKey: NSDeviceResolution];

  // Add the bits per sample entry
  bps = NSBitsPerSampleFromDepth(_depth);
  [devDesc setObject: [NSNumber numberWithInt: bps]
	      forKey: NSDeviceBitsPerSample];

  // Add the color space entry.
  colorSpaceName = NSColorSpaceFromDepth(_depth);
  [devDesc setObject: colorSpaceName
	      forKey: NSDeviceColorSpaceName];
		
  return [NSDictionary dictionaryWithDictionary: devDesc];
}

// Mac OS X methods
- (const NSWindowDepth*) supportedWindowDepths
{
  /*
   * Skeletal implementation
   * NSWindowDepth* retval = NSZoneMalloc([self zone], sizeof(NSWindowDepth)*2);
   * retval[1] = _depth;
   * retval[2] = 0;
   * return retval;
   */
  return GSAvailableDepthsForScreen(_screenNumber);
}

- (NSRect) visibleFrame
{
  NSRect visFrame = _frame;

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
	return _frame;
    }
}

/*
 * Class methods
 */

+ (void) initialize
{
  if (self == [NSScreen class])
    {
      [self setVersion:1];
    }
}

// Creating NSScreen Instances
+ (NSScreen*) mainScreen
{
  int *windows = 0, count;
  NSScreen *mainScreen = nil;

  // Initialize the window list.
  windows = _screenNumbers(&count);

  // If the list is empty quit...
  if (windows == NULL)
    return nil; // something is wrong. This shouldn't happen.

  // main screen is always first in the array.
  mainScreen = [[NSScreen alloc] _initWithScreenNumber: windows[0]];
  NSZoneFree(NSDefaultMallocZone(), windows); // free the list

  return AUTORELEASE(mainScreen);
}

+ (NSScreen*) deepestScreen
{
  NSArray *screenArray = [NSScreen screens];
  NSEnumerator *screenEnumerator = nil;
  NSScreen *deepestScreen = nil, *screen = nil;  
  int maxBits = 0;

  // Iterate over the list of screens and find the
  // one with the most depth.
  screenEnumerator = [screenArray objectEnumerator];
  while ((screen = [screenEnumerator nextObject]) != nil)
    {
      int bits = 0;
      
      bits = [screen depth];
      
      if (bits > maxBits)
	{
	  maxBits = bits;
	  deepestScreen = screen;
	}
    }

  return deepestScreen;
}

+ (NSArray*) screens
{
  int count = 0, index = 0, *windows = 0;
  NSMutableArray *screenArray = [NSMutableArray array];

  // Get the number of screens.
  windows = _screenNumbers(&count);

  // If the list is empty quit...
  if (windows == NULL)
    return nil; // something is wrong. This shouldn't happen.

  // Iterate over the list
  for (index = 0; index < count; index++)
    {
      NSScreen *screen = nil;
      
      screen = [[NSScreen alloc] _initWithScreenNumber: windows[index]];
      [screenArray addObject: AUTORELEASE(screen)];
    }

  NSZoneFree(NSDefaultMallocZone(), windows); // free the list
  
  return [NSArray arrayWithArray: screenArray];
}
@end


