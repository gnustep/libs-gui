/* 
   NSScreen.h

   Class representing monitors

   Copyright (C) 1996, 2000 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996

   Fixes and updates made by
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

#ifndef _GNUstep_H_NSScreen
#define _GNUstep_H_NSScreen

#include <Foundation/NSObject.h>
#include <AppKit/NSGraphics.h>

@class NSArray;
@class NSDictionary;
@class NSMutableDictionary;

@interface NSScreen : NSObject
{
@private
  NSWindowDepth        _depth;
  NSRect               _frame;
  int                  _screenNumber;

  void                *_reserved;
}

/*
 * Creating NSScreen Instances
 */
+ (NSScreen*) mainScreen;
+ (NSScreen*) deepestScreen;
+ (NSArray*) screens;

/*
 * Reading Screen Information
 */
- (NSWindowDepth) depth;
- (NSRect) frame;
- (NSDictionary*) deviceDescription;

#ifndef STRICT_OPENSTEP
- (const NSWindowDepth*) supportedWindowDepths;
- (NSRect) visibleFrame;
#endif

@end
#endif // _GNUstep_H_NSScreen
