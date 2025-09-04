/* -*-objc-*-
   NSImageView.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: January 1998

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

/**
 * <title>NSImageView</title>
 * <abstract>Control for displaying and editing images</abstract>
 *
 * NSImageView provides a specialized control for displaying images with
 * various presentation options including alignment, scaling, and framing.
 * The view extends NSControl to provide image-specific functionality while
 * maintaining integration with the target-action pattern and responder chain.
 *
 * Key features include:
 * - Image display with multiple alignment options
 * - Flexible scaling modes for image fitting and presentation
 * - Frame styles for visual enhancement
 * - Optional image editing capabilities
 * - Cut, copy, and paste support for image manipulation
 * - Animation support for animated image formats
 * - Drag and drop integration for image transfer
 * - Integration with NSImageCell for consistent behavior
 *
 * The image view automatically handles image rendering, scaling, and
 * positioning based on the configured alignment and scaling modes.
 * Frame styles provide visual context including bezels, grooves, and
 * photo frame appearances.
 *
 * For interactive applications, the view supports editing mode which
 * allows users to replace the displayed image. Cut, copy, and paste
 * operations enable integration with the system pasteboard for image
 * transfer between applications.
 *
 * The view works seamlessly with animated image formats, providing
 * automatic animation control when appropriate content is loaded.
 */

#ifndef _GNUstep_H_NSImageView
#define _GNUstep_H_NSImageView
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSControl.h>
#import <AppKit/NSImageCell.h>

APPKIT_EXPORT_CLASS
@interface NSImageView : NSControl
{
  id _target;
  SEL _action;
  struct GSImageViewFlagsType {
    // total 32 bits.  30 bits left.
    unsigned allowsCutCopyPaste: 1;
    unsigned initiatesDrag: 1;
  } _ivflags;
}

/**
 * Returns the currently displayed image.
 * Returns: The NSImage instance being displayed, or nil if no image is set
 */
- (NSImage *)image;

/**
 * Sets the image to display in the view.
 * image: The NSImage to display, or nil to clear the current image
 */
- (void)setImage:(NSImage *)image;

/**
 * Returns the image alignment within the view frame.
 * Returns: The NSImageAlignment value specifying how the image is positioned
 * when smaller than the view bounds
 */
- (NSImageAlignment)imageAlignment;

/**
 * Sets the alignment of the image within the view.
 * align: The NSImageAlignment specifying image positioning (left, center, right, top, bottom, etc.)
 */
- (void)setImageAlignment:(NSImageAlignment)align;
/**
 * Returns the image scaling behavior.
 * Returns: The NSImageScaling value indicating how the image is scaled
 * to fit the view bounds
 */
- (NSImageScaling)imageScaling;

/**
 * Sets the scaling behavior for the image.
 * scaling: The NSImageScaling mode (proportional, fit to bounds, none, etc.)
 */
- (void)setImageScaling:(NSImageScaling)scaling;
/**
 * Returns the style of frame drawn around the image.
 * Returns: The NSImageFrameStyle value indicating the border appearance
 */
- (NSImageFrameStyle)imageFrameStyle;

/**
 * Sets the style of frame to draw around the image.
 * style: The NSImageFrameStyle (none, photo, bezel, groove, etc.)
 */
- (void)setImageFrameStyle:(NSImageFrameStyle)style;
/**
 * Sets whether the image can be edited by the user.
 * flag: YES to allow editing (drag-and-drop image replacement), NO to disable
 */
- (void)setEditable:(BOOL)flag;

/**
 * Returns whether the image view allows user editing.
 * Returns: YES if users can replace the image via drag-and-drop, NO otherwise
 */
- (BOOL)isEditable;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
/**
 * Returns whether the image view animates animated images.
 * Returns: YES if animated images (like GIFs) are played, NO if only first frame shows
 */
- (BOOL)animates;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 * Sets whether animated images should be animated.
 * flag: YES to play animated images, NO to show only the first frame
 */
- (void)setAnimates:(BOOL)flag;

/**
 * Returns whether cut, copy, and paste operations are allowed.
 * Returns: YES if clipboard operations are enabled, NO otherwise
 */
- (BOOL)allowsCutCopyPaste;

/**
 * Sets whether cut, copy, and paste operations are allowed.
 * flag: YES to enable clipboard operations, NO to disable
 */
- (void)setAllowsCutCopyPaste:(BOOL)flag;
#endif
#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)
/**
 * Creates and returns a new image view configured with the specified image.
 * image: The NSImage to display in the new image view
 * Returns: An initialized NSImageView instance displaying the image
 */
+ (instancetype) imageViewWithImage: (NSImage *)image;
#endif

@end

#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
/*
 * Methods that are GNUstep extensions
 */
@interface NSImageView (GNUstep)

/**
 * Returns whether the image view initiates drag operations when the user drags the image.
 * Returns: YES if dragging the image starts a drag operation, NO otherwise
 */
- (BOOL)initiatesDrag;

/**
 * Sets whether the image view should initiate drag operations.
 * flag: YES to enable drag operations when users drag the image, NO to disable
 */
- (void)setInitiatesDrag: (BOOL)flag;

@end
#endif
#endif /* _GNUstep_H_NSImageView */
