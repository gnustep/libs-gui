/* 
   NSPasteboard.h

   Class to transfer data to and from the pasteboard server

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

//
// Pasteboard Type Globals 
//
APPKIT_EXPORT NSString *NSStringPboardType;
APPKIT_EXPORT NSString *NSColorPboardType;
APPKIT_EXPORT NSString *NSFileContentsPboardType;
APPKIT_EXPORT NSString *NSFilenamesPboardType;
APPKIT_EXPORT NSString *NSFontPboardType;
APPKIT_EXPORT NSString *NSRulerPboardType;
APPKIT_EXPORT NSString *NSPostScriptPboardType;
APPKIT_EXPORT NSString *NSTabularTextPboardType;
APPKIT_EXPORT NSString *NSRTFPboardType;
APPKIT_EXPORT NSString *NSRTFDPboardType;
APPKIT_EXPORT NSString *NSTIFFPboardType;
APPKIT_EXPORT NSString *NSDataLinkPboardType;
APPKIT_EXPORT NSString *NSGeneralPboardType;

#ifndef STRICT_OPENSTEP
APPKIT_EXPORT NSString *NSPDFPboardType;
APPKIT_EXPORT NSString *NSPICTPboardType;
APPKIT_EXPORT NSString *NSURLPboardType;
#endif

//
// Pasteboard Name Globals 
//
APPKIT_EXPORT NSString *NSDragPboard;
APPKIT_EXPORT NSString *NSFindPboard;
APPKIT_EXPORT NSString *NSFontPboard;
APPKIT_EXPORT NSString *NSGeneralPboard;
APPKIT_EXPORT NSString *NSRulerPboard;

//
// Pasteboard Exceptions
//
APPKIT_EXPORT NSString *NSPasteboardCommunicationException;


@interface NSPasteboard : NSObject
{
    NSString*	name;		// The name of this pasteboard.
    int		changeCount;	// What we think the current count is.
    id		target;		// Proxy to the object in the server.
    id		owner;		// Local pasteboard owner.
    BOOL	useHistory;	// Want strict OPENSTEP?
}

//
// Creating and Releasing an NSPasteboard Object
//
+ (NSPasteboard *)generalPasteboard;
+ (NSPasteboard *)pasteboardWithName:(NSString *)name;
+ (NSPasteboard *)pasteboardWithUniqueName;
- (void)releaseGlobally;

//
// Getting Data in Different Formats 
//
+ (NSPasteboard *)pasteboardByFilteringData:(NSData *)data
				     ofType:(NSString *)type;
+ (NSPasteboard *)pasteboardByFilteringFile:(NSString *)filename;
+ (NSPasteboard *)pasteboardByFilteringTypesInPasteboard:(NSPasteboard *)pboard;
+ (NSArray *)typesFilterableTo:(NSString *)type;

//
// Referring to a Pasteboard by Name 
//
- (NSString *)name;

//
// Writing Data 
//
- (int)addTypes:(NSArray *)newTypes
	  owner:(id)newOwner;
- (int)declareTypes:(NSArray *)newTypes
	      owner:(id)newOwner;
- (BOOL)setData:(NSData *)data
	forType:(NSString *)dataType;
- (BOOL)setPropertyList:(id)propertyList
		forType:(NSString *)dataType;
- (BOOL)setString:(NSString *)string
	  forType:(NSString *)dataType;
- (BOOL)writeFileContents:(NSString *)filename;
- (BOOL)writeFileWrapper:(NSFileWrapper *)wrapper;

//
// Determining Types 
//
- (NSString *)availableTypeFromArray:(NSArray *)types;
- (NSArray *)types;

//
// Reading Data 
//
- (int)changeCount;
- (NSData *)dataForType:(NSString *)dataType;
- (id)propertyListForType:(NSString *)dataType;
- (NSString *)readFileContentsType:(NSString *)type
			    toFile:(NSString *)filename;
- (NSFileWrapper *)readFileWrapper;
- (NSString *)stringForType:(NSString *)dataType;

@end

@interface NSObject (NSPasteboardOwner)
//
// Methods Implemented by the Owner 
//
- (void)pasteboard:(NSPasteboard *)sender
provideDataForType:(NSString *)type;
- (void)pasteboard:(NSPasteboard *)sender
provideDataForType:(NSString *)type
	andVersion:(int)ver;
- (void)pasteboardChangedOwner:(NSPasteboard *)sender;

@end

@interface NSPasteboard (GNUstepExtensions)
+ (NSString *) mimeTypeForPasteboardType: (NSString *)type;
+ (NSString *) pasteboardTypeForMimeType: (NSString *)mimeType;

- (void)setChangeCount: (int)changeCount;
@end

//
// Return File-related Pasteboard Types
//
APPKIT_EXPORT NSString *NSCreateFileContentsPboardType(NSString *fileType);
APPKIT_EXPORT NSString *NSCreateFilenamePboardType(NSString *filename);
APPKIT_EXPORT NSString *NSGetFileType(NSString *pboardType);
APPKIT_EXPORT NSArray *NSGetFileTypes(NSArray *pboardTypes);


#endif // _GNUstep_H_NSPasteboard
