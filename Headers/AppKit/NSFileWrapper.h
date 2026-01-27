/*
   NSFileWrapper.h

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

#ifndef _GNUstep_H_NSFileWrapper_GUI
#define _GNUstep_H_NSFileWrapper_GUI

/**
 * This header provides AppKit applications with access to NSFileWrapper,
 * which is primarily defined in Foundation. NSFileWrapper objects hold
 * a file's contents in dynamic memory and provide a convenient way to
 * work with files and directories as objects.
 *
 * In the context of AppKit applications, NSFileWrapper is commonly used
 * with document-based applications, drag and drop operations, and anywhere
 * file system entities need to be represented as objects. The class
 * supports files, directories, and symbolic links, providing a unified
 * interface for manipulating file system structures.
 *
 * Key capabilities include:
 * - Reading files and directories into memory
 * - Creating new file wrappers programmatically
 * - Writing file wrappers back to the file system
 * - Maintaining file attributes and metadata
 * - Supporting nested directory structures
 * - Handling symbolic links appropriately
 *
 * For document-based applications, NSFileWrapper provides an excellent
 * foundation for implementing document packages (bundles) and complex
 * document formats that consist of multiple files and directories.
 *
 * The complete interface and documentation for NSFileWrapper can be
 * found in Foundation/NSFileWrapper.h. AppKit-specific extensions,
 * if any, are provided through categories defined elsewhere in the
 * AppKit framework.
 */
#import <Foundation/NSFileWrapper.h>

#endif
