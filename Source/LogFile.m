/* 
   LogFile.m

   Logfile for recording trace messages

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/LogFile.h>

@implementation LogFile

// Class methods
+ (void)initialize
{
	// Initial version
	if (self == [LogFile class])
		[self setVersion:1.0];

}

// Instance methods
- init
{
	[super init];
	l_flags.is_locking = NO;
	l_flags.is_date_logging = YES;
	if (the_log) [self closeLog];
	return self;
}

- (void)dealloc
{
	[self closeLog];
	return [super dealloc];
}

- initStdout
{
	[self init];
	return self;
}

- initStdoutWithLocking
{
	[self init];
	l_flags.is_locking = YES;
	return self;
}

- initFile:(const char *)filename
{
	[self init];
	the_log = fopen(filename, "w");
	if (the_log) [self writeLog: "Start of Log\n"];
	if (!the_log)
		return nil;
	else
		return self;
}

- initFileWithLocking:(const char *)filename;
{
	[self init];
	l_flags.is_locking = YES;
	the_log = fopen(filename, "w");
	if (the_log) [self writeLog: "Start of Log\n"];
	if (!the_log)
		return nil;
	else
		return self;
}

// Instance methods
- writeLog:(const char *)logEntry
{
	if (the_log == NULL)
		printf("%s", logEntry);
	else
	{
		fprintf(the_log, "%s", logEntry);
		fflush(the_log);
	}
}

- closeLog
{
	[self writeLog:"Log closed.\n"];
	if (the_log) fclose(the_log);
	the_log = NULL;
}

- (BOOL)isDateLogging
{
	return (BOOL)l_flags.is_date_logging;
}

- setDateLogging:(BOOL)flag
{
	l_flags.is_date_logging = flag;
}

- (BOOL)isLocking
{
	return (BOOL)l_flags.is_locking;
}

@end
