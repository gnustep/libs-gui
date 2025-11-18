/* Implementation of class NSScrubberTouchBarItem
   Copyright (C) 2025 Free Software Foundation, Inc.
   
   By: GNUstep Contributors
   Date: Sep 30 2025

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

#import <AppKit/NSScrubberTouchBarItem.h>
#import <AppKit/NSScrubber.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>

@implementation NSScrubberTouchBarItem

/*
 * Class methods
 */

+ (void) initialize
{
    if (self == [NSScrubberTouchBarItem class])
    {
        [self setVersion: 1];
    }
}

/*
 * Initialization and deallocation
 */

- (id) initWithIdentifier: (NSString *)identifier
{
    self = [super initWithIdentifier: identifier];
    if (self)
    {
        _scrubber = [[NSScrubber alloc] init];
        [self setView: _scrubber];
        [self setCustomizationLabel: @"Scrubber"];
    }
    return self;
}

- (void) dealloc
{
    RELEASE(_scrubber);
    [super dealloc];
}

/*
 * NSCoding protocol implementation
 */

- (id) initWithCoder: (NSCoder *)coder
{
    self = [super initWithCoder: coder];
    if (self)
    {
        ASSIGN(_scrubber, [coder decodeObjectForKey: @"NSScrubberTouchBarItem.scrubber"]);
        if (_scrubber)
        {
            [self setView: _scrubber];
        }
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
    [super encodeWithCoder: coder];
    [coder encodeObject: _scrubber forKey: @"NSScrubberTouchBarItem.scrubber"];
}

/*
 * Accessor methods
 */

- (NSScrubber *) scrubber
{
    return _scrubber;
}

- (void) setScrubber: (NSScrubber *)scrubber
{
    ASSIGN(_scrubber, scrubber);
    [self setView: _scrubber];
}

@end