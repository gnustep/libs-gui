/* Coverage for NSLayoutManager property state that needs no window server: the
   text storage, delegate, text containers, invisible and control character
   flags, hyphenation factor, non-contiguous layout flag and first text view of
   a new layout manager; the flag and delegate round-trips; adding a text
   container; and the link established by adding the layout manager to a text
   storage.  Every assertion here matches AppKit (verified on a macOS runner)
   and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSTextContainer.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSLayoutManager *lm;
  NSTextContainer *tc;
  NSTextStorage *ts;
  id delegate;

  lm = AUTORELEASE([[NSLayoutManager alloc] init]);

  PASS([lm textStorage] == nil, "a new layout manager has no text storage");
  PASS([lm delegate] == nil, "default delegate is nil");
  PASS([[lm textContainers] count] == 0,
       "a new layout manager has no text containers");
  PASS([lm showsInvisibleCharacters] == NO,
       "default showsInvisibleCharacters is NO");
  PASS([lm showsControlCharacters] == NO,
       "default showsControlCharacters is NO");
  PASS([lm hyphenationFactor] == 0.0, "default hyphenationFactor is 0");
  PASS([lm allowsNonContiguousLayout] == NO,
       "default allowsNonContiguousLayout is NO");
  PASS([lm firstTextView] == nil,
       "a new layout manager has no first text view");

  [lm setShowsInvisibleCharacters: YES];
  PASS([lm showsInvisibleCharacters] == YES,
       "showsInvisibleCharacters round-trips");
  [lm setShowsControlCharacters: YES];
  PASS([lm showsControlCharacters] == YES,
       "showsControlCharacters round-trips");

  delegate = AUTORELEASE([[NSObject alloc] init]);
  [lm setDelegate: delegate];
  PASS([lm delegate] == delegate, "delegate round-trips");

  tc = AUTORELEASE([[NSTextContainer alloc]
    initWithContainerSize: NSMakeSize(100, 100)]);
  [lm addTextContainer: tc];
  PASS([[lm textContainers] count] == 1, "a text container can be added");
  PASS([[lm textContainers] containsObject: tc],
       "the added text container is in the list");

  ts = AUTORELEASE([[NSTextStorage alloc] initWithString: @"hi"]);
  [ts addLayoutManager: lm];
  PASS([lm textStorage] == ts,
       "adding the layout manager to a text storage links it");

  DESTROY(arp);
  return 0;
}
