/* Implementation of class GSSpeechRecognitionServer
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Fri Dec  6 04:55:59 EST 2019

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import "GSSpeechRecognitionServer.h"
#import "GSSpeechRecognitionEngine.h"
#import <Foundation/Foundation.h>

static GSSpeechRecognitionServer *_sharedInstance;
static int _clients = 0;

@implementation GSSpeechRecognitionServer

/**
 * Monitor connection...
 */
+ (void)connectionDied: (NSNotification*)aNotification
{
  NSArray *objs = [[aNotification object] localObjects];
  NSEnumerator *en = [objs objectEnumerator];
  id o = nil;

  if(_clients > 0)
    {
      _clients--;
    }
  
  if(_clients == 0)
    {
      NSLog(@"Client count is zero, exiting");
      exit(0);
    }
  
  NSLog(@"NSSpeechRecognizer server connection count = %d after disconnection", _clients);
  while((o = [en nextObject]) != nil)
    {
      if ([o isKindOfClass: self])
        {
          RELEASE(o);
        }
    }
}

+ (void)initialize
{
  _sharedInstance = [[self alloc] init];
  _clients = 0;
  [[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(connectionDied:)
                       name: NSConnectionDidDieNotification
                     object: nil];
}

+ (void)start
{
  NSConnection *connection = [NSConnection defaultConnection];
  [connection setRootObject: _sharedInstance];
  RETAIN(connection);
  if (NO == [connection registerName: @"GSSpeechRecognitionServer"])
    {
      NSLog(@"Could not register name, make sure another server is not running.");
      return;
    }
  [[NSRunLoop currentRunLoop] run];
}

+ (id)sharedServer
{
  NSLog(@"NSSpeechRecognizer server connection count = %d after connection", _clients);
  return _sharedInstance;
}

- (void) addClient
{
  _clients++;
}

- (BOOL) bundlePathIsLoaded: (NSString *)path
{
  int		i = 0;  
  NSBundle	*bundle;
  for (i = 0; i < [bundles count]; i++)
    {
      bundle = [bundles objectAtIndex: i];
      if ([path isEqualToString: [bundle bundlePath]] == YES)
	{
	  return YES;
	}
    }
  return NO;
}

- (BOOL) loadPlugin: (NSString*)path
{
  NSBundle	*bundle;
  NSString	*className;
  // NSObject	*plugin;
  // Class		pluginClass;

  if([self bundlePathIsLoaded: path])
    {
      NSLog(@"bundle has already been loaded");
      return NO;
    }
  
  bundle = [NSBundle bundleWithPath: path]; 
  if (bundle == nil)
    {
      NSLog(@"Could not load bundle"); 
      return NO;
    }

  className = [[bundle infoDictionary] objectForKey: @"NSPrincipalClass"];
  if (className == nil)
    {
      NSLog(@"No plugin class in plist");
      return NO;
    }

  /*
  pluginClass = [bundle classNamed: className];
  if (pluginClass == 0)
    {
      NSLog(@"Could not load bundle princpal class: %@", className);		       
      return NO;
    }

  plugin = [[pluginClass alloc] init];
  if ([plugin isKindOfClass: [GSSpeechRecognitionEngine class]] == NO)
    {
      NSLog(@"bundle contains wrong type of class");
      RELEASE(plugin);
      return NO;
    }
  */
  
  // add to the bundles list...
  [bundles addObject: bundle];	
  
  // manage plugin data.
  [pluginNames addObject: className];

  // RELEASE(plugin);

  return YES;
}

- (GSSpeechRecognitionEngine *) defaultEngine
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *className = [defaults stringForKey: @"GSDefaultSpeechRecognitionEngine"];
  if ([pluginNames containsObject: className])
    {
      _engineClass = NSClassFromString(className);
    }
  else
    {
      _engineClass = NSClassFromString(@"PocketsphinxSpeechRecognitionEngine");
    }
  
  return [[engineClass alloc] init];
}

- (id)init
{
  NSArray *array = nil;
  
  if (nil == (self = [super init]))
    {
      return nil;
    }
  
  // pluginsDict = [[NSMutableDictionary alloc] init];
  // plugins = [[NSMutableArray alloc] init];
  bundles = [[NSMutableArray alloc] init];
  pluginNames = [[NSMutableArray alloc] init];
  array = [[NSBundle mainBundle] pathsForResourcesOfType: @"recognizer"
                                 inDirectory: nil];
  if ([array count] > 0)
    {
      unsigned	index;    
      array = [array sortedArrayUsingSelector: @selector(compare:)];
      
      for (index = 0; index < [array count]; index++)
	{
	  [self loadPlugin: [array objectAtIndex: index]];
	}
    }
  
  _engine = [self defaultEngine];
  if (nil == _engine)
    {
      [self release];
      return nil;
    }
  else
    {
      NSLog(@"Got engine starting... %@", _engine);
      [_engine start];
    }

  _blocking = [[NSMutableArray alloc] initWithCapacity: 10];  // 10 seems reasonable...

  return self;
}

- (void) dealloc
{
  [_engine stop];
  RELEASE(_engine);
  RELEASE(_blocking);
  [super dealloc];
}

- (void) addToBlockingRecognizers: (NSString *)s
{
  [_blocking addObject: s];
}

- (void) removeFromBlockingRecognizers: (NSString *)s
{
  [_blocking removeObject: s];
}

- (BOOL) isBlocking: (NSString *)s
{
  return [[_blocking firstObject] isEqualToString: s];
}

@end
