/* Implementation of class NSPathControl
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Apr 22 18:19:40 EDT 2020

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

#import "AppKit/NSPathControl.h"
#import "AppKit/NSPathCell.h"

@implementation NSPathControl

+ (void) initialize
{
  if (self == [NSPathControl class])
    {
      [self setVersion: 1.0];
      [self setCellClass: [NSPathCell class]];
    }
}

- (void) setPathStyle: (NSPathStyle)style
{
  _pathStyle = style;
}

- (NSPathStyle) pathStyle
{
  return _pathStyle;
}

- (NSPathComponentCell *) clickedPathComponentCell
{
  return nil;
}

- (NSArray *) pathComponentCells
{
  return _pathComponentCells;
}

- (void) setPathComponentCells: (NSArray *)cells
{
  ASSIGN(_pathComponentCells, cells);
}

- (SEL) doubleAction;
{
  return _doubleAction;
}

- (void) setDoubleAction: (SEL)doubleAction
{
  _doubleAction = doubleAction;
}

- (NSURL *) URL
{
  return _url;
}

- (void) setURL: (NSURL *)url
{
  ASSIGNCOPY(_url, url);
}

- (id<NSPathControlDelegate>) delegate
{
  return _delegate;
}

- (void) setDelegate: (id<NSPathControlDelegate>) delegate
{
  _delegate = delegate;
}

- (void) setDraggingSourceOperationMask: (NSDragOperation)mask 
                               forLocal: (BOOL)local
{
}

- (NSMenu *) menu
{
  return [super menu];
}

- (void) setMenu: (NSMenu *)menu
{
  [super setMenu: menu];
}

- (NSArray *) allowedTypes;
{
  return _allowedTypes;
}

- (void) setAllowedTypes: (NSArray *)allowedTypes
{
  ASSIGNCOPY(_allowedTypes, allowedTypes);
}

- (NSPathControlItem *) clickedPathItem
{
  return nil;
}

- (NSArray *) pathItems
{
  return _pathItems;
}

- (void) setPathItems: (NSArray *)items
{
  ASSIGNCOPY(_pathItems, items);
}

- (NSAttributedString *) placeholderAttributedString
{
  return _placeholderAttributedString;
}

- (void) setPlaceholderAttributedString: (NSAttributedString *)string
{
  ASSIGNCOPY(_placeholderAttributedString, string);
}

- (NSString *) placeholderString
{
  return _placeholderString;
}

- (void) setPlaceholderString: (NSString *)string
{
  ASSIGNCOPY(_placeholderString, string);
}
@end

