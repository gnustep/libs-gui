/*
   Functions.m

   Generic Functions for the GNUstep GUI Library.

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

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

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSProcessInfo.h>

#include "AppKit/NSApplication.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSGraphicsContext.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSView.h"
#include "AppKit/NSWindow.h"
#include "AppKit/DPSOperators.h"

char **NSArgv = NULL;

/*
 * Main initialization routine for the GNUstep GUI Library Apps
 */
int
NSApplicationMain(int argc, const char **argv)
{
  NSDictionary		*infoDict;
  NSString		*className;
  Class			appClass;
  CREATE_AUTORELEASE_POOL(pool);
#if defined(LIB_FOUNDATION_LIBRARY) || defined(GS_PASS_ARGUMENTS)
  extern char		**environ;

  [NSProcessInfo initializeWithArguments: (char**)argv
				   count: argc
			     environment: environ];
#endif

  infoDict = [[NSBundle mainBundle] infoDictionary];
  className = [infoDict objectForKey: @"NSPrincipalClass"];
  appClass = NSClassFromString(className);

  if (appClass == 0)
    {
      NSLog(@"Bad application class '%@' specified", className);
      appClass = [NSApplication class];
    }

  [[appClass sharedApplication] run];

  DESTROY(NSApp);

  RELEASE(pool);

  return 0;
}

/*
 * Convert an NSEvent Type to it's respective Event Mask
 */
unsigned
NSEventMaskFromType(NSEventType type)
{
  switch (type)
    {
      case NSLeftMouseDown:	return NSLeftMouseDownMask;
      case NSLeftMouseUp:	return NSLeftMouseUpMask;
      case NSOtherMouseDown:	return NSOtherMouseDownMask;
      case NSOtherMouseUp:	return NSOtherMouseUpMask;
      case NSRightMouseDown:	return NSRightMouseDownMask;
      case NSRightMouseUp:	return NSRightMouseUpMask;
      case NSMouseMoved:	return NSMouseMovedMask;
      case NSMouseEntered:	return NSMouseEnteredMask;
      case NSMouseExited:	return NSMouseExitedMask;
      case NSLeftMouseDragged:	return NSLeftMouseDraggedMask;
      case NSOtherMouseDragged:	return NSOtherMouseDraggedMask;
      case NSRightMouseDragged:	return NSRightMouseDraggedMask;
      case NSKeyDown:		return NSKeyDownMask;
      case NSKeyUp:		return NSKeyUpMask;
      case NSFlagsChanged:	return NSFlagsChangedMask;
      case NSPeriodic:		return NSPeriodicMask;
      case NSCursorUpdate:	return NSCursorUpdateMask;
      case NSScrollWheel:	return NSScrollWheelMask;
      case NSAppKitDefined:	return NSAppKitDefinedMask;
      case NSSystemDefined:	return NSSystemDefinedMask;
      case NSApplicationDefined: return NSApplicationDefinedMask;
    }
  return 0;
}

/*
 * Color Functions
 */

/*
 * Get Information About Color Space and Window Depth
 */
const NSWindowDepth*
NSAvailableWindowDepths(void)
{
  /*
   * Perhaps this is the only function which
   * belongs in the backend.   It should be possible
   * to detect which depths the window server is capable
   * of.
   */	
  return (const NSWindowDepth *)_GSWindowDepths;
}

NSWindowDepth
NSBestDepth(NSString *colorSpace, int bitsPerSample, int bitsPerPixel,
  BOOL planar, BOOL *exactMatch)
{
  int			components = NSNumberOfColorComponents(colorSpace);
  int			index = 0;
  const NSWindowDepth	*depths = NSAvailableWindowDepths();
  NSWindowDepth		bestDepth = NSDefaultDepth;
  
  *exactMatch = NO;
  
  if (components == 1)
    {	
      for (index = 0; depths[index] != 0; index++)
	{
	  NSWindowDepth	depth = depths[index];

	  if (NSPlanarFromDepth(depth))
	    {
	      bestDepth = depth;
	      if (NSBitsPerSampleFromDepth(depth) == bitsPerSample)
		{
		  *exactMatch = YES;
		}
	    }
	}
    }
  else
    {
      for (index = 0; depths[index] != 0; index++)
	{
	  NSWindowDepth	depth = depths[index];

	  if (!NSPlanarFromDepth(depth))
	    {
	      bestDepth = depth;
	      if (NSBitsPerSampleFromDepth(depth) == bitsPerSample)
		{
		  *exactMatch = YES;
		}
	    }
	}
    }
  
  return bestDepth;
}

int
NSBitsPerPixelFromDepth(NSWindowDepth depth)
{
  int	bps = NSBitsPerSampleFromDepth(depth);
  int	spp = 0;
  
  if (depth & _GSRGBBitValue)
    {
      spp = 3;	
    }
  else if (depth & _GSCMYKBitValue)
    {
      spp = 4;
    }
  else if (depth & _GSGrayBitValue)
    {
      spp = 1;
    }
  return (spp * bps);
}

int
NSBitsPerSampleFromDepth(NSWindowDepth depth)
{
  NSWindowDepth	bitValue = 0;

  /*
   * Test against colorspace bit.
   * and out the bit to get the bps value.
   */
  if (depth & _GSRGBBitValue)
    {
      bitValue = _GSRGBBitValue;
    }
  else if (depth & _GSCMYKBitValue)
    {
      bitValue = _GSCMYKBitValue;
    }
  else if (depth & _GSGrayBitValue)
    {
      bitValue = _GSGrayBitValue;
    }
  /*
   * AND against the complement
   * to extract the bps value.	
   */
  return (depth & ~(bitValue));
}

NSString*
NSColorSpaceFromDepth(NSWindowDepth depth)
{
  NSString	*colorSpace = NSCalibratedWhiteColorSpace;
  
  /*
   * Test against each of the possible colorspace bits
   * and return the corresponding colorspace.
   */
  if (depth == 0)
    {
      colorSpace = NSCalibratedBlackColorSpace;
    }
  else if (depth & _GSRGBBitValue)
    {
      colorSpace = NSCalibratedRGBColorSpace;
    }
  else if (depth & _GSCMYKBitValue)
    {
      colorSpace = NSDeviceCMYKColorSpace;
    }
  else if (depth & _GSGrayBitValue)
    {
      colorSpace = NSCalibratedWhiteColorSpace;
    }
  else if (depth & _GSNamedBitValue)
    {
      colorSpace = NSNamedColorSpace;
    }
  else if (depth & _GSCustomBitValue)
    {
      colorSpace = NSCustomColorSpace;
    }

  return colorSpace;
}

int
NSNumberOfColorComponents(NSString *colorSpaceName)
{
  int	components = 1;
  
  /*
   * These are the only exceptions to the above.
   * All other colorspaces have as many bps as bpp.
   */
  if ([colorSpaceName isEqualToString: NSCalibratedRGBColorSpace]
    || [colorSpaceName isEqualToString: NSDeviceRGBColorSpace])
    {
      components = 3;
    }
  else if ([colorSpaceName isEqualToString: NSDeviceCMYKColorSpace])
    {
      components = 4;
    }
  return components;
}

BOOL
NSPlanarFromDepth(NSWindowDepth depth)
{
  BOOL planar = NO;
  
  /*
   * Only the grayscale depths are planar.
   * All others are interleaved.
   */
  if (depth & _GSGrayBitValue)
    {
      planar = YES;
    }
  return planar;
}

/* Graphic Ops */
NSColor* NSReadPixel(NSPoint location)
{
  NSLog(@"NSReadPixel not implemented");
  return nil;
}

void NSCopyBitmapFromGState(int srcGstate, NSRect srcRect, NSRect destRect)
{
  NSLog(@"NSCopyBitmapFromGState not implemented");
}

void NSCopyBits(int srcGstate, NSRect srcRect, NSPoint destPoint)
{
  float x, y, w, h;
  NSGraphicsContext *ctxt = GSCurrentContext();

  x = NSMinX(srcRect);
  y = NSMinY(srcRect);
  w = NSWidth(srcRect);
  h = NSHeight(srcRect);

  DPScomposite(ctxt, x, y, w, h, srcGstate, destPoint.x, destPoint.y,
	       NSCompositeCopy);
}

/*
 * Rectangle Drawing 
 */
void NSEraseRect(NSRect aRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  DPSgsave(ctxt);
  DPSsetgray(ctxt, NSWhite);
  NSRectFill(aRect);
  DPSgrestore(ctxt);
}

void NSHighlightRect(NSRect aRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  DPScompositerect(ctxt, NSMinX(aRect), NSMinY(aRect), 
		   NSWidth(aRect), NSHeight(aRect), 
		   NSCompositeHighlight);
}

void NSRectClip(NSRect aRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  DPSrectclip(ctxt, NSMinX(aRect), NSMinY(aRect), 
	      NSWidth(aRect), NSHeight(aRect));
  DPSnewpath(ctxt);
}

void NSRectClipList(const NSRect *rects, int count)
{
  int i;
  NSRect union_rect;

  if (count == 0)
    return;

  /* 
     The specification is not clear if the union of the rects 
     should produce the new clip rect or if the outline of all rects 
     should be used as clip path.
  */
  union_rect = rects[0];
  for (i = 1; i < count; i++)
    union_rect = NSUnionRect(union_rect, rects[i]);

  NSRectClip(union_rect);
}

void NSRectFill(NSRect aRect)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  DPSrectfill(ctxt, NSMinX(aRect), NSMinY(aRect), 
	      NSWidth(aRect), NSHeight(aRect));
}

void NSRectFillList(const NSRect *rects, int count)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  GSRectFillList(ctxt, rects, count);
}

void 
NSRectFillListWithColors(const NSRect *rects, NSColor **colors, int count)
{
  int i;

  for (i = 0; i < count; i++)
    {
      [colors[i] set];
      NSRectFill(rects[i]);
    }
}

void NSRectFillListWithGrays(const NSRect *rects, const float *grays, 
			     int count)
{
  int i;
  NSGraphicsContext *ctxt = GSCurrentContext();

  for (i = 0; i < count; i++)
    {
      DPSsetgray(ctxt, grays[i]);
      DPSrectfill(ctxt,  NSMinX(rects[i]), NSMinY(rects[i]), 
		  NSWidth(rects[i]), NSHeight(rects[i]));
    }
}

void NSRectFillUsingOperation(NSRect aRect, NSCompositingOperation op)
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  DPScompositerect(ctxt, NSMinX(aRect), NSMinY(aRect), 
		   NSWidth(aRect), NSHeight(aRect), op);
}


void 
NSRectFillListUsingOperation(const NSRect *rects, int count, 
			     NSCompositingOperation op)
{
  int i;

  for (i = 0; i < count; i++)
    {
      NSRectFillUsingOperation(rects[i], op);
    }
}

void 
NSRectFillListWithColorsUsingOperation(const NSRect *rects, 
				       NSColor **colors, 
				       int num, 
				       NSCompositingOperation op)
{
  int i;

  for (i = 0; i < num; i++)
    {
      [colors[i] set];
      NSRectFillUsingOperation(rects[i], op);
    }
}

/*
 * Draw a Bordered Rectangle
 */
void NSDottedFrameRect(const NSRect aRect)
{
  float dot_dash[] = {1.0, 1.0};
  NSGraphicsContext *ctxt = GSCurrentContext();

  DPSsetgray(ctxt, NSBlack);
  DPSsetlinewidth(ctxt, 1.0);
  // FIXME
  DPSsetdash(ctxt, dot_dash, 2, 0.0);
  DPSrectstroke(ctxt,  NSMinX(aRect), NSMinY(aRect), 
		NSWidth(aRect), NSHeight(aRect));
}

void NSFrameRect(const NSRect aRect)
{
  NSFrameRectWithWidth(aRect, 1.0);
}

void NSFrameRectWithWidth(const NSRect aRect, float frameWidth)
{
  float width;
  NSGraphicsContext *ctxt = GSCurrentContext();
  DPScurrentlinewidth(ctxt, &width);
  DPSsetlinewidth(ctxt, frameWidth);
  DPSrectstroke(ctxt,  NSMinX(aRect), NSMinY(aRect), 
		NSWidth(aRect), NSHeight(aRect));
  DPSsetlinewidth(ctxt, width);
}

//*****************************************************************************
//
// 	Draws an unfilled rectangle, clipped by clipRect, whose border
//	is defined by the parallel arrays sides and grays, both of length
//	count. Each element of sides specifies an edge of the rectangle,
//	which is drawn with a width of 1.0 using the corresponding gray level
//	from grays. If the edges array contains recurrences of the same edge,
//	each is inset within the previous edge.
//
//*****************************************************************************

NSRect 
NSDrawTiledRects(NSRect aRect,const NSRect clipRect,  
		 const NSRectEdge * sides, 
		 const float *grays, int count)
{
  int i;
  NSRect slice;
  NSRect remainder = aRect;
  NSRect rects[count];
  BOOL hasClip = !NSIsEmptyRect(clipRect);

  if (hasClip && NSIntersectsRect(aRect, clipRect) == NO)
    return remainder;

  for (i = 0; i < count; i++)
    {
      NSDivideRect(remainder, &slice, &remainder, 1.0, sides[i]);
      if (hasClip)
	rects[i] = NSIntersectionRect(slice, clipRect);
      else
	rects[i] = slice;
    }

  NSRectFillListWithGrays(rects, grays, count);

  return remainder;
}

NSRect 
NSDrawColorTiledRects(NSRect boundsRect, NSRect clipRect, 
		      const NSRectEdge *sides, NSColor **colors, 
		      int count)
{
  int i;
  NSRect slice;
  NSRect remainder = boundsRect;
  NSRect rects[count];
  BOOL hasClip = !NSIsEmptyRect(clipRect);

  if (hasClip && NSIntersectsRect(boundsRect, clipRect) == NO)
    return remainder;

  for (i = 0; i < count; i++)
    {
      NSDivideRect(remainder, &slice, &remainder, 1.0, sides[i]);
      if (hasClip)
	rects[i] = NSIntersectionRect(slice, clipRect);
      else
	rects[i] = slice;
    }

  NSRectFillListWithColors(rects, colors, count);

  return remainder;
}

void
NSDrawButton(const NSRect aRect, const NSRect clipRect)
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  NSRectEdge down_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			     NSMinXEdge, NSMinYEdge, 
			     NSMaxXEdge, NSMaxYEdge};
  float grays[] = {NSBlack, NSBlack, 
		   NSWhite, NSWhite, 
		   NSDarkGray, NSDarkGray};
  NSRect rect;
  NSGraphicsContext *ctxt = GSCurrentContext();

  if (GSWViewIsFlipped(ctxt) == YES)
    {
      rect = NSDrawTiledRects(aRect, clipRect,
			       down_sides, grays, 6);
    }
  else
    {
      rect = NSDrawTiledRects(aRect, clipRect,
			       up_sides, grays, 6);
    }

  DPSsetgray(ctxt, NSLightGray);
  DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect), 
	      NSWidth(rect), NSHeight(rect));
}

void
NSDrawGrayBezel(const NSRect aRect, const NSRect clipRect)
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge,
			   NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge};
  NSRectEdge down_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge,
			     NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge};
  float grays[] = {NSWhite, NSWhite, NSDarkGray, NSDarkGray,
		   NSLightGray, NSLightGray, NSBlack, NSBlack};
  NSRect rect;
  NSGraphicsContext *ctxt = GSCurrentContext();

  if (GSWViewIsFlipped(ctxt) == YES)
    {
      rect = NSDrawTiledRects(aRect, clipRect,
			       down_sides, grays, 8);
      // to give a really clean look we add 2 dark gray points
      DPSsetgray(ctxt, NSDarkGray);
      DPSrectfill(ctxt, NSMinX(aRect) + 1., NSMaxY(aRect) - 2., 1., 1.);
      DPSrectfill(ctxt, NSMaxX(aRect) - 2., NSMinY(aRect) + 1., 1., 1.);
    }
  else
    {
      rect = NSDrawTiledRects(aRect, clipRect,
			       up_sides, grays, 8);
      // to give a really clean look we add 2 dark gray points
      DPSsetgray(ctxt, NSDarkGray);
      DPSrectfill(ctxt, NSMinX(aRect) + 1., NSMinY(aRect) + 1., 1., 1.);
      DPSrectfill(ctxt, NSMaxX(aRect) - 2., NSMaxY(aRect) - 2., 1., 1.);
    }

  DPSsetgray(ctxt, NSLightGray);
  DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect), 
	      NSWidth(rect), NSHeight(rect));
}

void 
NSDrawGroove(const NSRect aRect, const NSRect clipRect)
{
  NSRectEdge up_sides[] = {NSMinXEdge, NSMaxYEdge, NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge, NSMaxXEdge, NSMinYEdge};
  NSRectEdge down_sides[] = {NSMinXEdge, NSMinYEdge, NSMinXEdge, NSMinYEdge, 
			     NSMaxXEdge, NSMaxYEdge, NSMaxXEdge, NSMaxYEdge};
  float grays[] = {NSDarkGray, NSDarkGray, NSWhite, NSWhite,
		   NSWhite, NSWhite, NSDarkGray, NSDarkGray};
  NSRect rect;
  NSGraphicsContext *ctxt = GSCurrentContext();

  if (GSWViewIsFlipped(ctxt) == YES)
    {
      rect = NSDrawTiledRects(aRect, clipRect,
			       down_sides, grays, 8);
    }
  else
    {
      rect = NSDrawTiledRects(aRect, clipRect,
			       up_sides, grays, 8);
    }

  DPSsetgray(ctxt, NSLightGray);
  DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect), 
	      NSWidth(rect), NSHeight(rect));
}

void 
NSDrawWhiteBezel(const NSRect aRect,  const NSRect clipRect)
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge, 
  			   NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge};
  NSRectEdge down_sides[] = {NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge, 
  			     NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge};
  float grays[] = {NSWhite, NSWhite, NSDarkGray, NSDarkGray,
  		   NSLightGray, NSLightGray, NSDarkGray, NSDarkGray};
  NSRect rect;
  NSGraphicsContext *ctxt = GSCurrentContext();

  if (GSWViewIsFlipped(ctxt) == YES)
    {
      rect = NSDrawTiledRects(aRect, clipRect,
			       down_sides, grays, 8);
    }
  else
    {
      rect = NSDrawTiledRects(aRect, clipRect,
			       up_sides, grays, 8);
    }

  DPSsetgray(ctxt, NSWhite);
  DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect), 
	      NSWidth(rect), NSHeight(rect));
}

void 
NSDrawDarkBezel(NSRect aRect, NSRect clipRect)
{
  // FIXME
  NSDrawGrayBezel(aRect, clipRect);
}

void 
NSDrawLightBezel(NSRect aRect, NSRect clipRect)
{
  // FIXME
  NSDrawWhiteBezel(aRect, clipRect);
}

void
NSDrawFramePhoto(const NSRect aRect, const NSRect clipRect)
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  NSRectEdge down_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			     NSMinXEdge, NSMinYEdge, 
			     NSMaxXEdge, NSMaxYEdge};
  float grays[] = {NSDarkGray, NSDarkGray, 
		   NSDarkGray, NSDarkGray,
                   NSBlack, NSBlack};
 
  NSRect rect;
  NSGraphicsContext *ctxt = GSCurrentContext();

  if (GSWViewIsFlipped(ctxt) == YES)
    {
      rect = NSDrawTiledRects(aRect, clipRect,
			       down_sides, grays, 6);
    }
  else
    {
      rect = NSDrawTiledRects(aRect, clipRect,
			       up_sides, grays, 6);
    }

  DPSsetgray(ctxt, NSLightGray);
  DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect), 
	      NSWidth(rect), NSHeight(rect));
}

void 
NSDrawWindowBackground(NSRect aRect)
{
  [[NSColor windowBackgroundColor] set];
  NSRectFill(aRect);  
}

void 
NSFrameLinkRect(NSRect aRect, BOOL isDestination)
{
// TODO
}

float 
NSLinkFrameThickness(void)
{
// TODO
  return 1.5;
}

void 
NSConvertGlobalToWindowNumber(int globalNum, unsigned int *winNum)
{
// TODO
  *winNum = 0;
}

void 
NSConvertWindowNumberToGlobal(int winNum, unsigned int *globalNum)
{
// TODO
  *globalNum = 0;
}

void 
NSCountWindowsForContext(int context, int *count)
{
// TODO
  *count = 0;
}

void 
NSShowSystemInfoPanel(NSDictionary *options)
{
  [NSApp orderFrontStandardInfoPanelWithOptions: options];
}

void 
NSWindowListForContext(int context, int size, int list[][])
{
// TODO
}

int 
NSGetWindowServerMemory(int context, int *virtualMemory, 
			int *windowBackingMemory, NSString **windowDumpStream)
{
// TODO
  return -1;
}

