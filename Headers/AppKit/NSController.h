/** <title>NSController</title>

   <abstract>abstract base class for controllers</abstract>

   Copyright <copy>(C) 2006 Free Software Foundation, Inc.</copy>

   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date: June 2006

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#ifndef _GNUstep_H_NSController
#define _GNUstep_H_NSController

#include <Foundation/NSObject.h>

#if OS_API_VERSION(100300,GS_API_LATEST)

@class NSMutableArray;

@interface NSController : NSObject <NSCoding>
{
  NSMutableArray *_editors;
}

// NSEditor protocol
- (BOOL) commitEditing;
- (void) discardEditing;

- (BOOL) isEditing;

// NSEditorRegistration protocol
- (void) objectDidBeginEditing: (id)editor;
- (void) objectDidEndEditing: (id)editor;

@end

#endif // OS_API_VERSION

#endif // _GNUstep_H_NSController
