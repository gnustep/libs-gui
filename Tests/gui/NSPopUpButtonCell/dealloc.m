/*
 * Tests on proper deallocation
 */

#include "Testing.h"

#include <AppKit/NSApplication.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/NSMenu.h>

@interface MenuValidator : NSObject
{

}
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;

@end

@implementation MenuValidator

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
  return YES;
}
@end

int main(int argc, char **argv)
{
	CREATE_AUTORELEASE_POOL(arp);
	NSPopUpButton *b;
	NSPopUpButtonCell *bc;
	NSMenuItem *item;
	MenuValidator *mv;
	NSMenu *menu;

	START_SET("NSPopupButtonCell GNUstep -[dealloc]")

	NS_DURING
	{
		[NSApplication sharedApplication];
	}
	NS_HANDLER
	{
		if ([[localException name] isEqualToString: NSInternalInconsistencyException ])
			SKIP("It looks like GNUstep backend is not yet installed")
	}
	NS_ENDHANDLER

	b = [[NSPopUpButton alloc] init];

	bc = [b cell];
	[bc setUsesItemFromMenu: NO]; // allocates own _menuItem
	item = [bc menuItem];
	[item retain];
	[b dealloc];                  // release own _menuItem

	PASS([item retainCount] == 1, "-[setUsesItemFromMenu:NO]");

	DESTROY(item);

	b = [[NSPopUpButton alloc] init];
	[b addItemWithTitle: @"foo"];
	[b addItemWithTitle: @"bar"];
	mv = [MenuValidator new];
	bc = [b cell];
	menu = [bc menu];
	[menu setDelegate: mv];

	[mv release]; // validator is deallocated early

	[b dealloc]; // must not fall in a segfault

	PASS(YES, "early validator deallocation");

	END_SET("NSPopupButtonCell GNUstep -[dealloc]")

	DESTROY(arp);

	return 0;
}

