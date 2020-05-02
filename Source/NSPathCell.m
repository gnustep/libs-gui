/* Implementation of class NSPathCell
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Apr 22 18:19:07 EDT 2020

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

#import "AppKit/NSPathCell.h"

@implementation NSPathCell

- (void)mouseEntered:(NSEvent *)event 
           withFrame:(NSRect)frame 
              inView:(NSView *)view
{
}

- (void)mouseExited:(NSEvent *)event 
          withFrame:(NSRect)frame 
             inView:(NSView *)view
{
}

- (void) setAllowedTypes: (NSArray *)types
{
  ASSIGNCOPY(_allowedTypes, types);
}

- (NSArray *) allowedTypes
{
  return _allowedTypes;
}

- (NSPathStyle) pathStyle
{
  return _pathStyle;
}

- (void) setPathStyle: (NSPathStyle)pathStyle
{
  _pathStyle = pathStyle;
}

- (void) setControlSize: (NSControlSize)size
{
  _controlSize = size;
}

- (void) setObjectValue: (id)obj
{
  ASSIGN(_objectValue, obj);
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

- (NSColor *) backgroundColor
{
  return _backgroundColor;
}

- (void) setBackgroundColor: (NSColor *)color
{
  ASSIGNCOPY(_backgroundColor, color);
}

+ (Class) pathComponentCellClass
{
  return pathComponentCellClass;
}

+ (void) setPathComponentCellClass: (Class)clz
{
  pathComponentCellClass = clz;
}

- (NSRect)rectOfPathComponentCell:(NSPathComponentCell *)cell 
                        withFrame:(NSRect)frame 
                           inView:(NSView *)view
{
  return NSZeroRect;
}

- (NSPathComponentCell *)pathComponentCellAtPoint:(NSPoint)point 
                                        withFrame:(NSRect)frame 
                                           inView:(NSView *)view
{
  return nil;
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
  ASSIGNCOPY(_pathComponentCells, cells);
}

- (SEL) doubleAction
{
  return _doubleAction;
}

- (void) setDoubleAction: (SEL)action
{
  _doubleAction = action;
}

- (NSURL *) URL
{
  return _url;
}

- (void) setURL: (NSURL *)url
{
  ASSIGNCOPY(_url, url);
}

- (id<NSPathCellDelegate>) delegate
{
  return _delegate;
}

- (void) setDelegate: (id<NSPathCellDelegate>)delegate
{
  _delegate = delegate;
}

- (void) drawInteriorWithFrame: (NSRect)frame inView: (NSView *)controlView
{
  NSLog(@"Drawing");
}

- (id) initWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      if ([coder containsValueForKey: @"NSPathComponentCells"])
        {
          [self setPathComponentCells: [coder decodeObjectForKey: @"NSPathComponentCells"]];
        }
    }
  else
    {
    }

  return self;
}

@end
