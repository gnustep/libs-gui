/* Implementation of class NSAccessibilityCustomElement
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

#import <Foundation/NSString.h>
#import "AppKit/NSAccessibilityElement.h"

@implementation NSAccessibilityElement

+ (instancetype) accessibilityElementWithRole: (NSString *)role
					frame: (NSRect)frame
					label: (NSString *)label
				       parent: (id)parent
{
   NSAccessibilityElement *e = [[self alloc] initWithRole: role
						    frame: frame
						    label: label
						   parent: parent];
   return AUTORELEASE(e);
}

- (instancetype) initWithRole: (NSString *)role
			frame: (NSRect)frame
			label: (NSString *)label
		       parent: (id)parent
{
   self = [super init];
   if (self != nil)
      {
         _accessibilityFrame = frame;
         ASSIGN(_accessibilityRole, role);
         ASSIGN(_accessibilityLabel, label);
         _accessibilityParent = parent;
         _accessibilityFocused = NO;
      }
   return self;
}

- (void) dealloc
{
   RELEASE(_accessibilityLabel);
   RELEASE(_accessibilityIdentifier);
   RELEASE(_accessibilityRole);
   RELEASE(_accessibilitySubrole);
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

- (NSString *) accessibilityIdentifier
{
  return _accessibilityIdentifier;
}

- (void) setAccessibilityIdentifier: (NSString *)identifier
{
  ASSIGN(_accessibilityIdentifier, identifier);
}

- (NSRect) accessibilityFrame
{
  return _accessibilityFrame;
}

- (void) setAccessibilityFrame: (NSRect)frame
{
  _accessibilityFrame = frame;
}

- (id) accessibilityParent
{
  return _accessibilityParent;
}

- (void) setAccessibilityParent: (id)parent
{
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

- (NSString *) accessibilityRole
{
  return _accessibilityRole;
}

- (void) setAccessibilityRole: (NSString *)role
{
  ASSIGN(_accessibilityRole, role);
}

- (NSString *) accessibilitySubrole
{
  return _accessibilitySubrole;
}

- (void) setAccessibilitySubrole: (NSString *)subrole
{
  ASSIGN(_accessibilitySubrole, subrole);
}

- (NSString *) accessibilityRoleDescription
{
   if (_accessibilitySubrole != nil)
      {
         return [NSString stringWithFormat: @"%@ (%@)", _accessibilityRole,
			  _accessibilitySubrole];
      }
   return _accessibilityRole;
}

@end

