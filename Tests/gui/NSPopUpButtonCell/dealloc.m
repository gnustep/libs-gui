/*
 * Tests on proper deallocation... mainly on _menu and _menuItem
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
	NSMenuView *mr;

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

	// -[setUsesItemFromMenu:NO]
	b = [[NSPopUpButton alloc] init];

	bc = [b cell];
	[bc setUsesItemFromMenu: NO]; // allocates own _menuItem
	item = [bc menuItem];
	[item retain];
	[b dealloc];                  // releases own _menuItem

	PASS(item != nil && [item retainCount] == 1, "-[setUsesItemFromMenu:NO]");

	DESTROY(item);

	// -[setPullsDown:YES]
	CREATE_AUTORELEASE_POOL(arp2); // item addition involves a pool
	b = [[NSPopUpButton alloc] init];
	[b addItemWithTitle: @"foo"];
	bc = [b cell];
	[bc setPullsDown: YES];       // calls -[setMenuItem:]
	item = [bc menuItem];
	[item retain];
	[b dealloc];                  
	DESTROY(arp2);

	PASS(item != nil && [item retainCount] == 1, "-[setPullsDown:YES]");

	DESTROY(item);

	// when highlighted
	CREATE_AUTORELEASE_POOL(arp3); // item addition involves a pool
	b = [[NSPopUpButton alloc] init];
	[b addItemWithTitle: @"foo"];
	bc = [b cell];
	menu = [bc menu];
	mr = [menu menuRepresentation];
	[mr setHighlightedItemIndex: [bc indexOfItemWithTitle: @"foo"]];
	item = [bc menuItem];
	[item retain];
	[b dealloc];                  
	DESTROY(arp3);

	PASS(item != nil && [item retainCount] == 1, "when highlighted");

	DESTROY(item);

	// when selected
	CREATE_AUTORELEASE_POOL(arp4); // item addition involves a pool
	b = [[NSPopUpButton alloc] init];
	[b addItemWithTitle: @"foo"];
	bc = [b cell];
	menu = [bc menu];
	[bc selectItem: [bc itemWithTitle: @"foo"]];
	item = [bc menuItem];
	[item retain];
	[b dealloc];                  
	DESTROY(arp4);

	PASS(item != nil && [item retainCount] == 1, "when selected");

	DESTROY(item);

	// early validator deallocation
	b = [[NSPopUpButton alloc] init];
	[b addItemWithTitle: @"foo"];
	[b addItemWithTitle: @"bar"];
	mv = [MenuValidator new];
	bc = [b cell];
	menu = [bc menu];
	[menu setDelegate: mv];

	[mv release]; // the validator is deallocated early

	[b dealloc]; // must not fall in a segfault(called NSZombie)

	PASS(YES, "early validator deallocation");

	END_SET("NSPopupButtonCell GNUstep -[dealloc]")

	DESTROY(arp);

	return 0;
}

