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

#import "config.h"
#import <Foundation/NSArchiver.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSString.h>
#import "GSOpenStepNibReader.h"

#import "GNUstepGUI/GSModelLoaderFactory.h"
#import "GNUstepGUI/GSNibLoading.h"

@interface GSNibLoader : GSModelLoader
@end

@implementation GSNibLoader
+ (void) initialize
{
  // should do something...
}

+ (BOOL) canReadData: (NSData *)theData
{
  id plist = nil;
  if (GSOpenStepNibIsTypedStream(theData)) return YES;
  if ([theData length] == 0) return NO;
  /* Preserve XML keyed archive probing without instantiating a plist parser.
   * The keyed unarchiver validates the archive when it is actually loaded. */
  if ([theData length] < 8 || memcmp([theData bytes], "bplist00", 8))
    {
      NSUInteger length = MIN([theData length], (NSUInteger)1024);
      NSString *header = AUTORELEASE([[NSString alloc]
        initWithBytes: [theData bytes] length: length encoding: NSUTF8StringEncoding]);
      return header != nil && [header rangeOfString: @"<plist"].length != 0
        && [header rangeOfString: @"NSKeyedArchiver"].length != 0;
    }
  /* A binary plist is not necessarily a keyed archive. */
  @try
    {
      plist = [NSPropertyListSerialization propertyListWithData: theData
        options: NSPropertyListImmutable format: NULL error: NULL];
    }
  @catch (NSException *exception) { return NO; }
  return [plist isKindOfClass: [NSDictionary class]]
    && [[plist objectForKey: @"$archiver"] isEqual: @"NSKeyedArchiver"]
    && [[plist objectForKey: @"$objects"] isKindOfClass: [NSArray class]]
    && [[plist objectForKey: @"$top"] isKindOfClass: [NSDictionary class]];
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
  BOOL loaded = NO;
  BOOL typedStream = GSOpenStepNibIsTypedStream(data);
  NSKeyedUnarchiver *unarchiver = nil;
  CREATE_AUTORELEASE_POOL(pool);

  NS_DURING
    {
      if (data != nil)
	{
	  if (typedStream)
	    data = GSOpenStepNibKeyedData(data);
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
		      if (typedStream)
		        GSOpenStepNibFinishDecoding(unarchiver);
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
	      [unarchiver finishDecoding];
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
      loaded = NO;
      NSLog(@"Exception occurred while loading model: %@",[localException reason]);
    }
  NS_ENDHANDLER
  RELEASE(unarchiver);

  if (loaded == NO)
    {
      NSLog(@"Failed to load Nib\n");
    }

  RELEASE(pool);
  return loaded;
}

- (NSData *) dataForFile: (NSString *)fileName
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  BOOL isDir = NO;

  NSDebugLog(@"Loading Nib `%@'...\n", fileName);
  if ([mgr fileExistsAtPath: fileName isDirectory: &isDir])
    {
      NSData *data = nil;
      
      // Prefer the current archive when a bundle also has a legacy copy.
      if (isDir == NO)
	{
	  data = [NSData dataWithContentsOfFile: fileName];
	  NSDebugLog(@"Loaded data from file...");
	}
      else
	{
	  NSArray *payloads = [NSArray arrayWithObjects: @"keyedobjects.nib",
	    @"objects.nib", @"data.nib", nil];
	  NSEnumerator *en = [payloads objectEnumerator];
	  NSString *payload;
	  while ((payload = [en nextObject]) != nil)
	    {
	      NSString *path = [fileName stringByAppendingPathComponent: payload];
	      if ([mgr fileExistsAtPath: path])
	        {
	          /* A broken preferred payload is an error, not permission to
	           * instantiate a different, potentially obsolete interface. */
	          data = [NSData dataWithContentsOfFile: path];
	          break;
	        }
	    }
	}
      return data;
    }
  else
    {
      NSLog(@"NIB file specified %@, could not be found.", fileName);
    }
  return nil;
}
@end
