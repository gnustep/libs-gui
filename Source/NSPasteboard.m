/** <title>NSPasteboard</title>

   <abstract>Implementation of class for communicating with the
			pasteboard server.</abstract>

   Copyright (C) 1997,1999,2003 Free Software Foundation, Inc.

   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1997
   
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

#include "gnustep/gui/config.h"
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSWorkspace.h"
#include "AppKit/NSFileWrapper.h"
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSHost.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSConnection.h>
#include <Foundation/NSDistantObject.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSException.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSPortNameServer.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSSerialization.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSMethodSignature.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSTimer.h>

#include "gnustep/gui/GSServicesManager.h"
#include "gnustep/gui/GSPasteboardServer.h"

static NSString	*contentsPrefix = @"NSTypedFileContentsPboardType:";
static NSString	*namePrefix = @"NSTypedFilenamesPboardType:";

/*
 * A pasteboard class for lazily filtering data
 */
@interface FilteredPasteboard : NSPasteboard
{
@public
  NSArray	*originalTypes;
  NSString	*file;
  NSData	*data;
  NSPasteboard	*pboard;
}
@end

@implementation	FilteredPasteboard
/**
 * Find a filter specification to use.
 */
+ (NSString*) _filterForType: (NSString*)type fromTypes: (NSArray*)types
{
  NSDictionary	*filters = [[GSServicesManager manager] filters];
  NSEnumerator	*enumerator = [filters keyEnumerator];
  NSString	*key;

  while ((key = [enumerator nextObject]) != nil)
    {
      NSDictionary	*info = [filters objectForKey: key];
      NSArray		*returnTypes = [info objectForKey: @"NSReturnTypes"];

      if ([returnTypes containsObject: type] == YES)
	{
	  NSArray	*sendTypes = [info objectForKey: @"NSSendTypes"];
	  unsigned 	i;

	  for (i = 0; i < [types count]; i++)
	    {
	      if ([sendTypes containsObject: [types objectAtIndex: i]] == YES)
		{
		  return key;
		}
	    }
	}
    }
  return nil;
}

/**
 * Given an array of types, produce an array of all the types we can
 * make from that using a single filter.
 */
+ (NSArray*) _typesFilterableFrom: (NSArray*)from
{
  NSMutableSet	*types = [NSMutableSet setWithCapacity: 8];
  NSDictionary	*info = [[GSServicesManager manager] filters];
  unsigned 	i;

  for (i = 0; i < [from count]; i++)
    {
      NSString		*type = [from objectAtIndex: i];
      NSEnumerator	*enumerator = [info objectEnumerator];

      [types addObject: type];	// Always include original type

      while ((info = [enumerator nextObject]) != nil)
	{
	  NSArray	*sendTypes = [info objectForKey: @"NSSendTypes"];

	  if ([sendTypes containsObject: type] == YES)
	    {
	      NSArray	*returnTypes = [info objectForKey: @"NSReturnTypes"];

	      [types addObjectsFromArray: returnTypes];
	    }
	}
    }
  return [types allObjects];
}

- (void) dealloc
{
  DESTROY(originalTypes);
  DESTROY(data);
  DESTROY(pboard);
  [super dealloc];
}

/**
 * This method actually performs any filtering required.
 */
- (void) pasteboard: (NSPasteboard*)sender
 provideDataForType: (NSString*)type
{
  NSDictionary	*info;
  NSString	*filterName = nil;
  NSString	*fromType = nil;
  NSString	*mechanism;

  NSAssert(sender == self, NSInvalidArgumentException);

  /*
   * If the requested type is the same as one of the original types,
   * no filtering is required ... and we can just write what we have.
   */
  if ([originalTypes containsObject: type] == YES)
    {
      info = [NSDictionary dictionaryWithObjectsAndKeys:
	@"NSIdentity", @"NSInputMechanism",
        nil];
      filterName = nil;
    }
  else
    {
      NSDictionary	*filters;
      NSEnumerator	*enumerator;

      /*
       * Locate the filter information needed, including the type we are
       * converting from and the name of the filter to use.
       */
      filters = [[GSServicesManager manager] filters];
      enumerator = [filters keyEnumerator];
      while (fromType == nil && (filterName = [enumerator nextObject]) != nil)
	{
	  NSArray	*returnTypes;

	  info = [filters objectForKey: filterName];
	  returnTypes = [info objectForKey: @"NSReturnTypes"];

	  if ([returnTypes containsObject: type] == YES)
	    {
	      NSArray	*sendTypes = [info objectForKey: @"NSSendTypes"];
	      unsigned 	i;

	      for (i = 0; i < [originalTypes count]; i++)
		{
		  fromType = [originalTypes objectAtIndex: i];
		  if ([sendTypes containsObject: fromType] == YES)
		    {
		      break;
		    }
		  fromType = nil;
		}
	    }
	}
    }

  mechanism = [info objectForKey: @"NSInputMechanism"];

  if ([mechanism isEqualToString: @"NSUnixStdio"] == YES)
    {
      NSMutableData	*m = [NSMutableData dataWithCapacity: 1023];
      NSString		*filename;
      NSData		*d;
      NSPipe		*p;
      NSTask		*t;
      id		o;

      /*
       * The data for an NSUnixStdio filter must be one or more filenames
       */
      if ([type isEqualToString: NSFilenamesPboardType] == NO
	&& [type hasPrefix: namePrefix] == NO)
	{
	  [sender setData: [NSData data] forType: type];
	  return;	// Not the name of a file to filter.
	}
      if (data != nil)
	{
	  d = data;
	}
      else if (file != nil)
	{
	  d = [NSData dataWithContentsOfFile: file];
	}
      else
	{
	  d = [pboard dataForType: fromType];
	}

      o = [NSDeserializer deserializePropertyListFromData: d
					mutableContainers: NO];
      if ([o isKindOfClass: [NSString class]] == YES)
	{
	  filename = o;
	}
      else if ([o isKindOfClass: [NSArray class]] == YES
	&& [o count] > 0
	&& [[o objectAtIndex: 0] isKindOfClass: [NSString class]] == YES)
	{
	  filename = [o objectAtIndex: 0];
	}
      else
	{
	  [sender setData: [NSData data] forType: type];
	  return;	// Not the name of a file to filter.
	}

      /*
       * Set up and launch task to filter the named file.
       */
      t = [NSTask new];
      [t setLaunchPath: [info objectForKey: @"NSPortName"]];
      [t setArguments: [NSArray arrayWithObject: filename]];
      p = [NSPipe pipe];
      [t setStandardOutput: p];
      [t launch];

      /*
       * Read all the data that the task writes.
       */
      while ((d = [[p fileHandleForReading] availableData]) != nil)
	{
	  [m appendData: d];
	}
      [t waitUntilExit];
      RELEASE(t);

      /*
       * And send it on.
       */
      [sender setData: m forType: type];
    }
  else if ([mechanism isEqualToString: @"NSIdentity"] == YES
    || [mechanism isEqualToString: @"NSMapFile"] == YES)
    {
      /*
       * An 'identity' filter simply places the required data on the
       * pasteboard.
       */
      if (data != nil)
	{
	  [sender setData: data forType: type];
	}
      else if (file != nil)
	{
	  [sender writeFileContents: file];
	}
      else
	{
	  NSData	*d = [pboard dataForType: type];

	  [sender setData: d forType: type];
	}
    }
  else
    {
      extern BOOL 	GSPerformService(NSString*, NSPasteboard*, BOOL);
      NSPasteboard	*tmp;

      /*
       * Put data onto a pasteboard that can be used by the service provider.
       */
      if (data != nil)
	{
	  tmp = [NSPasteboard pasteboardWithUniqueName];
	  [tmp declareTypes: [NSArray arrayWithObject: fromType] owner: nil];
	  [tmp setData: data forType: fromType];
	}
      else if (file != nil)
	{
	  tmp = [NSPasteboard pasteboardWithUniqueName];
	  [tmp declareTypes: [NSArray arrayWithObject: fromType] owner: nil];
	  [tmp writeFileContents: file];
	}
      else
	{
	  tmp = pboard;		// Already in a pasteboard.
	}

      /*
       * Now get the service provider to do the job.
       */
      GSPerformService(filterName, tmp, YES);

      /*
       * Finally, make it available.
       */
      [sender setData: [tmp dataForType: type] forType: type];
    }
}

@end



@interface NSPasteboard (Private)
+ (id<GSPasteboardSvr>) _pbs;
+ (NSPasteboard*) _pasteboardWithTarget: (id<GSPasteboardObj>)aTarget
				   name: (NSString*)aName;
- (id) _target;
@end

/**
 * <p>The pasteboard system is the primary mechanism for data exchange
 * between OpenStep applications.  It is used for cut and paste of data,
 * as the exchange mechanism for <em>services</em> (as listed on the
 * services menu), for communicating with a spelling server in order to
 * perform spell checking, and for <em>filter services</em> which convert
 * data of one typ to another transparently.
 * </p>
 * <p>Pasteboards are identified by names, some of which are standard
 * and are intended to exist permenantly and be shared between all
 * applications, others are temporary or private and are used to handle
 * specific services.
 * </p>
 * <p>All data transferred to/from pasteboards is <em>typed</em>.  Mostly
 * using one of several standard types for common data or using standardised
 * names which identify particular kinds of files and their contents
 * (see the NSCreateFileContentsPboardType() an
 * NSCreateFilenamePboardType() functions for details).  It is also possible
 * for cooperating applications to use their own private types ... any string
 * value will do.
 * </p>
 * <p>Each pasteboard has an <em>owner</em> ... an object which declares the
 * types of data it can provide.  Unless versions of the pasteboard data
 * corresponding to all the declared types are written to the pasteboard,
 * the owner is responsible for producing the data for the pasteboard when
 * it is called for (lazy provision of data).<br />
 * The pasteboard owner needs to implement the methods of the
 * NSPasteboardOwner informal protocl in order to do this.
 * </p>
 */
@implementation NSPasteboard

static	NSLock			*dictionary_lock = nil;
static	NSMutableDictionary	*pasteboards = nil;
static	id<GSPasteboardSvr>	the_server = nil;
static  NSMapTable              *mimeMap = NULL;

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSPasteboard class])
    {
      // Initial version
      [self setVersion: 1];
      dictionary_lock = [[NSLock alloc] init];
      pasteboards = [[NSMutableDictionary alloc] initWithCapacity: 8];
    }
}

/*
 *	Special method to use a local server rather than connecting over DO
 */
+ (void) _localServer: (id<GSPasteboardSvr>)s
{
  the_server = s;
}

+ (id) _lostServer: (NSNotification*)notification
{
  id	obj = the_server;

  the_server = nil;
  [[NSNotificationCenter defaultCenter]
    removeObserver: self
	      name: NSConnectionDidDieNotification
	    object: [notification object]];
  RELEASE(obj);
  return self;
}

+ (id<GSPasteboardSvr>) _pbs
{
  if (the_server == nil)
    {
      NSString	*host;
      NSString	*description;

      host = [[NSUserDefaults standardUserDefaults] stringForKey: @"NSHost"];
      if (host == nil)
	{
	  host = @"";
	}
      else
	{
	  NSHost	*h;

	  /*
	   * If we have a host specified, but it is the current host,
	   * we do not need to ask for a host by name (nameserver lookup
	   * can be faster) and the empty host name can be used to
	   * indicate that we may start a pasteboard server locally.
	   */
	  h = [NSHost hostWithName: host];
	  if (h == nil)
	    {
	      NSLog(@"Unknown NSHost (%@) ignored", host);
	      host = @"";
	    }
	  else if ([h isEqual: [NSHost currentHost]] == YES)
	    {
	      host = @"";
	    }
	  else
	    {
	      host = [h name];
	    }
	}

      if ([host length] == 0)
	{
	  description = @"local host";
	}
      else
	{
	  description = host;
	}

      the_server = (id<GSPasteboardSvr>)[NSConnection
	rootProxyForConnectionWithRegisteredName: PBSNAME host: host];
      if (the_server == nil && [host length] > 0)
	{
	  NSString	*service;

	  service = [PBSNAME stringByAppendingFormat: @"-%@", host];
	  the_server = (id<GSPasteboardSvr>)[NSConnection
	    rootProxyForConnectionWithRegisteredName: service host: @"*"];
	}

      if (RETAIN((id)the_server) != nil)
	{
	  NSConnection*	conn = [(id)the_server connectionForProxy];

	  [[NSNotificationCenter defaultCenter]
	    addObserver: self
	       selector: @selector(_lostServer:)
		   name: NSConnectionDidDieNotification
		 object: conn];
	}
      else
	{
	  static BOOL		recursion = NO;
	  static NSString	*cmd = nil;
	  static NSArray	*args = nil;

	  if (cmd == nil && recursion ==NO)
	    {
#ifdef GNUSTEP_BASE_LIBRARY
	      cmd = RETAIN([[NSSearchPathForDirectoriesInDomains(
		GSToolsDirectory, NSSystemDomainMask, YES) objectAtIndex: 0]
		stringByAppendingPathComponent: @"gpbs"]);
#else
	      cmd = RETAIN([[@GNUSTEP_INSTALL_PREFIX 
		stringByAppendingPathComponent: @"Tools"] 
		stringByAppendingPathComponent: @"gpbs"]);
#endif
	    }
	  if (recursion == YES || cmd == nil)
	    {
	      NSLog(@"Unable to contact pasteboard server - "
		@"please ensure that gpbs is running for %@.", description);
	      return nil;
	    }
	  else
	    {
	      NSLog(@"\nI couldn't contact the pasteboard server for %@ -\n"
@"so I'm attempting to to start one - which will take a few seconds.\n"
@"Trying to launch gpbs from %@ or a machine/operating-system subdirectory.\n"
@"It is recommended that you start the pasteboard server (gpbs) when\n"
@"your windowing system is started up.\n", description,
[cmd stringByDeletingLastPathComponent]);
	      if ([host length] > 0)
		{
		  args = [[NSArray alloc] initWithObjects:
		    @"-NSHost", host, nil];
		}
	      [NSTask launchedTaskWithLaunchPath: cmd arguments: args];
	      [NSTimer scheduledTimerWithTimeInterval: 5.0
					   invocation: nil
					      repeats: NO];
	      [[NSRunLoop currentRunLoop] runUntilDate: 
		[NSDate dateWithTimeIntervalSinceNow: 5.0]];
	      recursion = YES;
	      [self _pbs];
	      recursion = NO;
	    }
	}
    }
  return the_server;
}

/*
 * Creating and Releasing an NSPasteboard Object
 */
+ (NSPasteboard*) _pasteboardWithTarget: (id<GSPasteboardObj>)aTarget
				   name: (NSString*)aName
{
  NSPasteboard	*p = nil;

  [dictionary_lock lock];
  p = [pasteboards objectForKey: aName];
  if (p != nil)
    {
      /*
       * It is conceivable that the following may have occurred -
       * 1. The pasteboard was created on the server
       * 2. We set up an NSPasteboard to point to it
       * 3. The pasteboard on the server was destroyed by a [-releaseGlobally]
       * 4. The named pasteboard was asked for again - resulting in a new
       *	object being created on the server.
       * If this is the case, our proxy for the object on the server will be
       *	out of date, so we swap it for the newly created one.
       */
      if (p->target != (id)aTarget)
	{
	  AUTORELEASE(p->target);
	  p->target = RETAIN((id)aTarget);
	}
    }
  else
    {
      /*
       * For a newly created NSPasteboard object, we must make an entry
       * in the dictionary so we can look it up safely.
       */
      p = [self alloc];
      if (p != nil)
	{
	  p->target = RETAIN((id)aTarget);
	  p->name = RETAIN(aName);
	  [pasteboards setObject: p forKey: aName];
	  AUTORELEASE(p);
	}
      /*
       * The AUTORELEASE ensures that the NSPasteboard object we are
       * returning will be released once our caller has finished with it.
       * This is necessary so that our RELEASE method will be called to
       * remove the NSPasteboard from the 'pasteboards' array when it is not
       * needed any more.
       */
    }
  [dictionary_lock unlock];
  return p;
}

/**
 * Returns the general pasteboard found by calling +pasteboardWithName:
 * with NSGeneralPboard as the name.
 */
+ (NSPasteboard*) generalPasteboard
{
  return [self pasteboardWithName: NSGeneralPboard];
}

/**
 * <p>Returns the pasteboard for the specified name.  Creates a new pasreboard
 * if (and only if) one with the given name does not exist.
 * </p>
 * Standard pasteboard names are -
 * <list>
 *   <item>NSGeneralPboard</item>
 *   <item>NSFontPboard</item>
 *   <item>NSRulerPboard</item>
 *   <item>NSFindPboard</item>
 *   <item>NSDragPboard</item>
 * </list>
 */
+ (NSPasteboard*) pasteboardWithName: (NSString*)aName
{
  NS_DURING
    {
      id<GSPasteboardObj>	anObj;

      anObj = [[self _pbs] pasteboardWithName: aName];
      if (anObj)
	{
	  NSPasteboard	*ret;

	  ret = [self _pasteboardWithTarget: anObj name: aName];
	  NS_VALRETURN(ret);
	}
    }
  NS_HANDLER
    {
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER

  return nil;
}

/**
 * Creates and returns a new pasteboard with a name guaranteed to be unique
 * within the pasteboard server.
 */
+ (NSPasteboard*) pasteboardWithUniqueName
{
  NS_DURING
    {
      id<GSPasteboardObj>	anObj;

      anObj = [[self _pbs] pasteboardWithName: nil];
      if (anObj)
	{
	  NSString	*aName;

	  aName = [anObj name];
	  if (aName)
	    {
	      NSPasteboard	*ret;

	      ret = [self _pasteboardWithTarget: anObj name: aName];
	      NS_VALRETURN(ret);
	    }
	}
    }
  NS_HANDLER
    {
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER

  return nil;
}

/**
 * <p>Creates and returns a pasteboard from which the data in the named
 * file can be read in all the types to which it can be converted by
 * filter services.<br />
 * The type of data in the file is inferred from the file extension.
 * </p>
 * <p>No filtering is actually performed until some object asks the
 * pasteboard for the data, so calling this method is quite inexpensive.
 * </p>
 */
+ (NSPasteboard*) pasteboardByFilteringData: (NSData*)data
				     ofType: (NSString*)type
{
  FilteredPasteboard	*p;
  NSArray		*types;
  NSArray		*originalTypes;

  originalTypes = [NSArray arrayWithObject: type];
  types = [FilteredPasteboard _typesFilterableFrom: originalTypes];
  p = (FilteredPasteboard*)[FilteredPasteboard pasteboardWithUniqueName];
  p->originalTypes = [originalTypes copy];
  p->data = [data copy];
  [p declareTypes: types owner: p];
  return p;
}

/**
 * <p>Creates and returns a pasteboard from which the data in the named
 * file can be read in all the types to which it can be converted by
 * filter services.<br />
 * The type of data in the file is inferred from the file extension.
 * </p>
 */
+ (NSPasteboard*) pasteboardByFilteringFile: (NSString*)filename
{
  FilteredPasteboard	*p;
  NSString		*ext = [filename pathExtension];
  NSArray		*types;
  NSArray		*originalTypes;

  if ([ext length] > 0)
    {
      originalTypes = [NSArray arrayWithObjects:
	NSCreateFileContentsPboardType(ext),
	NSFileContentsPboardType,
	nil];
    }
  else
    {
      originalTypes = [NSArray arrayWithObject: NSFileContentsPboardType];
    }
  types = [FilteredPasteboard _typesFilterableFrom: originalTypes];
  p = (FilteredPasteboard*)[FilteredPasteboard pasteboardWithUniqueName];
  p->originalTypes = [originalTypes copy];
  p->file = [filename copy];
  [p declareTypes: types owner: p];
  return p;
}

/**
 * <p>Creates and returns a pasteboard where the data contained in pboard
 * is available for reading in as many types as it can be converted to by
 * available filter services.  This normally expands on the range of types
 * available in pboard.
 * </p>
 * <p>NB. This only permits a single level of filtering ... if pboard was
 * previously returned by another filtering method, it is returned instead
 * of a new pasteboard.
 * </p>
 */
+ (NSPasteboard*) pasteboardByFilteringTypesInPasteboard: (NSPasteboard*)pboard
{
  FilteredPasteboard	*p;
  NSArray		*types;
  NSArray		*originalTypes;

  if ([pboard isKindOfClass: [FilteredPasteboard class]] == YES)
    {
      return pboard;
    }
  originalTypes = [pboard types];
  types = [FilteredPasteboard _typesFilterableFrom: originalTypes];
  p = (FilteredPasteboard*)[FilteredPasteboard pasteboardWithUniqueName];
  p->originalTypes = [originalTypes copy];
  p->pboard = RETAIN(pboard);
  [p declareTypes: types owner: p];
  return p;
}

/**
 * Returns an array of the types from which data of the specified type
 * can be produced by registered filter services.<br />
 * The original type is always present in this array.<br />
 * Raises an exception if type is nil.
 */
+ (NSArray*) typesFilterableTo: (NSString*)type
{
  NSMutableSet	*types = [NSMutableSet setWithCapacity: 8];
  NSDictionary	*info = [[GSServicesManager manager] filters];
  NSEnumerator	*enumerator = [info objectEnumerator];

  [types addObject: type];	// Always include original type

  /*
   * Step through the filters looking for those which handle the type
   */
  while ((info = [enumerator nextObject]) != nil)
    {
      NSArray	*returnTypes = [info objectForKey: @"NSReturnTypes"];

      if ([returnTypes containsObject: type] == YES)
	{
	  NSArray	*sendTypes = [info objectForKey: @"NSSendTypes"];

	  [types addObjectsFromArray: sendTypes];
	}
    }

  return [types allObjects];
}

/*
 * Instance methods
 */

- (id) _target
{
  return target;
}

/*
 * Creating and Releasing an NSPasteboard Object
 */

- (void) dealloc
{
  RELEASE(target);
  RELEASE(name);
  [super dealloc];
}

/**
 * Releases the receiver in the pasteboard server so that no other application
 * can use the pasteboard.  This should not be called for any of the standard
 * pasteboards, only for temporary ones.
 */
- (void) releaseGlobally
{
  if ([name isEqualToString: NSGeneralPboard] == YES
    || [name isEqualToString: NSFontPboard] == YES
    || [name isEqualToString: NSRulerPboard] == YES
    || [name isEqualToString: NSFindPboard] == YES
    || [name isEqualToString: NSDragPboard] == YES)
    {
      [NSException raise: NSGenericException
		  format: @"Illegal attempt to globally release %@", name];
    }
  [target releaseGlobally];
  [pasteboards removeObjectForKey: name];
}

/**
 * Returns the pasteboard name for the receiver.
 */
- (NSString*) name
{
  return name;
}

/**
 * <p>Adds newTypes to the pasteboard and declares newOwner to be the owner
 * of the pasteboard.  Use only after -declareTypes:owner: has been called
 * for the same owner, because the new owner may not support all the types
 * declared by a previous owner.
 * </p>
 * <p>Returns the new change count for the pasteboard, or zero if an error
 * occurs.
 * </p>
 */
- (int) addTypes: (NSArray*)newTypes
	   owner: (id)newOwner
{
  int	count = 0;

  NS_DURING
    {
      count = [target addTypes: newTypes
			 owner: newOwner
		    pasteboard: self
		      oldCount: changeCount];
      if (count > 0)
	{
	  changeCount = count;
	}
    }
  NS_HANDLER
    {
      count = 0;
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER
  return count;
}

/**
 * <p>Sets the owner of the pasteboard to be newOwner and declares newTypes
 * as the types of data supported by it.<br />
 * This invalidates existing data in the pasteboard (except where the GNUstep
 * -setHistory: extension allows multi-version data to be held).
 * </p>
 * <p>The value of newOwner may be nil, but if it is, data should
 * immediately be written to the pasteboard for all the value in newTypes
 * as a nil owner cannot be used for lazy supply of data.
 * </p>
 * <p>This increments the change count for the pasteboard and the new
 * count is returned, or zero is returned if an error occurs.<br />
 * Where -setChangeCount: has been used, the highest count to date
 * is incremented and returned, rather than the last value specified
 * by the -setChangeCount: method.
 * </p>
 */
- (int) declareTypes: (NSArray*)newTypes
	       owner: (id)newOwner
{
  NS_DURING
    {
      changeCount = [target declareTypes: newTypes
				   owner: newOwner
			      pasteboard: self];
    }
  NS_HANDLER
    {
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER
  return changeCount;
}

/*
 *	Hack to ensure correct release of NSPasteboard objects -
 *	If we are released such that the only thing retaining us
 *	is the pasteboards dictionary, remove us from that dictionary
 *	as well.
 */
- (void) release
{
  if ([self retainCount] == 2)
    {
      [dictionary_lock lock];
      RETAIN(super);
      [pasteboards removeObjectForKey: name];
      RELEASE(super);
      [dictionary_lock unlock];
    }
  RELEASE(super);
}

/**
 * <p>Writes data of type dataType to the pasteboard server so that other
 * applications can read it.  The dataType must be one of the types
 * previously declared for the pasteboard.<br />
 * All the other methods for writing data to the pasteboard call this one.
 * </p>
 * <p>Returns YES on success, NO if the data could not be written for some
 * reason.
 * </p>
 */
- (BOOL) setData: (NSData*)data
	 forType: (NSString*)dataType
{
  BOOL	ok = NO;

  NS_DURING
    {
      ok = [target setData: data
		   forType: dataType
		    isFile: NO
		  oldCount: changeCount];
    }
  NS_HANDLER
    {
      ok = NO;
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER
  return ok;
}

/**
 * <p>Serialises the data in the supplied property list and writes it to the
 * pasteboard server using the -setData:forType: method.
 * </p>
 * <p>Data written using this method can be read by -propertyListForType:
 * or, if it was a simple string, by -stringForType:
 * </p>
 * <p>If the data is retrieved using -dataForType: then it needs to be
 * deserialized into a property list.
 * </p>
 */
- (BOOL) setPropertyList: (id)propertyList
		 forType: (NSString*)dataType
{
  NSData	*d = [NSSerializer serializePropertyList: propertyList];

  return [self setData: d forType: dataType];
}

/**
 * <p>Writes  string it to the pasteboard server using the
 * -setPropertyList:forType: method.
 * </p>
 * <p>The data may subsequently be read from the reciver using the
 * -stringForType: or -propertyListForType: method.
 * </p>
 * <p>If the data is retrieved using -dataForType: then it needs to be
 * deserialized into a property list.
 * </p>
 */
- (BOOL) setString: (NSString*)string
	   forType: (NSString*)dataType
{
  return [self setPropertyList: string forType: dataType];
}

/**
 * <p>Writes the contents of the file filename to the pasteboard server
 * after declaring the type NSFileContentsPboardType as well as a type
 * based on the file extension (given by the NSCreateFileContentsPboardType()
 * function) if those types have not already been declared.<br />
 * If the filename has no extension, only NSFileContentsPboardType is used.
 * </p>
 * <p>Data written to a pasteboard by this method should be read using
 * the -readFileContentsType:toFile: or -readFileWrapper method.
 * </p>
 * <p>If the data is retrieved using -dataForType: then it needs to be
 * deserialized by the NSFileWrapper class.
 * </p>
 */
- (BOOL) writeFileContents: (NSString*)filename
{
  NSFileWrapper *wrapper;
  NSData	*data;
  NSArray	*types;
  NSString	*ext = [filename pathExtension];
  BOOL		ok = NO;

  wrapper = [[NSFileWrapper alloc] initWithPath: filename];
  data = [wrapper serializedRepresentation];
  RELEASE(wrapper);
  if ([ext length] > 0)
    {
      types = [NSArray arrayWithObjects: NSFileContentsPboardType,
	NSCreateFileContentsPboardType(ext), nil];
    }
  else
    {
      types = [NSArray arrayWithObject: NSFileContentsPboardType];
    }
  if ([[self types] isEqual: types] == NO)
    {
      if ([self declareTypes: types owner: owner] == 0)
	{
	  return NO;	// Unable to declare types.
	}
    }
  NS_DURING
    {
      ok = [target setData: data
		   forType: NSFileContentsPboardType
		    isFile: YES
		  oldCount: changeCount];
    }
  NS_HANDLER
    {
      ok = NO;
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER
  return ok;
}

/**
 * <p>Writes the contents of the file wrapper to the pasteboard server
 * after declaring the type NSFileContentsPboardType as well as a type
 * based on the file extension of the wrappers preferred filename if 
 * those types have not already been declared.
 * </p>
 * <p>Raises an exception if there is no preferred filename.
 * </p>
 * <p>Data written to a pasteboard by this method should be read using
 * the -readFileContentsType:toFile: or -readFileWrapper method.
 * </p>
 * <p>If the data is retrieved using -dataForType: then it needs to be
 * deserialized by the NSFileWrapper class.
 * </p>
 */
- (BOOL) writeFileWrapper: (NSFileWrapper *)wrapper
{
  NSString	*filename = [wrapper preferredFilename];
  NSData	*data;
  NSArray	*types;
  NSString	*ext = [filename pathExtension];
  BOOL		ok = NO;

  if (filename == nil)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"Cannot put file on pastboard with "
	@"no preferred filename"];
    }
  data = [wrapper serializedRepresentation];
  if ([ext length] > 0)
    {
      types = [NSArray arrayWithObjects: NSFileContentsPboardType,
	NSCreateFileContentsPboardType(ext), nil];
    }
  else
    {
      types = [NSArray arrayWithObject: NSFileContentsPboardType];
    }
  if ([[self types] isEqual: types] == NO)
    {
      if ([self declareTypes: types owner: owner] == 0)
	{
	  return NO;	// Unable to declare types.
	}
    }
  NS_DURING
    {
      ok = [target setData: data
		   forType: NSFileContentsPboardType
		    isFile: YES
		  oldCount: changeCount];
    }
  NS_HANDLER
    {
      ok = NO;
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER
  return ok;
}

/**
 * Returns the first type listed in types which the receiver has been
 * declared to support.
 */
- (NSString*) availableTypeFromArray: (NSArray*)types
{
  NSString *type = nil;

  NS_DURING
    {
      int	count = 0;

      type = [target availableTypeFromArray: types
				changeCount: &count];
      changeCount = count;
    }
  NS_HANDLER
    {
      type = nil;
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER
  return type;
}

/**
 * Returns all the types that the receiver has been declared to support.
 */
- (NSArray*) types
{
  NSArray *result = nil;

  NS_DURING
    {
      int	count = 0;

      result = [target typesAndChangeCount: &count];
      changeCount = count;
    }
  NS_HANDLER
    {
      result = nil;
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER
  return result;
}

/**
 * Returns the change count for the receiving pasteboard.  This count
 * is incremented whenever the owner of the pasteboard is changed.
 */
- (int) changeCount
{
  NS_DURING
    {
      int	count;

      count = [target changeCount];
      changeCount = count;
    }
  NS_HANDLER
    {
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER
  return changeCount;
}

/**
 * Returns data from the pasteboard of the specified dataType, or nil
 * if no such data is available.<br />
 * May raise an exception if communication with the pasteboard server fails.
 */
- (NSData*) dataForType: (NSString*)dataType
{
  NSData	*d = nil;

  NS_DURING
    {
      d = [target dataForType: dataType
		     oldCount: changeCount
		mustBeCurrent: (useHistory == NO) ? YES : NO];
    }
  NS_HANDLER
    {
      d = nil;
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER
  return d;
}

/**
 * Calls -dataForType: to obtain data (expected to be a serialized property
 * list) and returns the object produced by deserializing it.
 */
- (id) propertyListForType: (NSString*)dataType
{
  NSData	*d = [self dataForType: dataType];

  if (d)
    return [NSDeserializer deserializePropertyListFromData: d
					 mutableContainers: NO];
  else
    return nil;
}

/**
 * <p>Obtains data of the specified dataType from the pasteboard, deserializes
 * it to the specified filename and returns the file name (or nil on failure).
 * </p>
 * <p>This method should only be used to read data written by
 * the -writeFileContents: or -writeFileWrapper method.
 * </p>
 */
- (NSString*) readFileContentsType: (NSString*)type
			    toFile: (NSString*)filename
{
  NSData	*d;
  NSFileWrapper *wrapper;

  if (type == nil)
    {
      type = NSCreateFileContentsPboardType([filename pathExtension]);
    }
  d = [self dataForType: type];
  if (d == nil)
    {
      d = [self dataForType: NSFileContentsPboardType];
      if (d == nil)
	return nil;
    }

  wrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation: d];
  if ([wrapper writeToFile: filename atomically: NO updateFilenames: NO] == NO)
    {
      RELEASE(wrapper);
      return nil;
    }
  RELEASE(wrapper);
  return filename;
}

/**
 * <p>Obtains data of the specified dataType from the pasteboard, deserializes
 * it and returns the resulting file wrapper (or nil).
 * </p>
 * <p>This method should only be used to read data written by
 * the -writeFileContents: or -writeFileWrapper method.
 * </p>
 */
- (NSFileWrapper*) readFileWrapper
{
  NSData *d = [self dataForType: NSFileContentsPboardType];

  if (d == nil)
    return nil;

  return
    AUTORELEASE([[NSFileWrapper alloc] initWithSerializedRepresentation: d]);
}

/**
 * <p>Obtains data of the specified dataType from the pasteboard, deserializes
 * it and returns the resulting string (or nil).
 * </p>
 * <p>The string should have been written using the -setString:forType: or
 * -setPropertyList:forType: method.
 * </p>
 */
- (NSString*) stringForType: (NSString*)dataType
{
  NSString	*s = [self propertyListForType: dataType];

  if ([s isKindOfClass: [NSString class]] == NO)
    {
      s = nil;
    }
  return s;
}

@end



/**
 * GNUstep specific extensions ...<br />
 * <p>GNUstep adds a mechanism for mapping between OpenStep pasteboard
 * types and MIME types.  This is useful for interopration with other
 * systems, as MIME types have come into common usage (long after the
 * OpenStep specification was created).
 * </p>
 * <p>The other extension to the pasteboard system produced by GNUstep
 * is the ability to keep a history of recent items placed in a
 * pasteboard, and retrieve data from that history rather than just
 * the current item.
 * </p>
 */
@implementation NSPasteboard (GNUstepExtensions)

/**
 * <p>Once the -setChangeCount: message has been sent to an NSPasteboard
 * the object will gain an extra GNUstep behaviour - when geting data
 * from the pasteboard, the data need no longer be from the latest
 * version but may be a version from a previous representation with
 * the specified change count.
 * </p>
 * <p>The value of count must be one which has previously been returned
 * by -declareTypes:owner: and should not be further in the past than
 * specified by the -setHistory: method.
 * </p>
 */
- (void) setChangeCount: (int)count
{
  useHistory = YES;
  changeCount = count;
}

/**
 * Sets the number of changes for which pasteboard data is kept.<br />
 * This is 1 by default.
 */
- (void) setHistory: (unsigned)length
{
  NS_DURING
    {
      [target setHistory: length];
    }
  NS_HANDLER
    {
      [NSException raise: NSPasteboardCommunicationException
		  format: @"%@", [localException reason]];
    }
  NS_ENDHANDLER
}

+ (void) _initMimeMappings
{
  mimeMap = NSCreateMapTable(NSObjectMapKeyCallBacks,
    NSObjectMapValueCallBacks, 0);

  NSMapInsert(mimeMap, (void *)NSStringPboardType,
    (void *)@"text/plain");
  NSMapInsert(mimeMap, (void *)NSFileContentsPboardType, 
    (void *)@"text/plain");
  NSMapInsert(mimeMap, (void *)NSFilenamesPboardType, 
    (void *)@"text/uri-list");
  NSMapInsert(mimeMap, (void *)NSPostScriptPboardType, 
    (void *)@"application/postscript");
  NSMapInsert(mimeMap, (void *)NSTabularTextPboardType, 
    (void *)@"text/tab-separated-values");
  NSMapInsert(mimeMap, (void *)NSRTFPboardType,
    (void *)@"text/richtext");
  NSMapInsert(mimeMap, (void *)NSTIFFPboardType,
    (void *)@"image/tiff");
  NSMapInsert(mimeMap, (void *)NSGeneralPboardType,
    (void *)@"text/plain");
}

/**
 * Return the mapping for pasteboard->mime, or return the original pasteboard
 * type if no mapping is found
 */
+ (NSString *) mimeTypeForPasteboardType: (NSString *)type
{
  NSString	*mime;

  if (mimeMap == NULL)
    {
      [self _initMimeMappings];
    }
  mime = NSMapGet(mimeMap, (void *)type);
  if (mime == nil)
    {
      mime = type;
    }
  return mime;
}

/**
 * Return the mapping for mime->pasteboard, or return the original pasteboard
 * type if no mapping is found. This method may not have a one-to-one 
 * mapping
 */
+ (NSString *) pasteboardTypeForMimeType: (NSString *)mimeType
{
  BOOL			found;
  NSString		*type;
  NSString		*mime;
  NSMapEnumerator	enumerator;
  
  if (mimeMap == NULL)
    {
      [self _initMimeMappings];
    }
  enumerator = NSEnumerateMapTable(mimeMap);
  while ((found = NSNextMapEnumeratorPair(&enumerator, 
    (void **)(&type), (void **)(&mime))))
    {
      if ([mimeType isEqual: mime])
	{
	  break;
	}
    }

  if (found == NO)
    {
      type = mimeType;
    }
  return type;
}

@end

/**
 * Category of NSURL providing convenience methods.
 */
@implementation NSURL (NSPasteboard)
/**
 * Creates a URL with data (of NSURLPboardType) from pasteBoard.
 */
+ (NSURL *) URLFromPasteboard: (NSPasteboard *)pasteBoard
{
  return [self URLWithString: [pasteBoard stringForType: NSURLPboardType]];
}

/**
 * Writes the receiver (as data of NSURLPboardType) to pasteBoard.
 */
- (void) writeToPasteboard: (NSPasteboard *)pasteBoard
{
  [pasteBoard setString: [self absoluteString]
		forType: NSURLPboardType];
}

@end


/**
 * <p>Returns a standardised pasteboard type for file contents,
 * formed from the supplied file extension.
 * </p>
 * <p>Data written to a pasteboard with a file contents type should
 * be written using the [NSPasteboard-writeFileContents:] or
 * [NSPasteboard-writeFileWrapper:] method.  Similarly, the data should
 * be read using the [NSPasteboard-readFileContentsType:toFile:] or
 * [NSPasteboard-readFileWrapper] method.
 * </p>
 */
NSString*
NSCreateFileContentsPboardType(NSString *fileType)
{
  NSString	*ext = [fileType pathExtension];

  if ([ext length] == 0)
    {
      ext = fileType;
    }
  return [NSString stringWithFormat: @"%@%@", contentsPrefix, ext];
}

/**
 * <p>Returns a standardised pasteboard type for file names,
 * formed from the supplied file extension.
 * </p>
 * <p>Data written to a pasteboard with a file names type should
 * be a single name writen using [NSPasteboard-setString:forType:] or
 * an array of strings written using
 * [NSPasteboard-setPropertyList:forType:].<br />
 * Similarly, the data should be read using 
 * the [NSPasteboard-stringForType:] or
 * [NSPasteboard-propertyListForType:] method.
 * </p>
 * <p>See also the NSGetFileType() and NSGetFileTypes() functions.
 */
NSString*
NSCreateFilenamePboardType(NSString *fileType)
{
  NSString	*ext = [fileType pathExtension];

  if ([ext length] == 0)
    {
      ext = fileType;
    }
  return [NSString stringWithFormat: @"%@%@", namePrefix, ext];
}

/**
 * Returns the file type (fileType extension) corresponding to the
 * pasteboard type given.<br />
 * This is a counterpart to the NSCreateFilenamePboardType() function.
 */
NSString*
NSGetFileType(NSString *pboardType)
{
  if ([pboardType hasPrefix: contentsPrefix])
    {
      return [pboardType substringFromIndex: [contentsPrefix length]];
    }
  if ([pboardType hasPrefix: namePrefix])
    {
      return [pboardType substringFromIndex: [namePrefix length]];
    }
  return nil;
}

/**
 * Returns the file types (filename extensions) corresponding to the
 * pasteboard types given.
 */
NSArray*
NSGetFileTypes(NSArray *pboardTypes)
{
  NSMutableArray *a = [NSMutableArray arrayWithCapacity: [pboardTypes count]];
  unsigned int	i;

  for (i = 0; i < [pboardTypes count]; i++)
    {
      NSString	*s = NSGetFileType([pboardTypes objectAtIndex: i]);

      if (s && ! [a containsObject: s])
	{
	  [a addObject: s];
	}
    }
  if ([a count] > 0)
    {
      return AUTORELEASE([a copy]);
    }
  return nil;
}

