/* 
   NSDataLinkPanel.h

   Standard panel for inspecting data links

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

#ifndef _GNUstep_H_NSDataLinkPanel
#define _GNUstep_H_NSDataLinkPanel

#include <AppKit/stdappkit.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSDataLink.h>
#include <Foundation/NSCoder.h>
#include <AppKit/NSApplication.h>


@interface NSDataLinkPanel : NSPanel <NSCoding>

{
  // Attributes
}

//
// Initializing
//
+ (NSDataLinkPanel *)sharedDataLinkPanel;

//
// Keeping the Panel Up to Date
//
+ (void)getLink:(NSDataLink **)link
	manager:(NSDataLinkManager **)linkManager
isMultiple:(BOOL *)flag;
+ (void)setLink:(NSDataLink *)link
	manager:(NSDataLinkManager *)linkManager
isMultiple:(BOOL)flag;
- (void)getLink:(NSDataLink **)link
	manager:(NSDataLinkManager **)linkManager
isMultiple:(BOOL *)flag;
- (void)setLink:(NSDataLink *)link
	manager:(NSDataLinkManager *)linkManager
isMultiple:(BOOL)flag;

//
// Customizing the Panel
//
- (NSView *)accessoryView;
- (void)setAccessoryView:(NSView *)aView;

//
// Responding to User Input
//
- (void)pickedBreakAllLinks:(id)sender;
- (void)pickedBreakLink:(id)sender;
- (void)pickedOpenSource:(id)sender;
- (void)pickedUpdateDestination:(id)sender;
- (void)pickedUpdateMode:(id)sender;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSDataLinkPanel
