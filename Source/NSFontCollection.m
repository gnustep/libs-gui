/* Implementation of class NSFontCollection
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Tue Dec 10 11:51:33 EST 2019

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSArray.h>
#import <Foundation/NSError.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSString.h>
#import <AppKit/NSFontCollection.h>
#import <GNUstepGUI/GSFontInfo.h>

static NSMutableDictionary *_availableFontCollections = nil;
static NSLock *_fontCollectionLock = nil;

@interface NSFontCollection (Private)

+ (void) _loadAvailableFontCollections;
- (BOOL) _writeToFile; 
- (BOOL) _removeFile;
- (void) _setFonts: (NSArray *)fonts;
- (void) _setQueryAttributes: (NSArray *)queryAttributes;
- (void) _setFullFileName: (NSString *)fn;

@end

@implementation NSFontCollection (Private)

/**
 * Load all font collections....
 */
+ (void) _loadAvailableFontCollections
{
  [_fontCollectionLock lock];
  if (_availableFontCollections != nil)
    {
      // Nothing to do ... already loaded
      [_fontCollectionLock unlock];
    }
  else
    {
      NSString			*dir;
      NSString			*file;
      NSEnumerator		*e;
      NSFileManager		*fm = [NSFileManager defaultManager];
      NSDirectoryEnumerator	*de;
      NSFontCollection		*newCollection;

      if (_availableFontCollections == nil)
	{
	  // Create the global array of font collections...
	  _availableFontCollections = [[NSMutableDictionary alloc] init];
	}
      else
	{
	  [_availableFontCollections removeAllObjects];
	}
      
      /*
       * Load color lists found in standard paths into the array
       * FIXME: Check exactly where in the directory tree we should scan.
       */
      e = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
	NSAllDomainsMask, YES) objectEnumerator];

      while ((dir = (NSString *)[e nextObject])) 
	{
	  BOOL flag;

	  dir = [dir stringByAppendingPathComponent: @"FontCollections"];
	  if (![fm fileExistsAtPath: dir isDirectory: &flag] || !flag)
	    {
	      // Only process existing directories
	      continue;
	    }

	  de = [fm enumeratorAtPath: dir];
	  while ((file = [de nextObject])) 
	    {
	      if ([[file pathExtension] isEqualToString: @"collection"])
		{
		  NSString	*name;
		  name = [file stringByDeletingPathExtension];
		  newCollection = [NSKeyedUnarchiver unarchiveObjectWithFile: [dir stringByAppendingPathComponent: file]];
                  if (newCollection != nil && name != nil)
                    {
                      [newCollection _setFullFileName: file];
                      [_availableFontCollections setObject: newCollection forKey: name];
                      RELEASE(newCollection);
                    }
                }
	    }
	}  
      /*
      if (defaultSystemFontCollection != nil)
        {
	  [_availableFontCollections addObject: defaultSystemFontCollection];
	}
      */
      [_fontCollectionLock unlock];
    }
}

/*
 * Writing and Removing Files
 */
- (BOOL) _writeToFile
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString      *tmpPath;
  BOOL          isDir;
  BOOL          success;
  BOOL          path_is_standard = YES;
  NSString     *path = nil;
  
  /*
   * We need to initialize before saving, to avoid the new file being 
   * counted as a different collection thus making it appear twice
   */
  [NSFontCollection _loadAvailableFontCollections];

  if (path == nil)
    {
      NSArray	*paths;

      // FIXME the standard path for saving font collections
      paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
	NSUserDomainMask, YES);
      if ([paths count] == 0)
	{
	  NSLog (@"Failed to find Library directory for user");
	  return NO;	// No directory to save to.
	}
      path = [[paths objectAtIndex: 0]
	stringByAppendingPathComponent: @"FontCollections"]; 
      isDir = YES;
    }
  else
    {
      [fm fileExistsAtPath: path isDirectory: &isDir];
    }

  if (isDir)
    {
      ASSIGN (_fullFileName, [[path stringByAppendingPathComponent: _name] 
        stringByAppendingPathExtension: @"collection"]);
    }
  else // it is a file
    {
      if ([[path pathExtension] isEqual: @"collection"] == YES)
	{
	  ASSIGN (_fullFileName, path);
	}
      else
	{
	  ASSIGN (_fullFileName, [[path stringByDeletingPathExtension]
	    stringByAppendingPathExtension: @"collection"]);
	}
      path = [path stringByDeletingLastPathComponent];
    }

  // Check if the path is a standard path
  if ([[path lastPathComponent] isEqualToString: @"FontCollections"] == NO)
    {
      path_is_standard = NO;
    }
  else 
    {
      tmpPath = [path stringByDeletingLastPathComponent];
      if (![NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
	NSAllDomainsMask, YES) containsObject: tmpPath])
	{
	  path_is_standard = NO;
	}
    }

  /*
   * If path is standard and it does not exist, try to create it.
   * System standard paths should always be assumed to exist; 
   * this will normally then only try to create user paths.
   */
  if (path_is_standard && ([fm fileExistsAtPath: path] == NO))
    {
      if ([fm createDirectoryAtPath: path 
        withIntermediateDirectories: YES
			 attributes: nil
                              error: NULL])
	{
	  NSLog (@"Created standard directory %@", path);
	}
      else
	{
	  NSLog (@"Failed attempt to create directory %@", path);
	}
    }

  success = [NSKeyedArchiver archiveRootObject: self 
                                        toFile: _fullFileName];

  if (success && path_is_standard)
    {
      [_fontCollectionLock lock];
      if ([[_availableFontCollections allValues] containsObject: self] == NO)
        {
          NSString *name = [[_fullFileName lastPathComponent] stringByDeletingPathExtension];
          [_availableFontCollections setObject: self forKey: name];
        }
      [_fontCollectionLock unlock];      
      return YES;
    }
  
  return success;
}

- (BOOL) _removeFile
{
  BOOL result = NO;
  if (_fullFileName) //  && _is_editable)
    {
      // Remove the file
      [[NSFileManager defaultManager] removeFileAtPath: _fullFileName
					       handler: nil];
      
      // Remove the color list from the global list of colors
      [_fontCollectionLock lock];
      NSString *name = [[_fullFileName lastPathComponent] stringByDeletingPathExtension];
      [_availableFontCollections removeObjectForKey: name];
      [_fontCollectionLock unlock];

      // Reset file name
      _fullFileName = nil;
    }
  return result;
}

- (void) _setFonts: (NSArray *)fonts
{
  // [_fonts addObjectsFromArray: fonts];
}

- (void) _setQueryAttributes: (NSArray *)queryAttributes
{
  ASSIGN(_queryAttributes, [queryAttributes mutableCopy]);
}

- (void) _setName: (NSString *)n
{
  ASSIGNCOPY(_name, n);
}

- (NSString *) _name
{
  return _name;
}

- (void) _setFullFileName: (NSString *)fn
{
  ASSIGNCOPY(_fullFileName, fn);
}

@end

@interface NSCTFontCollection : NSObject
@end

@implementation NSCTFontCollection
@end

@implementation NSFontCollection 


+ (void) initialize
{
  if (self == [NSFontCollection class])
    {
      [self _loadAvailableFontCollections];
    }
}

// Initializers...
- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      //      _fonts = [[NSMutableArray alloc] initWithCapacity: 50];
      _queryDescriptors = [[NSMutableArray alloc] initWithCapacity: 10];
      _exclusionDescriptors = [[NSMutableArray alloc] initWithCapacity: 10];
      _queryAttributes = [[NSMutableArray alloc] initWithCapacity: 10];
    }
  return self;
}

- (void) dealloc
{
  //  RELEASE(_fonts);
  RELEASE(_queryDescriptors);
  RELEASE(_exclusionDescriptors);
  RELEASE(_queryAttributes);
  [super dealloc];
}

+ (NSFontCollection *) fontCollectionWithDescriptors: (NSArray *)queryDescriptors
{
  NSFontCollection *fc = [[NSFontCollection alloc] init];
  ASSIGNCOPY(fc->_queryDescriptors, queryDescriptors);
  return fc;
}

+ (NSFontCollection *) fontCollectionWithAllAvailableDescriptors
{
  return [self fontCollectionWithDescriptors:
                 [[GSFontEnumerator sharedEnumerator] availableFontDescriptors]];
}

+ (NSFontCollection *) fontCollectionWithLocale: (NSLocale *)locale
{
  return [self fontCollectionWithAllAvailableDescriptors];
}

+ (BOOL) showFontCollection: (NSFontCollection *)collection
                   withName: (NSFontCollectionName)name
                 visibility: (NSFontCollectionVisibility)visibility
                      error: (NSError **)error
{
  BOOL rv = [collection _writeToFile];
  [NSFontCollection _loadAvailableFontCollections];
  return rv;
}

+ (BOOL) hideFontCollectionWithName: (NSFontCollectionName)name
                         visibility: (NSFontCollectionVisibility)visibility
                              error: (NSError **)error
{
  NSFontCollection *collection = [_availableFontCollections objectForKey: name];
  BOOL rv = [collection _removeFile];
  
  [NSFontCollection _loadAvailableFontCollections];

  return rv;
}

+ (BOOL) renameFontCollectionWithName: (NSFontCollectionName)aname
                           visibility: (NSFontCollectionVisibility)visibility
                               toName: (NSFontCollectionName)name
                                error: (NSError **)error
{
  NSFontCollection *collection = [_availableFontCollections objectForKey: aname];
  BOOL rv = [collection _removeFile];

  if (rv == YES)
    {
      [collection _setName: name];
      [collection _writeToFile];
    }
  [NSFontCollection _loadAvailableFontCollections];

  return rv;
}

+ (NSArray *) allFontCollectionNames
{
  return [_availableFontCollections allKeys];
}

+ (NSFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
{
  return nil;
}

+ (NSFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
                                   visibility: (NSFontCollectionVisibility)visibility
{
  return nil;
}

// Descriptors
- (NSArray *) queryDescriptors  // copy
{
  return [_queryDescriptors copy];
}

- (NSArray *) exclusionDescriptors
{
  return [_exclusionDescriptors copy];
}

- (NSArray *) matchingDescriptors
{
  return [self matchingDescriptorsWithOptions: nil];
}

- (NSArray *) matchingDescriptorsWithOptions: (NSDictionary *)options
{
  GSFontEnumerator *fen = [GSFontEnumerator sharedEnumerator];
  return [fen matchingFontDescriptorsFor: options];
}

- (NSArray *) matchingDescriptorsForFamily: (NSString *)family
{
  return [self matchingDescriptorsForFamily: family options: nil];
}

- (NSArray *) matchingDescriptorsForFamily: (NSString *)family options: (NSDictionary *)options
{
  NSMutableArray *r = [NSMutableArray arrayWithCapacity: 50];
  NSArray *a = [self matchingDescriptorsWithOptions: options];
  NSEnumerator *en = [a objectEnumerator];
  id o = nil;

  while((o = [en nextObject]) != nil)
    {
      if ([[o familyName] isEqualToString: family])
        {
          [r addObject: o];
        }    
    }
  
  return [a copy];
}

- (instancetype) copyWithZone: (NSZone *)zone
{
  NSFontCollection *fc = [[NSFontCollection allocWithZone: zone] init];

  // ASSIGNCOPY(fc->_fonts, _fonts);
  ASSIGNCOPY(fc->_queryDescriptors, _queryDescriptors);
  ASSIGNCOPY(fc->_exclusionDescriptors, _exclusionDescriptors);
  ASSIGNCOPY(fc->_queryAttributes, _queryAttributes);

  return fc;
}

- (instancetype) mutableCopyWithZone: (NSZone *)zone
{
  NSMutableFontCollection *fc = [[NSMutableFontCollection allocWithZone: zone] init];

  // [fc _setFonts: _fonts];
  [fc setQueryDescriptors: _queryDescriptors];
  [fc setExclusionDescriptors: _exclusionDescriptors];
  [fc _setQueryAttributes: _queryAttributes];

  return fc;
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
        }
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
}
  
@end
 

@implementation NSMutableFontCollection 

+ (NSMutableFontCollection *) fontCollectionWithDescriptors: (NSArray *)queryDescriptors
{
  NSMutableFontCollection *fc = [[NSMutableFontCollection alloc] init];
  ASSIGNCOPY(fc->_queryDescriptors, queryDescriptors);
  return fc;
}

+ (NSMutableFontCollection *) fontCollectionWithAllAvailableDescriptors
{
  return [self fontCollectionWithDescriptors:
                 [[GSFontEnumerator sharedEnumerator] availableFontDescriptors]];
}

+ (NSMutableFontCollection *) fontCollectionWithLocale: (NSLocale *)locale
{
  return [self fontCollectionWithAllAvailableDescriptors];
}

+ (NSMutableFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
{
  return nil; 
}

+ (NSMutableFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
                                          visibility: (NSFontCollectionVisibility)visibility
{
  return nil; 
}

- (NSArray *) queryDescriptors
{
  return _queryDescriptors;
}

- (void) setQueryDescriptors: (NSArray *)queryDescriptors
{
  ASSIGN(_queryDescriptors, [queryDescriptors mutableCopy]);
}

- (NSArray *) exclusionDescriptors
{
  return _exclusionDescriptors;
}

- (void) setExclusionDescriptors: (NSArray *)exclusionDescriptors
{
  ASSIGN(_exclusionDescriptors, [exclusionDescriptors mutableCopy]);
}

- (void)addQueryForDescriptors: (NSArray *)descriptors
{
  [_queryDescriptors addObjectsFromArray: descriptors];
}

- (void)removeQueryForDescriptors: (NSArray *)descriptors
{
  [_queryDescriptors removeObjectsInArray: descriptors];
}

@end
