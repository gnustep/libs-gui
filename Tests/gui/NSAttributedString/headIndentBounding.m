#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSStringDrawing.h>
#include <AppKit/NSFont.h>

/* A paragraph first line head indent must not change the rectangle reported by
   -boundingRectWithSize:options:. AppKit ignores the head indent for the
   convenience drawing methods: the origin stays at zero and the width stays the
   text width, so the reported size matches what -drawInRect: paints. Checked
   against AppKit on a macOS runner. */

static NSAttributedString *
noteString(CGFloat indent)
{
  NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
  NSDictionary *attrs;

  [p setFirstLineHeadIndent: indent];
  attrs = [NSDictionary dictionaryWithObjectsAndKeys:
             [NSFont systemFontOfSize: 12], NSFontAttributeName,
             p, NSParagraphStyleAttributeName, nil];
  RELEASE(p);
  return AUTORELEASE([[NSAttributedString alloc]
                       initWithString: @"votre texte en gras"
                            attributes: attrs]);
}

int
main(int argc, char **argv)
{
  NSRect r0, r20;

  START_SET("NSAttributedString head indent bounding rect")

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

  r0 = [noteString(0.0) boundingRectWithSize: NSMakeSize(336, 9999) options: 0];
  r20 = [noteString(20.0) boundingRectWithSize: NSMakeSize(336, 9999) options: 0];

  PASS(r20.origin.x == 0.0,
       "a first line head indent leaves the bounding rect origin at zero");

  PASS(fabs(r20.origin.x - r0.origin.x) < 0.001
    && fabs(r20.origin.y - r0.origin.y) < 0.001
    && fabs(r20.size.width - r0.size.width) < 0.001
    && fabs(r20.size.height - r0.size.height) < 0.001,
       "a first line head indent does not change the bounding rect");

  END_SET("NSAttributedString head indent bounding rect")

  return 0;
}
