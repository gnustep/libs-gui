/*
   Functions.m

   Generic Functions for the GNUstep GUI Library.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: December 1998
   
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

#include <AppKit/NSApplication.h>
#include <AppKit/NSEvent.h>
#include <AppKit/GSContext.h>

char **NSArgv = NULL;

//
// Main initialization routine for the GNUstep GUI Library Apps
//
int NSApplicationMain(int argc, const char **argv)
{
extern char** environ;

#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(char**)argv
				 count:argc
			     environment:environ];
#endif

  [NSAutoreleasePool new];

#ifndef NX_CURRENT_COMPILER_RELEASE
  initialize_gnustep_backend();
#endif

  [[NSApplication sharedApplication] run];

  return 0;
}

//
// Convert an NSEvent Type to it's respective Event Mask
//
unsigned int NSEventMaskFromType(NSEventType type)
{													
	switch(type)										
		{												
		case NSLeftMouseDown:							
			return NSLeftMouseDownMask;
		case NSLeftMouseUp:
			return NSLeftMouseUpMask;
		case NSRightMouseDown:
			return NSRightMouseDownMask;
		case NSRightMouseUp:
			return NSRightMouseUpMask;
		case NSMouseMoved:
			return NSMouseMovedMask;
		case NSMouseEntered:
			return NSMouseEnteredMask;
		case NSMouseExited:
			return NSMouseExitedMask;
		case NSLeftMouseDragged:
			return NSLeftMouseDraggedMask;
		case NSRightMouseDragged:
			return NSRightMouseDraggedMask;
		case NSKeyDown:
			return NSKeyDownMask;
		case NSKeyUp:
			return NSKeyUpMask;
		case NSFlagsChanged:
			return NSFlagsChangedMask;
		case NSPeriodic:
			return NSPeriodicMask;
		case NSCursorUpdate:
			return NSCursorUpdateMask;
		default:
			break;
		}

	return 0;
}
