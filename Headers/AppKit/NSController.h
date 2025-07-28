/** <title>NSController</title>

   <abstract>abstract base class for controllers</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date: June 2006

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

/**
 *  Class: NSController
 *  Description: Abstract base class for controllers. NSController provides a common
 *               interface for managing editing and communication between a model
 *               and view objects, and is the superclass of concrete controller classes
 *               like NSObjectController and NSArrayController.
 *
 *  Instance Variables:
 *    _editors        - An array of objects currently editing the controller's values.
 *    _declared_keys  - An array of key names that the controller is managing.
 */

#ifndef _GNUstep_H_NSController
#define _GNUstep_H_NSController
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)

@class NSMutableArray;

APPKIT_EXPORT_CLASS
@interface NSController : NSObject <NSCoding>
{
  NSMutableArray *_editors;
  NSMutableArray *_declared_keys;
}

// NSEditor protocol

/**
 *  Commits all pending edits to the underlying model.
 *  Returns YES if editing was successfully committed.
 */
- (BOOL) commitEditing;

/**
 *  Discards any uncommitted changes made by editors.
 */
- (void) discardEditing;

/**
 *  Returns whether any registered editors are currently editing.
 */
- (BOOL) isEditing;

// NSEditorRegistration protocol

/**
 *  Registers that a specific editor has started editing.
 */
- (void) objectDidBeginEditing: (id)editor;

/**
 *  Unregisters the editor indicating editing is complete.
 */
- (void) objectDidEndEditing: (id)editor;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 *  Commits editing and notifies a delegate when the operation completes.
 */
- (void) commitEditingWithDelegate: (id)delegate
		 didCommitSelector: (SEL)didCommitSelector
		       contextInfo: (void*)contextInfo;
#endif

@end

#endif // OS_API_VERSION

#endif // _GNUstep_H_NSController
