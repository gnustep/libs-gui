/* 
   GSHelpManagerPanel.h

   GSHelpManagerPanel displays a help message for an item.

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Pedro Ivo Andrade Tavares <ptavares@iname.com>
   Date: September 1999
   
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
#ifndef _GNUstep_H_GSHelpManagerPanel
#define _GNUstep_H_GSHelpManagerPanel

#include <AppKit/NSPanel.h>

@class NSTextView;
@class NSAttributedString;

@interface GSHelpManagerPanel: NSPanel
{
   NSTextView *textView;
}

+sharedHelpManagerPanel;

-(void)setHelpText: (NSAttributedString*)helpText;

@end

#endif // _GNUstep_H_GSHelpManagerPanel
