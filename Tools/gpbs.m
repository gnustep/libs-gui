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

#include <Foundation/Foundation.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/GSPasteboardServer.h>

#include <signal.h>
#include <unistd.h>

@class PasteboardServer;
@class PasteboardObject;

@protocol XPb
+ (id) ownerByOsPb: (NSString*)p;
@end
static Class	xPbClass;

int debug = 0;
int verbose = 0;

#define MAXHIST 100

PasteboardServer	*server = nil;
NSConnection		*conn = nil;
NSLock			*dictionary_lock = nil;
NSMutableDictionary	*pasteboards = nil;

@interface	NSPasteboard (GNULocal)
+ (void) _localServer: (id<GSPasteboardSvr>)s;
@end

@interface PasteboardData: NSObject
{
  NSData	*data;
  NSString	*type;
  id		owner;
  id		pboard;
  BOOL		wantsChangedOwner;
  BOOL		hasGNUDataForType;
  BOOL		hasStdDataForType;
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
      d->type = RETAIN(aType);
      d->owner = RETAIN(anObject);
      d->pboard = RETAIN(anotherObject);
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
      RELEASE(o);
      o = pboard;
      pboard = nil;
      RELEASE(o);
      ourConnection = YES;
    }
  if (pboard && [pboard isProxy] && [pboard connectionForProxy] == c)
    {
      o = owner;
      owner = nil;
      RELEASE(o);
      o = pboard;
      pboard = nil;
      RELEASE(o);
      ourConnection = YES;
    }
  return ourConnection;
}

- (void) dealloc
{
  RELEASE(type);
  RELEASE(data);
  RELEASE(owner);
  RELEASE(pboard);
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
  /*
   * If the owner of this item is an X window - we can't use the data from
   * the last time the selection was accessed because the X window may have
   * changed it's selection without telling us - isn't X wonderful :-(
   */
  if (data != nil && owner != nil
    && [owner isProxy] == NO && [owner isKindOfClass: xPbClass] == YES)
    {
      DESTROY(data);
    }

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
  ASSIGN(data, d);
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
  int			refNum;
  id			owner;
  id			pboard;
  NSMutableArray	*items;
  BOOL			hasBeenFiltered;
  BOOL			wantsChangedOwner;
  BOOL			hasGNUDataForType;
  BOOL			hasStdDataForType;
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
- (id) owner;
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

      e->owner = RETAIN(anOwner);
      e->pboard = RETAIN(aPboard);

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
	  RELEASE(d);
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
	  RELEASE(d);
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
      RELEASE(o);
      o = pboard;
      pboard = nil;
      RELEASE(o);
      ourConnection = YES;
    }

  if (pboard && [pboard isProxy] && [pboard connectionForProxy] == c)
    {
      o = owner;
      owner = nil;
      RELEASE(o);
      o = pboard;
      pboard = nil;
      RELEASE(o);
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
  RELEASE(owner);
  RELEASE(pboard);
  RELEASE(items);
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
  NSMutableArray	*a = [NSMutableArray arrayWithCapacity: 4];
  unsigned		i;

  NS_DURING
    {
      if (wantsChangedOwner == YES && owner != nil)
	{
	  [a addObject: owner];
	}

      for (i = 0; i < [items count]; i++)
	{
	  PasteboardData	*d = [items objectAtIndex: i];

	  if ([d wantsChangedOwner] == YES && [d owner] != nil
	    && [a indexOfObjectIdenticalTo: [d owner]] == NSNotFound)
	    {
	      [a addObject: [d owner]];
	    }
	}

      if (wantsChangedOwner == YES)
	{
	  [owner pasteboardChangedOwner: pboard];
	  if (owner != nil)
	    {
	      [a removeObjectIdenticalTo: owner];
	    }
	}

      for (i = 0; i < [items count] && [a count] > 0; i++)
	{
	  PasteboardData	*d = [items objectAtIndex: i];
	  id			o = [d owner];

	  if (o != nil && [a containsObject: o])
	    {
	      [o pasteboardChangedOwner: [d pboard]];
	      [a removeObjectIdenticalTo: o];
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

- (id) owner
{
  return owner;
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
      PasteboardData* d = [items objectAtIndex: i];
      [t addObject: [d type]];
    }
  return t;
}

@end



@interface PasteboardObject: NSObject <GSPasteboardObj>
{
  NSString		*name;
  int			nextCount;
  unsigned		histLength;
  NSMutableArray	*history;
  PasteboardEntry	*current;
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
  pasteboards = [[NSMutableDictionary alloc] initWithCapacity: 8];
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
      if ([pasteboards objectForKey: aName] == nil)
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
      pb->name = RETAIN(aName);
      pb->nextCount = 1;
      pb->histLength = 1;
      pb->history = [[NSMutableArray alloc] initWithCapacity: 2];
      pb->current = nil;
      [pasteboards setObject: pb forKey: aName];
      AUTORELEASE(pb);
    }
  [dictionary_lock unlock];
  return pb;
}

- (int) addTypes: (NSArray*)types
	   owner: (id)owner
      pasteboard: (NSPasteboard*)pb
	oldCount: (int)count
{
  PasteboardEntry *e = [self entryByCount: count];

  if (e)
    {
      id	x = [xPbClass ownerByOsPb: name];

      [e addTypes: types owner: owner pasteboard: pb];

      /*
       * If there is an X pasteboard corresponding to this pasteboard, and the
       * X system doesn't currently own the pasteboard, we must inform it of
       * the change in the types of data supplied by this pasteboard.
       * We do this by simulating a change of pasteboard ownership.
       */
      if (x != owner && x != nil)
	[x pasteboardChangedOwner: pb];
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
      e = [self entryByCount: *count];
    }
  if (e)
    {
      unsigned	  i;

      *count = [e refNum];
      for (i = 0; i < [types count]; i++)
	{
	  NSString* key = [types objectAtIndex: i];

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
      e = [self entryByCount: count];
    }
  if (verbose)
    {
      NSLog(@"%@ get data for type '%@' version %d\n",
	self, type, e ? [e refNum] : -1);
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
  RELEASE(name);
  RELEASE(history);
  [super dealloc];
}

- (int) declareTypes: (bycopy NSArray*)types
	       owner: (id)owner
	  pasteboard: (NSPasteboard*)pb
{
  PasteboardEntry	*old = RETAIN(current);
  id			x = [xPbClass ownerByOsPb: name];

  /*
   * If neither the new nor the old owner of the pasteboard is the X
   * pasteboard owner corresponding to this pasteboard, we will need
   * to inform the X owner of the change of ownership.
   */
  if (x == owner)
    x = nil;
  else if (x == [old owner])
    x = nil;

  current = [PasteboardEntry newWithTypes: types
				    owner: owner
				   pboard: pb
				      ref: nextCount++];
  [history addObject: current];
  RELEASE(current);
  if ([history count] > histLength)
    {
      [history removeObjectAtIndex: 0];
    }
  [old lostOwnership];
  RELEASE(old);
  /*
   * If there is an interested X pasteboard - inform it of the ownership
   * change.
   */
  if (x != nil)
    [x pasteboardChangedOwner: pb];
  if (verbose)
    {
      NSLog(@"%@ declare types '%@' version %d\n",
	self, types, [current refNum]);
    }
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
	  if ([[history objectAtIndex: i] refNum] == count)
	    {
	      return (PasteboardEntry*)[history objectAtIndex: i];
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
      NSLog(@"%@ set data for type '%@' version %d\n", self, type, count);
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
	  [history removeObjectAtIndex: 0];
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
      e = [self entryByCount: *count];
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
  NSMutableArray	*permenant;
}
- (BOOL) connection: (NSConnection*)ancestor
  shouldMakeNewConnection: (NSConnection*)newConn;
- (id) connectionBecameInvalid: (NSNotification*)notification;

- (id<GSPasteboardObj>) pasteboardByFilteringData: (NSData*)data
					   ofType: (NSString*)type
					   isFile: (BOOL)flag;
- (id<GSPasteboardObj>) pasteboardByFilteringTypesInPasteboard: pb;
- (id<GSPasteboardObj>) pasteboardWithName: (NSString*)name;
- (id<GSPasteboardObj>) pasteboardWithUniqueName;
@end



@implementation PasteboardServer

- (BOOL) connection: (NSConnection*)ancestor
  shouldMakeNewConnection: (NSConnection*)newConn;
{
  [[NSNotificationCenter defaultCenter]
    addObserver: self
       selector: @selector(connectionBecameInvalid:)
	   name: NSConnectionDidDieNotification
	 object: newConn];
  [newConn setDelegate: self];
  return YES;
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
  RELEASE(permenant);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self)
    {
      /*
       * Tell the NSPasteboard class to use us as the server so that the X
       * pasteboard owners can talk to us directly rather than over D.O.
       */
      [NSPasteboard _localServer: (id<GSPasteboardSvr>)self];

      /*
       *  Create all the pasteboards which must persist forever and add them
       *  to a local array.
       */
      permenant = [[NSMutableArray alloc] initWithCapacity: 5];
      [permenant addObject: [self pasteboardWithName: NSGeneralPboard]];
      [permenant addObject: [self pasteboardWithName: NSDragPboard]];
      [permenant addObject: [self pasteboardWithName: NSFontPboard]];
      [permenant addObject: [self pasteboardWithName: NSRulerPboard]];
      [permenant addObject: [self pasteboardWithName: NSFindPboard]];

      /*
       * Ensure that the X pasteboard system is initialised.
       */
      xPbClass = NSClassFromString(@"XPbOwner");
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



static void
ihandler(int sig)
{
  signal(sig, SIG_DFL);
  abort();
}

static void
init(int argc, char** argv)
{
  NSArray	*args = [[NSProcessInfo processInfo] arguments];
  unsigned	count;

  for (count = 1; count < [args count]; count++)
    {
      NSString	*a = [args objectAtIndex: count];

      if ([a isEqualToString: @"--help"] == YES)
	{
	  printf("gpbs\n\n");
	  printf("GNU Pasteboard server\n");
	  printf("--help\tfor help\n");
	  printf("--no-fork\tavoid fork() to make debugging easy\n");
	  printf("--verbose\tMore verbose debug output\n");
	  exit(0);
	}
      else if ([a isEqualToString: @"--no-fork"] == YES)
	debug++;
      else if ([a isEqualToString: @"--verbose"] == YES)
	verbose++;
      else if ([a length] > 0)
	{
	  printf("gpbs - GNU Pasteboard server\n");
	  printf("I don't understand '%s'\n", [a cString]);
	  printf("--help	for help\n");
	  exit(0);
	}
    }

  for (count = 0; count < 32; count++)
    {
      signal((int)count, ihandler);
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
main(int argc, char** argv, char **env)
{
  CREATE_AUTORELEASE_POOL(pool);
  NSString      *hostname;

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

  init(argc, argv);

  // [NSObject enableDoubleReleaseCheck: YES];

  server = [[PasteboardServer alloc] init];

  if (server == nil)
    {
      NSLog(@"Unable to create server object.\n");
      exit(1);
    }

  /* Register a connection that provides the server object to the network */
  conn = [NSConnection defaultConnection];
  [conn setRootObject: server];
  [conn setDelegate: server];
  [[NSNotificationCenter defaultCenter]
    addObserver: server
       selector: @selector(connectionBecameInvalid:)
	   name: NSConnectionDidDieNotification
	 object: (id)conn];

  hostname = [[NSUserDefaults standardUserDefaults] stringForKey: @"NSHost"];
  if ([hostname length] == 0)
    {
      if ([conn registerName: PBSNAME] == NO)
        {
          NSLog(@"Unable to register with name server.\n");
          exit(1);
        }
    }
  else
    {
      NSHost            *host = [NSHost hostWithName: hostname];
      NSPort            *port = [conn receivePort];
      NSPortNameServer  *ns = [NSPortNameServer systemDefaultPortNameServer];
      NSArray           *a;
      unsigned          c;

      if (host == nil)
        {
          NSLog(@"gdnc - unknown NSHost argument  ... %@ - quiting.", hostname);
          exit(1);
        }
      a = [host names];
      c = [a count];
      while (c-- > 0)
        {
          NSString      *name = [a objectAtIndex: c];

          name = [PBSNAME stringByAppendingFormat: @"-%@", name];
          if ([ns registerPort: port forName: name] == NO)
            {
            }
        }
      a = [host addresses];
      c = [a count];
      while (c-- > 0)
        {
          NSString      *name = [a objectAtIndex: c];

          name = [PBSNAME stringByAppendingFormat: @"-%@", name];
          if ([ns registerPort: port forName: name] == NO)
            {
            }
        }
    }

  if (verbose)
    {
      NSLog(@"GNU pasteboard server startup.\n");
    }
  [[NSRunLoop currentRunLoop] run];
  RELEASE(pool);
  exit(0);
}

