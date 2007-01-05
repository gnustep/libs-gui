/* 
   GSToolbarCustomizationPalette.m

   The palette which allows to customize toolbar
   
   Copyright (C) 2007 Free Software Foundation, Inc.

   Author:  Quentin Mathe <qmathe@club-internet.fr>
   Date: January 2007
   
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

#include "AppKit/NSNibLoading.h"
#include "AppKit/NSWindow.h"
#include "GNUstepGUI/GSToolbar.h"
#include "GNUstepGUI/GSToolbarCustomizationPalette.h"


@implementation GSToolbarCustomizationPalette

+ (GSToolbarCustomizationPalette *) paletteWithToolbar: (GSToolbar *)toolbar
{
  return AUTORELEASE([[GSToolbarCustomizationPalette alloc] 
    initWithToolbar: toolbar]);
}

- (GSToolbarCustomizationPalette *) initWithToolbar: (GSToolbar *)toolbar
{
  self = [super init];

  if (self != nil)
    {
      BOOL nibLoaded = [NSBundle loadNibNamed: @"GSToolbarCustomizationPalette" 
                                        owner: self];

      if (nibLoaded == NO)
        {
          NSLog(@"Failed to load gorm for GSToolbarCustomizationPalette");
          return nil;
        }
    }

  return self;
}

- (void) show: (id)sender
{
  [_customizationWindow makeKeyAndOrderFront: self];
}

@end
