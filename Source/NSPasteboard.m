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

/*
 * A pasteboard class for lazily filtering data
 */
@interface FilteredPasteboard : NSPasteboard
{
@public
  NSArray	*originalTypes;
  NSData	*data;
  NSString	*file;
  NSPasteboard	*pboard;
}
@end

@implementation	FilteredPasteboard
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
  DESTROY(file);
  DESTROY(pboard);
  [super dealloc];
}

/**
 * This method actually performs any filtering required.
 */
- (void) pasteboard: (NSPasteboard*)sender
 provideDataForType: (NSString*)type
{
  /*
   * If the requested type is the same as one of the original types,
   * no filtering is required ... and we can just write what we have.
   */
  if ([originalTypes containsObject: type] == YES)
    {
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
// FIXME
    }
}

@end



@interface NSPasteboard (Private)
+ (id<GSPasteboardSvr>) _pbs;
+ (NSPasteboard*) _pasteboardWithTarget: (id<GSPasteboardObj>)aTarget
				   name: (NSString*)aName;
- (id) _target;
@end

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

      anObj = [[self _pbs] pasteboardWithUniqueName];
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
 * <p>Returns a pasteboard from which the data (of the specified type)
 * can be read in all the types to which it can be converted by
 * filter services.
 * </p>
 * <p>Also registers the pasteboard as providing information of the
 * specified type.
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
 * as the types of data supported by it.
 * </p>
 * <p>Returns the new change count for the pasteboard, or zero if an error
 * occurs.
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
 * previously declared for the pasteboard.
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
 * Serialises the data in the supplied property list and writes it to the
 * pasteboard server using the -setData:forType: method.
 */
- (BOOL) setPropertyList: (id)propertyList
		 forType: (NSString*)dataType
{
  NSData	*d = [NSSerializer serializePropertyList: propertyList];

  return [self setData: d forType: dataType];
}

/**
 * Writes  string it to the pasteboard server using the
 * -setPropertyList:forType: method.
 */
- (BOOL) setString: (NSString*)string
	   forType: (NSString*)dataType
{
  return [self setPropertyList: string forType: dataType];
}

/**
 * Writes the contents of the file filename to the pasteboard server
 * after declaring the type NSFileContentsPboardType as well as a type
 * based on the file extension (given by the NSCreateFileContentsPboardType()
 * function) if there is one.
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
  if ([self declareTypes: types owner: owner] == 0)
    {
      return NO;	// Unable to declare types.
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
 * based on the file extension of the wrappers preferred filename.
 * </p>
 * <p>Raises an exception if there is no preferred filename.
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
  if ([self declareTypes: types owner: owner] == 0)
    {
      return NO;	// Unable to declare types.
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
 * Obtains data of the specified dataType from the pasteboard, deserializes
 * it to the specified filename and returns the file name (or nil on failure).
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
 * Obtains data of the specified dataType from the pasteboard, deserializes
 * it and returns the resulting file wrapper (or nil).
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
 * Obtains data of the specified dataType from the pasteboard, deserializes
 * it and returns the resulting string (or nil).
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

/*
 * Methods Implemented by the Owner 
 */
- (void) pasteboard: (NSPasteboard*)sender
 provideDataForType: (NSString*)type
{
}

- (void) pasteboard: (NSPasteboard*)sender
 provideDataForType: (NSString*)type
	 andVersion: (int)version
{
}

- (void) pasteboardChangedOwner: (NSPasteboard*)sender
{
}

@end

@implementation NSPasteboard (GNUstepExtensions)

/**
 * Once the -setChangeCount: message has been sent to an NSPasteboard
 * the object will gain an extra GNUstep behaviour - when geting data
 * from the pasteboard, the data need no longer be from the latest
 * version but may be a version from a previous representation with
 * the specified change count.
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

@implementation NSURL (NSPasteboard)
+ (NSURL *) URLFromPasteboard: (NSPasteboard *)pasteBoard
{
  return [self URLWithString: [pasteBoard stringForType: NSURLPboardType]];
}

- (void) writeToPasteboard: (NSPasteboard *)pasteBoard
{
  [pasteBoard setString: [self absoluteString]
	      forType: NSURLPboardType];
}

@end


static NSString*	contentsPrefix = @"NSTypedFileContentsPboardType:";
static NSString*	namePrefix = @"NSTypedFilenamesPboardType:";

/**
 * Returns a standardised pasteboard type for file contents,
 * formed from the supplied file extension.
 */
NSString*
NSCreateFileContentsPboardType(NSString *fileType)
{
  return [NSString stringWithFormat: @"%@%@", contentsPrefix, fileType];
}

/**
 * Returns a standardised pasteboard type for file names,
 * formed from the supplied file extension.
 */
NSString*
NSCreateFilenamePboardType(NSString *filename)
{
  return [NSString stringWithFormat: @"%@%@", namePrefix, filename];
}

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

