/*
   NSGraphics.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: February 1997
   
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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/
#ifndef __NSGraphics_h__
#define __NSGraphics_h__

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>

@class NSString;
@class NSColor;

//
// Colorspace Names 
//
extern NSString *NSCalibratedWhiteColorSpace; 
extern NSString *NSCalibratedBlackColorSpace; 
extern NSString *NSCalibratedRGBColorSpace;
extern NSString *NSDeviceWhiteColorSpace;
extern NSString *NSDeviceBlackColorSpace;
extern NSString *NSDeviceRGBColorSpace;
extern NSString *NSDeviceCMYKColorSpace;
extern NSString *NSNamedColorSpace;
extern NSString *NSCustomColorSpace;

typedef int NSWindowDepth;

//
// Gray Values 
//
extern const float NSBlack;
extern const float NSDarkGray;
extern const float NSWhite;
extern const float NSLightGray;

//
// Device Dictionary Keys 
//
extern NSString *NSDeviceResolution;
extern NSString *NSDeviceColorSpaceName;
extern NSString *NSDeviceBitsPerSample;
extern NSString *NSDeviceIsScreen;
extern NSString *NSDeviceIsPrinter;
extern NSString *NSDeviceSize;

//
// Rectangle Drawing Functions
//
void NSEraseRect(NSRect aRect);
void NSHighlightRect(NSRect aRect);
void NSRectClip(NSRect aRect);
void NSRectClipList(const NSRect *rects, int count);
void NSRectFill(NSRect aRect);
void NSRectFillList(const NSRect *rects, int count);
void NSRectFillListWithGrays(const NSRect *rects, 
			     const float *grays, int count);

//
// Draw a Bordered Rectangle
//
void NSDrawButton(NSRect aRect, NSRect clipRect);
void NSDrawGrayBezel(NSRect aRect, NSRect clipRect);
void NSDrawGroove(NSRect aRect, NSRect clipRect);
NSRect NSDrawTiledRects(NSRect boundsRect, NSRect clipRect, 
			const NSRectEdge *sides, const float *grays, 
			int count);
void NSDrawWhiteBezel(NSRect aRect, NSRect clipRect);
void NSFrameRect(NSRect aRect);
void NSFrameRectWithWidth(NSRect aRect, float frameWidth);

//
// Get Information About Color Space and Window Depth
//
const NSWindowDepth *NSAvailableWindowDepths(void);
NSWindowDepth NSBestDepth(NSString *colorSpace, 
			  int bitsPerSample, int bitsPerPixel, 
			  BOOL planar, BOOL *exactMatch);
int NSBitsPerPixelFromDepth(NSWindowDepth depth);
int NSBitsPerSampleFromDepth(NSWindowDepth depth);
NSString *NSColorSpaceFromDepth(NSWindowDepth depth);
int NSNumberOfColorComponents(NSString *colorSpaceName);
BOOL NSPlanarFromDepth(NSWindowDepth depth);

//
// Read the Color at a Screen Position
//
NSColor *NSReadPixel(NSPoint location);

//
// Copy an image
//
void NSCopyBitmapFromGState(int srcGstate, NSRect srcRect, NSRect destRect);
void NSCopyBits(int srcGstate, NSRect srcRect, NSPoint destPoint);

//
// Render Bitmap Images
//
void NSDrawBitmap(NSRect rect,
                  int pixelsWide,
                  int pixelsHigh,
                  int bitsPerSample,
                  int samplesPerPixel,
                  int bitsPerPixel,
                  int bytesPerRow, 
                  BOOL isPlanar,
                  BOOL hasAlpha, 
                  NSString *colorSpaceName, 
                  const unsigned char *const data[5]);

//
// Play the System Beep
//
void NSBeep(void);


#endif /* __NSGraphics_h__ */
