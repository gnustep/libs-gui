/*
copyright 2004 Alexander Malmberg <alexander@malmberg.org>
*/

#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSParagraphStyle.h>

int main(int argc, char **argv)
{
	int ok;

	START_SET("NSParagraphStyle NSParagraphStyle_defaultWritingDirection")

	ok = [NSParagraphStyle defaultWritingDirectionForLanguage: @"en"]==NSWritingDirectionLeftToRight
	  && [NSParagraphStyle defaultWritingDirectionForLanguage: @"ar"]==NSWritingDirectionRightToLeft;

	PASS(ok,"[NSParagraphStyle defaultWritingDirectionForLanguage:] works");

	END_SET("NSParagraphStyle NSParagraphStyle_defaultWritingDirection")
	return 0;
}

