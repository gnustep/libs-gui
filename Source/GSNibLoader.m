/** <title>GSNibLoader</title>

   <abstract>Nib (Cocoa XML) model loader</abstract>

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2005
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include "GNUstepGUI/GSModelLoaderFactory.h"
#include "GNUstepGUI/GSNibLoading.h"

@interface GSNibLoader : GSModelLoader
@end

@implementation GSNibLoader
+ (void) initialize
{
  // should do something...
}

+ (NSString *)type
{
  return @"nib";
}

+ (float) priority
{
  return 3.0;
}

- (BOOL) loadModelData: (NSData *)data
     externalNameTable: (NSDictionary *)context
              withZone: (NSZone *)zone;
{
  BOOL		loaded = NO;
  NSUnarchiver *unarchiver = nil;

  NS_DURING
    {
      if (data != nil)
	{
	  unarchiver = [[NSKeyedUnarchiver alloc] 
			 initForReadingWithData: data];
	  if (unarchiver != nil)
	    {
	      id obj;
	      
	      NSDebugLog(@"Invoking unarchiver");
	      [unarchiver setObjectZone: zone];
	      obj = [unarchiver decodeObjectForKey: @"IB.objectdata"];
	      if (obj != nil)
		{
		  if ([obj isKindOfClass: [NSIBObjectData class]])
		    {
		      NSDebugLog(@"Calling awakeWithContext");
		      [obj awakeWithContext: context];
		      loaded = YES;
		    }
		  else
		    {
		      NSLog(@"Nib without container object!");
		    }
		}
	      else
		{
		  NSLog(@"IB.objectdata not found when loading nib.");
		}
	      RELEASE(unarchiver);
	    }
	  else
	    {
	      NSLog(@"Could not instantiate unarchiver.");
	    }
	}
      else
	{
	  NSLog(@"Data passed to nib loading method is nil.");
	}
    }
  NS_HANDLER
    {
      NSLog(@"Exception occured while loading model: %@",[localException reason]);
      // TEST_RELEASE(unarchiver);
    }
  NS_ENDHANDLER

  if (loaded == NO)
    {
      NSLog(@"Failed to load Nib\n");
    }

  return loaded;
}

- (BOOL) loadModelFile: (NSString *)fileName
     externalNameTable: (NSDictionary *)context
              withZone: (NSZone *)zone;
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  BOOL          isDir = NO;
  BOOL          loaded = NO;

  NSDebugLog(@"Loading Nib `%@'...\n", fileName);

  if ([mgr fileExistsAtPath: fileName isDirectory: &isDir])
    {
      NSData	*data = nil;
      
      // if the data is in a directory, then load from keyedobjects.nib in the directory
      if (isDir == NO)
	{
	  data = [NSData dataWithContentsOfFile: fileName];
	  NSDebugLog(@"Loaded data from file...");
	}
      else
	{
	  NSString *newFileName = [fileName stringByAppendingPathComponent: @"keyedobjects.nib"];
	  data = [NSData dataWithContentsOfFile: newFileName];
	  NSDebugLog(@"Loaded data from %@...",newFileName);
	}

      loaded = [self loadModelData: data 
		     externalNameTable: context
		     withZone: zone];

      // report a problem if there is one.
      if (loaded == NO)
	{
	  NSLog(@"Could not load Nib file: %@",fileName);
	}
    }
  else
    {
      NSLog(@"Nib file specified %@, could not be found.",fileName);
    }
      
  return loaded;
}
@end
