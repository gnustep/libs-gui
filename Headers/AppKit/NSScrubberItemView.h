/* Definition of class NSScrubberItemView
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

#ifndef _NSScrubberItemView_h_GNUSTEP_GUI_INCLUDE
#define _NSScrubberItemView_h_GNUSTEP_GUI_INCLUDE

#import "AppKit/NSView.h"

#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

/**
 * NSScrubberArrangedView is the base class for views that can be arranged
 * within a scrubber layout.
 */
APPKIT_EXPORT_CLASS
@interface NSScrubberArrangedView : NSView

@end

/**
 * NSScrubberItemView represents an individual item within an NSScrubber.
 * This is the base class for custom item views in a scrubber control.
 */
APPKIT_EXPORT_CLASS
@interface NSScrubberItemView : NSScrubberArrangedView
{
    NSString *_reuseIdentifier;
}

/**
 * Returns the reuse identifier associated with this item view.
 * Used by the scrubber to efficiently reuse item views.
 */
- (NSString *) reuseIdentifier;

/**
 * Sets the reuse identifier associated with this item view.
 * reuseIdentifier is the identifier string.
 */
- (void) setReuseIdentifier: (NSString *)reuseIdentifier;

/**
 * Prepares the item view for reuse by clearing any view-specific content.
 * Subclasses should override this method to reset their content to a default state.
 */
- (void) prepareForReuse;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSScrubberItemView_h_GNUSTEP_GUI_INCLUDE */

