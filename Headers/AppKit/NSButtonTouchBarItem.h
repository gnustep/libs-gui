/** <title>NSButtonTouchBarItem</title>

    <abstract>Button control item for Touch Bar interfaces</abstract>

    NSButtonTouchBarItem provides a touch-optimized button control specifically
    designed for Touch Bar interfaces. It extends the basic NSTouchBarItem
    functionality to provide button-specific features such as titles, images,
    colors, and action handling optimized for touch interaction.

    This Touch Bar item supports:
    * Text labels with automatic font optimization for Touch Bar display
    * Icon and image display with appropriate sizing and rendering
    * Background colors and visual styling for touch interfaces
    * Target-action pattern for handling touch events
    * Enabled/disabled state management
    * Integration with accessibility services

    The button automatically adapts its appearance for the Touch Bar environment:
    * Optimized sizing and spacing for finger-based interaction
    * High-contrast rendering for the Touch Bar display characteristics
    * Dynamic type support for accessibility and user preferences
    * Visual feedback for touch interactions and state changes

    NSButtonTouchBarItem is commonly used for:
    * Primary actions and commands relevant to the current context
    * Quick access to frequently used application functions
    * Modal confirmations and secondary action options
    * Navigation and workflow control within Touch Bar interfaces

    Copyright (C) 2019 Free Software Foundation, Inc.

    By: Gregory John Casamento
    Date: Thu Dec  5 12:44:26 EST 2019

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
    License along with this library; see the file COPYING.LIB.
    If not, see <http://www.gnu.org/licenses/> or write to the
    Free Software Foundation, 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#ifndef _NSButtonTouchBarItem_h_GNUSTEP_GUI_INCLUDE
#define _NSButtonTouchBarItem_h_GNUSTEP_GUI_INCLUDE

#import <AppKit/NSTouchBarItem.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

APPKIT_EXPORT_CLASS
@interface NSButtonTouchBarItem : NSTouchBarItem

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSButtonTouchBarItem_h_GNUSTEP_GUI_INCLUDE */

