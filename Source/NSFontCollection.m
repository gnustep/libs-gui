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
#import <Foundation/NSData.h>

#import <AppKit/NSFontCollection.h>
#import <GNUstepGUI/GSFontInfo.h>

static NSMutableDictionary *_availableFontCollections = nil;
static NSLock *_fontCollectionLock = nil;

/*
 * Private functions...
 */
@interface NSFontCollection (Private)

+ (void) _loadAvailableFontCollections;
- (BOOL) _writeToFile; 
- (BOOL) _removeFile;
- (NSMutableDictionary *) _fontCollectionDictionary;
- (void) _setFontCollectionDictionary: (NSMutableDictionary *)dict;
- (void) _setQueryAttributes: (NSArray *)queryAttributes;
- (void) _setFullFileName: (NSString *)fn;

@end

/*
 * Private functions...
 */
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
       * Load font lists found in standard paths into the array
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
		  NSString *name = [file stringByDeletingPathExtension];
		  newCollection = [self _readFileAtPath: [dir stringByAppendingPathComponent: file]]; 
                  if (newCollection != nil && name != nil)
                    {
                      [newCollection _setFullFileName: file];
                      [_availableFontCollections setObject: newCollection
                                                     forKey: name];
                      RELEASE(newCollection);
                    }
                }
	    }
	}  

      [_fontCollectionLock unlock];
    }
}

+ (NSFontCollection *) _readFileAtPath: (NSString *)path
{
  NSFontCollection *fc = [[NSFontCollection alloc] init];
  NSData *d = [NSData dataWithContentsOfFile: path];
  NSKeyedUnarchiver *u = [[NSKeyedUnarchiver alloc] initForReadingWithData: d];

  [fc _setFontCollectionDictionary: [u decodeObjectForKey: @"NSFontCollectionDictionary"]];
  RELEASE(u);
  RELEASE(d);
  
  return fc;
}

/*
 * Writing and Removing Files
 */
- (BOOL) _writeToFile
{
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL           success = NO;
  NSString      *path = nil;
  NSArray	*paths;
  
  /*
   * We need to initialize before saving, to avoid the new file being 
   * counted as a different collection thus making it appear twice
   */
  [NSFontCollection _loadAvailableFontCollections];
  
  // Find library....
  paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                              NSUserDomainMask, YES);
  if ([paths count] == 0)
    {
      NSLog (@"Failed to find Library directory for user");
      return NO;	// No directory to save to.
    }
  
  path = [[paths objectAtIndex: 0] stringByAppendingPathComponent: @"FontCollections"];
  if ([fm fileExistsAtPath: path] == NO)
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

  NSLog(@"Name = %@", [self _name]);
  
  // Create the archive...
  [self _setFullFileName:
          [path stringByAppendingPathComponent:
                  [[self _name] stringByAppendingPathExtension: @"collection"]]];
  NSMutableData *m = [[NSMutableData alloc] initWithCapacity: 10240];
  NSKeyedArchiver *a = [[NSKeyedArchiver alloc] initForWritingWithMutableData: m];
  [a encodeObject: [self _fontCollectionDictionary]
           forKey: @"NSFontCollectionDictionary"];
  [a finishEncoding];
  RELEASE(a);

  // Write the file....
  NSLog(@"Writing to %@", [self _fullFileName]);
  success = [m writeToFile: [self _fullFileName] atomically: YES];
  if (success)
    {
      [_fontCollectionLock lock];
      if ([[_availableFontCollections allValues] containsObject: self] == NO)
        {
          NSString *name = [[[self _fullFileName] lastPathComponent] stringByDeletingPathExtension];
          [_availableFontCollections setObject: self forKey: name];
        }
      [_fontCollectionLock unlock];      
      return YES;
    }
  RELEASE(m);
  
  return success;
}

- (BOOL) _removeFile
{
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL          isDir;
  NSString     *path = nil;
  BOOL result = NO;
 
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
      [self _setFullFileName: [[path stringByAppendingPathComponent: [self _name]] 
                                stringByAppendingPathExtension: @"collection"]];
    }
  else // it is a file
    {
      if ([[path pathExtension] isEqual: @"collection"] == YES)
	{
          [self _setFullFileName: path];
	}
      else
	{
          [self _setFullFileName: [[path stringByDeletingPathExtension]
                                    stringByAppendingPathExtension: @"collection"]];
	}
      path = [path stringByDeletingLastPathComponent];
    }
    
  if ([self _fullFileName]) 
    {
      // Remove the file
      [[NSFileManager defaultManager] removeFileAtPath: [self _fullFileName]
					       handler: nil];
      
      // Remove the color list from the global list of colors
      [_fontCollectionLock lock];
      NSString *name = [[[self _fullFileName] lastPathComponent] stringByDeletingPathExtension];
      [_availableFontCollections removeObjectForKey: name];
      [_fontCollectionLock unlock];

      // Reset file name
      [self _setFullFileName: nil];
    }
  
  return result;
}

- (NSMutableDictionary *) _fontCollectionDictionary
{
  return _fontCollectionDictionary;
}

- (void) _setFontCollectionDictionary: (NSMutableDictionary *)dict
{
  ASSIGNCOPY(_fontCollectionDictionary, dict);
}

- (void) _setQueryAttributes: (NSArray *)queryAttributes
{
  return [_fontCollectionDictionary setObject: queryAttributes
                                       forKey: @"NSFontDescriptorAttributes"];
}

- (void) _setName: (NSString *)n
{
  [_fontCollectionDictionary setObject: n
                                forKey: @"NSFontCollectionName"];
}

- (NSString *) _name
{
  return [_fontCollectionDictionary objectForKey: @"NSFontCollectionName"];
}

- (void) _setFullFileName: (NSString *)fn
{
  [_fontCollectionDictionary setObject: fn
                                forKey: @"NSFontCollectionFileName"];
}

- (NSString *) _fullFileName
{
  return [_fontCollectionDictionary objectForKey: @"NSFontCollectionFileName"];
}

@end

/*
 * NSFontCollection
 */ 
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
      _fontCollectionDictionary = [[NSMutableDictionary alloc] initWithCapacity: 10];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_fontCollectionDictionary);
  [super dealloc];
}

+ (NSFontCollection *) fontCollectionWithDescriptors: (NSArray *)queryDescriptors
{
  NSFontCollection *fc = [[NSFontCollection alloc] init];
  [fc _setQueryAttributes: queryDescriptors];
  return fc;
}

+ (NSFontCollection *) fontCollectionWithAllAvailableDescriptors
{
  NSFontCollection *fc =  [self fontCollectionWithDescriptors:
                                  [[GSFontEnumerator sharedEnumerator] availableFontDescriptors]];
  if (fc != nil)
    {
      [fc _setName: NSFontCollectionAllFonts];
      [fc _writeToFile];
      [NSFontCollection _loadAvailableFontCollections];
    }
  
  return fc;
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
  NSFontCollection *fc = [_availableFontCollections objectForKey: name];
  if (fc == nil)
    {
      BOOL rv = NO; 

      fc = [[NSFontCollection alloc] init];
      [fc _setName: name];
      rv = [fc _writeToFile];
      if (rv == YES)
        {
          [NSFontCollection _loadAvailableFontCollections];
        }
    }
  return fc;
}

+ (NSFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
                                   visibility: (NSFontCollectionVisibility)visibility
{
  return [self fontCollectionWithName: name];
}

// Descriptors
- (NSArray *) queryDescriptors 
{
  return [_fontCollectionDictionary objectForKey: @"NSFontDescriptorAttributes"];
}

- (NSArray *) exclusionDescriptors
{
  return [_fontCollectionDictionary objectForKey: @"NSFontExclusionDescriptorAttributes"];
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
  ASSIGNCOPY(fc->_fontCollectionDictionary, _fontCollectionDictionary);
  return fc;
}

- (instancetype) mutableCopyWithZone: (NSZone *)zone
{
  NSMutableFontCollection *fc = [[NSMutableFontCollection allocWithZone: zone] init];

  [fc _setFontCollectionDictionary: _fontCollectionDictionary];

  return fc;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: _fontCollectionDictionary
                   forKey: @"NSFontCollectionDictionary"];
    }
}

- (instancetype) initWithCoder: (NSCoder *)coder
{
  self = [super init];
  if (self != nil)
    {
      if ([coder allowsKeyedCoding])
        {
          ASSIGN(_fontCollectionDictionary,
                 [coder decodeObjectForKey: @"NSFontCollectionDictionary"]);
        }
    }
  return self;
}
  
@end
 

@implementation NSMutableFontCollection

+ (void) initialize
{
  if (self == [NSMutableFontCollection class])
    {
      [self _loadAvailableFontCollections];
    }
}

+ (NSMutableFontCollection *) fontCollectionWithDescriptors: (NSArray *)queryDescriptors
{
  NSMutableFontCollection *fc = [[NSMutableFontCollection alloc] init];
  [fc _setQueryAttributes: queryDescriptors];
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
  return [[_availableFontCollections objectForKey: name] mutableCopy]; 
}

+ (NSMutableFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
                                          visibility: (NSFontCollectionVisibility)visibility
{
  return [[_availableFontCollections objectForKey: name] mutableCopy]; 
}

- (NSArray *) queryDescriptors
{
  return [_fontCollectionDictionary objectForKey: @"NSFontDescriptorAttributes"];
}

- (void) setQueryDescriptors: (NSArray *)queryDescriptors
{
  [_fontCollectionDictionary setObject: queryDescriptors
                                forKey: @"NSFontDescriptorAttributes"];
}

- (NSArray *) exclusionDescriptors
{
  return [_fontCollectionDictionary objectForKey: @"NSFontExclusionDescriptorAttributes"];
}

- (void) setExclusionDescriptors: (NSArray *)exclusionDescriptors
{
  [_fontCollectionDictionary setObject: [exclusionDescriptors mutableCopy]
                                forKey: @"NSFontExclusionDescriptorAttributes"];
}

- (void)addQueryForDescriptors: (NSArray *)descriptors
{
  NSMutableArray *arr = [[self queryDescriptors] mutableCopy];
  [arr addObjectsFromArray: descriptors];
  [self setQueryDescriptors: arr];
}

- (void)removeQueryForDescriptors: (NSArray *)descriptors
{
  NSMutableArray *arr = [[self queryDescriptors] mutableCopy];
  [arr removeObjectsInArray: descriptors];
  [self setQueryDescriptors: arr];
}

@end
