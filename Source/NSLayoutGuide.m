/* Implementation of class NSLayoutGuide
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory Casamento <greg.casamento@gmail.com>
   Date: Sat May  9 16:30:36 EDT 2020

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

#import "AppKit/NSLayoutGuide.h"
#import "AppKit/NSLayoutAnchor.h"
#import "GSAutoLayoutAnchorPrivate.h"

@implementation NSLayoutGuide

- (NSRect) frame
{
  return _frame;
}

- (NSView *) owningView
{
  return _owningView;
}

- (void) setOwningView: (NSView *)owningView
{
  _owningView = owningView; // weak
}

- (NSUserInterfaceItemIdentifier) identifier
{
  return _identifier;
}

- (void) setIdentifier: (NSUserInterfaceItemIdentifier)identifier
{
  ASSIGNCOPY(_identifier, identifier);
}

- (NSLayoutXAxisAnchor *) leadingAnchor
{
  return AUTORELEASE([[NSLayoutXAxisAnchor alloc]
                       initWithItem: self
                          attribute: NSLayoutAttributeLeading]);
}

- (NSLayoutXAxisAnchor *) trailingAnchor
{
  return AUTORELEASE([[NSLayoutXAxisAnchor alloc]
                       initWithItem: self
                          attribute: NSLayoutAttributeTrailing]);
}

- (NSLayoutXAxisAnchor *) leftAnchor
{
  return AUTORELEASE([[NSLayoutXAxisAnchor alloc]
                       initWithItem: self
                          attribute: NSLayoutAttributeLeft]);
}

- (NSLayoutXAxisAnchor *) rightAnchor
{
  return AUTORELEASE([[NSLayoutXAxisAnchor alloc]
                       initWithItem: self
                          attribute: NSLayoutAttributeRight]);
}

- (NSLayoutYAxisAnchor *) topAnchor
{
  return AUTORELEASE([[NSLayoutYAxisAnchor alloc]
                       initWithItem: self
                          attribute: NSLayoutAttributeTop]);
}

- (NSLayoutYAxisAnchor *) bottomAnchor
{
  return AUTORELEASE([[NSLayoutYAxisAnchor alloc]
                       initWithItem: self
                          attribute: NSLayoutAttributeBottom]);
}

- (NSLayoutDimension *) widthAnchor
{
  return AUTORELEASE([[NSLayoutDimension alloc]
                       initWithItem: self
                          attribute: NSLayoutAttributeWidth]);
}

- (NSLayoutDimension *) heightAnchor
{
  return AUTORELEASE([[NSLayoutDimension alloc]
                       initWithItem: self
                          attribute: NSLayoutAttributeHeight]);
}

- (NSLayoutXAxisAnchor *) centerXAnchor
{
  return AUTORELEASE([[NSLayoutXAxisAnchor alloc]
                       initWithItem: self
                          attribute: NSLayoutAttributeCenterX]);
}

- (NSLayoutYAxisAnchor *) centerYAnchor
{
  return AUTORELEASE([[NSLayoutYAxisAnchor alloc]
                       initWithItem: self
                          attribute: NSLayoutAttributeCenterY]);
}

- (BOOL) hasAmbiguousLayout
{
  return _hasAmbiguousLayout;
}
  
- (NSArray *) constraintsAffectingLayoutForOrientation: (NSLayoutConstraintOrientation)orientation
{
  return [NSArray array];
}

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _frame = NSZeroRect;
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_identifier);
  [super dealloc];
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
}

@end

