/** <title>GSFusedSilicaContext</title>

   <abstract>Extention to NSGraphicsContext for necessary methods</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Adam Fedor <fedor@gnu.org>
   Date: Oct 2002
   
   This file is part of the GNUStep

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
   */

#ifndef _GSFusedSilicaContext_h_INCLUDE
#define _GSFusedSilicaContext_h_INCLUDE

#include <AppKit/NSGraphicsContext.h>
#include <GNUstepGUI/GSFusedSilica.h>

@interface NSGraphicsContext (FusedSilica)

/* Colorspaces */
+ (CGColorSpaceRef) CGColorSpaceCreateDeviceGray;
+ (CGColorSpaceRef) CGColorSpaceCreateDeviceRGB;
+ (CGColorSpaceRef) CGColorSpaceCreateDeviceCMYK;
+ (CGColorSpaceRef) CGColorSpaceCreateCalibratedGray: (const float *)whitePoint
						    : (const float *)blackPoint
						    : (float)gamma;
+ (CGColorSpaceRef) CGColorSpaceCreateCalibratedRGB: (const float *)whitePoint
						   : (const float *)blackPoint
						   : (const float *)gamma
						   : (const float *)matrix;
+ (CGColorSpaceRef) CGColorSpaceCreateLab: (const float *)whitePoint
					 : (const float *)blackPoint
					 : (const float *)range;
+ (CGColorSpaceRef) CGColorSpaceCreateICCBased: (size_t)nComponents
					      : (const float *)range
					      : (CGDataProviderRef)profile
					      : (CGColorSpaceRef)alternateSpace;
+ (CGColorSpaceRef) CGColorSpaceCreateIndexed: (CGColorSpaceRef)baseSpace
					     : (size_t) lastIndex
					     : (const unsigned short int *)colorTable;
+ (size_t) CGColorSpaceGetNumberOfComponents: (CGColorSpaceRef)cs;
+ (CGColorSpaceRef) CGColorSpaceRetain: (CGColorSpaceRef)cs;
+ (void) CGColorSpaceRelease: (CGColorSpaceRef)cs;

/* Fonts */

+ (CGFontRef) CGFontReferenceFromFont: (NSFont *)font;
+ (CGFontRef) CGFontRetain: (CGFontRef) font;
+ (void) CGFontRelease: (CGFontRef) font;

@end

#endif
