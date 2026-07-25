/* Tests the NSAttributedString AppKit attribute-query methods:
 * fontAttributesInRange: (which returns only the character-level font
 * attributes), rulerAttributesInRange: (which returns only the paragraph
 * style), and containsAttachments.  These are plain value operations.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSValue.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSTextAttachment.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSStringDrawing.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSAttributedString attribute queries")

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

  {
    NSFont *font = [NSFont systemFontOfSize: 12];
    NSParagraphStyle *ps = [NSParagraphStyle defaultParagraphStyle];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
      font, NSFontAttributeName,
      [NSColor redColor], NSForegroundColorAttributeName,
      ps, NSParagraphStyleAttributeName,
      [NSNumber numberWithInt: 2], NSKernAttributeName,
      nil];
    NSAttributedString *s = [[NSAttributedString alloc] initWithString: @"hello"
                                                           attributes: attrs];
    NSDictionary *fa = [s fontAttributesInRange: NSMakeRange(0, 5)];
    NSDictionary *ra = [s rulerAttributesInRange: NSMakeRange(0, 5)];

    /* fontAttributesInRange keeps the character-level attributes and drops the
     * paragraph style. */
    PASS([fa objectForKey: NSFontAttributeName] == font,
         "fontAttributesInRange keeps the font");
    PASS([fa objectForKey: NSForegroundColorAttributeName] != nil
      && [[fa objectForKey: NSKernAttributeName] intValue] == 2,
      "fontAttributesInRange keeps the colour and kerning");
    PASS([fa objectForKey: NSParagraphStyleAttributeName] == nil,
      "fontAttributesInRange drops the paragraph style");

    /* rulerAttributesInRange keeps only the paragraph style. */
    PASS([ra objectForKey: NSParagraphStyleAttributeName] == ps,
      "rulerAttributesInRange keeps the paragraph style");
    PASS([ra objectForKey: NSFontAttributeName] == nil
      && [ra count] == 1,
      "rulerAttributesInRange drops the character attributes");
    RELEASE(s);
  }

  /* A string carrying no paragraph style yields an empty ruler dictionary. */
  {
    NSAttributedString *s = [[NSAttributedString alloc]
      initWithString: @"plain"];
    PASS([[s rulerAttributesInRange: NSMakeRange(0, 5)] count] == 0,
      "a string with no paragraph style has empty ruler attributes");
    RELEASE(s);
  }

  /* fontAttributesInRange raises for a range beyond the string. */
  {
    NSAttributedString *s = [[NSAttributedString alloc]
      initWithString: @"abc"];
    BOOL raised = NO;

    NS_DURING
    {
      [s fontAttributesInRange: NSMakeRange(0, 10)];
    }
    NS_HANDLER
    {
      raised = [[localException name] isEqualToString: NSRangeException];
    }
    NS_ENDHANDLER
    RELEASE(s);
    PASS(raised, "fontAttributesInRange raises for a range beyond the string");
  }

  /* containsAttachments is false for plain text and true once an attachment
   * is present. */
  {
    NSAttributedString *plain = [[NSAttributedString alloc]
      initWithString: @"no attachment here"];
    NSTextAttachment *att = [[NSTextAttachment alloc] init];
    NSAttributedString *withAtt =
      [NSAttributedString attributedStringWithAttachment: att];

    PASS([plain containsAttachments] == NO,
      "plain text contains no attachments");
    PASS([withAtt containsAttachments] == YES,
      "an attachment string contains an attachment");
    RELEASE(plain);
    RELEASE(att);
  }

  END_SET("NSAttributedString attribute queries")

  DESTROY(arp);
  return 0;
}
