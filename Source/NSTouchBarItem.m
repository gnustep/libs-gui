/* Implementation of class NSTouchBarItem
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Thu Dec  5 12:45:10 EST 2019

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <AppKit/NSTouchBarItem.h>
#import <AppKit/NSView.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>

// Standard touch bar item identifiers
NSString * const NSTouchBarItemIdentifierFixedSpaceSmall = @"NSTouchBarItemIdentifierFixedSpaceSmall";
NSString * const NSTouchBarItemIdentifierFixedSpaceLarge = @"NSTouchBarItemIdentifierFixedSpaceLarge";
NSString * const NSTouchBarItemIdentifierFlexibleSpace = @"NSTouchBarItemIdentifierFlexibleSpace";

@implementation NSTouchBarItem

/*
 * Class methods
 */

+ (void) initialize
{
    if (self == [NSTouchBarItem class])
    {
        [self setVersion: 1];
    }
}

/*
 * Initialization and deallocation
 */

- (id) init
{
    return [self initWithIdentifier: nil];
}

- (id) initWithIdentifier: (NSString *)identifier
{
    self = [super init];
    if (self)
    {
        ASSIGNCOPY(_identifier, identifier);
        _view = nil;
        _customizationLabel = nil;
        _isVisible = YES;
    }
    return self;
}

- (void) dealloc
{
    RELEASE(_identifier);
    RELEASE(_view);
    RELEASE(_customizationLabel);
    [super dealloc];
}

/*
 * NSCoding protocol implementation
 */

- (id) initWithCoder: (NSCoder *)coder
{
    self = [super init];
    if (self)
    {
        ASSIGNCOPY(_identifier, [coder decodeObjectForKey: @"NSTouchBarItem.identifier"]);
        ASSIGN(_view, [coder decodeObjectForKey: @"NSTouchBarItem.view"]);
        ASSIGNCOPY(_customizationLabel, [coder decodeObjectForKey: @"NSTouchBarItem.customizationLabel"]);
        _isVisible = [coder decodeBoolForKey: @"NSTouchBarItem.isVisible"];
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
    [coder encodeObject: _identifier forKey: @"NSTouchBarItem.identifier"];
    [coder encodeObject: _view forKey: @"NSTouchBarItem.view"];
    [coder encodeObject: _customizationLabel forKey: @"NSTouchBarItem.customizationLabel"];
    [coder encodeBool: _isVisible forKey: @"NSTouchBarItem.isVisible"];
}

/*
 * Accessor methods
 */

- (NSString *) identifier
{
    return _identifier;
}

- (NSView *) view
{
    return _view;
}

- (void) setView: (NSView *)view
{
    ASSIGN(_view, view);
}

- (NSString *) customizationLabel
{
    return _customizationLabel;
}

- (void) setCustomizationLabel: (NSString *)label
{
    ASSIGNCOPY(_customizationLabel, label);
}

- (BOOL) isVisible
{
    return _isVisible;
}

@end

