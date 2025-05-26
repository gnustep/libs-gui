/** <title>NSMovie</title>

   <abstract>Encapsulate a Quicktime movie</abstract>

   Copyright <copy>(C) 2003 Free Software Foundation, Inc.</copy>

   Author: Gregory John Casamento <greg.casamento@gmail.com>
   Date: May 2025
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: March 2003

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
#import <Foundation/NSCoder.h>
#import <Foundation/NSData.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSUUID.h>

#import "AppKit/NSMovie.h"
#import "AppKit/NSPasteboard.h"

NSString *_writeDataToTempFile(NSData *data)
{
  NSString *tempDirectory = NSTemporaryDirectory();
  NSString *filename = [NSString stringWithFormat: @"tmpfile-%@.dat", [[NSUUID UUID] UUIDString]];
  NSString *filepath = [tempDirectory stringByAppendingPathComponent: filename];
  NSError *error = nil;

  BOOL success = [data writeToFile: filepath options: NSDataWritingAtomic error: &error];
  if (success)
    {
      return nil;
    }
  
  return filepath;
}

@implementation NSMovie

+ (NSArray*) movieUnfilteredFileTypes
{
  return [NSArray arrayWithObjects: @"mp4", @"mov", @"avi", @"flv", @"mkv", @"webm", nil ];
}

+ (NSArray*) movieUnfilteredPasteboardTypes
{
  return [self movieUnfilteredFileTypes];
}

+ (BOOL) canInitWithPasteboard: (NSPasteboard*)pasteboard
{
  NSArray *pbTypes = [pasteboard types];
  NSArray *myTypes = [self movieUnfilteredPasteboardTypes];

  return ([pbTypes firstObjectCommonWithArray: myTypes] != nil);
}

- (instancetype) initWithData: (NSData *)movie
{
  if (movie == nil)
    {
      RELEASE(self);
      return nil;
    }

  self = [super init];
  if (self != nil)
    {
      NSString *filepath = _writeDataToTempFile(_movie);

      _url = [NSURL fileURLWithPath: filepath];
      _tmp = YES;
      ASSIGN(_movie, movie);
    }
  
  return self;
}

- (instancetype) initWithMovie: (void*)movie
{
  return [self initWithData: movie];
}

- (instancetype) initWithURL: (NSURL*)url byReference: (BOOL)byRef
{
  self = [super init];
  if (self != nil)
    {
      ASSIGN(_url, url);
    }
  
  return self;
}

- (instancetype) initWithPasteboard: (NSPasteboard*)pasteboard
{
  NSString *type;
  NSData* data;

  type =
    [pasteboard availableTypeFromArray: 
		  [object_getClass(self) movieUnfilteredPasteboardTypes]];
  if (type == nil)
    {
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
  _tmp = NO;
  [[NSFileManager defaultManager] removeFileAtPath: [_url path] handler: nil];
  TEST_RELEASE(_url);
  TEST_RELEASE(_movie);
  
  [super dealloc];
}

- (void*) QTMovie
{
  return (void*)[_movie bytes];
}

- (NSURL*) URL
{
  return _url;
}

// NSCopying protocoll
- (id) copyWithZone: (NSZone *)zone
{
  NSMovie *new = (NSMovie*)NSCopyObject (self, 0, zone);

  new->_movie = [_movie copyWithZone: zone];
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
      [aCoder encodeObject: _movie];
      [aCoder encodeObject: _url];
    }
}

- (instancetype) initWithCoder: (NSCoder*)aDecoder
{
  if ([aDecoder allowsKeyedCoding])
    {
      // FIXME
    }
  else
    {
      ASSIGN (_movie, [aDecoder decodeObject]);
      ASSIGN (_url, [aDecoder decodeObject]);
    }
  return self;
}

@end
