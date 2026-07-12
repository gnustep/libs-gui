/* Tests the NSMutableAttributedString AppKit attribute mutators:
 * superscriptRange:, subscriptRange: and unscriptRange: (which raise and lower
 * the superscript level and remove it), and setAlignment:range: (which sets the
 * alignment on the paragraph style over a range).  These are plain value
 * operations.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSValue.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSText.h>
#include <AppKit/NSStringDrawing.h>

static NSMutableAttributedString *
str(void)
{
  return [[[NSMutableAttributedString alloc] initWithString: @"hello world"]
           autorelease];
}

static int
superAt(NSAttributedString *s, NSUInteger i)
{
  return [[s attribute: NSSuperscriptAttributeName
               atIndex: i
        effectiveRange: NULL] intValue];
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSAttributedString mutation")

  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER

  /* superscriptRange raises the level by one each time. */
  {
    NSMutableAttributedString *s = str();

    [s superscriptRange: NSMakeRange(0, 5)];
    pass(superAt(s, 0) == 1, "superscriptRange sets the level to 1");
    [s superscriptRange: NSMakeRange(0, 5)];
    pass(superAt(s, 0) == 2, "superscriptRange raises the level to 2");
  }

  /* subscriptRange lowers the level by one each time. */
  {
    NSMutableAttributedString *s = str();

    [s subscriptRange: NSMakeRange(0, 5)];
    pass(superAt(s, 0) == -1, "subscriptRange sets the level to -1");
    [s subscriptRange: NSMakeRange(0, 5)];
    pass(superAt(s, 0) == -2, "subscriptRange lowers the level to -2");
  }

  /* A superscript then a subscript cancel back to zero. */
  {
    NSMutableAttributedString *s = str();

    [s superscriptRange: NSMakeRange(0, 5)];
    [s subscriptRange: NSMakeRange(0, 5)];
    pass(superAt(s, 0) == 0, "a superscript then a subscript cancel to 0");
  }

  /* unscriptRange removes the attribute entirely. */
  {
    NSMutableAttributedString *s = str();

    [s superscriptRange: NSMakeRange(0, 5)];
    [s unscriptRange: NSMakeRange(0, 5)];
    pass([s attribute: NSSuperscriptAttributeName atIndex: 0
         effectiveRange: NULL] == nil,
      "unscriptRange removes the superscript attribute");
  }

  /* The script mutators raise for a range beyond the string. */
  {
    NSMutableAttributedString *s = str();
    BOOL raised = NO;

    NS_DURING
    {
      [s superscriptRange: NSMakeRange(0, 100)];
    }
    NS_HANDLER
    {
      raised = [[localException name] isEqualToString: NSRangeException];
    }
    NS_ENDHANDLER
    pass(raised, "superscriptRange raises for a range beyond the string");
  }

  /* setAlignment sets the alignment on the paragraph style over the range. */
  {
    NSMutableAttributedString *s = str();
    NSParagraphStyle *ps;

    [s setAlignment: NSRightTextAlignment range: NSMakeRange(0, [s length])];
    ps = [s attribute: NSParagraphStyleAttributeName atIndex: 0
        effectiveRange: NULL];
    pass(ps != nil && [ps alignment] == NSRightTextAlignment,
      "setAlignment sets the paragraph alignment");
  }

  /* setAlignment on a sub-range only affects that range. */
  {
    NSMutableAttributedString *s = str();
    NSParagraphStyle *inRange;

    [s setAlignment: NSCenterTextAlignment range: NSMakeRange(0, 5)];
    inRange = [s attribute: NSParagraphStyleAttributeName atIndex: 0
             effectiveRange: NULL];
    pass(inRange != nil && [inRange alignment] == NSCenterTextAlignment,
      "setAlignment applies to the given range");
    pass([s attribute: NSParagraphStyleAttributeName atIndex: 6
         effectiveRange: NULL] == nil,
      "setAlignment leaves text outside the range without a paragraph style");
  }

  END_SET("NSAttributedString mutation")

  DESTROY(arp);
  return 0;
}
