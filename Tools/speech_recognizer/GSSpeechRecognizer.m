/* Implementation of class GSSpeechRecognizer
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

#import "GSSpeechRecognizer.h"

static GSSpeechRecognitionServer *server;
static int clients;

@interface GSSpeechRecognizer (Private)
+ (void)connectionDied: (NSNotification*)aNotification;
@end

@implementation GSSpeechRecognizer
+ (void)initialize
{
  if (self == [GSSpeechRecognizer class])
    {
      server = [GSSpeechRecognitionServer sharedServer];
      RETAIN(server);
      [[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector(connectionDied:)
                       name: NSConnectionDidDieNotification
                     object: nil];
    }
}

/**
 * If the remote end exits before freeing the GSSpeechRecognizer then we need
 * to send it a -release message to make sure it dies.
 */
+ (void)connectionDied: (NSNotification*)aNotification
{
  NSEnumerator *e = [[[aNotification object] localObjects] objectEnumerator];
  NSObject *o = nil;
  
  for (o = [e nextObject] ; nil != o ; o = [e nextObject])
    {
      if ([o isKindOfClass: self])
        {
          [o release];
        }
    }
}

/**
 * If no clients have been active for some time, kill the speech server to
 * conserve resources.
 */
+ (void)exitIfUnneeded: (NSTimer*)sender
{
  if (clients == 0)
    {
      exit(0);
    }
}

- (id)init
{
  self = [super init];
  if (self != nil)
    {
      clients++;
      NSLog(@"self = %@",self);
    }
  return self;
}

- (void)dealloc
{
  NSLog(@"Deallocating recognizer....");
  clients--;
  if (clients == 0)
    {
      [NSTimer scheduledTimerWithTimeInterval: 600
                                       target: object_getClass(self)
                                     selector: @selector(exitIfUnneeded:)
                                     userInfo: nil
                                      repeats: NO];
    }
  [super dealloc];
}

- (void) startListening
{
  NSLog(@"Start Listening");
  if (server != nil)
    {
      [server startListening];
    }
}

- (void) stopListening
{
  NSLog(@"Stop Listening");
  if (server != nil)
    {
      [server stopListening];
    }
}

@end
