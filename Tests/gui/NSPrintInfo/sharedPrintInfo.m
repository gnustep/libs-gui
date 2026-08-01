/*
copyright 2004 Alexander Malmberg <alexander@malmberg.org>
*/

#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSPrintInfo.h>

int main(int argc, char **argv)
{
	START_SET("NSPrintInfo sharedPrintInfo")

	/* Should run without causing any exceptions. */
	[NSPrintInfo sharedPrintInfo];

	END_SET("NSPrintInfo sharedPrintInfo")
	return 0;
}

