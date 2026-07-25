#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTableHeaderView.h>

/* Records whether the column header asked the indicator image to draw,
   without depending on any particular backend's pixels. */
@interface ProbeImage : NSImage
{
@public
  BOOL drewInHeader;
}
@end

@implementation ProbeImage
- (void) drawInRect: (NSRect)dst
           fromRect: (NSRect)src
          operation: (NSCompositingOperation)op
           fraction: (CGFloat)delta
     respectFlipped: (BOOL)respectFlipped
              hints: (NSDictionary *)hints
{
  drewInHeader = YES;
}
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTableView *tv;
  NSTableColumn *col;
  ProbeImage *img;
  NSWindow *w;
  NSTableHeaderView *header;

  START_SET("NSTableView indicator image")

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
      w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 120, 120)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      tv = AUTORELEASE([[NSTableView alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 80)]);
      col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"c"]);
      [col setWidth: 120];
      [tv addTableColumn: col];

      /* Checked against AppKit: no indicator image by default; setting one
         stores it for the column (retained, not copied); nil clears it. */
      PASS([tv indicatorImageInTableColumn: col] == nil,
        "indicatorImageInTableColumn: is nil by default");

      img = AUTORELEASE([[ProbeImage alloc] initWithSize: NSMakeSize(12, 12)]);
      [tv setIndicatorImage: img inTableColumn: col];
      PASS([tv indicatorImageInTableColumn: col] == img,
        "indicatorImageInTableColumn: returns the image set for the column");

      /* The table view and its header must share a window for the header to
         lay out its columns. */
      header = [tv headerView];
      [header setFrame: NSMakeRect(0, 80, 120, 22)];
      [[w contentView] addSubview: tv];
      [[w contentView] addSubview: header];

      /* Drawing the header draws the column's indicator image. */
      img->drewInHeader = NO;
      [header lockFocus];
      [header drawRect: [header bounds]];
      [header unlockFocus];
      PASS(img->drewInHeader == YES,
        "the indicator image is drawn in the column header");

      /* After clearing it, the header no longer draws it. */
      [tv setIndicatorImage: nil inTableColumn: col];
      PASS([tv indicatorImageInTableColumn: col] == nil,
        "setIndicatorImage: nil clears the indicator image");

      img->drewInHeader = NO;
      [header lockFocus];
      [header drawRect: [header bounds]];
      [header unlockFocus];
      PASS(img->drewInHeader == NO,
        "the indicator image is not drawn once it is cleared");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
    }
  NS_ENDHANDLER

  END_SET("NSTableView indicator image")

  DESTROY(arp);
  return 0;
}
