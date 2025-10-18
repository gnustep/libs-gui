/** <title>NSScrubberTouchBarItem</title>

    <abstract>Touch bar item that displays an NSScrubber control</abstract>

    NSScrubberTouchBarItem is a specialized touch bar item that hosts
    an NSScrubber control, allowing horizontal scrolling lists to be
    displayed in the Touch Bar or fallback window.

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
    Library General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free
    Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110 USA.
*/

#ifndef _NSScrubberTouchBarItem_h_GNUSTEP_GUI_INCLUDE
#define _NSScrubberTouchBarItem_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSTouchBarItem.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSScrubber;

/**
 * NSScrubberTouchBarItem is a touch bar item that displays an NSScrubber control.
 */
APPKIT_EXPORT_CLASS
@interface NSScrubberTouchBarItem : NSTouchBarItem
{
    NSScrubber *_scrubber;
}

/**
 * The scrubber control displayed by this item.
 */
- (NSScrubber *) scrubber;
- (void) setScrubber: (NSScrubber *)scrubber;

/**
 * Creates a new scrubber touch bar item with the specified identifier.
 */
- (id) initWithIdentifier: (NSString *)identifier;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSScrubberTouchBarItem_h_GNUSTEP_GUI_INCLUDE */