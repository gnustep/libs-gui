#include <AppKit/NSApplication.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/PSOperators.h>

static float GSMenuBarHeight = 25.0; // a guess.

@implementation NSMenuView

// Class methods.

+ (float)menuBarHeight
{
  return GSMenuBarHeight;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
  return YES;
}

// Init methods.

- (id)init
{
  return [self initWithFrame:NSZeroRect];
}

- (id)initWithFrame:(NSRect)aFrame
{
  cellSize = NSMakeSize(110,20);
  menuv_highlightedItemIndex = -1;

  return [super initWithFrame:aFrame];
}

// Our menu.

- (void)setMenu:(NSMenu *)menu
{
  ASSIGN(menuv_menu, menu);
}

- (NSMenu *)menu
{
  return menuv_menu;
}

- (void)setHorizontal:(BOOL)flag
{
  menuv_horizontal = flag;
}

- (BOOL)isHorizontal
{
  return menuv_horizontal;
}

- (void)setFont:(NSFont *)font
{
  ASSIGN(menuv_font, font);
}

- (NSFont *)font
{
  return menuv_font;
}

/* 
 * - (void)setHighlightedItemIndex:(int)index
 *
 * MacOS-X defines this function as the central way of switching to a new
 * highlighted item. The index value is == to the item you want
 * highlighted. When used this method unhighlights the last item (if
 * applicable) and selects the new item. If index == -1 highlighting is
 * turned off.
 *
 * NOTES (Michael Hanni):
 *
 * I modified this method for GNUstep to take submenus into account. This
 * way we get maximum performance while still using a method outside the
 * loop.
 *
 */

- (void)setHighlightedItemIndex:(int)index
{
  NSArray *menu_items = [menuv_menu itemArray];
  id anItem;

  [self lockFocus];

  if (index == -1) {
    if (menuv_highlightedItemIndex != -1) {
      anItem  = [menu_items objectAtIndex:menuv_highlightedItemIndex];

      [anItem highlight:NO
	      withFrame:[self rectOfItemAtIndex:menuv_highlightedItemIndex]
	         inView:self];
      [anItem setState:0];
      menuv_highlightedItemIndex = -1;
    }
  } else if (index >= 0) {
    if ( menuv_highlightedItemIndex != -1 ) {
      anItem  = [menu_items objectAtIndex:menuv_highlightedItemIndex];

      [anItem highlight:NO
	    withFrame:[self rectOfItemAtIndex:menuv_highlightedItemIndex]
	       inView:self];

      if ([anItem hasSubmenu] && ![[anItem target] isTornOff])
        [[anItem target] close];

      [anItem setState:0];
    }

    anItem = [menu_items objectAtIndex:index];

    [anItem highlight:YES
	    withFrame:[self rectOfItemAtIndex:index]
	       inView:self];

    [anItem setState:1];

    if ([anItem hasSubmenu])
      [[anItem target] display];

    // set view needs to be redrawn
    [window flushWindow];

    // set ivar to new index
    menuv_highlightedItemIndex = index;
  }
  [self unlockFocus];
  [window flushWindow];
}

- (int)highlightedItemIndex
{
  return menuv_highlightedItemIndex;
}

- (void)setMenuItemCell:(NSMenuItemCell *)cell
	 forItemAtIndex:(int)index
{
//  [menuv_items insertObject:cell atIndex:index];

  // resize the cell
  [cell setNeedsSizing:YES];

  // resize menuview
  [self setNeedsSizing:YES];
}

- (NSMenuItemCell *)menuItemCellForItemAtIndex:(int)index
{
  return [[menuv_menu itemArray] objectAtIndex:index];
}

- (NSMenuView *)attachedMenuView
{
  return [[menuv_menu attachedMenu] menuView];
}

- (NSMenu *)attachedMenu
{
  return [menuv_menu attachedMenu];
}

- (BOOL)isAttached
{
  return [menuv_menu isAttached];
}

- (BOOL)isTornOff
{
  return [menuv_menu isTornOff];
}

- (void)setHorizontalEdgePadding:(float)pad
{
  menuv_hEdgePad = pad;
}

- (float)horizontalEdgePadding
{
  return menuv_hEdgePad;
}

- (void)itemChanged:(NSNotification *)notification
{
}

- (void)itemAdded:(NSNotification *)notification
{
}

- (void)itemRemoved:(NSNotification *)notification
{
}

// Submenus.

- (void)detachSubmenu
{
}

- (void)attachSubmenuForItemAtIndex:(int)index
{
  // create rect to display submenu in.

  // order window with submenu in it to front.
}

- (void)update
{
//  [menuv_menu update];

  if (menuv_needsSizing)
    [self sizeToFit];
}

- (void)setNeedsSizing:(BOOL)flag
{
  menuv_needsSizing = flag;
}

- (BOOL)needsSizing
{
  return menuv_needsSizing;
}

- (void)sizeToFit
{
  int i;
  int howMany = [[menuv_menu itemArray] count];
  int howHigh = (howMany * cellSize.height) + 21;
  float neededWidth = 0;

  for (i=0;i<[[menuv_menu itemArray] count];i++)
  {
    float aWidth;

    NSMenuItemCell *anItem = [[menuv_menu itemArray] objectAtIndex:i];
    aWidth = [anItem titleWidth];

    if (aWidth > neededWidth)
      neededWidth = aWidth;
  }

  cellSize.width = 7 + neededWidth + 7 + 7 + 5;

  [[self window] setFrame:NSMakeRect(300,300,cellSize.width,howHigh) display:YES];
  [self setFrame:NSMakeRect(0,0,cellSize.width,howHigh-21)];
}

- (float)stateImageOffset
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_stateImageOffset;
}

- (float)stateImageWidth
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_stateImageWidth;
}

- (float)imageAndTitleOffset
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_imageAndTitleOffset;
}

- (float)imageAndTitleWidth
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_imageAndTitleWidth;
}

- (float)keyEquivalentOffset
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_keyEqOffset;
}

- (float)keyEquivalentWidth
{
  if (menuv_needsSizing)
    [self sizeToFit];

  return menuv_keyEqWidth;
}

- (NSRect)innerRect
{
  return [self bounds];

  // this could change if we drew menuitemcells as
  // plain rects with no bezel like in macOSX. Talk to Michael Hanni if
  // you would like to see this configurable.
}

- (NSRect)rectOfItemAtIndex:(int)index
{
  NSRect theRect;

  if (menuv_needsSizing)
    [self sizeToFit];

  if (index == 0)
    theRect.origin.y = [self frame].size.height - cellSize.height;
  else
    theRect.origin.y = [self frame].size.height - (cellSize.height * (index + 1));
  theRect.origin.x = 0;
  theRect.size = cellSize;

  return theRect;
}

- (int)indexOfItemAtPoint:(NSPoint)point
{
  // The MacOSX API says that this method calls - rectOfItemAtIndex for
  // *every* cell to figure this out. Well, instead we will just do some
  // simple math.
  NSRect aRect = [self rectOfItemAtIndex:0];

  // this will need some finnessing but should be close.
  return ([self frame].size.height - point.y) / aRect.size.height;
}

- (void)setNeedsDisplayForItemAtIndex:(int)index
{
  [[[menuv_menu itemArray] objectAtIndex:index] setNeedsDisplay:YES];  
}

- (NSPoint)locationForSubmenu:(NSMenu *)aSubmenu
{
  if (menuv_needsSizing)
    [self sizeToFit];

  // find aSubmenu's parent

  // position aSubmenu's window to be adjacent to its parent.

  // return new origin of window.
  return NSZeroPoint;
}

- (void)resizeWindowWithMaxHeight:(float)maxHeight
{
  // set the menuview's window to max height in order to keep on screen?
}

- (void)setWindowFrameForAttachingToRect:(NSRect)screenRect 
			        onScreen:(NSScreen *)screen
			   preferredEdge:(NSRectEdge)edge
		       popUpSelectedItem:(int)selectedItemIndex
{
  // huh.
}

// Drawing.
 
- (void)drawRect:(NSRect)rect
{
  int i;
  NSArray *menuCells = [menuv_menu itemArray];
  NSRect aRect = [self frame];

  // This code currently doesn't take intercell spacing into account. I'll
  // need to fix that.

  aRect.origin.y = cellSize.height * ([menuCells count] - 1);
  aRect.size = cellSize;

  for (i=0;i<[menuCells count];i++)
  {
    id aCell = [menuCells objectAtIndex:i];

    [aCell drawWithFrame:aRect inView:self];
    aRect.origin.y -= cellSize.height;
  }
}

// Event.

- (void)performActionWithHighlightingForItemAtIndex:(int)index
{
  // for use with key equivalents.
}

- (BOOL)trackWithEvent:(NSEvent *)event
{
  NSPoint       lastLocation = [event locationInWindow];
  float         height = [self frame].size.height;
  int index;
  int lastIndex = 0;
  unsigned      eventMask =   NSLeftMouseUpMask | NSLeftMouseDownMask
                            | NSRightMouseUpMask | NSRightMouseDraggedMask
			    | NSLeftMouseDraggedMask;
  BOOL          done = NO;
  NSApplication *theApp = [NSApplication sharedApplication];  
  NSDate        *theDistantFuture = [NSDate distantFuture];
  int theCount = [[menuv_menu itemArray] count];
  id selectedCell;

// These 3 BOOLs are misnomers. I'll rename them later. -Michael. FIXME.

  BOOL weWereOut = NO;
  BOOL weLeftMenu = NO;
  BOOL weRightMenu = NO;

  // Get our mouse location, regardless of where it may be it the event
  // stream.

  lastLocation = [[self window] mouseLocationOutsideOfEventStream];

  index = (height - lastLocation.y) / cellSize.height;
                                         
  if (index >= 0 && index < theCount) {
    [self setHighlightedItemIndex:index];
    lastIndex = index;
  }
  
  while (!done) {

    event = [theApp nextEventMatchingMask: eventMask
                                untilDate: theDistantFuture
                                   inMode: NSEventTrackingRunLoopMode
                                  dequeue: YES];

    switch ([event type])
    {
      case NSRightMouseUp:
      case NSLeftMouseUp:
      /* right mouse up or left mouse up means we're done */
        done = YES;
        break;
      case NSRightMouseDragged:
      case NSLeftMouseDragged:
        lastLocation = [[self window] mouseLocationOutsideOfEventStream];

#ifdef 0
  NSLog (@"location = (%f, %f, %f)", lastLocation.x, [[self window]
frame].origin.x, [[self window] frame].size.width);  
#endif

        if (lastLocation.x > 0
             && lastLocation.x < [[self window] frame].size.width) {
          lastLocation = [self convertPoint: lastLocation fromView:nil];

          index = (height - lastLocation.y) / cellSize.height;
#ifdef 0                                         
  NSLog (@"location = (%f, %f)", lastLocation.x, lastLocation.y);  
  NSLog (@"index = %d\n", index);
#endif
          if (index >= 0 && index < theCount) {
	    if (index != lastIndex) {
              [self setHighlightedItemIndex:index];
              lastIndex = index;
            } else {
              if (weWereOut) {
                [self setHighlightedItemIndex:index];
                lastIndex = index;
		weWereOut = NO;
	      } 
	    }
	  }
        } else if (lastLocation.x > [[self window] frame].size.width) {
          NSRect aRect = [self rectOfItemAtIndex:lastIndex];
          if (lastLocation.y > aRect.origin.y && lastLocation.y <
	      aRect.origin.y + aRect.size.height && [[[menuv_menu itemArray] objectAtIndex:lastIndex] hasSubmenu]) {
	    weLeftMenu = YES;
            done = YES;
	  }
        } else if (lastLocation.x < 0) {
          if ([menuv_menu supermenu]) {
	    weRightMenu = YES;
            done = YES;
          }
        } else {
// FIXME, Michael. This might be needed... or not?
/*
NSLog(@"This is the final else... its evil\n");
          if (lastIndex >= 0 && lastIndex < theCount) {
            [self setHighlightedItemIndex:-1];
            lastIndex = index;
	    weWereOut = YES;
            [window flushWindow];
          }
*/
        }
        [window flushWindow];
      default:
        break;
    }
  }

  if (!weLeftMenu && !weRightMenu) {
    if (![[[menuv_menu itemArray] objectAtIndex:menuv_highlightedItemIndex] hasSubmenu]) {
      BOOL finished = NO;
      NSMenu *aMenu = menuv_menu;
      selectedCell = [[menuv_menu itemArray] objectAtIndex:index];

      [self setHighlightedItemIndex:-1];

      if ([selectedCell action])
        [menuv_menu performActionForItem:[[menuv_menu itemArray] objectAtIndex:index]];

      if ([selectedCell hasSubmenu])
        [[selectedCell target] close];

      while (!finished) { // Recursive menu close & deselect.
        if ([aMenu supermenu] && ![aMenu isTornOff]) {
          [[[aMenu supermenu] menuView] setHighlightedItemIndex:-1];
          [aMenu close];
	  aMenu = [aMenu supermenu];
        } 
        else
          finished = YES;

        [window flushWindow];
      }
    }
  } else if (weRightMenu) {
    NSPoint cP = [[self window] convertBaseToScreen:lastLocation];

    [self setHighlightedItemIndex:-1];

    if ([menuv_menu supermenu] && ![menuv_menu isTornOff]) {
      [self mouseUp:
            [NSEvent mouseEventWithType:NSLeftMouseUp
                location:cP
                modifierFlags:[event modifierFlags]
                timestamp:[event timestamp]
                windowNumber:[[self window] windowNumber]
                context:[event context] 
                eventNumber:[event eventNumber]
                clickCount:[event clickCount]
                pressure:[event pressure]]];

      [[[menuv_menu supermenu] menuView] mouseDown:
            [NSEvent mouseEventWithType:NSLeftMouseDragged
                location:cP
                modifierFlags:[event modifierFlags]
                timestamp:[event timestamp]
                windowNumber:[[[[menuv_menu supermenu] menuView] window] windowNumber]
                context:[event context] 
                eventNumber:[event eventNumber]
                clickCount:[event clickCount]
                pressure:[event pressure]]];
    }
  } else /* The weLeftMenu case */ {
    NSPoint cP = [[self window] convertBaseToScreen:lastLocation];

    NSLog(@"Urph.\n");

    selectedCell = [[menuv_menu itemArray] objectAtIndex:lastIndex];
    if ([selectedCell hasSubmenu]) {
      [self mouseUp:
            [NSEvent mouseEventWithType:NSLeftMouseUp
                location:cP
                modifierFlags:[event modifierFlags]
                timestamp:[event timestamp]
                windowNumber:[[self window] windowNumber]
                context:[event context] 
                eventNumber:[event eventNumber]
                clickCount:[event clickCount]
                pressure:[event pressure]]];

      [[[selectedCell target] menuView] mouseDown:
            [NSEvent mouseEventWithType:NSLeftMouseDragged
                location:cP
                modifierFlags:[event modifierFlags]
                timestamp:[event timestamp]
                windowNumber:[[[[selectedCell target] menuView] window] windowNumber]
                context:[event context] 
                eventNumber:[event eventNumber]
                clickCount:[event clickCount]
                pressure:[event pressure]]];
    }
  }

  return YES;                
}

- (void)mouseDown:(NSEvent *)theEvent
{
  [self trackWithEvent:theEvent];
}
@end
