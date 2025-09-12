/* Interface of class NSAccessibilityCustomElement
   Copyright (C) 2020 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: Mon 15 Jun 2020 03:19:09 AM EDT

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

#ifndef _NSAccessibilityElement_h_GNUSTEP_GUI_INCLUDE
#define _NSAccessibilityElement_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_13, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

APPKIT_EXPORT_CLASS
@interface NSAccessibilityElement : NSObject

/* Convenience factory for creating a simple accessibility element with the
 * specified role, frame, label and parent. Role/label are copied. */
+ (instancetype) accessibilityElementWithRole: (NSString *)role
                                         frame: (NSRect)frame
                                         label: (NSString *)label
                                        parent: (id)parent;

/* Designated initializer. */
- (instancetype) initWithRole: (NSString *)role
                         frame: (NSRect)frame
                         label: (NSString *)label
                        parent: (id)parent;

// Basic attribute accessors (mirroring Cocoa style naming) -----------------
- (NSString *) accessibilityLabel;
- (void) setAccessibilityLabel: (NSString *)label;

- (NSString *) accessibilityIdentifier;
- (void) setAccessibilityIdentifier: (NSString *)identifier;

- (NSRect) accessibilityFrame;
- (void) setAccessibilityFrame: (NSRect)frame;

- (id) accessibilityParent;
- (void) setAccessibilityParent: (id)parent;

- (BOOL) isAccessibilityFocused;
- (void) setAccessibilityFocused: (BOOL)focused;

- (NSString *) accessibilityRole;
- (void) setAccessibilityRole: (NSString *)role;

- (NSString *) accessibilitySubrole;
- (void) setAccessibilitySubrole: (NSString *)subrole;

/* A rudimentary role description derived from role/subrole strings. */
- (NSString *) accessibilityRoleDescription;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSAccessibilityElement_h_GNUSTEP_GUI_INCLUDE */

