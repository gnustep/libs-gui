/* 
   NSHelpManager.m

   Description...

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Pedro Ivo Andrade Tavares <ptavares@iname.com>
   Date: 1999
   
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

#ifndef __GNUstep_H_NSHelpManager
#define __GNUstep_H_NSHelpManager

#include <Foundation/NSBundle.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSMapTable.h>
#include <AppKit/NSApplication.h>

@class NSAttributedString;

@interface NSBundle (NSHelpManager)
- (NSAttributedString*) contextHelpForKey: (NSString*) key;
@end

@interface NSApplication (NSHelpManager)
- (void) showHelp: (id) sender;
- (void) activateContextHelpMode: (id) sender;
@end

@interface NSHelpManager: NSObject
{
@private
  NSMapTable* contextHelpTopics;
}

//
// Class methods
//
+ (NSHelpManager*)sharedHelpManager;

+ (BOOL)isContextHelpModeActive;

+ (void)setContextHelpModeActive: (BOOL) flag;

//
// Instance methods
//
- (NSAttributedString*) contextHelpForObject: (id)object;

- (void) removeContextHelpForObject: (id)object;

- (void) setContextHelp: (NSAttributedString*) help withObject: (id) object;

- (BOOL) showContextHelpForObject: (id)object locationHint: (NSPoint) point;

@end

// Notifications
APPKIT_EXPORT NSString* NSContextHelpModeDidActivateNotification;
APPKIT_EXPORT NSString* NSContextHelpModeDidDeactivateNotification;

#endif // GNUstep_H_NSHelpManager
