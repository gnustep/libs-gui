/** <title>NSPanel</title>

   <abstract>Panel window class and related functions</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
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

#include "config.h"

#include <Foundation/NSCoder.h>
#include "AppKit/NSPanel.h"
#include "AppKit/NSButton.h"
#include "AppKit/NSTextField.h"
#include "AppKit/NSImage.h"

@implementation	NSPanel

/*
 * Class methods
 */
+ (void)initialize
{
  if (self  ==  [NSPanel class])
    {
      [self setVersion: 1];
    }
}

/*
 * Instance methods
 */
- (id) init
{
  int style =  NSTitledWindowMask | NSClosableWindowMask;

  return [self initWithContentRect: NSZeroRect
			 styleMask: style
			   backing: NSBackingStoreBuffered
			     defer: NO];
}

- (void) _initDefaults
{
  [super _initDefaults];
  [self setReleasedWhenClosed: NO];
  [self setHidesOnDeactivate: YES];
  [self setExcludedFromWindowsMenu: YES];
}

- (BOOL) canBecomeKeyWindow
{
  return YES;
}

- (BOOL) canBecomeMainWindow
{
  return NO;
}

/*
 * If we receive an escape, close.
 */
- (void) keyDown: (NSEvent*)theEvent
{
  if ([@"\e" isEqual: [theEvent charactersIgnoringModifiers]]
     &&  ([self styleMask] & NSClosableWindowMask)  ==  NSClosableWindowMask)
    [self close];
  else
    [super keyDown: theEvent];
}

/*
 * Determining the Panel's Behavior
 */
- (BOOL) isFloatingPanel
{
  return _isFloatingPanel;
}

- (void) setFloatingPanel: (BOOL)flag
{
  if (_isFloatingPanel != flag)
    {
      _isFloatingPanel = flag;
      if (flag == YES)
	{
	  [self setLevel: NSFloatingWindowLevel];
	}
      else
	{
	  [self setLevel: NSNormalWindowLevel];
	}
    }
}

- (BOOL) worksWhenModal
{
  return _worksWhenModal;
}

- (void) setWorksWhenModal: (BOOL)flag
{
  _worksWhenModal = flag;
}

- (BOOL) becomesKeyOnlyIfNeeded
{
  return _becomesKeyOnlyIfNeeded;
}

- (void) setBecomesKeyOnlyIfNeeded: (BOOL)flag
{
  _becomesKeyOnlyIfNeeded = flag;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL	flag;

  [super encodeWithCoder: aCoder];
  flag = _becomesKeyOnlyIfNeeded;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _isFloatingPanel;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
  flag = _worksWhenModal;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &flag];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  BOOL	flag;

  [super initWithCoder: aDecoder];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  [self setBecomesKeyOnlyIfNeeded: flag];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  [self setFloatingPanel: flag];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &flag];
  [self setWorksWhenModal: flag];

  return self;
}


- (void) sendEvent: (NSEvent*)theEvent
{
  [self _sendEvent: theEvent
    becomesKeyOnlyIfNeeded: _becomesKeyOnlyIfNeeded];
}

@end /* NSPanel */
