/*
copyright 2004 Alexander Malmberg <alexander@malmberg.org>
*/

#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSPrintInfo.h>

int main(int argc, char **argv)
{
	START_SET("NSPrintInfo sharedPrintInfo")

	/* The set had no testcase at all, so it reported nothing whether this
	   worked or not. */
	PASS_RUNS([NSPrintInfo sharedPrintInfo];,
		"sharedPrintInfo runs without raising");

	END_SET("NSPrintInfo sharedPrintInfo")
	return 0;
}

