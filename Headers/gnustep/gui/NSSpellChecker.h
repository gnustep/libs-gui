/* 
   NSSpellChecker.h

   Class which is interface to spell-checking service

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#ifndef _GNUstep_H_NSSpellChecker
#define _GNUstep_H_NSSpellChecker

#include <AppKit/stdappkit.h>
#include <AppKit/NSView.h>
#include <AppKit/NSPanel.h>
#include <Foundation/NSRange.h>

@interface NSSpellChecker : NSObject

{
  // Attributes
}

//
// Making a Checker available 
//
+ (NSSpellChecker *)sharedSpellChecker;
+ (BOOL)sharedSpellCheckerExists;

//
// Managing the Spelling Panel 
//
- (NSView *)accessoryView;
- (void)setAccessoryView:(NSView *)aView;
- (NSPanel *)spellingPanel;

//
// Checking Spelling 
//
- (int)countWordsInString:(NSString *)aString
		 language:(NSString *)language;
- (NSRange)checkSpellingOfString:(NSString *)stringToCheck
		      startingAt:(int)startingOffset;
- (NSRange)checkSpellingOfString:(NSString *)stringToCheck
		      startingAt:(int)startingOffset
language:(NSString *)language
		      wrap:(BOOL)wrapFlag
inSpellDocumentWithTag:(int)tag
		      wordCount:(int *)wordCount;

//
// Setting the Language 
//
- (NSString *)language;
- (BOOL)setLanguage:(NSString *)aLanguage;

//
// Managing the Spelling Process 
//
+ (int)uniqueSpellDocumentTag;
- (void)closeSpellDocumentWithTag:(int)tag;
- (void)ignoreWord:(NSString *)wordToIgnore
inSpellDocumentWithTag:(int)tag;
- (NSArray *)ignoredWordsInSpellDocumentWithTag:(int)tag;
- (void)setIgnoredWords:(NSArray *)someWords
 inSpellDocumentWithTag:(int)tag;
- (void)setWordFieldStringValue:(NSString *)aString;
- (void)updateSpellingPanelWithMisspelledWord:(NSString *)word;

@end

#endif // _GNUstep_H_NSSpellChecker

