/** <title>GSLPRPageLayout</title>

   <abstract></abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.
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
#include <Foundation/NSDebug.h>
//#include <AppKit/NSApplication.h>
//#include <AppKit/NSFont.h>
//#include <AppKit/NSTextField.h>
//#include <AppKit/NSImage.h>
//#include <AppKit/NSImageView.h>
//#include <AppKit/NSBox.h>
//#include <AppKit/NSButton.h>
//#include <AppKit/NSComboBox.h>
//#include <AppKit/NSPopUpButton.h>
//#include <AppKit/NSMatrix.h>
//#include <AppKit/NSNibLoading.h>
//#include <AppKit/NSForm.h>
//#include <AppKit/NSFormCell.h>
//#include <AppKit/NSPrintInfo.h>
//#include <AppKit/NSPageLayout.h>
//#include <AppKit/NSPrinter.h>
//#include "GSGuiPrivate.h"
#include "GSLPRPageLayout.h"
//#include "GNUstepGUI/GSPrinting.h"



@implementation GSLPRPageLayout
//
// Class methods
//
+ (void)initialize
{
  NSDebugMLLog(@"GSPrinting", @"");
  if (self == [GSLPRPageLayout class])
    {
      // Initial version
      [self setVersion:1];
    }
}


+ (id) allocWithZone: (NSZone*)zone
{
  NSDebugMLLog(@"GSPrinting", @"");
  return NSAllocateObject(self, 0, zone);
}


@end
