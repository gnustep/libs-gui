/** <title>NSMovie</title>

   <abstract>Encapsulate a Quicktime movie</abstract>

   Copyright <copy>(C) 2003 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2003

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: March 2022

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

#import <Foundation/NSArray.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSURL.h>

#import "AppKit/NSMovie.h"
#import "AppKit/NSPasteboard.h"

#import "GNUstepGUI/GSVideoSource.h"
#import "GNUstepGUI/GSVideoSink.h"

#import "GSFastEnumeration.h"

/* Class variables and functions for class methods */
static NSArray *__videoSourcePlugIns = nil;
static NSArray *__videoSinkPlugIns = nil;

static inline void _loadNSMoviePlugIns (void)
{
  NSArray       *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                             NSAllDomainsMask, YES);
  NSMutableArray *all = [NSMutableArray array];
  NSMutableArray *sourcePlugins = [NSMutableArray array];
  NSMutableArray *sinkPlugins = [NSMutableArray array];
  
  // Collect paths...
  FOR_IN(NSString*, path, paths)
    {
      NSBundle *bundle = [NSBundle bundleWithPath: path];
      paths = [bundle pathsForResourcesOfType: @"nsmovie"
                                  inDirectory: @"Bundles"];
      [all addObjectsFromArray: paths];
    }
  END_FOR_IN(paths);

  // Check all paths for bundles conforming to the protocol...
  FOR_IN(NSString*, path, all)
    {
      NSBundle *bundle = [NSBundle bundleWithPath: path];
      Class plugInClass = [bundle principalClass];
      if ([plugInClass conformsToProtocol: @protocol(GSVideoSource)])
        {
          [sourcePlugins addObject:plugInClass];
        }
      else if ([plugInClass conformsToProtocol: @protocol(GSVideoSink)])
        {
          [sinkPlugins addObject:plugInClass];
        }
      else
        {
          NSLog (@"Bundle %@ does not conform to GSVideoSource or GSVideoSink",
                 path);
        }
    }
  END_FOR_IN(all);
  
  __videoSourcePlugIns = [[NSArray alloc] initWithArray: sourcePlugins];
  __videoSinkPlugIns = [[NSArray alloc] initWithArray: sinkPlugins];
}

@implementation NSMovie

+ (void) initialize
{
  if (self == [NSMovie class])
    {
      [self setVersion: 2];
      _loadNSMoviePlugIns();
    }
}

+ (NSArray *) movieUnfilteredFileTypes
{
  NSMutableArray *array = [NSMutableArray arrayWithCapacity: 10];

  FOR_IN(Class, sourceClass, __videoSourcePlugIns)
    {
      [array addObjectsFromArray: [sourceClass movieUnfilteredFileTypes]];
    }
  END_FOR_IN(__videoSourcePlugIns);
  
  return array;
}

+ (NSArray *) movieUnfilteredPasteboardTypes
{
  return [NSArray arrayWithObjects: @"NSGeneralPboardType", nil];
}

+ (BOOL) canInitWithPasteboard: (NSPasteboard*)pasteboard
{
  NSArray *pbTypes = [pasteboard types];
  NSArray *myTypes = [self movieUnfilteredPasteboardTypes];

  return ([pbTypes firstObjectCommonWithArray: myTypes] != nil);
}

- (id) initWithData: (NSData *)movieData
{
  self = [super init];
  if (self != nil)
    {
      if (movieData != nil)
        {
          ASSIGN(_movieData, movieData);

          // Choose video sink...
          FOR_IN(Class, pluginClass, __videoSinkPlugIns)
            {
              if ([pluginClass canInitWithData: movieData])
                {
                  _sink = [[pluginClass alloc] init];
                }
            }
          END_FOR_IN(__videoSinkPlugIns);

          // Choose video source...
          FOR_IN(Class, pluginClass, __videoSourcePlugIns)
            {
              if ([pluginClass canInitWithData: movieData])
                {
                  _source = [[pluginClass alloc] initWithData: movieData];
                }
            }
          END_FOR_IN(__videoSourcePlugIns);
        }
      else
        {
          RELEASE(self);
        }
    }

  return self;
}

- (id) initWithMovie: (void*)movie
{
  self = [super init];
  if (self != nil)
    {
      _movie = movie;
    }
  return self;
}

- (id) initWithURL: (NSURL*)url byReference: (BOOL)byRef
{
  NSData* data = [url resourceDataUsingCache: YES];

  self = [self initWithData: data];
  if (byRef)
    {
      ASSIGN(_url, url);
    }

  return self;
}

- (id) initWithPasteboard: (NSPasteboard*)pasteboard
{
  NSString *type;
  NSData* data;

  type = [pasteboard availableTypeFromArray: 
			 [object_getClass(self) movieUnfilteredPasteboardTypes]];
  if (type == nil)
    {
      // NSArray *array = [pasteboard propertyListForType: NSFilenamesPboardType];
      // FIXME
      data = nil;
    }
  else 
    {
      data = [pasteboard dataForType: type];
    }

  if (data == nil)
    {
      RELEASE(self);
      return nil;
    }

  self = [self initWithData: data];

  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_url);
  TEST_RELEASE(_movieData);
  _movie = nil;
    
  [super dealloc];
}

- (void*) QTMovie
{
  return (void*)[_movieData bytes];
}

- (NSURL*) URL
{
  return _url;
}

// NSCopying protocoll
- (id) copyWithZone: (NSZone *)zone
{
  NSMovie *new = (NSMovie*)NSCopyObject (self, 0, zone);

  new->_movie = _movie;
  new->_movieData =  [_movieData copyWithZone: zone];
  new->_url = [_url copyWithZone: zone];

  return new;
}

// NSCoding protocoll
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      // FIXME
    }
  else
    {
      [aCoder encodeObject: _movieData];
      [aCoder encodeObject: _url];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  if ([aDecoder allowsKeyedCoding])
    {
      // FIXME
    }
  else
    {
      ASSIGN (_movieData, [aDecoder decodeObject]);
      ASSIGN (_url, [aDecoder decodeObject]);
    }
  return self;
}

@end
