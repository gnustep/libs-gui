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

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <stdio.h>
#include <stdarg.h>

#include <AppKit/NSGraphics.h>

#ifndef LIB_FOUNDATION_LIBRARY

#include <Foundation/NSString.h>
#include <gnustep/gui/LogFile.h>

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
#endif /* LIB_FOUNDATION_LIBRARY */

void NSNullLog(NSString *format, ...)
{
}

//
// Play the System Beep
//
void NSBeep(void)
{
#ifdef WIN32
	MessageBeep(MB_OK);
#endif
}
