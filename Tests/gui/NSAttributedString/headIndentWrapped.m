#include "Testing.h"
#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSGeometry.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSStringDrawing.h>
#include <AppKit/NSFont.h>

/* A paragraph head indent shifts every line of the paragraph, so a wrapped
   string laid out in a container of width W with indent I wraps in the same
   column as the un-indented string laid out in a container of width W - I.  The
   convenience bounding rect keeps its origin at zero (the indent is not folded
   into the reported origin), while the reported size reflects that narrower
   column.  Checked against AppKit on a macOS runner. */

#define INDENT 24.0
#define WIDTH  150.0

static NSAttributedString *
para(CGFloat indent)
{
  NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
  NSDictionary *attrs;

  [p setFirstLineHeadIndent: indent];
  [p setHeadIndent: indent];
  [p setLineBreakMode: NSLineBreakByWordWrapping];
  attrs = [NSDictionary dictionaryWithObjectsAndKeys:
             [NSFont systemFontOfSize: 12], NSFontAttributeName,
             p, NSParagraphStyleAttributeName, nil];
  RELEASE(p);
  return AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"The quick brown fox jumps over the lazy dog"
         attributes: attrs]);
}

static NSRect
bounds(NSAttributedString *s, CGFloat w)
{
  return [s boundingRectWithSize: NSMakeSize(w, 1000.0)
                        options: NSStringDrawingUsesLineFragmentOrigin];
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSRect indented, narrowed, full;

  START_SET("NSAttributedString wrapped head indent")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  indented = bounds(para(INDENT), WIDTH);
  narrowed = bounds(para(0.0), WIDTH - INDENT);
  full = bounds(para(0.0), WIDTH);

  PASS(indented.origin.x == 0.0,
    "a head indent leaves the wrapped bounding rect origin at zero");

  PASS(fabs(indented.size.width - narrowed.size.width) < 0.5
    && fabs(indented.size.height - narrowed.size.height) < 0.5,
    "an indented paragraph wraps like the same text in a container narrowed "
    "by the indent (the indent applies to every line, not just the first)");

  PASS(indented.size.height >= full.size.height,
    "indenting every line wraps to at least as many lines as the plain text");

  END_SET("NSAttributedString wrapped head indent")

  DESTROY(arp);
  return 0;
}
