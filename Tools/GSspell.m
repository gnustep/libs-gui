/* 
   GSspell.m

   GNUstep spell checker facility.

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <borgheron@yahoo.com>
   Date: May 2001
   
   This file is part of the GNUstep Project

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
    
   You should have received a copy of the GNU General Public  
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

*/ 

#include <AppKit/AppKit.h>

@interface GNUSpellChecker : NSObject
@end

@implementation GNUSpellChecker
- (NSRange)spellServer:(NSSpellServer *)sender
findMisspelledWordInString:(NSString *)stringToCheck
                  language:(NSString *)language
                 wordCount:(int *)wordCount
                 countOnly:(BOOL)countOnly
{
  int length = 0;
  NSRange r = NSMakeRange(0,0);

  NSLog(@"Stubbed out - Finding misspelled word");
  
  length = [stringToCheck length];
  if(length < 10)
    {
      r.length = length;
    }
  else
    {
      r.length = 10;
    }
    
  return r;
}

- (NSArray *)spellServer:(NSSpellServer *)sender
   suggestGuessesForWord:(NSString *)word
              inLanguage:(NSString *)language
{
  NSArray *array = [NSArray arrayWithObjects: word, @"test", nil];

  NSLog(@"Stubbed out - returning test guess results: %@", array);
  
  return array;
}

- (void)spellServer:(NSSpellServer *)sender
       didLearnWord:(NSString *)word
         inLanguage:(NSString *)language
{
  NSLog(@"Stubbed out -- Learning word: %@", word);
}

- (void)spellServer:(NSSpellServer *)sender
      didForgetWord:(NSString *)word
         inLanguage:(NSString *)language
{
  NSLog(@"Stubbed out -- Forgetting word: %@", word);
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
  if( [aServer registerLanguage: @"English" byVendor: @"GNU"] ) //&& 
    //  [aServer registerLanguage: @"Spanish" byVendor: @"GNU"] &&
    //  [aServer registerLanguage: @"French"  byVendor: @"GNU"] )
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
