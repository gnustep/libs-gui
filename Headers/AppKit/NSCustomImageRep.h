/*
   NSCustomImageRep.h

   Custom image representation.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Written by:  Adam Fedor <fedor@colorado.edu>
   Date: Feb 1996

   This file is part of the GNUstep GUI Library.

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
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSCustomImageRep
#define _GNUstep_H_NSCustomImageRep
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSImageRep.h>

/**
 * NSCustomImageRep provides a flexible way to create custom image representations
 * by delegating the actual drawing to another object. Instead of storing bitmap
 * data or vector graphics internally, this image representation calls a specified
 * method on a delegate object whenever the image needs to be drawn.
 *
 * This approach is particularly useful for creating dynamic images that are
 * generated programmatically, images that depend on current state or context,
 * or images that are too complex or memory-intensive to pre-render and cache.
 * The delegate-based drawing allows for real-time generation and infinite
 * scalability since the drawing is performed at render time.
 *
 * The delegate object must implement a drawing method that takes the custom
 * image representation as its parameter. This method is responsible for
 * performing all the drawing operations needed to render the image content
 * within the current graphics context.
 *
 * NSCustomImageRep integrates seamlessly with NSImage and the broader image
 * system, allowing custom-drawn content to be used anywhere standard image
 * representations can be used, including in image views, buttons, and other
 * graphical elements.
 */
APPKIT_EXPORT_CLASS
@interface NSCustomImageRep : NSImageRep
{
  // Attributes
  id  _delegate;
  SEL _selector;
}

/**
 * Initializes a custom image representation with a drawing delegate and selector.
 * Creates a new custom image representation that will call the specified selector
 * on the given delegate object whenever the image needs to be drawn. The delegate
 * method should perform all necessary drawing operations to render the image
 * content within the current graphics context.
 *
 * The aSelector parameter specifies the method to call on the delegate for drawing.
 * This method should take the NSCustomImageRep instance as its single parameter
 * and should not return a value. The anObject parameter specifies the delegate
 * object that will handle the drawing operations.
 *
 * The delegate object is not retained by the custom image representation, so the
 * caller must ensure the delegate remains valid for the lifetime of the image rep.
 * Returns a newly initialized custom image representation configured with the
 * specified delegate and drawing selector.
 */
- (id)initWithDrawSelector:(SEL)aSelector
		  delegate:(id)anObject;

//
// Identifying the Object
//

/**
 * Returns the delegate object responsible for drawing this image representation.
 * The delegate object contains the drawing logic that is called whenever this
 * custom image representation needs to be rendered. The delegate should implement
 * the method specified by the drawing selector and perform all necessary drawing
 * operations within the current graphics context.
 *
 * The delegate is not retained by the custom image representation, so callers
 * should ensure the delegate object remains valid for the lifetime of the image rep.
 * Returns the delegate object, or nil if no delegate has been set.
 */
- (id)delegate;

/**
 * Returns the selector for the drawing method called on the delegate.
 * This selector identifies the method that will be invoked on the delegate object
 * whenever the custom image representation needs to be drawn. The method should
 * take the NSCustomImageRep instance as its parameter and perform all drawing
 * operations needed to render the image content.
 *
 * The drawing method is called within the context of the current graphics state,
 * so the delegate can use standard drawing operations and expect them to appear
 * in the correct location and with the appropriate transformations applied.
 * Returns the selector for the delegate's drawing method.
 */
- (SEL)drawSelector;

@end

#endif // _GNUstep_H_NSCustomImageRep
