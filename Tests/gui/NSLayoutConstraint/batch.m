#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSLayoutConstraint.h>
#import <AppKit/NSLayoutAnchor.h>

static NSArray *
constraintsForSubview(NSView *sub, NSView *content)
{
  return [NSArray arrayWithObjects:
    [[sub leftAnchor] constraintEqualToAnchor: [content leftAnchor]
                                     constant: 20.0],
    [[sub bottomAnchor] constraintEqualToAnchor: [content bottomAnchor]
                                       constant: 10.0],
    [[sub widthAnchor] constraintEqualToAnchor: [content widthAnchor]
                                      constant: -50.0],
    [[sub heightAnchor] constraintEqualToAnchor: [content heightAnchor]
                                       constant: -25.0],
    nil];
}

int
main(int argc, const char **argv)
{
  START_SET("NSLayoutConstraint batched add and remove")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w1 = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 300, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSView *content1 = [w1 contentView];
      NSView *sub1 = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 0, 0)]);
      NSArray *batched;
      NSRect batchedFrame;

      [sub1 setTranslatesAutoresizingMaskIntoConstraints: NO];
      [content1 addSubview: sub1];

      batched = constraintsForSubview(sub1, content1);
      [content1 addConstraints: batched];
      [w1 layoutIfNeeded];
      batchedFrame = [sub1 frame];

      PASS(fabs(batchedFrame.size.width - 250.0) < 0.01
        && fabs(batchedFrame.size.height - 175.0) < 0.01,
        "a batch of constraints sizes the subview");
      PASS(fabs(batchedFrame.origin.x - 20.0) < 0.01
        && fabs(batchedFrame.origin.y - 10.0) < 0.01,
        "a batch of constraints positions the subview");

      /* The same constraints added one at a time must reach the same
         solution. */
      {
        NSWindow *w2 = AUTORELEASE([[NSWindow alloc]
          initWithContentRect: NSMakeRect(0, 0, 300, 200)
                    styleMask: NSWindowStyleMaskBorderless
                      backing: NSBackingStoreBuffered
                        defer: NO]);
        NSView *content2 = [w2 contentView];
        NSView *sub2 = AUTORELEASE([[NSView alloc]
          initWithFrame: NSMakeRect(0, 0, 0, 0)]);
        NSEnumerator *en;
        NSLayoutConstraint *c;
        NSRect singleFrame;

        [sub2 setTranslatesAutoresizingMaskIntoConstraints: NO];
        [content2 addSubview: sub2];

        en = [constraintsForSubview(sub2, content2) objectEnumerator];
        while ((c = [en nextObject]) != nil)
          {
            [content2 addConstraint: c];
          }
        [w2 layoutIfNeeded];
        singleFrame = [sub2 frame];

        PASS(NSEqualRects(batchedFrame, singleFrame),
          "a batch reaches the same frame as the same constraints added singly");
      }

      /* Resizing after a batched add reflows through the same engine. */
      [w1 setContentSize: NSMakeSize(400, 300)];
      PASS(fabs(NSWidth([sub1 frame]) - 350.0) < 0.01
        && fabs(NSHeight([sub1 frame]) - 275.0) < 0.01,
        "a batched subview reflows on resize");

      /* A batched removal must leave the same state as removing the same
         constraints one at a time. */
      {
        NSWindow *w3 = AUTORELEASE([[NSWindow alloc]
          initWithContentRect: NSMakeRect(0, 0, 300, 200)
                    styleMask: NSWindowStyleMaskBorderless
                      backing: NSBackingStoreBuffered
                        defer: NO]);
        NSView *content3 = [w3 contentView];
        NSView *sub3 = AUTORELEASE([[NSView alloc]
          initWithFrame: NSMakeRect(0, 0, 0, 0)]);
        NSArray *singly;
        NSEnumerator *en;
        NSLayoutConstraint *c;

        [sub3 setTranslatesAutoresizingMaskIntoConstraints: NO];
        [content3 addSubview: sub3];
        singly = constraintsForSubview(sub3, content3);
        [content3 addConstraints: singly];
        [w3 setContentSize: NSMakeSize(400, 300)];
        [w3 layoutIfNeeded];

        [content1 removeConstraints: batched];

        en = [singly objectEnumerator];
        while ((c = [en nextObject]) != nil)
          {
            [content3 removeConstraint: c];
          }

        PASS(NSEqualRects([sub1 frame], [sub3 frame]),
          "a batched removal leaves the same frame as removing singly");

        [w1 setContentSize: NSMakeSize(500, 400)];
        [w1 layoutIfNeeded];
        [w3 setContentSize: NSMakeSize(500, 400)];
        [w3 layoutIfNeeded];
        PASS(NSEqualRects([sub1 frame], [sub3 frame]),
          "a batched removal reflows the same as removing singly");
      }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSLayoutConstraint batched add and remove")
  return 0;
}
