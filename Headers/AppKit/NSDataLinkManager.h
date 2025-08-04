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

/** <p>Initializes a link manager with a delegate.</p>
    <p>Creates a new NSDataLinkManager with the specified delegate.
    The delegate will receive callbacks for link management events.</p>
    @param anObject The delegate object that will handle link management callbacks
    @return A new NSDataLinkManager instance
*/
- (id) initWithDelegate: (id)anObject;

/** <p>Initializes a link manager with a delegate and associates it with a file.</p>
    <p>Creates a new NSDataLinkManager with the specified delegate and
    associates it with a particular file. This is typically used when
    the manager represents links within a specific document.</p>
    @param anObject The delegate object that will handle link management callbacks
    @param path The file path to associate with this manager
    @return A new NSDataLinkManager instance
*/
- (id) initWithDelegate: (id)anObject
               fromFile: (NSString *)path;

//
// Adding and Removing Links
//

/** <p>Adds a destination link at the specified selection.</p>
    <p>Registers a new data link as a destination within this manager.
    The link will be positioned at the given selection and the manager
    will monitor it for updates. Triggers startTrackingLink: delegate callback.</p>
    @param link The NSDataLink to add as a destination
    @param selection The location where the link should be placed
    @return YES if the link was added successfully, NO if it already exists
*/
- (BOOL)addLink: (NSDataLink *)link
	     at: (NSSelection *)selection;

/** <p>Adds a source link to this manager.</p>
    <p>Registers a new data link as a source within this manager.
    The manager will monitor the source for changes and can provide
    data to destination links. Triggers startTrackingLink: delegate callback.</p>
    @param link The NSDataLink to add as a source
    @return YES if the link was added successfully, NO if it already exists
*/
- (BOOL)addSourceLink: (NSDataLink *)link;

/** <p>Adds a link as a marker at the specified selection.</p>
    <p>Adds a data link that serves only as a position marker.
    Marker links don't transfer data but can be useful for UI purposes.</p>
    @param link The NSDataLink to add as a marker
    @param selection The location where the marker should be placed
    @return YES if the marker was added successfully, NO otherwise
*/
- (BOOL)addLinkAsMarker: (NSDataLink *)link
		     at: (NSSelection *)selection;

/** <p>Recreates a link that was previously at another location.</p>
    <p>Used when moving or copying links between documents.
    Attempts to restore a link from pasteboard data.</p>
    @param oldSelection The previous location of the link
    @param pasteboard The pasteboard containing the link data
    @param selection The new location for the link
    @return The restored NSDataLink, or nil if restoration failed
*/
- (NSDataLink *)addLinkPreviouslyAt: (NSSelection *)oldSelection
		     fromPasteboard: (NSPasteboard *)pasteboard
				 at: (NSSelection *)selection;

/** <p>Removes a specific link from this manager.</p>
    <p>Removes the specified link from both source and destination collections.
    Triggers stopTrackingLink: delegate callback for proper cleanup.</p>
    @param link The NSDataLink to remove
*/
- (void)removeLink: (NSDataLink *)link;

/** <p>Breaks all links managed by this manager.</p>
    <p>Permanently breaks all source and destination links.
    Each link will be broken individually and delegate callbacks
    will be triggered for each one.</p>
*/
- (void)breakAllLinks;

/** <p>Writes all source links to the pasteboard.</p>
    <p>Puts data for all source links onto the pasteboard,
    allowing them to be pasted into other documents.</p>
    @param pasteboard The pasteboard to write to
*/
- (void)writeLinksToPasteboard: (NSPasteboard *)pasteboard;

//
// Informing the Link Manager of Document Status
//

/** <p>Notifies the manager that its document is closing.</p>
    <p>Call this when the document associated with this manager is being closed.
    Triggers the dataLinkManagerCloseDocument: delegate callback.</p>
*/
- (void)noteDocumentClosed;

/** <p>Notifies the manager that its document has been edited.</p>
    <p>Call this when the document has been modified.
    Triggers the dataLinkManagerDidEditLinks: delegate callback.</p>
*/
- (void)noteDocumentEdited;

/** <p>Notifies the manager that its document has been reverted.</p>
    <p>Call this when the document has been reverted to a saved state.
    Triggers the dataLinkManagerDidEditLinks: delegate callback.</p>
*/
- (void)noteDocumentReverted;

/** <p>Notifies the manager that its document has been saved.</p>
    <p>Updates timestamps for all source links and triggers update
    checking for destination links. This ensures links stay synchronized
    with saved document state.</p>
*/
- (void)noteDocumentSaved;

/** <p>Notifies the manager that its document has been saved with a new name.</p>
    <p>Updates the internal filename reference and performs standard save processing.
    This maintains link integrity when documents are renamed.</p>
    @param path The new file path of the document
*/
- (void)noteDocumentSavedAs: (NSString *)path;

/** <p>Notifies the manager that its document has been saved to a different location.</p>
    <p>Updates source link filenames when applicable for "Save As" operations.
    This ensures links continue to reference the correct files.</p>
    @param path The path where the document was saved
*/
- (void)noteDocumentSavedTo: (NSString *)path;

//
// Getting and Setting Information about the Link Manager
//

/** <p>Returns the current delegate object.</p>
    <p>The delegate receives callbacks for link management events.</p>
    @return The delegate object, or nil if no delegate is set
*/
- (id)delegate;

/** <p>Returns whether the delegate verifies links.</p>
    <p>When YES, the delegate is consulted before link operations.</p>
    @return YES if delegate verification is enabled, NO otherwise
*/
- (BOOL)delegateVerifiesLinks;

/** <p>Returns the filename associated with this manager.</p>
    <p>For document-based managers, this is the document's file path.</p>
    @return The associated filename, or nil if not file-based
*/
- (NSString *)filename;

/** <p>Returns whether the manager interacts with users.</p>
    <p>When YES, the manager may display dialogs or UI for link operations.</p>
    @return YES if user interaction is enabled, NO otherwise
*/
- (BOOL)interactsWithUser;

/** <p>Returns whether the document has been edited.</p>
    <p>Indicates if the document contains unsaved changes.</p>
    @return YES if the document has been edited, NO otherwise
*/
- (BOOL)isEdited;

/** <p>Sets whether the delegate should verify link operations.</p>
    <p>When enabled, the delegate is consulted before link operations.</p>
    @param flag YES to enable delegate verification, NO to disable
*/
- (void)setDelegateVerifiesLinks: (BOOL)flag;

/** <p>Sets whether the manager should interact with users.</p>
    <p>Controls whether dialogs or UI elements are displayed.</p>
    @param flag YES to enable user interaction, NO to disable
*/
- (void)setInteractsWithUser: (BOOL)flag;

//
// Getting and Setting Information about the Manager's Links
//

/** <p>Returns whether link outlines are currently visible.</p>
    <p>Link outlines provide visual feedback about linked data locations.</p>
    @return YES if link outlines are visible, NO otherwise
*/
- (BOOL)areLinkOutlinesVisible;

/** <p>Returns an enumerator for all destination links.</p>
    <p>Use this to iterate through all links where this manager
    serves as the destination.</p>
    @return An NSEnumerator for destination links
*/
- (NSEnumerator *)destinationLinkEnumerator;

/** <p>Finds the destination link at the specified selection.</p>
    <p>Searches for a destination link that matches the given selection.</p>
    @param destSel The selection to search for
    @return The matching NSDataLink, or nil if not found
*/
- (NSDataLink *)destinationLinkWithSelection: (NSSelection *)destSel;

/** <p>Sets the visibility of link outlines.</p>
    <p>Controls whether visual indicators are drawn around linked data.
    Triggers dataLinkManagerRedrawLinkOutlines: delegate callback.</p>
    @param flag YES to show outlines, NO to hide them
*/
- (void)setLinkOutlinesVisible: (BOOL)flag;

/** <p>Returns an enumerator for all source links.</p>
    <p>Use this to iterate through all links where this manager
    serves as the source.</p>
    @return An NSEnumerator for source links
*/
- (NSEnumerator *)sourceLinkEnumerator;

//
// Link Update Management
//

/** <p>Manually checks all destination links for needed updates.</p>
    <p>Iterates through all destination links and consults the delegate
    via isUpdateNeededForLink: to determine which links need updating.
    Performs updates for links that need them.</p>
*/
- (void)checkForLinkUpdates;

/** <p>Manually triggers redrawing of link outlines.</p>
    <p>Calls the dataLinkManagerRedrawLinkOutlines: delegate method
    to request that visual link indicators be refreshed.</p>
*/
- (void)redrawLinkOutlines;

/** <p>Returns whether links are tracked individually.</p>
    <p>Queries the delegate via dataLinkManagerTracksLinksIndividually:
    to determine the current tracking mode.</p>
    @return YES if individual tracking is enabled, NO for batch tracking
*/
- (BOOL)tracksLinksIndividually;
@end


//
// Methods Implemented by the Delegate
//
@interface NSObject (NSDataLinkManagerDelegate)

// Data link management methods

/** <p>Called when a data link has been broken.</p>
    <p>Notifies the delegate that a link connection has been permanently
    severed and will no longer provide updates.</p>
    @param sender The NSDataLinkManager that managed the link
    @param link The NSDataLink that was broken
*/
- (void)dataLinkManager: (NSDataLinkManager *)sender
	   didBreakLink: (NSDataLink *)link;

/** <p>Called to determine if a link needs updating.</p>
    <p>The delegate should return YES if the link's destination should
    be updated with current source data. This is called during file
    monitoring and manual update checks.</p>
    @param sender The NSDataLinkManager requesting the update check
    @param link The NSDataLink being evaluated for updates
    @return YES if the link should be updated, NO otherwise
*/
- (BOOL)dataLinkManager: (NSDataLinkManager *)sender
  isUpdateNeededForLink: (NSDataLink *)link;

/** <p>Called when the manager starts tracking a new link.</p>
    <p>Notifies the delegate that a new link has been added and
    the manager is now monitoring it for changes.</p>
    @param sender The NSDataLinkManager that is tracking the link
    @param link The NSDataLink that is now being tracked
*/
- (void)dataLinkManager: (NSDataLinkManager *)sender
      startTrackingLink: (NSDataLink *)link;

/** <p>Called when the manager stops tracking a link.</p>
    <p>Notifies the delegate that a link has been removed and
    is no longer being monitored. Use this for cleanup operations.</p>
    @param sender The NSDataLinkManager that was tracking the link
    @param link The NSDataLink that is no longer being tracked
*/
- (void)dataLinkManager: (NSDataLinkManager *)sender
       stopTrackingLink: (NSDataLink *)link;

/** <p>Called when the document associated with the manager is closing.</p>
    <p>Gives the delegate a chance to perform cleanup operations
    before the document is closed.</p>
    @param sender The NSDataLinkManager whose document is closing
*/
- (void)dataLinkManagerCloseDocument: (NSDataLinkManager *)sender;

/** <p>Called when the document's links have been modified.</p>
    <p>Notifies the delegate that links have been added, removed,
    or otherwise changed in the document.</p>
    @param sender The NSDataLinkManager whose links were modified
*/
- (void)dataLinkManagerDidEditLinks: (NSDataLinkManager *)sender;

/** <p>Called when link outlines should be redrawn.</p>
    <p>Requests that the delegate refresh visual indicators
    around linked data in the document.</p>
    @param sender The NSDataLinkManager requesting the redraw
*/
- (void)dataLinkManagerRedrawLinkOutlines: (NSDataLinkManager *)sender;

/** <p>Called to determine the link tracking mode.</p>
    <p>The delegate should return YES if links should be tracked
    individually, or NO for batch tracking operations.</p>
    @param sender The NSDataLinkManager requesting the tracking mode
    @return YES for individual tracking, NO for batch tracking
*/
- (BOOL)dataLinkManagerTracksLinksIndividually: (NSDataLinkManager *)sender;

// Selection management methods

/** <p>Called to copy data to the pasteboard.</p>
    <p>The delegate should copy the data at the specified selection
    to the pasteboard. Used during link operations and copy/paste.</p>
    @param pasteboard The pasteboard to copy data to
    @param selection The selection containing the data to copy
    @param flag YES if a cheap copy is allowed, NO for full copy
    @return YES if the copy was successful, NO otherwise
*/
- (BOOL)copyToPasteboard: (NSPasteboard *)pasteboard
		      at: (NSSelection *)selection
	cheapCopyAllowed: (BOOL)flag;

/** <p>Called to import a file at the specified selection.</p>
    <p>The delegate should import the contents of the specified file
    into the document at the given selection location.</p>
    @param filename The path of the file to import
    @param selection The location where the file should be imported
    @return YES if the import was successful, NO otherwise
*/
- (BOOL)importFile: (NSString *)filename
		at: (NSSelection *)selection;

/** <p>Called to paste data from the pasteboard.</p>
    <p>The delegate should paste the data from the pasteboard
    into the document at the specified selection location.</p>
    @param pasteboard The pasteboard containing data to paste
    @param selection The location where data should be pasted
    @return YES if the paste was successful, NO otherwise
*/
- (BOOL)pasteFromPasteboard: (NSPasteboard *)pasteboard
			 at: (NSSelection *)selection;

/** <p>Called to show or highlight a selection.</p>
    <p>The delegate should make the specified selection visible
    and highlighted in the document view.</p>
    @param selection The selection to show
    @return YES if the selection was successfully shown, NO otherwise
*/
- (BOOL)showSelection: (NSSelection *)selection;

/** <p>Called to get the window containing a selection.</p>
    <p>The delegate should return the window that contains
    the specified selection.</p>
    @param selection The selection whose window is requested
    @return The NSWindow containing the selection, or nil if not found
*/
- (NSWindow *)windowForSelection: (NSSelection *)selection;
@end


//
// Draw a Distinctive Outline around Linked Data
//

/** <p>Draws a distinctive frame around linked data.</p>
    <p>Utility function to draw visual indicators around linked content.
    The frame style differs depending on whether the data is a source or destination.</p>
    @param aRect The rectangle to frame
    @param isDestination YES for destination links, NO for source links
*/
void NSFrameLinkRect(NSRect aRect, BOOL isDestination);

/** <p>Returns the thickness of link frame outlines.</p>
    <p>Utility function that returns the standard thickness used
    for drawing link outline frames.</p>
    @return The frame thickness in points
*/
float NSLinkFrameThickness(void);

#endif // _GNUstep_H_NSDataLinkManager
