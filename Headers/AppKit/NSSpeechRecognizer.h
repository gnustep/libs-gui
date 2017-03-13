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

#ifndef _GNUstep_H_NSSpeechRecognizer
#define _GNUstep_H_NSSpeechRecognizer

#import <Foundation/NSObject.h>

// forward declarations...
@class NSString, NSArray;
@protocol NSSpeechRecognizerDelegate;

// class declaration...
@interface NSSpeechRecognizer : NSObject
{
  id<NSSpeechRecognizerDelegate> _delegate;
  NSArray *_commands;
  NSString *_displayedCommandsTitle;
  BOOL _listensInForegroundOnly;
  BOOL _blocksOtherRecognizers;
}

- (id)init;

- (void)startListening;
- (void)stopListening;

- (id<NSSpeechRecognizerDelegate>)delegate;
- (void)setDelegate:(id<NSSpeechRecognizerDelegate>)delegate;

- (NSArray *)commands;
- (void)setCommands: (NSArray *)commands;

- (NSString *)displayedCommandsTitle;
- (void)setDisplayedCommandsTitle: (NSString *)displayedCommandsTitle;

- (BOOL)listensInForegroundOnly;
- (void)setListensInForegroundOnly: (BOOL)flag;

- (BOOL) blocksOtherRecognizers;
- (void) setBlocksOtherRecognizers: (BOOL)flag;
          
@end

@protocol NSSpeechRecognizerDelegate <NSObject>
- (void)speechRecognizer: (NSSpeechRecognizer *)sender
     didRecognizeCommand: (NSString *)command;
@end

@interface NSObject (NSSpeechRecognizerDelegate) <NSSpeechRecognizerDelegate>
@end

#endif // _GNUstep_H_NSSpeechRecognizer
