/* 
   Functions.m

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: November 1998
   
   This file is part of the GNUstep Project

   This library is free software; you can redistribute it and/or 
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
   
   You should have received a copy of the GNU General Public 
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

*/ 

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSCStringText.h>
#include <AppKit/NSEvent.h>
#include <AppKit/GSWraps.h>

/*
 * Dummy definitions provided here to avoid errors when not linking with
 * a back end.
 */

BOOL initialize_gnustep_backend(void)
{
  return YES;
}
void NSHighlightRect(NSRect aRect)
{}
void NSRectClip(NSRect aRect)
{}
void NSRectFill(NSRect aRect)
{}
void NSFrameRect(NSRect aRect)
{}
void NSEraseRect(NSRect aRect)
{}
void NSDrawButton(NSRect aRect, NSRect clipRect)
{}
void NSDrawGrayBezel(NSRect aRect, NSRect clipRect)
{}
void NSDrawGroove(NSRect aRect, NSRect clipRect)
{}
void NSDrawPopupNibble(NSPoint aPoint)
{}
void NSDrawDownArrow(NSPoint aPoint)
{}

/* Dummy wraps */
unsigned int GSWDefineAsUserObj(NSGraphicsContext *ctxt) {return 0;}
void GSWViewIsFlipped(NSGraphicsContext *ctxt, BOOL flipped) {}

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


void NSDrawWhiteBezel(NSRect aRect, NSRect clipRect)
{
}

void NSDrawBezel(NSRect aRect, NSRect clipRect)
{
}


NSRect NSDrawTiledRects(NSRect boundsRect, NSRect clipRect, 
			const NSRectEdge *sides, const float *grays, int count)
{
  return NSZeroRect;
}

const NSWindowDepth *NSAvailableWindowDepths(void)
{
  return NULL;
}

NSWindowDepth NSBestDepth(NSString *colorSpace, 
			  int bitsPerSample, int bitsPerPixel, 
			  BOOL planar, BOOL *exactMatch)
{
  return 0;
}

int NSBitsPerPixelFromDepth(NSWindowDepth depth)
{
  return 0;
}

int NSBitsPerSampleFromDepth(NSWindowDepth depth)
{
  return 0;
}

NSString *NSColorSpaceFromDepth(NSWindowDepth depth)
{
  return nil;
}

int NSNumberOfColorComponents(NSString *colorSpaceName)
{
  return 0;
}

BOOL NSPlanarFromDepth(NSWindowDepth depth)
{
  return NO;
}

NSColor *NSReadPixel(NSPoint location)
{
  return nil;
}

unsigned short NSEditorFilter(unsigned short theChar, 
			      int flags, NSStringEncoding theEncoding)
{
  return 0;
}

unsigned short NSFieldFilter(unsigned short theChar, 
			     int flags, NSStringEncoding theEncoding)
{
  return 0;
}

int NSDrawALine(id self, NSLayInfo *layInfo)
{
  return 0;
}

int NSScanALine(id self, NSLayInfo *layInfo)
{
  return 0;
}

void NSTextFontInfo(id fid, 
		    float *ascender, float *descender, 
		    float *lineHeight)
{}

NSData * NSDataWithWordTable(const unsigned char *smartLeft,
			     const unsigned char *smartRight,
			     const unsigned char *charClasses,
			     const NSFSM *wrapBreaks,
			     int wrapBreaksCount,
			     const NSFSM *clickBreaks, 
			     int clickBreaksCount, 
			     BOOL charWrap)
{
  return nil;
}

void NSReadWordTable(NSZone *zone,
		     NSData *data,
		     unsigned char **smartLeft,
		     unsigned char **smartRight,
		     unsigned char **charClasses,
		     NSFSM **wrapBreaks,
		     int *wrapBreaksCount,
		     NSFSM **clickBreaks,
		     int *clickBreaksCount, 
		     BOOL *charWrap)
{}

//
// Array Allocation Functions for Use by the NSText Class
//
NSTextChunk *NSChunkCopy(NSTextChunk *pc, NSTextChunk *dpc)
{
  return NULL;
}

NSTextChunk *NSChunkGrow(NSTextChunk *pc, int newUsed)
{
  return NULL;
}

NSTextChunk *NSChunkMalloc(int growBy, int initUsed)
{
  return NULL;
}

NSTextChunk *NSChunkRealloc(NSTextChunk *pc)
{
  return NULL;
}

NSTextChunk *NSChunkZoneCopy(NSTextChunk *pc, 
                             NSTextChunk *dpc,
                             NSZone *zone)
{
  return NULL;
}

NSTextChunk *NSChunkZoneGrow(NSTextChunk *pc, int newUsed, NSZone *zone)
{
  return NULL;
}

NSTextChunk *NSChunkZoneMalloc(int growBy, int initUsed, NSZone *zone)
{
  return NULL;
}

NSTextChunk *NSChunkZoneRealloc(NSTextChunk *pc, NSZone *zone)
{
  return NULL;
}

void NSCopyBitmapFromGState(int srcGstate, NSRect srcRect, NSRect destRect)
{
}

void NSCopyBits(int srcGstate, NSRect srcRect, NSPoint destPoint)
{
}

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
                  const unsigned char *const data[5])
{
}

void NSBeep(void)
{
}

//
// Draw a Distinctive Outline around Linked Data
//
void NSFrameLinkRect(NSRect aRect, BOOL isDestination)
{
}

float NSLinkFrameThickness(void)
{
  return 0;
}

// Color Functions
NSWindowDepth GSWindowDepthForScreen(int screen) {}

const NSWindowDepth *GSAvailableDepthsForScreen(int screen) {}
