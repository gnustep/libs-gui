/* 
   NSDataLink.h

   Link between a source and dependent document

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

#ifndef _GNUstep_H_NSDataLink
#define _GNUstep_H_NSDataLink

#include <Foundation/NSCoder.h>
#include <AppKit/AppKitDefines.h>

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

@interface NSDataLink : NSObject <NSCoding>
{
  // Attributes
}

//
// Initializing a Link
//
- (id)initLinkedToFile:(NSString *)filename;
- (id)initLinkedToSourceSelection:(NSSelection *)selection
			managedBy:(NSDataLinkManager *)linkManager
		  supportingTypes:(NSArray *)newTypes;
- (id)initWithContentsOfFile:(NSString *)filename;
- (id)initWithPasteboard:(NSPasteboard *)pasteboard;

//
// Exporting a Link
//
- (BOOL)saveLinkIn:(NSString *)directoryName;
- (BOOL)writeToFile:(NSString *)filename;
- (void)writeToPasteboard:(NSPasteboard *)pasteboard;

//
// Information about the Link
//
- (NSDataLinkDisposition)disposition;
- (NSDataLinkNumber)linkNumber;
- (NSDataLinkManager *)manager;

//
// Information about the Link's Source
//
- (NSDate *)lastUpdateTime;
- (BOOL)openSource;
- (NSString *)sourceApplicationName;
- (NSString *)sourceFilename;
- (NSSelection *)sourceSelection;
- (NSArray *)types;

//
// Information about the Link's Destination
//
- (NSString *)destinationApplicationName;
- (NSString *)destinationFilename;
- (NSSelection *)destinationSelection;

//
// Changing the Link
//
- (BOOL)break;
- (void)noteSourceEdited;
- (void)setUpdateMode:(NSDataLinkUpdateMode)mode;
- (BOOL)updateDestination;
- (NSDataLinkUpdateMode)updateMode;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSDataLink

