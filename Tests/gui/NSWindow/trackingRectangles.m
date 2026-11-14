/* Lifetime exercise for -[NSWindow _checkTrackingRectangles:forEvent:]: the
   walk snapshots a view's tracking rectangles and then its subviews into C
   arrays that hold no references, and calls the rect owners' mouseEntered: /
   mouseExited: from inside those loops.  A handler that takes a hover box
   down -- the superview being the box's only owner -- used to free an entry
   the walk had not reached yet, and the walk then messaged freed memory; the
   same shape applies to an owner that removes a tracking rect of its own.
   The walk is driven with synthesised mouse-moved events, but -[NSWindow
   sendEvent:] discards events for a window that is not visible, so the window
   really has to be ordered in and the set keeps the backend skip guard. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>

@interface TrackState : NSObject
{
@public
  NSView *content;           /* the view the hover boxes are put into */
  id box;                    /* the box currently up; deliberately unretained */
  int enters;                /* mouseEntered: calls the walk delivered */
  int deallocs;              /* hover boxes deallocated so far */
  int freedInsideHandler;    /* boxes gone before the handler returned */
  int watcherEnters;
  int watcherExits;
  int ghostEvents;           /* events arriving through the removed rect */
}
@end

@implementation TrackState
@end

/* The hover box.  Nothing owns it but its superview, the way a view a form
   puts up and takes down again is owned. */
@interface HoverBox : NSView
{
@public
  TrackState *state;
}
@end

@implementation HoverBox
- (void) dealloc
{
  state->deallocs++;
  [super dealloc];
}
@end

@interface HoverBadge : NSView
{
@public
  TrackState *state;
}
@end

@implementation HoverBadge
- (void) mouseEntered: (NSEvent *)e
{
  NSAutoreleasePool *pool;
  HoverBox *fresh;
  int before;

  state->enters++;

  /* Take the box that is up down and put a fresh one in its place: the
     pattern of a badge that shows a hint on entering and swaps it when the
     pointer goes straight on to the next badge.  This runs from inside the
     subview loop of the walk, which still holds the box in its snapshot.
     The inner pool is drained here so that a box merely autoreleased by the
     removal would be counted too. */
  before = state->deallocs;
  pool = [[NSAutoreleasePool alloc] init];
  [state->box removeFromSuperview];
  [pool release];
  if (state->deallocs != before)
    {
      state->freedInsideHandler++;
    }

  fresh = [[HoverBox alloc] initWithFrame: NSMakeRect(20, 100, 200, 40)];
  fresh->state = state;
  [state->content addSubview: fresh];  /* the superview: its only owner */
  RELEASE(fresh);
  state->box = fresh;
}
@end

/* Owner of a tracking rectangle.  The removing one takes its sibling
   rectangle -- the one after it in the same snapshot -- down from inside its
   own mouseEntered:; the other one must never hear anything again. */
@interface RectWatcher : NSObject
{
@public
  TrackState *state;
  NSView *panel;
  NSTrackingRectTag doomed;
  BOOL removes;
}
@end

@implementation RectWatcher
- (void) mouseEntered: (NSEvent *)e
{
  if (removes)
    {
      state->watcherEnters++;
      [panel removeTrackingRect: doomed];
    }
  else
    {
      state->ghostEvents++;
    }
}
- (void) mouseExited: (NSEvent *)e
{
  if (removes)
    {
      state->watcherExits++;
    }
  else
    {
      state->ghostEvents++;
    }
}
@end

static void
moveMouseTo(NSWindow *w, NSPoint p)
{
  NSEvent *e = [NSEvent mouseEventWithType: NSMouseMoved
                                  location: p
                             modifierFlags: 0
                                 timestamp: 0
                              windowNumber: [w windowNumber]
                                   context: nil
                               eventNumber: 0
                                clickCount: 0
                                  pressure: 0];

  [w sendEvent: e];
}

int
main(int argc, const char **argv)
{
  START_SET("NSWindow tracking rectangles")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      TrackState *state = AUTORELEASE([[TrackState alloc] init]);
      NSWindow *w;
      NSView *content;
      HoverBadge *first;
      HoverBadge *second;
      HoverBox *box;
      NSWindow *pw;
      NSView *panel;
      RectWatcher *watcher;
      RectWatcher *ghost;
      int i;

      w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 400, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      content = [w contentView];
      state->content = content;

      first = AUTORELEASE([[HoverBadge alloc]
        initWithFrame: NSMakeRect(20, 20, 40, 40)]);
      first->state = state;
      second = AUTORELEASE([[HoverBadge alloc]
        initWithFrame: NSMakeRect(200, 20, 40, 40)]);
      second->state = state;
      [content addSubview: first];
      [content addSubview: second];

      /* After the badges in the subview list, so the walk reaches it only
         once a badge's handler has already taken it down. */
      box = [[HoverBox alloc] initWithFrame: NSMakeRect(20, 100, 200, 40)];
      box->state = state;
      [content addSubview: box];
      RELEASE(box);
      state->box = box;

      [first addTrackingRect: [first bounds]
                       owner: first
                    userData: NULL
                assumeInside: NO];
      [second addTrackingRect: [second bounds]
                        owner: second
                     userData: NULL
                 assumeInside: NO];

      [w orderFront: nil];

      /* Out, into the second badge, then straight into the first: the walk
         that delivers each of those moves takes the box down through a
         handler and then carries on through the rest of the snapshot it took
         before the handler ran. */
      for (i = 0; i < 5; i++)
        {
          moveMouseTo(w, NSMakePoint(350, 150));
          moveMouseTo(w, NSMakePoint(220, 40));
          moveMouseTo(w, NSMakePoint(40, 40));
        }

      /* Control: the walk really delivered the enter events, so a failure
         below is about object lifetime and not about events that never
         arrived. */
      PASS(state->enters == 10,
        "the tracking walk delivers an enter event to each badge entered");

      PASS(state->freedInsideHandler == 0,
        "a subview removed by a mouseEntered: handler outlives the walk "
        "that is holding it");

      /* Control: the walk's hold is given up again, so the boxes it kept
         alive are not leaked. */
      PASS(state->deallocs == state->enters,
        "every hover box taken down is released once its walk is over");

      /* The tracking rectangle snapshot: an owner that removes a sibling
         rectangle from its own handler.  Without the fix the array entry for
         that rectangle is freed memory by the time the loop reaches it and
         sends it -isValid. */
      pw = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 400, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      panel = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(20, 20, 360, 160)]);
      [[pw contentView] addSubview: panel];

      watcher = AUTORELEASE([[RectWatcher alloc] init]);
      watcher->state = state;
      watcher->panel = panel;
      watcher->removes = YES;
      ghost = AUTORELEASE([[RectWatcher alloc] init]);
      ghost->state = state;
      ghost->removes = NO;

      [panel addTrackingRect: NSMakeRect(0, 0, 180, 160)
                       owner: watcher
                    userData: NULL
                assumeInside: NO];
      watcher->doomed = [panel addTrackingRect: NSMakeRect(180, 0, 180, 160)
                                         owner: ghost
                                      userData: NULL
                                  assumeInside: NO];

      [pw orderFront: nil];

      moveMouseTo(pw, NSMakePoint(100, 100));  /* into the watcher's rect */
      moveMouseTo(pw, NSMakePoint(300, 100));  /* over the removed rect */
      moveMouseTo(pw, NSMakePoint(390, 195));  /* out of the panel */

      /* Control: the rectangle loop ran and the surviving rectangle still
         tracks after its sibling was taken out from under it. */
      PASS(state->watcherEnters == 1 && state->watcherExits == 1,
        "the rectangle that removed its sibling keeps tracking");

      PASS(state->ghostEvents == 0,
        "a tracking rectangle removed during the walk delivers nothing more");

      [w orderOut: nil];
      [pw orderOut: nil];
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSWindow tracking rectangles")

  return 0;
}
