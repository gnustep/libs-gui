/* 
   GSDragManager.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: June 1999
  
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

#include <gnustep/gui/config.h>

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

/*
 *	Stuff to maintain a map table so we know what windows and views are
 *	registered for drag and drop.
 *	FIXME - may need locks for thread safety?
 */
static NSMapTable	*typesMap = 0;

static inline void
GSSetupDragTypes()
{
  if (typesMap == 0)
    {
      typesMap = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
                NSObjectMapValueCallBacks, 0);
    }
}

NSArray*
GSGetDragTypes(id obj)
{
  GSSetupDragTypes();
  return NSMapGet(typesMap, (void*)(gsaddr)obj);
}

void
GSRegisterDragTypes(id obj, NSArray *types)
{
  NSArray	*m = [types mutableCopy];
  NSArray	*t = [m copy];

  RELEASE(m);
  GSSetupDragTypes();
  NSMapInsert(typesMap, (void*)(gsaddr)obj, (void*)(gsaddr)t);
  RELEASE(t);
}

void
GSUnregisterDragTypes(id obj)
{
  GSSetupDragTypes();
  NSMapRemove(typesMap, (void*)(gsaddr)obj);
}


