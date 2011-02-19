/*
copyright 2005 Alexander Malmberg <alexander@malmberg.org>

Test that the file lists in NSSavePanel are reloaded properly when the
delegate changes.
*/

#include "Testing.h"

/*#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSBundle.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSSavePanel.h>
#include <AppKit/NSWindow.h>*/
#include <AppKit/AppKit.h>

/* Ugly but automatable. :)  */
typedef struct
{
	@defs(NSSavePanel);
} NSSavePanel_ivars;

@interface Delegate : NSObject
@end

@implementation Delegate

static BOOL pressed;
static NSSavePanel *sp;

+(BOOL) panel: (NSSavePanel *)p
	shouldShowFilename: (NSString *)fname
{
//	printf("should show '%s'?\n",[fname cString]);
	if ([[fname lastPathComponent] isEqual: @"B"])
	{
		return NO;
	}
	return YES;
}

/*+(void) foo
{
	printf("did press button\n");
	pressed=YES;
	[sp validateVisibleColumns];
}*/

@end

int main(int argc, char **argv)
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSSavePanel *p;
	NSBrowser *b;
	NSMatrix *m;

	[NSApplication sharedApplication];

	sp=p=[NSSavePanel savePanel];
	[p setDirectory: [[[[[NSBundle mainBundle] bundlePath]
		stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]
		stringByAppendingPathComponent: @"dummy"]];
#if 0
	[p makeKeyAndOrderFront: nil];
	[p setDelegate: [Delegate self]];
	{
		NSButton *b=[[NSButton alloc] initWithFrame: NSMakeRect(0,0,50,50)];
		[b setTitle: @"Click me"];
		[b setTarget: [Delegate self]];
		[b setAction: @selector(foo)];
		[p setAccessoryView: b];
	}
//	[p validateVisibleColumns];
	[p runModal];
#else

	b=((NSSavePanel_ivars *)p)->_browser;
	m=[b matrixInColumn: [b lastColumn]];
	pass([m numberOfRows] == 3
	     && [[[m cellAtRow: 0 column: 0] stringValue] isEqual: @"A"]
	     && [[[m cellAtRow: 1 column: 0] stringValue] isEqual: @"B"]
	     && [[[m cellAtRow: 2 column: 0] stringValue] isEqual: @".svn"],
		"browser initially contains all files");

	[p setDelegate: [Delegate self]];

	b=((NSSavePanel_ivars *)p)->_browser;
	m=[b matrixInColumn: [b lastColumn]];
	pass([m numberOfRows] == 2
	     && [[[m cellAtRow: 0 column: 0] stringValue] isEqual: @"A"]
	     && [[[m cellAtRow: 1 column: 0] stringValue] isEqual: @".svn"],
		"browser is reloaded after -setDelegate:");


	/* Not really a -setDelegate: issue, but the other methods involved are
	   documented as doing the wrong thing.  */
	[p setDelegate: nil];
	b=((NSSavePanel_ivars *)p)->_browser;
	m=[b matrixInColumn: [b lastColumn]];
	pass([m numberOfRows] == 3
	     && [[[m cellAtRow: 0 column: 0] stringValue] isEqual: @"A"]
	     && [[[m cellAtRow: 1 column: 0] stringValue] isEqual: @"B"]
	     && [[[m cellAtRow: 2 column: 0] stringValue] isEqual: @".svn"],
		"browser contains all files after resetting delegate");

	[b scrollColumnsLeftBy: [b lastColumn]];
	[p setDelegate: [Delegate self]];
	b=((NSSavePanel_ivars *)p)->_browser;
	m=[b matrixInColumn: [b lastColumn]];
	pass([m numberOfRows] == 2
	     && [[[m cellAtRow: 0 column: 0] stringValue] isEqual: @"A"]
	     && [[[m cellAtRow: 1 column: 0] stringValue] isEqual: @".svn"],
		"browser is reloaded after -setDelegate: (2)");
#endif

//	[p validateVisibleColumns];

	[arp release];
	return 0;
}

