/*
   NSDataLink.h

   Link between a source and dependent document

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

#ifndef _GNUstep_H_NSDataLink
#define _GNUstep_H_NSDataLink
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>

@class NSString;
@class NSArray;
@class NSDate;

@class NSDataLinkManager;
@class NSSelection;
@class NSPasteboard;

typedef int NSDataLinkNumber;

typedef enum _NSDataLinkDisposition {
  NSLinkInDestination,
  NSLinkInSource,
  NSLinkBroken
} NSDataLinkDisposition;

typedef enum _NSDataLinkUpdateMode {
  NSUpdateContinuously,
  NSUpdateWhenSourceSaved,
  NSUpdateManually,
  NSUpdateNever
} NSDataLinkUpdateMode;

APPKIT_EXPORT NSString *NSDataLinkFileNameExtension;

APPKIT_EXPORT_CLASS
@interface NSDataLink : NSObject <NSCoding>
{
  // Attributes
  @private
  // link info.
  NSDataLinkNumber      _linkNumber;
  NSDataLinkDisposition _disposition;
  NSDataLinkUpdateMode  _updateMode;

  // info about the source.
  NSDate                *_lastUpdateTime;
  NSString              *_sourceApplicationName;
  NSString              *_sourceFilename;
  NSSelection           *_sourceSelection;
  id                    _sourceManager;

  // info about the destination
  NSString              *_destinationApplicationName;
  NSString              *_destinationFilename;
  NSSelection           *_destinationSelection;
  id                    _destinationManager;

  // types.
  NSArray               *_types;

  // other flags
  struct __linkFlags {
    unsigned   appVerifies:1;
    unsigned   broken:1;
    unsigned   canUpdateContinuously:1;
    unsigned   isDirty:1;
    unsigned   willOpenSource:1;
    unsigned   willUpdate:1;
    unsigned   isMarker:1;
  } _flags;
}

//
// Initializing a Link
//

/** Initializes a data link connected to a file.
 * Creates a new NSDataLink object that references the specified file.
 * The link will monitor the file for changes and can update dependent
 * documents when the source file is modified.
 */
- (id)initLinkedToFile:(NSString *)filename;

/** Initializes a data link with a source selection managed by a link manager.
 * Creates a new NSDataLink that represents a selection within a document
 * managed by the specified NSDataLinkManager. This is typically used for
 * creating links between different parts of the same application.
 */
- (id)initLinkedToSourceSelection:(NSSelection *)selection
			managedBy:(NSDataLinkManager *)linkManager
		  supportingTypes:(NSArray *)newTypes;

/** Initializes a data link from a saved file.
 * Reconstructs a data link from a previously saved link file.
 * The file should contain archived link data created by writeToFile.
 */
- (id)initWithContentsOfFile:(NSString *)filename;

/** Initializes a data link from pasteboard data.
 * Creates a data link from link data stored on the pasteboard.
 * This is typically used when pasting linked data.
 */
- (id)initWithPasteboard:(NSPasteboard *)pasteboard;

//
// Exporting a Link
//

/** Saves the link to a directory.
 * Writes the link data to a file in the specified directory.
 * The filename is automatically generated based on the link number.
 */
- (BOOL)saveLinkIn:(NSString *)directoryName;

/** Writes the link data to a specific file.
 * Archives the complete link data to the specified file path.
 * The saved file can later be used with initWithContentsOfFile.
 */
- (BOOL)writeToFile:(NSString *)filename;

/** Writes link data to the pasteboard.
 * Puts the link data onto the pasteboard so it can be pasted
 * into other documents or applications.
 */
- (void)writeToPasteboard:(NSPasteboard *)pasteboard;

//
// Information about the Link
//

/** Returns the current disposition of the link.
 * The disposition indicates whether the link exists in the source
 * document, destination document, or is broken.
 */
- (NSDataLinkDisposition)disposition;

/** Returns the unique number identifying this link.
 * Each link has a unique number assigned by its manager.
 * This number is used for tracking and identification purposes.
 */
- (NSDataLinkNumber)linkNumber;

/** Returns the link manager responsible for this link.
 * The manager handles link updates, monitoring, and lifecycle management.
 */
- (NSDataLinkManager *)manager;

//
// Information about the Link's Source
//

/** Returns the last time the source was updated.
 * This timestamp indicates when the source data was last modified.
 * It's used to determine if destination links need updating.
 */
- (NSDate *)lastUpdateTime;

/** Opens the source document or application.
 * Attempts to open the source document in its associated application.
 * This allows users to edit the source data directly.
 */
- (BOOL)openSource;

/** Returns the name of the source application.
 * Identifies which application created or manages the source data.
 */
- (NSString *)sourceApplicationName;

/** Returns the filename of the source data.
 * For file-based links, this returns the path to the source file.
 */
- (NSString *)sourceFilename;

/** Returns the selection within the source document.
 * For document-based links, this identifies the specific portion
 * of the source document that is linked.
 */
- (NSSelection *)sourceSelection;

/** Returns the array of supported data types.
 * Lists the pasteboard types that this link can provide.
 * Used during copy/paste operations to determine compatibility.
 */
- (NSArray *)types;

//
// Information about the Link's Destination
//

/** Returns the name of the destination application.
 * Identifies which application contains the destination document.
 */
- (NSString *)destinationApplicationName;

/** Returns the filename of the destination document.
 * For file-based destinations, this returns the path to the destination file.
 */
- (NSString *)destinationFilename;

/** Returns the selection within the destination document.
 * Identifies where the linked data appears in the destination document.
 */
- (NSSelection *)destinationSelection;

//
// Changing the Link
//

/** Breaks the data link connection.
 * Permanently severs the connection between source and destination.
 * Once broken, the link cannot be restored and will no longer update.
 * Notifies both source and destination managers via delegate callbacks.
 */
- (BOOL)break;

/** Notifies the link that its source has been edited.
 * Call this method when the source data has been modified.
 * This marks the link as dirty and may trigger update checks
 * depending on the current update mode.
 */
- (void)noteSourceEdited;

/** Sets when the link should update its destination.
 * Controls the automatic update behavior of the link.
 */
- (void)setUpdateMode:(NSDataLinkUpdateMode)mode;

/** Updates the destination with current source data.
 * Attempts to update the destination with the latest source data.
 * Consults the destination manager's delegate to determine if update
 * is needed and handles the actual data transfer.
 */
- (BOOL)updateDestination;

/** Returns the current update mode.
 * Indicates when this link will automatically update its destination.
 */
- (NSDataLinkUpdateMode)updateMode;
@end

APPKIT_EXPORT NSString *NSDataLinkFilenameExtension;
APPKIT_EXPORT NSString *NSDataLinkPboardType;

#endif // _GNUstep_H_NSDataLink

