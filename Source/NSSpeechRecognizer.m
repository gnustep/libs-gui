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

@implementation NSSpeechRecognizer

+ (void) initialize
{
}

// Initialize
- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
    }
  return self;
}

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
  // Do nothing...
}

- (void) stopListening
{
  // Do nothing...
}

@end

