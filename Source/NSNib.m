/** <title>NSNib</title>
   
   <abstract>
   This class serves as a container for a nib file.  It's possible 
   to load a nib file from a URL or from a bundle.   Using this 
   class the nib file can now be "preloaded" and instantiated 
   multiple times when/if needed.  Also, since it's possible to 
   initialize this class using a NSURL it's possible to load 
   nib files from remote locations. 
   <b/>
   This class uses: NSNibOwner and NSNibTopLevelObjects to allow
   the caller to specify the owner of the nib during instantiation
   and receive an array containing the top level objects of the nib
   file.
   </abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2004
   
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

#include <AppKit/NSNib.h>
#include <AppKit/NSNibLoading.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSURL.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>

#include "GNUstepGUI/GSNibTemplates.h"
#include "GNUstepGUI/IMLoading.h"

@implementation NSNib

+ (NSString *) _nibFilename: (NSString *)fileName
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  BOOL           isDir = NO;
  NSString      *newFileName = nil;

  // assign the filename...
  ASSIGN(newFileName, fileName);

  // detect if it's a directory or not...
  if([mgr fileExistsAtPath: fileName isDirectory: &isDir])
    {
      // if the data is in a directory, then load from objects.gorm in the directory
      if(isDir == YES)
	{
	  newFileName = [fileName stringByAppendingPathComponent: @"objects.gorm"];
	}
    }
  
  return newFileName;
}

// private method to read in the data...
- (void) _readNibData: (NSString *)fileName
{
  NSString      *ext = [fileName pathExtension];

  if ([ext isEqual: @"nib"])
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];
      NSString		*base = [fileName stringByDeletingPathExtension];

      /* We can't read nibs, look for an equivalent gorm or gmodel file */
      fileName = [base stringByAppendingPathExtension: @"gorm"];
      if ([mgr isReadableFileAtPath: fileName])
	{
	  ext = @"gorm";
	}
    }

  NSDebugLog(@"Loading Nib `%@'...\n", fileName);
  NS_DURING
    {
      NSString *newFileName = [NSNib _nibFilename: fileName];
      _nibData = [NSData dataWithContentsOfFile: newFileName];
      NSDebugLog(@"Loaded data from %@...",newFileName);
    }
  NS_HANDLER
    {
      NSLog(@"Exception occured while loading model: %@",[localException reason]);
    }
  NS_ENDHANDLER
}

// handle the notification...
- (void) _handleNotification: (NSNotification *)notification
{
  id obj = [notification object];
  [_topLevelItems addObject: obj];  
}

// subscribe to the notification...
- (void) _addObserver
{
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  // add myself as an observer and initialize the items array.
  [nc addObserver: self
      selector: @selector(_handleNotification:)
      name: @"__GSInternalNibItemAddedNotification"
      object: nil];
}

/**
 * Load the NSNib object from the specified URL.  This location can be
 * any type of resource capable of being pointed to by the NSURL object.
 * A file in the local file system or a file on an ftp site.
 */
- (id)initWithContentsOfURL: (NSURL *)nibFileURL
{
  if((self = [super init]) != nil)
    {
      // load the nib data into memory...
      _nibData = [NSData dataWithContentsOfURL: nibFileURL];
      [self _addObserver];
    }
  return self;
}

/**
 * Load the nib indicated by <code>nibNamed</code>.  If the <code>bundle</code>
 * argument is <code>nil</code>, then the main bundle is used to resolve the path,
 * otherwise the bundle which is supplied will be used.
 */
- (id)initWithNibNamed: (NSString *)nibNamed bundle: (NSBundle *)bundle
{
  if((self = [super init]) != nil)
    {
      NSString *bundlePath = nil;
      NSString *fileName = nil;

      if(bundle == nil)
	{
	  bundle = [NSBundle mainBundle];
	}

      // initialize the bundle...
      bundlePath = [bundle pathForNibResource: nibNamed];
      fileName = [bundlePath stringByAppendingPathComponent: nibNamed];

      // load the nib data into memory...
      [self _readNibData: fileName];
      [self _addObserver];
    }
  return self;
}

/**
 * This is a GNUstep specific method.  This method is used when the caller wants the
 * objects instantiated in the nib to be stored in the given <code>zone</code>.
 */
- (BOOL)instantiateNibWithExternalNameTable: (NSDictionary *)externalNameTable
				   withZone: (NSZone *)zone
{
  BOOL		 loaded = NO;
  NSUnarchiver	*unarchiver = nil;

  NS_DURING
  {
    if (_nibData != nil)
      {
	unarchiver = [[NSUnarchiver alloc] initForReadingWithData: _nibData];
	if (unarchiver != nil)
	  {
 	    id obj;

	    NSDebugLog(@"Invoking unarchiver");
	    [unarchiver setObjectZone: zone];
	    obj = [unarchiver decodeObject];
	    if (obj != nil)
	      {
		if ([obj isKindOfClass: [GSNibContainer class]])
		  {
		    NSDebugLog(@"Calling awakeWithContext");
		    [obj awakeWithContext: externalNameTable
			 topLevelItems: _topLevelItems];
		    loaded = YES;
	 	  }
		else
		  {
		    NSLog(@"Nib '%@' without container object!");
		  }
	      }
	    RELEASE(unarchiver);
	  }
      }
  }
  NS_HANDLER
  {
    NSLog(@"Exception occured while loading model: %@",[localException reason]);
    TEST_RELEASE(unarchiver);
  }
  NS_ENDHANDLER
  
  if (loaded == NO)
  {
    NSLog(@"Failed to load Nib\n");
  }

  return loaded;
}

/**
 * This method instantiates the nib file.  The externalNameTable dictionary
 * accepts the NSNibOwner and NSNibTopLevelObjects entries described earlier.
 * It is recommended, for subclasses whose purpose is to change the behaviour 
 * of nib loading, to override this method.
 */
- (BOOL)instantiateNibWithExternalNameTable: (NSDictionary *)externalNameTable
{
  return [self instantiateNibWithExternalNameTable: externalNameTable
	       withZone: NSDefaultMallocZone()];
}

/**
 * This method instantiates the nib file.  It utilizes the 
 * instantiateNibWithExternalNameTable: method to, in a convenient way, 
 * allow the user to specify both keys accepted by the
 * nib loading process.
 */
- (BOOL)instantiateNibWithOwner: (id)owner topLevelObjects: (NSArray **)topLevelObjects
{
  NSMutableDictionary *externalNameTable = [NSMutableDictionary dictionary];

  // add the necessary things to the table...
  [externalNameTable setObject: owner forKey: @"NSNibOwner"];

  if(topLevelObjects != 0)
    {
      *topLevelObjects = [NSMutableArray array];
      [externalNameTable setObject: *topLevelObjects forKey: @"NSNibTopLevelObjects"];
    }

  return [self instantiateNibWithExternalNameTable: externalNameTable]; 
}

- (id) initWithCoder: (NSCoder *)coder
{
  if((self = [super init]) != nil)
    {
      [coder decodeValueOfObjCType: @encode(id)
	     at: &_nibData];
    }
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  [coder encodeValueOfObjCType: @encode(id)
	 at: &_nibData];
}

- (void) dealloc
{
  RELEASE(_nibData);
  RELEASE(_topLevelItems);
  [super dealloc];
}

@end
