#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSTabViewItem.h>
#include <AppKit/PSOperators.h>

@implementation NSTabViewItem
- (id) initWithIdentifier:(id)identifier
{
  [super init];

  ASSIGN(item_ident, identifier);
  item_state = NSBackgroundTab;

  return self;
}

// Set identifier.

- (void)setIdentifier:(id)identifier
{
  ASSIGN(item_ident, identifier);
}

- (id)identifier
{
  return item_ident;
}

// Set label for item.

- (void)setLabel:(NSString *)label
{
  ASSIGN(item_label, label);
}

- (NSString *)label
{
  return item_label;
}

- (NSSize)sizeOfLabel:(BOOL)shouldTruncateLabel
{
  NSSize rSize;

  rSize.height = 12;

  if (shouldTruncateLabel) {
    // what is the algo to truncate?
    rSize.width = [[item_tabview font] widthOfString:item_label];
    return rSize;
  } else {
    rSize.width = [[item_tabview font] widthOfString:item_label];
    return rSize;
  }
  return NSZeroSize;
}

// Set view to display when item is clicked.

- (void)setView:(NSView *)view
{
  if (item_view)
    RELEASE(item_view);

  ASSIGN(item_view, view);
}

- (NSView *)view
{
  return item_view;
}

// Set color of tab surface.

- (void)setColor:(NSColor *)color
{
  ASSIGN(item_color, color);
}

- (NSColor *)color
{
  return item_color;
}

// tab state

- (NSTabState)tabState
{
  return item_state;
}

- (void)_setTabState:(NSTabState)tabState
{
  item_state = tabState;
}

// Tab view, this is the "super" view.

- (void)_setTabView:(NSTabView *)tabView
{
  item_tabview = tabView;
}

- (NSTabView *)tabView
{
  return item_tabview;
}

// First responder.

- (void)setInitialFirstResponder:(NSView *)view
{
}

- (id)initialFirstResponder
{
  return nil;
}

// Draw item.

- (void)drawLabel:(BOOL)shouldTruncateLabel
	   inRect:(NSRect)tabRect
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
  NSRect lRect;
  NSRect fRect;

  item_rect = tabRect;

  DPSgsave(ctxt);

  fRect = tabRect;

  if (item_state == NSSelectedTab)
    {
      fRect.origin.y -= 1;
      fRect.size.height += 1;
      [[NSColor controlBackgroundColor] set];
      NSRectFill(fRect);
    }
  else if (item_state == NSBackgroundTab)
    {
      [[NSColor controlBackgroundColor] set];
      NSRectFill(fRect);
    }
  else
    {
      [[NSColor controlBackgroundColor] set];
    }

  lRect = tabRect;
  lRect.origin.y += 3;
  [[item_tabview font] set];

  DPSsetgray(ctxt, 0);
  DPSmoveto(ctxt, lRect.origin.x, lRect.origin.y);
  DPSshow(ctxt, [item_label cString]);

  DPSgrestore(ctxt);
}

// Non spec

- (NSRect) _tabRect
{
  return item_rect;
}

// NSCoding protocol.

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeObject:item_ident];
  [aCoder encodeObject:item_label];
  [aCoder encodeObject:item_view];
  [aCoder encodeObject:item_color];
  [aCoder encodeValueOfObjCType: @encode(NSTabState) at: &item_state];
  [aCoder encodeObject:item_tabview];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &item_ident];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &item_label];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &item_view];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &item_color];
  [aDecoder decodeValueOfObjCType: @encode(NSTabState) at:&item_state];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &item_tabview];

  return self;
}
@end
