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
 * NSController is an abstract base class that provides the foundational infrastructure
 * for controller objects in Cocoa's Model-View-Controller (MVC) architecture.
 * It serves as the superclass for concrete controller classes like NSObjectController,
 * NSArrayController, and NSTreeController.
 *
 * Key responsibilities include:
 * - Managing editing sessions and editor registration
 * - Providing a common interface for model-view communication
 * - Handling commit and discard operations for pending changes
 * - Supporting the NSEditor and NSEditorRegistration protocols
 * - Enabling Key-Value Observing (KVO) integration
 * - Managing declared keys for automatic observation
 *
 * NSController implements the NSEditor protocol to participate in editing
 * hierarchies, allowing controllers to be composed and managed by other controllers.
 * It also implements NSEditorRegistration to manage child editors that are
 * editing the controller's content.
 *
 * Subclasses should override the abstract methods to provide specific behavior
 * for their particular model management strategies. The base class provides
 * the infrastructure for tracking active editors and coordinating editing
 * operations across the controller hierarchy.
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
  /**
   * Array of objects currently registered as editors with this controller.
   * These editors are notified when editing operations begin or end, and
   * the controller coordinates commit and discard operations across all
   * registered editors.
   */
  NSMutableArray *_editors;

  /**
   * Array of key names that this controller is managing through Key-Value
   * Observing (KVO). These keys are automatically observed when the
   * controller is configured, enabling automatic updates when model
   * values change.
   */
  NSMutableArray *_declared_keys;
}

// NSEditor protocol

/**
 * Commits all pending edits to the underlying model objects.
 * This method coordinates with all registered editors to ensure that
 * any uncommitted changes are properly saved to the model. The operation
 * may fail if validation errors occur during the commit process.
 * Returns: YES if all edits were successfully committed, NO if errors occurred
 */
- (BOOL) commitEditing;

/**
 * Discards any uncommitted changes made by registered editors.
 * This method instructs all registered editors to abandon their current
 * changes and revert to the last committed state. This operation cannot
 * fail and will always restore the controller to a clean state.
 */
- (void) discardEditing;

/**
 * Returns whether any registered editors are currently in an editing state.
 * This method checks if any of the registered editors have uncommitted
 * changes that need to be either committed or discarded before the
 * controller can be safely released or reconfigured.
 * Returns: YES if editing is in progress, NO if all editors are inactive
 */
- (BOOL) isEditing;

// NSEditorRegistration protocol

/**
 * Registers that a specific editor has started editing controller content.
 * This method should be called by editor objects when they begin an editing
 * session. The controller maintains a list of active editors and uses this
 * information to coordinate commit and discard operations. The editor will
 * remain registered until objectDidEndEditing: is called.
 * editor: The object that has begun editing controller content
 */
- (void) objectDidBeginEditing: (id)editor;

/**
 * Unregisters an editor, indicating that editing is complete.
 * This method should be called by editor objects when they finish an editing
 * session, either through successful commit or discard of changes. The
 * controller removes the editor from its list of active editors and may
 * perform cleanup operations as needed.
 * editor: The object that has finished editing controller content
 */
- (void) objectDidEndEditing: (id)editor;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 * Commits editing asynchronously and notifies a delegate when complete.
 * This method provides an asynchronous alternative to commitEditing that
 * allows the caller to be notified when the commit operation completes.
 * This is particularly useful for operations that may take time to complete
 * or when the UI needs to remain responsive during the commit process.
 *
 * The delegate method signature should be:
 * - (void)editor:(id)editor didCommit:(BOOL)didCommit contextInfo:(void *)contextInfo
 *
 * delegate: The object to notify when the commit operation completes
 * didCommitSelector: The selector to call on the delegate (must match signature above)
 * contextInfo: User-defined context data to pass to the delegate method
 */
- (void) commitEditingWithDelegate: (id)delegate
		 didCommitSelector: (SEL)didCommitSelector
		       contextInfo: (void*)contextInfo;
#endif

@end

#endif // OS_API_VERSION

#endif // _GNUstep_H_NSController
