/* Implementation of class NSTableCellView
   Copyright (C) 2022 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 03-09-2022

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

@implementation NSTableCellView

- (void) setObjectValue: (id)value
{
  ASSIGN(_objectValue, value);
}

- (id) objectValue
{
  return _objectValue;
}

- (void) setImageView: (NSImageView *)imageView
{
  ASSIGN(_imageView, imageView);
}

- (NSImageView *) imageView
{
  return _imageView;
}

- (void) setTextField: (NSTextField *)textField
{
  ASSIGN(_textField, textField);
}

- (NSTextField *) textField
{
  return _textField;
}

- (void) setBackgroundStyle: (NSBackgroundStyle)style
{
  _backgroundStyle = style;
}

- (NSBackgroundStyle) backgroundStyle
{
  return _backgroundStyle;
}

- (void) setRowSizeStyle: (NSTableViewRowSizeStyle)style
{
  _rowSizeStyle = style;
}

- (NSTableViewRowSizeStyle) rowSizeStyle
{
  return _rowSizeStyle;
}

- (NSArray *) draggingImageComponents
{
  return _draggingImageComponents;
}


@end

