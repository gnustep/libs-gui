/** <title>NSTouchBar</title>

    <abstract>Touch-sensitive control bar for modern Mac hardware support</abstract>

    NSTouchBar provides a framework for creating and managing touch-sensitive
    control bars that can be displayed on supporting hardware such as the
    MacBook Pro Touch Bar. It enables applications to present contextual
    controls and shortcuts that adapt to the current application state.

    The Touch Bar system provides:
    * Dynamic, contextual user interface elements
    * Touch-optimized controls and interactions
    * Integration with the responder chain for context-sensitive content
    * Support for standard controls like buttons, sliders, and text fields
    * Custom item creation and layout management

    NSTouchBar works by:
    * Automatically detecting available touch bar hardware
    * Managing item lifecycles and display coordination
    * Providing delegate methods for dynamic content updates
    * Supporting customization and user personalization
    * Gracefully degrading when touch hardware is unavailable

    Applications can use Touch Bars to:
    * Provide quick access to commonly used functions
    * Display contextual information and controls
    * Enhance productivity with touch-optimized interactions
    * Create adaptive interfaces that respond to user workflow

    Copyright (C) 2020 Free Software Foundation, Inc.

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
    Library General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free
    Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110 USA.
*/

#ifndef _NSTouchBar_h_GNUSTEP_GUI_INCLUDE
#define _NSTouchBar_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

APPKIT_EXPORT_CLASS
@interface NSTouchBar : NSObject

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSTouchBar_h_GNUSTEP_GUI_INCLUDE */

