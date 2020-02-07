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
#import "GSSpeechRecognizer.h"
#import <Foundation/Foundation.h>

static GSSpeechRecognitionServer *sharedInstance;

@implementation GSSpeechRecognitionServer

+ (void)initialize
{
  sharedInstance = [self new];
}

+ (void)start
{
  NSConnection *connection = [NSConnection defaultConnection];
  [connection setRootObject: sharedInstance];
  if (NO == [connection registerName: @"GSSpeechRecognitionServer"])
    {
      return;
    }
  [[NSRunLoop currentRunLoop] run];
}

+ (id)sharedServer
{
  return sharedInstance;
}

- (id)init
{
  if (nil == (self = [super init]))
    {
      return nil;
    }
  
  _engine = [GSSpeechRecognitionEngine defaultSpeechRecognitionEngine];

  if (nil == _engine)
    {
      [self release];
      return nil;
    }
  else
    {
      NSLog(@"Got engine %@", _engine);
    }
  
  return self;
}

- (id)newRecognizer
{
  GSSpeechRecognizer *r = [[GSSpeechRecognizer alloc] init];
  RETAIN(r);
  return r;
}

- (void) startListening
{
  [_engine startListening];
}

- (void) stopListening
{
  [_engine stopListening];
}

@end
