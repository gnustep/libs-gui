/* A text field cell honors the truncating line break modes like NSCell
 * does, and still draws its text at the top of the title rectangle.
 *
 * -[NSAttributedString drawInRect:] is replaced to record what the cell
 * hands to it, so the test checks the drawn string and rectangle rather
 * than pixels.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <objc/runtime.h>

static IMP		originalDrawInRect;
static NSString		*drawnString;
static NSRect		drawnRect;

static void
recordDrawInRect(id self, SEL _cmd, NSRect rect)
{
  ASSIGN(drawnString, [self string]);
  drawnRect = rect;
  ((void (*)(id, SEL, NSRect))originalDrawInRect)(self, _cmd, rect);
}

static NSWindow		*window;

static NSTextField *
makeField(NSRect frame, NSString *text, NSLineBreakMode mode)
{
  NSTextField	*field = [[NSTextField alloc] initWithFrame: frame];

  [field setEditable: NO];
  [field setBezeled: NO];
  [field setBordered: NO];
  [field setDrawsBackground: NO];
  [[field cell] setLineBreakMode: mode];
  [field setStringValue: text];
  [[window contentView] addSubview: field];
  return AUTORELEASE(field);
}

static NSRect
titleRect(NSTextField *field)
{
  return [[field cell] titleRectForBounds: [field bounds]];
}

static void
draw(NSTextField *field)
{
  DESTROY(drawnString);
  drawnRect = NSZeroRect;
  [field display];
}

int
main(int argc, char **argv)
{
  NSAutoreleasePool	*pool = [NSAutoreleasePool new];
  NSString		*text = @"The quick brown fox jumps over the lazy dog";
  NSTextField		*field;
  Method		m;

  START_SET("NSTextFieldCell truncation")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name]
	isEqualToString: NSInternalInconsistencyException])
	{
	  SKIP("It looks like GNUstep backend is not yet installed")
	}
    }
  NS_ENDHANDLER

  m = class_getInstanceMethod([NSAttributedString class],
    @selector(drawInRect:));
  originalDrawInRect = method_setImplementation(m, (IMP)recordDrawInRect);

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(50, 50, 300, 200)
				       styleMask: NSBorderlessWindowMask
					 backing: NSBackingStoreBuffered
					   defer: NO];
  [window orderFrontRegardless];

  field = makeField(NSMakeRect(10, 10, 100, 20), text,
    NSLineBreakByTruncatingTail);
  draw(field);
  PASS([drawnString hasPrefix: @"The"] && [drawnString hasSuffix: @"..."],
    "truncating tail keeps the start and ends with an ellipsis (%s)",
    [drawnString UTF8String]);

  field = makeField(NSMakeRect(10, 40, 100, 20), text,
    NSLineBreakByTruncatingHead);
  draw(field);
  PASS([drawnString hasPrefix: @"..."] && [drawnString hasSuffix: @"dog"],
    "truncating head keeps the end and starts with an ellipsis (%s)",
    [drawnString UTF8String]);

  field = makeField(NSMakeRect(10, 70, 100, 20), text,
    NSLineBreakByTruncatingMiddle);
  draw(field);
  PASS([drawnString hasPrefix: @"The"] && [drawnString hasSuffix: @"dog"]
    && [drawnString rangeOfString: @"..."].location != NSNotFound,
    "truncating middle keeps both ends with an ellipsis between (%s)",
    [drawnString UTF8String]);
  PASS([drawnString length] < [text length],
    "the truncated text is shorter than the original");

  field = makeField(NSMakeRect(10, 100, 100, 20), text,
    NSLineBreakByClipping);
  draw(field);
  PASS_EQUAL(drawnString, text, "clipping draws the whole text");

  field = makeField(NSMakeRect(150, 10, 300, 20), text,
    NSLineBreakByTruncatingTail);
  draw(field);
  PASS_EQUAL(drawnString, text, "text that fits is not truncated");

  field = makeField(NSMakeRect(150, 40, 100, 60), text,
    NSLineBreakByTruncatingTail);
  draw(field);
  PASS([drawnString hasSuffix: @"..."]
    && NSEqualRects(drawnRect, titleRect(field)),
    "a field taller than one line draws at the top of its title rect");

  field = makeField(NSMakeRect(150, 110, 100, 80), text,
    NSLineBreakByWordWrapping);
  [field setStringValue: text];
  draw(field);
  PASS_EQUAL(drawnString, text, "a wrapping field draws the whole text");
  PASS(NSEqualRects(drawnRect, titleRect(field)),
    "a wrapping field draws into its whole title rect");

  END_SET("NSTextFieldCell truncation")

  [pool release];
  return 0;
}
