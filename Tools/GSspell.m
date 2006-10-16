/* 
   GSspell.m

   GNUstep spell checker facility.

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: May 2001
   
   This file is part of the GNUstep Project

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
    
   You should have received a copy of the GNU General Public  
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

*/ 

// get the configuration.
#include "config.h"
#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>

#ifdef HAVE_ASPELL_H
#include <aspell.h>
#endif

// A minor category for NSData so that we can convert NSStrings
// into data.
@interface NSData (MethodsForSpellChecker)
+ (id)dataWithString: (NSString *)string;
@end

@implementation NSData (MethodsForSpellChecker)
+ (id)dataWithString: (NSString *)string
{
  NSData *data = [NSData dataWithBytes: (char *)[string cString]
			        length: [string length]];
  return data;
}
@end

@interface GNUSpellChecker : NSObject
{
#ifdef HAVE_ASPELL_H
  AspellConfig          *config;
  AspellSpeller         *speller;
  AspellDocumentChecker *checker;
#endif  
}
@end

@implementation GNUSpellChecker
- (NSRange)spellServer:(NSSpellServer *)sender
findMisspelledWordInString:(NSString *)stringToCheck
                  language:(NSString *)language
                 wordCount:(int *)wordCount
                 countOnly:(BOOL)countOnly
{
  NSRange r = NSMakeRange(0,0);

#ifdef HAVE_ASPELL_H
  if (countOnly)
    {
      NSScanner *inputScanner = [NSScanner scannerWithString: stringToCheck];
      [inputScanner setCharactersToBeSkipped: [NSCharacterSet whitespaceAndNewlineCharacterSet]];      
      while (![inputScanner isAtEnd])
        {
          [inputScanner scanUpToCharactersFromSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]
			intoString: NULL];
          *wordCount++;
	}
    }
  else
    {
      const char *p = [stringToCheck UTF8String];
      AspellToken token;
      int length = strlen(p);

      aspell_document_checker_process(checker, p, length);
      token = aspell_document_checker_next_misspelling(checker);
      r = NSMakeRange(token.offset,token.len);
    }
#else
  NSLog(@"spellServer:findMisspelledWordInString:...  invoked, spell server not configured.");
#endif

  return r;
}

- (NSArray *)spellServer:(NSSpellServer *)sender
   suggestGuessesForWord:(NSString *)word
              inLanguage:(NSString *)language
{
  NSMutableArray *array = [NSMutableArray array];

#ifdef HAVE_ASPELL_H
  {
    const char *p = [word UTF8String];
    int len = strlen(p);
    int words = 0;
    const struct AspellWordList *list = aspell_speller_suggest(speller, p, len);
    AspellStringEnumeration *en;

    words = aspell_word_list_size(list);
    en = aspell_word_list_elements(list);

    // add them to the array.
    while (!aspell_string_enumeration_at_end(en))
      {
	const char *string = aspell_string_enumeration_next(en);
	NSString *word = [NSString stringWithUTF8String: string];
	[array addObject: word];
      }

    // cleanup.
    delete_aspell_string_enumeration(en);
  }
#else
  NSLog(@"spellServer:suggestGuessesForWord:... invoked, spell server not configured");
#endif
  
  return array;
}

- (void)spellServer:(NSSpellServer *)sender
       didLearnWord:(NSString *)word
         inLanguage:(NSString *)language
{
#ifdef HAVE_ASPELL_H
  {
    const char *aword = [word UTF8String];
    aspell_speller_add_to_personal(speller, aword, strlen(aword));
    NSLog(@"Not implemented");
  }
#else
  NSLog(@"spellServer:didLearnWord:inLanguage: invoked, spell server not configured");
#endif
}

- (void)spellServer:(NSSpellServer *)sender
      didForgetWord:(NSString *)word
         inLanguage:(NSString *)language
{
#ifdef HAVE_ASPELL_H
  NSLog(@"Not implemented");
#else
  NSLog(@"spellServer:didForgetWord:inLanguage: invoked, spell server not configured");
#endif
}

- init
{
  self = [super init];
  if (self != nil)
    {
#ifdef HAVE_ASPELL_H
      // initialization...
      config  = new_aspell_config();
      speller = to_aspell_speller(new_aspell_speller(config));
      checker = to_aspell_document_checker(new_aspell_document_checker(speller));
#endif
    }
  return self;
}
@end

#ifdef GNUSTEP
int main(int argc, char** argv, char **env)
#else
int main(int argc, char** argv)
#endif
{
  CREATE_AUTORELEASE_POOL (_pool);
  NSSpellServer *aServer = [[NSSpellServer alloc] init];
  if ([aServer registerLanguage: @"AmericanEnglish" byVendor: @"GNU"]) //&& 
    {
      [aServer setDelegate: [[GNUSpellChecker alloc] init]];
      NSLog(@"Spell server started and waiting.");
      [aServer run];
      NSLog(@"Unexpected death of spell checker");
    }
  else
    {
      NSLog(@"Cannot create spell checker instance");
    }
  RELEASE(_pool);
  return 0;
}
