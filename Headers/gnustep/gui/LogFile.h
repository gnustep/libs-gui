/* 
   LogFile.h

   Logfile for recording trace messages

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep Application Library.

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

#ifndef _GNUstep_H_LogFile
#define _GNUstep_H_LogFile

#include <Foundation/NSObject.h>
#include <stdio.h>

@interface LogFile : NSObject

{
	// Attributes
	struct _MB_lflags
	{
	  unsigned int is_locking:1;
	  unsigned int is_date_logging:1;
	} l_flags;
	FILE *the_log;
}

//
// Call one of these to initialize the log file and open a stream
//   to the standard output or a file.  
//
// -init does not open a file
- init;
- initStdout;
- initStdoutWithLocking;
- initFile:(const char *)filename;
- initFileWithLocking:(const char *)filename;

// Instance methods
- writeLog:(const char *)logEntry;
- closeLog;
- (BOOL)isDateLogging;
- setDateLogging:(BOOL)flag;
- (BOOL)isLocking;

@end

#ifdef DEBUGLOG
#define NSDebugLog(format, args...) NSLog(format, ## args)
#else
#define NSDebugLog(format, args...)
#endif

#endif // _GNUstep_H_LogFile
