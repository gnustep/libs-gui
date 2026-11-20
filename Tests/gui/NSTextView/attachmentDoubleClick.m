/* A double click on an attachment reaches the text view's delegate, as
   -textView:doubleClickedOnCell:inRect:atIndex:, and a delegate without
   that method still gets the word selected.  The text view has to be in a
   window, so the set needs a display.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSTextAttachment.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSWindow.h>

@interface Recorder : NSObject
{
@public
  int doubleClicks;
  NSUInteger index;
}
@end

@implementation Recorder
- (void) textView: (NSTextView *)textView
doubleClickedOnCell: (id <NSTextAttachmentCell>)cell
           inRect: (NSRect)cellFrame
          atIndex: (NSUInteger)charIndex
{
  doubleClicks++;
  index = charIndex;
}
@end

static NSWindow *window = nil;

/* The matching mouse up waits in the queue before the click. */
static void
doubleClick(NSTextView *tv, NSPoint inView)
{
  NSPoint where = [tv convertPoint: inView toView: nil];

  [NSApp postEvent: [NSEvent mouseEventWithType: NSLeftMouseUp
                                       location: where
                                  modifierFlags: 0
                                      timestamp: 0
                                   windowNumber: [window windowNumber]
                                        context: nil
                                    eventNumber: 2
                                     clickCount: 2
                                       pressure: 0.0]
           atStart: NO];
  [tv mouseDown: [NSEvent mouseEventWithType: NSLeftMouseDown
                                    location: where
                               modifierFlags: 0
                                   timestamp: 0
                                windowNumber: [window windowNumber]
                                     context: nil
                                 eventNumber: 1
                                  clickCount: 2
                                    pressure: 1.0]];
}

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTextView *tv;
  NSTextAttachment *attachment;
  NSImage *image;
  NSMutableAttributedString *text;
  NSLayoutManager *lm;
  NSUInteger glyph;
  NSRect line;
  NSPoint origin;
  NSPoint onAttachment;
  NSPoint onWord;
  Recorder *recorder;

  START_SET("NSTextView attachment double click")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(100, 100, 400, 200)
                                       styleMask: NSTitledWindowMask
                                         backing: NSBackingStoreBuffered
                                           defer: NO];
  tv = AUTORELEASE([[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, 400, 200)]);
  [[window contentView] addSubview: tv];
  [window makeKeyAndOrderFront: nil];

  image = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(40, 40)]);
  attachment = AUTORELEASE([[NSTextAttachment alloc] init]);
  [(NSTextAttachmentCell *)[attachment attachmentCell] setImage: image];
  text = AUTORELEASE([[NSMutableAttributedString alloc] initWithString: @"words "]);
  [text appendAttributedString:
    [NSAttributedString attributedStringWithAttachment: attachment]];
  [[tv textStorage] setAttributedString: text];

  lm = [tv layoutManager];
  glyph = [lm glyphRangeForCharacterRange: NSMakeRange(6, 1)
                     actualCharacterRange: NULL].location;
  line = [lm lineFragmentRectForGlyphAtIndex: glyph effectiveRange: NULL];
  origin = [tv textContainerOrigin];
  onAttachment = NSMakePoint(origin.x + NSMinX(line) + [lm locationForGlyphAtIndex: glyph].x + 20,
                             origin.y + NSMinY(line) + [lm locationForGlyphAtIndex: glyph].y - 20);
  onWord = NSMakePoint(origin.x + NSMinX(line) + 10, onAttachment.y);

  recorder = AUTORELEASE([[Recorder alloc] init]);
  [tv setDelegate: (id)recorder];
  doubleClick(tv, onAttachment);
  PASS(recorder->doubleClicks == 1 && recorder->index == 6,
    "a double click on an attachment is sent to the delegate with its index");

  [tv setDelegate: nil];
  [tv setSelectedRange: NSMakeRange(0, 0)];
  doubleClick(tv, onWord);
  PASS(NSEqualRanges([tv selectedRange], NSMakeRange(0, 5)),
    "a double click on a word selects it");

  END_SET("NSTextView attachment double click")

  DESTROY(window);
  DESTROY(arp);
  return 0;
}
