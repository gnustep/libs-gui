/* rtcScanner.h

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Stefan Bðhringer (stefan.boehringer@uni-bochum.de)
   Date: Dec 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef rtfScanner_h_INCLUDE
#define rtfScanner_h_INCLUDE

#include	<objc/objc.h>

#if !defined(YES)
	typedef	char	BOOL;
	enum { NO, YES };
#endif

typedef enum { NoError, LEXoutOfMemory, LEXsyntaxError } GSLexError;

typedef struct _RTFscannerCtxt {
	int	(*lgetchar)(void *);
	char	pushbackBuffer[4];	// gaurantee 4 chars of pushback
	int	pushbackCount;
	int	streamPosition;
	int	streamLineNumber;
	void	*customContext;
} RTFscannerCtxt;

typedef struct {
	BOOL	isEmpty;
	int	parameter;
	int	token;
	const char	*name;
} RTFcmd;

typedef enum {
	GSRTFfamilyNil, GSRTFfamilyRoman, GSRTFfamilySwiss,
	GSRTFfamilyModern, GSRTFfamilyScript, GSRTFfamilyDecor,
	GSRTFfamilyTech
} RTFfontFamily;


void	lexInitContext(RTFscannerCtxt *lctxt, void *customContext, int (*getcharFunction)());

#endif
