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

#include <gnustep/gui/config.h>
#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>

@class NSString;
@class NSArray;
@class NSData;

//
// Pasteboard Type Globals 
//
extern NSString *NSStringPboardType;
extern NSString *NSColorPboardType;
extern NSString *NSFileContentsPboardType;
extern NSString *NSFilenamesPboardType;
extern NSString *NSFontPboardType;
extern NSString *NSRulerPboardType;
extern NSString *NSPostScriptPboardType;
extern NSString *NSTabularTextPboardType;
extern NSString *NSRTFPboardType;
extern NSString *NSTIFFPboardType;
extern NSString *NSDataLinkPboardType;
extern NSString *NSGeneralPboardType;

//
// Pasteboard Name Globals 
//
extern NSString *NSDragPboard;
extern NSString *NSFindPboard;
extern NSString *NSFontPboard;
extern NSString *NSGeneralPboard;
extern NSString *NSRulerPboard;

@interface NSPasteboard : NSObject
{
  // Attributes
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
- (NSString *)stringForType:(NSString *)dataType;

//
// Methods Implemented by the Owner 
//
- (void)pasteboard:(NSPasteboard *)sender
  provideDataForType:(NSString *)type;
- (void)pasteboardChangedOwner:(NSPasteboard *)sender;

@end

//
// Return File-related Pasteboard Types
//
NSString *NSCreateFileContentsPboardType(NSString *fileType);
NSString *NSCreateFilenamePboardType(NSString *filename);
NSString *NSGetFileType(NSString *pboardType);
NSArray *NSGetFileTypes(NSArray *pboardTypes);


#endif // _GNUstep_H_NSPasteboard
