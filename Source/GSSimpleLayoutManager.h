/*
   GSSimpleLayoutManager.h

   First GNUstep layout manager, extracted from NSText

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: September 2000
   Extracted from NSText, reorganised to specification

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
   59 Temple Place - Suite 330, Boston, MA 02111 - 1307, USA.
*/
#ifndef __GSSimpleLayoutManager_h_GNUSTEP_GUI_INCLUDE
#define __GSSimpleLayoutManager_h_GNUSTEP_GUI_INCLUDE

#include <Foundation/NSGeometry.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSTextView.h>
#include <AppKit/NSLayoutManager.h>

@interface GSSimpleLayoutManager: NSLayoutManager
{
  // contains private _GNULineLayoutInfo objects
  NSMutableArray	*_lineLayoutInformation;
  NSRect _rects[4];
}

@end

#endif /*__NSCharacterSet_h_GNUSTEP_BASE_INCLUDE*/
