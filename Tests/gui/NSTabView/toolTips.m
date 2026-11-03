/* A tab view gives each item's tooltip the area that item's tab occupies.

   The tab rects are settled by the theme as it draws, so the tooltips are
   asked for after a draw.  What the tab view asks for is recorded by a
   subclass rather than inferred from the screen: NSView keeps no public list
   of the tooltip rects it holds.
*/
#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSValue.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewItem.h>

static NSMutableArray *tips = nil;
static NSMutableArray *rects = nil;
static int removals = 0;

@interface RecordingTabView : NSTabView
@end

@implementation RecordingTabView

- (NSToolTipTag) addToolTipRect: (NSRect)aRect
			  owner: (id)anObject
		       userData: (void *)data
{
  [tips addObject: anObject];
  [rects addObject: [NSValue valueWithRect: aRect]];
  return [super addToolTipRect: aRect owner: anObject userData: data];
}

- (void) removeAllToolTips
{
  removals++;
  [super removeAllToolTips];
}

@end

static NSTabViewItem *
mk(NSString *ident, NSString *label, NSString *tip)
{
  NSTabViewItem *it = AUTORELEASE([[NSTabViewItem alloc]
    initWithIdentifier: ident]);

  [it setLabel: label];
  [it setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 50, 50)])];
  if (tip != nil)
    {
      [it setToolTip: tip];
    }
  return it;
}

int
main(int argc, const char **argv)
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];

  START_SET("NSTabView toolTips")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  tips = [NSMutableArray new];
  rects = [NSMutableArray new];

  NS_DURING
    {
      NSWindow		*w;
      RecordingTabView	*tv;
      NSTabViewItem	*withTip;

      w = AUTORELEASE([[NSWindow alloc]
	initWithContentRect: NSMakeRect(0, 0, 200, 120)
		  styleMask: NSWindowStyleMaskBorderless
		    backing: NSBackingStoreBuffered
		      defer: NO]);
      tv = AUTORELEASE([[RecordingTabView alloc]
	initWithFrame: NSMakeRect(0, 0, 200, 120)]);
      withTip = mk(@"a", @"A", @"the first tab");
      [tv addTabViewItem: withTip];
      [tv addTabViewItem: mk(@"b", @"B", nil)];
      [w setContentView: tv];
      [tv display];

      PASS([tips count] == 1,
	   "one tooltip is registered, for the one item that has one");
      if ([tips count] == 1)
	{
	  PASS([[tips objectAtIndex: 0] isEqual: @"the first tab"],
	       "the tooltip registered is the item's own");
	  PASS(NSEqualRects([[rects objectAtIndex: 0] rectValue],
			    [withTip _tabRect]),
	       "the rect registered is the rect that item's tab occupies");
	}
      PASS(removals > 0, "the tooltips are renewed rather than accumulated");
    }
  NS_HANDLER
    PASS(0 == 1, "drawing the tab view raised");
  NS_ENDHANDLER

  DESTROY(tips);
  DESTROY(rects);

  END_SET("NSTabView toolTips")

  [arp release];
  return 0;
}
