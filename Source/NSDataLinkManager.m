/** <title>NSDataLinkManager</title>

   Copyright (C) 1996 Free Software Foundation, Inc.

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
#include "AppKit/NSDataLinkManager.h"

@implementation NSDataLinkManager

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSDataLinkManager class])
    {
      // Initial version
      [self setVersion:1];
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

  ASSIGN(delegate,anObject);
  filename = nil;
  delegateVerifiesLinks = NO;
  interactsWithUser = NO;
  isEdited = NO;
  areLinkOutlinesVisible = NO;

  return self;
}

- (id)initWithDelegate:(id)anObject
	      fromFile:(NSString *)path
{
  self = [super init];

  ASSIGN(delegate,anObject);
  ASSIGN(filename,path);
  delegateVerifiesLinks = NO;
  interactsWithUser = NO;
  isEdited = NO;
  areLinkOutlinesVisible = NO;

  return self;
}

//
// Adding and Removing Links
//
- (BOOL)addLink:(NSDataLink *)link
	     at:(NSSelection *)selection
{
  return NO;
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
  NSLog(@"Break all links.");
}

- (void)writeLinksToPasteboard:(NSPasteboard *)pasteboard
{
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
  return nil;
}

- (NSDataLink *)destinationLinkWithSelection:(NSSelection *)destSel
{
  return nil;
}

- (void)setLinkOutlinesVisible:(BOOL)flag
{
  areLinkOutlinesVisible = flag;
}

- (NSEnumerator *)sourceLinkEnumerator
{
  return nil;
}

//
// Methods Implemented by the Delegate
//
- (BOOL)copyToPasteboard:(NSPasteboard *)pasteboard 
		      at:(NSSelection *)selection
cheapCopyAllowed:(BOOL)flag
{
  return NO;
}

- (void)dataLinkManager:(NSDataLinkManager *)sender 
	   didBreakLink:(NSDataLink *)link
{
}

- (BOOL)dataLinkManager:(NSDataLinkManager *)sender 
  isUpdateNeededForLink:(NSDataLink *)link
{
  return NO;
}

- (void)dataLinkManager:(NSDataLinkManager *)sender 
      startTrackingLink:(NSDataLink *)link
{
}

- (void)dataLinkManager:(NSDataLinkManager *)sender 
       stopTrackingLink:(NSDataLink *)link
{
}

- (void)dataLinkManagerCloseDocument:(NSDataLinkManager *)sender
{
}

- (void)dataLinkManagerDidEditLinks:(NSDataLinkManager *)sender
{
}

- (void)dataLinkManagerRedrawLinkOutlines:(NSDataLinkManager *)sender
{
}

- (BOOL)dataLinkManagerTracksLinksIndividually:(NSDataLinkManager *)sender
{
  return NO;
}

- (BOOL)importFile:(NSString *)filename
		at:(NSSelection *)selection
{
  return NO;
}

- (BOOL)pasteFromPasteboard:(NSPasteboard *)pasteboard 
			 at:(NSSelection *)selection
{
  return NO;
}

- (BOOL)showSelection:(NSSelection *)selection
{
  return NO;
}

- (NSWindow *)windowForSelection:(NSSelection *)selection
{
  return nil;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  return self;
}

@end
