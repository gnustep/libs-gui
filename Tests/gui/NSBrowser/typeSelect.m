/* A delegate can supply the strings type select searches, veto a keystroke
   before the search starts, and take over the search itself. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSMatrix.h>

static NSArray *rows;

@interface Lister : NSObject
@end

@implementation Lister
- (NSInteger) browser: (NSBrowser *)sender numberOfRowsInColumn: (NSInteger)column
{
  return [rows count];
}
- (void) browser: (NSBrowser *)sender
 willDisplayCell: (id)cell
	   atRow: (NSInteger)row
	  column: (NSInteger)column
{
  [cell setStringValue: [rows objectAtIndex: row]];
  [cell setLeaf: YES];
}
@end

/* The cells say nothing useful, so a match proves the search used the string
   the delegate handed out rather than the cell's own. */
@interface Renamer : Lister
@end

@implementation Renamer
- (void) browser: (NSBrowser *)sender
 willDisplayCell: (id)cell
	   atRow: (NSInteger)row
	  column: (NSInteger)column
{
  [cell setStringValue: @"-"];
  [cell setLeaf: YES];
}
- (NSString *) browser: (NSBrowser *)browser
typeSelectStringForRow: (NSInteger)row
	      inColumn: (NSInteger)column
{
  return [rows objectAtIndex: ([rows count] - 1 - row)];
}
@end

@interface Vetoer : Lister
{
@public
  NSInteger calls;
  BOOL sawNilSearchString;
}
@end

@implementation Vetoer
- (BOOL) browser: (NSBrowser *)browser
shouldTypeSelectForEvent: (NSEvent *)event
withCurrentSearchString: (NSString *)searchString
{
  if (calls == 0 && searchString == nil)
    {
      sawNilSearchString = YES;
    }
  calls++;
  return NO;
}
@end

@interface Searcher : Lister
{
@public
  NSInteger calls;
  NSInteger fromRow;
  NSInteger toRow;
  NSInteger inColumn;
  NSString *forString;
  NSInteger answer;
}
@end

@implementation Searcher
- (void) dealloc
{
  RELEASE(forString);
  DEALLOC
}
- (NSInteger) browser: (NSBrowser *)browser
nextTypeSelectMatchFromRow: (NSInteger)startRow
		toRow: (NSInteger)endRow
	     inColumn: (NSInteger)column
	    forString: (NSString *)searchString
{
  calls++;
  fromRow = startRow;
  toRow = endRow;
  inColumn = column;
  ASSIGN(forString, searchString);
  return answer;
}
@end

static NSBrowser *
browserWithDelegate(id delegate)
{
  NSBrowser *browser = AUTORELEASE([[NSBrowser alloc]
    initWithFrame: NSMakeRect(0, 0, 400, 200)]);

  [browser setDelegate: delegate];
  [browser loadColumnZero];
  [browser selectRow: 0 inColumn: 0];
  return browser;
}

static void
typeCharacter(NSBrowser *browser, NSString *characters)
{
  NSEvent *event = [NSEvent keyEventWithType: NSKeyDown
				    location: NSZeroPoint
			       modifierFlags: 0
				   timestamp: 0.0
				windowNumber: 0
				     context: nil
				  characters: characters
		 charactersIgnoringModifiers: characters
				   isARepeat: NO
				     keyCode: 0];

  [browser keyDown: event];
}

int
main(int argc, const char **argv)
{
  NSBrowser *browser;
  Vetoer *vetoer;
  Searcher *searcher;

  START_SET("NSBrowser type select delegate methods")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  rows = [NSArray arrayWithObjects: @"alpha", @"beta", @"Bravo", @"charlie",
		  @"delta", nil];

  NS_DURING
    {
      browser = browserWithDelegate(AUTORELEASE([[Renamer alloc] init]));
      typeCharacter(browser, @"c");
      PASS([browser selectedRowInColumn: 0] == 1,
	"type select matches the string the delegate supplies for a row");

      vetoer = AUTORELEASE([[Vetoer alloc] init]);
      browser = browserWithDelegate(vetoer);
      typeCharacter(browser, @"d");
      PASS(vetoer->calls == 1,
	"the delegate is asked whether a key should start type select");
      PASS(vetoer->sawNilSearchString,
	"the first keystroke of a search carries no search string yet");
      PASS([browser selectedRowInColumn: 0] == 0,
	"a delegate that refuses the keystroke stops the search");

      searcher = AUTORELEASE([[Searcher alloc] init]);
      searcher->answer = 3;
      browser = browserWithDelegate(searcher);
      typeCharacter(browser, @"b");
      PASS(searcher->calls == 1,
	"a delegate that implements the search is asked to run it");
      PASS(searcher->fromRow == 1 && searcher->toRow == 0,
	"the search starts below the selected row and wraps back to it");
      PASS(searcher->inColumn == 0
	&& [searcher->forString isEqualToString: @"b"],
	"the search is given the column and the characters typed so far");
      PASS([browser selectedRowInColumn: 0] == 3,
	"the row the delegate picks is the row that gets selected");

      typeCharacter(browser, @"r");
      PASS(searcher->calls == 2
	&& [searcher->forString isEqualToString: @"br"],
	"a second keystroke extends the string the delegate searches for");
      PASS(searcher->fromRow == 3,
	"extending the string can match the row already selected");

      searcher = AUTORELEASE([[Searcher alloc] init]);
      searcher->answer = -1;
      browser = browserWithDelegate(searcher);
      typeCharacter(browser, @"b");
      PASS(searcher->calls == 1 && [browser selectedRowInColumn: 0] == 0,
	"a delegate that finds nothing leaves the selection alone");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSBrowser type select delegate methods")


  return 0;
}
