
/* 
   dummy.m

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: November 1998
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include	<Foundation/NSObject.h>
#include	<Foundation/NSGeometry.h>

/*
 *	Dummy definitions provided here to avoid errors when not linking with
 *	a back end.
 */

BOOL initialize_gnustep_backend(void)					{ return YES; }
void NSHighlightRect(NSRect aRect)						{}
void NSRectFill(NSRect aRect)							{}
void NSBeep(void)										{}
void NSFrameRect(NSRect aRect)  						{}
void NSDrawButton(NSRect aRect, NSRect clipRect)		{}
void NSDrawGrayBezel(NSRect aRect, NSRect clipRect)		{}
void NSDrawGroove(NSRect aRect, NSRect clipRect)		{}

void PSlineto(float x, float y)							{}
void PSmoveto(float x, float y)							{}
void PSrlineto(float x, float y)						{}
void PSsetgray(float num)								{}					
void PSstroke(void)										{}
void PSsetlinewidth(float width)						{}			
void PSgrestore(void)									{}
void PSgsave(void)										{}

void GSfill() {}
void GSsetgray() {}
void GSnewpath() {}
void GSgrestore() {}
void GSrectfill() {}
void GSsetlinewidth() {}
void GSclosepath() {}
void GSshow() {}
void GStranslate() {}
void GSmoveto() {}
void GSgsave() {}
void GSlineto() {}
void GSstroke() {}
void GSrlineto() {}
void GSrectclip() {}


@interface  GMModel : NSObject
@end

@implementation GMModel
@end

@interface  GMUnarchiver : NSObject
@end

@implementation GMUnarchiver
@end

@interface  NSWindowView : NSObject
@end

@implementation NSWindowView
@end

@interface  GPSDrawContext : NSObject
@end

@implementation GPSDrawContext
@end

