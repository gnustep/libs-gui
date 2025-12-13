/* Implementation of class GSTouchBarWindow
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

#import <AppKit/GSTouchBarWindow.h>
#import <AppKit/NSTouchBar.h>
#import <AppKit/NSTouchBarItem.h>
#import <AppKit/NSView.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSColor.h>
#import <Foundation/NSMutableDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNotificationCenter.h>

@implementation GSTouchBarWindow

/* * Class methods */

+ (void) initialize
{
    if (self == [GSTouchBarWindow class])
    {
        [self setVersion: 1];
    }
}

/*
 * Initialization and deallocation
 */

- (id) initWithTouchBar: (NSTouchBar *)touchBar
{
    NSRect frame = NSMakeRect(0, 0, 600, 60);
    NSUInteger styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
    
    self = [super initWithContentRect: frame
                            styleMask: styleMask
                              backing: NSBackingStoreBuffered
                                defer: NO];
    
    if (self)
    {
        ASSIGN(_touchBar, touchBar);
        _autoHidesOnDeactivate = YES;
        _itemViews = [[NSMutableArray alloc] init];
        
        [self setTitle: @"Touch Bar"];
        [self setLevel: NSFloatingWindowLevel];
        [self setHidesOnDeactivate: NO];
        
        [self _setupContent];
        [self updateContent];
        [self positionRelativeToMainWindow];
        
        // Register for application state notifications
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver: self
                   selector: @selector(_applicationDidBecomeActive:)
                       name: NSApplicationDidBecomeActiveNotification
                     object: nil];
        [center addObserver: self
                   selector: @selector(_applicationDidResignActive:)
                       name: NSApplicationDidResignActiveNotification
                     object: nil];
    }
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    RELEASE(_touchBar);
    RELEASE(_itemViews);
    RELEASE(_itemContainerView);
    [super dealloc];
}

/*
 * Accessor methods
 */

- (NSTouchBar *) touchBar
{
    return _touchBar;
}

- (void) setTouchBar: (NSTouchBar *)touchBar
{
    ASSIGN(_touchBar, touchBar);
    [self updateContent];
}

- (BOOL) autoHidesOnDeactivate
{
    return _autoHidesOnDeactivate;
}

- (void) setAutoHidesOnDeactivate: (BOOL)autoHides
{
    _autoHidesOnDeactivate = autoHides;
}

/*
 * Content management
 */

- (void) updateContent
{
    if (!_itemContainerView || !_touchBar)
        return;
    
    // Remove existing items
    NSEnumerator *enumerator = [_itemViews objectEnumerator];
    NSView *itemView;
    
    while ((itemView = [enumerator nextObject]) != nil)
    {
        [itemView removeFromSuperview];
    }
    [_itemViews removeAllObjects];
    
    // Add current touch bar items
    NSArray *identifiers = [_touchBar itemIdentifiers];
    if (identifiers)
    {
        enumerator = [identifiers objectEnumerator];
        NSString *identifier;
        
        while ((identifier = [enumerator nextObject]) != nil)
        {
            NSTouchBarItem *item = [_touchBar itemForIdentifier: identifier];
            if (item && [item isVisible])
            {
                itemView = [item view];
                if (itemView)
                {
                    [_itemContainerView addSubview: itemView];
                    [_itemViews addObject: itemView];
                }
                else
                {
                    // Create placeholder for space items
                    NSView *spacer = [self _createSpacerForIdentifier: identifier];
                    if (spacer)
                    {
                        [_itemContainerView addSubview: spacer];
                        [_itemViews addObject: spacer];
                    }
                }
            }
        }
    }
    
    [self _layoutItemViews];
}

- (void) positionRelativeToMainWindow
{
    NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
    NSRect mainFrame, windowFrame;
    
    if (mainWindow)
    {
        mainFrame = [mainWindow frame];
        windowFrame = [self frame];
        
        // Position below the main window
        windowFrame.origin.x = mainFrame.origin.x + (NSWidth(mainFrame) - NSWidth(windowFrame)) / 2;
        windowFrame.origin.y = mainFrame.origin.y - NSHeight(windowFrame) - 20;
        
        [self setFrame: windowFrame display: YES];
    }
    else
    {
        [self center];
    }
}

/*
 * Private methods
 */

- (void) _setupContent
{
    // Create container view for items
    NSRect contentBounds = [[self contentView] bounds];
    _itemContainerView = [[NSView alloc] initWithFrame: NSInsetRect(contentBounds, 10, 10)];
    [_itemContainerView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    [[self contentView] addSubview: _itemContainerView];
    
    // Set background color to match Touch Bar appearance
    NSColor *backgroundColor = [NSColor colorWithCalibratedRed: 0.2 green: 0.2 blue: 0.2 alpha: 1.0];
    [self setBackgroundColor: backgroundColor];
}

- (void) _layoutItemViews
{
    NSRect containerBounds = [_itemContainerView bounds];
    NSUInteger itemCount = [_itemViews count];
    
    if (itemCount == 0)
        return;
    
    CGFloat totalWidth = NSWidth(containerBounds);
    CGFloat spacing = 8.0;
    CGFloat availableWidth = totalWidth - (spacing * (itemCount - 1));
    CGFloat itemWidth = availableWidth / itemCount;
    CGFloat currentX = 0;
    
    NSEnumerator *enumerator = [_itemViews objectEnumerator];
    NSView *itemView;
    
    while ((itemView = [enumerator nextObject]) != nil)
    {
        NSRect itemFrame = NSMakeRect(currentX, 
                                     (NSHeight(containerBounds) - 30) / 2, 
                                     itemWidth, 
                                     30);
        [itemView setFrame: itemFrame];
        currentX += itemWidth + spacing;
    }
}

- (NSView *) _createSpacerForIdentifier: (NSString *)identifier
{
    NSView *spacer = nil;
    CGFloat width = 0;
    
    if ([identifier isEqualToString: NSTouchBarItemIdentifierFixedSpaceSmall])
    {
        width = 16;
    }
    else if ([identifier isEqualToString: NSTouchBarItemIdentifierFixedSpaceLarge])
    {
        width = 32;
    }
    else if ([identifier isEqualToString: NSTouchBarItemIdentifierFlexibleSpace])
    {
        width = 20; // Will expand in stack view
    }
    
    if (width > 0)
    {
        spacer = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, width, 30)]);
    }
    
    return spacer;
}

/*
 * Notification handlers
 */

- (void) _applicationDidBecomeActive: (NSNotification *)notification
{
    if ([self isVisible])
    {
        [self orderFront: nil];
    }
}

- (void) _applicationDidResignActive: (NSNotification *)notification
{
    if (_autoHidesOnDeactivate)
    {
        [self orderOut: nil];
    }
}

@end

@implementation GSTouchBarFallbackManager

static GSTouchBarFallbackManager *_sharedManager = nil;

/* * Class methods */

+ (void) initialize
{
    if (self == [GSTouchBarFallbackManager class])
    {
        [self setVersion: 1];
    }
}

+ (GSTouchBarFallbackManager *) sharedManager
{
    if (_sharedManager == nil)
    {
        _sharedManager = [[GSTouchBarFallbackManager alloc] init];
    }
    return _sharedManager;
}

/*
 * Initialization and deallocation
 */

- (id) init
{
    self = [super init];
    if (self)
    {
        _fallbackWindows = [[NSMutableDictionary alloc] init];
        _touchBarHardwareAvailable = [self _detectTouchBarHardware];
    }
    return self;
}

- (void) dealloc
{
    [_fallbackWindows release];
    [super dealloc];
}

/*
 * Hardware detection
 */

- (BOOL) isTouchBarHardwareAvailable
{
    return _touchBarHardwareAvailable;
}

- (BOOL) _detectTouchBarHardware
{
    // On Linux and most systems, Touch Bar hardware is not available
    // This could be enhanced to check for specific hardware or environment variables
    return NO;
}

/*
 * Fallback window management
 */

- (void) showFallbackWindowForTouchBar: (NSTouchBar *)touchBar
{
    if (!touchBar)
        return;
    
    NSString *key = [NSString stringWithFormat: @"%p", touchBar];
    GSTouchBarWindow *window = [_fallbackWindows objectForKey: key];
    
    if (!window)
    {
        window = [[GSTouchBarWindow alloc] initWithTouchBar: touchBar];
        [_fallbackWindows setObject: window forKey: key];
        [window release]; // Retained by dictionary
    }
    
    [window makeKeyAndOrderFront: nil];
}

- (void) hideFallbackWindowForTouchBar: (NSTouchBar *)touchBar
{
    if (!touchBar)
        return;
    
    NSString *key = [NSString stringWithFormat: @"%p", touchBar];
    GSTouchBarWindow *window = [_fallbackWindows objectForKey: key];
    
    if (window)
    {
        [window orderOut: nil];
        [_fallbackWindows removeObjectForKey: key];
    }
}

- (GSTouchBarWindow *) fallbackWindowForTouchBar: (NSTouchBar *)touchBar
{
    if (!touchBar)
        return nil;
    
    NSString *key = [NSString stringWithFormat: @"%p", touchBar];
    return [_fallbackWindows objectForKey: key];
}

@end