/* 
   gpbs.m

   GNUstep pasteboard server

   Copyright (C) 1997,1999 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: August 1997
   
   This file is part of the GNUstep Project

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
    
   You should have received a copy of the GNU General Public  
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

*/ 

#include <gnustep/gui/config.h>
#include <Foundation/NSString.h>
#include <Foundation/NSData.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSConnection.h>
#include <Foundation/NSDistantObject.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSTimer.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSException.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSObjCRuntime.h>
#include <AppKit/NSPasteboard.h>

#include <gnustep/gui/GSPasteboardServer.h>

#include <signal.h>

@class PasteboardServer;

int debug = 0;
int verbose = 0;

#define MAXHIST 100

PasteboardServer	*server = nil;
NSConnection		*conn = nil;
NSLock			*dictionary_lock = nil;
NSMutableDictionary	*pasteboards = nil;

@interface PasteboardData: NSObject
{
  NSData*   data;
  NSString* type;
  id	    owner;
  id	    pboard;
  BOOL	    wantsChangedOwner;
  BOOL	    hasGNUDataForType;
  BOOL	    hasStdDataForType;
}
+ (PasteboardData*) newWithType: (NSString*)aType
			  owner: (id)anObject
			 pboard: (id)anotherObject
	      wantsChangedOwner: (BOOL)wants
	      hasStdDataForType: (BOOL)StdData
	      hasGNUDataForType: (BOOL)GNUData;
- (BOOL) checkConnection: (NSConnection*)c;
- (NSData*) data;
- (NSData*) newDataWithVersion: (int)version;
- (id) owner;
- (id) pboard;
- (void) setData: (NSData*)d;
- (NSString*) type;
- (BOOL) wantsChangedOwner;
@end

@implementation PasteboardData

+ (PasteboardData*) newWithType: (NSString*)aType
			  owner: (id)anObject
			 pboard: (id)anotherObject
	      wantsChangedOwner: (BOOL)wants
	      hasStdDataForType: (BOOL)StdData
	      hasGNUDataForType: (BOOL)GNUData;
{
  PasteboardData*   d = [PasteboardData alloc];

  if (d)
    {
      d->type = [aType retain];
      d->owner = [anObject retain];
      d->pboard = [anotherObject retain];
      d->wantsChangedOwner = wants;
      d->hasStdDataForType = StdData;
      d->hasGNUDataForType = GNUData;
    }
  return d;
}

- (BOOL) checkConnection: (NSConnection*)c
{
  BOOL	ourConnection = NO;
  id	o;

  if (owner && [owner isProxy] && [owner connectionForProxy] == c)
    {
      o = owner;
      owner = nil;
      [o release];
      o = pboard;
      pboard = nil;
      [o release];
      ourConnection = YES;
    }
  if (pboard && [pboard isProxy] && [pboard connectionForProxy] == c)
    {
      o = owner;
      owner = nil;
      [o release];
      o = pboard;
      pboard = nil;
      [o release];
      ourConnection = YES;
    }
  return ourConnection;
}

- (void) dealloc
{
  [type release];
  [data release];
  [owner release];
  [pboard release];
  [super dealloc];
}

- (NSString*) description
{
  return [NSString stringWithFormat: @"PasteboardData for type '%@'", type];
}

- (NSData*) data
{
  if (verbose)
    {
      NSLog(@"get data for %x\n", (unsigned)self);
    }
  return data;
}

- (NSData*) newDataWithVersion: (int)version
{
  if (data == nil && (owner && pboard))
    {
      if (hasGNUDataForType)
	{
	  [owner pasteboard: pboard
	 provideDataForType: type
		 andVersion: version];
	}
      else if (hasStdDataForType)
	{
	  [owner pasteboard: pboard
	 provideDataForType: type];
	}
    }
  return [self data];
}

- (id) owner
{
  return owner;
}

- (id) pboard
{
  return pboard;
}

- (void) setData: (NSData*)d
{
  if (verbose)
    {
      NSLog(@"set data for %x\n", (unsigned)self);
    }
  [d retain];
  [data release];
  data = d;
}

- (id) type
{
  return type;
}

- (BOOL) wantsChangedOwner
{
  return wantsChangedOwner;
}

@end



@interface PasteboardEntry: NSObject
{
  int		refNum;
  BOOL		hasBeenFiltered;
  id		owner;
  id		pboard;
  NSMutableArray    *items;
  BOOL		wantsChangedOwner;
  BOOL		hasGNUDataForType;
  BOOL		hasStdDataForType;
}
+ (PasteboardEntry*) newWithTypes: (NSArray*)someTypes
			    owner: (id)anOwner
			   pboard: (id)aPboard
			      ref: (int)count;
- (void) addTypes: (NSArray*)types owner: (id)owner pasteboard: (id)pb;
- (BOOL) checkConnection: (NSConnection*)c;
- (BOOL) hasBeenFiltered;
- (PasteboardData*) itemForType: (NSString*)type;
- (void) lostOwnership;
- (int) refNum;
- (NSArray*) types;
@end

@implementation PasteboardEntry

+ (PasteboardEntry*) newWithTypes: (NSArray*)someTypes
			    owner: (id)anOwner
			   pboard: (id)aPboard
			      ref: (int)count
{
  PasteboardEntry*  e = [PasteboardEntry alloc];

  if (e)
    {
      int     i;

      e->owner = [anOwner retain];
      e->pboard = [aPboard retain];

      if (anOwner && [anOwner respondsToSelector:
		@selector(pasteboardChangedOwner:)])
	{
	  e->wantsChangedOwner = YES;
	}
      if (anOwner && [anOwner respondsToSelector:
		@selector(pasteboard:provideDataForType:)])
	{
	  e->hasStdDataForType = YES;
	}
      if (anOwner && [anOwner respondsToSelector:
		@selector(pasteboard:provideDataForType:andVersion:)])
	{
	  e->hasGNUDataForType = YES;
	}

      e->items = [[NSMutableArray alloc] initWithCapacity: [someTypes count]];
      for (i = 0; i < [someTypes count]; i++)
	{
	  NSString		*type = [someTypes objectAtIndex: i];
	  PasteboardData	*d;

	  d = [PasteboardData newWithType: type
				    owner: anOwner
				   pboard: aPboard
			wantsChangedOwner: e->wantsChangedOwner
			hasStdDataForType: e->hasStdDataForType
			hasGNUDataForType: e->hasGNUDataForType];
	  [e->items addObject: d];
	  [d release];
	}
      e->refNum = count;
      if (verbose > 1)
	{
	  NSLog(@"New PasteboardEntry %d with items - %@", count, e->items);
	}
    }
  return e;
}

- (void) addTypes: newTypes owner: newOwner pasteboard: pb
{
  int	i;
  BOOL	wants = NO;
  BOOL	StdData = NO;
  BOOL	GNUData = NO;

  if (newOwner && [newOwner respondsToSelector:
	@selector(pasteboardChangedOwner:)])
    {
      wants = YES;
    }
  if (newOwner && [newOwner respondsToSelector:
	@selector(pasteboard:provideDataForType:)])
    {
      StdData = YES;
    }
  if (newOwner && [newOwner respondsToSelector:
	@selector(pasteboard:provideDataForType:andVersion:)])
    {
      GNUData = YES;
    }

  for (i = 0; i < [newTypes count]; i++)
    {
      NSString	*type = (NSString*)[newTypes objectAtIndex: i];

      if ([self itemForType: type] == nil)
	{
	  PasteboardData*   d;

	  d = [PasteboardData newWithType: type
				    owner: newOwner
				   pboard: pb
			wantsChangedOwner: wants
			hasStdDataForType: StdData
			hasGNUDataForType: GNUData];
	  [items addObject: d];
	  [d release];
	}
    }
  if (verbose > 1)
    {
      NSLog(@"Modified PasteboardEntry %d with items - %@", refNum, items);
    }
}

- (BOOL) checkConnection: (NSConnection*)c
{
  BOOL		ourConnection = NO;
  unsigned	i;
  id		o;

  if (owner && [owner isProxy] && [owner connectionForProxy] == c)
    {
      o = owner;
      owner = nil;
      [o release];
      o = pboard;
      pboard = nil;
      [o release];
      ourConnection = YES;
    }

  if (pboard && [pboard isProxy] && [pboard connectionForProxy] == c)
    {
      o = owner;
      owner = nil;
      [o release];
      o = pboard;
      pboard = nil;
      [o release];
      ourConnection = YES;
    }

  for (i = [items count]; i > 0; i--)
    {
      PasteboardData	*d = [items objectAtIndex: i-1];

      if ([d checkConnection: c] == YES && [d data] == nil && [d owner] == nil)
	{
	  if (verbose > 1)
	    {
	      NSLog(@"Removing item from PasteboardEntry %d\n", refNum);
	    }
	  [items removeObjectAtIndex: i-1];
	}
    }
  return ourConnection;
}

- (void) dealloc
{
  [owner release];
  [pboard release];
  [items release];
  [super dealloc];
}

- (BOOL) hasBeenFiltered
{
  return hasBeenFiltered;
}

- (PasteboardData*) itemForType: (NSString*)type
{
  unsigned i, count;

  count = [items count];
  for (i = 0; i < count; i++)
    {
      PasteboardData	*d = [items objectAtIndex: i];

      if ([[d type] isEqual: type])
	{
	  return d;
	}
    }
  return nil;
}

- (void) lostOwnership
{
  NSMutableArray*   a = [NSMutableArray arrayWithCapacity:4];
  unsigned i;

  NS_DURING
    {
      if (wantsChangedOwner)
	{
	  [a addObject: owner];
	}

      for (i = 0; i < [items count]; i++)
	{
	  PasteboardData*   d = [items objectAtIndex:i];

	  if ([d wantsChangedOwner] && [a containsObject: [d owner]] == NO)
	    {
	      [a addObject: [d owner]];
	    }
	}

      if (wantsChangedOwner)
	{
	  [a removeObject: owner];
	  [owner pasteboardChangedOwner: pboard];
	}

      for (i = 0; i < [items count] && [a count] > 0; i++)
	{
	  PasteboardData*   d = [items objectAtIndex:i];
	  id		o = [d owner];

	  if ([a containsObject: o])
	    {
	      [o pasteboardChangedOwner: [d pboard]];
	      [a removeObject: o];
	    }
	}
    }
  NS_HANDLER
    {
      NSLog(@"Error informing objects of ownership change - %@\n",
	[localException reason]);
    }
  NS_ENDHANDLER
}

- (int) refNum
{
  return refNum;
}

- (NSArray*) types
{
  NSMutableArray*   t = [NSMutableArray arrayWithCapacity: [items count]];
  unsigned int	    i;

  for (i = 0; i < [items count]; i++)
    {
      PasteboardData* d = [items objectAtIndex:i];
      [t addObject: [d type]];
    }
  return t;
}

@end



@interface PasteboardObject: NSObject <GSPasteboardObj>
{
  NSString	*name;
  int		nextCount;
  unsigned	histLength;
  NSMutableArray    *history;
  PasteboardEntry   *current;
}

+ (PasteboardObject*) pasteboardWithName: (NSString*)name;

- (int) addTypes: (NSArray*)types
	   owner: (id)owner
      pasteboard: (id)pboard
	oldCount: (int)count;
- (NSString*) availableTypeFromArray: (NSArray*)types
	     changeCount: (int*)count;
- (int) changeCount;
- (BOOL) checkConnection: (NSConnection*)c;
- (NSData*) dataForType: (NSString*)type
	   oldCount: (int)count
      mustBeCurrent: (BOOL)flag;
- (int) declareTypes: (NSArray*)types
	       owner: (id)owner
	  pasteboard: (id)pboard;
- (PasteboardEntry*) entryByCount: (int)count;
- (NSString*) name;
- (void) releaseGlobally;
- (BOOL) setData: (NSData*)data
	 forType: (NSString*)type
	  isFile: (BOOL)flag
	oldCount: (int)count;
- (void) setHistory: (unsigned)length;
- (NSArray*) typesAndChangeCount: (int*)count;

@end

@implementation PasteboardObject

+ (void) initialize
{
  pasteboards = [[NSMutableDictionary alloc] initWithCapacity:8];
  dictionary_lock = [[NSLock alloc] init];
}

+ (PasteboardObject*) pasteboardWithName: (NSString*)aName
{
  static int	    number = 0;
  PasteboardObject* pb;

  [dictionary_lock lock];
  while (aName == nil)
    {
      aName = [NSString stringWithFormat: @"%dlocalName", number++];
      if ([pasteboards objectForKey:aName] == nil)
	{
	  break;	// This name is unique.
	}
      else
	{
	  aName = nil;	// Name already in use - try another.
	}
    }

  pb = [pasteboards objectForKey: aName];
  if (pb == nil)
    {
      pb = [PasteboardObject alloc];
      pb->name = [aName retain];
      pb->nextCount = 1;
      pb->histLength = 1;
      pb->history = [[NSMutableArray alloc] initWithCapacity:2];
      pb->current = nil;
      [pasteboards setObject: pb forKey: aName];
      [pb autorelease];
    }
  [dictionary_lock unlock];
  return pb;
}

- (int) addTypes: (NSArray*)types
	   owner: (id)owner
      pasteboard: (NSPasteboard*)pb
	oldCount: (int)count
{
  PasteboardEntry *e = [self entryByCount:count];

  if (e)
    {
      [e addTypes: types owner: owner pasteboard: pb];
      return count;
    }
  return 0;
}

- (NSString*) availableTypeFromArray: (NSArray*)types
			 changeCount: (int*)count
{
  PasteboardEntry *e = nil;

  if (*count <= 0)
    {
      e = current;
    }
  else
    {
      e = [self entryByCount:*count];
    }
  if (e)
    {
      unsigned	  i;

      *count = [e refNum];
      for (i = 0; i < [types count]; i++)
	{
	  NSString* key = [types objectAtIndex:i];

	  if ([e itemForType: key] != nil)
	    {
	      return key;
	    }
	}
    }
  return nil;
}

- (int) changeCount
{
  if (current)
    {
      return [current refNum];
    }
  return 0;
}

- (BOOL) checkConnection: (NSConnection*)c
{
  unsigned	i;
  BOOL		found = NO;

  for (i = 0; i < [history count]; i++)
    {
      if ([[history objectAtIndex: i] checkConnection: c] == YES)
	{
	  found = YES;
	}
    }
  return found;
}

- (NSData*) dataForType: (NSString*)type
	       oldCount: (int)count
	  mustBeCurrent: (BOOL)flag
{
  PasteboardEntry *e = nil;

  if (flag)
    {
      e = current;
    }
  else
    {
      e = [self entryByCount:count];
    }
  if (verbose)
    {
      NSLog(@"get data for type '%@' version %d\n", type, e ? [e refNum] : -1);
    }
  if (e)
    {
      PasteboardData	*d = [e itemForType: type];

      if (d)
	{
	  return [d newDataWithVersion: [e refNum]];
	}
    }
  return nil; 
}

- (void) dealloc
{
  [name release];
  [history release];
  [super dealloc];
}

- (int) declareTypes: (bycopy NSArray*)types
	       owner: (id)owner
	  pasteboard: (NSPasteboard*)pb
{
  PasteboardEntry	*old = [current retain];

  current = [PasteboardEntry newWithTypes: types
				    owner: owner
				   pboard: pb
				      ref: nextCount++];
  [history addObject: current];
  [current release];
  if ([history count] > histLength)
    {
      [history removeObjectAtIndex: 0];
    }
  [old lostOwnership];
  [old release];
  return [current refNum];
}

- (PasteboardEntry*) entryByCount: (int)count
{
  if (current == nil)
    {
      return nil;
    }
  else if ([current refNum] == count)
    {
      return current;
    }
  else
    {
      int i;

      for (i = 0; i < [history count]; i++)
	{
	  if ([[history objectAtIndex:i] refNum] == count)
	    {
	      return (PasteboardEntry*)[history objectAtIndex:i];
	    }
	}
      return nil;
    }
}

- (NSString*) name
{
  return name;
}

- (void) releaseGlobally
{
  if ([name isEqual: NSDragPboard]) return;
  if ([name isEqual: NSFindPboard]) return;
  if ([name isEqual: NSFontPboard]) return;
  if ([name isEqual: NSGeneralPboard]) return;
  if ([name isEqual: NSRulerPboard]) return;
  [pasteboards removeObjectForKey: name];
}

- (BOOL) setData: (NSData*)data
	 forType: (NSString*)type
	  isFile: (BOOL)flag
	oldCount: (int)count
{
  PasteboardEntry	*e;

  if (verbose)
    {
      NSLog(@"set data for type '%@' version %d\n", type, count);
    }
  e = [self entryByCount: count];
  if (e)
    {
      PasteboardData	*d;

      if (flag)
	{
	  d = [e itemForType: NSFileContentsPboardType];
	  if (d)
	    {
	      [d setData: data];
	    }
	  else
	    {
	      return NO;
	    }
	  if (type && [type isEqual: NSFileContentsPboardType] == NO)
	    {
	      d = [e itemForType: type];
	      if (d)
		{
		  [d setData: data];
		}
	      else
		{
		  return NO;
		}
	    }
	  return YES;
	}
      else if (type)
	{
	  d = [e itemForType: type];
	  if (d)
	    {
	      [d setData: data];
	      return YES;
	    }
	  else
	    {
	      return NO;
	    }
	}
      else
	{
	  return NO;
	}
    }
  else
    {
      return NO;
    }
}

- (void) setHistory: (unsigned)length
{
  if (length < 1) length = 1;
  if (length > MAXHIST) length = MAXHIST;

  histLength = length;
  if (length < histLength)
    {
      while ([history count] > histLength)
	{
	  [history removeObjectAtIndex:0];
	}
    }
}

- (NSArray*) typesAndChangeCount: (int*)count
{
  PasteboardEntry *e = nil;

  if (*count <= 0)
    {
      e = current;
    }
  else
    {
      e = [self entryByCount:*count];
    }
  if (e)
    {
      *count = [e refNum];
      return [e types];
    }
  return nil;
}

@end





@interface PasteboardServer : NSObject <GSPasteboardSvr>
{
  NSMutableArray*   permenant;
}
- (NSConnection*) connection: ancestor didConnect: newConn;
- connectionBecameInvalid: notification;

- (id<GSPasteboardObj>) pasteboardByFilteringData: (NSData*)data
					   ofType: (NSString*)type
					   isFile: (BOOL)flag;
- (id<GSPasteboardObj>) pasteboardByFilteringTypesInPasteboard: pb;
- (id<GSPasteboardObj>) pasteboardWithName: (NSString*)name;
- (id<GSPasteboardObj>) pasteboardWithUniqueName;
- (NSArray*) typesFilterableTo: (NSString*)type;
@end

@implementation PasteboardServer

- (NSConnection*) connection: ancestor didConnect: newConn
{
  [[NSNotificationCenter defaultCenter]
    addObserver: self
       selector: @selector(connectionBecameInvalid:)
	   name: NSConnectionDidDieNotification
	 object: newConn];
  [newConn setDelegate: self];
  return newConn;
}

- (id) connectionBecameInvalid: (NSNotification*)notification
{
  id connection = [notification object];

  if (connection == conn)
    {
      NSLog(@"Help - pasteboard server connection has died!\n");
      exit(1);
    }
  if ([connection isKindOf: [NSConnection class]])
    {
      NSEnumerator    *e = [pasteboards objectEnumerator];
      PasteboardObject	  *o;

      while ((o = [e nextObject]) != nil)
	{
	  [o checkConnection: connection];
	}
    }
  return self;
}

- (void) dealloc
{
  [permenant release];
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self)
    {
      permenant = [[NSMutableArray alloc] initWithCapacity:5];
      /*
       *  Create all the pasteboards which must persist forever and add them
       *  to a local array.
       */
      [permenant addObject: [self pasteboardWithName: NSGeneralPboard]];
      [permenant addObject: [self pasteboardWithName: NSFontPboard]];
      [permenant addObject: [self pasteboardWithName: NSRulerPboard]];
      [permenant addObject: [self pasteboardWithName: NSFindPboard]];
      [permenant addObject: [self pasteboardWithName: NSDragPboard]];
    }
  return self;
}

- (id<GSPasteboardObj>) pasteboardByFilteringData: (NSData*)data
					   ofType: (NSString*)type
					   isFile: (BOOL)flag
{
  [self notImplemented: _cmd];
  return nil;
}

- (id<GSPasteboardObj>) pasteboardByFilteringTypesInPasteboard: pb
{
  [self notImplemented: _cmd];
  return nil;
}

- (id<GSPasteboardObj>) pasteboardWithName: (NSString*)name
{
  return [PasteboardObject pasteboardWithName: name];
}

- (id<GSPasteboardObj>) pasteboardWithUniqueName
{
  return [PasteboardObject pasteboardWithName: nil];
}

- (NSArray*) typesFilterableTo: (NSString*)type
{
  [self notImplemented: _cmd];
  return nil;
}

@end



static int
ihandler(int sig)
{
  signal(sig, SIG_DFL);
  abort();
}

static void
init(int argc, char** argv)
{
  const char  *options = "Hdv";
  int	  sym;

  while ((sym = getopt(argc, argv, options)) != -1)
    {
      switch(sym)
	{
	  case 'H':
	    printf("%s -[%s]\n", argv[0], options);
	    printf("GNU Pasteboard server\n");
	    printf("-H\tfor help\n");
	    printf("-d\tavoid fork() to make debugging easy\n");
	    printf("-v\tMore verbose debug output\n");
	    exit(0);

	  case 'd':
	    debug++;
	    break;

	  case 'v':
	    verbose++;
	    break;

	  default:
	    printf("%s - GNU Pasteboard server\n", argv[0]);
	    printf("-H	for help\n");
	    exit(0);
	}
    }

  for (sym = 0; sym < 32; sym++)
    {
      signal(sym, ihandler);
    }
  signal(SIGPIPE, SIG_IGN);
  signal(SIGTTOU, SIG_IGN);
  signal(SIGTTIN, SIG_IGN);
  signal(SIGHUP, SIG_IGN);
  signal(SIGTERM, ihandler);

  if (debug == 0)
    {
      /*
       *  Now fork off child process to run in background.
       */
      switch (fork())
	{
	  case -1:
	    NSLog(@"gpbs - fork failed - bye.\n");
	    exit(1);

	  case 0:
	    /*
	     *	Try to run in background.
	     */
#ifdef	NeXT
	    setpgrp(0, getpid());
#else
	    setsid();
#endif
	    break;

	  default:
	    if (verbose)
	      {
		NSLog(@"Process backgrounded (running as daemon)\r\n");
	      }
	    exit(0);
	}
    }
}


int
main(int argc, char** argv)
{
  NSAutoreleasePool	*pool = [NSAutoreleasePool new];

  init(argc, argv);

  // [NSObject enableDoubleReleaseCheck: YES];

  server = [[PasteboardServer alloc] init];

  if (server == nil)
    {
      NSLog(@"Unable to create server object.\n");
      exit(1);
    }

  /* Register a connection that provides the server object to the network */
  conn = [NSConnection newRegisteringAtName:PBSNAME
		 withRootObject:server];
  
  if (conn == nil)
    {
      NSLog(@"Unable to register with name server.\n");
      exit(1);
    }

  [conn setDelegate:server];
  [[NSNotificationCenter defaultCenter]
    addObserver: server
       selector: @selector(connectionBecameInvalid:)
	   name: NSConnectionDidDieNotification
	 object: conn];

  if (verbose)
    {
      NSLog(@"GNU pasteboard server startup.\n");
    }
  [[NSRunLoop currentRunLoop] run];
  [pool release];
  exit(0);
}


