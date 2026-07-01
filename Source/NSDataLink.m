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
#import <Foundation/NSArray.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSArchiver.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import "AppKit/NSDataLink.h"
#import "AppKit/NSDataLinkManager.h"
#import "AppKit/NSPasteboard.h"
#import "AppKit/NSSavePanel.h"
#import "AppKit/NSSelection.h"

@implementation NSDataLink

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSDataLink class])
    {
      // Initial version
      [self setVersion: 0];
    }
}

- (id)init
{
  if ((self = [super init]) != nil)
    {
      _linkNumber = 0;
      _disposition = NSLinkInDestination;
      _updateMode = NSUpdateContinuously;
      _lastUpdateTime = nil;
      _sourceApplicationName = nil;
      _sourceFilename = nil;
      _sourceSelection = nil;
      _sourceManager = nil;
      _destinationApplicationName = nil;
      _destinationFilename = nil;
      _destinationSelection = nil;
      _destinationManager = nil;
      _types = nil;
      _flags.appVerifies = NO;
      _flags.broken = NO;
      _flags.canUpdateContinuously = YES;
      _flags.isDirty = NO;
      _flags.willOpenSource = NO;
      _flags.willUpdate = NO;
      _flags.isMarker = NO;
    }
  return self;
}

- (void)dealloc
{
  RELEASE(_lastUpdateTime);
  RELEASE(_sourceApplicationName);
  RELEASE(_sourceFilename);
  RELEASE(_sourceSelection);
  RELEASE(_destinationApplicationName);
  RELEASE(_destinationFilename);
  RELEASE(_destinationSelection);
  RELEASE(_types);
  
  [super dealloc];
}

- (id)initLinkedToFile:(NSString *)filename
{
  if ((self = [self init]) != nil)
    {
      NSData *data = [NSData dataWithBytes: [filename cString] length: [filename cStringLength]];
      NSSelection *selection = [NSSelection selectionWithDescriptionData: data];
      ASSIGN(_sourceSelection, selection);
      ASSIGN(_sourceFilename, filename);
    }
  return self;
}

- (id)initLinkedToSourceSelection:(NSSelection *)selection
			managedBy:(NSDataLinkManager *)linkManager
		  supportingTypes:(NSArray *)newTypes
{
  if ((self = [self init]) != nil)
    {
      ASSIGN(_sourceSelection,selection);
      ASSIGN(_sourceManager,linkManager);
      ASSIGN(_types,newTypes);
    }
  return self;
}

- (id)initWithContentsOfFile:(NSString *)filename
{
  NSData *data = [[NSData alloc] initWithContentsOfFile: filename];
  id object = nil;

  if (data != nil)
    {
      object = [NSUnarchiver unarchiveObjectWithData: data];
    }
  RELEASE(data);
  RELEASE(self);
  return RETAIN(object);
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard
{
  NSData *data = [pasteboard dataForType: NSDataLinkPboardType];
  id object = nil;

  if (data != nil)
    {
      object = [NSUnarchiver unarchiveObjectWithData: data];
    }
  RELEASE(self);
  return RETAIN(object);
}

//
// Exporting a Link
//
- (BOOL)saveLinkIn:(NSString *)directoryName
{
  NSSavePanel		*sp;
  int			result;

  sp = [NSSavePanel savePanel];
  [sp setRequiredFileType: NSDataLinkFilenameExtension];
  result = [sp runModalForDirectory: directoryName file: @""];
  if (result == NSOKButton)
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];
      NSString		*path = [sp filename];

      if ([mgr fileExistsAtPath: path] == YES)
	{
	  /* NSSavePanel has already asked if it's ok to replace */
	  NSString	*bPath = [path stringByAppendingString: @"~"];
	  
	  [mgr removeFileAtPath: bPath handler: nil];
	  [mgr movePath: path toPath: bPath handler: nil];
	}

      // save it.
      return [self writeToFile: path];
    }
  return NO;
}

- (BOOL)writeToFile:(NSString *)filename
{
  NSString *path = filename;

  if ([[path pathExtension] isEqual: NSDataLinkFilenameExtension] == NO)
    {
      path = [filename stringByAppendingPathExtension: NSDataLinkFilenameExtension];
    }

  return [NSArchiver archiveRootObject: self toFile: path];
}

- (void)writeToPasteboard:(NSPasteboard *)pasteboard
{
  NSData *data = [NSArchiver archivedDataWithRootObject: self];
  [pasteboard declareTypes: [NSArray arrayWithObject: NSDataLinkPboardType]
		     owner: nil];
  [pasteboard setData: data forType: NSDataLinkPboardType];
}

//
// Information about the Link
//
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
  return _sourceManager;
}

//
// Information about the Link's Source
//
- (NSDate *)lastUpdateTime
{
  return _lastUpdateTime;
}

- (BOOL)openSource
{
  id delegate = [_sourceManager delegate];

  if ([delegate respondsToSelector: @selector(showSelection:)] == YES)
    {
      return [delegate showSelection: _sourceSelection];
    }

  return (_sourceFilename != nil);
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

//
// Information about the Link's Destination
//
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

  if ([srcDelegate respondsToSelector: @selector(dataLinkManager:didBreakLink:)])
    {
      [srcDelegate dataLinkManager: _sourceManager didBreakLink: self];
    }

  if ([dstDelegate respondsToSelector: @selector(dataLinkManager:didBreakLink:)])
    {
      [dstDelegate dataLinkManager: _destinationManager didBreakLink: self];
    }

  _disposition = NSLinkBroken;
  _flags.broken = YES;

  return YES;
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
  id srcDelegate = [_sourceManager delegate];
  id dstDelegate = [_destinationManager delegate];
  NSPasteboard *pasteboard;
  BOOL result = NO;

  if (_flags.broken == YES || _updateMode == NSUpdateNever)
    {
      return NO;
    }

  if ([dstDelegate respondsToSelector: @selector(dataLinkManager:isUpdateNeededForLink:)] == YES
      && [dstDelegate dataLinkManager: _destinationManager isUpdateNeededForLink: self] == NO)
    {
      _flags.isDirty = NO;
      return YES;
    }

  if (_sourceFilename != nil
      && [dstDelegate respondsToSelector: @selector(importFile:at:)] == YES)
    {
      result = [dstDelegate importFile: _sourceFilename at: _destinationSelection];
    }
  else if ([srcDelegate respondsToSelector: @selector(copyToPasteboard:at:cheapCopyAllowed:)] == YES
	   && [dstDelegate respondsToSelector: @selector(pasteFromPasteboard:at:)] == YES)
    {
      pasteboard = [NSPasteboard pasteboardWithUniqueName];
      result = [srcDelegate copyToPasteboard: pasteboard
					  at: _sourceSelection
			    cheapCopyAllowed: NO];
      if (result == YES)
	{
	  result = [dstDelegate pasteFromPasteboard: pasteboard
						 at: _destinationSelection];
	}
      [pasteboard releaseGlobally];
    }

  if (result == YES)
    {
      ASSIGN(_lastUpdateTime, [NSDate date]);
      _flags.isDirty = NO;
      _flags.willUpdate = NO;
    }

  return result;
}

- (NSDataLinkUpdateMode)updateMode
{
  return _updateMode;
}

- (BOOL)isEqual:(id)object
{
  if (self == object)
    return YES;
  if (![object isKindOfClass: [NSDataLink class]])
    return NO;
  
  NSDataLink *other = (NSDataLink *)object;
  
  // Compare basic properties
  if (_linkNumber != other->_linkNumber)
    return NO;
  if (_disposition != other->_disposition)
    return NO;
  if (_updateMode != other->_updateMode)
    return NO;
  
  // Compare object properties - handle nil cases
  // Don't compare managers as they are not encoded/decoded
  if (![self isObject:_lastUpdateTime equalTo:other->_lastUpdateTime])
    return NO;
  if (![self isObject:_sourceApplicationName equalTo:other->_sourceApplicationName])
    return NO;
  if (![self isObject:_sourceFilename equalTo:other->_sourceFilename])
    return NO;
  if (![self isObject:_sourceSelection equalTo:other->_sourceSelection])
    return NO;
  if (![self isObject:_destinationApplicationName equalTo:other->_destinationApplicationName])
    return NO;
  if (![self isObject:_destinationFilename equalTo:other->_destinationFilename])
    return NO;
  if (![self isObject:_destinationSelection equalTo:other->_destinationSelection])
    return NO;
  if (![self isObject:_types equalTo:other->_types])
    return NO;
  
  return YES;
}

- (NSUInteger)hash
{
  return _linkNumber ^ _disposition ^ _updateMode ^ [_sourceFilename hash] ^ [_sourceSelection hash];
}

- (BOOL)isObject:(id)obj1 equalTo:(id)obj2
{
  if (obj1 == obj2)
    return YES;
  if (obj1 == nil || obj2 == nil)
    return NO;
  return [obj1 isEqual:obj2];
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
      [aCoder encodeInt: _disposition forKey: @"GSDisposition"];
      [aCoder encodeInt: _updateMode forKey: @"GSUpdateMode"];

      [aCoder encodeObject: _lastUpdateTime forKey: @"GSLastUpdateTime"];      

      [aCoder encodeObject: _sourceApplicationName forKey: @"GSSourceApplicationName"];
      [aCoder encodeObject: _sourceFilename forKey: @"GSSourceFilename"];
      [aCoder encodeObject: _sourceSelection forKey: @"GSSourceSelection"];
      // Don't encode sourceManager - it's typically a weak reference
      [aCoder encodeObject: nil forKey: @"GSSourceManager"];

      [aCoder encodeObject: _destinationApplicationName forKey: @"GSDestinationApplicationName"];
      [aCoder encodeObject: _destinationFilename forKey: @"GSDestinationFilename"];
      [aCoder encodeObject: _destinationSelection forKey: @"GSDestinationSelection"];
      // Don't encode destinationManager - it's typically a weak reference
      [aCoder encodeObject: nil forKey: @"GSDestinationManager"];
      
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
      // Don't encode sourceManager - it's typically a weak reference
      id nilManager = nil;
      [aCoder encodeValueOfObjCType: @encode(id)  at: &nilManager];
      
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_destinationApplicationName];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_destinationFilename];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_destinationSelection];
      // Don't encode destinationManager - it's typically a weak reference
      [aCoder encodeValueOfObjCType: @encode(id)  at: &nilManager];
      
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
  if ((self = [self init]) == nil)
    {
      return nil;
    }

  if ([aCoder allowsKeyedCoding])
    {
      id obj;

      _linkNumber = [aCoder decodeIntForKey: @"GSLinkNumber"];
      _disposition = [aCoder decodeIntForKey: @"GSDisposition"];
      _updateMode = [aCoder decodeIntForKey: @"GSUpdateMode"];

      obj = [aCoder decodeObjectForKey: @"GSLastUpdateTime"];
      ASSIGN(_lastUpdateTime, obj);

      obj = [aCoder decodeObjectForKey: @"GSSourceApplicationName"];
      ASSIGN(_sourceApplicationName,obj);
      obj = [aCoder decodeObjectForKey: @"GSSourceFilename"];
      ASSIGN(_sourceFilename,obj); 
      obj = [aCoder decodeObjectForKey: @"GSSourceSelection"];
      ASSIGN(_sourceSelection,obj);
      // Decode and discard the encoded nil manager
      [aCoder decodeObjectForKey: @"GSSourceManager"];
      _sourceManager = nil;

      obj = [aCoder decodeObjectForKey: @"GSDestinationApplicationName"];
      ASSIGN(_destinationApplicationName,obj);
      obj = [aCoder decodeObjectForKey: @"GSDestinationFilename"];
      ASSIGN(_destinationFilename,obj);
      obj = [aCoder decodeObjectForKey: @"GSDestinationSelection"];
      ASSIGN(_destinationSelection,obj);  
      // Decode and discard the encoded nil manager
      [aCoder decodeObjectForKey: @"GSDestinationManager"];
      _destinationManager = nil;

      obj = [aCoder decodeObjectForKey: @"GSTypes"];
      ASSIGN(_types,obj);

      // flags...
      _flags.appVerifies = [aCoder decodeBoolForKey: @"GSAppVerifies"];
      _flags.canUpdateContinuously = [aCoder decodeBoolForKey: @"GSCanUpdateContinuously"];
      _flags.isDirty = [aCoder decodeBoolForKey: @"GSIsDirty"];
      _flags.willOpenSource = [aCoder decodeBoolForKey: @"GSWillOpenSource"];
      _flags.willUpdate = [aCoder decodeBoolForKey: @"GSWillUpdate"];
      _flags.broken = NO;
      _flags.isMarker = NO;
    }
  else
    {
      int version = [aCoder versionForClassName: @"NSDataLink"];
      if (version == 0)
	{
	  BOOL flag = NO;
	  id obj;
	  
	  [aCoder decodeValueOfObjCType: @encode(int) at: &_linkNumber];
	  [aCoder decodeValueOfObjCType: @encode(int) at: &_disposition];
	  [aCoder decodeValueOfObjCType: @encode(int) at: &_updateMode];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &obj];
	  ASSIGN(_lastUpdateTime, obj);
	  
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &obj];
	  ASSIGN(_sourceApplicationName, obj);
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &obj];
	  ASSIGN(_sourceFilename, obj);
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &obj];
	  ASSIGN(_sourceSelection, obj);
	  // Skip the encoded nil manager
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &obj];
	  _sourceManager = nil;
	  
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &obj];
	  ASSIGN(_destinationApplicationName, obj);
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &obj];
	  ASSIGN(_destinationFilename, obj);
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &obj];
	  ASSIGN(_destinationSelection, obj);
	  // Skip the encoded nil manager
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &obj];
	  _destinationManager = nil;
	  
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &obj];
	  ASSIGN(_types, obj);
	  
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
	  _flags.broken = NO;
	  _flags.isMarker = NO;
	}
      else
	return nil;
    }

  return self;
}

@end
