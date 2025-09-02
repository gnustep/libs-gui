/* Definition of class NSPDFImageRep
   Copyright (C) 2019 Free Software Foundation, Inc.

   By: Gregory Casamento <greg.casamento@gmail.com>
   Date: Fri Nov 15 04:24:27 EST 2019

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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

/**
 * <title>NSPDFImageRep</title>
 * <abstract>Image representation for PDF documents</abstract>
 *
 * NSPDFImageRep provides specialized image representation functionality for
 * PDF documents. This class extends NSImageRep to handle the display and
 * manipulation of PDF content, supporting multi-page documents with page
 * navigation and bounds calculation.
 *
 * Key features include:
 * - Loading PDF documents from NSData instances
 * - Multi-page document support with page navigation
 * - Current page tracking and manipulation
 * - Bounds calculation for proper layout and display
 * - PDF data preservation and access
 * - Integration with the NSImage system for display
 *
 * The class maintains the original PDF representation internally while
 * providing page-based access to individual pages within the document.
 * This allows applications to display PDF content within NSImage views
 * and handle page navigation for multi-page documents.
 *
 * NSPDFImageRep is commonly used for displaying PDF thumbnails, implementing
 * PDF viewers, or incorporating PDF content into documents and user interfaces.
 * The class handles the complexities of PDF rendering while providing a
 * simple page-oriented interface.
 */

#ifndef _NSPDFImageRep_h_GNUSTEP_GUI_INCLUDE
#define _NSPDFImageRep_h_GNUSTEP_GUI_INCLUDE
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSImageRep.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_0, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

APPKIT_EXPORT_CLASS
@interface NSPDFImageRep : NSImageRep
{
  NSArray *_pageReps;
  NSUInteger _currentPage;
  NSData *_pdfRepresentation;
}

/**
 * Creates a new PDF image representation from PDF data.
 * imageData: NSData containing the PDF document content
 * Returns: A new autoreleased NSPDFImageRep instance, or nil if the data is invalid
 */
+ (instancetype) imageRepWithData: (NSData *)imageData;

/**
 * Initializes a PDF image representation with PDF data.
 * imageData: NSData containing the PDF document content
 * Returns: An initialized NSPDFImageRep instance, or nil if the data is invalid
 */
- (instancetype) initWithData: (NSData *)imageData;

/**
 * Returns the bounding rectangle of the current page in the PDF document.
 * The bounds are in the PDF's coordinate system and may need transformation
 * for display purposes.
 * Returns: NSRect representing the bounds of the current page
 */
- (NSRect) bounds;

/**
 * Returns the zero-based index of the currently selected page.
 * Returns: The current page index, starting from 0
 */
- (NSInteger) currentPage;

/**
 * Sets the currently selected page for display and rendering operations.
 * currentPage: Zero-based page index to select (must be within page count bounds)
 */
- (void) setCurrentPage: (NSInteger)currentPage;

/**
 * Returns the total number of pages in the PDF document.
 * Returns: The number of pages available in the PDF document
 */
- (NSInteger) pageCount;

/**
 * Returns the original PDF data used to create this image representation.
 * This provides access to the complete PDF document for saving or further processing.
 * Returns: NSData containing the complete PDF document
 */
- (NSData *) PDFRepresentation;

@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSPDFImageRep_h_GNUSTEP_GUI_INCLUDE */

