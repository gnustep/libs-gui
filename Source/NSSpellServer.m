/* 
   NSSpellServer.m

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

#include <gnustep/gui/NSSpellServer.h>

@implementation NSSpellServer

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSSpellServer class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Instance methods
//
//
// Checking in Your Service 
//
- (BOOL)registerLanguage:(NSString *)language
		byVendor:(NSString *)vendor
{
  return NO;
}

//
// Assigning a Delegate 
//
- (id)delegate
{
  return nil;
}

- (void)setDelegate:(id)anObject
{}

//
// Running the Service 
//
- (void)run
{}

//
// Checking User Dictionaries 
//
- (BOOL)isWordInUserDictionaries:(NSString *)word
		   caseSensitive:(BOOL)flag
{
  return NO;
}

//
// Methods Implemented by the Delegate 
//
- (NSRange)spellServer:(NSSpellServer *)sender
findMisspelledWordInString:(NSString *)stringToCheck
language:(NSString *)language
wordCount:(int *)wordCount
countOnly:(BOOL)countOnly
{
  NSRange r;

  return r;
}

- (NSArray *)spellServer:(NSSpellServer *)sender
   suggestGuessesForWord:(NSString *)word
inLanguage:(NSString *)language
{
  return nil;
}

- (void)spellServer:(NSSpellServer *)sender
       didLearnWord:(NSString *)word
inLanguage:(NSString *)language
{}

- (void)spellServer:(NSSpellServer *)sender
      didForgetWord:(NSString *)word
inLanguage:(NSString *)language
{}

@end
