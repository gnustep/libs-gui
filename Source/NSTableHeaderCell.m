#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSColor.h>

@implementation NSTableHeaderCell
- (void) drawInteriorWithFrame: (NSRect)cellFrame
		        inView: (NSView *)controlView
{
  [controlView lockFocus];
  [[NSColor controlShadowColor] set];
  NSRectFill(cellFrame);
  [super drawInteriorWithFrame: cellFrame inView: controlView];
  [controlView unlockFocus];
}
@end
