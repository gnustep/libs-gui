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
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/
#ifndef __NSGraphics_h__
#define __NSGraphics_h__

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSGraphicsContext.h>



@class NSString;
@class NSColor;
@class NSGraphicsContext;

/*
 * Colorspace Names 
 */
extern NSString *NSCalibratedWhiteColorSpace; 
extern NSString *NSCalibratedBlackColorSpace; 
extern NSString *NSCalibratedRGBColorSpace;
extern NSString *NSDeviceWhiteColorSpace;
extern NSString *NSDeviceBlackColorSpace;
extern NSString *NSDeviceRGBColorSpace;
extern NSString *NSDeviceCMYKColorSpace;
extern NSString *NSNamedColorSpace;
extern NSString *NSCustomColorSpace;


/*
 * Color function externs
 */
extern const NSWindowDepth _GSGrayBitValue;
extern const NSWindowDepth _GSRGBBitValue;
extern const NSWindowDepth _GSCMYKBitValue;
extern const NSWindowDepth _GSCustomBitValue;
extern const NSWindowDepth _GSNamedBitValue;
extern const NSWindowDepth *_GSWindowDepths[7];
extern const NSWindowDepth NSDefaultDepth;
extern const NSWindowDepth NSTwoBitGrayDepth;
extern const NSWindowDepth NSEightBitGrayDepth;
extern const NSWindowDepth NSEightBitRGBDepth;
extern const NSWindowDepth NSTwelveBitRGBDepth;
extern const NSWindowDepth GSSixteenBitRGBDepth;
extern const NSWindowDepth NSTwentyFourBitRGBDepth;

/*
 * Gray Values 
 */
extern const float NSBlack;
extern const float NSDarkGray;
extern const float NSWhite;
extern const float NSLightGray;
extern const float NSGray;

/*
 * Device Dictionary Keys 
 */
extern NSString *NSDeviceResolution;
extern NSString *NSDeviceColorSpaceName;
extern NSString *NSDeviceBitsPerSample;
extern NSString *NSDeviceIsScreen;
extern NSString *NSDeviceIsPrinter;
extern NSString *NSDeviceSize;

/*
 * Get Information About Color Space and Window Depth
 */
const NSWindowDepth *NSAvailableWindowDepths(void);
NSWindowDepth NSBestDepth(NSString *colorSpace, 
			  int bitsPerSample, int bitsPerPixel, 
			  BOOL planar, BOOL *exactMatch);
int NSBitsPerPixelFromDepth(NSWindowDepth depth);
int NSBitsPerSampleFromDepth(NSWindowDepth depth);
NSString *NSColorSpaceFromDepth(NSWindowDepth depth);
int NSNumberOfColorComponents(NSString *colorSpaceName);
BOOL NSPlanarFromDepth(NSWindowDepth depth);


/*
 * Functions for getting information about windows.
 */
void NSCountWindows(int *count);
void NSWindowList(int size, int list[]);

static inline void
NSEraseRect(NSRect aRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSEraseRect_)
    (ctxt, @selector(NSEraseRect:), aRect);
}

static inline void 
NSHighlightRect(NSRect aRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSHighlightRect_)
    (ctxt, @selector(NSHighlightRect:), aRect);
}

static inline void
NSRectClip(NSRect aRect)      
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSRectClip_)
    (ctxt, @selector(NSRectClip:), aRect);
}

static inline void
NSRectClipList(const NSRect *rects, int count)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSRectClipList__)
    (ctxt, @selector(NSRectClipList::), rects, count);
}

static inline void
NSRectFill(NSRect aRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSRectFill_)
    (ctxt, @selector(NSRectFill:), aRect);
}

static inline void
NSRectFillList(const NSRect *rects, int count)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSRectFillList__)
    (ctxt, @selector(NSRectFillList::), rects, count);
}

static inline void
NSRectFillListWithGrays(const NSRect *rects,const float *grays,int count) 
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSRectFillListWithGrays___)
    (ctxt, @selector(NSRectFillListWithGrays:::), rects, grays, count);
}

static inline void
NSDrawButton(const NSRect aRect, const NSRect clipRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSDrawButton__)
    (ctxt, @selector(NSDrawButton::), aRect, clipRect);
}

static inline void
NSDrawGrayBezel(const NSRect aRect, const NSRect clipRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSDrawGrayBezel__)
    (ctxt, @selector(NSDrawGrayBezel::), aRect, clipRect);
}

static inline void
NSDrawGroove(const NSRect aRect, const NSRect clipRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSDrawGroove__)
    (ctxt, @selector(NSDrawGroove::), aRect, clipRect);
}

static inline void
NSDrawWhiteBezel(const NSRect aRect, const NSRect clipRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSDrawWhiteBezel__)
    (ctxt, @selector(NSDrawWhiteBezel::), aRect, clipRect);
}

static inline void
NSDrawBezel(NSRect aRect, NSRect clipRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSDrawGrayBezel__)
    (ctxt, @selector(NSDrawGrayBezel::), aRect, clipRect);
}

static inline NSRect
NSDrawTiledRects(NSRect boundsRect, NSRect clipRect,
  const NSRectEdge *sides, const float *grays, int count)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  return (ctxt->methods->NSDrawTiledRects_____)
    (ctxt, @selector(NSDrawTiledRects:::::), boundsRect, clipRect,
     sides, grays, count);
}

static inline void
NSDottedFrameRect(NSRect aRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSDottedFrameRect_)
    (ctxt, @selector(NSDottedFrameRect:), aRect);
}

static inline void
NSFrameRect(const NSRect aRect)  
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSFrameRect_)
    (ctxt, @selector(NSFrameRect:), aRect);
}

static inline void
NSFrameRectWithWidth(const NSRect aRect, float frameWidth)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSFrameRectWithWidth__)
    (ctxt, @selector(NSFrameRectWithWidth::), aRect, frameWidth);
}


static inline NSColor*
NSReadPixel(NSPoint location)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  return (ctxt->methods->NSReadPixel_)
    (ctxt, @selector(NSReadPixel:), location);
}

static inline void
NSCopyBitmapFromGState(int srcGstate, NSRect srcRect, NSRect destRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSCopyBitmapFromGState___)
    (ctxt, @selector(NSCopyBitmapFromGState:::), srcGstate, srcRect, destRect);
}

static inline void
NSCopyBits(int srcGstate, NSRect srcRect, NSPoint destPoint)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSCopyBits___)
    (ctxt, @selector(NSCopyBits:::), srcGstate, srcRect, destPoint);
}

static inline void 
NSDrawBitmap(NSRect rect,
	     int pixelsWide,
	     int pixelsHigh,
	     int bitsPerSample,
	     int samplesPerPixel,
	     int bitsPerPixel,
	     int bytesPerRow,
	     BOOL isPlanar,
	     BOOL hasAlpha,
	     NSString *colorSpaceName,
	     const unsigned char *const data[5])
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSDrawBitmap___________)
    (ctxt, @selector(NSDrawBitmap:::::::::::),  rect,
     pixelsWide,
     pixelsHigh,
     bitsPerSample,
     samplesPerPixel,
     bitsPerPixel,
     bytesPerRow,
     isPlanar,
     hasAlpha,
     colorSpaceName,
     data);
    }

static inline void
NSBeep(void)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSBeep)
    (ctxt, @selector(NSBeep));
}

static inline unsigned int 
GSWDefineAsUserObj(NSGraphicsContext *ctxt)
{
  return (ctxt->methods->GSWDefineAsUserObj)
    (ctxt, @selector(GSWDefineAsUserObj));
}

static inline void
GSWViewIsFlipped(NSGraphicsContext *ctxt, BOOL flipped)
{
  (ctxt->methods->GSWViewIsFlipped_)
    (ctxt, @selector(GSWViewIsFlipped::), flipped);
}

static inline NSWindowDepth
GSWindowDepthForScreen(NSGraphicsContext *ctxt, int screen_num)
{
  return (ctxt->methods->GSWindowDepthForScreen_)
    (ctxt, @selector(GSWindowDepthForScreen::), screen_num);
}

static inline const NSWindowDepth*
GSAvailableDepthsForScreen(NSGraphicsContext *ctxt, int screen_num)
{
  return (ctxt->methods->GSAvailableDepthsForScreen_)
    (ctxt, @selector(GSAvailableDepthsForScreen::), screen_num);
}

#ifndef	NO_GNUSTEP
@class	NSArray;
@class	NSWindow;

NSArray* GSAllWindows();
NSWindow* GSWindowWithNumber(int num);
#endif

#endif /* __NSGraphics_h__ */
