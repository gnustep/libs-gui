#import "Testing.h"
#import <Foundation/NSArray.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSRulerView.h>
#import <AppKit/NSRulerMarker.h>

/* NSRulerView marker management: adding, removing and setting the markers.
   These operate on an in-memory list and do not need a window server. */

static NSRulerMarker *
markerAt(NSRulerView *r, CGFloat loc)
{
  NSImage *img = AUTORELEASE([[NSImage alloc]
    initWithSize: NSMakeSize(8, 8)]);
  return AUTORELEASE([[NSRulerMarker alloc]
    initWithRulerView: r
       markerLocation: loc
                image: img
          imageOrigin: NSMakePoint(0, 0)]);
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSRulerView *r = AUTORELEASE([[NSRulerView alloc]
    initWithScrollView: nil orientation: NSHorizontalRuler]);
  NSRulerMarker *m1;
  NSRulerMarker *m2;
  NSRulerMarker *m3;

  /* markers can only be added to a ruler that has a client view */
  [r setClientView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 600, 400)])];

  m1 = markerAt(r, 10.0);
  m2 = markerAt(r, 20.0);
  m3 = markerAt(r, 30.0);

  [r addMarker: m1];
  PASS([[r markers] count] == 1, "adding a marker grows the list");
  [r addMarker: m2];
  PASS([[r markers] count] == 2, "a second marker is added");
  PASS([[r markers] objectAtIndex: 0] == m1, "the markers keep their order");

  [r removeMarker: m1];
  PASS([[r markers] count] == 1, "removing a marker shrinks the list");
  PASS([[r markers] objectAtIndex: 0] == m2,
    "the remaining marker is the one not removed");

  [r setMarkers: [NSArray arrayWithObjects: m1, m2, m3, nil]];
  PASS([[r markers] count] == 3, "setting the markers replaces the list");

  [r setMarkers: nil];
  PASS([r markers] == nil || [[r markers] count] == 0,
    "setting nil markers clears the list");

  DESTROY(arp);
  return 0;
}
