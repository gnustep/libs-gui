/* 
   Functions.m

   Generic Functions for the GNUstep GUI Library.

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

#include <gnustep/gui/Functions.h>
#include <gnustep/gui/LogFile.h>
#include <stdio.h>
#include <stdarg.h>

// Should be in Foundation Kit
// Does not handle %@
// yuck, yuck, yuck
extern LogFile *logFile;
void NSLogV(NSString *format, va_list args)
{
	char out[1024];

	vsprintf(out, [format cString], args);
	[logFile writeLog:out];
}

void NSLog(NSString *format, ...)
{
	va_list ap;

	va_start(ap, format);
	NSLogV(format, ap);
	va_end(ap);
}

void NSNullLog(NSString *format, ...)
{
}
