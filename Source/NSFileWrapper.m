/* 
   NSFileWrapper.m

   NSFileWrapper objects hold a file's contents in dynamic memory.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Sept 1998
   
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

#include <gnustep/gui/config.h>

#include <AppKit/NSFileWrapper.h>
#include <AppKit/NSFont.h>


@implementation NSFileWrapper

//
// Initialization 
//
- (id)initDirectoryWithFileWrappers:(NSDictionary *)docs	// Init instance of
{															// directory type
	return nil;
}
														    
- (id)initRegularFileWithContents:(NSData *)data		  // Init instance of
{														  // regular file type
	return nil;
}
														   
- (id)initSymbolicLinkWithDestination:(NSString *)path	  // Init instance of
{														  // symbolic link type
	return nil;
}
										// Init an instance from the file,
										// directory, or symbolic link at path. 
- (id)initWithPath:(NSString *)path		// This can create a tree of instances
{										// with a directory instance at the top
	return nil;
}
										// Init an instance from data in std
										// serial format.  Serial format is the
										// same as that used by NSText's 
										// RTFDFromRange: method.  This can 
										// create a tree of instances with a 
										// directory instance at the top
- (id)initWithSerializedRepresentation:(NSData *)data
{
	return nil;
}

//
// General methods 
//													// write instance to disk
- (BOOL)writeToFile:(NSString *)path 				// at path. if directory
		 atomically:(BOOL)atomicFlag 				// type, this method is
		 updateFilenames:(BOOL)updateFilenamesFlag	// recursive, if flag is
{													// YES the wrapper will be
	return NO;										// updated with the name
}													// used in writing the file
													
- (NSData *)serializedRepresentation
{
	return nil;
}

- (void)setFilename:(NSString *)filename
{
}

- (NSString *)filename
{
	return nil;
}

- (void)setPreferredFilename:(NSString *)filename
{
}

- (NSString *)preferredFilename;
{
	return nil;
}

- (void)setFileAttributes:(NSDictionary *)attributes
{
}

- (NSDictionary *)fileAttributes
{
	return nil;
}

- (BOOL)isRegularFile
{
	return NO;
}

- (BOOL)isDirectory
{
	return NO;
}

- (BOOL)isSymbolicLink
{
	return NO;
}

- (void)setIcon:(NSImage *)icon
{
}

- (NSImage *)icon;
{
	return nil;
}

- (BOOL)needsToBeUpdatedFromPath:(NSString *)path
{
	return NO;
}

- (BOOL)updateFromPath:(NSString *)path
{
	return NO;
}

//								
// Directory type methods 				  
//									 											
- (NSString *)addFileWrapper:(NSFileWrapper *)doc			
{
	return nil;
}

- (void)removeFileWrapper:(NSFileWrapper *)doc				
{
}

- (NSDictionary *)fileWrappers;								
{
	return nil;
}

- (NSString *)keyForFileWrapper:(NSFileWrapper *)doc		
{
	return nil;
}

- (NSString *)addFileWithPath:(NSString *)path				
{
	return nil;
}

- (NSString *)addRegularFileWithContents:(NSData *)data 
					   preferredFilename:(NSString *)filename
{
	return nil;
}

- (NSString *)addSymbolicLinkWithDestination:(NSString *)path 
					   	   preferredFilename:(NSString *)filename
{
	return nil;
}

//								
// Regular file type methods 				  
//									 											
- (NSData *)regularFileContents
{
	return nil;
}

//								
// Symbolic link type methods 				  
//									 											
- (NSString *)symbolicLinkDestination
{
	return nil;
}

//								
// Archiving 				  
//									 											
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  return self;
}

@end
