/** <title>NSDataLink</title>

   Copyright (C) 1996, 2005 Free Software Foundation, Inc.

   Author: Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2005
   Author: Scott Christley <scottc@net-community.com>
   Date: 1996

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

#include "config.h"

#import <Foundation/NSFileManager.h>
#import <Foundation/NSArchiver.h>
#import <Foundation/NSData.h>
#import <Foundation/NSKeyedArchiver.h>

#import "AppKit/NSDataLink.h"
#import "AppKit/NSDataLinkManager.h"
#import "AppKit/NSPasteboard.h"
#import "AppKit/NSSavePanel.h"
#import "AppKit/NSSelection.h"

@implementation NSDataLink

+ (void)initialize
{
  if (self == [NSDataLink class])
    {
      // Initial version
      [self setVersion: 0];
    }
}

- (id)initLinkedToFile:(NSString * )filename
{
  if ((self = [super init]))
    {
      _sourceFilename = [filename copy];
      _disposition = NSLinkInSource;
      _lastUpdateTime = [[NSFileManager defaultManager] attributesOfItemAtPath:filename error:nil][NSFileModificationDate];
      _flags.broken = NO;
    }
  return self;
}

- (id)initLinkedToSourceSelection:(NSSelection *)selection
                         managedBy:(NSDataLinkManager *)linkManager
                   supportingTypes:(NSArray *)newTypes
{
  if ((self = [super init]))
    {
      _sourceSelection = [selection retain];
      _sourceManager = [linkManager retain];
      _types = [newTypes retain];
      _disposition = NSLinkInSource;
      _flags.broken = NO;
    }
  return self;
}

- (id)initWithContentsOfFile:(NSString *)filename
{
  NSData *data = [NSData dataWithContentsOfFile:filename];
  if (data)
    {
      return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
  return nil;
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard
{
  NSData *data = [pasteboard dataForType:NSDataLinkPboardType];
  if (data)
    {
      return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
  return nil;
}

- (BOOL)saveLinkIn:(NSString *)directoryName
{
  NSString *filePath = [directoryName stringByAppendingPathComponent:
                         [NSString stringWithFormat:@"Link_%d.link", _linkNumber]];
  return [self writeToFile:filePath];
}

- (BOOL)writeToFile:(NSString *)filename
{
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
  return [data writeToFile:filename atomically:YES];
}

- (void)writeToPasteboard:(NSPasteboard *)pasteboard
{
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
  [pasteboard declareTypes:@[NSDataLinkPboardType] owner:nil];
  [pasteboard setData:data forType:NSDataLinkPboardType];
}

- (NSDataLinkDisposition)disposition
{
  return _disposition;
}

- (NSDataLinkNumber)linkNumber
{
  return _linkNumber;
}

- (NSDataLinkManager *)manager
{
  return (_disposition == NSLinkInSource) ? _sourceManager : _destinationManager;
}

- (NSDate *)lastUpdateTime
{
  return _lastUpdateTime;
}

- (BOOL)openSource
{
  return NO; /* Stub */
}

- (NSString *)sourceApplicationName
{
  return _sourceApplicationName;
}

- (NSString *)sourceFilename
{
  return _sourceFilename;
}

- (NSSelection *)sourceSelection
{
  return _sourceSelection;
}

- (NSArray *)types
{
  return _types;
}

- (NSString *)destinationApplicationName
{
  return _destinationApplicationName;
}

- (NSString *)destinationFilename
{
  return _destinationFilename;
}

- (NSSelection *)destinationSelection
{
  return _destinationSelection;
}

//
// Changing the Link
//
- (BOOL)break
{
  id srcDelegate = [_sourceManager delegate];
  id dstDelegate = [_destinationManager delegate];

  // The spec is quite vague here.  I don't know under what
  // circumstances a link cannot be broken, so this method
  // always returns YES.

  _disposition = NSLinkBroken;

  if ([srcDelegate respondsToSelector: @selector(dataLinkManager:didBreakLink:)])
    {
      [srcDelegate dataLinkManager: _sourceManager didBreakLink: self];
    }

  if ([dstDelegate respondsToSelector: @selector(dataLinkManager:didBreakLink:)])
    {
      [dstDelegate dataLinkManager: _destinationManager didBreakLink: self];
    }

  return (_flags.broken = YES);
}

- (void)noteSourceEdited
{
  _flags.isDirty = YES;

  if (_updateMode != NSUpdateNever)
    {
      [_sourceManager noteDocumentEdited];
    }
}

- (void)setUpdateMode:(NSDataLinkUpdateMode)mode
{
  _updateMode = mode;
}

- (BOOL)updateDestination
{
  if (_flags.broken || _updateMode == NSUpdateNever)
    return NO;
  _flags.isDirty = NO;
  return YES;
}

- (NSDataLinkUpdateMode)updateMode
{
  return _updateMode;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL flag = NO;

  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeInt: _linkNumber forKey: @"GSLinkNumber"];
      [aCoder encodeInt: _disposition forKey: @"GSUpdateMode"];
      [aCoder encodeInt: _updateMode forKey: @"GSLastUpdateMode"];

      [aCoder encodeObject: _lastUpdateTime forKey: @"GSLastUpdateTime"];

      [aCoder encodeObject: _sourceApplicationName forKey: @"GSSourceApplicationName"];
      [aCoder encodeObject: _sourceFilename forKey: @"GSSourceFilename"];
      [aCoder encodeObject: _sourceSelection forKey: @"GSSourceSelection"];
      [aCoder encodeObject: _sourceManager forKey: @"GSSourceManager"];

      [aCoder encodeObject: _destinationApplicationName forKey: @"GSDestinationApplicationName"];
      [aCoder encodeObject: _destinationFilename forKey: @"GSDestinationFilename"];
      [aCoder encodeObject: _destinationSelection forKey: @"GSDestinationSelection"];
      [aCoder encodeObject: _destinationManager forKey: @"GSDestinationManager"];

      [aCoder encodeObject: _types forKey: @"GSTypes"];

      // flags...
      flag = _flags.appVerifies;
      [aCoder encodeBool: flag forKey: @"GSAppVerifies"];
      flag = _flags.canUpdateContinuously;
      [aCoder encodeBool: flag forKey: @"GSCanUpdateContinuously"];
      flag = _flags.isDirty;
      [aCoder encodeBool: flag forKey: @"GSIsDirty"];
      flag = _flags.willOpenSource;
      [aCoder encodeBool: flag forKey: @"GSWillOpenSource"];
      flag = _flags.willUpdate;
      [aCoder encodeBool: flag forKey: @"GSWillUpdate"];
    }
  else
    {
      [aCoder encodeValueOfObjCType: @encode(int) at: &_linkNumber];
      [aCoder encodeValueOfObjCType: @encode(int) at: &_disposition];
      [aCoder encodeValueOfObjCType: @encode(int) at: &_updateMode];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_lastUpdateTime];

      [aCoder encodeValueOfObjCType: @encode(id)  at: &_sourceApplicationName];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_sourceFilename];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_sourceSelection];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_sourceManager];

      [aCoder encodeValueOfObjCType: @encode(id)  at: &_destinationApplicationName];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_destinationFilename];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_destinationSelection];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_destinationManager];

      [aCoder encodeValueOfObjCType: @encode(id)  at: &_types];

      // flags...
      flag = _flags.appVerifies;
      [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
      flag = _flags.canUpdateContinuously;
      [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
      flag = _flags.isDirty;
      [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
      flag = _flags.willOpenSource;
      [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
      flag = _flags.willUpdate;
      [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
    }
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      id obj;

      _linkNumber = [aCoder decodeIntForKey: @"GSLinkNumber"];
      _disposition = [aCoder decodeIntForKey: @"GSDisposition"];
      _updateMode = [aCoder decodeIntForKey: @"GSUpdateMode"];

      obj = [aCoder decodeObjectForKey: @"GSSourceManager"];
      ASSIGN(_sourceManager,obj);
      obj = [aCoder decodeObjectForKey: @"GSDestinationManager"];
      ASSIGN(_destinationManager,obj);
      obj = [aCoder decodeObjectForKey: @"GSLastUpdateTime"];
      ASSIGN(_lastUpdateTime, obj);
      obj = [aCoder decodeObjectForKey: @"GSSourceApplicationName"];
      ASSIGN(_sourceApplicationName,obj);
      obj = [aCoder decodeObjectForKey: @"GSSourceFilename"];
      ASSIGN(_sourceFilename,obj);
      obj = [aCoder decodeObjectForKey: @"GSSourceSelection"];
      ASSIGN(_sourceSelection,obj);
      obj = [aCoder decodeObjectForKey: @"GSSourceManager"];
      ASSIGN(_sourceManager,obj);
      obj = [aCoder decodeObjectForKey: @"GSDestinationApplicationName"];
      ASSIGN(_destinationApplicationName,obj);
      obj = [aCoder decodeObjectForKey: @"GSDestinationFilename"];
      ASSIGN(_destinationFilename,obj);
      obj = [aCoder decodeObjectForKey: @"GSDestinationSelection"];
      ASSIGN(_destinationSelection,obj);
      obj = [aCoder decodeObjectForKey: @"GSDestinationManager"];
      ASSIGN(_destinationManager,obj);
      obj = [aCoder decodeObjectForKey: @"GSTypes"];
      ASSIGN(_types,obj);

      // flags...
      _flags.appVerifies = [aCoder decodeBoolForKey: @"GSAppVerifies"];
      _flags.canUpdateContinuously = [aCoder decodeBoolForKey: @"GSCanUpdateContinuously"];
      _flags.isDirty = [aCoder decodeBoolForKey: @"GSIsDirty"];
      _flags.willOpenSource = [aCoder decodeBoolForKey: @"GSWillOpenSource"];
      _flags.willUpdate = [aCoder decodeBoolForKey: @"GSWillUpdate"];
    }
  else
    {
      int version = [aCoder versionForClassName: @"NSDataLink"];
      if (version == 0)
	{
	  BOOL flag = NO;

	  [aCoder decodeValueOfObjCType: @encode(int) at: &_linkNumber];
	  [aCoder decodeValueOfObjCType: @encode(int) at: &_disposition];
	  [aCoder decodeValueOfObjCType: @encode(int) at: &_updateMode];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_sourceManager];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_destinationManager];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_lastUpdateTime];

	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_sourceApplicationName];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_sourceFilename];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_sourceSelection];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_sourceManager];

	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_destinationApplicationName];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_destinationFilename];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_destinationSelection];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_destinationManager];

	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_types];

	  // flags...
	  [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
	  _flags.appVerifies = flag;
	  [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
	  _flags.canUpdateContinuously = flag;
	  [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
	  _flags.isDirty = flag;
	  [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
	  _flags.willOpenSource = flag;
	  [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
	  _flags.willUpdate = flag;
	}
      else
	return nil;
    }

  return self;
}

@end
