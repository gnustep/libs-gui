/*
   NSDataLinkPanel.h

   Standard panel for inspecting data links

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

#ifndef _GNUstep_H_NSDataLinkPanel
#define _GNUstep_H_NSDataLinkPanel
#import <AppKit/AppKitDefines.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSPanel.h>

@class NSDataLink;
@class NSDataLinkManager;
@class NSView;

@interface NSApplication (NSDataLinkPanel)
- (void) orderFrontDataLinkPanel: (id)sender;
@end

APPKIT_EXPORT_CLASS
@interface NSDataLinkPanel : NSPanel
{
  // Outlets
  id _sourceField;
  id _lastUpdateField;
  id _openSourceButton;
  id _updateDestinationButton;
  id _breakLinkButton;
  id _breakAllLinksButton;
  id _updateModeButton;

  // Attributes
  NSDataLinkManager *_currentDataLinkManager;
  NSDataLink *_currentDataLink;
  BOOL _multipleSelection;
  NSView *_accessoryView;
}

//
// Initializing
//

/** Returns the shared data link panel instance.
 * Creates and returns the singleton NSDataLinkPanel instance.
 * This panel is used throughout the application for managing data links.
 */
+ (NSDataLinkPanel *)sharedDataLinkPanel;

//
// Keeping the Panel Up to Date
//

/** Gets the current link and manager from the panel.
 * Returns the currently selected data link and its manager.
 * Also indicates whether multiple links are selected.
 */
+ (void)getLink:(NSDataLink **)link
	manager:(NSDataLinkManager **)linkManager
     isMultiple:(BOOL *)flag;

/** Sets the current link and manager for the panel.
 * Updates the panel to display information about the specified link.
 * Pass YES for isMultiple when multiple links are selected.
 */
+ (void)setLink:(NSDataLink *)link
	manager:(NSDataLinkManager *)linkManager
     isMultiple:(BOOL)flag;

/** Gets the current link and manager from the panel instance.
 * Instance method version that returns the currently selected data link
 * and its manager. Also indicates whether multiple links are selected.
 */
- (void)getLink:(NSDataLink **)link
	manager:(NSDataLinkManager **)linkManager
     isMultiple:(BOOL *)flag;

/** Sets the current link and manager for the panel instance.
 * Instance method version that updates the panel to display information
 * about the specified link. Pass YES for isMultiple when multiple links are selected.
 */
- (void)setLink:(NSDataLink *)link
	manager:(NSDataLinkManager *)linkManager
     isMultiple:(BOOL)flag;

//
// Customizing the Panel
//

/** Returns the accessory view for the panel.
 * The accessory view allows applications to add custom controls
 * to the data link panel for application-specific functionality.
 */
- (NSView *)accessoryView;

/** Sets the accessory view for the panel.
 * Applications can provide a custom view to extend the panel's
 * functionality with application-specific controls and information.
 */
- (void)setAccessoryView:(NSView *)aView;

//
// Responding to User Input
//

/** Handles the "Break All Links" button action.
 * Called when the user clicks the button to break all data links
 * in the current selection or document. Confirms the action with the user.
 */
- (void)pickedBreakAllLinks:(id)sender;

/** Handles the "Break Link" button action.
 * Called when the user clicks the button to break the currently
 * selected data link. Permanently severs the link connection.
 */
- (void)pickedBreakLink:(id)sender;

/** Handles the "Open Source" button action.
 * Called when the user clicks the button to open the source document
 * or application. Attempts to launch the appropriate application.
 */
- (void)pickedOpenSource:(id)sender;

/** Handles the "Update Destination" button action.
 * Called when the user clicks the button to manually update the
 * destination with current source data.
 */
- (void)pickedUpdateDestination:(id)sender;

/** Handles the update mode selection control.
 * Called when the user changes the update mode setting for the
 * current data link (continuous, on save, manual, or never).
 */
- (void)pickedUpdateMode:(id)sender;

@end

#endif // _GNUstep_H_NSDataLinkPanel
