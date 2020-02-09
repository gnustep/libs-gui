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

static NSMutableArray *_availableFontCollections = nil;
static NSLock *_fontCollectionLock = nil;

@interface NSFontCollection (Private)

+ (void) _loadAvailableFontCollections;
- (BOOL) _writeToFile: (NSString *)path;
- (void) _removeFile;
- (void) _setFonts: (NSArray *)fonts;
- (void) _setQueryAttributes: (NSArray *)queryAttributes;

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
	  _availableFontCollections = [[NSMutableArray alloc] init];
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
                  if (newCollection != nil)
                    {
                      [_availableFontCollections addObject: newCollection];
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
- (BOOL) _writeToFile: (NSString *)path
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString      *tmpPath;
  BOOL          isDir;
  BOOL          success;
  BOOL          path_is_standard = YES;

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
      if ([_availableFontCollections containsObject: self] == NO)
	[_availableFontCollections addObject: self];
      [_fontCollectionLock unlock];      
      return YES;
    }
  
  return success;
}

- (void) _removeFile
{
  if (_fullFileName) //  && _is_editable)
    {
      // Remove the file
      [[NSFileManager defaultManager] removeFileAtPath: _fullFileName
					       handler: nil];
      
      // Remove the color list from the global list of colors
      [_fontCollectionLock lock];
      [_availableFontCollections removeObject: self];
      [_fontCollectionLock unlock];

      // Reset file name
      _fullFileName = nil;
    }
}

- (void) _setFonts: (NSArray *)fonts
{
  // [_fonts addObjectsFromArray: fonts];
}

- (void) _setQueryAttributes: (NSArray *)queryAttributes
{
  ASSIGN(_queryAttributes, [queryAttributes mutableCopy]);
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

// This method will get the actual list of fonts
/*
- (void) _runQueryWithDescriptors: (NSArray *)queryDescriptors
{
  NSEnumerator *en = [queryDescriptors objectEnumerator];
  GSFontEnumerator *fen = [GSFontEnumerator sharedEnumerator];
  id d = nil;

  ASSIGNCOPY(_queryDescriptors, queryDescriptors);
  while ((d = [en nextObject]) != nil)
    {
      NSArray *names = [fen availableFontNamesMatchingFontDescriptor: d];
      id name = nil;

      en = [names objectEnumerator];
      while ((name = [en nextObject]) != nil)
        {
          NSFont *font = [NSFont fontWithName: name size: 0.0]; // get default size
          [_fonts addObject: font];
        }
    }
}*/

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
  return YES;
}

+ (BOOL) hideFontCollectionWithName: (NSFontCollectionName)name
                         visibility: (NSFontCollectionVisibility)visibility
                              error: (NSError **)error
{
  return YES;
}

+ (BOOL) renameFontCollectionWithName: (NSFontCollectionName)aname
                           visibility: (NSFontCollectionVisibility)visibility
                               toName: (NSFontCollectionName)name
                                error: (NSError **)error
{
  return YES;
}

+ (NSArray *) allFontCollectionNames
{
  return nil;
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
