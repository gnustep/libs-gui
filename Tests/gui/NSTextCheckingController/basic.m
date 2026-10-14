/* NSTextCheckingController drives a client through the NSTextCheckingClient
 * methods. The client here records what it is asked so that the calls each
 * controller method makes can be checked, and holds a string with two
 * misspellings in it.
 *
 * The behaviour asserted here was measured on macOS 26: the controller takes a
 * unique spell document tag of its own, -checkSpelling: selects and marks the
 * next misspelling after the selection, -changeSpelling: replaces the selected
 * range and reselects it at the length of the replacement, -ignoreSpelling:
 * asks the client for nothing, and after -invalidate a check does nothing at
 * all.
 */
#import "ObjectTesting.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/* "sentance" is at 5 with length 8, "mispelled" at 20 with length 9. */
static NSString * const kText = @"This sentance has a mispelled word in it.";

@interface TestClient : NSObject
{
@public
  NSMutableAttributedString *store;
  NSRange selected;
  NSMutableArray *calls;
  NSRange lastAnnotated;
  NSDictionary *lastAnnotations;
}
@end

@implementation TestClient

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      store = [[NSMutableAttributedString alloc] initWithString: kText];
      selected = NSMakeRange(5, 8);
      calls = [[NSMutableArray alloc] init];
      lastAnnotated = NSMakeRange(NSNotFound, 0);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(store);
  RELEASE(calls);
  RELEASE(lastAnnotations);
  [super dealloc];
}

- (NSRange) selectedRange
{
  [calls addObject: @"selectedRange"];
  return selected;
}

- (NSAttributedString *) annotatedSubstringForProposedRange: (NSRange)range
                                                actualRange: (NSRangePointer)actualRange
{
  NSRange clamped = NSIntersectionRange(range, NSMakeRange(0, [store length]));

  [calls addObject: @"annotatedSubstringForProposedRange:actualRange:"];
  if (actualRange != NULL)
    {
      *actualRange = clamped;
    }
  return [store attributedSubstringFromRange: clamped];
}

- (void) selectAndShowRange: (NSRange)range
{
  [calls addObject: @"selectAndShowRange:"];
  selected = range;
}

- (void) setAnnotations: (NSDictionary *)annotations range: (NSRange)range
{
  [calls addObject: @"setAnnotations:range:"];
  lastAnnotated = range;
  ASSIGN(lastAnnotations, annotations);
  if ([annotations count] > 0)
    {
      [store addAttributes: annotations range: range];
    }
  else
    {
      [store removeAttribute: NSSpellingStateAttributeName range: range];
    }
}

- (void) replaceCharactersInRange: (NSRange)range
              withAnnotatedString: (NSAttributedString *)annotatedString
{
  [calls addObject: @"replaceCharactersInRange:withAnnotatedString:"];
  [store replaceCharactersInRange: range withString: [annotatedString string]];
}

- (void) addAnnotations: (NSDictionary *)annotations range: (NSRange)range {}
- (void) removeAnnotation: (NSString *)name range: (NSRange)range {}
- (id) candidateListTouchBarItem { return nil; }
- (NSView *) viewForRange: (NSRange)range
                firstRect: (NSRect *)firstRect
              actualRange: (NSRangePointer)actualRange { return nil; }

@end

int main()
{
  START_SET("NSTextCheckingController")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name]
	isEqualToString: NSInternalInconsistencyException ])
	{
	  SKIP("It looks like GNUstep backend is not yet installed")
	}
    }
  NS_ENDHANDLER

  TestClient *client = AUTORELEASE([[TestClient alloc] init]);
  NSTextCheckingController *c;

  c = AUTORELEASE([[NSTextCheckingController alloc]
    initWithClient: (id<NSTextCheckingClient>)client]);

  PASS(c != nil, "a controller was created")
  PASS([c client] == (id)client, "the controller reports the client it was given")

  /* The controller takes a spell document tag of its own rather than leaving
     it at zero, so that ignored words are kept per document. */
  PASS([c spellCheckerDocumentTag] != 0,
    "the controller has its own spell checker document tag")
  PASS([c spellCheckerDocumentTag] < [NSSpellChecker uniqueSpellDocumentTag],
    "the tag came from the spell checker")

  [c setSpellCheckerDocumentTag: 42];
  PASS([c spellCheckerDocumentTag] == 42, "the tag can be set")

  PASS([[c validAnnotations] containsObject: NSSpellingStateAttributeName],
    "the spelling state is a valid annotation")

  /* -checkSpelling: carries on from the end of the selection, so with
     "sentance" selected it moves to "mispelled" and marks it. */
  START_SET("checkSpelling:")
    if ([[NSSpellChecker sharedSpellChecker] guessesForWord: @"mispelled"] == nil
        && [[NSSpellChecker sharedSpellChecker]
             checkSpellingOfString: kText startingAt: 0].length == 0)
      {
        SKIP("no spell checking service is available")
      }

    [client->calls removeAllObjects];
    [c checkSpelling: nil];

    PASS([client->calls containsObject: @"selectAndShowRange:"],
      "checkSpelling: shows the range it found")
    PASS_EQUAL(NSStringFromRange(client->selected),
      NSStringFromRange(NSMakeRange(20, 9)),
      "checkSpelling: selects the misspelling after the selection")
    PASS_EQUAL(NSStringFromRange(client->lastAnnotated),
      NSStringFromRange(NSMakeRange(20, 9)),
      "checkSpelling: annotates the misspelling it found")
    PASS([[client->lastAnnotations allKeys]
      containsObject: NSSpellingStateAttributeName],
      "checkSpelling: marks the range with the spelling state")

    /* -changeSpelling: replaces the selection and leaves it selected at the
       length of the replacement. */
    {
      NSCell *cell = AUTORELEASE([[NSCell alloc] initTextCell: @"misspelled"]);
      NSMatrix *sender = AUTORELEASE([[NSMatrix alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 20)
                 mode: NSRadioModeMatrix
            prototype: cell
         numberOfRows: 1
      numberOfColumns: 1]);

      [sender selectCellAtRow: 0 column: 0];
      [[sender selectedCell] setStringValue: @"misspelled"];

      [client->calls removeAllObjects];
      [c changeSpelling: sender];

      PASS([client->calls
        containsObject: @"replaceCharactersInRange:withAnnotatedString:"],
        "changeSpelling: replaces the text of the range")
      PASS_EQUAL([client->store string],
        @"This sentance has a misspelled word in it.",
        "changeSpelling: puts the correction in the text")
      PASS_EQUAL(NSStringFromRange(client->selected),
        NSStringFromRange(NSMakeRange(20, 10)),
        "changeSpelling: reselects at the length of the correction")
    }
  END_SET("checkSpelling:")

  /* What each method asks the client for does not depend on a spell checking
     service being present, so it is checked unguarded. */
  [c setSpellCheckerDocumentTag: [NSSpellChecker uniqueSpellDocumentTag]];
  client->selected = NSMakeRange(5, 8);

  [client->calls removeAllObjects];
  [c checkSpelling: nil];
  PASS_EQUAL([client->calls objectAtIndex: 0], @"selectedRange",
    "checkSpelling: starts from the selection")
  PASS([client->calls
    containsObject: @"annotatedSubstringForProposedRange:actualRange:"],
    "checkSpelling: asks the client for the text")

  [client->calls removeAllObjects];
  [c checkTextInRange: NSMakeRange(0, 41)
                types: NSTextCheckingTypeSpelling
              options: [NSDictionary dictionary]];
  PASS([client->calls containsObject: @"setAnnotations:range:"],
    "checkTextInRange: clears the annotations of the range it checked")
  PASS_EQUAL(NSStringFromRange(client->lastAnnotated),
    NSStringFromRange(NSMakeRange(0, 41)),
    "checkTextInRange: covers the whole range it was given")

  [client->calls removeAllObjects];
  [c checkTextInDocument: nil];
  PASS_EQUAL(NSStringFromRange(client->lastAnnotated),
    NSStringFromRange(NSMakeRange(0, 41)),
    "checkTextInDocument: takes the extent from the client")

  [client->calls removeAllObjects];
  [c considerTextCheckingForRange: NSMakeRange(0, 10)];
  PASS_EQUAL(NSStringFromRange(client->lastAnnotated),
    NSStringFromRange(NSMakeRange(0, 10)),
    "considerTextCheckingForRange: checks the range it was given")

  [client->calls removeAllObjects];
  [c insertedTextInRange: NSMakeRange(0, 4)];
  PASS_EQUAL(NSStringFromRange(client->lastAnnotated),
    NSStringFromRange(NSMakeRange(0, 4)),
    "insertedTextInRange: checks the text that was inserted")

  /* A range with no marking on it has no menu. */
  {
    NSRange effective = NSMakeRange(0, 0);

    PASS([c menuAtIndex: 30 clickedOnSelection: NO
         effectiveRange: &effective] == nil,
      "an unmarked range has no menu")
    PASS(effective.location == NSNotFound,
      "an unmarked range reports a not-found effective range")
  }

  /* -ignoreSpelling: is between the controller and the spell checker: the
     client is asked for nothing at all. */
  {
    NSCell *cell = AUTORELEASE([[NSCell alloc] initTextCell: @"Kiefer"]);
    NSMatrix *sender = AUTORELEASE([[NSMatrix alloc]
      initWithFrame: NSMakeRect(0, 0, 100, 20)
               mode: NSRadioModeMatrix
          prototype: cell
       numberOfRows: 1
    numberOfColumns: 1]);

    [sender selectCellAtRow: 0 column: 0];
    [[sender selectedCell] setStringValue: @"Kiefer"];

    [client->calls removeAllObjects];
    [c ignoreSpelling: sender];
    PASS([client->calls count] == 0, "ignoreSpelling: asks the client for nothing")
  }

  /* After -invalidate the controller stops working on the client. */
  [c invalidate];
  [client->calls removeAllObjects];
  [c checkSpelling: nil];
  [c checkTextInSelection: nil];
  [c checkTextInDocument: nil];
  [c considerTextCheckingForRange: NSMakeRange(0, 5)];
  PASS([client->calls count] == 0,
    "an invalidated controller does not touch the client")
  PASS([c menuAtIndex: 5 clickedOnSelection: NO effectiveRange: NULL] == nil,
    "an invalidated controller has no menu")

  END_SET("NSTextCheckingController")

  return 0;
}
