/* 
   NSSpellServer.m

   Description...

   This class provides a 

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Rewritten by: Gregory Casamento <borgheron@yahoo.com>
   Date: 2000

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

#include <gnustep/gui/config.h>
#include <AppKit/NSSpellServer.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSConnection.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSSet.h>

/* User dictionary location */
static NSString *GNU_UserDictionariesDir = @"Dictionaries";

// Function to create name for spell server....
NSString *GSSpellServerName(NSString *vendor,
			     NSString *language)
{
  NSString *serverName = nil;
  
  if(language == nil || vendor == nil) 
    {
      return nil;
    }

  serverName = [[vendor stringByAppendingString: language]
		 stringByAppendingString: @"SpellChecker"];

  return serverName;
}

@implementation NSSpellServer

// Class methods
+ (void)initialize
{
  if (self == [NSSpellServer class])
    {
      // Initial version
      [self setVersion:1];
    }
}

// Non-private Instance methods
- init
{
  [super init];

  _delegate = nil;
  _userDictionaries = [NSMutableDictionary dictionary];

  return self;
}

// Checking in Your Service 
- (BOOL)registerLanguage:(NSString *)language
		byVendor:(NSString *)vendor
{
  NSString *serverName = GSSpellServerName(vendor, language);
  NSConnection *connection = nil;
  BOOL result = NO;

  if(serverName == nil)
    {
      return NO;
    }

  connection = [[NSConnection alloc] init];
  if(connection)
    {
      NSLog(@"Connection created.");
      RETAIN(connection);
      [connection setRootObject: self];
      result = [connection registerName: serverName];
      if(result) NSLog(@"Registered: %@",serverName);
    }

  return result;
}

// Assigning a Delegate 
- (id)delegate
{
  return _delegate;
}

- (void)setDelegate:(id)anObject
{
  RETAIN(anObject);
  ASSIGN(_delegate, anObject);
}

// Running the Service 
- (void)run
{
  // Start the runloop explicitly.
  [[NSRunLoop currentRunLoop] run];
}

// Private method
// Determine the path to the dictionary
- (NSString *)_pathToDictionary: (NSString *)currentLanguage
{
  NSString *path = nil;
  NSString *user_gsroot = nil;
  NSDictionary *env = nil;
  
  env = [[NSProcessInfo processInfo] environment];
  
  user_gsroot = [env objectForKey: @"GNUSTEP_USER_ROOT"];
  if(currentLanguage != nil)
    {
      NSString *dirPath = nil;
      NSFileManager *mgr = [NSFileManager defaultManager];
      
      // Build the path and try to get the dictionary
      dirPath = [user_gsroot stringByAppendingPathComponent: 
			       GNU_UserDictionariesDir];
      path =  [dirPath stringByAppendingPathComponent: currentLanguage];
      
      if (![mgr fileExistsAtPath: path ])
	{
	  if([mgr fileExistsAtPath: dirPath])
	    {
	      // The directory exists create the file.
	      NSArray *emptyDict = [NSArray array];

	      if(![emptyDict writeToFile: path atomically: YES])
		{
		  NSLog(@"Failed to create %@",path);
		  path = nil;
		}
	    }
	  else
	    {
	      // The directory does not exist create it.
	      if([mgr createDirectoryAtPath: dirPath attributes: nil])
		{
		  // Directory created. Now create the empty file.
		  NSArray *emptyDict = [NSArray array];
		  
		  if(![emptyDict writeToFile: path atomically: YES])
		    {
		      NSLog(@"Failed to create %@",path);
		      path = nil;
		    }
		}
	      else
		{
		  NSLog(@"Failed to create %@",dirPath);
		  path = nil;
		}
	    }
	}
    }
  
  NSLog(@"Path = %@", path);
  
  return path;
}

// Private method
// Open up dictionary stored in the user's directory.          
- (NSMutableSet *)_openUserDictionary: (NSString *)language
{
  NSString *path = nil;
  NSMutableSet *words = nil;

  if((words = [_userDictionaries objectForKey: language]) == nil)
    {
      if((path = [self _pathToDictionary: language]) != nil)
	{
	  NSArray *wordarray = [NSArray arrayWithContentsOfFile: path];
	  if(wordarray == nil)
	    {
	      NSLog(@"Unable to load user dictionary from path %@",path);
	    }
	  else
	    {
	      words = [NSMutableSet setWithArray: wordarray];
	      [_userDictionaries setObject: words forKey: language];
	    }
	}
      else
	{
	  NSLog(@"Unable to find user dictionary at: %@", path);
	}
    }
  else
    {
      NSLog(@"User dictionary for language %@ already opened.",
	    language);
    }

  // successful in opening the desired dictionary..
  return words;
}

// Checking User Dictionaries
- (BOOL)_isWord: (NSString *)word
   inDictionary: (NSSet *)dict
  caseSensitive: (BOOL)flag
{
  BOOL result = NO;
  NSString *dictWord = nil;
  NSEnumerator *setEnumerator = nil, *dictEnumerator = nil;

  NSLog(@"Searching user dictionary");
  // Catch the odd cases before they start trouble later on...
  if(word == nil || dict == nil) 
    {
      return NO; // avoid checking, if NIL.
    }

  if([word length] == 0 || [dict count] == 0) 
    {
      return NO; // avoid checking, if has no length. 
    }

  // Check the dictionary for the word...
  dictEnumerator = [dict objectEnumerator];
  while((dictWord = [setEnumerator nextObject]) && result == NO)
    {
      // If the case is important then uppercase both strings
      // and compare, otherwise do the comparison.
      if(flag == NO)
	{
	  NSString *upperWord = [word uppercaseString];
	  NSString *upperDictWord = [dictWord uppercaseString];
	  
	  result = [upperWord isEqualToString: upperDictWord];
	}
      else
	{
	  result = [word isEqualToString: dictWord];
	}
    }
  
  return result;
}

// Checking User Dictionaries
- (BOOL)isWordInUserDictionaries:(NSString *)word
		   caseSensitive:(BOOL)flag
{
  NSArray *userLanguages = [NSUserDefaults userLanguages];  
  NSString *currentLanguage = [userLanguages objectAtIndex: 0];
  NSSet *userDict = [self _openUserDictionary: currentLanguage];
  BOOL result = NO;

  if(userDict)
    {
      result = [self _isWord: word
		     inDictionary: userDict
		     caseSensitive: flag];
    }

  return result;
}

// Save the dictionary stored in user's directory.
- (BOOL)_saveUserDictionary: (NSString *)language
{
  NSString *path = nil;

  if((path = [self _pathToDictionary: language]) != nil)
    {
      NSMutableSet *set = [_userDictionaries objectForKey: language];      
      if(![[set allObjects] writeToFile: path atomically: YES])
	{
	  NSLog(@"Unable to save dictionary to path %@",path);
	  return NO;
	}
    }
  else
    {
      NSLog(@"Unable to save dictionary at: %@", path);
      return NO;
    }
  // successful in saving the desired dictionary..
  return YES; 
}

// Learn a new word and put it into the dictionary
-(BOOL)_learnWord: (NSString *)word
     inDictionary: (NSString *)language
{
  NSMutableSet *set = [self _openUserDictionary: language];
  [set addObject: word];
  NSLog(@"learnWord....");

  NS_DURING
    {
      [_delegate spellServer: self
		 didLearnWord: word
		 inLanguage: language];
    }
  NS_HANDLER
    {
      NSLog(@"Spell server delegate throw exception: %@",
	    [localException reason]);
    }
  NS_ENDHANDLER
  
  return [self _saveUserDictionary: language];
}

// Forget a word and remove it from the dictionary
-(BOOL)_forgetWord: (NSString *)word
      inDictionary: (NSString *)language
{
  NSMutableSet *set = [self _openUserDictionary: language];
  NSLog(@"forgetWord....");
  [set removeObject: word];

  NS_DURING
    {
      [_delegate spellServer: self
		 didForgetWord: word
		 inLanguage: language];
    }
  NS_HANDLER
    {
      NSLog(@"Spell server delegate throw exception: %@",
	    [localException reason]);
    }
  NS_ENDHANDLER

  return [self _saveUserDictionary: language];
}

// Find a misspelled word
- (NSRange)_findMisspelledWordInString: (NSString *)stringToCheck
			      language: (NSString *)language
		   learnedDictionaries: (NSArray *)dictionaries
			     wordCount: (int *)wordCount
			     countOnly: (BOOL)countOnly
{
  NSRange r = NSMakeRange(0,0);
  NSLog(@"In _findMispelledWorkInString:....");

  NSLog(@"%@", _delegate);

  if(dictionaries != nil)
    {
      // Will put code here to check the user dictionary.
    }
  else
    {
      NSLog(@"No user dictionary to check");
    }

  // Forward to delegate
  NS_DURING
    {
      r = [_delegate spellServer: self
		     findMisspelledWordInString: stringToCheck
		     language: language
		     wordCount: wordCount
		     countOnly: countOnly];
    }
  NS_HANDLER
    {
      NSLog(@"Call to delegate caused the following exception: %@",
	    [localException reason]);
    }
  NS_ENDHANDLER

  return r;
}

- (NSArray *)_suggestGuessesForWord: (NSString *)word
		       inLanguage: (NSString *)language
{
  NSArray *words = nil;

  NSLog(@"Entered suggestGuesses....");
  // Forward to delegate
  NS_DURING
    {
      words = [_delegate spellServer: self
			 suggestGuessesForWord: word
			 inLanguage: language];
    }
  NS_HANDLER
    {
      NSLog(@"Call to delegate caused the following exception: %@",
	    [localException reason]);
    }
  NS_ENDHANDLER

  return words;
}
@end
