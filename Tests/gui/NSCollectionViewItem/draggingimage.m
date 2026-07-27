/* Coverage for -[NSCollectionViewItem draggingImageComponents]: an item with no
   view has none, and an item with a view has a single icon component whose frame
   is the view bounds and whose contents is an image of the view.  The snapshot
   uses the backend, so the set is skipped when it is unavailable.  The
   assertions match AppKit (verified on a macOS runner). */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSCollectionViewItem.h>
#include <AppKit/NSDraggingItem.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSCollectionViewItem *item;
  NSArray *components;
  NSDraggingImageComponent *component;

  START_SET("NSCollectionViewItem draggingImageComponents")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  item = AUTORELEASE([[NSCollectionViewItem alloc] init]);
  PASS([[item draggingImageComponents] count] == 0,
       "an item with no view has no dragging image components");

  NS_DURING
    {
      NSWindow *window = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 80, 60)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSView *view = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 80, 60)]);

      [window setContentView: view];
      [item setView: view];

      components = [item draggingImageComponents];
      PASS([components count] == 1,
           "an item with a view has one dragging image component");
      component = [components objectAtIndex: 0];
      PASS([[component key] isEqualToString: NSDraggingImageComponentIconKey],
           "the component uses the icon key");
      PASS(NSEqualRects([component frame], NSMakeRect(0, 0, 80, 60)),
           "the component frame matches the view bounds");
      PASS([[component contents] isKindOfClass: [NSImage class]],
           "the component contents is an image of the view");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("The backend cannot render the view offscreen")
    else
      [localException raise];
  NS_ENDHANDLER

  END_SET("NSCollectionViewItem draggingImageComponents")

  DESTROY(arp);
  return 0;
}
