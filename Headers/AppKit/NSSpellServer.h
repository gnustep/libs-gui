/* 
   NSSpellServer.h

   Class to allow a spell checker to be available to other apps

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2001

   Author of previous version: Scott Christley <scottc@net-community.com>
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

#ifndef _GNUstep_H_NSSpellServer
#define _GNUstep_H_NSSpellServer

#include <Foundation/NSObject.h>
#include <Foundation/NSRange.h>

// Forward declarations
@class NSConnection;
@class NSMutableArray;
@class NSMutableDictionary;

@interface NSSpellServer : NSObject
{
@private
  id _delegate;
  BOOL _caseSensitive; 
  NSMutableDictionary *_userDictionaries;
  NSString *_currentLanguage;
  NSArray *_ignoredWords;
}

// Checking in Your Service 
- (BOOL)registerLanguage:(NSString *)language
		byVendor:(NSString *)vendor;

// Assigning a Delegate 
- (id)delegate;
- (void)setDelegate:(id)anObject;

// Running the Service 
- (void)run;

// Checking User Dictionaries 
- (BOOL)isWordInUserDictionaries:(NSString *)word
		   caseSensitive:(BOOL)flag;
@end

/**
  This is an informal protocol since the
  NSSpellChecker will need to use a proxy object
  to call these methods.  

  These methods need to be implemented by the spell service
  so that the NSSpellServer instance call call them when
  necessary.
*/
@interface NSObject (NSSpellServerDelegate)
/**
 * <p>
 * This method is called when the user begins spell checking the document.
 * The parameters are: <code>sender</code> the spell server instance which
 * invoked this method, <code>stringToCheck</code> this is the string which
 * the spell service is going to attempt to find misspelled words in,
 * <code>language</code> the language to check in, <code>wordCount</code> the
 * number of words checked, and <code>countOnly</code> a flag which dictates
 * if them method checks the spelling or just counts the words in the given
 * string.
 * </p>
 * <p>
 * Returns a range for any word it finds that is misspelled.
 * </p>
 */
- (NSRange)spellServer:(NSSpellServer *)sender
findMisspelledWordInString:(NSString *)stringToCheck
                  language:(NSString *)language
                 wordCount:(int *)wordCount
                 countOnly:(BOOL)countOnly;

/**
 * Attempts to guess the correct spelling of <code>word</code>. 
 */
- (NSArray *)spellServer:(NSSpellServer *)sender
   suggestGuessesForWord:(NSString *)word
              inLanguage:(NSString *)language;

/**
 * Records the new word in the user's dictionary for the given language.
 */
- (void)spellServer:(NSSpellServer *)sender
       didLearnWord:(NSString *)word
         inLanguage:(NSString *)language;

/**
 * Forgets the given word in the user's dictionary for the given language.
 */
- (void)spellServer:(NSSpellServer *)sender
      didForgetWord:(NSString *)word
         inLanguage:(NSString *)language;
@end
#endif // _GNUstep_H_NSSpellServer
