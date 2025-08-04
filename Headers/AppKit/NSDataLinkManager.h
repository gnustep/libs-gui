/*
   NSDataLinkManager.h

   Manager of a NSDataLink

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996

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

#ifndef _GNUstep_H_NSDataLinkManager
#define _GNUstep_H_NSDataLinkManager

#import <Foundation/NSObject.h>
#import "AppKit/AppKitDefines.h"
#import "AppKit/NSDataLink.h"

@class NSEnumerator;
@class NSMutableArray;
@class NSPasteboard;
@class NSString;
@class NSSelection;
@class NSThread;
@class NSWindow;

APPKIT_EXPORT_CLASS
@interface NSDataLinkManager : NSObject <NSCoding>
{
  // Attributes
  id                   _delegate;
  NSString            *_filename;
  NSMutableArray      *_sourceLinks;
  NSMutableArray      *_destinationLinks;
  NSDataLinkNumber     _nextLinkNumber;
  NSThread            *_monitorThread;
  int                  _inotifyFD;
  NSMutableDictionary *_watchDescriptors;

  struct __dlmFlags {
    unsigned areLinkOutlinesVisible:1;
    unsigned delegateVerifiesLinks:1;
    unsigned interactsWithUser:1;
    unsigned isEdited:1;
  } _flags;
}

//
// Initializing and Freeing a Link Manager
//

/** Initializes a link manager with a delegate.
 * Creates a new NSDataLinkManager with the specified delegate.
 * The delegate will receive callbacks for link management events.
 */
- (id) initWithDelegate: (id)anObject;

/** Initializes a link manager with a delegate and associates it with a file.
 * Creates a new NSDataLinkManager with the specified delegate and
 * associates it with a particular file. This is typically used when
 * the manager represents links within a specific document.
 */
- (id) initWithDelegate: (id)anObject
               fromFile: (NSString *)path;

//
// Adding and Removing Links
//

/** Adds a destination link at the specified selection.
 * Registers a new data link as a destination within this manager.
 * The link will be positioned at the given selection and the manager
 * will monitor it for updates. Triggers startTrackingLink delegate callback.
 */
- (BOOL)addLink: (NSDataLink *)link
	     at: (NSSelection *)selection;

/** Adds a source link to this manager.
 * Registers a new data link as a source within this manager.
 * The manager will monitor the source for changes and can provide
 * data to destination links. Triggers startTrackingLink delegate callback.
 */
- (BOOL)addSourceLink: (NSDataLink *)link;

/** Adds a link as a marker at the specified selection.
 * Adds a data link that serves only as a position marker.
 * Marker links don't transfer data but can be useful for UI purposes.
 */
- (BOOL)addLinkAsMarker: (NSDataLink *)link
		     at: (NSSelection *)selection;

/** Recreates a link that was previously at another location.
 * Used when moving or copying links between documents.
 * Attempts to restore a link from pasteboard data.
 */
- (NSDataLink *)addLinkPreviouslyAt: (NSSelection *)oldSelection
		     fromPasteboard: (NSPasteboard *)pasteboard
				 at: (NSSelection *)selection;

/** Removes a specific link from this manager.
 * Removes the specified link from both source and destination collections.
 * Triggers stopTrackingLink delegate callback for proper cleanup.
 */
- (void)removeLink: (NSDataLink *)link;

/** Breaks all links managed by this manager.
 * Permanently breaks all source and destination links.
 * Each link will be broken individually and delegate callbacks
 * will be triggered for each one.
 */
- (void)breakAllLinks;

/** Writes all source links to the pasteboard.
 * Puts data for all source links onto the pasteboard,
 * allowing them to be pasted into other documents.
 */
- (void)writeLinksToPasteboard: (NSPasteboard *)pasteboard;

//
// Informing the Link Manager of Document Status
//

/** Notifies the manager that its document is closing.
 * Call this when the document associated with this manager is being closed.
 * Triggers the dataLinkManagerCloseDocument delegate callback.
 */
- (void)noteDocumentClosed;

/** Notifies the manager that its document has been edited.
 * Call this when the document has been modified.
 * Triggers the dataLinkManagerDidEditLinks delegate callback.
 */
- (void)noteDocumentEdited;

/** Notifies the manager that its document has been reverted.
 * Call this when the document has been reverted to a saved state.
 * Triggers the dataLinkManagerDidEditLinks delegate callback.
 */
- (void)noteDocumentReverted;

/** Notifies the manager that its document has been saved.
 * Updates timestamps for all source links and triggers update
 * checking for destination links. This ensures links stay synchronized
 * with saved document state.
 */
- (void)noteDocumentSaved;

/** Notifies the manager that its document has been saved with a new name.
 * Updates the internal filename reference and performs standard save processing.
 * This maintains link integrity when documents are renamed.
 */
- (void)noteDocumentSavedAs: (NSString *)path;

/** Notifies the manager that its document has been saved to a different location.
 * Updates source link filenames when applicable for "Save As" operations.
 * This ensures links continue to reference the correct files.
 */
- (void)noteDocumentSavedTo: (NSString *)path;

//
// Getting and Setting Information about the Link Manager
//

//
// Manager Information
//

/** Returns the delegate object for this manager.
 * The delegate handles link tracking, updates, and user interactions.
 * Returns nil if no delegate is set.
 */
- (id)delegate;

/** Returns whether the delegate verifies links before processing.
 * When YES, the delegate will be asked to verify each link operation.
 * This provides additional control over link management.
 */
- (BOOL)delegateVerifiesLinks;

/** Returns the filename of the document managed by this instance.
 * This is the file path used for link resolution and document identification.
 * Returns nil if no filename is set.
 */
- (NSString *)filename;

/** Returns whether the manager interacts with users during operations.
 * When YES, the manager may display dialogs or request user input.
 * When NO, operations proceed automatically without user interaction.
 */
- (BOOL)interactsWithUser;

/** Returns whether the managed document has been edited.
 * This flag tracks modification state for proper link updating.
 * Used to determine when links need timestamp updates.
 */
- (BOOL)isEdited;

/** Sets whether the delegate verifies links before processing.
 * Pass YES to enable delegate verification of link operations.
 * Pass NO to allow automatic processing without delegate verification.
 */
- (void)setDelegateVerifiesLinks: (BOOL)flag;

/** Sets whether the manager interacts with users during operations.
 * Pass YES to enable user interaction dialogs and prompts.
 * Pass NO to operate silently without user interruption.
 */
- (void)setInteractsWithUser: (BOOL)flag;

//
// Getting and Setting Information about the Manager's Links
//

//
// Link Management and Information
//

/** Returns whether link outlines are currently visible.
 * Link outlines provide visual feedback about data link locations.
 * Returns YES if outlines are drawn, NO if they are hidden.
 */
- (BOOL)areLinkOutlinesVisible;

/** Returns an enumerator for all destination links in this document.
 * Destination links are data links that receive updates from source links.
 * Use this to iterate through all incoming data connections.
 */
- (NSEnumerator *)destinationLinkEnumerator;

/** Returns the destination link that contains the specified selection.
 * Searches through destination links to find one matching the selection.
 * Returns nil if no destination link matches the selection.
 */
- (NSDataLink *)destinationLinkWithSelection: (NSSelection *)destSel;

/** Sets whether link outlines are visible in the document.
 * Pass YES to show visual outlines around data links.
 * Pass NO to hide link outlines for cleaner display.
 */
- (void)setLinkOutlinesVisible: (BOOL)flag;

/** Returns an enumerator for all source links in this document.
 * Source links are data links that provide data to other documents.
 * Use this to iterate through all outgoing data connections.
 */
- (NSEnumerator *)sourceLinkEnumerator;

//
// Link Update Management
//

/** Manually checks all destination links for needed updates.
 * Iterates through all destination links and consults the delegate
 * via isUpdateNeededForLink to determine which links need updating.
 * Performs updates for links that need them.
 */
- (void)checkForLinkUpdates;

/** Manually triggers redrawing of link outlines.
 * Calls the dataLinkManagerRedrawLinkOutlines delegate method
 * to request that visual link indicators be refreshed.
 */
- (void)redrawLinkOutlines;

/** Returns whether links are tracked individually.
 * Queries the delegate via dataLinkManagerTracksLinksIndividually
 * to determine the current tracking mode.
 */
- (BOOL)tracksLinksIndividually;
@end


//
// Methods Implemented by the Delegate
//
@interface NSObject (NSDataLinkManagerDelegate)

// Data link management methods

/** Called when a data link has been broken.
 * Notifies the delegate that a link connection has been permanently
 * severed and will no longer provide updates.
 */
- (void)dataLinkManager: (NSDataLinkManager *)sender
	   didBreakLink: (NSDataLink *)link;

/** Called to determine if a link needs updating.
 * The delegate should return YES if the link's destination should
 * be updated with current source data. This is called during file
 * monitoring and manual update checks.
 */
- (BOOL)dataLinkManager: (NSDataLinkManager *)sender
  isUpdateNeededForLink: (NSDataLink *)link;

/** Called when the manager starts tracking a new link.
 * Notifies the delegate that a new link has been added and
 * the manager is now monitoring it for changes.
 */
- (void)dataLinkManager: (NSDataLinkManager *)sender
      startTrackingLink: (NSDataLink *)link;

/** Called when the manager stops tracking a link.
 * Notifies the delegate that a link has been removed and
 * is no longer being monitored. Use this for cleanup operations.
 */
- (void)dataLinkManager: (NSDataLinkManager *)sender
       stopTrackingLink: (NSDataLink *)link;

/** Called when the document associated with the manager is closing.
 * Gives the delegate a chance to perform cleanup operations
 * before the document is closed.
 */
- (void)dataLinkManagerCloseDocument: (NSDataLinkManager *)sender;

/** Called when the document's links have been modified.
 * Notifies the delegate that links have been added, removed,
 * or otherwise changed in the document.
 */
- (void)dataLinkManagerDidEditLinks: (NSDataLinkManager *)sender;

/** Called when link outlines should be redrawn.
 * Requests that the delegate refresh visual indicators
 * around linked data in the document.
 */
- (void)dataLinkManagerRedrawLinkOutlines: (NSDataLinkManager *)sender;

/** Called to determine the link tracking mode.
 * The delegate should return YES if links should be tracked
 * individually, or NO for batch tracking operations.
 */
- (BOOL)dataLinkManagerTracksLinksIndividually: (NSDataLinkManager *)sender;

// Selection management methods

/** Called to copy data to the pasteboard.
 * The delegate should copy the data at the specified selection
 * to the pasteboard. Used during link operations and copy/paste.
 */
- (BOOL)copyToPasteboard: (NSPasteboard *)pasteboard
		      at: (NSSelection *)selection
	cheapCopyAllowed: (BOOL)flag;

/** Called to import a file at the specified selection.
 * The delegate should import the contents of the specified file
 * into the document at the given selection location.
 */
- (BOOL)importFile: (NSString *)filename
		at: (NSSelection *)selection;

/** Called to paste data from the pasteboard.
 * The delegate should paste the data from the pasteboard
 * into the document at the specified selection location.
 */
- (BOOL)pasteFromPasteboard: (NSPasteboard *)pasteboard
			 at: (NSSelection *)selection;

/** Called to show or highlight a selection.
 * The delegate should make the specified selection visible
 * and highlighted in the document view.
 */
- (BOOL)showSelection: (NSSelection *)selection;

/** Called to get the window containing a selection.
 * The delegate should return the window that contains
 * the specified selection.
 */
- (NSWindow *)windowForSelection: (NSSelection *)selection;
@end


//
// Draw a Distinctive Outline around Linked Data
//

/** Draws a distinctive frame around linked data.
 * Utility function to draw visual indicators around linked content.
 * The frame style differs depending on whether the data is a source or destination.
 */
void NSFrameLinkRect(NSRect aRect, BOOL isDestination);

/** Returns the thickness of link frame outlines.
 * Utility function that returns the standard thickness used
 * for drawing link outline frames.
 */
float NSLinkFrameThickness(void);

#endif // _GNUstep_H_NSDataLinkManager
