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
#include <AppKit/AppKitDefines.h>

@class NSString;
@class NSColor;
@class NSGraphicsContext;

/*
 * Colorspace Names 
 */
APPKIT_EXPORT NSString *NSCalibratedWhiteColorSpace; 
APPKIT_EXPORT NSString *NSCalibratedBlackColorSpace; 
APPKIT_EXPORT NSString *NSCalibratedRGBColorSpace;
APPKIT_EXPORT NSString *NSDeviceWhiteColorSpace;
APPKIT_EXPORT NSString *NSDeviceBlackColorSpace;
APPKIT_EXPORT NSString *NSDeviceRGBColorSpace;
APPKIT_EXPORT NSString *NSDeviceCMYKColorSpace;
APPKIT_EXPORT NSString *NSNamedColorSpace;
APPKIT_EXPORT NSString *NSCustomColorSpace;


/*
 * Color function APPKIT_EXPORTs
 */
APPKIT_EXPORT const NSWindowDepth _GSGrayBitValue;
APPKIT_EXPORT const NSWindowDepth _GSRGBBitValue;
APPKIT_EXPORT const NSWindowDepth _GSCMYKBitValue;
APPKIT_EXPORT const NSWindowDepth _GSCustomBitValue;
APPKIT_EXPORT const NSWindowDepth _GSNamedBitValue;
APPKIT_EXPORT const NSWindowDepth *_GSWindowDepths[7];
APPKIT_EXPORT const NSWindowDepth NSDefaultDepth;
APPKIT_EXPORT const NSWindowDepth NSTwoBitGrayDepth;
APPKIT_EXPORT const NSWindowDepth NSEightBitGrayDepth;
APPKIT_EXPORT const NSWindowDepth NSEightBitRGBDepth;
APPKIT_EXPORT const NSWindowDepth NSTwelveBitRGBDepth;
APPKIT_EXPORT const NSWindowDepth GSSixteenBitRGBDepth;
APPKIT_EXPORT const NSWindowDepth NSTwentyFourBitRGBDepth;

/*
 * Gray Values 
 */
APPKIT_EXPORT const float NSBlack;
APPKIT_EXPORT const float NSDarkGray;
APPKIT_EXPORT const float NSWhite;
APPKIT_EXPORT const float NSLightGray;
APPKIT_EXPORT const float NSGray;

/*
 * Device Dictionary Keys 
 */
APPKIT_EXPORT NSString *NSDeviceResolution;
APPKIT_EXPORT NSString *NSDeviceColorSpaceName;
APPKIT_EXPORT NSString *NSDeviceBitsPerSample;
APPKIT_EXPORT NSString *NSDeviceIsScreen;
APPKIT_EXPORT NSString *NSDeviceIsPrinter;
APPKIT_EXPORT NSString *NSDeviceSize;

/*
 * Get Information About Color Space and Window Depth
 */
APPKIT_DECLARE const NSWindowDepth *NSAvailableWindowDepths(void);
APPKIT_DECLARE NSWindowDepth NSBestDepth(NSString *colorSpace, 
			  int bitsPerSample, int bitsPerPixel, 
			  BOOL planar, BOOL *exactMatch);
APPKIT_DECLARE int NSBitsPerPixelFromDepth(NSWindowDepth depth);
APPKIT_DECLARE int NSBitsPerSampleFromDepth(NSWindowDepth depth);
APPKIT_DECLARE NSString *NSColorSpaceFromDepth(NSWindowDepth depth);
APPKIT_DECLARE int NSNumberOfColorComponents(NSString *colorSpaceName);
APPKIT_DECLARE BOOL NSPlanarFromDepth(NSWindowDepth depth);


/*
 * Functions for getting information about windows.
 */
APPKIT_DECLARE void NSCountWindows(int *count);
APPKIT_DECLARE void NSWindowList(int size, int list[]);

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

APPKIT_DECLARE NSRect NSDrawTiledRects(NSRect aRect,const NSRect clipRect,  
			const NSRectEdge * sides, 
			const float *grays, int count);

APPKIT_EXPORT void NSDrawButton(const NSRect aRect, const NSRect clipRect);
APPKIT_EXPORT void NSDrawGrayBezel(const NSRect aRect, const NSRect clipRect);
APPKIT_EXPORT void NSDrawGroove(const NSRect aRect, const NSRect clipRect);
APPKIT_EXPORT void NSDrawWhiteBezel(const NSRect aRect, const NSRect clipRect);
APPKIT_EXPORT void NSDrawFramePhoto(const NSRect aRect, const NSRect clipRect);

// This is from an old version of the specification 
static inline void
NSDrawBezel(const NSRect aRect, const NSRect clipRect)
{
  NSDrawGrayBezel(aRect, clipRect);
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
GSWSetViewIsFlipped(NSGraphicsContext *ctxt, BOOL flipped)
{
  (ctxt->methods->GSWSetViewIsFlipped_)
    (ctxt, @selector(GSWSetViewIsFlipped:), flipped);
}

static inline BOOL
GSWViewIsFlipped(NSGraphicsContext *ctxt)
{
  return (ctxt->methods->GSWViewIsFlipped)
    (ctxt, @selector(GSWViewIsFlipped));
}

static inline NSWindowDepth
GSWindowDepthForScreen(NSGraphicsContext *ctxt, int screen_num)
{
  return (ctxt->methods->GSWindowDepthForScreen_)
    (ctxt, @selector(GSWindowDepthForScreen:), screen_num);
}

static inline const NSWindowDepth*
GSAvailableDepthsForScreen(NSGraphicsContext *ctxt, int screen_num)
{
  return (ctxt->methods->GSAvailableDepthsForScreen_)
    (ctxt, @selector(GSAvailableDepthsForScreen:), screen_num);
}

#ifndef	NO_GNUSTEP
@class	NSArray;
@class	NSWindow;

APPKIT_DECLARE NSArray* GSAllWindows();
APPKIT_DECLARE NSWindow* GSWindowWithNumber(int num);
#endif

#ifndef	STRICT_OPENSTEP
// Window operations
APPKIT_DECLARE void NSConvertGlobalToWindowNumber(int globalNum, unsigned int *winNum);
APPKIT_DECLARE void NSConvertWindowNumberToGlobal(int winNum, unsigned int *globalNum);

// Rectangle drawing
APPKIT_DECLARE NSRect NSDrawColorTiledRects(NSRect boundsRect, NSRect clipRect, 
					    const NSRectEdge *sides, 
					    NSColor **colors, 
					    int count);
APPKIT_DECLARE void NSDrawDarkBezel(NSRect aRect, NSRect clipRect);
APPKIT_DECLARE void NSDrawLightBezel(NSRect aRect, NSRect clipRect);
APPKIT_DECLARE void NSRectFillListWithColors(const NSRect *rects, 
					     NSColor **colors, int count);

static inline void
NSRectFillUsingOperation(NSRect aRect, NSCompositingOperation op) 
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  (ctxt->methods->NSRectFillUsingOperation__)
    (ctxt, @selector(NSRectFillUsingOperation::), aRect, op);
}

APPKIT_DECLARE void NSRectFillListUsingOperation(const NSRect *rects, int count, 
						 NSCompositingOperation op);
APPKIT_DECLARE void NSRectFillListWithColorsUsingOperation(const NSRect *rects, 
							   NSColor **colors, 
							   int num, 
							   NSCompositingOperation op);

APPKIT_DECLARE void NSDrawWindowBackground(NSRect aRect);

// Context information
APPKIT_DECLARE void NSCountWindowsForContext(int context, int *count);
APPKIT_DECLARE void NSWindowListForContext(int context, int size, int list[][]);
APPKIT_DECLARE int NSGetWindowServerMemory(int context, int *virtualMemory, 
					   int *windowBackingMemory, 
					   NSString **windowDumpStream);

#endif

#endif /* __NSGraphics_h__ */
