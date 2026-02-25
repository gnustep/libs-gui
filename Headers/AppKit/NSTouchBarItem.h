/* Definition of class NSTouchBarItem
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
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#ifndef _NSTouchBarItem_h_GNUSTEP_GUI_INCLUDE
#define _NSTouchBarItem_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSView;

/**
 * Standard touch bar item identifiers
 */
extern NSString * const NSTouchBarItemIdentifierFixedSpaceSmall;
extern NSString * const NSTouchBarItemIdentifierFixedSpaceLarge;
extern NSString * const NSTouchBarItemIdentifierFlexibleSpace;

/**
 * NSTouchBarItem represents a single item in a touch bar.
 */
APPKIT_EXPORT_CLASS
@interface NSTouchBarItem : NSObject <NSCoding>
{
    NSString *_identifier;
    NSView *_view;
    NSString *_customizationLabel;
    BOOL _isVisible;
}

/**
 * The unique identifier for this item.
 */
- (NSString *) identifier;

/**
 * The view that represents this item's content.
 */
- (NSView *) view;
- (void) setView: (NSView *)view;

/**
 * The localized string labeling this item during customization.
 */
- (NSString *) customizationLabel;
- (void) setCustomizationLabel: (NSString *)label;

/**
 * Whether this item is currently visible.
 */
- (BOOL) isVisible;

/**
 * Creates a new touch bar item with the specified identifier.
 */
- (id) initWithIdentifier: (NSString *)identifier;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSTouchBarItem_h_GNUSTEP_GUI_INCLUDE */

