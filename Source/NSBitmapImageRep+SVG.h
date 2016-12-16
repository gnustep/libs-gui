/*
   NSBitmapImageRep+SVG.m

   Methods for loading .icns images.

   Copyright (C) 2008 Free Software Foundation, Inc.
   
   Written by: Gregory Casamento
   Date: 2008-08-12
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#ifndef _NSBitmapImageRep_SVG_H_include
#define _NSBitmapImageRep_SVG_H_include

#import "AppKit/NSBitmapImageRep.h"

@interface NSBitmapImageRep (SVG)
+ (BOOL) _bitmapIsSVG: (NSData *)imageData;
+ (NSArray*) _imageRepsWithSVGData: (NSData *)imageData;
- (id) _initBitmapFromSVG: (NSData *)imageData;
// - (NSData *) _SVGRepresentationWithProperties: (NSDictionary *) properties;
@end

#endif
