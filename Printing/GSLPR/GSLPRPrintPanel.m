/** <title>GSLPRPrintPanel</title>

   <abstract>Standard panel for querying user about printing.</abstract>

   Copyright (C) 2001,2004 Free Software Foundation, Inc.

   Written By: Adam Fedor <fedor@gnu.org>
   Date: Oct 2001
   Modified for Printing Backend Support
   Author: Chad Hardin <cehardin@mac.com>
   Date: June 2004
   
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

//#include "config.h"
#include <Foundation/NSDebug.h>
//#include <Foundation/NSArray.h>
//#include <Foundation/NSBundle.h>
//#include <Foundation/NSDictionary.h>
//#include <Foundation/NSValue.h>
//#include "AppKit/NSApplication.h"
//#include "AppKit/NSForm.h"
//#include "AppKit/NSNibLoading.h"
//#include "AppKit/NSPrinter.h"
//#include "AppKit/NSPrintPanel.h"
//#include "AppKit/NSPrintInfo.h"
//#include "AppKit/NSPrintOperation.h"
//#include "AppKit/NSPopUpButton.h"
//#include "AppKit/NSSavePanel.h"
//#include "AppKit/NSView.h"
//#include "GSGuiPrivate.h"
#include "GSLPRPrintPanel.h"
//#include "GNUstepGUI/GSPrinting.h"



@implementation GSLPRPrintPanel
//
// Class methods
//
+ (id) allocWithZone: (NSZone*)zone
{
  NSDebugMLLog(@"GSPrinting", @"");
  return NSAllocateObject(self, 0, zone);
}

@end
