/* 
   <title>GSToolbarView.h</title>

   <abstract>The private toolbar class which draws the actual toolbar.</abstract>
   
   Copyright (C) 2002 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>,
            Fabien Vallon <fabien.vallon@fr.alcove.com>
   Date: May 2002
   
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

#ifndef _GSToolbarView_h_INCLUDE
#define _GSToolbarView_h_INCLUDE

#include <Foundation/NSObject.h>
#include "AppKit/NSToolbarItem.h"
#include "AppKit/NSToolbar.h"
#include "AppKit/NSView.h"

@interface GSToolbarView : NSView
{
  NSToolbar *_toolbar;
}
- (id) initWithToolbar: (NSToolbar *)toolbar;
- (void) setToolbar: (NSToolbar *)toolbar;
- (NSToolbar *) toolbar;
@end

@interface NSToolbar (GNUstepPrivate)
- (id) _toolbarView;
@end

#endif
