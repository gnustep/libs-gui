#include <gnustep/gui/config.h>  
#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/PSOperators.h>

@implementation NSPopUpButtonCell
+ (void) initialize
{
  if (self == [NSPopUpButtonCell class])
    [self setVersion: 1];
}

- (id)init
{
  return [super init];   
}
    
- (void)drawWithFrame:(NSRect)cellFrame
               inView:(NSView*)view  
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
  NSRect rect = cellFrame;
  NSRect arect = cellFrame;
  NSPoint point;

  NSDrawButton(cellFrame, cellFrame);
  
  arect.size.width -= 4;
  arect.size.height -= 4;
  arect.origin.x += 2;
  arect.origin.y += 2;
 
  if (cell_highlighted) {
    [[NSColor whiteColor] set];
    NSRectFill(arect);
  } else {
    [[NSColor lightGrayColor] set];  
    NSRectFill(arect);
  }

  [cell_font set];

  point.y = rect.origin.y + (rect.size.height/2) - 4;
  point.x = rect.origin.x + xDist;
  rect.origin = point;  

  [[NSColor blackColor] set];
  
  // Draw the title.

  DPSmoveto(ctxt, rect.origin.x, rect.origin.y);
  DPSshow(ctxt, [contents cString]);

  rect.size.width = 15;                         // calc image rect
  rect.size.height = cellFrame.size.height;
  rect.origin.x = cellFrame.origin.x + cellFrame.size.width - (6 + 11);
  rect.origin.y = cellFrame.origin.y;
  
  if ([(NSPopUpButton *)view titleOfSelectedItem] == contents)
  {
    [super _drawImage:[NSImage imageNamed:@"common_Nibble"] inFrame:rect];
  }
}
@end
