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
#import "AppKit/NSGraphics.h"

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
  [_cell setPathStyle: style];
  [self setNeedsDisplay];
}

- (NSPathStyle) pathStyle
{
  return [_cell pathStyle];
}

- (NSPathComponentCell *) clickedPathComponentCell
{
  return [_cell clickedPathComponentCell];
}

- (NSArray *) pathComponentCells
{
  return [_cell pathComponentCells];
}

- (void) setPathComponentCells: (NSArray *)cells
{
  [_cell setPathComponentCells: cells];
  [self setNeedsDisplay];
}

- (SEL) doubleAction;
{
  return [_cell doubleAction];
}

- (void) setDoubleAction: (SEL)doubleAction
{
  [_cell setDoubleAction: doubleAction];
}

- (NSURL *) URL
{
  return [_cell URL];
}

- (void) setURL: (NSURL *)url
{
  [_cell setURL: url];
  [self setNeedsDisplay];
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
  return [_cell allowedTypes];
}

- (void) setAllowedTypes: (NSArray *)allowedTypes
{
  [_cell setAllowedTypes: allowedTypes];
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
  return [_cell placeholderAttributedString];
}

- (void) setPlaceholderAttributedString: (NSAttributedString *)string
{
  [_cell setPlaceholderAttributedString: string];
  [self setNeedsDisplay];
}

- (NSString *) placeholderString
{
  return [_cell placeholderString];
}

- (void) setPlaceholderString: (NSString *)string
{
  [_cell setPlaceholderString: string];
  [self setNeedsDisplay];
}

- (NSColor *) backgroundColor
{
  return _backgroundColor;
}

- (void) setBackgroundColor: (NSColor *)color
{
  ASSIGN(_backgroundColor, color);
  [self setNeedsDisplay];
}

- (void) drawRect: (NSRect)frame
{
  [super drawRect: frame];
  [_backgroundColor set];
  NSRectFill(frame);
}

- (instancetype) initWithCoder: (NSKeyedUnarchiver *)coder
{
  self = [super initWithCoder: coder];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
          // Defaults for some values which aren't encoded unless they are non-default.
          [self setBackgroundColor: [NSColor windowBackgroundColor]];
          [self setPathStyle: NSPathStyleStandard];

          if ([coder containsValueForKey: @"NSPathStyle"])
            {
              [self setPathStyle: [coder decodeIntegerForKey: @"NSPathStyle"]];
            }

          if ([coder containsValueForKey: @"NSBackgroundColor"])
            {
              [self setBackgroundColor: [coder decodeObjectForKey: @"NSBackgroundColor"]];
            }
        }
      else
        {
        }
    }
  return self;
}
@end

