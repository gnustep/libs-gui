/* 
   NSPasteboard.m

   Description...	Implementation of class for communicating with the
			pasteboard server.

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
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

#include <AppKit/NSPasteboard.h>
#include <AppKit/PasteboardServer.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSConnection.h>
#include <Foundation/NSDistantObject.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSException.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSSerialization.h>
#include <Foundation/NSUserDefaults.h>

// Pasteboard Type Globals 
NSString *NSStringPboardType = @"NSStringPboardType";
NSString *NSColorPboardType = @"NSColorPboardType";
NSString *NSFileContentsPboardType = @"NSFileContentsPboardType";
NSString *NSFilenamesPboardType = @"NSFilenamesPboardType";
NSString *NSFontPboardType = @"NSFontPboardType";
NSString *NSRulerPboardType = @"NSRulerPboardType";
NSString *NSPostScriptPboardType = @"NSPostScriptPboardType";
NSString *NSTabularTextPboardType = @"NSTabularTextPboardType";
NSString *NSRTFPboardType = @"NSRTFPboardType";
NSString *NSTIFFPboardType = @"NSTIFFPboardType";
NSString *NSDataLinkPboardType = @"NSDataLinkPboardType";
NSString *NSGeneralPboardType = @"NSGeneralPboardType";

// Pasteboard Name Globals 
NSString *NSDragPboard = @"NSDragPboard";
NSString *NSFindPboard = @"NSFindPboard";
NSString *NSFontPboard = @"NSFontPboard";
NSString *NSGeneralPboard = @"NSGeneralPboard";
NSString *NSRulerPboard = @"NSRulerPboard";

//
// Pasteboard Exceptions
//
NSString *NSPasteboardCommunicationException
= @"NSPasteboardCommunicationException";

@interface NSPasteboard (Private)
+ (id<PasteboardServer>) _pbs;
+ (NSPasteboard*) _pasteboardWithTarget: (id<PasteboardObject>)aTarget
				   name: (NSString*)aName;
- (id) _target;
@end

@implementation NSPasteboard

static	NSLock			*dictionary_lock = nil;
static	NSMutableDictionary	*pasteboards = nil;
static	id<PasteboardServer>	the_server = nil;


//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPasteboard class])
    {
      // Initial version
      [self setVersion:1];
      dictionary_lock = [[NSLock alloc] init];
      pasteboards = [[NSMutableDictionary alloc] initWithCapacity:8];
    }
}

+ _lostServer: notification
{
  id	obj = the_server;

  the_server = nil;
  [NSNotificationCenter removeObserver: self
              			  name: NSConnectionDidDieNotification
              			object: [notification object]];
  [obj release];
  return self;
}

+ (id<PasteboardServer>) _pbs
{
  if (the_server == nil) {
    NSString*	host;

    host = [[NSUserDefaults standardUserDefaults] stringForKey: @"NSHost"];
    if (host == nil) {
      host = [[NSProcessInfo processInfo] hostName];
    }
    the_server = (id<PasteboardServer>)[NSConnection
	rootProxyForConnectionWithRegisteredName: PBSNAME
					    host: host];
    if ([(id)the_server retain]) {
      NSConnection*	conn = [(id)the_server connectionForProxy];

      [NSNotificationCenter
              addObserver: self
              selector: @selector(_lostServer:)
              name: NSConnectionDidDieNotification
              object: conn];
    }
  }
  return the_server;
}

//
// Creating and Releasing an NSPasteboard Object
//
+ (NSPasteboard*) _pasteboardWithTarget: (id<PasteboardObject>)aTarget
				   name: (NSString*)aName
{
  NSPasteboard*	p = nil;

  [dictionary_lock lock];
  p = [pasteboards objectForKey: aName];
  if (p) {
    /*
     *	It is conceivable that the following may have occurred -
     *	1. The pasteboard was created on the server
     *	2. We set up an NSPasteboard to point to it
     *	3. The pasteboard on the server was destroyed by a [-releaseGlobally]
     *	4. The named pasteboard was asked for again - resulting in a new
     *		object being created on the server.
     *	If this is the case, our proxy for the object on the server will be
     *	out of date, so we swap it for the newly created one.
     */
    if (p->target != aTarget) {
      [p->target autorelease];
      p->target = [(id)aTarget retain];
    }
  }
  else {
    /*
     *	For a newly created NSPasteboard object, we must make an entry
     *	in the dictionary so we can look it up safely.
     */
    p = [NSPasteboard alloc];
    if (p) {
      p->target = [(id)aTarget retain];
      p->name = [aName retain];
      [pasteboards setObject:p forKey:aName];
      [p autorelease];
    }
    /*
     *	The [-autorelease] message ensures that the NSPasteboard object we are
     *	returning will be released once our caller has finished with it.
     *	This is necessary so that our [-release] method will be called to
     *	remove the NSPasteboard from the 'pasteboards' array when it is not
     *	needed any more.
     */
  }
  [dictionary_lock unlock];
  return p;
}

+ (NSPasteboard *)generalPasteboard
{
  return [self pasteboardWithName: NSGeneralPboard];
}

+ (NSPasteboard *)pasteboardWithName:(NSString *)aName
{
  id<PasteboardObject>	anObj = nil;

  NS_DURING
  {
    anObj = [[self _pbs] pasteboardWithName: aName];
  }
  NS_HANDLER
  {
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  if (anObj) {
    return [self _pasteboardWithTarget:anObj name:aName];
  }
  return nil;
}

+ (NSPasteboard *)pasteboardWithUniqueName
{
  id<PasteboardObject>	anObj = nil;
  NSString		*aName = nil;

  NS_DURING
  {
    anObj = [[self _pbs] pasteboardWithUniqueName];
    aName = [anObj name];
  }
  NS_HANDLER
  {
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  if (anObj) {
    return [self _pasteboardWithTarget:anObj name:aName];
  }
  return nil;
}

//
// Getting Data in Different Formats 
//
+ (NSPasteboard *)pasteboardByFilteringData:(NSData *)data
				     ofType:(NSString *)type
{
  id<PasteboardObject>	anObj = nil;
  NSString 		*aName = nil;

  NS_DURING
  {
    anObj = [[self _pbs] pasteboardByFilteringData: data
					     ofType: type
					     isFile: NO];
    aName = [anObj name];
  }
  NS_HANDLER
  {
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  if (anObj) {
    return [self _pasteboardWithTarget:anObj name: aName];
  }
  return nil;
}

+ (NSPasteboard *)pasteboardByFilteringFile:(NSString *)filename
{
  id<PasteboardObject>	anObj = nil;
  NSString*	aName = nil;
  NSData*	data = [NSData dataWithContentsOfFile:filename];
  NSString*	type = NSCreateFileContentsPboardType([filename pathExtension]);

  NS_DURING
  {
    anObj = [[self _pbs] pasteboardByFilteringData: data
					     ofType: type
					     isFile: YES];
    aName = [anObj name];
  }
  NS_HANDLER
  {
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  if (anObj) {
    return [self _pasteboardWithTarget:anObj name: aName];
  }
  return nil;
}

+ (NSPasteboard *)pasteboardByFilteringTypesInPasteboard:(NSPasteboard *)pboard
{
  id<PasteboardObject>	anObj = nil;
  NSString		*aName = nil;

  NS_DURING
  {
    anObj = [pboard _target];
    anObj = [[self _pbs] pasteboardByFilteringTypesInPasteboard: anObj];
    aName = [anObj name];
  }
  NS_HANDLER
  {
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  if (anObj) {
    return [self _pasteboardWithTarget:anObj name: aName];
  }
  return nil;
}

+ (NSArray *)typesFilterableTo:(NSString *)type
{
  NSArray*	types = nil;

  NS_DURING
  {
    types = [[self _pbs] typesFilterableTo: type];
  }
  NS_HANDLER
  {
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  return types;
}

//
// Instance methods
//

- (id) _target
{
  return target;
}

//
// Creating and Releasing an NSPasteboard Object
//

- (void) dealloc
{
  [target release];
  [name release];
  [self dealloc];
}

- (void) releaseGlobally
{
    [target releaseGlobally];
    [pasteboards removeObjectForKey: name];
}

//
// Referring to a Pasteboard by Name 
//
- (NSString *)name
{
  return name;
}

//
// Writing Data 
//
- (int)addTypes:(NSArray *)newTypes
	  owner:(id)newOwner
{
  int	count = 0;

  NS_DURING
  {
    count = [target addTypes: newTypes
		       owner: newOwner
		  pasteboard: self
		    oldCount: changeCount];
    if (count > 0) {
      changeCount = count;
    }
  }
  NS_HANDLER
  {
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  return count;
}

- (int)declareTypes:(NSArray *)newTypes
	      owner:(id)newOwner
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
		format: @"%s", [[localException reason] cString]];
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
  if ([self retainCount] == 2) {
    [dictionary_lock lock];
    [super retain];
    [pasteboards removeObjectForKey: name];
    [super release];
    [dictionary_lock unlock];
  }
  [super release];
}

- (BOOL)setData:(NSData *)data
	forType:(NSString *)dataType
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
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  return ok;
}

- (BOOL)setPropertyList:(id)propertyList
		forType:(NSString *)dataType
{
  NSData*	d = [NSSerializer serializePropertyList: propertyList];

  return [self setData: d forType: dataType];
}

- (BOOL)setString:(NSString *)string
	  forType:(NSString *)dataType
{
  return [self setPropertyList: string forType: dataType];
}

- (BOOL)writeFileContents:(NSString *)filename
{
  NSData*	data = [NSData dataWithContentsOfFile:filename];
  NSString*	type = NSCreateFileContentsPboardType([filename pathExtension]);
  BOOL	ok = NO;

  NS_DURING
  {
    ok = [target setData: data
		 forType: type
		  isFile: YES
		oldCount: changeCount];
  }
  NS_HANDLER
  {
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  return ok;
}

//
// Determining Types 
//
- (NSString *)availableTypeFromArray:(NSArray *)types
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
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  return type;
}

- (NSArray *)types
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
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  return result;
}

//
// Reading Data 
//
- (int)changeCount
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
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  return changeCount;
}

- (NSData *)dataForType:(NSString *)dataType
{
  NSData*	d = nil;

  NS_DURING
  {
    d = [target dataForType: dataType
		   oldCount: changeCount
	      mustBeCurrent: useHistory];
  }
  NS_HANDLER
  {
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
  return d;
}

- (id)propertyListForType:(NSString *)dataType
{
  NSData*	d = [self dataForType: dataType];

  return [NSDeserializer deserializePropertyListFromData: d
				       mutableContainers: NO];
}

- (NSString *)readFileContentsType:(NSString *)type
			    toFile:(NSString *)filename
{
  NSData*	d;

  if (type == nil) {
    type = NSCreateFileContentsPboardType([filename pathExtension]);
  }
  d = [self dataForType: type];
  if ([d writeToFile: filename atomically: NO] == NO) {
    return nil;
  }
  return filename;
}

- (NSString *)stringForType:(NSString *)dataType
{
  return [self propertyListForType: dataType];
}

//
// Methods Implemented by the Owner 
//
- (void)pasteboard:(NSPasteboard *)sender
provideDataForType:(NSString *)type
{}

- (void)pasteboardChangedOwner:(NSPasteboard *)sender
{}

@end

@implementation NSPasteboard (GNUstepExtensions)

/*
 *	Once the '[-setChangeCount:]' message has been sent to an NSPasteboard
 *	the object will gain an extra GNUstep behaviour - when geting data
 *	from the pasteboard, the data need no longer be from the latest
 *	version but may be a version from a previous representation with
 *	the specified change count.
 */
- (void) setChangeCount: (int)count
{
  useHistory = YES;
  changeCount = count;
}

- (void) setHistory: (unsigned)length
{
  NS_DURING
  {
    [target setHistory: length];
  }
  NS_HANDLER
  {
    [NSException raise: NSPasteboardCommunicationException
		format: @"%s", [[localException reason] cString]];
  }
  NS_ENDHANDLER
}
@end

static NSString*	contentsPrefix = @"NSPBFileCont";
static NSString*	namePrefix = @"NSPBFileName";

NSString *NSCreateFileContentsPboardType(NSString *fileType)
{
  return [NSString stringWithFormat:@"%@%@", contentsPrefix, fileType];
}

NSString *NSCreateFilenamePboardType(NSString *filename)
{
  return [NSString stringWithFormat:@"%@%@", namePrefix, filename];
}

NSString *NSGetFileType(NSString *pboardType)
{
  if ([pboardType hasPrefix: contentsPrefix]) {
    return [pboardType substringFromIndex: [contentsPrefix length]];
  }
  if ([pboardType hasPrefix: namePrefix]) {
    return [pboardType substringFromIndex: [namePrefix length]];
  }
  return nil;
}

NSArray *NSGetFileTypes(NSArray *pboardTypes)
{
  NSMutableArray *a = [NSMutableArray arrayWithCapacity: [pboardTypes count]];
  unsigned int	i;

  for (i = 0; i < [pboardTypes count]; i++) {
    NSString*	s = NSGetFileType([pboardTypes objectAtIndex:i]);

    if (s && ! [a containsObject:s]) {
      [a addObject:s];
    }
  }
  if ([a count] > 0) {
    return [[a copy] autorelease];
  }
  return nil;
}



