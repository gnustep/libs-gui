/** <title>NSSpeechRecognizer</title>

   <abstract>abstract base class for speech recognition</abstract>

   Copyright <copy>(C) 2017 Free Software Foundation, Inc.</copy>

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Date: Mar 13, 2017

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#import <AppKit/NSSpeechRecognizer.h>

@implementation NSSpeechRecognizer
- (id)init
{
  self = [super init];
  if(self)
    {
      _commands = nil;
      _displayedCommandsTitle = @"";
      _delegate = nil;
      _listensInForegroundOnly = NO;
      _blocksOtherRecognizers = NO;
    }
  return self;
}

- (void)startListening
{
  // TO BE IMPLEMENTED
}

- (void)stopListening
{
  // TO BE IMPLEMENTED
}

- (id<NSSpeechRecognizerDelegate>)delegate
{
  return _delegate;
}

- (void)setDelegate:(id<NSSpeechRecognizerDelegate>)delegate
{
  ASSIGN(_delegate, delegate);
}

- (NSArray *)commands
{
  return _commands;
}

- (void)setCommands: (NSArray *)commands
{
  ASSIGNCOPY(_commands, commands);  
}

- (NSString *)displayedCommandsTitle
{
  return _displayedCommandsTitle;
}

- (void)setDisplayedCommandsTitle: (NSString *)displayedCommandsTitle
{
  ASSIGNCOPY(_displayedCommandsTitle, displayedCommandsTitle);
}

- (BOOL)listensInForegroundOnly
{
  return _listensInForegroundOnly;
}

- (void)setListensInForegroundOnly: (BOOL)flag
{
  _listensInForegroundOnly = flag;
}

- (BOOL) blocksOtherRecognizers
{
  return _blocksOtherRecognizers;
}

- (void) setBlocksOtherRecognizers: (BOOL)flag
{
  _blocksOtherRecognizers = flag;
}
          
@end
