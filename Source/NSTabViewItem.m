#include <AppKit/NSTabViewItem.h>

@implementation NSTabViewItem
- (id) initWithIdentifier:(id)identifier
{
  [super init];

  ASSIGN(item_ident, identifier);

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
  if (shouldTruncateLabel) {
  } else {
  }

  return NSZeroSize;
}

// Set view to display when item is clicked.

- (void)setView:(NSView *)view
{
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

// Tab view, this is the "super" view.

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
  // Implement in backend?
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
