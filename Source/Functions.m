/*
   Functions.m

   Generic Functions for the GNUstep GUI Library.

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

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

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSProcessInfo.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSGraphics.h>

char **NSArgv = NULL;

/*
 * Main initialization routine for the GNUstep GUI Library Apps
 */
int
NSApplicationMain(int argc, const char **argv)
{
  NSDictionary		*infoDict;
  NSString		*className;
  Class			appClass;
  CREATE_AUTORELEASE_POOL(pool);
#if defined(LIB_FOUNDATION_LIBRARY) || defined(GS_PASS_ARGUMENTS)
  extern char		**environ;

  [NSProcessInfo initializeWithArguments: (char**)argv
				   count: argc
			     environment: environ];
#endif

  infoDict = [[NSBundle mainBundle] infoDictionary];
  className = [infoDict objectForKey: @"NSPrincipalClass"];
  appClass = NSClassFromString(className);

  if (appClass == 0)
    {
      NSLog(@"Bad application class '%@' specified", className);
      appClass = [NSApplication class];
    }

  [[appClass sharedApplication] run];

  DESTROY(NSApp);

  RELEASE(pool);

  return 0;
}

/*
 * Convert an NSEvent Type to it's respective Event Mask
 */
unsigned
NSEventMaskFromType(NSEventType type)
{
  switch(type)
    {
      case NSLeftMouseDown:	return NSLeftMouseDownMask;
      case NSLeftMouseUp:	return NSLeftMouseUpMask;
      case NSRightMouseDown:	return NSRightMouseDownMask;
      case NSRightMouseUp:	return NSRightMouseUpMask;
      case NSMouseMoved:	return NSMouseMovedMask;
      case NSMouseEntered:	return NSMouseEnteredMask;
      case NSMouseExited:	return NSMouseExitedMask;
      case NSLeftMouseDragged:	return NSLeftMouseDraggedMask;
      case NSRightMouseDragged:	return NSRightMouseDraggedMask;
      case NSKeyDown:		return NSKeyDownMask;
      case NSKeyUp:		return NSKeyUpMask;
      case NSFlagsChanged:	return NSFlagsChangedMask;
      case NSPeriodic:		return NSPeriodicMask;
      case NSCursorUpdate:	return NSCursorUpdateMask;
      case NSAppKitDefined:	return NSAppKitDefinedMask;
      case NSSystemDefined:	return NSSystemDefinedMask;
      case NSApplicationDefined: return NSApplicationDefinedMask;
    }
  return 0;
}

/*
 * Color Functions
 */

/*
 * Get Information About Color Space and Window Depth
 */
const NSWindowDepth*
NSAvailableWindowDepths(void)
{
  /*
   * Perhaps this is the only function which
   * belongs in the backend.   It should be possible
   * to detect which depths the window server is capable
   * of.
   */	
  return (const NSWindowDepth *)_GSWindowDepths;
}

NSWindowDepth
NSBestDepth(NSString *colorSpace, int bitsPerSample, int bitsPerPixel,
  BOOL planar, BOOL *exactMatch)
{
  int			components = NSNumberOfColorComponents(colorSpace);
  int			index = 0;
  const NSWindowDepth	*depths = NSAvailableWindowDepths();
  NSWindowDepth		bestDepth = NSDefaultDepth;
  
  *exactMatch = NO;
  
  if (components == 1)
    {	
      for (index = 0; depths[index] != 0; index++)
	{
	  NSWindowDepth	depth = depths[index];

	  if (NSPlanarFromDepth(depth))
	    {
	      bestDepth = depth;
	      if (NSBitsPerSampleFromDepth(depth) == bitsPerSample)
		{
		  *exactMatch = YES;
		}
	    }
	}
    }
  else
    {
      for (index = 0; depths[index] != 0; index++)
	{
	  NSWindowDepth	depth = depths[index];

	  if (!NSPlanarFromDepth(depth))
	    {
	      bestDepth = depth;
	      if (NSBitsPerSampleFromDepth(depth) == bitsPerSample)
		{
		  *exactMatch = YES;
		}
	    }
	}
    }
  
  return bestDepth;
}

int
NSBitsPerPixelFromDepth(NSWindowDepth depth)
{
  int	bps = NSBitsPerSampleFromDepth(depth);
  int	spp = 0;
  
  if (depth & _GSRGBBitValue)
    {
      spp = 3;	
    }
  else if (depth & _GSCMYKBitValue)
    {
      spp = 4;
    }
  else if (depth & _GSGrayBitValue)
    {
      spp = 1;
    }
  return (spp * bps);
}

int
NSBitsPerSampleFromDepth(NSWindowDepth depth)
{
  NSWindowDepth	bitValue = 0;

  /*
   * Test against colorspace bit.
   * and out the bit to get the bps value.
   */
  if (depth & _GSRGBBitValue)
    {
      bitValue = _GSRGBBitValue;
    }
  else if (depth & _GSCMYKBitValue)
    {
      bitValue = _GSCMYKBitValue;
    }
  else if (depth & _GSGrayBitValue)
    {
      bitValue = _GSGrayBitValue;
    }
  /*
   * AND against the complement
   * to extract the bps value.	
   */
  return (depth & ~(bitValue));
}

NSString*
NSColorSpaceFromDepth(NSWindowDepth depth)
{
  NSString	*colorSpace = NSCalibratedWhiteColorSpace;
  
  /*
   * Test against each of the possible colorspace bits
   * and return the corresponding colorspace.
   */
  if (depth == 0)
    {
      colorSpace = NSCalibratedBlackColorSpace;
    }
  else if (depth & _GSRGBBitValue)
    {
      colorSpace = NSCalibratedRGBColorSpace;
    }
  else if (depth & _GSCMYKBitValue)
    {
      colorSpace = NSDeviceCMYKColorSpace;
    }
  else if (depth & _GSGrayBitValue)
    {
      colorSpace = NSCalibratedWhiteColorSpace;
    }
  else if (depth & _GSNamedBitValue)
    {
      colorSpace = NSNamedColorSpace;
    }
  else if (depth & _GSCustomBitValue)
    {
      colorSpace = NSCustomColorSpace;
    }

  return colorSpace;
}

int
NSNumberOfColorComponents(NSString *colorSpaceName)
{
  int	components = 1;
  
  /*
   * These are the only exceptions to the above.
   * All other colorspaces have as many bps as bpp.
   */
  if ([colorSpaceName isEqualToString: NSCalibratedRGBColorSpace]
    || [colorSpaceName isEqualToString: NSDeviceRGBColorSpace])
    {
      components = 3;
    }
  else if ([colorSpaceName isEqualToString: NSDeviceCMYKColorSpace])
    {
      components = 4;
    }
  return components;
}

BOOL
NSPlanarFromDepth(NSWindowDepth depth)
{
  BOOL planar = NO;
  
  /*
   * Only the grayscale depths are planar.
   * All others are interleaved.
   */
  if (depth & _GSGrayBitValue)
    {
      planar = YES;
    }
  return planar;
}
