/* 
   NSPasteboard.h

   Class to transfer data to and from the pasteboard server

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Richard Frith-Macdonald <rfm@gnu.org>
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSPasteboard
#define _GNUstep_H_NSPasteboard

#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <AppKit/AppKitDefines.h>

@class NSString;
@class NSArray;
@class NSData;
@class NSFileWrapper;

/**
 * Pasteboard contains string data as written by
 * [NSPasteboard-setString:forType:] or [NSPasteboard-setPropertyList:forType:]
 */
APPKIT_EXPORT NSString *NSStringPboardType;

/**
 * Pasteboard contains string color information
 */
APPKIT_EXPORT NSString *NSColorPboardType;
APPKIT_EXPORT NSString *NSFileContentsPboardType;
APPKIT_EXPORT NSString *NSFilenamesPboardType;

/**
 * Pasteboard contains font color information
 */
APPKIT_EXPORT NSString *NSFontPboardType;

/**
 * Pasteboard contains ruler color information
 */
APPKIT_EXPORT NSString *NSRulerPboardType;

/**
 * Pasteboard contains postscript code
 */
APPKIT_EXPORT NSString *NSPostScriptPboardType;

/**
 * Pasteboard contains tabular text.
 */
APPKIT_EXPORT NSString *NSTabularTextPboardType;

/**
 * Pasteboard contains text in rich text format.
 */
APPKIT_EXPORT NSString *NSRTFPboardType;

/**
 * Pasteboard contains text in rich text format with additional info
 */
APPKIT_EXPORT NSString *NSRTFDPboardType;

/**
 * Pasteboard contains a TIFF image
 */
APPKIT_EXPORT NSString *NSTIFFPboardType;

/**
 * Pasteboard contains a link to data in some document
 */
APPKIT_EXPORT NSString *NSDataLinkPboardType;

/**
 * Pasteboard contains general binary data
 */
APPKIT_EXPORT NSString *NSGeneralPboardType;

#ifndef STRICT_OPENSTEP
/**
 * Pasteboard contains a PDF document
 */
APPKIT_EXPORT NSString *NSPDFPboardType;

/**
 * Pasteboard contains a PICT diagram document
 */
APPKIT_EXPORT NSString *NSPICTPboardType;

/**
 * Pasteboard contains a URL
 */
APPKIT_EXPORT NSString *NSURLPboardType;

/**
 * Pasteboard contains HTML data
 */
APPKIT_EXPORT NSString *NSHTMLPboardType;
#endif

/**
 * The pasteboard used for drag and drop information.
 */
APPKIT_EXPORT NSString *NSDragPboard;

/**
 * The pasteboard used search and replace editing operations.
 */
APPKIT_EXPORT NSString *NSFindPboard;

/**
 * The pasteboard used for cutting and pasting font information.
 */
APPKIT_EXPORT NSString *NSFontPboard;

/**
 * The general purpose pasteboard (mostly used for sut and paste)
 */
APPKIT_EXPORT NSString *NSGeneralPboard;

/**
 * The pasteboard used for cutting and pasting ruler information.
 */
APPKIT_EXPORT NSString *NSRulerPboard;

/**
 * Exception raised when communication with the pasteboard server fails.
 */
APPKIT_EXPORT NSString *NSPasteboardCommunicationException;


@interface NSPasteboard : NSObject
{
  NSString	*name;		// The name of this pasteboard.
  int		changeCount;	// What we think the current count is.
  id		target;		// Proxy to the object in the server.
  id		owner;		// Local pasteboard owner.
  BOOL		useHistory;	// Want strict OPENSTEP?
}

//
// Creating and Releasing an NSPasteboard Object
//
+ (NSPasteboard*) generalPasteboard;
+ (NSPasteboard*) pasteboardWithName: (NSString*)aName;
+ (NSPasteboard*) pasteboardWithUniqueName;
- (void) releaseGlobally;

//
// Getting Data in Different Formats 
//
+ (NSPasteboard*) pasteboardByFilteringData: (NSData*)data
				     ofType: (NSString*)type;
+ (NSPasteboard*) pasteboardByFilteringFile: (NSString*)filename;
+ (NSPasteboard*) pasteboardByFilteringTypesInPasteboard: (NSPasteboard*)pboard;
+ (NSArray*) typesFilterableTo: (NSString*)type;

//
// Referring to a Pasteboard by Name 
//
- (NSString*) name;

//
// Writing Data 
//
- (int) addTypes: (NSArray*)newTypes
	   owner: (id)newOwner;
- (int) declareTypes: (NSArray*)newTypes
	       owner: (id)newOwner;
- (BOOL) setData: (NSData*)data
	 forType: (NSString*)dataType;
- (BOOL) setPropertyList: (id)propertyList
		 forType: (NSString*)dataType;
- (BOOL) setString: (NSString*)string
	   forType: (NSString*)dataType;
- (BOOL) writeFileContents: (NSString*)filename;
- (BOOL) writeFileWrapper: (NSFileWrapper*)wrapper;

//
// Determining Types 
//
- (NSString*) availableTypeFromArray: (NSArray*)types;
- (NSArray*) types;

//
// Reading Data 
//
- (int) changeCount;
- (NSData*) dataForType: (NSString*)dataType;
- (id) propertyListForType: (NSString*)dataType;
- (NSString*) readFileContentsType: (NSString*)type
			    toFile: (NSString*)filename;
- (NSFileWrapper*) readFileWrapper;
- (NSString*) stringForType: (NSString*)dataType;

@end

@interface NSObject (NSPasteboardOwner)
- (void) pasteboard: (NSPasteboard*)sender
 provideDataForType: (NSString*)type;
- (void) pasteboard: (NSPasteboard*)sender
 provideDataForType: (NSString*)type
	 andVersion: (int)version;
- (void) pasteboardChangedOwner: (NSPasteboard*)sender;
@end

@interface NSPasteboard (GNUstepExtensions)
+ (NSString*) mimeTypeForPasteboardType: (NSString*)type;
+ (NSString*) pasteboardTypeForMimeType: (NSString*)mimeType;
- (void) setChangeCount: (int)count;
@end

#ifndef STRICT_OPENSTEP
#include <Foundation/NSURL.h>

@interface NSURL (NSPasteboard)
+ (NSURL*) URLFromPasteboard: (NSPasteboard*)pasteBoard;
- (void) writeToPasteboard: (NSPasteboard*)pasteBoard;
@end

#endif
//
// Return File-related Pasteboard Types
//
APPKIT_EXPORT NSString *NSCreateFileContentsPboardType(NSString *fileType);
APPKIT_EXPORT NSString *NSCreateFilenamePboardType(NSString *fileType);
APPKIT_EXPORT NSString *NSGetFileType(NSString *pboardType);
APPKIT_EXPORT NSArray *NSGetFileTypes(NSArray *pboardTypes);


#endif // _GNUstep_H_NSPasteboard
