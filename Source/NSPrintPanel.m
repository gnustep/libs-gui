/* 
   NSPrintPanel.m

   Description...

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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
#include <AppKit/NSPrintPanel.h>

@implementation NSPrintPanel

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPrintPanel class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Creating an NSPrintPanel 
//
+ (NSPrintPanel *)printPanel
{
  return nil;
}

//
// Instance methods
//

//
// Customizing the Panel 
//
- (void)setAccessoryView:(NSView *)aView
{}

- (NSView *)accessoryView
{
  return nil;
}

//
// Running the Panel 
//
- (int)runModal
{
  return 0;
}

- (void)pickedButton:(id)sender
{}

//
// Updating the Panel's Display 
//
- (void)pickedAllPages:(id)sender
{}

- (void)pickedLayoutList:(id)sender
{}

//
// Communicating with the NSPrintInfo Object 
//
- (void)updateFromPrintInfo
{}

- (void)finalWritePrintInfo
{}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  return self;
}

@end
