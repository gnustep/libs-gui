/*
   Cocoa.h

   Cocoa compatible declarations. Not to be used in normal GNUstep code.

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author:  Fred Kiefer <fredkiefer@gmx.de>
   Date: 2004

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

#ifndef _GNUstep_H_COCOA
#define _GNUstep_H_COCOA

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#ifndef M_PI
#define M_PI 3.1415926535897932384626433
#endif

#if (!defined(__cplusplus) && !defined(__USE_ISOC99))
typedef BOOL bool;
#define false NO
#define true  YES
#endif 

#endif /* _GNUstep_H_COCOA */
