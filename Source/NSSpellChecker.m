/* 
   NSSpellChecker.m

   Description...

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

#include <AppKit/NSSpellChecker.h>

@implementation NSSpellChecker

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSSpellChecker class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Making a Checker available 
//
+ (NSSpellChecker *)sharedSpellChecker
{
  return nil;
}

+ (BOOL)sharedSpellCheckerExists
{
  return NO;
}

//
// Managing the Spelling Process 
//
+ (int)uniqueSpellDocumentTag
{
  return 0;
}

//
// Instance methods
//
//
// Managing the Spelling Panel 
//
- (NSView *)accessoryView
{
  return nil;
}

- (void)setAccessoryView:(NSView *)aView
{}

- (NSPanel *)spellingPanel
{
  return nil;
}

//
// Checking Spelling 
//
- (int)countWordsInString:(NSString *)aString
		 language:(NSString *)language
{
  return 0;
}

- (NSRange)checkSpellingOfString:(NSString *)stringToCheck
		      startingAt:(int)startingOffset
{
  NSRange r;

  return r;
}

- (NSRange)checkSpellingOfString:(NSString *)stringToCheck
		      startingAt:(int)startingOffset
language:(NSString *)language
		      wrap:(BOOL)wrapFlag
inSpellDocumentWithTag:(int)tag
		      wordCount:(int *)wordCount
{
  NSRange r;

  return r;
}

//
// Setting the Language 
//
- (NSString *)language
{
  return nil;
}

- (BOOL)setLanguage:(NSString *)aLanguage
{
  return NO;
}

//
// Managing the Spelling Process 
//
- (void)closeSpellDocumentWithTag:(int)tag
{}

- (void)ignoreWord:(NSString *)wordToIgnore
inSpellDocumentWithTag:(int)tag
{}

- (NSArray *)ignoredWordsInSpellDocumentWithTag:(int)tag
{
  return nil;
}

- (void)setIgnoredWords:(NSArray *)someWords
 inSpellDocumentWithTag:(int)tag
{}

- (void)setWordFieldStringValue:(NSString *)aString
{}

- (void)updateSpellingPanelWithMisspelledWord:(NSString *)word
{}

@end
