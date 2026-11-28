#import <AppKit/AppKit.h>
#include "Testing.h"
#include <math.h>

static NSRect
LayoutRect(NSAttributedString *text, CGFloat width)
{
  NSTextStorage *storage = [[NSTextStorage alloc]
    initWithAttributedString: text];
  NSLayoutManager *layout = [[NSLayoutManager alloc] init];
  NSTextContainer *container = [[NSTextContainer alloc]
    initWithContainerSize: NSMakeSize(width, 100000)];
  NSRect rect;

  [storage addLayoutManager: layout];
  [layout addTextContainer: container];
  [layout glyphRangeForTextContainer: container];
  rect = [layout usedRectForTextContainer: container];
  RELEASE(container);
  RELEASE(layout);
  RELEASE(storage);
  return rect;
}

int
main(void)
{
  START_SET("RTF and RTFD layout round trip")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name]
            isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSValue valueWithSize: NSMakeSize(620, 840)], NSPaperSizeDocumentAttribute,
    [NSNumber numberWithDouble: 60], NSLeftMarginDocumentAttribute,
    [NSNumber numberWithDouble: 80], NSRightMarginDocumentAttribute,
    [NSNumber numberWithDouble: 45], NSTopMarginDocumentAttribute,
    [NSNumber numberWithDouble: 65], NSBottomMarginDocumentAttribute,
    [NSValue valueWithSize: NSMakeSize(770, 845)], NSViewSizeDocumentAttribute,
    [NSNumber numberWithInt: 119], NSViewZoomDocumentAttribute,
    [NSNumber numberWithInt: 2], NSViewModeDocumentAttribute, nil];
  CGFloat tails[] = {0, -24, 300};
  int format, t, iteration;

  for (format = 0; format < 2; format++)
    for (t = 0; t < 3; t++)
      {
        NSMutableParagraphStyle *style =
          AUTORELEASE([[NSMutableParagraphStyle alloc] init]);
        [style setTailIndent: tails[t]];
        [style setHeadIndent: 12];
        [style setFirstLineHeadIndent: 24];
        [style setLineSpacing: 3];
        [style setParagraphSpacingBefore: 6];
        [style setParagraphSpacing: 8];
        if (t == 0)
          [style setLineHeightMultiple: 1.5];
        else if (t == 1)
          [style setMinimumLineHeight: 20];
        else
          [style setMaximumLineHeight: 25];
        NSDictionary *run = [NSDictionary dictionaryWithObjectsAndKeys:
          style, NSParagraphStyleAttributeName,
          [NSFont systemFontOfSize: 12], NSFontAttributeName,
          nil];
        NSAttributedString *text = AUTORELEASE([[NSAttributedString alloc]
          initWithString: @"A document must keep the same margins and line "
            @"wrapping when saved and opened again. This paragraph is long "
            @"enough to wrap across several lines, including its indentation."
          attributes: run]);
        NSRect originalRect = LayoutRect(text, 480);
        NSDictionary *documentAttributes = attributes;

        for (iteration = 0; iteration < 3; iteration++)
          {
            NSDictionary *readAttributes = nil;
            NSAttributedString *loaded;
            NSRange range = NSMakeRange(0, [text length]);
            if (format == 0)
              {
                NSData *data = [text RTFFromRange: range
                  documentAttributes: documentAttributes];
                loaded = AUTORELEASE([[NSAttributedString alloc]
                  initWithRTF: data documentAttributes: &readAttributes]);
              }
            else
              {
                NSFileWrapper *wrapper = [text RTFDFileWrapperFromRange: range
                  documentAttributes: documentAttributes];
                loaded = AUTORELEASE([[NSAttributedString alloc]
                  initWithRTFDFileWrapper: wrapper
                  documentAttributes: &readAttributes]);
              }
            PASS_EQUAL([loaded string], [text string], "text survives");
            NSEnumerator *keys = [attributes keyEnumerator];
            NSString *key;
            while ((key = [keys nextObject]))
              PASS_EQUAL([readAttributes objectForKey: key],
                [attributes objectForKey: key], "page/view setting survives");
            NSParagraphStyle *readStyle = [loaded
              attribute: NSParagraphStyleAttributeName atIndex: 0
              effectiveRange: NULL];
            CGFloat expectedTail = tails[t] > 0 ? tails[t] - 480 : tails[t];
            PASS(fabs([readStyle tailIndent] - expectedTail) < 0.01,
                 "trailing margin distance survives");
            PASS([readStyle lineSpacing] == [style lineSpacing]
              && [readStyle paragraphSpacingBefore]
                == [style paragraphSpacingBefore]
              && [readStyle paragraphSpacing] == [style paragraphSpacing]
              && [readStyle lineHeightMultiple] == [style lineHeightMultiple]
              && [readStyle minimumLineHeight] == [style minimumLineHeight]
              && [readStyle maximumLineHeight] == [style maximumLineHeight],
              "paragraph and line spacing survive");
            NSRect rect = LayoutRect(loaded, 480);
            PASS(fabs(rect.size.height - originalRect.size.height) < 0.01
              && fabs(rect.size.width - originalRect.size.width) < 0.01,
              "line wrapping and layout bounds survive");
            text = loaded;
            documentAttributes = readAttributes;
          }
      }
  END_SET("RTF and RTFD layout round trip")
  return 0;
}

