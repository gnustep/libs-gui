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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

*/ 

#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>
#include <Foundation/NSString.h>

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
  NSTask *_spellTask;
}
@end

@implementation GNUSpellChecker
// Find the ispell executable in the user's path.
- (NSString *)_locateIspell
{
  NSDictionary *env = [[NSProcessInfo processInfo] environment];
  NSString *path = [env objectForKey: @"PATH"], *fullPath = nil;
  NSScanner *pathScanner = nil;
  BOOL found = NO;
  NSFileManager *fm = [NSFileManager defaultManager];
 
  pathScanner = [NSScanner scannerWithString: path];
  while(![pathScanner isAtEnd]  && !found)
    {
      NSString *directory = nil;
      BOOL scanned = NO;

      scanned = [pathScanner scanUpToString: @":" intoString: &directory];
      [pathScanner scanString: @":" intoString: NULL];
      fullPath = [directory stringByAppendingString: @"/ispell"];
      found = [fm fileExistsAtPath: fullPath];
    }
    
  if(!found)
    {
      fullPath = nil;
    }

  return fullPath;
}

// Start the ispell command.
// The -a option allows the program to accept commands 
// from stdin and put output on stdout.
- (id)_runIspell
{
  NSArray *args = [NSArray arrayWithObject: @"-a"];
  if(_spellTask == nil)
    {
      NSString *pathToIspell = [self _locateIspell];
      NSPipe 
	*inputPipe = [NSPipe pipe],
	*outputPipe = [NSPipe pipe];

      _spellTask = [[NSTask alloc] init];      
      [_spellTask setLaunchPath: pathToIspell];
      [_spellTask setArguments: args];      
      [_spellTask setStandardInput: inputPipe];
      [_spellTask setStandardOutput: outputPipe];
      [_spellTask launch];
      
      if(![_spellTask isRunning])
	{
	  NSLog(@"ispell failed to launch");
	}
      else
	{
	  // Enter terse mode immediately upon startup.
	  NSString *terseCommand = @"!", *outstring = nil;
	  NSData 
	    *data = [NSData dataWithString: terseCommand], 
	    *output = nil;

	  // Sleep until ispell starts
	  [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1]];
	  [[[_spellTask standardInput] fileHandleForWriting] writeData: data];
	  output = [[[_spellTask standardOutput] fileHandleForReading] availableData];
	  outstring = [NSString stringWithCString: (char *)[output bytes]];
	}
    }

  return _spellTask;
}

- (void)_handleTaskTermination: (NSNotification *)notification
{
  NSLog(@"ispell process died");
  _spellTask = nil;
}

- (NSRange)spellServer:(NSSpellServer *)sender
findMisspelledWordInString:(NSString *)stringToCheck
                  language:(NSString *)language
                 wordCount:(int *)wordCount
                 countOnly:(BOOL)countOnly
{
  int length = 0;
  NSRange r = NSMakeRange(0,0);
  char *p = 0;

  [self _runIspell];
  if(_spellTask != nil)
    {
      NSCharacterSet *newlineSet = nil;
      NSRange newlineRange;
      NSString 
	*checkCommand = @"^", *outputString = nil;
      NSData 
	*inputData = nil,
	*outputData = nil;
      NSScanner 
	*inputScanner = nil;
      
      NSFileHandle 
	*standardInput  = [[_spellTask standardInput]  fileHandleForWriting],
	*standardOutput = [[_spellTask standardOutput] fileHandleForReading];

      unsigned int i = 0;

      newlineRange.location = (unsigned char)'\n';
      newlineRange.length = 1;
      newlineSet = [NSCharacterSet characterSetWithRange: newlineRange];
      inputScanner = [NSScanner scannerWithString: stringToCheck];
      [inputScanner setCharactersToBeSkipped: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      
      *wordCount = 0;
      while(![inputScanner isAtEnd])
	{
	  NSScanner *outputScanner = nil;
	  NSString  *outputString = nil, *fullCommand = nil, *inputString = nil;
	  NSData *returnChar = [NSData dataWithBytes: "\n"
				              length: 1];

	  [inputScanner scanUpToCharactersFromSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]
			               intoString: &inputString];
	  
	  fullCommand = [checkCommand stringByAppendingString: inputString];
	  fullCommand = [fullCommand stringByAppendingString: @"\n"];
	  inputData = [NSData dataWithString: fullCommand];
	  [standardInput writeData: inputData];
	  [standardInput writeData: returnChar];
	  outputData = [standardOutput availableData];
	  p = (char *)[outputData bytes];
	  outputString = [NSString stringWithCString: p];

	  // Put everything back into a string for scanning
	  outputScanner = [NSScanner scannerWithString: outputString];
	  
	  // Check to see if the first character in the byte stream is
	  // a carriage return.   If so, no spelling errors were found.
	  if(p[0] != '\n' && !countOnly)
	    {
	      NSString *indicator = nil;
	      NSString *word = nil,
		*count = nil,
		*offset = nil;
	      int start = 0;

	      [outputScanner scanUpToString: @" " intoString: &indicator];
	      if([indicator isEqualToString: @"&"]
		 || [indicator isEqualToString: @"?"])
		{
		  BOOL found = NO;
		  [outputScanner scanUpToString: @" " intoString: &word];
		  [outputScanner scanUpToString: @" " intoString: &count];
		  [outputScanner scanUpToString: @":" intoString: &offset];
		    
		  found = [sender isWordInUserDictionaries: word caseSensitive: NO];
		  if(!found)
		    {
		      start = [inputScanner scanLocation] - [word length];
		      r = NSMakeRange(start, [word length]);
		      break;
		    }
		}
	      else
		if([indicator isEqualToString: @"#"])
		  {
		    BOOL found = NO;
		    [outputScanner scanUpToString: @" " intoString: &word];
		    [outputScanner scanUpToString: @" " intoString: &offset];
		    
		    found = [sender isWordInUserDictionaries: word caseSensitive: NO];
		    if(!found)
		      {
			start = [inputScanner scanLocation] - [word length];
			r = NSMakeRange(start, [word length]);
			break;
		      }
		  }
	    }
	  *wordCount++;
	}
    }

  return r;
}

- (NSArray *)spellServer:(NSSpellServer *)sender
   suggestGuessesForWord:(NSString *)word
              inLanguage:(NSString *)language
{
  NSMutableArray *array = [NSMutableArray array];
  NSString *checkCommand = @"^", *fullCommand = nil, *outputString = nil;
  NSScanner *inputScanner = nil;
  NSData   *inputData = nil, *outputData = nil;
  NSData *returnChar = [NSData dataWithBytes: "\n"
			              length: 1];
  NSFileHandle 
    *standardInput  = [[[self _runIspell] standardInput]  fileHandleForWriting],
    *standardOutput = [[[self _runIspell] standardOutput] fileHandleForReading];
  char *p = 0;
  unsigned int i = 0;
  BOOL stop = NO;

  fullCommand = [checkCommand stringByAppendingString: word];
  inputData = [NSData dataWithString: fullCommand];
  [standardInput writeData: inputData];
  [standardInput writeData: returnChar];

  // Check to see if the first character in the byte stream is
  // a carriage return.   If so, no spelling errors were found.
  outputData = [standardOutput availableData];

  // look at the results
  p = (char *)[outputData bytes];
  if(p[0] != '\n')
    {
      NSString *indicator = nil;
      NSString *word = nil;
      NSScanner *outputScanner = nil;
      int i = 0;

      // replace the first carriage return with a NULL to prevent the
      // NSString from being constructed incorrectly
      while(p[i] != '\n')
	{
	  i++;
	}
      p[i] = 0;

      // Put everything back into a string for scanning
      outputString = [NSString stringWithCString: p];
      outputScanner = [NSScanner scannerWithString: outputString]; 
      [outputScanner setCharactersToBeSkipped: [NSCharacterSet whitespaceAndNewlineCharacterSet]];

      // Scan the string for the indicator.  Either & or #.
      // The "&" and "?" symbols indicates a misspelled word for which ispell can suggest corrections
      // whereas the "#" symbol represents a word for which ispell cannot suggest corrections. 
      [outputScanner scanUpToString: @" " intoString: &indicator];
      if([indicator isEqualToString: @"&"] 
	 || [indicator isEqualToString: @"?"])
	{
	  // get past the ": " on ispell's output line
	  [outputScanner scanUpToString: @": " intoString: NULL];
	  [outputScanner scanString: @": " intoString: NULL];
	  while(![outputScanner isAtEnd])
	    {
	      NSString *guessWord = nil;

	      if([outputScanner scanUpToString: @", " intoString: &guessWord])
		{
		  [outputScanner scanString: @", " intoString: NULL];
		}
	      else
		if(![outputScanner scanUpToCharactersFromSet: 
				     [NSCharacterSet whitespaceAndNewlineCharacterSet]
				   intoString: &guessWord])		  	      
		  {
		    break;
		  }
	      
	      if(guessWord != nil)
		{
		  [array addObject: guessWord];
		}
	    }
	}
      else
	if([indicator isEqualToString: @"#"])
	  {
	    [outputScanner scanUpToString: @" " intoString: &word];
	  }
    }
  
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

- init
{
  [super init];
  [[NSNotificationCenter defaultCenter] 
    addObserver: self
       selector: @selector(_handleTaskTermination:)
           name: NSTaskDidTerminateNotification
         object: nil];
  [self _runIspell];

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
