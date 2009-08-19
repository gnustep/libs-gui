/** <title>NSSpeechSynthesizer</title>

   <abstract>abstract base class for speech synthesis</abstract>

   Copyright <copy>(C) 2009 Free Software Foundation, Inc.</copy>

   Author: Gregory Casamento <greg.casamento@gmail.com>
   Date: Mar 2009

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

#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSError.h>
#include "AppKit/NSSpeechSynthesizer.h"

// Keys for properties...
NSString *NSVoiceIdentifier = @"NSVoiceIdentifier";
NSString *NSVoiceName = @"NSVoiceName";
NSString *NSVoiceAge = @"NSVoiceAge";
NSString *NSVoiceGender = @"NSVoiceGender";
NSString *NSVoiceDemoText = @"NSVoiceDemoText";
NSString *NSVoiceLanguage = @"NSVoiceLanguage";
NSString *NSVoiceLocaleIdentifier = @"NSVoiceLocaleIdentifier";
NSString *NSVoiceSupportedCharacters = @"NSVoiceSupportedCharacters";
NSString *NSVoiceIndividuallySpokenCharacters = @"NSVoiceIndividuallySpokenCharacters";

// Values for gender
NSString *NSVoiceGenderNeuter = @"NSVoiceGenderNeuter";
NSString *NSVoiceGenderMale = @"NSVoiceGenderMale";
NSString *NSVoiceGenderFemale = @"NSVoiceGenderFemale";

// values for speech mode
NSString *NSSpeechModeText = @"NSSpeechModeText";
NSString *NSSpeechModePhoneme = @"NSSpeechModePhoneme";
NSString *NSSpeechModeNormal = @"NSSpeechModeNormal";
NSString *NSSpeechModeLiteral = @"NSSpeechModeLiteral";

// values for speech status...
NSString *NSSpeechStatusOutputBusy = @"NSSpeechStatusOutputBusy";
NSString *NSSpeechStatusOutputPaused = @"NSSpeechStatusOutputPaused";
NSString *NSSpeechStatusNumberOfCharactersLeft = @"NSSpeechStatusNumberOfCharactersLeft";
NSString *NSSpeechStatusPhonemeCode = @"NSSpeechStatusPhonemeCode";

// values for error
NSString *NSSpeechErrorCount = @"NSSpeechErrorCount";
NSString *NSSpeechErrorOldestCode = @"NSSpeechErrorOldestCode";
NSString *NSSpeechErrorOldestCharacterOffset = @"NSSpeechErrorOldestCharacterOffset";
NSString *NSSpeechErrorNewestCode = @"NSSpeechErrorNewestCode";
NSString *NSSpeechErrorNewestCharacterOffset = @"NSSpeechErrorNewestCharacterOffset";

// values for info
NSString *NSSpeechSynthesizerInfoIdentifier = @"NSSpeechSynthesizerInfoIdentifier";
NSString *NSSpeechSynthesizerInfoVersion = @"NSSpeechSynthesizerInfoVersion";

// values for command delimiter
NSString *NSSpeechCommandPrefix = @"NSSpeechCommandPrefix";
NSString *NSSpeechCommandSuffix = @"NSSpeechCommandSuffix";

// values for dictionaries.
NSString *NSSpeechDictionaryLanguage = @"NSSpeechDictionaryLanguage";
NSString *NSSpeechDictionaryModificationDate = @"NSSpeechDictionaryModificationDate";
NSString *NSSpeechDictionaryPronunciations = @"NSSpeechDictionaryPronunciations";
NSString *NSSpeechDictionaryAbreviations = @"NSSpeechDictionaryAbreviations";
NSString *NSSpeechDictionaryEntrySpelling = @"NSSpeechDictionaryEntrySpelling";
NSString *NSSpeechDictionaryEntryPhonemes = @"NSSpeechDictionaryEntryPhonemes";

// class declaration...
@implementation NSSpeechSynthesizer 
// init...
- (id) initWithVoice: (NSString *)voice 
{
  return self;
}

// configuring speech synthesis
- (BOOL) usesFeebackWindow 
{
  return _usesFeedbackWindow;
}

- (void) setUsesFeebackWindow: (BOOL)flag 
{
  _usesFeedbackWindow = flag;
}

- (NSString *) voice 
{
  return _voice;
}

- (void) setVoice: (NSString *)voice 
{
  ASSIGN(_voice, voice);
}

- (float) rate 
{
  return _rate;
}

- (void) setRate: (float)rate 
{
  _rate = rate;
}

- (float) volume 
{
  return _volume;
}

- (void) setVolume: (float)volume 
{
  _volume = volume;
}

- (void) addSpeechDictionary: (NSDictionary *)speechDictionary 
{
}

- (id) objectForProperty: (NSString *)property error: (NSError **)error 
{
  return nil;
}

- (id) setObject: (id) object 
     forProperty: (NSString *)property 
           error: (NSError **)error 
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (id) delegate 
{
  return _delegate;
}

- (void) setDelegate: (id)delegate
{
  _delegate = delegate;
}

// Getting information...
+ (NSArray *) availableVoices 
{
  return [NSArray array];
}

+ (NSDictionary *) attributesForVoice: (NSString *)voice 
{
  return [NSDictionary dictionary];
}

+ (NSString *) defaultVoice 
{ 
  [self subclassResponsibility: _cmd];
  return nil;
}

// Getting state...
+ (BOOL) isAnyApplicationSpeaking 
{
  return NO;
}

// Synthesizing..
- (BOOL) isSpeaking 
{
  return _isSpeaking;
}

- (BOOL) startSpeakingString: (NSString *)text 
{
  [self subclassResponsibility: _cmd];
  return NO;
}

- (BOOL) startSpeakingString: (NSString *)text toURL: (NSURL *)url 
{
  [self subclassResponsibility: _cmd];
  return NO;
}

- (void) stopSpeaking 
{
  [self subclassResponsibility: _cmd];
}

- (void) stopSpeakingAtBoundary: (NSSpeechBoundary)boundary 
{
  [self subclassResponsibility: _cmd];
}

- (void) pauseSpeakingAtBoundary: (NSSpeechBoundary)boundary 
{ 
  [self subclassResponsibility: _cmd];
}

- (void) continueSpeaking 
{
  [self subclassResponsibility: _cmd]; 
}

- (NSString *) phonemesFromText: (NSString *)text
{
  [self subclassResponsibility: _cmd];
  return nil;
}
@end

