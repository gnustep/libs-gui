/** <title>NSDataLinkManager</title>

   Copyright (C) 1996, 2005 Free Software Foundation, Inc.

   Author: Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2005
   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#include "config.h"
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSDataLinkManager.h>
#include <AppKit/NSDataLink.h>

@interface NSDataLink (Private)
- (void) setLastUpdateTime: (NSDate *)date;
- (void) setSourceFilename: (NSString *)src;
- (void) setDestinationFilename: (NSString *)dst;
- (void) setSourceManager: (id)src;
- (void) setDestinationManager: (id)dst;
- (void) setSourceSelection: (id)src;
- (void) setDestinationSelection: (id)dst;
@end

@implementation NSDataLink (Private)
- (void) setLastUpdateTime: (NSDate *)date
{
  ASSIGN(lastUpdateTime, date);
}

- (void) setSourceFilename: (NSString *)src
{
  ASSIGN(sourceFilename,src);
}

- (void) setDestinationFilename: (NSString *)dst
{
  ASSIGN(destinationFilename, dst);
}

- (void) setSourceManager: (id)src
{
  ASSIGN(sourceManager,src);
}

- (void) setDestinationManager: (id)dst
{
  ASSIGN(destinationManager,dst);
}

- (void) setSourceSelection: (id)src
{
  ASSIGN(sourceSelection,src);
}

- (void) setDestinationSelection: (id)dst
{
  ASSIGN(destinationSelection,dst);
}
@end


@implementation NSDataLinkManager

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSDataLinkManager class])
    {
      // Initial version
      [self setVersion: 0];
    }
}

//
// Instance methods
//
//
// Initializing and Freeing a Link Manager
//
- (id)initWithDelegate:(id)anObject
{
  self = [super init];

  if(self != nil)
    {
      ASSIGN(delegate,anObject);
      filename = nil;
      delegateVerifiesLinks = NO;
      interactsWithUser = NO;
      isEdited = NO;
      areLinkOutlinesVisible = NO;
    }

  return self;
}

- (id)initWithDelegate:(id)anObject
	      fromFile:(NSString *)path
{
  self = [super init];

  if(self != nil)
    {
      ASSIGN(delegate,anObject);
      ASSIGN(filename,path);
      delegateVerifiesLinks = NO;
      interactsWithUser = NO;
      isEdited = NO;
      areLinkOutlinesVisible = NO;
    }

  return self;
}

//
// Adding and Removing Links
//
- (BOOL)addLink:(NSDataLink *)link
	     at:(NSSelection *)selection
{
  BOOL result = NO;

  [link setDestinationSelection: selection];
  [link setDestinationManager: self];

  if([destinationLinks containsObject: link] == NO)
    {
      [destinationLinks addObject: link];
      result = YES;
    }

  return result;
}

- (BOOL)addLinkAsMarker:(NSDataLink *)link
		     at:(NSSelection *)selection
{
  return NO;
}

- (NSDataLink *)addLinkPreviouslyAt:(NSSelection *)oldSelection
		     fromPasteboard:(NSPasteboard *)pasteboard
                                 at:(NSSelection *)selection
{
  return nil;
}

- (void)breakAllLinks
{
  NSArray *allLinks = [sourceLinks arrayByAddingObjectsFromArray: destinationLinks];
  NSEnumerator *en = [allLinks objectEnumerator];
  id obj = nil;

  while((obj = [en nextObject]) != nil)
    {
      [obj break];
    }
}

- (void)writeLinksToPasteboard:(NSPasteboard *)pasteboard
{
  NSArray *allLinks = [sourceLinks arrayByAddingObjectsFromArray: destinationLinks];
  NSEnumerator *en = [allLinks objectEnumerator];
  id obj = nil;

  while((obj = [en nextObject]) != nil)
    {
      [obj writeToPasteboard: pasteboard];
    }
}

//
// Informing the Link Manager of Document Status
//
- (void)noteDocumentClosed
{
}

- (void)noteDocumentEdited
{
}

- (void)noteDocumentReverted
{
}

- (void)noteDocumentSaved
{
}

- (void)noteDocumentSavedAs:(NSString *)path
{
}

- (void)noteDocumentSavedTo:(NSString *)path
{
}

//
// Getting and Setting Information about the Link Manager
//
- (id)delegate
{
  return delegate;
}

- (BOOL)delegateVerifiesLinks
{
  return delegateVerifiesLinks;
}

- (NSString *)filename
{
  return filename;
}

- (BOOL)interactsWithUser
{
  return interactsWithUser;
}

- (BOOL)isEdited
{
  return isEdited;
}

- (void)setDelegateVerifiesLinks:(BOOL)flag
{
  delegateVerifiesLinks = flag;
}

- (void)setInteractsWithUser:(BOOL)flag
{
  interactsWithUser = flag;
}

//
// Getting and Setting Information about the Manager's Links
//
- (BOOL)areLinkOutlinesVisible
{
  return areLinkOutlinesVisible;
}

- (NSEnumerator *)destinationLinkEnumerator
{
  return [destinationLinks objectEnumerator];
}

- (NSDataLink *)destinationLinkWithSelection:(NSSelection *)destSel
{
  NSEnumerator *en = [self destinationLinkEnumerator];
  id obj = nil;

  while((obj = [en nextObject]) != nil)
    {
      if([obj destinationSelection] == destSel)
	{
	  break;
	}
    }

  return obj;
}

- (void)setLinkOutlinesVisible:(BOOL)flag
{
  areLinkOutlinesVisible = flag;
}

- (NSEnumerator *)sourceLinkEnumerator
{
  return [sourceLinks objectEnumerator];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL flag = NO;

  [aCoder encodeValueOfObjCType: @encode(id)  at: &filename];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &sourceLinks];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &destinationLinks];

  flag = areLinkOutlinesVisible;
  [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
  flag = delegateVerifiesLinks;
  [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
  flag = interactsWithUser;
  [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
  flag = isEdited;
  [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  int version = [aCoder versionForClassName: @"NSDataLinkManager"];

  if(version == 0)
    {
      BOOL flag = NO;
      
      [aCoder decodeValueOfObjCType: @encode(id)  at: &filename];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &sourceLinks];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &destinationLinks];
      
      [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
      areLinkOutlinesVisible = flag;
      [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
      delegateVerifiesLinks = flag;
      [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
      interactsWithUser = flag;
      [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
      isEdited = flag;
    }
  else
    {
      return nil;
    }

  return self;
}

@end
