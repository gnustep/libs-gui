/* Implementation of class NSScrubberItemView
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Apr  8 09:17:27 EDT 2020

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

#import "AppKit/NSScrubberItemView.h"
#import <AppKit/NSTextField.h>
#import <AppKit/NSFont.h>
#import <Foundation/NSString.h>

@implementation NSScrubberArrangedView

@end

@implementation NSScrubberItemView

@end

@implementation NSScrubberTextItemView

/*
 * Class methods
 */

+ (void) initialize
{
    if (self == [NSScrubberTextItemView class])
    {
        [self setVersion: 1];
    }
}

/*
 * Initialization and deallocation
 */

- (id) initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self)
    {
        _textField = [[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        [_textField setBezeled: NO];
        [_textField setDrawsBackground: NO];
        [_textField setEditable: NO];
        [_textField setSelectable: NO];
        [_textField setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
        [_textField setAlignment: NSTextAlignmentCenter];
        [_textField setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
        
        [self addSubview: _textField];
    }
    return self;
}

- (void) dealloc
{
    RELEASE(_textField);
    [super dealloc];
}

/*
 * Accessor methods
 */

- (NSString *) title
{
    return [_textField stringValue];
}

- (void) setTitle: (NSString *)title
{
    [_textField setStringValue: title ? title : @""];
}

- (NSTextField *) textField
{
    return _textField;
}

@end

