/*
   NSEPSImageRep.h

   EPS image representation.

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
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

/**
 * <title>NSEPSImageRep</title>
 * <abstract>Image representation for Encapsulated PostScript (EPS) files</abstract>
 *
 * NSEPSImageRep provides specialized image representation functionality for
 * Encapsulated PostScript (EPS) documents. This class extends NSImageRep to
 * handle the display and manipulation of vector-based EPS content, supporting
 * both the preservation of original PostScript code and rendering to bitmap
 * formats when needed.
 *
 * Key features include:
 * - Loading EPS documents from NSData instances
 * - Bounding box calculation for proper layout and scaling
 * - Preservation of original PostScript code for high-quality output
 * - Integration with the graphics state system for rendering
 * - Automatic bitmap conversion when pixel-based operations are required
 * - Support for both display and printing workflows
 *
 * EPS files contain vector graphics described in PostScript language along
 * with a bounding box that defines the image dimensions. This class handles
 * the parsing of EPS headers to extract bounding box information and manages
 * the transition between vector and bitmap representations as needed.
 *
 * The class is commonly used for importing illustrations, logos, and other
 * vector graphics into applications while maintaining their scalable nature.
 * When high-resolution output is required, the original PostScript code is
 * preserved for optimal quality.
 */

#ifndef _GNUstep_H_NSEPSImageRep
#define _GNUstep_H_NSEPSImageRep
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSGeometry.h>
#import <AppKit/NSImageRep.h>

@class NSData;

APPKIT_EXPORT_CLASS
@interface NSEPSImageRep : NSImageRep
{
  // Attributes
  NSBitmapImageRep *_pageRep;
  NSRect _bounds;
  NSData *_epsData;
}

//
// Initializing a New Instance
//

/**
 * Creates a new EPS image representation from EPS data.
 * epsData: NSData containing the Encapsulated PostScript content
 * Returns: A new autoreleased NSEPSImageRep instance, or nil if the data is invalid
 */
+ (id)imageRepWithData:(NSData *)epsData;

/**
 * Initializes an EPS image representation with EPS data.
 * This method parses the EPS data to extract bounding box information and
 * prepares the representation for rendering operations.
 * epsData: NSData containing the Encapsulated PostScript content
 * Returns: An initialized NSEPSImageRep instance, or nil if the data is invalid
 */
- (id)initWithData:(NSData *)epsData;

//
// Getting Image Data
//

/**
 * Returns the bounding box of the EPS image.
 * The bounding box is extracted from the EPS header and defines the
 * coordinate space and dimensions of the PostScript content.
 * Returns: NSRect representing the EPS bounding box in PostScript coordinates
 */
- (NSRect)boundingBox;

/**
 * Returns the original EPS data used to create this image representation.
 * This provides access to the complete PostScript code for high-quality
 * output or further processing.
 * Returns: NSData containing the original Encapsulated PostScript content
 */
- (NSData *)EPSRepresentation;

//
// Drawing the Image
//

/**
 * Prepares the graphics state for EPS rendering.
 * This method sets up the necessary graphics state parameters and coordinate
 * transformations required for proper PostScript interpretation. It should be
 * called before rendering EPS content to ensure correct display.
 */
- (void)prepareGState;

@end

#endif // _GNUstep_H_NSEPSImageRep

