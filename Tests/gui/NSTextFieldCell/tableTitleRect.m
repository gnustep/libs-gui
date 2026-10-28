#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSClipView.h>
#include <AppKit/NSStringDrawing.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSText.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSWindow.h>

@interface Source : NSObject
@end

@implementation Source
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tv
{
  return 3;
}
- (id) tableView: (NSTableView *)tv
  objectValueForTableColumn: (NSTableColumn *)col
             row: (NSInteger)row
{
  return @"Row";
}
- (void) tableView: (NSTableView *)tv
    setObjectValue: (id)value
    forTableColumn: (NSTableColumn *)col
               row: (NSInteger)row
{
}
@end

int
main(int argc, char **argv)
{
  START_SET("NSTextFieldCell title rect in a table view")

  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      {
        SKIP("It looks like GNUstep backend is not yet installed")
      }
  }
  NS_ENDHANDLER

  {
    NSRect bounds = NSMakeRect(0, 0, 200, 40);
    NSTableView *table = AUTORELEASE([[NSTableView alloc]
      initWithFrame: NSMakeRect(0, 0, 200, 200)]);
    NSTextFieldCell *cell = AUTORELEASE([[NSTextFieldCell alloc]
      initTextCell: @"Row"]);
    CGFloat textHeight = [[cell attributedStringValue] size].height;
    NSRect r;

    [cell setLineBreakMode: NSLineBreakByTruncatingTail];

    r = [cell titleRectForBounds: bounds];
    PASS(NSEqualRects(r, bounds),
      "outside a table view the title rect is the whole cell");

    [cell setControlView: table];
    r = [cell titleRectForBounds: bounds];
    PASS(fabs(NSHeight(r) - textHeight) <= 1.0,
      "in a table view the title rect is one line high");
    PASS(fabs(NSMidY(r) - NSMidY(bounds)) <= 1.0,
      "in a table view the title rect is vertically centered");
    PASS(NSMinX(r) == NSMinX(bounds) && NSWidth(r) == NSWidth(bounds),
      "centering does not change the horizontal extent");

    r = [cell titleRectForBounds: NSMakeRect(0, 0, 200, textHeight - 2)];
    PASS(NSHeight(r) == textHeight - 2,
      "a cell lower than its text keeps the whole rect");

    [cell setStringValue: @""];
    r = [cell titleRectForBounds: bounds];
    PASS(NSHeight(r) > 0 && fabs(NSMidY(r) - NSMidY(bounds)) <= 1.0,
      "an empty cell keeps a centered line for the field editor");

    [cell setStringValue: @"Row"];
    [cell setWraps: YES];
    r = [cell titleRectForBounds: bounds];
    PASS(NSEqualRects(r, bounds),
      "a wrapping cell keeps the whole rect");
  }

  NS_DURING
  {
    Source *source = AUTORELEASE([[Source alloc] init]);
    NSWindow *window = AUTORELEASE([[NSWindow alloc]
      initWithContentRect: NSMakeRect(100, 100, 300, 300)
                styleMask: NSTitledWindowMask
                  backing: NSBackingStoreBuffered
                    defer: NO]);
    NSTableView *table = AUTORELEASE([[NSTableView alloc]
      initWithFrame: NSMakeRect(0, 0, 300, 300)]);
    NSTableColumn *column = AUTORELEASE([[NSTableColumn alloc]
      initWithIdentifier: @"name"]);
    NSRect cellFrame;
    NSRect editorFrame;
    NSView *editorView;

    [column setWidth: 200];
    [table addTableColumn: column];
    [table setRowHeight: 40];
    [table setDataSource: source];
    [[window contentView] addSubview: table];
    [table reloadData];
    [table selectRow: 1 byExtendingSelection: NO];
    [table editColumn: 0 row: 1 withEvent: nil select: YES];

    editorView = [table currentEditor];
    if ([[editorView superview] isKindOfClass: [NSClipView class]])
      {
        editorView = [editorView superview];
      }
    editorFrame = [editorView frame];
    cellFrame = [table frameOfCellAtColumn: 0 row: 1];
    PASS([table currentEditor] != nil, "the cell is being edited");
    PASS(NSHeight(editorFrame) < NSHeight(cellFrame)
      && fabs(NSMidY(editorFrame) - NSMidY(cellFrame)) <= 1.0,
      "the field editor is vertically centered in the cell");
    [table abortEditing];
  }
  NS_HANDLER
  {
    PASS(0, "editing a table cell raised %s",
      [[localException reason] UTF8String]);
  }
  NS_ENDHANDLER

  END_SET("NSTextFieldCell title rect in a table view")

  return 0;
}
