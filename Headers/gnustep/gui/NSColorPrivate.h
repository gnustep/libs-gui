/* 
   NSColorPrivate.h

   Private methods for the color class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: September 1996
   
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

#ifndef _GNUstep_H_NSColorPrivate
#define _GNUstep_H_NSColorPrivate

#include <AppKit/NSColor.h>

@interface NSColor (GNUstepPrivate)

+ (NSColor*) colorFromString: (NSString*)string;
+ (void) defaultSystemColors;
+ (void) defaultsDidChange: (NSNotification*)notification;

- (void) supportMaxColorSpaces;

- (void)setColorSpaceName:(NSString *)str;
- (void)setCatalogName:(NSString *)str;
- (void)setColorName:(NSString *)str;

// RGB component values
- (void)setRed:(float)value;
- (void)setGreen:(float)value;
- (void)setBlue:(float)value;

// CMYK component values
- (void)setCyan:(float)value;
- (void)setMagenta:(float)value;
- (void)setYellow:(float)value;
- (void)setBlack:(float)value;

// HSB component values
- (void)setHue:(float)value;
- (void)setSaturation:(float)value;
- (void)setBrightness:(float)value;

// Grayscale
- (void)setWhite:(float)value;

- (void)setAlpha:(float)value;
- (void)setActiveComponent:(int)value;
- (void)setValidComponents:(int)value;
- (void)setClear:(BOOL)flag;

@end

#endif // _GNUstep_H_NSColorPrivate
