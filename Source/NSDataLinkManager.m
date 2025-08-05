/** <title>NSDataLinkManager</title>

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
#import <Foundation/NSArchiver.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSPanel.h"
#import "AppKit/NSDataLinkManager.h"
#import "AppKit/NSDataLink.h"
#import "AppKit/NSPasteboard.h"

#ifdef HAVE_INOTIFY_H
#import <sys/inotify.h>
#endif

#import <unistd.h>
#import <fcntl.h>

#import "GSFastEnumeration.h"

@interface NSDataLinkManager (Private)
- (void) stopMonitoring;
- (void) startMonitoring;
- (void) monitorLoop;
@end

// Private setters/getters for links...
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
  ASSIGN(_lastUpdateTime, date);
}

- (void) setSourceFilename: (NSString *)src
{
  ASSIGN(_sourceFilename,src);
}

- (void) setDestinationFilename: (NSString *)dst
{
  ASSIGN(_destinationFilename, dst);
}

- (void) setSourceManager: (id)src
{
  ASSIGN(_sourceManager,src);
}

- (void) setDestinationManager: (id)dst
{
  ASSIGN(_destinationManager,dst);
}

- (void) setSourceSelection: (id)src
{
  ASSIGN(_sourceSelection,src);
}

- (void) setDestinationSelection: (id)dst
{
  ASSIGN(_destinationSelection,dst);
}

- (void) setIsMarker: (BOOL)flag
{
  _flags.isMarker = flag;
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
- (id) initWithDelegate: (id)anObject
	       fromFile: (NSString *)path
{
  self = [super init];

  if (self != nil)
    {
      _delegate = anObject; // don't retain...
      ASSIGN(_filename,path);
      _flags.delegateVerifiesLinks = NO;
      _flags.interactsWithUser = NO;
      _flags.isEdited = NO;
      _flags.areLinkOutlinesVisible = NO;

      _sourceLinks = [[NSMutableArray alloc] init];
      _destinationLinks = [[NSMutableArray alloc] init];
      _watchDescriptors = [[NSMutableDictionary alloc] init];
      _nextLinkNumber = 1;
#ifdef HAVE_INOTIFY_H
      _inotifyFD = inotify_init();
#endif
      if (_inotifyFD < 0)
	{
	  NSLog(@"Failed to initialize inotify");
	}
      [self startMonitoring];
    }

  return self;
}

- (id)initWithDelegate: (id)anObject
{
  return [self initWithDelegate: anObject fromFile: nil];
}

- (void) dealloc
{
  RELEASE(_sourceLinks);
  RELEASE(_destinationLinks);
  RELEASE(_watchDescriptors);

  [self stopMonitoring];
  [super dealloc];
}

//
// Monitoring methods
//
- (void)stopMonitoring
{
#ifdef HAVE_INOTIFY_H
  NSArray *allKeys = [_watchDescriptors allKeys];
  NSEnumerator *en = [allKeys objectEnumerator];
  NSNumber *key = nil;

  while ((key = [en nextObject]) != nil)
    {
      inotify_rm_watch(_inotifyFD, [key intValue]);
    }

  [_watchDescriptors removeAllObjects];

  if (_inotifyFD >= 0)
    {
      close(_inotifyFD);
      _inotifyFD = -1;
    }

  if (_monitorThread && [_monitorThread isExecuting])
    {
      [_monitorThread cancel];  // thread must check isCancelled
    }
#endif
}

- (void)startMonitoring
{
  _monitorThread = [[NSThread alloc] initWithTarget:self selector:@selector(monitorLoop) object:nil];
  [_monitorThread start];
}

- (void)monitorLoop
{
#ifdef HAVE_INOTIFY_H
  char buffer[1024];
  while (![[NSThread currentThread] isCancelled])
    {
      ssize_t length = read(_inotifyFD, buffer, sizeof(buffer));
      if (length < 0)
	{
	  continue;
	}

      ssize_t i = 0;
      while (i < length)
	{
	  struct inotify_event *event = (struct inotify_event *)&buffer[i];
	  NSNumber *key = [NSNumber numberWithInt:event->wd];
	  NSDataLink *link = [_watchDescriptors objectForKey: key];
	  if (link != nil)
	    {
	      [link noteSourceEdited];
	      NSLog(@"Source file changed for link #%d", [link linkNumber]);

	      // Check if delegate wants to verify this update
	      if ([_delegate respondsToSelector: @selector(dataLinkManager:isUpdateNeededForLink:)])
		{
		  BOOL needsUpdate = [_delegate dataLinkManager: self isUpdateNeededForLink: link];
		  if (needsUpdate)
		    {
		      [link updateDestination];
		    }
		}
	    }
	  i += sizeof(struct inotify_event) + event->len;
	}
    }
#endif
}

- (void) _checkLink: (NSDataLink *)link
{
  if (link == nil)
    {
      NSRunAlertPanel(@"Links", @"You must save the source document before you can link to it.", @"OK", nil, nil);
    }
}

//
// Adding and Removing Links
//
- (BOOL) addLink: (NSDataLink *)link
	      at: (NSSelection *)selection
{
  BOOL result = NO;

  [self _checkLink: link];
  [link setDestinationSelection: selection];
  [link setDestinationManager: self];

  if ([_destinationLinks containsObject: link] == NO)
    {
      [_destinationLinks addObject: link];
      result = YES;

      // Notify delegate that we're starting to track this link
      if ([_delegate respondsToSelector: @selector(dataLinkManager:startTrackingLink:)])
	{
	  [_delegate dataLinkManager: self startTrackingLink: link];
	}
    }

  return result;
}

- (BOOL) addLinkAsMarker: (NSDataLink *)link
		      at: (NSSelection *)selection
{
  [link setIsMarker: YES];
  return [self addLink: link at: selection];
}

- (NSDataLink *) addLinkPreviouslyAt: (NSSelection *)oldSelection
		      fromPasteboard: (NSPasteboard *)pasteboard
				  at: (NSSelection *)selection
{
  NSData *data = [pasteboard dataForType: NSDataLinkPboardType];
  NSArray *links = [NSUnarchiver unarchiveObjectWithData: data];
  NSEnumerator *en = [links objectEnumerator];
  NSDataLink *link = nil;

  while ((link = [en nextObject]) != nil)
    {
      if ([link destinationSelection] == oldSelection)
	{
	}
    }

  return nil;
}

- (void) breakAllLinks
{
  FOR_IN(NSDataLink*, src, _sourceLinks)
    {
      // Notify delegate we're stopping tracking
      if ([_delegate respondsToSelector: @selector(dataLinkManager:stopTrackingLink:)])
	{
	  [_delegate dataLinkManager: self stopTrackingLink: src];
	}
      [src break];
    }
  END_FOR_IN(_sourceLinks);

  FOR_IN(NSDataLink*, dst, _destinationLinks)
    {
      // Notify delegate we're stopping tracking
      if ([_delegate respondsToSelector: @selector(dataLinkManager:stopTrackingLink:)])
	{
	  [_delegate dataLinkManager: self stopTrackingLink: dst];
	}
      [dst break];
    }
  END_FOR_IN(_destinationLinks);
}

- (void) removeLink: (NSDataLink *)link
{
  if ([_sourceLinks containsObject: link])
    {
      // Notify delegate we're stopping tracking
      if ([_delegate respondsToSelector: @selector(dataLinkManager:stopTrackingLink:)])
	{
	  [_delegate dataLinkManager: self stopTrackingLink: link];
	}
      [_sourceLinks removeObject: link];
    }

  if ([_destinationLinks containsObject: link])
    {
      // Notify delegate we're stopping tracking
      if ([_delegate respondsToSelector: @selector(dataLinkManager:stopTrackingLink:)])
	{
	  [_delegate dataLinkManager: self stopTrackingLink: link];
	}
      [_destinationLinks removeObject: link];
    }
}

- (BOOL) addSourceLink: (NSDataLink *)link
{
  BOOL result = NO;

  [link setSourceManager: self];

  if ([_sourceLinks containsObject: link] == NO)
    {
      [_sourceLinks addObject: link];
      result = YES;

      // Notify delegate that we're starting to track this link
      if ([_delegate respondsToSelector: @selector(dataLinkManager:startTrackingLink:)])
	{
	  [_delegate dataLinkManager: self startTrackingLink: link];
	}
    }

  return result;
}

- (void) writeLinksToPasteboard: (NSPasteboard *)pasteboard
{
  FOR_IN(NSDataLink*, obj, _sourceLinks)
    {
      [obj writeToPasteboard: pasteboard];
    }
  END_FOR_IN(_sourceLinks);
}

//
// Informing the Link Manager of Document Status
//
- (void) noteDocumentClosed
{
  if ([_delegate respondsToSelector: @selector(dataLinkManagerCloseDocument:)])
    {
      [_delegate dataLinkManagerCloseDocument: self];
    }
}

- (void) noteDocumentEdited
{
  if ([_delegate respondsToSelector: @selector(dataLinkManagerDidEditLinks:)])
    {
      [_delegate dataLinkManagerDidEditLinks: self];
    }
}

- (void) noteDocumentReverted
{
  if ([_delegate respondsToSelector: @selector(dataLinkManagerDidEditLinks:)])
    {
      [_delegate dataLinkManagerDidEditLinks: self];
    }
}

- (void) noteDocumentSaved
{
  // Update all source links when document is saved
  FOR_IN(NSDataLink*, link, _sourceLinks)
    {
      [link setLastUpdateTime: [NSDate date]];
    }
  END_FOR_IN(_sourceLinks);

  // Check if any destination links need updates
  [self checkForLinkUpdates];
}

- (void) noteDocumentSavedAs:(NSString *)path
{
  ASSIGN(_filename, path);
  [self noteDocumentSaved];
}

- (void)noteDocumentSavedTo:(NSString *)path
{
  // When saving to a different location, update source links if applicable
  FOR_IN(NSDataLink*, link, _sourceLinks)
    {
      if ([[link sourceFilename] isEqualToString: _filename])
	{
	  [link setSourceFilename: path];
	}
    }
  END_FOR_IN(_sourceLinks);
}

//
// Getting and Setting Information about the Link Manager
//
- (id) delegate
{
  return _delegate;
}

- (BOOL)delegateVerifiesLinks
{
  return _flags.delegateVerifiesLinks;
}

- (NSString *)filename
{
  return _filename;
}

- (BOOL)interactsWithUser
{
  return _flags.interactsWithUser;
}

- (BOOL)isEdited
{
  return _flags.isEdited;
}

- (void)setDelegateVerifiesLinks:(BOOL)flag
{
  _flags.delegateVerifiesLinks = flag;
}

- (void)setInteractsWithUser:(BOOL)flag
{
  _flags.interactsWithUser = flag;
}

//
// Getting and Setting Information about the Manager's Links
//
- (BOOL)areLinkOutlinesVisible
{
  return _flags.areLinkOutlinesVisible;
}

- (NSEnumerator *)destinationLinkEnumerator
{
  return [_destinationLinks objectEnumerator];
}

- (NSDataLink *)destinationLinkWithSelection:(NSSelection *)destSel
{
  id result = nil;

  FOR_IN(id, obj, _destinationLinks)
    {
      if ([[obj destinationSelection] isEqual: destSel])
	{
	  result = obj;
	  break;
	}
    }
  END_FOR_IN(_destinationLinks);

  return result;
}

- (void)setLinkOutlinesVisible:(BOOL)flag
{
  _flags.areLinkOutlinesVisible = flag;

  // Notify delegate to redraw outlines when visibility changes
  if ([_delegate respondsToSelector: @selector(dataLinkManagerRedrawLinkOutlines:)])
    {
      [_delegate dataLinkManagerRedrawLinkOutlines: self];
    }
}

- (NSEnumerator *)sourceLinkEnumerator
{
  return [_sourceLinks objectEnumerator];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL flag = NO;

  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeObject: _filename forKey: @"GSFilename"];
      [aCoder encodeObject: _sourceLinks forKey: @"GSSourceLinks"];
      [aCoder encodeObject: _destinationLinks forKey: @"GSDestinationLinks"];

      flag = _flags.areLinkOutlinesVisible;
      [aCoder encodeBool: flag forKey: @"GSAreLinkOutlinesVisible"];
      flag = _flags.delegateVerifiesLinks;
      [aCoder encodeBool: flag forKey: @"GSDelegateVerifiesLinks"];
      flag = _flags.interactsWithUser;
      [aCoder encodeBool: flag forKey: @"GSInteractsWithUser"];
      flag = _flags.isEdited;
      [aCoder encodeBool: flag forKey: @"GSIsEdited"];
    }
  else
    {
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_filename];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_sourceLinks];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &_destinationLinks];

      flag = _flags.areLinkOutlinesVisible;
      [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
      flag = _flags.delegateVerifiesLinks;
      [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
      flag = _flags.interactsWithUser;
      [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
      flag = _flags.isEdited;
      [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
    }
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  if ([aCoder allowsKeyedCoding])
    {
      BOOL flag = NO;
      id obj;

      obj = [aCoder decodeObjectForKey: @"GSFilename"];
      ASSIGN(_filename,obj);
      obj = [aCoder decodeObjectForKey: @"GSSourceLinks"];
      ASSIGN(_sourceLinks,obj);
      obj = [aCoder decodeObjectForKey: @"GSDestinationLinks"];
      ASSIGN(_destinationLinks,obj);

      flag = [aCoder decodeBoolForKey: @"GSAreLinkOutlinesVisible"];
      _flags.areLinkOutlinesVisible = flag;
      flag = [aCoder decodeBoolForKey: @"GSDelegateVerifiesLinks"];
      _flags.delegateVerifiesLinks = flag;
      flag = [aCoder decodeBoolForKey: @"GSInteractsWithUser"];
      _flags.interactsWithUser = flag;
      flag = [aCoder decodeBoolForKey: @"GSIsEdited"];
      _flags.isEdited = flag;
    }
  else
    {
      int version = [aCoder versionForClassName: @"NSDataLinkManager"];
      if (version == 0)
	{
	  BOOL flag = NO;

	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_filename];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_sourceLinks];
	  [aCoder decodeValueOfObjCType: @encode(id)  at: &_destinationLinks];

	  [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
	  _flags.areLinkOutlinesVisible = flag;
	  [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
	  _flags.delegateVerifiesLinks = flag;
	  [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
	  _flags.interactsWithUser = flag;
	  [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
	  _flags.isEdited = flag;
	}
      else
	return nil;
    }
  return self;
}

//
// Additional delegate callback methods
//
- (void) checkForLinkUpdates
{
  FOR_IN(NSDataLink*, link, _destinationLinks)
    {
      if ([_delegate respondsToSelector: @selector(dataLinkManager:isUpdateNeededForLink:)])
	{
	  BOOL needsUpdate = [_delegate dataLinkManager: self isUpdateNeededForLink: link];
	  if (needsUpdate)
	    {
	      [link updateDestination];
	    }
	}
    }
  END_FOR_IN(_destinationLinks);
}

- (void) redrawLinkOutlines
{
  if ([_delegate respondsToSelector: @selector(dataLinkManagerRedrawLinkOutlines:)])
    {
      [_delegate dataLinkManagerRedrawLinkOutlines: self];
    }
}

- (BOOL) tracksLinksIndividually
{
  if ([_delegate respondsToSelector: @selector(dataLinkManagerTracksLinksIndividually:)])
    {
      return [_delegate dataLinkManagerTracksLinksIndividually: self];
    }
  return YES; // Default behavior
}

@end
