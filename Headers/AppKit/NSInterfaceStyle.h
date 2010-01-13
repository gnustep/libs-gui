/* 
   NSInterfaceStyle.h

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1999
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#ifndef _GNUstep_H_NSInterfaceStyle
#define _GNUstep_H_NSInterfaceStyle
#import <GNUstepBase/GSVersionMacros.h>

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)

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
  GSWindowMakerInterfaceStyle = 4,

  /*
   * GNUstep specific style for native menus.
   */
  GSNativeInterfaceStyle = 5

} NSInterfaceStyle;

APPKIT_EXPORT NSString	*NSInterfaceStyleDefault;

APPKIT_EXPORT NSInterfaceStyle
NSInterfaceStyleForKey(NSString *key, NSResponder *responder);

#endif // GS_API_MACOSX

#endif // _GNUstep_H_NSInterfaceStyle


