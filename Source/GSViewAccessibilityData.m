/** <title>GSViewAccessibilityData</title>

   <abstract>Encapsulates accessibility properties for NSView</abstract>

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

#import "GNUstepGUI/GSViewAccessibilityData.h"
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>

@implementation GSViewAccessibilityData

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      // Set default values to match NSView behavior
      _accessibilityEnabled = YES;

      // Explicituly set other properties to nil/NO to avoid uninitialized values
      _accessibilityLabel = nil;
      _accessibilityValue = nil;
      _accessibilityHelp = nil;
      _accessibilityRole = nil;
      _accessibilityTitle = nil;
      _accessibilityRoleDescription = nil;
      _accessibilityIdentifier = nil;
      _accessibilityUserInputLabels = nil;
      _accessibilityChildren = nil;
      _accessibilityCustomActions = nil;
      _accessibilityParent = nil;
      _accessibilityFocused = NO;
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_accessibilityLabel);
  RELEASE(_accessibilityValue);
  RELEASE(_accessibilityHelp);
  RELEASE(_accessibilityRole);
  RELEASE(_accessibilityTitle);
  RELEASE(_accessibilityRoleDescription);
  RELEASE(_accessibilityIdentifier);
  RELEASE(_accessibilityUserInputLabels);
  RELEASE(_accessibilityChildren);
  RELEASE(_accessibilityCustomActions);
  // _accessibilityParent is a weak reference, no RELEASE needed
  
  [super dealloc];
}

- (NSString *) accessibilityLabel
{
  return _accessibilityLabel;
}

- (void) setAccessibilityLabel: (NSString *)label
{
  ASSIGN(_accessibilityLabel, label);
}

- (NSString *) accessibilityValue
{
  return _accessibilityValue;
}

- (void) setAccessibilityValue: (NSString *)value
{
  ASSIGN(_accessibilityValue, value);
}

- (NSString *) accessibilityHelp
{
  return _accessibilityHelp;
}

- (void) setAccessibilityHelp: (NSString *)help
{
  ASSIGN(_accessibilityHelp, help);
}

- (NSAccessibilityRole) accessibilityRole
{
  return _accessibilityRole;
}

- (void) setAccessibilityRole: (NSAccessibilityRole)role
{
  ASSIGN(_accessibilityRole, role);
}

- (NSString *) accessibilityTitle
{
  return _accessibilityTitle;
}

- (void) setAccessibilityTitle: (NSString *)title
{
  ASSIGN(_accessibilityTitle, title);
}

- (NSString *) accessibilityRoleDescription
{
  return _accessibilityRoleDescription;
}

- (void) setAccessibilityRoleDescription: (NSString *)roleDescription
{
  ASSIGN(_accessibilityRoleDescription, roleDescription);
}

- (NSString *) accessibilityIdentifier
{
  return _accessibilityIdentifier;
}

- (void) setAccessibilityIdentifier: (NSString *)identifier
{
  ASSIGN(_accessibilityIdentifier, identifier);
}

- (NSArray *) accessibilityUserInputLabels
{
  return _accessibilityUserInputLabels;
}

- (void) setAccessibilityUserInputLabels: (NSArray *)labels
{
  ASSIGN(_accessibilityUserInputLabels, labels);
}

- (NSArray *) accessibilityChildren
{
  return _accessibilityChildren;
}

- (void) setAccessibilityChildren: (NSArray *)children
{
  ASSIGN(_accessibilityChildren, children);
}

- (NSArray *) accessibilityCustomActions
{
  return _accessibilityCustomActions;
}

- (void) setAccessibilityCustomActions: (NSArray *)actions
{
  ASSIGN(_accessibilityCustomActions, actions);
}

- (id) accessibilityParent
{
  return _accessibilityParent;
}

- (void) setAccessibilityParent: (id)parent
{
  // Weak reference - don't retain
  _accessibilityParent = parent;
}

- (BOOL) isAccessibilityFocused
{
  return _accessibilityFocused;
}

- (void) setAccessibilityFocused: (BOOL)focused
{
  _accessibilityFocused = focused;
}

- (BOOL) isAccessibilityEnabled
{
  return _accessibilityEnabled;
}

- (void) setAccessibilityEnabled: (BOOL)enabled
{
  _accessibilityEnabled = enabled;
}

@end