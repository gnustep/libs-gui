/* NSBitmapImageRep+GIF.h

   Functionality for reading GIF images

   Copyright (C) 2003 Free Software Foundation, Inc.
   
   Written by:  Stefan Kleine Stegemann <stefan@wms-network.de>
   Date: Nov 2003
   
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

#ifndef _NSBitmapImageRep_GIF_H_include
#define _NSBitmapImageRep_GIF_H_include

#include "AppKit/NSBitmapImageRep.h"

@interface NSBitmapImageRep (GIFReading)

+ (BOOL) _bitmapIsGIF: (NSData *)imageData;
- (id) _initBitmapFromGIF: (NSData *)imageData
             errorMessage: (NSString **)errorMsg;

@end

#endif // _NSBitmapImageRep_GIF_H_include

