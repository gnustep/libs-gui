/* <title>GSXibLoader</title>

   <abstract>Xib (Cocoa XML) model loader</abstract>

   Copyright (C) 2010, 2011 Free Software Foundation, Inc.

   Written by: Fred Kiefer <FredKiefer@gmx.de>
   Created: March 2010

   This file is part of the GNUstep Base Library.

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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02110 USA.
*/

#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSApplication.h"
#import "AppKit/NSMenu.h"
#import "AppKit/NSNib.h"

#import "GNUstepGUI/GSModelLoaderFactory.h"
#import "GNUstepGUI/GSNibLoading.h"
#import "GNUstepGUI/GSXibLoading.h"
#import "GNUstepGUI/GSXibKeyedUnarchiver.h"

#import <float.h>

@interface NSApplication (StorybardCompatibility)
- (void) _setMainMenu: (NSMenu*)aMenu;
@end

@interface NSMenu (StoryboardCompatibility)
- (BOOL) _isMainMenu;
@end

@implementation NSMenu (StoryboardCompatibility)

- (BOOL) _isMainMenu
{
  if (_name)
    return [_name isEqualToString:@"_NSMainMenu"];
  return NO;
}

@end

@interface GSStoryboardLoader: GSModelLoader
{
}
@end

@implementation GSStoryboardLoader

+ (BOOL) canReadData: (NSData *)theData
{
  char *header = calloc(1024, sizeof(char));

  if (header != NULL)
    {
      [theData getBytes: header
                 length: 1024];

      NSString *hdr = [[NSString alloc] initWithBytes: header
                                               length: 1024
                                             encoding: NSUTF8StringEncoding];
      AUTORELEASE(hdr);
      if ([hdr containsString: @"Cocoa.Storyboard.XIB"])
        {
          free(header);
          return YES;
        }

      free(header);
    }

  return NO;
}

+ (NSString*) type
{
  return @"storyboard";
}

+ (float) priority
{
  return 5.0;
}

- (void) awake: (NSArray *)rootObjects
   withContext: (NSDictionary *)context
{
  NSMutableArray *topLevelObjects = [context objectForKey: NSNibTopLevelObjects];
  id owner = [context objectForKey: NSNibOwner];
  NSEnumerator *en;
  id obj;
  NSUInteger index = 0;

  if ([rootObjects count] == 0)
    {
      NSWarnMLog(@"No root objects in XIB!");
      return;
    }

  NSDebugLLog(@"Storyboard", @"First object %@", [rootObjects objectAtIndex: 0]);
  NSDebugLLog(@"Storyboard", @"Second object %@", [rootObjects objectAtIndex: 1]);
  NSDebugLLog(@"Storyboard", @"Third object %@", [rootObjects objectAtIndex: 2]);
  // Use the owner as first root object
  [(NSCustomObject*)[rootObjects objectAtIndex: 0] setRealObject: owner];

  en = [rootObjects objectEnumerator];
  while ((obj = [en nextObject]) != nil)
    {
      index++;

      if ([obj respondsToSelector: @selector(nibInstantiate)])
        {
          obj = [obj nibInstantiate];
        }

      // IGNORE file's owner, first responder and NSApplication instances...
      if ((obj != nil) && (index > 3))
        {
          [topLevelObjects addObject: obj];
          // All top level objects must be released by the caller to avoid
          // leaking, unless they are going to be released by other nib
          // objects on behalf of the owner.
          RETAIN(obj);
        }

      if (([obj isKindOfClass: [NSMenu class]]) &&
          ([obj _isMainMenu]))
        {
          // add the menu...
          [NSApp _setMainMenu: obj];
        }
    }
}

- (void) awake: (NSArray *)rootObjects
   inContainer: (id)objects
   withContext: (NSDictionary *)context
{
  [self awake: rootObjects withContext: context];

  // Load connections and awaken objects
  if ([objects respondsToSelector: @selector(nibInstantiate)])
    {
      [objects nibInstantiate];
    }
}

- (BOOL) loadModelData: (NSData *)data
     externalNameTable: (NSDictionary *)context
              withZone: (NSZone *)zone
{
  BOOL loaded = NO;

  NS_DURING
    {
      if (data != nil)
	{
          NSKeyedUnarchiver *unarchiver = [GSXibKeyedUnarchiver unarchiverForReadingWithData: data];

	  if (unarchiver != nil)
	    {
	      NSArray *rootObjects;
              IBObjectContainer *objects;
	      IBScenesContainer *scenes;
	      
	      NSDebugLLog(@"Storyboard", @"Invoking unarchiver");
	      [unarchiver setObjectZone: zone];
              rootObjects = [unarchiver decodeObjectForKey: @"IBDocument.RootObjects"];
              objects = [unarchiver decodeObjectForKey: @"IBDocument.Objects"];
	      scenes = [unarchiver decodeObjectForkey: @"IBDocument.Scenes"];
	      
	      NSLog(@"root objects = %@", rootObjects);
	      NSLog(@"objects = %@", objects);
	      NSLog(@"scenes = %@", scenes)

	      /*
	      [self awake: rootObjects
		    inContainer: objects
		    withContext: context];
	      */
              loaded = YES;
	    }
	  else
	    {
              NSLog(@"Could not instantiate Xib unarchiver/Unable to parse Storyboard.");
	    }
	}
      else
	{
	  NSLog(@"Data passed to Storyboard loading method is nil.");
	}
    }
  NS_HANDLER
    {
      NSLog(@"Exception occurred while loading model: %@",[localException reason]);
    }
  NS_ENDHANDLER

  if (loaded == NO)
    {
      NSLog(@"Failed to load Storyboard\n");
    }

  return loaded;
}

- (NSData*) dataForFile: (NSString*)fileName
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  BOOL isDir = NO;

  NSDebugLLog(@"Storyboard", @"Loading Storyboard `%@'...\n", fileName);
  if ([mgr fileExistsAtPath: fileName isDirectory: &isDir])
    {
      if (isDir == NO)
	{
	  return [NSData dataWithContentsOfFile: fileName];
        }
      else
        {
          NSLog(@"Storyboard file specified %@, is directory.", fileName);
        }
    }
  else
    {
      NSLog(@"Storyboard file specified %@, could not be found.", fileName);
    }

  return nil;
}

@end
