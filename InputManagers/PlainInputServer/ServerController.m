/*
    ServerController.m  (PlainInputServer)

    Copyright (C) 2004 Free Software Foundation, Inc.

    Author: Kazunobu Kuriyama <kazunobu.kuriyama@nifty.com>
    Date: March, 2004

    This file is part of the GNUstep GUI Library.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; see the file COPYING.LIB.
    If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <Foundation/NSNotification.h>
#include <Foundation/NSConnection.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSDebug.h>
#include <AppKit/NSInputServer.h>
#include "PlainInputServer.h"
#include "ServerController.h"


static NSString *theConnectionName = @"PlainInputServer2ConnectionName";
static ServerController	*controller = nil;


@interface ServerController (Connection)
- (void)connectionDidDie: (NSNotification *)aNotification;
@end /* @interface ServerController (Connection) */


@implementation ServerController

+ (id)sharedInstance
{
  if (controller == nil)
    {
      controller = [[ServerController alloc] init];
    }
  return controller;
}


- (id)init
{
  if ((self = [super init]) != nil)
    {
      PlainInputServer	    *theDelegate = [PlainInputServer sharedInstance];
      NSNotificationCenter  *theCenter;

      if (theDelegate == nil)
	{
	  NSLog(@"%@: Initialization failed", self);
	  [self release];
	  return nil;
	}

      server = [[NSInputServer alloc] initWithDelegate: theDelegate
						  name: theConnectionName];
      if (server == nil)
	{
	  NSLog(@"%@: Initialization failed", self);
	  [self release];
	  return nil;
	}

      theCenter= [NSNotificationCenter defaultCenter];
      [theCenter addObserver: self
		    selector: @selector(connectionDidDie:)
			name: NSConnectionDidDieNotification
		      object: nil];
    }
  return self;
}


- (void)run
{
  NSRunLoop *loop = [NSRunLoop currentRunLoop];

  [loop configureAsServer];
  [loop run];

  [[NSNotificationCenter defaultCenter] removeObserver: self];
}


- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [server release];
  [super dealloc];
}

@end /* @implementation ServerController */


@implementation ServerController (Connection)

- (void)connectionDidDie: (NSNotification *)aNotification
{
  NSDebugMLLog(@"%@: connection to %@ died", server, [aNotification object]);
}

@end /* @implementation ServerController (Connection) */
