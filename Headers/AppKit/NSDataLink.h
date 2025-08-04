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

/** <p>Initializes a data link connected to a file.</p>
    <p>Creates a new NSDataLink object that references the specified file.
    The link will monitor the file for changes and can update dependent
    documents when the source file is modified.</p>
    @param filename The path to the source file
    @return A new NSDataLink instance or nil if initialization fails
*/
- (id)initLinkedToFile:(NSString *)filename;

/** <p>Initializes a data link with a source selection managed by a link manager.</p>
    <p>Creates a new NSDataLink that represents a selection within a document
    managed by the specified NSDataLinkManager. This is typically used for
    creating links between different parts of the same application.</p>
    @param selection The source selection to link to
    @param linkManager The manager responsible for this link
    @param newTypes Array of supported pasteboard types
    @return A new NSDataLink instance or nil if initialization fails
*/
- (id)initLinkedToSourceSelection:(NSSelection *)selection
			managedBy:(NSDataLinkManager *)linkManager
		  supportingTypes:(NSArray *)newTypes;

/** <p>Initializes a data link from a saved file.</p>
    <p>Reconstructs a data link from a previously saved link file.
    The file should contain archived link data created by writeToFile:.</p>
    @param filename Path to the saved link file
    @return A new NSDataLink instance or nil if the file cannot be read
*/
- (id)initWithContentsOfFile:(NSString *)filename;

/** <p>Initializes a data link from pasteboard data.</p>
    <p>Creates a data link from link data stored on the pasteboard.
    This is typically used when pasting linked data.</p>
    @param pasteboard The pasteboard containing link data
    @return A new NSDataLink instance or nil if no valid link data is found
*/
- (id)initWithPasteboard:(NSPasteboard *)pasteboard;

//
// Exporting a Link
//

/** <p>Saves the link to a directory.</p>
    <p>Writes the link data to a file in the specified directory.
    The filename is automatically generated based on the link number.</p>
    @param directoryName Path to the directory where the link should be saved
    @return YES if the link was saved successfully, NO otherwise
*/
- (BOOL)saveLinkIn:(NSString *)directoryName;

/** <p>Writes the link data to a specific file.</p>
    <p>Archives the complete link data to the specified file path.
    The saved file can later be used with initWithContentsOfFile:.</p>
    @param filename Path where the link data should be written
    @return YES if the data was written successfully, NO otherwise
*/
- (BOOL)writeToFile:(NSString *)filename;

/** <p>Writes link data to the pasteboard.</p>
    <p>Puts the link data onto the pasteboard so it can be pasted
    into other documents or applications.</p>
    @param pasteboard The pasteboard to write to
*/
- (void)writeToPasteboard:(NSPasteboard *)pasteboard;

//
// Information about the Link
//

/** <p>Returns the current disposition of the link.</p>
    <p>The disposition indicates whether the link exists in the source
    document, destination document, or is broken.</p>
    @return The current NSDataLinkDisposition value
*/
- (NSDataLinkDisposition)disposition;

/** <p>Returns the unique number identifying this link.</p>
    <p>Each link has a unique number assigned by its manager.
    This number is used for tracking and identification purposes.</p>
    @return The link's unique identification number
*/
- (NSDataLinkNumber)linkNumber;

/** <p>Returns the link manager responsible for this link.</p>
    <p>The manager handles link updates, monitoring, and lifecycle management.</p>
    @return The NSDataLinkManager instance managing this link
*/
- (NSDataLinkManager *)manager;

//
// Information about the Link's Source
//

/** <p>Returns the last time the source was updated.</p>
    <p>This timestamp indicates when the source data was last modified.
    It's used to determine if destination links need updating.</p>
    @return NSDate representing the last update time, or nil if unknown
*/
- (NSDate *)lastUpdateTime;

/** <p>Opens the source document or application.</p>
    <p>Attempts to open the source document in its associated application.
    This allows users to edit the source data directly.</p>
    @return YES if the source was opened successfully, NO otherwise
*/
- (BOOL)openSource;

/** <p>Returns the name of the source application.</p>
    <p>Identifies which application created or manages the source data.</p>
    @return The application name as a string, or nil if unknown
*/
- (NSString *)sourceApplicationName;

/** <p>Returns the filename of the source data.</p>
    <p>For file-based links, this returns the path to the source file.</p>
    @return The source filename, or nil for non-file sources
*/
- (NSString *)sourceFilename;

/** <p>Returns the selection within the source document.</p>
    <p>For document-based links, this identifies the specific portion
    of the source document that is linked.</p>
    @return The source selection, or nil for file-based links
*/
- (NSSelection *)sourceSelection;

/** <p>Returns the array of supported data types.</p>
    <p>Lists the pasteboard types that this link can provide.
    Used during copy/paste operations to determine compatibility.</p>
    @return Array of NSString objects representing pasteboard types
*/
- (NSArray *)types;

//
// Information about the Link's Destination
//

/** <p>Returns the name of the destination application.</p>
    <p>Identifies which application contains the destination document.</p>
    @return The destination application name, or nil if unknown
*/
- (NSString *)destinationApplicationName;

/** <p>Returns the filename of the destination document.</p>
    <p>For file-based destinations, this returns the path to the destination file.</p>
    @return The destination filename, or nil for non-file destinations
*/
- (NSString *)destinationFilename;

/** <p>Returns the selection within the destination document.</p>
    <p>Identifies where the linked data appears in the destination document.</p>
    @return The destination selection, or nil if not applicable
*/
- (NSSelection *)destinationSelection;

//
// Changing the Link
//

/** <p>Breaks the data link connection.</p>
    <p>Permanently severs the connection between source and destination.
    Once broken, the link cannot be restored and will no longer update.
    Notifies both source and destination managers via delegate callbacks.</p>
    @return YES if the link was successfully broken, NO otherwise
*/
- (BOOL)break;

/** <p>Notifies the link that its source has been edited.</p>
    <p>Call this method when the source data has been modified.
    This marks the link as dirty and may trigger update checks
    depending on the current update mode.</p>
*/
- (void)noteSourceEdited;

/** <p>Sets when the link should update its destination.</p>
    <p>Controls the automatic update behavior of the link.</p>
    @param mode The desired update mode (continuous, on save, manual, or never)
*/
- (void)setUpdateMode:(NSDataLinkUpdateMode)mode;

/** <p>Updates the destination with current source data.</p>
    <p>Attempts to update the destination with the latest source data.
    Consults the destination manager's delegate to determine if update
    is needed and handles the actual data transfer.</p>
    @return YES if the update was successful, NO if update failed or wasn't needed
*/
- (BOOL)updateDestination;

/** <p>Returns the current update mode.</p>
    <p>Indicates when this link will automatically update its destination.</p>
    @return The current NSDataLinkUpdateMode setting
*/
- (NSDataLinkUpdateMode)updateMode;
@end

APPKIT_EXPORT NSString *NSDataLinkFilenameExtension;
APPKIT_EXPORT NSString *NSDataLinkPboardType;

#endif // _GNUstep_H_NSDataLink

