/** <title>NSSound</title>

   <abstract>Load, manipulate and play sounds</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.
   
   Author: Enrico Sersale <enrico@imago.ro>
   Date: Jul 2002

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
#include <Foundation/Foundation.h>
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSSound.h"

#ifdef HAVE_AUDIOFILE_H
#include <audiofile.h>
#endif

#define BUFFER_SIZE_IN_FRAMES 4096

#define DEFAULT_CHANNELS 2

/* Class variables and functions for class methods */
static NSMutableDictionary *nameDict = nil;
static NSDictionary *nsmapping = nil;

#define	GSNDNAME @"GNUstepGSSoundServer"

@implementation NSBundle (NSSoundAdditions)

- (NSString *) pathForSoundResource: (NSString *)name
{
  NSString *ext = [name pathExtension];
  NSString *path = nil;

  if ((ext == nil) || [ext isEqualToString:@""])
    {
      NSArray	*types = [NSSound soundUnfilteredFileTypes];
      unsigned	c = [types count];
      unsigned	i;

      for (i = 0; path == nil && i < c; i++)
	{
	  ext = [types objectAtIndex: i];
	  path = [self pathForResource: name ofType: ext];
	}
    }
  else
    {
      name = [name stringByDeletingPathExtension];
      path = [self pathForResource: name ofType: ext];
    }
  return path;
}

@end 

@protocol GSSoundSvr

- (BOOL) playSound: (id)aSound;
- (BOOL) stopSoundWithIdentifier: (NSString *)identifier;
- (BOOL) pauseSoundWithIdentifier: (NSString *)identifier;
- (BOOL) resumeSoundWithIdentifier: (NSString *)identifier;
- (BOOL) isPlayingSoundWithIdentifier: (NSString *)identifier;

@end 

static id<GSSoundSvr> the_server = nil;

@interface NSSound (PrivateMethods)

+ (id<GSSoundSvr>) gsnd;
+ (void) localServer: (id<GSSoundSvr>)s;
+ (id) lostServer: (NSNotification*)notification;

- (BOOL) getDataFromFileAtPath: (NSString *)path;
- (void) setIdentifier: (NSString *)identifier;
- (NSString *) identifier;
- (float) samplingRate;
- (float) frameSize;
- (long) frameCount;
- (NSData *) data;

@end

@implementation NSSound (PrivateMethods)

#ifdef HAVE_AUDIOFILE_H
+ (id<GSSoundSvr>) gsnd
{
  if (the_server == nil) 
    {
      NSString *host;
      NSString *description;
      
      host = [[NSUserDefaults standardUserDefaults] stringForKey: @"NSHost"];
      if (host == nil) 
	{
	  host = @"";
	} 
      else 
	{
	  NSHost *h = [NSHost hostWithName: host];
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

      the_server = (id<GSSoundSvr>)[NSConnection
	rootProxyForConnectionWithRegisteredName: GSNDNAME host: host];

      if (the_server == nil && [host length] > 0) 
	{
	  NSString *service = [GSNDNAME stringByAppendingFormat: @"-%@", host];

	  the_server = (id<GSSoundSvr>)[NSConnection
	    rootProxyForConnectionWithRegisteredName: service host: @"*"];
	}

      if (RETAIN ((id)the_server) != nil) 
	{
	  NSConnection*	conn = [(id)the_server connectionForProxy];

	  [[NSNotificationCenter defaultCenter]
	    addObserver: self
	    selector: @selector(lostServer:)
	    name: NSConnectionDidDieNotification
	    object: conn];
	} 
      else 
	{
	  static BOOL recursion = NO;
	  static NSString	*cmd = nil;
	  static NSArray *args = nil;
	  
	  if (cmd == nil && recursion == NO) 
	    {
#ifdef GNUSTEP_BASE_LIBRARY
	      cmd = RETAIN([[NSSearchPathForDirectoriesInDomains(
				 GSToolsDirectory, NSSystemDomainMask, YES) 
								objectAtIndex: 0]
			     stringByAppendingPathComponent: @"gnustep_sndd"]);
#else
	      cmd = RETAIN([[@GNUSTEP_INSTALL_PREFIX 
			      stringByAppendingPathComponent: @"Tools"] 
			     stringByAppendingPathComponent: @"gnustep_sndd"]);
#endif
	    }

	  if (recursion == YES || cmd == nil) 
	    {
	      NSLog(@"Unable to contact sound server - "
		    @"please ensure that gnustep_sndd is running for %@.", description);
	      return nil;
	    } 
	  else 
	    {
	      NSLog(@"\nI couldn't contact the sound server for %@ -\n"
		    @"so I'm attempting to to start one - which will take a few seconds.\n"
		    @"Trying to launch gnustep_sndd from %@ or a machine/operating-system subdirectory.\n"
		    @"It is recommended that you start the sound server (gnustep_sndd) when\n"
		    @"your windowing system is started up.\n", description,
		    [cmd stringByDeletingLastPathComponent]);

	      if ([host length] > 0) 
		{
		  args = [[NSArray alloc] initWithObjects: @"-NSHost", host, nil];
		}

	      [NSTask launchedTaskWithLaunchPath: cmd arguments: args];

	      [NSTimer scheduledTimerWithTimeInterval: 5.0
		       invocation: nil repeats: NO];

	      [[NSRunLoop currentRunLoop] runUntilDate: 
					      [NSDate dateWithTimeIntervalSinceNow: 5.0]];

	      recursion = YES;
	      [self gsnd];
	      recursion = NO;
	    }
	}
    }
		
  return the_server;
}

+ (void) localServer: (id<GSSoundSvr>)s
{
  the_server = s;
}

+ (id) lostServer: (NSNotification*)notification
{
  id obj = the_server;

  the_server = nil;
  [[NSNotificationCenter defaultCenter]
    removeObserver: self
    name: NSConnectionDidDieNotification
    object: [notification object]];
  RELEASE (obj);
  return self;
}

- (BOOL) getDataFromFileAtPath: (NSString *)path
{
  NSMutableData *d;
  AFfilehandle file;
  AFframecount framesRead;
  void *buffer;

#define CHECK_AF_ERR(x) \
if ((x) == -1) { \
afCloseFile(file); \
return NO; \
}

  if ((file = afOpenFile([path fileSystemRepresentation], "r", NULL)) 
	== AF_NULL_FILEHANDLE) 
    {
      return NO;
    }

  _dataFormat = AF_SAMPFMT_TWOSCOMP;
  CHECK_AF_ERR (afSetVirtualSampleFormat(file, AF_DEFAULT_TRACK, _dataFormat, 16));
  _channelCount = DEFAULT_CHANNELS;
  CHECK_AF_ERR (afSetVirtualChannels(file, AF_DEFAULT_TRACK, _channelCount));
  CHECK_AF_ERR (_samplingRate = afGetRate(file, AF_DEFAULT_TRACK));	
  CHECK_AF_ERR (_frameCount = afGetFrameCount(file, AF_DEFAULT_TRACK));	
  CHECK_AF_ERR (_frameSize = afGetVirtualFrameSize(file, AF_DEFAULT_TRACK, 1));	
  CHECK_AF_ERR (_dataLocation = afGetDataOffset(file, AF_DEFAULT_TRACK));
		
  buffer = NSZoneMalloc(NSDefaultMallocZone(), BUFFER_SIZE_IN_FRAMES * _frameSize);
  d = [[NSMutableData alloc] initWithCapacity: 1];

  CHECK_AF_ERR (framesRead = afReadFrames(file, AF_DEFAULT_TRACK, buffer, 
					  BUFFER_SIZE_IN_FRAMES));
  while (framesRead > 0) 
    {	
      [d appendBytes: (const void *)buffer 
	 length: framesRead * _frameSize];
      CHECK_AF_ERR (framesRead = afReadFrames(file, AF_DEFAULT_TRACK, buffer, 
					      BUFFER_SIZE_IN_FRAMES));		
    }

  _data = d;	
  _dataSize = [_data length];
  NSZoneFree(NSDefaultMallocZone(), buffer);
  afCloseFile(file);
	
  return YES;
}

#else
/* No sound software */

+ (id<GSSoundSvr>) gsnd
{
  return nil;
}

+ (void) localServer: (id<GSSoundSvr>)s
{
}

+ (id) lostServer: (NSNotification*)notification
{
  return self;
}

- (BOOL) getDataFromFileAtPath: (NSString *)path
{
  NSLog(@"NSSound: No sound software installed, cannot get sound");
  return NO;
}
#endif

- (void) setIdentifier: (NSString *)identifier
{
  ASSIGN (_uniqueIdentifier, identifier);
}

- (NSString *) identifier
{
  return _uniqueIdentifier;
}

- (float) samplingRate
{
  return _samplingRate;
}

- (float) frameSize
{
  return _frameSize;
}

- (long) frameCount
{
  return _frameCount;
}

- (NSData *) data
{
  return _data;
}

@end

@implementation	NSSound

+ (void) initialize
{
  if (self == [NSSound class]) 
    {
      NSString *path = [NSBundle pathForLibraryResource: @"nsmapping"
				                 ofType: @"strings"
				             inDirectory: @"Sounds"];
      [self setVersion: 1];

      nameDict = [[NSMutableDictionary alloc] initWithCapacity: 10];
      
      if (path) 
	{
	  nsmapping = RETAIN([[NSString stringWithContentsOfFile: path]
			       propertyListFromStringsFileFormat]);
	}
    }
}

- (void) dealloc
{
  TEST_RELEASE (_data);
  if ((_name != nil) && self == [nameDict objectForKey: _name]) 
    { 
      [nameDict removeObjectForKey: _name];
    }
  TEST_RELEASE (_name);
  TEST_RELEASE (_uniqueIdentifier);
  [super dealloc];
}

//
// Creating an NSSound 
//
- (id) initWithContentsOfFile: (NSString *)path byReference:(BOOL)byRef
{
  self = [super init];
	
  if (self) 
    {			
      _onlyReference = byRef;			
      ASSIGN (_name, [path lastPathComponent]);
      _uniqueIdentifier = nil;
      if ([self getDataFromFileAtPath: path] == NO) 
	{
	  NSLog(@"Could not get sound data from %@", path);
	  DESTROY (self);
	}
    }
	
  return self;
}

- (id) initWithContentsOfURL: (NSURL *)url byReference:(BOOL)byRef
{
  _onlyReference = byRef;	
  return [self initWithData: [NSData dataWithContentsOfURL: url]];
}

- (id) initWithData: (NSData *)data
{
  [self notImplemented: _cmd];
  return nil;
}

- (id) initWithPasteboard: (NSPasteboard *)pasteboard
{
  if ([NSSound canInitWithPasteboard: pasteboard] == YES) 
    {	
      NSData *d = [pasteboard dataForType: @"NSGeneralPboardType"];	
      return [self initWithData: d];	
    }
  return nil;
}

//
// Playing
//
- (BOOL) pause 
{
  if (_uniqueIdentifier) 
    {
      return [[NSSound gsnd] pauseSoundWithIdentifier: _uniqueIdentifier];
    }	
  return NO;
}

- (BOOL) play
{
  return [[NSSound gsnd] playSound: self];
}

- (BOOL) resume
{
  if (_uniqueIdentifier) 
    {
      return [[NSSound gsnd] resumeSoundWithIdentifier: _uniqueIdentifier];
    }	
  return NO;
}

- (BOOL) stop
{
  if (_uniqueIdentifier) 
    {
      return [[NSSound gsnd] stopSoundWithIdentifier: _uniqueIdentifier];
    }	
  return NO;
}

- (BOOL) isPlaying
{
  if (_uniqueIdentifier) 
    {
      return [[NSSound gsnd] isPlayingSoundWithIdentifier: _uniqueIdentifier];
    }	
  return NO;
}

//
// Working with pasteboards 
//
+ (BOOL) canInitWithPasteboard: (NSPasteboard *)pasteboard
{
  NSArray *pbTypes = [pasteboard types];
  NSArray *myTypes = [NSSound soundUnfilteredPasteboardTypes];

  return ([pbTypes firstObjectCommonWithArray: myTypes] != nil);
}

+ (NSArray *) soundUnfilteredPasteboardTypes
{
  return [NSArray arrayWithObjects: @"NSGeneralPboardType", nil];
}

- (void) writeToPasteboard: (NSPasteboard *)pasteboard
{
  NSData *d = [NSArchiver archivedDataWithRootObject: self];

  if (d != nil) {
    [pasteboard declareTypes: [NSSound soundUnfilteredPasteboardTypes] 
		owner: nil];
    [pasteboard setData: d forType: @"NSGeneralPboardType"];
  }
}

//
// Working with delegates 
//
- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id)aDelegate
{
  _delegate = aDelegate;
}

//
// Naming Sounds 
//
+ (id) soundNamed: (NSString*)name
{
  NSString	*realName = [nsmapping objectForKey: name];
  NSSound	*sound;

  if (realName) 
    {
      name = realName;
    }
	
  sound = (NSSound *)[nameDict objectForKey: name];
 
  if (sound == nil) 
    {
      NSString	*extension;
      NSString	*path = nil;
      NSBundle	*main_bundle;
      NSArray	*array;
      NSString	*the_name = name;

      // FIXME: This should use [NSBundle pathForSoundResource], but this will 
      // only allow soundUnfilteredFileTypes.
      /* If there is no sound with that name, search in the main bundle */
			
      main_bundle = [NSBundle mainBundle];
      extension = [name pathExtension];
		
      if (extension != nil && [extension length] == 0) 
	{
	  extension = nil;
	}

      /* Check if extension is one of the sound types */
      array = [NSSound soundUnfilteredFileTypes];
	
      if ([array indexOfObject: extension] != NSNotFound) 
	{
	  /* Extension is one of the sound types
	     So remove from the name */
	  the_name = [name stringByDeletingPathExtension];
	} 
      else 
	{
	  /* Otherwise extension is not an sound type
	     So leave it alone */
	  the_name = name;
	  extension = nil;
	}

      /* First search locally */
      if (extension) 
	{
	  path = [main_bundle pathForResource: the_name ofType: extension];
	} 
      else 
	{
	  id o, e;

	  e = [array objectEnumerator];
	  while ((o = [e nextObject])) 
	    {
	      path = [main_bundle pathForResource: the_name ofType: o];
	      if (path != nil && [path length] != 0) 
		{
		  break;
		}
	    }
	}

      /* If not found then search in system */
      if (!path) 
	{
	  if (extension) 
	    {
	      path = [NSBundle pathForLibraryResource: the_name
				               ofType: extension
				          inDirectory: @"Sounds"];
	    } 
	  else 
	    {
	      id o, e;

	      e = [array objectEnumerator];
	      while ((o = [e nextObject])) {
	      path = [NSBundle pathForLibraryResource: the_name
				               ofType: o
				          inDirectory: @"Sounds"];
		if (path != nil && [path length] != 0) 
		  {
		    break;
		  }
	      }
	    }
	}

      if ([path length] != 0) 
	{
	  sound = [[self allocWithZone: NSDefaultMallocZone()]
		    initWithContentsOfFile: path byReference: NO];

	  if (sound != nil) 
	    {
	      [sound setName: name];
	      RELEASE(sound);	
	      sound->_onlyReference = YES;
	    }

	  return sound;
	}
    }  
	
  return sound;
}

+ (NSArray *) soundUnfilteredFileTypes
{
  return [NSArray arrayWithObjects: @"aiff", @"waw", @"snd", @"au", nil];
}

- (NSString *) name
{
  return _name;
}

- (BOOL) setName: (NSString *)aName
{
  BOOL retained = NO;
  
  if (!aName || [nameDict objectForKey: aName]) 
    {
      return NO;
    }
	
  if ((_name != nil) && self == [nameDict objectForKey: _name]) 
    {
      /* We retain self in case removing from the dictionary releases
	 us */
      RETAIN (self);
      retained = YES;
      [nameDict removeObjectForKey: _name];
    }
  
  ASSIGN(_name, aName);
  
  [nameDict setObject: self forKey: _name];
  if (retained) 
    {
      RELEASE (self);
    }
  
  return YES;
}

//
// NSCoding 
//
- (void) encodeWithCoder: (NSCoder *)coder
{
  [coder encodeValueOfObjCType: @encode(BOOL) at: &_onlyReference];
  [coder encodeObject: _name];
	
  if (_onlyReference == YES) 
    {
      return;
    }

  if (_uniqueIdentifier != nil) 
    {
      [coder encodeObject: _uniqueIdentifier];
    }

  [coder encodeConditionalObject: _delegate];
  [coder encodeValueOfObjCType: @encode(long) at: &_dataLocation];
  [coder encodeValueOfObjCType: @encode(long) at: &_dataSize];
  [coder encodeValueOfObjCType: @encode(int) at: &_dataFormat];
  [coder encodeValueOfObjCType: @encode(float) at: &_samplingRate];
  [coder encodeValueOfObjCType: @encode(float) at: &_frameSize];
  [coder encodeValueOfObjCType: @encode(long) at: &_frameCount];
  [coder encodeValueOfObjCType: @encode(int) at: &_channelCount];

  [coder encodeObject: _data];
}

- (id) initWithCoder: (NSCoder*)decoder
{	
  [decoder decodeValueOfObjCType: @encode(BOOL) at: &_onlyReference];

  if (_onlyReference == YES) 
    {
      NSString *theName = [decoder decodeObject];

      RELEASE (self);
      self = RETAIN ([NSSound soundNamed: theName]);
      [self setName: theName];	
    } 
  else 
    {
      _name = TEST_RETAIN ([decoder decodeObject]);
      _uniqueIdentifier = TEST_RETAIN ([decoder decodeObject]);
      [self setDelegate: [decoder decodeObject]];
      
      [decoder decodeValueOfObjCType: @encode(long) at: &_dataLocation];
      [decoder decodeValueOfObjCType: @encode(long) at: &_dataSize];
      [decoder decodeValueOfObjCType: @encode(int) at: &_dataFormat];
      [decoder decodeValueOfObjCType: @encode(float) at: &_samplingRate];
      [decoder decodeValueOfObjCType: @encode(float) at: &_frameSize];
      [decoder decodeValueOfObjCType: @encode(long) at: &_frameCount];
      [decoder decodeValueOfObjCType: @encode(int) at: &_channelCount];
      
      _data = RETAIN([decoder decodeObject]);
    }
	
  return self;
}

- (id) awakeAfterUsingCoder: (NSCoder *)coder
{
  return self;
}

//
// NSCopying 
//
- (id) copyWithZone: (NSZone *)zone
{
  NSSound *newSound = (NSSound *)NSCopyObject(self, 0, zone);
	
  newSound->_data = [_data copyWithZone: zone];	
  newSound->_name = [_name copyWithZone: zone];		
  newSound->_uniqueIdentifier = [_uniqueIdentifier copyWithZone: zone];
	
  return newSound;
}

@end
