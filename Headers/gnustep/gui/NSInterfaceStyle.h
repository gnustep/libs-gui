/* 
   NSInterfaceStyle.h

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1999
   
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

#ifndef	STRICT_OPENSTEP

#ifndef _GNUstep_H_NSInterfaceStyle
#define _GNUstep_H_NSInterfaceStyle

#include <AppKit/AppKitDefines.h>

@class NSResponder;
@class NSString;

typedef	enum {
  NSNoInterfaceStyle = 0,
  NSNextStepInterfaceStyle = 1,
  NSMacintoshInterfaceStyle = 2,
  NSWindows95InterfaceStyle = 3,

/*
 * GNUstep specific. Blame: Michael Hanni.
 */ 

  GSWindowMakerInterfaceStyle = 4

} NSInterfaceStyle;

APPKIT_EXPORT NSString	*NSInterfaceStyleDefault;

APPKIT_EXPORT NSInterfaceStyle
NSInterfaceStyleForKey(NSString *key, NSResponder *responder);

#endif // _GNUstep_H_NSInterfaceStyle
#endif // STRICT_OPENSTEP

