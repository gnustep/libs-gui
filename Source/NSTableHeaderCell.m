#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSColor.h>

@implementation NSTableHeaderCell
- (void)drawInteriorWithFrame:(NSRect)cellFrame
		       inView:(NSView *)controlView
{
    [[NSColor darkGrayColor] set];
    NSRectFill(cellFrame);
    [super drawInteriorWithFrame: cellFrame inView: controlView];
}
@end
