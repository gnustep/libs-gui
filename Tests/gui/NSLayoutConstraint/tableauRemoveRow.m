/* Lifetime exercise for the tableau behind Auto Layout.  -[GSCSTableau
   removeRowForVariable:] used to read the row expression out of the row
   dictionary, remove the entry -- which released the expression, the
   dictionary being its only owner -- and then walk the freed object's term
   variables, while -pivotWithEntryVariable:exitVariable: went on to rewrite
   the very same expression and put it back into the tableau.  Every content
   view resize of a window that has a layout engine removes and re-adds the
   content size constraints, so every such resize went through that path.
   The set reaches it through public API only -- constrained NSViews in a
   window whose content size is changed over and over -- and keeps the usual
   backend skip guard. */
#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSLayoutAnchor.h>
#include <AppKit/NSLayoutConstraint.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>

static BOOL
sameRect(NSRect a, NSRect b)
{
  return fabs(a.origin.x - b.origin.x) < 0.01
    && fabs(a.origin.y - b.origin.y) < 0.01
    && fabs(a.size.width - b.size.width) < 0.01
    && fabs(a.size.height - b.size.height) < 0.01;
}

int
main(int argc, const char **argv)
{
  START_SET("NSLayoutConstraint resize lifetime")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w;
      NSView *content;
      NSView *sub;
      NSView *other;
      NSLayoutConstraint *spare;
      NSSize sizes[6];
      CGFloat cw, ch;
      int resizes = 0;
      int wrong = 0;
      int rounds = 0;
      int i;

      w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 300, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      content = [w contentView];

      sub = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 0, 0)]);
      [sub setTranslatesAutoresizingMaskIntoConstraints: NO];
      [content addSubview: sub];
      other = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 0, 0)]);
      [other setTranslatesAutoresizingMaskIntoConstraints: NO];
      [content addSubview: other];

      /* Activating the first constraint is what gives the window a layout
         engine; from then on every content view resize pivots the tableau. */
      [[[sub leftAnchor] constraintEqualToAnchor: [content leftAnchor]
                                        constant: 20.0] setActive: YES];
      [[[sub bottomAnchor] constraintEqualToAnchor: [content bottomAnchor]
                                          constant: 10.0] setActive: YES];
      [[[sub widthAnchor] constraintEqualToAnchor: [content widthAnchor]
                                         constant: -50.0] setActive: YES];
      [[[sub heightAnchor] constraintEqualToAnchor: [content heightAnchor]
                                          constant: -25.0] setActive: YES];

      /* Inequalities put slack variables in the tableau, so the removals
         below have something to pivot on. */
      [[[sub widthAnchor] constraintGreaterThanOrEqualToConstant: 40.0]
        setActive: YES];
      [[[sub heightAnchor] constraintGreaterThanOrEqualToConstant: 20.0]
        setActive: YES];

      [[[other leftAnchor] constraintEqualToAnchor: [sub leftAnchor]
                                          constant: 10.0] setActive: YES];
      [[[other bottomAnchor] constraintEqualToAnchor: [sub bottomAnchor]
                                            constant: 10.0] setActive: YES];
      [[[other widthAnchor] constraintEqualToAnchor: [sub widthAnchor]
                                           constant: -40.0] setActive: YES];
      [[[other heightAnchor] constraintEqualToAnchor: [sub heightAnchor]
                                            constant: -40.0] setActive: YES];

      /* Toggled on and off around every resize: deactivating a constraint
         takes its row out of the tableau through the same method. */
      spare = [[sub heightAnchor] constraintGreaterThanOrEqualToConstant: 30.0];

      [w layoutIfNeeded];
      cw = NSWidth([content bounds]);
      ch = NSHeight([content bounds]);

      /* Control: the constraints lay the subviews out correctly before any
         resize, so a failure below is about the resizes themselves. */
      PASS(sameRect([sub frame], NSMakeRect(20, 10, cw - 50, ch - 25))
        && sameRect([other frame], NSMakeRect(30, 20, cw - 90, ch - 65)),
        "the constrained subviews track the initial content size");

      sizes[0] = NSMakeSize(300, 200);
      sizes[1] = NSMakeSize(520, 380);
      sizes[2] = NSMakeSize(360, 240);
      sizes[3] = NSMakeSize(600, 420);
      sizes[4] = NSMakeSize(280, 190);
      sizes[5] = NSMakeSize(460, 330);

      for (i = 0; i < 48; i++)
        {
          CGFloat was = cw;

          [spare setActive: YES];
          [w setContentSize: sizes[i % 6]];
          [spare setActive: NO];
          [w layoutIfNeeded];

          cw = NSWidth([content bounds]);
          ch = NSHeight([content bounds]);
          if (fabs(cw - was) > 0.01)
            {
              resizes++;
            }
          if (!sameRect([sub frame], NSMakeRect(20, 10, cw - 50, ch - 25)))
            {
              wrong++;
            }
          if (!sameRect([other frame], NSMakeRect(30, 20, cw - 90, ch - 65)))
            {
              wrong++;
            }
          rounds++;
        }

      /* Control: the content view really did change size in nearly every
         round, so the rounds above drove the solver rather than skipping it. */
      PASS(resizes >= 40, "each round resizes the content view");

      /* The tableau is rewritten from a row expression the row dictionary
         has already released, so what a resize leaves behind is whatever the
         allocator has since put in that memory: a corrupted solution here,
         or no answer at all because the run has already died. */
      PASS(wrong == 0,
        "the constrained subviews keep their exact geometry across "
        "repeated resizes");

      /* Reached only if 48 pivot-heavy resizes ran without the walk over a
         freed expression bringing the process down. */
      PASS(rounds == 48, "every resize round completed");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSLayoutConstraint resize lifetime")

  return 0;
}
