/** <title>GSViewAccessibilityData</title>

   <abstract>Encapsulates accessibility properties for NSView</abstract>

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Copyright (C) 2026 Free Software Foundation, Inc.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_GSViewAccessibilityData
#define _GNUstep_H_GSViewAccessibilityData

#import <Foundation/NSObject.h>
#import <AppKit/NSAccessibilityConstants.h>

@class NSString;
@class NSArray;

/**
 * GSViewAccessibilityData encapsulates all accessibility-related properties
 * for NSView instances. This allows views to only allocate this object when
 * accessibility functionality is actually needed, reducing memory overhead.
 */
@interface GSViewAccessibilityData : NSObject
{
@private
  NSString *_accessibilityLabel;
  NSString *_accessibilityValue;
  NSString *_accessibilityHelp;
  NSAccessibilityRole _accessibilityRole;
  NSString *_accessibilityTitle;
  NSString *_accessibilityRoleDescription;
  NSString *_accessibilityIdentifier;
  NSArray *_accessibilityUserInputLabels;
  NSArray *_accessibilityChildren;
  NSArray *_accessibilityCustomActions;
  id _accessibilityParent;            // weak reference
  BOOL _accessibilityFocused;
  BOOL _accessibilityEnabled;
}

// Property accessors
- (NSString *) accessibilityLabel;
- (void) setAccessibilityLabel: (NSString *)label;

- (NSString *) accessibilityValue;
- (void) setAccessibilityValue: (NSString *)value;

- (NSString *) accessibilityHelp;
- (void) setAccessibilityHelp: (NSString *)help;

- (NSAccessibilityRole) accessibilityRole;
- (void) setAccessibilityRole: (NSAccessibilityRole)role;

- (NSString *) accessibilityTitle;
- (void) setAccessibilityTitle: (NSString *)title;

- (NSString *) accessibilityRoleDescription;
- (void) setAccessibilityRoleDescription: (NSString *)roleDescription;

- (NSString *) accessibilityIdentifier;
- (void) setAccessibilityIdentifier: (NSString *)identifier;

- (NSArray *) accessibilityUserInputLabels;
- (void) setAccessibilityUserInputLabels: (NSArray *)labels;

- (NSArray *) accessibilityChildren;
- (void) setAccessibilityChildren: (NSArray *)children;

- (NSArray *) accessibilityCustomActions;
- (void) setAccessibilityCustomActions: (NSArray *)actions;

- (id) accessibilityParent;
- (void) setAccessibilityParent: (id)parent;

- (BOOL) isAccessibilityFocused;
- (void) setAccessibilityFocused: (BOOL)focused;

- (BOOL) isAccessibilityEnabled;
- (void) setAccessibilityEnabled: (BOOL)enabled;

@end

#endif // _GNUstep_H_GSViewAccessibilityData