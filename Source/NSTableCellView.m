/* Implementation of class NSTableCellView
   Copyright (C) 2022 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 12-12-2022

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

#import "AppKit/NSTableCellView.h"
#import "AppKit/NSImageView.h"
#import "AppKit/NSTextField.h"

@implementation NSTableCellView

- (id) objectValue
{
  return _objectValue;
}

- (void) setObjectValue: (id)objectValue
{
  ASSIGN(_objectValue, objectValue);
}

- (NSImageView *) imageView
{
  return _imageView;
}

- (void) setImageView: (NSImageView *)imageView
{
  ASSIGN(_imageView, imageView);
}

- (NSTextField *) textField
{
  return _textField;
}

- (void) setTextField: (NSTextField *)textField
{
  ASSIGN(_textField, textField);
}

- (NSBackgroundStyle) backgroundStyle
{
  return _backgroundStyle;
}

- (void) setBackgroundStyle: (NSBackgroundStyle)backgroundStyle
{
  _backgroundStyle = backgroundStyle;
}

- (NSTableViewRowSizeStyle) rowSizeStyle
{
  return _rowSizeStyle;
}

- (void) setRowSizeStyle: (NSTableViewRowSizeStyle) rowSizeStyle
{
  _rowSizeStyle = rowSizeStyle;
}

- (NSArray *) draggingImageComponents
{
  return _draggingImageComponents;
}

- (void) setDraggingImageComponents: (NSArray *)draggingImageComponents
{
  ASSIGNCOPY(_draggingImageComponents, draggingImageComponents);
}

@end

