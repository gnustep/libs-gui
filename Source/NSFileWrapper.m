/* 
   NSFileWrapper.m

   NSFileWrapper objects hold a file's contents in dynamic memory.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Sept 1998
   Author:  Jonathan Gapen <jagapen@whitewater.chem.wisc.edu>
   Date: Dec 1999
   
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
#include <AppKit/NSWorkspace.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>


@implementation NSFileWrapper

//
// Initialization 
//

// Init instance of directory type
- (id)initDirectoryWithFileWrappers:(NSDictionary *)docs
{
  NSEnumerator *enumerator;
  id key;
  NSFileWrapper *wrapper;
  [super init];

  _wrapperType = GSFileWrapperDirectoryType;
  _wrapperData = [NSMutableDictionary dictionaryWithCapacity: [docs count]];

  enumerator = [docs keyEnumerator];
  while ((key = [enumerator nextObject]))
    {
      wrapper = (NSFileWrapper *)[docs objectForKey: key];

      if (![wrapper preferredFilename])
        [wrapper setPreferredFilename: key];

      [_wrapperData setObject: wrapper forKey: key];
    }

  return self;
}
    
// Init instance of regular file type
- (id)initRegularFileWithContents:(NSData *)data
{
  [super init];

  _wrapperData = [data copyWithZone: [self zone]];
  _wrapperType = GSFileWrapperRegularFileType;
  
  return self;
}

// Init instance of symbolic link type
- (id)initSymbolicLinkWithDestination:(NSString *)path
{
  [super init];

  _wrapperData = path;
  _wrapperType = GSFileWrapperSymbolicLinkType;

  return self;
}
										// Init an instance from the file,
// directory, or symbolic link at path. 
// This can create a tree of instances
// with a directory instance at the top

- (id)initWithPath:(NSString *)path
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *fileType;

  NSDebugLLog(@"NSFileWrapper", @"initWithPath: %@", path);

  [self setFilename: path];
  [self setPreferredFilename: [path lastPathComponent]];
  [self setFileAttributes: [fm fileAttributesAtPath: path traverseLink: NO]];

  fileType = [[self fileAttributes] fileType];
  if ([fileType isEqualToString: @"NSFileTypeDirectory"])
    {
      NSString *filename;
      NSMutableArray *fileWrappers = [NSMutableArray new];
      NSArray *filenames = [fm directoryContentsAtPath: path];
      NSEnumerator *enumerator = [filenames objectEnumerator];

      while ((filename = [enumerator nextObject]))
        {
          [fileWrappers addObject:
            [[NSFileWrapper alloc] initWithPath:
              [path stringByAppendingPathComponent: filename]]];
        }
      self = [self initDirectoryWithFileWrappers: 
        [NSDictionary dictionaryWithObjects: fileWrappers forKeys: filenames]];
    }
  else if ([fileType isEqualToString: @"NSFileTypeRegular"])
    {
      self = [self initRegularFileWithContents:
                 [[NSData alloc] initWithContentsOfFile: path]];
    }
  else if ([fileType isEqualToString: @"NSFileTypeSymbolicLink"])
    {
      self = [self initSymbolicLinkWithDestination:
                 [fm pathContentOfSymbolicLinkAtPath: path]];
    }

  return self;
}
										// Init an instance from data in std
// serial format.  Serial format is the
// same as that used by NSText's 
// RTFDFromRange: method.  This can 
// create a tree of instances with a 
// directory instance at the top

// FIXME - implement
- (id)initWithSerializedRepresentation:(NSData *)data
{
  return nil;
}

- (void)dealloc
{
  if (_filename)
    [_filename release];
  if (_preferredFilename)
    [_preferredFilename release];
  if (_wrapperData)
    [_wrapperData release];
  if (_iconImage)
    [_iconImage release];
}

//
// General methods 
//

// write instance to disk at path; if directory type, this
// method is recursive; if updateFilenamesFlag is YES, the wrapper
// will be updated with the name used in writing the file

- (BOOL)writeToFile:(NSString *)path
         atomically:(BOOL)atomicFlag
    updateFilenames:(BOOL)updateFilenamesFlag
{
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL pathExists = [fm fileExistsAtPath: path];

  NSDebugLLog(@"NSFileWrapper",
              @"writeToFile: %@ atomically: updateFilenames:", path);

  // don't overwrite existing paths
  if (pathExists && atomicFlag)
    return NO;

  if (updateFilenamesFlag == YES)
    [self setFilename: [path lastPathComponent]];

  switch (_wrapperType)
    {
      case GSFileWrapperDirectoryType:
        {
          // FIXME - more robust save proceedure when atomicFlag set
          NSEnumerator *enumerator = [_wrapperData keyEnumerator];
          NSString *key;

          [fm createDirectoryAtPath: path attributes: _fileAttributes];
          while ((key = (NSString *)[enumerator nextObject]))
            {
              NSString *newPath =
                  [path stringByAppendingPathComponent: key];
              [[_wrapperData objectForKey: key] writeToFile: newPath
                                                 atomically: atomicFlag
                                         updateFilenames: updateFilenamesFlag];
            }
          return YES;
        }
      case GSFileWrapperRegularFileType:
        {
          return [_wrapperData writeToFile: path atomically: atomicFlag];
        }
      case GSFileWrapperSymbolicLinkType:
        {
          return [fm createSymbolicLinkAtPath: path pathContent: _wrapperData];
        }
    }
  return NO;
}

// FIXME - implement
- (NSData *)serializedRepresentation
{
  return nil;
}

- (void)setFilename:(NSString *)filename
{
  if (filename == nil || [filename isEqualToString: @""])
    [NSException raise: NSInternalInconsistencyException
                format: @"Empty or nil argument to setFilename:"];
  else
    ASSIGN(_filename, filename);
}

- (NSString *)filename
{
  return _filename;
}

- (void)setPreferredFilename:(NSString *)filename
{
  if (filename == nil || [filename isEqualToString: @""])
    [NSException raise: NSInternalInconsistencyException
                format: @"Empty or nil argument to setPreferredFilename:"];
  else
    ASSIGN(_preferredFilename, filename);
}

- (NSString *)preferredFilename;
{
  return _preferredFilename;
}

- (void)setFileAttributes:(NSDictionary *)attributes
{
  if (_fileAttributes == nil)
    _fileAttributes = [NSMutableDictionary new];

  [_fileAttributes addEntriesFromDictionary: attributes];
}

- (NSDictionary *)fileAttributes
{
  return _fileAttributes;
}

- (BOOL)isRegularFile
{
  if (_wrapperType == GSFileWrapperRegularFileType)
    return YES;
  else
    return NO;
}

- (BOOL)isDirectory
{
  if (_wrapperType == GSFileWrapperDirectoryType)
    return YES;
  else
    return NO;
}

- (BOOL)isSymbolicLink
{
  if (_wrapperType == GSFileWrapperSymbolicLinkType)
    return YES;
  else
    return NO;
}

- (void)setIcon:(NSImage *)icon
{
  ASSIGN(_iconImage, icon);
}

- (NSImage *)icon;
{
  if (!_iconImage)
    return [[NSWorkspace sharedWorkspace] iconForFile: [self filename]];
  else
    return _iconImage;
}

// FIXME - for directory wrappers
- (BOOL)needsToBeUpdatedFromPath:(NSString *)path
{
  NSFileManager *fm = [NSFileManager defaultManager];

  switch (_wrapperType)
    {
      case GSFileWrapperRegularFileType:
        if ([[self fileAttributes]
                isEqualToDictionary: [fm fileAttributesAtPath: path
                                                 traverseLink: NO]])
          return NO;
        break;
      case GSFileWrapperSymbolicLinkType:
        if ([_wrapperData isEqualToString:
                          [fm pathContentOfSymbolicLinkAtPath: path]])
          return NO;
        break;
      case GSFileWrapperDirectoryType:
        break;
    }

  return YES;
}

// FIXME - implement
- (BOOL)updateFromPath:(NSString *)path
{
  return NO;
}

//
// Directory type methods 
//

#define GSFileWrapperDirectoryTypeCheck() \
  if (_wrapperType != GSFileWrapperDirectoryType) \
	[NSException raise: NSInternalInconsistencyException \
	            format: @"Can't invoke %@ on a file wrapper that" \
                            @" does not wrap a directory!", _cmd];

// FIXME - handle duplicate names
- (NSString *)addFileWrapper:(NSFileWrapper *)doc			
{
  NSString *key;

  GSFileWrapperDirectoryTypeCheck();

  key = [doc preferredFilename];
  if (key == nil || [key isEqualToString: @""])
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"Adding file wrapper with no preferred filename."];
      return nil;
    }

  [_wrapperData setObject: doc forKey: key];

  return key;
}

- (void)removeFileWrapper:(NSFileWrapper *)doc				
{
  GSFileWrapperDirectoryTypeCheck();

  [_wrapperData removeObjectsForKeys: [_wrapperData allKeysForObject: doc]];
}

- (NSDictionary *)fileWrappers
{
  GSFileWrapperDirectoryTypeCheck();

  return _wrapperData;
}

- (NSString *)keyForFileWrapper:(NSFileWrapper *)doc
{
  GSFileWrapperDirectoryTypeCheck();

  return [[_wrapperData allKeysForObject: doc] objectAtIndex: 0];
}

- (NSString *)addFileWithPath:(NSString *)path
{
  NSFileWrapper *wrapper;
  GSFileWrapperDirectoryTypeCheck();

  wrapper = [[NSFileWrapper alloc] initWithPath: path];
  if (wrapper != nil)
    return [self addFileWrapper: wrapper];
  else
    return nil;
}

- (NSString *)addRegularFileWithContents:(NSData *)data 
                       preferredFilename:(NSString *)filename
{
  NSFileWrapper *wrapper;
  GSFileWrapperDirectoryTypeCheck();

  wrapper = [[NSFileWrapper alloc] initRegularFileWithContents: data];
  if (wrapper != nil)
    {
      [wrapper setPreferredFilename: filename];
      return [self addFileWrapper: wrapper];
    }
  else
    return nil;
}

- (NSString *)addSymbolicLinkWithDestination:(NSString *)path 
                           preferredFilename:(NSString *)filename
{
  NSFileWrapper *wrapper;
  GSFileWrapperDirectoryTypeCheck();

  wrapper = [[NSFileWrapper alloc] initSymbolicLinkWithDestination: path];
  if (wrapper != nil)
    {
      [wrapper setPreferredFilename: filename];
      return [self addFileWrapper: wrapper];
    }
  else
    return nil;
}

//								
// Regular file type methods 				  
//									 											
- (NSData *)regularFileContents
{
  if (_wrapperType == GSFileWrapperRegularFileType)
    return _wrapperData;
  else
    [NSException raise: NSInternalInconsistencyException
                format: @"File wrapper does not wrap regular file."];

  return nil; 
}

//								
// Symbolic link type methods 				  
//									 											
- (NSString *)symbolicLinkDestination
{
  if (_wrapperType == GSFileWrapperSymbolicLinkType)
    return _wrapperData;
  else
    [NSException raise: NSInternalInconsistencyException
                format: @"File wrapper does not wrap symbolic link."];

  return nil;
}

//								
// Archiving 				  
//

// The MacOS X docs do not say that NSFileWrapper conforms to the
// NSCoding protocol.  Should it nonetheless?

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
