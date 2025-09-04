/*
   NSFileWrapperExtensions.h

   NSFileWrapper objects hold a file's contents in dynamic memory.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Sept 1998

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

#ifndef _GNUstep_H_NSFileWrapper_Extensions
#define _GNUstep_H_NSFileWrapper_Extensions
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSFileWrapper.h>

@class NSImage;

/**
 * <title>NSFileWrapperExtensions</title>
 * <abstract>AppKit extensions to NSFileWrapper for icon support</abstract>
 *
 * This category extends the Foundation NSFileWrapper class with AppKit-specific
 * functionality, primarily adding support for associating icons with file wrappers.
 * These extensions allow file wrappers to carry visual representations that can
 * be used in user interfaces for displaying files and directories.
 *
 * The icon support is particularly useful when working with document-based
 * applications or file browsers where visual representation of files enhances
 * the user experience. The icons are stored as part of the file wrapper's
 * metadata and can be serialized along with the file wrapper's content.
 */
@interface NSFileWrapper (NSExtensions)

/**
 * Sets the icon image for this file wrapper.
 *
 * Associates an NSImage with this file wrapper that can be used as a visual
 * representation of the wrapped file or directory. The icon is stored as part
 * of the file wrapper's metadata and will be preserved when the file wrapper
 * is archived or serialized.
 *
 * This method is commonly used to provide custom icons for document types,
 * special directories, or other file system objects that benefit from
 * distinctive visual representation in user interfaces.
 *
 * @param icon The NSImage to use as the icon for this file wrapper.
 *            Pass nil to remove any existing icon association.
 */
- (void) setIcon: (NSImage*)icon;

/**
 * Returns the icon image associated with this file wrapper.
 *
 * Retrieves the NSImage that has been set as the icon for this file wrapper
 * using setIcon:. If no icon has been explicitly set, this method may return
 * a default icon based on the file wrapper's type and content, or nil if
 * no icon is available.
 *
 * The returned icon can be used in user interface elements such as file
 * browsers, document lists, or anywhere a visual representation of the
 * file wrapper is needed.
 *
 * @return The NSImage associated with this file wrapper as its icon,
 *         or nil if no icon is available.
 */
- (NSImage*) icon;

@end

#endif
