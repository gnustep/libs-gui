/** <title>NSScreen</title>

   Copyright (C) 1996, 2000 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
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

#include <Foundation/Foundation.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSInterfaceStyle.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/GSDisplayServer.h>
#include <AppKit/AppKitExceptions.h>

@interface NSScreen (Private)
- (id) _initWithScreenNumber: (int)screen;
@end

@implementation NSScreen

/*
 * Class methods
 */

+ (void) initialize
{
  if (self == [NSScreen class])
    {
      [self setVersion: 1];
    }
}

static NSMutableArray *screenArray = nil;

+ (void) resetScreens
{
  screenArray = nil;
}

+ (NSArray*) screens
{
  int count = 0, index = 0;
  NSArray *screens;
  GSDisplayServer *srv;

  if (screenArray != nil)
    return screenArray;

  srv = GSCurrentServer();
  screens = [srv screenList];
  count = [screens count];
  if (count == 0)
    {
      // something is wrong. This shouldn't happen.
      [NSException raise: NSWindowServerCommunicationException
		   format: @"Unable to retrieve list of screens from window server."];
      return nil;
    }

  screenArray = [NSMutableArray new];

  // Iterate over the list
  for (index = 0; index < count; index++)
    {
      NSScreen *screen = nil;
      
      screen = [[NSScreen alloc] _initWithScreenNumber: 
      			[[screens objectAtIndex: index] intValue]];
      [screenArray addObject: AUTORELEASE(screen)];
    }

  return [NSArray arrayWithArray: screenArray];
}

// Creating NSScreen Instances
+ (NSScreen*) mainScreen
{
  return [[self screens] objectAtIndex: 0];
}

+ (NSScreen*) deepestScreen
{
  NSArray *screenArray = [self screens];
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
  GSDisplayServer *srv;

  srv = GSCurrentServer();

  self = [super init];

  // Initialize i-vars
  _depth = 0;
  _frame = NSZeroRect;
  _screenNumber = 0;

  // Check for problems
  if (screen < 0)
    {
      NSLog(@"Internal error: Invalid screen number %d\n", screen);
      RELEASE(self);
      return nil;
    }

  if (srv == nil)
    {
      NSLog(@"Internal error: No current context\n");
      RELEASE(self);
      return nil;
    }

  // Fill in all of the i-vars with appropriate values.
  _screenNumber = screen;
  _frame = [srv boundsForScreen: _screenNumber];
  _depth = [srv windowDepthForScreen: _screenNumber];
  _supportedWindowDepths = NULL;

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
   * This method generates a dictionary from the
   * information we have gathered from the screen.
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
  screenResolution = [GSCurrentServer() resolutionForScreen: _screenNumber];
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
  // If the variable isn't initialized, get the info and
  // store it for the future.
  if (_supportedWindowDepths == NULL)
    {
      _supportedWindowDepths = 
        (NSWindowDepth*)[GSCurrentServer()
			       availableDepthsForScreen: _screenNumber];

      // Check the results
      if (_supportedWindowDepths == NULL)
	{
	  NSLog(@"Internal error: no depth list returned from window server.");
	  return NULL;
	}
    }

  return _supportedWindowDepths;
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

/** Returns the screen number */
- (int) screenNumber
{
  return _screenNumber;
}

// Release the memory for the depths array.
- (void) dealloc
{
  // _supportedWindowDepths can be NULL since it may or may not
  // be necessary to get this info.  The most common use of NSScreen
  // is to get the depth and frame attributes.
  if (_supportedWindowDepths != NULL)
    {
      NSZoneFree(NSDefaultMallocZone(), _supportedWindowDepths);
    }

  [super dealloc];
}

@end


