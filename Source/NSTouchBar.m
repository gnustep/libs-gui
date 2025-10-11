/* Implementation of class NSTouchBar
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: Gregory Casamento
   Date: Mon Jan 20 10:35:18 EST 2020

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

#import <AppKit/NSTouchBar.h>
#import <AppKit/NSTouchBarItem.h>
#import <AppKit/GSTouchBarWindow.h>
#import <Foundation/NSMutableDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>

@implementation NSTouchBar

/*
 * Class methods
 */

+ (void) initialize
{
    if (self == [NSTouchBar class])
    {
        [self setVersion: 1];
    }
}

/*
 * Initialization and deallocation
 */

- (id) init
{
    self = [super init];
    if (self)
    {
        _items = [[NSMutableDictionary alloc] init];
        _isVisible = NO;
        _showsFallbackWindow = YES; // Default to showing fallback on Linux
        _customizationIdentifier = nil;
        _defaultItemIdentifiers = nil;
        _itemIdentifiers = nil;
        _principalItemIdentifier = nil;
        _delegate = nil;
        _fallbackWindow = nil;
        _fallbackContentView = nil;
    }
    return self;
}

- (void) dealloc
{
    [self hideFallbackWindow];
    RELEASE(_customizationIdentifier);
    RELEASE(_defaultItemIdentifiers);
    RELEASE(_itemIdentifiers);
    RELEASE(_principalItemIdentifier);
    RELEASE(_items);
    RELEASE(_fallbackWindow);
    RELEASE(_fallbackContentView);
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
        ASSIGNCOPY(_customizationIdentifier, [coder decodeObjectForKey: @"NSTouchBar.customizationIdentifier"]);
        ASSIGNCOPY(_defaultItemIdentifiers, [coder decodeObjectForKey: @"NSTouchBar.defaultItemIdentifiers"]);
        ASSIGNCOPY(_itemIdentifiers, [coder decodeObjectForKey: @"NSTouchBar.itemIdentifiers"]);
        ASSIGNCOPY(_principalItemIdentifier, [coder decodeObjectForKey: @"NSTouchBar.principalItemIdentifier"]);
        _showsFallbackWindow = [coder decodeBoolForKey: @"NSTouchBar.showsFallbackWindow"];
        _items = [[NSMutableDictionary alloc] init];
        _isVisible = NO;
        _delegate = nil;
        _fallbackWindow = nil;
        _fallbackContentView = nil;
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
    [coder encodeObject: _customizationIdentifier forKey: @"NSTouchBar.customizationIdentifier"];
    [coder encodeObject: _defaultItemIdentifiers forKey: @"NSTouchBar.defaultItemIdentifiers"];
    [coder encodeObject: _itemIdentifiers forKey: @"NSTouchBar.itemIdentifiers"];
    [coder encodeObject: _principalItemIdentifier forKey: @"NSTouchBar.principalItemIdentifier"];
    [coder encodeBool: _showsFallbackWindow forKey: @"NSTouchBar.showsFallbackWindow"];
}

/*
 * Accessor methods
 */

- (NSString *) customizationIdentifier
{
    return _customizationIdentifier;
}

- (void) setCustomizationIdentifier: (NSString *)identifier
{
    ASSIGNCOPY(_customizationIdentifier, identifier);
}

- (NSArray *) defaultItemIdentifiers
{
    return _defaultItemIdentifiers;
}

- (void) setDefaultItemIdentifiers: (NSArray *)identifiers
{
    ASSIGNCOPY(_defaultItemIdentifiers, identifiers);
}

- (NSArray *) itemIdentifiers
{
    return _itemIdentifiers;
}

- (void) setItemIdentifiers: (NSArray *)identifiers
{
    ASSIGNCOPY(_itemIdentifiers, identifiers);
    [self _updateItems];
}

- (NSString *) principalItemIdentifier
{
    return _principalItemIdentifier;
}

- (void) setPrincipalItemIdentifier: (NSString *)identifier
{
    ASSIGNCOPY(_principalItemIdentifier, identifier);
}

- (id) delegate
{
    return _delegate;
}

- (void) setDelegate: (id)delegate
{
    _delegate = delegate;
    [self _updateItems];
}

- (BOOL) isVisible
{
    return _isVisible;
}

- (BOOL) showsFallbackWindow
{
    return _showsFallbackWindow;
}

- (void) setShowsFallbackWindow: (BOOL)shows
{
    _showsFallbackWindow = shows;
    if (!shows)
    {
        [self hideFallbackWindow];
    }
}

/*
 * Item management
 */

- (NSTouchBarItem *) itemForIdentifier: (NSString *)identifier
{
    NSTouchBarItem *item = [_items objectForKey: identifier];
    
    if (!item && _delegate && [_delegate respondsToSelector: @selector(touchBar:makeItemForIdentifier:)])
    {
        item = [_delegate touchBar: self makeItemForIdentifier: identifier];
        if (item)
        {
            [_items setObject: item forKey: identifier];
        }
    }
    
    return item;
}

/*
 * Fallback window management
 */

- (void) showFallbackWindow
{
    if (!_showsFallbackWindow)
        return;
    
    GSTouchBarFallbackManager *manager = [GSTouchBarFallbackManager sharedManager];
    
    // Only show fallback window if no hardware is available
    if (![manager isTouchBarHardwareAvailable])
    {
        [manager showFallbackWindowForTouchBar: self];
        _isVisible = YES;
    }
}

- (void) hideFallbackWindow
{
    GSTouchBarFallbackManager *manager = [GSTouchBarFallbackManager sharedManager];
    [manager hideFallbackWindowForTouchBar: self];
    _isVisible = NO;
}

/*
 * Private methods
 */

- (void) _updateItems
{
    // Clear existing items that are no longer needed
    NSArray *currentKeys = [_items allKeys];
    NSEnumerator *keyEnumerator = [currentKeys objectEnumerator];
    NSString *key;
    
    while ((key = [keyEnumerator nextObject]) != nil)
    {
        if (![_itemIdentifiers containsObject: key])
        {
            [_items removeObjectForKey: key];
        }
    }
    
    // Update fallback window if visible
    if (_isVisible)
    {
        GSTouchBarFallbackManager *manager = [GSTouchBarFallbackManager sharedManager];
        GSTouchBarWindow *window = [manager fallbackWindowForTouchBar: self];
        if (window)
        {
            [window updateContent];
        }
    }
}

@end
