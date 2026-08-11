/* Coverage for NSImageView configuration: the defaults (no image, centre
   alignment, no frame, not editable, cut/copy/paste allowed), the alignment,
   scaling and frame-style round-trips, the image round-trip and the
   +imageViewWithImage: constructor.  Checked against AppKit on a macOS runner
   (alignment, scaling and frame style are compared by their enumerated names).
   The view uses the theme and font backend, so the set is skipped when the
   backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSImageView.h>
#include <AppKit/NSImageCell.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSColor.h>

@interface TintRecordingImageCell : NSImageCell
{
  NSColor *_contentTintColor;
  NSUInteger _setContentTintColorCount;
}
- (NSColor *) contentTintColor;
- (void) setContentTintColor: (NSColor *)color;
- (NSUInteger) setContentTintColorCount;
@end

@implementation TintRecordingImageCell
- (void) dealloc
{
  RELEASE(_contentTintColor);
  [super dealloc];
}

- (NSColor *) contentTintColor
{
  return _contentTintColor;
}

- (void) setContentTintColor: (NSColor *)color
{
  _setContentTintColorCount++;
  ASSIGNCOPY(_contentTintColor, color);
}

- (NSUInteger) setContentTintColorCount
{
  return _setContentTintColorCount;
}
@end

int
main(int argc, char **argv)
{
  NSImageView *iv;

  START_SET("NSImageView state")

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

  NS_DURING
    {
      iv = AUTORELEASE([[NSImageView alloc]
        initWithFrame: NSMakeRect(0, 0, 80, 80)]);

      /* Defaults. */
      PASS([iv image] == nil, "a new image view has no image");
      PASS([iv imageAlignment] == NSImageAlignCenter,
           "the default alignment is centre");
      PASS([iv imageFrameStyle] == NSImageFrameNone,
           "the default frame style is none");
      PASS([iv isEditable] == NO, "an image view is not editable by default");
      PASS([iv allowsCutCopyPaste] == YES,
           "cut, copy and paste are allowed by default");
      PASS([iv contentTintColor] == nil,
           "the content tint color is nil by default");
      PASS([[iv cell] respondsToSelector: @selector(contentTintColor)] == NO,
           "the default image cell does not store a content tint color");

      /* Round-trips. */
      [iv setImageAlignment: NSImageAlignTop];
      PASS([iv imageAlignment] == NSImageAlignTop, "setImageAlignment: round trips");
      [iv setImageScaling: NSImageScaleNone];
      PASS([iv imageScaling] == NSImageScaleNone, "setImageScaling: round trips");
      [iv setImageFrameStyle: NSImageFramePhoto];
      PASS([iv imageFrameStyle] == NSImageFramePhoto,
           "setImageFrameStyle: round trips");
      [iv setEditable: YES];
      PASS([iv isEditable] == YES, "setEditable: round trips");
      [iv setContentTintColor: [NSColor redColor]];
      PASS([[iv contentTintColor] isEqual: [NSColor redColor]],
           "setContentTintColor: round trips");
      [iv setContentTintColor: nil];
      PASS([iv contentTintColor] == nil,
           "setContentTintColor: can clear the content tint color");

      /* Unlike NSButton, NSImageView keeps contentTintColor on the view. */
      {
        Class originalCellClass = [NSImageView cellClass];
        TintRecordingImageCell *tintCell;

        [NSImageView setCellClass: [TintRecordingImageCell class]];
        iv = AUTORELEASE([[NSImageView alloc]
          initWithFrame: NSMakeRect(0, 0, 80, 80)]);
        [NSImageView setCellClass: originalCellClass];

        tintCell = (TintRecordingImageCell *)[iv cell];
        [iv setContentTintColor: [NSColor blueColor]];
        PASS([[iv contentTintColor] isEqual: [NSColor blueColor]],
             "setContentTintColor: stores the color on the image view");
        PASS([tintCell contentTintColor] == nil
          && [tintCell setContentTintColorCount] == 0,
             "setContentTintColor: is not forwarded to the image cell");
      }

      /* Image round-trip. */
      NSImage *img = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);
      [iv setImage: img];
      PASS([iv image] == img, "setImage: keeps the image");

      /* +imageViewWithImage: builds a non-editable view holding the image. */
      NSImageView *iv2 = [NSImageView imageViewWithImage: img];
      PASS([iv2 image] == img, "+imageViewWithImage: sets the image");
      PASS([iv2 isEditable] == NO,
           "+imageViewWithImage: makes a non-editable view");
      PASS([iv2 imageFrameStyle] == NSImageFrameNone,
           "+imageViewWithImage: uses no frame");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSImageView state")

  return 0;
}
