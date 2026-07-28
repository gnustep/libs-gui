/* Menu bars placed in a window sit directly below the title bar, so the top
   edge of the menu has to meet the top of the content area.  A menu placed one
   point higher than that overlaps the title bar when GNUstep draws the window
   decorations itself.  The toolbar, laid out a few lines further down in
   -layout, uses the same reference without any adjustment.
*/

#import "Testing.h"
#import <math.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuView.h>
#import <AppKit/NSWindow.h>
#import <GNUstepGUI/GSWindowDecorationView.h>

@interface NSWindow (GSWindowDecorationViewTesting)
- (GSWindowDecorationView *) windowView;
@end

@interface GSWindowDecorationView (GSWindowDecorationViewTesting)
+ (NSRect) contentRectForFrameRect: (NSRect)aRect
                         styleMask: (NSUInteger)aStyle;
- (void) addMenuView: (NSMenuView *)menuView;
@end

/* The decoration view derives its content rect from its own frame with the
   class method, so recomputing it here gives the rectangle the layout used.
   The instance method is not equivalent: it also subtracts the menu bar. */
static NSRect
contentRectOf(GSWindowDecorationView *wv, NSUInteger style)
{
  return [[wv class] contentRectForFrameRect: [wv frame] styleMask: style];
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("GSWindowDecorationView menu position")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(100, 100, 400, 300)
                  styleMask: style
                    backing: NSBackingStoreBuffered
                      defer: YES]);
      NSMenu *menu = AUTORELEASE([[NSMenu alloc] initWithTitle: @"Test"]);
      NSMenuView *menuView = AUTORELEASE([[NSMenuView alloc]
        initWithFrame: NSZeroRect]);
      GSWindowDecorationView *wv = [w windowView];
      NSRect contentRect;

      [menu addItemWithTitle: @"File" action: NULL keyEquivalent: @""];
      [menuView setMenu: menu];
      [menuView setHorizontal: YES];
      [wv addMenuView: menuView];

      contentRect = contentRectOf(wv, style);
      PASS(fabs(NSMaxY([menuView frame]) - NSMaxY(contentRect)) < 0.5,
        "the menu top edge meets the top of the content area");

      /* The window is laid out again on every resize, so the menu has to stay
         flush there too. */
      [w setFrame: NSMakeRect(100, 100, 500, 400) display: NO];

      contentRect = contentRectOf(wv, style);
      PASS(fabs(NSMaxY([menuView frame]) - NSMaxY(contentRect)) < 0.5,
        "the menu top edge still meets the top of the content area after a resize");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("GSWindowDecorationView menu position")
  DESTROY(arp);
  return 0;
}
