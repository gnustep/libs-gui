/* 
   NSFontPanel.m

   System generic panel for selecting and previewing fonts

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
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSApplication.h>

@implementation NSFontPanel

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSFontPanel class])
    {
      NSDebugLog(@"Initialize NSFontPanel class\n");

      // Initial version
      [self setVersion:1];
    }
}

//
// Creating an NSFontPanel 
//
+ (NSFontPanel *)sharedFontPanel
{
  NSFontManager *fm = [NSFontManager sharedFontManager];

  return [fm fontPanel:YES];
}

//
// Instance methods
//
//
// Creating an NSFontPanel 
//
- (NSFont *)panelConvertFont:(NSFont *)fontObject
{
  return panel_font;
}

//
// Setting the Font 
//
- (void)setPanelFont:(NSFont *)fontObject
	  isMultiple:(BOOL)flag
{
  panel_font = fontObject;
}

//
// Configuring the NSFontPanel 
//
- (NSView *)accessoryView
{
  return nil;
}

- (BOOL)isEnabled
{
  return NO;
}

- (void)setAccessoryView:(NSView *)aView
{}

- (void)setEnabled:(BOOL)flag
{}

- (BOOL)worksWhenModal
{
  return NO;
}

//
// Displaying the NSFontPanel 
//
- (void)orderWindow:(NSWindowOrderingMode)place	 
	 relativeTo:(int)otherWindows
{}

- (void)display
{
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObject: panel_font];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  panel_font = [aDecoder decodeObject];

  return self;
}

@end
