#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSText.h>
#import <AppKit/NSEvent.h>

int
main(int argc, const char **argv)
{
  START_SET("NSWindow behaviour")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 120, 120)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);

      /* First responder, field editor and content view. Checked against
         AppKit. */
      PASS([w firstResponder] == w,
        "a new window is its own first responder");

      NSText *fe = [w fieldEditor: YES forObject: nil];
      PASS(fe != nil && [fe isKindOfClass: [NSText class]],
        "fieldEditor:forObject: returns an NSText");

      NSView *cv = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 80, 80)]);
      [w setContentView: cv];
      PASS([w contentView] == cv, "setContentView: sets the content view");
      PASS([cv window] == w, "a content view reports its window");

      NSWindow *child = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(20, 30, 60, 60)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: YES]);
      NSWindow *secondChild = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(10, 15, 60, 60)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: YES]);
      NSEvent *moveEvent = [NSEvent
        otherEventWithType: NSAppKitDefined
                  location: NSZeroPoint
             modifierFlags: 0
                 timestamp: 0
              windowNumber: [w windowNumber]
                   context: nil
                   subtype: GSAppKitWindowMoved
                     data1: 40
                     data2: 50];

      [w addChildWindow: child ordered: NSWindowAbove];
      [w addChildWindow: secondChild ordered: NSWindowAbove];
      PASS([[w childWindows] count] == 2,
        "addChildWindow:ordered: can add multiple children");
      PASS([[w childWindows] objectAtIndex: 0] == child
        && [[w childWindows] objectAtIndex: 1] == secondChild,
        "addChildWindow:ordered: appends children ordered above");
      [w sendEvent: moveEvent];
      PASS(NSEqualPoints([child frame].origin, NSMakePoint(60, 80)),
        "a child window follows its parent when the parent moves");
      PASS(NSEqualPoints([secondChild frame].origin, NSMakePoint(50, 65)),
        "all child windows follow their parent when the parent moves");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSWindow behaviour")
  return 0;
}
