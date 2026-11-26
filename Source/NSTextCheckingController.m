/* Implementation of class NSTextCheckingController
   Copyright (C) 2020 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: 02-08-2020

   This file is part of the GNUstep Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSArray.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import "AppKit/NSAttributedString.h"
#import "AppKit/NSCell.h"
#import "AppKit/NSMenu.h"
#import "AppKit/NSMenuItem.h"
#import "AppKit/NSPanel.h"
#import "AppKit/NSSpellChecker.h"
#import "AppKit/NSTextCheckingController.h"

/* The length asked for when the extent of the text is not known yet. */
#define GS_CHECKING_CHUNK 1024

@interface NSTextCheckingController (Private)

- (NSString *) _substringInRange: (NSRange)range
                     actualRange: (NSRangePointer)actualRange;
- (NSRange) _misspelledRangeInString: (NSString *)string
                          startingAt: (NSUInteger)location;
- (void) _markMisspelledRange: (NSRange)range;
- (void) _clearAnnotationsInRange: (NSRange)range;

@end

@implementation NSTextCheckingController

// initializer
- (instancetype) initWithClient: (id<NSTextCheckingClient>)client
{
  self = [super init];
  if (self != nil)
    {
      _client = client;
      _spellCheckerDocumentTag = [NSSpellChecker uniqueSpellDocumentTag];
    }
  return self;
}

// properties...
- (id<NSTextCheckingClient>) client
{
  return _client;
}

- (NSInteger) spellCheckerDocumentTag
{
  return _spellCheckerDocumentTag;
}

- (void) setSpellCheckerDocumentTag: (NSInteger)tag
{
  _spellCheckerDocumentTag = tag;
}

/* Asks the client for the text of a range. The client is free to return less
   than was asked for, so the range it actually supplied is reported back and
   every range found in the result has to be offset by its location. */
- (NSString *) _substringInRange: (NSRange)range
                     actualRange: (NSRangePointer)actualRange
{
  NSAttributedString *substring;

  substring = [_client annotatedSubstringForProposedRange: range
                                             actualRange: actualRange];
  return [substring string];
}

- (NSRange) _misspelledRangeInString: (NSString *)string
                          startingAt: (NSUInteger)location
{
  int wordCount = 0;

  if (location > [string length])
    {
      return NSMakeRange(NSNotFound, 0);
    }
  /* The count is handed to the spell server as an out parameter, so it needs
     somewhere to write even where the caller has no use for it. */
  return [[NSSpellChecker sharedSpellChecker]
           checkSpellingOfString: string
                      startingAt: location
                        language: nil
                            wrap: NO
          inSpellDocumentWithTag: _spellCheckerDocumentTag
                       wordCount: &wordCount];
}

- (void) _markMisspelledRange: (NSRange)range
{
  NSDictionary *annotations;

  annotations = [NSDictionary dictionaryWithObject:
    [NSNumber numberWithUnsignedInt: NSSpellingStateSpellingFlag]
                                            forKey: NSSpellingStateAttributeName];
  [_client setAnnotations: annotations range: range];
}

- (void) _clearAnnotationsInRange: (NSRange)range
{
  [_client setAnnotations: [NSDictionary dictionary] range: range];
}

// instance methods...
- (void) changeSpelling: (id)sender
{
  NSString *correction;
  NSRange selected;
  NSRange actual;

  if (_client == nil)
    {
      return;
    }

  correction = [[sender selectedCell] stringValue];
  if (correction == nil)
    {
      return;
    }

  selected = [_client selectedRange];
  [self _substringInRange: selected actualRange: &actual];

  [_client replaceCharactersInRange: actual
               withAnnotatedString: [[[NSAttributedString alloc]
                                       initWithString: correction] autorelease]];

  selected = NSMakeRange(actual.location, [correction length]);
  [self _clearAnnotationsInRange: selected];
  [_client selectAndShowRange: selected];
}

- (void) checkSpelling: (id)sender
{
  NSRange selected;
  NSRange actual;
  NSString *text;
  NSRange misspelled;

  if (_client == nil)
    {
      return;
    }

  /* Checking carries on from the end of the selection, so that asking again
     moves to the word after the one being shown. */
  selected = [_client selectedRange];
  text = [self _substringInRange:
    NSMakeRange(selected.location, GS_CHECKING_CHUNK) actualRange: &actual];
  if (text == nil)
    {
      return;
    }

  misspelled = [self _misspelledRangeInString: text
                                   startingAt: NSMaxRange(selected) - actual.location];
  if (misspelled.length == 0)
    {
      return;
    }

  misspelled.location += actual.location;
  [_client selectAndShowRange: misspelled];
  [self _markMisspelledRange: misspelled];
}

- (void) checkTextInRange: (NSRange)range
                    types: (NSTextCheckingTypes)checkingTypes
                  options: (NSDictionary *)options
{
  NSRange actual;
  NSString *text;
  NSUInteger location = 0;

  if (_client == nil)
    {
      return;
    }

  text = [self _substringInRange: range actualRange: &actual];
  if (text == nil)
    {
      return;
    }

  [self _clearAnnotationsInRange: actual];

  if ((checkingTypes & NSTextCheckingTypeSpelling) == 0)
    {
      return;
    }

  /* Every misspelling in the range is marked, not only the first. */
  while (location < [text length])
    {
      NSRange misspelled = [self _misspelledRangeInString: text
                                              startingAt: location];

      if (misspelled.length == 0)
        {
          break;
        }
      location = NSMaxRange(misspelled);
      misspelled.location += actual.location;
      [self _markMisspelledRange: misspelled];
    }
}

- (void) checkTextInSelection: (id)sender
{
  if (_client == nil)
    {
      return;
    }
  [self checkTextInRange: [_client selectedRange]
                   types: NSTextCheckingTypeSpelling
                 options: [NSDictionary dictionary]];
}

- (void) checkTextInDocument: (id)sender
{
  NSRange actual;

  if (_client == nil)
    {
      return;
    }

  /* The extent of the document is whatever the client reports for a range
     that covers everything. */
  [self _substringInRange: NSMakeRange(0, NSUIntegerMax) actualRange: &actual];
  [self checkTextInRange: actual
                   types: NSTextCheckingTypeSpelling
                 options: [NSDictionary dictionary]];
}

- (void) didChangeTextInRange: (NSRange)range
{
  [self considerTextCheckingForRange: range];
}

- (void) considerTextCheckingForRange: (NSRange)range
{
  if (_client == nil)
    {
      return;
    }
  [self checkTextInRange: range
                   types: NSTextCheckingTypeSpelling
                 options: [NSDictionary dictionary]];
}

- (void) didChangeSelectedRange
{
}

- (void) ignoreSpelling: (id)sender
{
  NSString *word = [[sender selectedCell] stringValue];

  if (word != nil)
    {
      [[NSSpellChecker sharedSpellChecker]
        ignoreWord: word inSpellDocumentWithTag: _spellCheckerDocumentTag];
    }
}

- (void) insertedTextInRange: (NSRange)range
{
  [self considerTextCheckingForRange: range];
}

- (void) invalidate
{
  if (_client != nil)
    {
      [[NSSpellChecker sharedSpellChecker]
        closeSpellDocumentWithTag: _spellCheckerDocumentTag];
      _client = nil;
    }
}

- (NSMenu *) menuAtIndex: (NSUInteger)location
      clickedOnSelection: (BOOL)clickedOnSelection
          effectiveRange: (NSRangePointer)effectiveRange
{
  NSAttributedString *substring;
  NSRange actual;
  NSRange marked;
  NSMenu *menu;
  NSEnumerator *guesses;
  NSString *guess;

  if (effectiveRange != NULL)
    {
      *effectiveRange = NSMakeRange(NSNotFound, 0);
    }
  if (_client == nil)
    {
      return nil;
    }

  /* A menu is offered for text that has already been marked, not for text
     that has yet to be checked. */
  substring = [_client annotatedSubstringForProposedRange:
    NSMakeRange(location, 0) actualRange: &actual];
  if ([substring length] == 0)
    {
      return nil;
    }

  marked = NSMakeRange(NSNotFound, 0);
  if ([substring attribute: NSSpellingStateAttributeName
                   atIndex: 0
            effectiveRange: &marked] == nil)
    {
      return nil;
    }

  marked.location += actual.location;
  if (effectiveRange != NULL)
    {
      *effectiveRange = marked;
    }

  menu = [[[NSMenu alloc] initWithTitle: @""] autorelease];
  guesses = [[[NSSpellChecker sharedSpellChecker]
    guessesForWord: [[substring string] substringWithRange:
      NSMakeRange(0, MIN(marked.length, [substring length]))]] objectEnumerator];
  while ((guess = [guesses nextObject]) != nil)
    {
      [[menu addItemWithTitle: guess
                      action: @selector(changeSpelling:)
               keyEquivalent: @""] setTarget: self];
    }
  if ([menu numberOfItems] == 0)
    {
      [menu addItemWithTitle: @"No Guesses Found" action: NULL keyEquivalent: @""];
    }

  return menu;
}

- (void) orderFrontSubstitutionsPanel: (id)sender
{
}

- (void) showGuessPanel: (id)sender
{
  NSSpellChecker *checker = [NSSpellChecker sharedSpellChecker];
  NSRange selected;
  NSRange actual;
  NSString *text;

  if (_client != nil)
    {
      selected = [_client selectedRange];
      text = [self _substringInRange: selected actualRange: &actual];
      if ([text length] > 0)
        {
          [checker updateSpellingPanelWithMisspelledWord: text];
        }
    }
  [[checker spellingPanel] orderFront: sender];
}

- (void) updateCandidates
{
}

- (NSArray *) validAnnotations
{
  return [NSArray arrayWithObjects: NSSpellingStateAttributeName,
                                   NSLinkAttributeName,
                                   NSTextAlternativesAttributeName,
                                   nil];
}

@end
