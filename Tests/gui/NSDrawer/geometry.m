#import "Testing.h"
#import <AppKit/AppKit.h>

/* A sliding drawer must reveal content, rather than squash its controls. */
@interface DrawerContent : NSView
{
@public
  int axis;
  BOOL stable;
}

@end

@implementation DrawerContent

- (void) setFrame: (NSRect)frame
{
  if ((axis == 1 && frame.size.width != 160)
      || (axis == 2 && frame.size.height != 120))
    stable = NO;
  [super setFrame: frame];
}

@end

@interface DrawerDelegate : NSObject
{
@public
  BOOL veto;
  BOOL resize;
  NSMutableArray *states;
}

@end

@implementation DrawerDelegate

- (id) init
{
  self = [super init];
  if (self != nil)
    states = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  RELEASE(states);
  DEALLOC;
}

- (BOOL) drawerShouldOpen: (NSDrawer *)drawer
{
  return !veto;
}

- (BOOL) drawerShouldClose: (NSDrawer *)drawer
{
  return !veto;
}

- (NSSize) drawerWillResizeContents: (NSDrawer *)drawer toSize: (NSSize)size
{
  return resize ? NSMakeSize(175, 135) : size;
}

- (void) record: (NSNotification *)notification
{
  [states addObject: [NSNumber numberWithInteger: [[notification object] state]]];
}

- (void) drawerWillOpen: (NSNotification *)notification
{
  [self record: notification];
}

- (void) drawerDidOpen: (NSNotification *)notification
{
  [self record: notification];
}

- (void) drawerWillClose: (NSNotification *)notification
{
  [self record: notification];
}

- (void) drawerDidClose: (NSNotification *)notification
{
  [self record: notification];
}

@end

int
main(void)
{
  START_SET("NSDrawer geometry and lifecycle")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if (getenv("GS_REQUIRE_DRAWER_DISPLAY") == NULL
        && [[localException name] isEqual: NSInternalInconsistencyException])
      SKIP("GNUstep backend unavailable")
    else
      [localException raise];
  NS_ENDHANDLER

  {
    NSWindow *parent = AUTORELEASE([[NSWindow alloc]
      initWithContentRect: NSMakeRect(300, 300, 400, 300)
                styleMask: NSTitledWindowMask
                  backing: NSBackingStoreBuffered defer: NO]);
    NSDrawer *drawer = AUTORELEASE([[NSDrawer alloc]
      initWithContentSize: NSMakeSize(160, 120) preferredEdge: NSMaxXEdge]);
    DrawerDelegate *delegate = AUTORELEASE([[DrawerDelegate alloc] init]);
    DrawerContent *view = AUTORELEASE([[DrawerContent alloc]
      initWithFrame: NSMakeRect(0, 0, 25, 35)]);
    NSWindow *window;
    NSRectEdge edges[] = { NSMinXEdge, NSMaxXEdge, NSMinYEdge, NSMaxYEdge };
    unsigned i;

    {
      NSDrawer *tiny = AUTORELEASE([[NSDrawer alloc]
        initWithContentSize: NSMakeSize(1, 1) preferredEdge: NSMinXEdge]);
      PASS(NSEqualSizes([[tiny contentView] frame].size, NSMakeSize(1, 1)),
        "tiny initial content sizes do not reduce the drawer trim");
    }
    [parent setReleasedWhenClosed: NO];
    [drawer setContentView: view];
    PASS(NSEqualSizes([view frame].size, [drawer contentSize]),
      "replacing the content view preserves and fills the content size");
    [drawer setMinContentSize: NSMakeSize(80, 60)];
    [drawer setMaxContentSize: NSMakeSize(220, 180)];
    [drawer setContentSize: NSMakeSize(10, 500)];
    PASS(NSEqualSizes([drawer contentSize], NSMakeSize(80, 180)),
      "requested size is constrained by the minimum and maximum");
    [drawer setDelegate: delegate];
    delegate->resize = YES;
    [drawer setContentSize: NSMakeSize(160, 120)];
    PASS(NSEqualSizes([drawer contentSize], NSMakeSize(175, 135)),
      "the resize delegate controls the content size");
    delegate->resize = NO;
    [drawer setContentSize: NSMakeSize(160, 120)];
    [drawer setParentWindow: parent];
    [drawer setLeadingOffset: 12];
    [drawer setTrailingOffset: 18];
    [parent orderFront: nil];
    window = [view window];
    delegate->veto = YES;
    [drawer open];
    PASS([drawer state] == NSDrawerClosedState && [delegate->states count] == 0,
      "an opening veto leaves the drawer closed without notifications");
    delegate->veto = NO;

    for (i = 0; i < 4; i++)
      {
        NSRect f, p = [parent frame];
        NSRect c = [[parent contentView] convertRect:
          [[parent contentView] bounds] toView: nil];
        view->axis = (edges[i] == NSMinXEdge || edges[i] == NSMaxXEdge) ? 1 : 2;
        view->stable = YES;
        [drawer openOnEdge: edges[i]];
        f = [window frame];
        PASS([drawer state] == NSDrawerOpenState && [drawer edge] == edges[i]
          && [window isVisible], "drawer opens visibly on the requested edge");
        if (edges[i] == NSMinXEdge || edges[i] == NSMaxXEdge)
          {
            PASS(f.size.width < 200 && [view frame].size.width == 160,
              "side drawer uses requested width, excluding its trim");
            PASS(f.size.height == c.size.height - 30
              && NSMinY(f) == NSMinY(p) + NSMinY(c) + 18,
              "side drawer respects content bounds and both offsets");
            PASS(edges[i] == NSMinXEdge ? NSMaxX(f) == NSMinX(p)
              : NSMinX(f) == NSMaxX(p), "side drawer touches its parent edge");
          }
        else
          {
            PASS(f.size.height < 160 && [view frame].size.height == 120,
              "horizontal drawer uses requested height, excluding its trim");
            PASS(f.size.width == c.size.width - 30,
              "horizontal drawer respects both offsets");
            PASS(edges[i] == NSMinYEdge ? NSMaxY(f) == NSMinY(p)
              : NSMinY(f) == NSMaxY(p), "horizontal drawer touches its parent edge");
          }
        PASS(NSContainsRect([[view superview] bounds], [view frame]),
          "content stays inside the trim after sliding");
        [drawer close];
        PASS(view->stable, "sliding never compresses the content along its depth");
        view->axis = 0;
        PASS([drawer state] == NSDrawerClosedState && ![window isVisible],
          "closing hides the drawer");
      }
    PASS([delegate->states count] == 16
      && [[delegate->states objectAtIndex: 0] integerValue] == NSDrawerOpeningState
      && [[delegate->states objectAtIndex: 1] integerValue] == NSDrawerOpenState
      && [[delegate->states objectAtIndex: 2] integerValue] == NSDrawerClosingState
      && [[delegate->states objectAtIndex: 3] integerValue] == NSDrawerClosedState,
      "notifications report the transition states in order");

    [drawer openOnEdge: NSMaxXEdge];
    [drawer setLeadingOffset: 25];
    PASS([window frame].size.height == [[parent contentView] frame].size.height - 43,
      "changing offsets immediately lays out an open drawer");
    [drawer setContentSize: NSMakeSize(190, 120)];
    PASS([view frame].size.width == 190,
      "an open drawer accepts a new content width");
    [parent setContentSize: NSMakeSize(420, 320)];
    PASS(NSMinX([window frame]) == NSMaxX([parent frame]),
      "drawer follows parent resizing");
    delegate->veto = YES;
    [drawer close];
    PASS([drawer state] == NSDrawerOpenState, "delegate can veto closing");
    delegate->veto = NO;
    [drawer setParentWindow: nil];
    PASS([drawer parentWindow] == parent, "parent changes wait until closing");
    [drawer close];
    PASS([drawer parentWindow] == nil && [[parent drawers] count] == 0,
      "a deferred nil parent detaches the drawer on closing");
    {
      NSWindow *other = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(400, 400, 300, 200)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered defer: NO]);
      [other setReleasedWhenClosed: NO];
      [other orderFront: nil];
      [drawer setParentWindow: parent];
      [drawer openOnEdge: NSMaxXEdge];
      [drawer setParentWindow: other];
      [drawer close];
      PASS([drawer parentWindow] == other && ![window isVisible]
        && [[other drawers] containsObject: drawer],
        "deferred reparenting leaves the closed drawer hidden");
      [drawer setParentWindow: nil];
      [other orderOut: nil];
    }
    [drawer setDelegate: nil];
    [parent orderOut: nil];
    [drawer setParentWindow: parent];
    [drawer openOnEdge: NSMaxXEdge];
    PASS(![window isVisible], "opening with a hidden parent stays hidden");
    [parent orderFront: nil];
    [[NSRunLoop currentRunLoop] runUntilDate:
      [NSDate dateWithTimeIntervalSinceNow: 0.25]];
    PASS([window isVisible], "drawer appears when the unchanged parent is shown");
    [parent orderOut: nil];
    [[NSRunLoop currentRunLoop] runUntilDate:
      [NSDate dateWithTimeIntervalSinceNow: 0.25]];
    PASS(![window isVisible], "drawer hides when the parent is ordered out");
    [drawer close];
    [drawer setParentWindow: nil];

    {
      NSData *data = [NSKeyedArchiver archivedDataWithRootObject: drawer];
      NSDrawer *decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];
      PASS([decoded state] == NSDrawerClosedState
        && [decoded edge] == [drawer preferredEdge]
        && NSEqualSizes([decoded contentSize], [drawer contentSize])
        && NSEqualSizes([[decoded contentView] frame].size, [decoded contentSize]),
        "decoded drawers restore their content geometry and preferred edge");
      [decoded setParentWindow: parent];
      PASS([[parent drawers] containsObject: decoded],
        "decoded drawers participate in the parent's drawer list");
      [decoded setParentWindow: nil];
    }
  }
  END_SET("NSDrawer geometry and lifecycle")
  return 0;
}

