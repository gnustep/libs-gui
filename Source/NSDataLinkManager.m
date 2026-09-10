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
#import <Foundation/NSDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSPanel.h"
#import "AppKit/NSDataLinkManager.h"
#import "AppKit/NSDataLink.h"
#import "AppKit/NSPasteboard.h"

/* A source file is watched by whichever mechanism the platform has.  inotify
   reports the file itself; the Windows notification handle reports that
   something in a directory changed, and every link taking its source from
   there is reported; where there is neither, a timer compares each file's
   modification date and size.  All three end at -_noteSourceEditedForLink:,
   which runs on the main thread. */
#ifdef HAVE_SYS_INOTIFY_H
#import <sys/inotify.h>
#define GS_MONITOR_INOTIFY 1
#elif defined(_WIN32)
#include <windows.h>
#define GS_MONITOR_WIN32 1
#endif

#import <unistd.h>
#import <fcntl.h>

#import "GSFastEnumeration.h"

/* How often the timer reads the dates, in seconds, where no notification
   mechanism is available. */
#define GS_POLL_INTERVAL 1.0

@interface NSDataLinkManager (Private)
- (void) stopMonitoring;
- (void) startMonitoring;
- (void) monitorLoop;
- (BOOL) _startNativeMonitoring;
- (void) _startPolling;
- (void) _stopPolling;
- (void) _pollSources: (id)timer;
- (BOOL) _noteStampOfPath: (NSString *)path;
- (void) _sourceChangedForLinkAtPath: (NSString *)path;
- (void) _directoryChanged: (NSString *)directory;
- (void) _noteSourceEditedForLink: (NSDataLink *)link;
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
      _watchedLinks = [[NSMutableDictionary alloc] init];
      _watchedStamps = [[NSMutableDictionary alloc] init];
      _nextLinkNumber = 1;
      _inotifyFD = -1;
#ifdef GS_MONITOR_INOTIFY
      _inotifyFD = inotify_init();
      if (_inotifyFD < 0)
	{
	  NSLog(@"Failed to initialize inotify");
	}
#endif
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
  /* Monitoring reads the watch table, so it has to be stopped first. */
  [self stopMonitoring];

  RELEASE(_sourceLinks);
  RELEASE(_destinationLinks);
  RELEASE(_watchDescriptors);
  RELEASE(_watchedLinks);
  RELEASE(_watchedStamps);
  RELEASE(_monitorThread);
  [super dealloc];
}

//
// Monitoring methods
//
- (void)stopMonitoring
{
  [self _stopPolling];

  /* The thread is asked to stop before anything it waits on is taken away. */
  if (_monitorThread && [_monitorThread isExecuting])
    {
      NSDate *limit = [NSDate dateWithTimeIntervalSinceNow: 1.0];

      [_monitorThread cancel];  // thread must check isCancelled
      while ([_monitorThread isExecuting]
	&& [limit timeIntervalSinceNow] > 0.0)
	{
	  [NSThread sleepForTimeInterval: 0.02];
	}
    }

#ifdef GS_MONITOR_INOTIFY
  {
    NSEnumerator *en = [[_watchDescriptors allKeys] objectEnumerator];
    NSNumber *key = nil;

    while ((key = [en nextObject]) != nil)
      {
	inotify_rm_watch(_inotifyFD, [key intValue]);
      }
  }

  if (_inotifyFD >= 0)
    {
      close(_inotifyFD);
      _inotifyFD = -1;
    }
#endif

#ifdef GS_MONITOR_WIN32
  {
    NSArray *values;
    NSEnumerator *en;
    NSValue *value = nil;

    @synchronized(self)
      {
	values = [[_watchDescriptors allValues] copy];
	[_watchDescriptors removeAllObjects];
      }
    en = [values objectEnumerator];
    while ((value = [en nextObject]) != nil)
      {
	FindCloseChangeNotification((HANDLE)[value pointerValue]);
      }
    RELEASE(values);
  }
#endif

  [_watchDescriptors removeAllObjects];
  [_watchedLinks removeAllObjects];
  [_watchedStamps removeAllObjects];
}

/* Start whichever notification mechanism the platform has.  Answers NO when
   there is none to start, and the timer stands in for it. */
- (BOOL) _startNativeMonitoring
{
#ifdef GS_MONITOR_INOTIFY
  /* With no descriptor to read there is nothing to wait on, and the loop
     would spin. */
  if (_inotifyFD < 0)
    {
      return NO;
    }
#endif

#if defined(GS_MONITOR_INOTIFY) || defined(GS_MONITOR_WIN32)
  _monitorThread = [[NSThread alloc] initWithTarget: self
					   selector: @selector(monitorLoop)
					     object: nil];
  [_monitorThread start];
  return YES;
#else
  return NO;
#endif
}

- (void)startMonitoring
{
  if ([self _startNativeMonitoring] == NO)
    {
      [self _startPolling];
    }
}

/* Read the dates of every watched source.  This is what the timer runs, and
   what the Windows watcher runs when a directory reports a change: the
   notification says a directory changed, and the dates say which file. */
- (void) _pollSources: (id)timer
{
  NSEnumerator *en = [[_watchedLinks allKeys] objectEnumerator];
  NSString *path;

  while ((path = [en nextObject]) != nil)
    {
      if ([self _noteStampOfPath: path] == YES)
	{
	  [self _sourceChangedForLinkAtPath: path];
	}
    }
}

- (void) _startPolling
{
  if (_pollTimer != nil)
    {
      return;
    }
  _pollTimer = [NSTimer scheduledTimerWithTimeInterval: GS_POLL_INTERVAL
						target: self
					      selector: @selector(_pollSources:)
					      userInfo: nil
					       repeats: YES];
}

- (void) _stopPolling
{
  if (_pollTimer != nil)
    {
      [_pollTimer invalidate];
      _pollTimer = nil;
    }
}

/* Answers YES when the file differs from the way it was last seen, and records
   how it is now.  A file just added is recorded without being reported, since
   nothing has changed yet.

   The size is compared as well as the modification date: a file rewritten in
   the same second as the reading before it keeps its date, and the timer has
   nothing else to go on. */
- (BOOL) _noteStampOfPath: (NSString *)path
{
  NSDictionary *attributes;
  NSString *now;
  NSString *before;

  attributes = [[NSFileManager defaultManager] fileAttributesAtPath: path
							traverseLink: YES];
  if (attributes == nil)
    {
      return NO;
    }

  now = [NSString stringWithFormat: @"%@ %llu",
    [attributes objectForKey: NSFileModificationDate],
    (unsigned long long)[attributes fileSize]];

  before = [_watchedStamps objectForKey: path];
  [_watchedStamps setObject: now forKey: path];

  return (before != nil && [now isEqual: before] == NO);
}

/* Watch the file a link takes its contents from, and remember which link the
   watch belongs to.  Watching the same file twice returns the same descriptor,
   so the table keeps the most recently added link for it. */
- (void) _watchSourceOfLink: (NSDataLink *)link
{
  NSString *path = [link sourceFilename];

  if (path == nil)
    {
      return;
    }

  /* Recorded for every mechanism, and with the date the file has now, so that
     the first comparison reports a change made after this point and not the
     file's whole history. */
  [_watchedLinks setObject: link forKey: path];
  [self _noteStampOfPath: path];

#ifdef GS_MONITOR_INOTIFY
  {
    int wd;

    if (_inotifyFD < 0)
      {
	return;
      }

    wd = inotify_add_watch(_inotifyFD, [path fileSystemRepresentation],
			   IN_CLOSE_WRITE | IN_MODIFY | IN_MOVE_SELF);
    if (wd < 0)
      {
	return;
      }

    [_watchDescriptors setObject: link forKey: [NSNumber numberWithInt: wd]];
  }
#endif

#ifdef GS_MONITOR_WIN32
  {
    NSString *directory = [path stringByDeletingLastPathComponent];
    HANDLE handle;

    /* One notification handle serves every link in a directory, so a
       directory already watched is left alone. */
    if ([directory length] == 0
      || [_watchDescriptors objectForKey: directory] != nil)
      {
	return;
      }

    handle = FindFirstChangeNotificationW(
      (const unichar *)[directory cStringUsingEncoding: NSUTF16StringEncoding],
      FALSE, FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_FILE_NAME);
    if (handle == INVALID_HANDLE_VALUE || handle == NULL)
      {
	/* Nothing to wait on for this directory: the timer reads its dates
	   instead, which is the same answer a platform with no notification
	   mechanism at all gets. */
	[self _startPolling];
	return;
      }

    /* The monitoring thread waits on these handles, so the table it reads is
       not written without the lock it takes. */
    @synchronized(self)
      {
	[_watchDescriptors setObject: [NSValue valueWithPointer: handle]
			      forKey: directory];
      }
  }
#endif
}

- (void) _unwatchSourceOfLink: (NSDataLink *)link
{
  NSString *path = [link sourceFilename];

  if (path != nil)
    {
      [_watchedLinks removeObjectForKey: path];
      [_watchedStamps removeObjectForKey: path];
    }

#ifdef GS_MONITOR_INOTIFY
  {
    NSArray *keys = [_watchDescriptors allKeysForObject: link];
    NSEnumerator *en = [keys objectEnumerator];
    NSNumber *key;

    while ((key = [en nextObject]) != nil)
      {
	if (_inotifyFD >= 0)
	  {
	    inotify_rm_watch(_inotifyFD, [key intValue]);
	  }
	[_watchDescriptors removeObjectForKey: key];
      }
  }
#endif

#ifdef GS_MONITOR_WIN32
  {
    NSString *directory = [path stringByDeletingLastPathComponent];
    NSEnumerator *en = [[_watchedLinks allKeys] objectEnumerator];
    NSString *other;
    NSValue *value;

    /* The handle is the directory's, so it stays while any other link in that
       directory is still watched. */
    while ((other = [en nextObject]) != nil)
      {
	if ([[other stringByDeletingLastPathComponent] isEqual: directory])
	  {
	    return;
	  }
      }

    @synchronized(self)
      {
	value = [_watchDescriptors objectForKey: directory];
	if (value != nil)
	  {
	    [_watchDescriptors removeObjectForKey: directory];
	  }
      }
    if (value != nil)
      {
	FindCloseChangeNotification((HANDLE)[value pointerValue]);
      }
  }
#endif
}

/* Called on the main thread for each watch that reported a change, so the
   delegate is never messaged from the monitoring thread. */
- (void) _sourceChangedForWatch: (NSNumber *)descriptor
{
  [self _noteSourceEditedForLink:
    [_watchDescriptors objectForKey: descriptor]];
}

/* The Windows watcher and the timer name the file rather than a watch. */
- (void) _sourceChangedForLinkAtPath: (NSString *)path
{
  [self _noteSourceEditedForLink: [_watchedLinks objectForKey: path]];
}

/* A directory the Windows watcher reported.  Every link taking its source from
   that directory is reported, without consulting the file's modification date:
   the notification is the platform saying something there changed, and a date
   is too coarse to confirm it.  An edit made in the same second as the one
   before it leaves the date alone, and the delegate exists to decide whether
   the change matters. */
- (void) _directoryChanged: (NSString *)directory
{
  NSEnumerator *en = [[_watchedLinks allKeys] objectEnumerator];
  NSString *path;

  while ((path = [en nextObject]) != nil)
    {
      if ([[path stringByDeletingLastPathComponent] isEqual: directory])
	{
	  /* Read now, so that a later poll does not report it again. */
	  [self _noteStampOfPath: path];
	  [self _sourceChangedForLinkAtPath: path];
	}
    }
}

- (void) _noteSourceEditedForLink: (NSDataLink *)link
{
  if (link == nil)
    {
      return;
    }

  [link noteSourceEdited];

  if ([_delegate respondsToSelector:
	@selector(dataLinkManager:isUpdateNeededForLink:)])
    {
      if ([_delegate dataLinkManager: self isUpdateNeededForLink: link])
	{
	  [link updateDestination];
	}
    }
}

- (void)monitorLoop
{
#ifdef GS_MONITOR_WIN32
  while (![[NSThread currentThread] isCancelled])
    {
      CREATE_AUTORELEASE_POOL(pool);
      NSArray *directories;
      HANDLE handles[MAXIMUM_WAIT_OBJECTS];
      DWORD count = 0;
      DWORD result;

      /* The table belongs to the main thread, so it is read under a lock and
	 the handles are copied out before waiting on them. */
      @synchronized(self)
	{
	  NSEnumerator *en;
	  NSString *directory;

	  directories = [_watchDescriptors allKeys];
	  en = [directories objectEnumerator];
	  while ((directory = [en nextObject]) != nil
	    && count < MAXIMUM_WAIT_OBJECTS)
	    {
	      NSValue *value = [_watchDescriptors objectForKey: directory];

	      if (value != nil)
		{
		  handles[count++] = (HANDLE)[value pointerValue];
		}
	    }
	  directories = [directories copy];
	}
      [directories autorelease];

      if (count == 0)
	{
	  /* No directory is watched yet; wait rather than spin, and look
	     again for one a link may have added meanwhile. */
	  DESTROY(pool);
	  [NSThread sleepForTimeInterval: 0.1];
	  continue;
	}

      /* The wait ends on its own so that a cancelled thread stops, and so
	 that a directory added since the snapshot is picked up. */
      result = WaitForMultipleObjects(count, handles, FALSE, 500);
      if (result >= WAIT_OBJECT_0 && result < WAIT_OBJECT_0 + count)
	{
	  DWORD index = result - WAIT_OBJECT_0;
	  NSString *directory = [directories objectAtIndex: index];

	  /* Re-arm before the change is examined, so an edit made while it is
	     being read is not missed. */
	  FindNextChangeNotification(handles[index]);

	  [self performSelectorOnMainThread: @selector(_directoryChanged:)
				 withObject: directory
			      waitUntilDone: NO];
	}
      DESTROY(pool);
    }
#endif

#ifdef GS_MONITOR_INOTIFY
  char buffer[1024];
  while (![[NSThread currentThread] isCancelled])
    {
      ssize_t length = read(_inotifyFD, buffer, sizeof(buffer));
      if (length < 0)
	{
	  continue;
	}

      ssize_t i = 0;
      CREATE_AUTORELEASE_POOL(pool);

      while (i < length)
	{
	  struct inotify_event *event = (struct inotify_event *)&buffer[i];
	  NSNumber *key = [NSNumber numberWithInt: event->wd];

	  /* The watch table and the delegate belong to the main thread. */
	  [self performSelectorOnMainThread: @selector(_sourceChangedForWatch:)
				 withObject: key
			      waitUntilDone: NO];

	  i += sizeof(struct inotify_event) + event->len;
	}
      DESTROY(pool);
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
      [self _watchSourceOfLink: link];
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

  [self _unwatchSourceOfLink: link];
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
