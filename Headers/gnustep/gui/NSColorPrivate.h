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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSColorPrivate
#define _GNUstep_H_NSColorPrivate

#include <gnustep/gui/NSColor.h>

@interface NSColor (GNUstepPrivate)

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
- (void)setClear:(BOOL)flag;

@end

#endif // _GNUstep_H_NSColorPrivate
