/* Interface of class NSAccessibilityCustomAction
   Copyright (C) 2020 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: Mon 15 Jun 2020 03:18:47 AM EDT

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#ifndef _NSAccessibilityCustomAction_h_GNUSTEP_GUI_INCLUDE
#define _NSAccessibilityCustomAction_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_13, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

DEFINE_BLOCK_TYPE(GSAccessibilityCustomActionHandler, void, BOOL);

APPKIT_EXPORT_CLASS
@interface NSAccessibilityCustomAction : NSObject
{
  NSString *_name;
  GSAccessibilityCustomActionHandler _handler;
  id _target;
  SEL _selector;
}

- (instancetype) initWithName: (NSString *)name
                      handler: (GSAccessibilityCustomActionHandler)handler;

- (instancetype) initWithName: (NSString *)name
                       target: (id)target
                     selector: (SEL)selector;

/* Convenience factory returning an autoreleased custom action that invokes a block. */
+ (instancetype) actionWithName: (NSString *)name
                         handler: (GSAccessibilityCustomActionHandler)handler;

/* Convenience factory returning an autoreleased custom action that sends selector to target. */
+ (instancetype) actionWithName: (NSString *)name
                          target: (id)target
                        selector: (SEL)selector;

- (NSString *) name;
- (void) setName: (NSString *)name;

- (GSAccessibilityCustomActionHandler) handler;
- (void) setHandler: (GSAccessibilityCustomActionHandler)handler;

- (id) target;
- (void) setTarget: (id)target;

- (SEL) selector;
- (void) setSelector: (SEL)selector;

/* Perform the custom action. Returns YES on success (block executed or target responded) */
- (BOOL) perform;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSAccessibilityCustomAction_h_GNUSTEP_GUI_INCLUDE */

