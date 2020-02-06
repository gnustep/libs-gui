/* Implementation of class NSSpeechRecognizer
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

#import <AppKit/NSSpeechRecognizer.h>
#import <Foundation/NSDistantObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSError.h>
#import <Foundation/NSConnection.h>
#import <Foundation/NSDistributedNotificationCenter.h>

#import "AppKit/NSWorkspace.h"

id   _speechRecognitionServer = nil;
BOOL _serverLaunchTested = NO;

#define SPEECH_RECOGNITION_SERVER @"GSSpeechRecognitionServer"

@interface NSObject (GSSpeechRecognitionServer)
- (NSSpeechRecognizer *) newRecognizer;
@end

@implementation NSSpeechRecognizer

+ (void) initialize
{
  _speechRecognitionServer = [NSConnection
                               rootProxyForConnectionWithRegisteredName: SPEECH_RECOGNITION_SERVER
                                                                   host: nil];
  RETAIN(_speechRecognitionServer);
  if (nil == _speechRecognitionServer)
    {
      NSWorkspace *ws = [NSWorkspace sharedWorkspace];
      [ws launchApplication: SPEECH_RECOGNITION_SERVER
                   showIcon: NO
                 autolaunch: NO];
    }
  else
    {
      NSLog(@"Server found in +initialize");
    }
}

- (void) processNotification: (NSNotification *)note
{
  NSString *word = (NSString *)[note object];
  NSEnumerator *en = [_commands objectEnumerator];
  id obj = nil;

  word = [word lowercaseString];
  while ((obj = [en nextObject]) != nil)
    {
      if ([[obj lowercaseString] isEqualToString: word])
        {
          [_delegate speechRecognizer: self
                  didRecognizeCommand: word];
        }
    }
}

// Initialize
- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      [[NSDistributedNotificationCenter defaultCenter]
        addObserver: self
           selector: @selector(processNotification:)
               name: GSSpeechRecognizerDidRecognizeWordNotification
             object: nil];
    }
  return self;
}

+ (id) allocWithZone: (NSZone *)aZone
{
  if (self == [NSSpeechRecognizer class])
    {
      if (nil == _speechRecognitionServer && !_serverLaunchTested)
        {
          unsigned int i = 0;

          // Wait for up to five seconds  for the server to launch, then give up.
          for (i=0 ; i < 50 ; i++)
            {
              _speechRecognitionServer = [NSConnection
                                           rootProxyForConnectionWithRegisteredName: SPEECH_RECOGNITION_SERVER
                                                                               host: nil];
              RETAIN(_speechRecognitionServer);
              if (nil != _speechRecognitionServer)
                {
                  NSLog(@"Server found!!!");
                  break;
                }
              [NSThread sleepForTimeInterval: 0.1];
            }
          
          // Set a flag so we don't bother waiting for the speech recognition server to
          // launch the next time if it didn't work this time.
          _serverLaunchTested = YES;
        }
      
      // If there is no server, this will return nil
      return [_speechRecognitionServer newRecognizer];
    }
  
  return [super allocWithZone: aZone];
}

// Delegate
- (id<NSSpeechRecognizerDelegate>) delegate
{
  return _delegate;
}

- (void) setDelegate: (id<NSSpeechRecognizerDelegate>)delegate
{
  _delegate = delegate;
}

// Configuring...
- (NSArray *) commands
{
  return _commands;
}

- (void) setCommands: (NSArray *)commands
{
  ASSIGNCOPY(_commands, commands);
}

- (NSString *) displayCommandsTitle
{
  return _displayCommandsTitle;
}

- (void) setDisplayCommandsTitle: (NSString *)displayCommandsTitle
{
  ASSIGNCOPY(_displayCommandsTitle, displayCommandsTitle);
}

- (BOOL) listensInForegroundOnly
{
  return _listensInForegroundOnly;
}

- (void) setListensInForegroundOnly: (BOOL)listensInForegroundOnly
{
  _listensInForegroundOnly = listensInForegroundOnly;
}

- (BOOL) blocksOtherRecognizers
{
  return _blocksOtherRecognizers;
}

- (void) setBlocksOtherRecognizers: (BOOL)blocksOtherRecognizers
{
  _blocksOtherRecognizers = blocksOtherRecognizers;
}

// Listening
- (void) startListening
{
  [self subclassResponsibility: _cmd];
}

- (void) stopListening
{
  [self subclassResponsibility: _cmd];
}
@end
