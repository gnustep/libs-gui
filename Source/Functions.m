/* 
   Functions.m

   Generic Functions for the GNUstep GUI Library.

   Copyright (C) 1996 Free Software Foundation, Inc.

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/Functions.h>
#include <gnustep/gui/LogFile.h>
#include <stdio.h>
#include <stdarg.h>

// Should be in Foundation Kit
// Does not handle %@
// yuck, yuck, yuck
extern LogFile *logFile;
void NSLogV(NSString *format, va_list args)
{
	char out[1024];

	vsprintf(out, [format cString], args);
	[logFile writeLog:out];
}

void NSLog(NSString *format, ...)
{
	va_list ap;

	va_start(ap, format);
	NSLogV(format, ap);
	va_end(ap);
}

void NSNullLog(NSString *format, ...)
{
}

//
// Rectangle Drawing Functions
//
//
// Optimize Drawing
//
void NSEraseRect(NSRect aRect)
{}

void NSHighlightRect(NSRect aRect)
{}

void NSRectClip(NSRect aRect)
{}

void NSRectClipList(const NSRect *rects, int count)
{}

void NS__RectFill(id self, NSRect aRect)
{
	char out[80];
        sprintf(out, "DPS: rect: %f %f %f %f\n", aRect.origin.x,
		aRect.origin.y, aRect.size.width, aRect.size.height);
        NSDebugLog([NSString stringWithCString: out]);

	PSrectfill(aRect.origin.x, aRect.origin.y, 
		   aRect.size.width, aRect.size.height);
}

void NSRectFillList(const NSRect *rects, int count)
{}

void NSRectFillListWithGrays(const NSRect *rects, 
			     const float *grays, int count)
{}

//
// Draw a Bordered Rectangle
//
void NSDrawButton(NSRect aRect, NSRect clipRect)
{}

void NSDrawGrayBezel(NSRect aRect, NSRect clipRect)
{}

void NSDrawGroove(NSRect aRect, NSRect clipRect)
{}

NSRect NSDrawTiledRects(NSRect boundsRect, NSRect clipRect, 
			const NSRectEdge *sides, const float *grays, 
			int count)
{
	return NSZeroRect;
}

void NSDrawWhiteBezel(NSRect aRect, NSRect clipRect)
{}

void NSFrameRect(NSRect aRect)
{}

void NSFrameRectWithWidth(NSRect aRect, float frameWidth)
{}

//
// Color Functions
//
//
// Get Information About Color Space and Window Depth
//
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

//
// Read the Color at a Screen Position
//
NSColor *NSReadPixel(NSPoint location)
{
	return nil;
}

//
// Text Functions
//
//
// Filter Characters Entered into a Text Object
//
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

//
// Calculate or Draw a Line of Text (in Text Object)
//
int NSDrawALine(id self, NSLayInfo *layInfo)
{
	return 0;
}

int NSScanALine(id self, NSLayInfo *layInfo)
{
	return 0;
}

//
// Calculate Font Ascender, Descender, and Line Height (in Text Object)
//
void NSTextFontInfo(id fid, 
		    float *ascender, float *descender, 
		    float *lineHeight)
{}

//
// Access Text Object's Word Tables
//
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


//
// Imaging Functions
//
//
// Copy an image
//
void NSCopyBitmapFromGState(int srcGstate, NSRect srcRect, NSRect destRect)
{}

void NSCopyBits(int srcGstate, NSRect srcRect, NSPoint destPoint)
{}

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
                  const unsigned char *const data[5])
{}

//
// Attention Panel Functions
//
//
// Create an Attention Panel without Running It Yet
//
id NSGetAlertPanel(NSString *title,
                   NSString *msg,
                   NSString *defaultButton,
                   NSString *alternateButton, 
                   NSString *otherButton, ...)
{
	return nil;
}

//
// Create and Run an Attention Panel
//
int NSRunAlertPanel(NSString *title,
                    NSString *msg,
                    NSString *defaultButton,
                    NSString *alternateButton,
                    NSString *otherButton, ...)
{
	return 0;
}

int NSRunLocalizedAlertPanel(NSString *table,
                             NSString *title,
                             NSString *msg,
                             NSString *defaultButton, 
                             NSString *alternateButton, 
                             NSString *otherButton, ...)
{
	return 0;
}

//
// Release an Attention Panel
//
void NSReleaseAlertPanel(id panel)
{}

//
// Services Menu Functions
//
//
// Determine Whether an Item Is Included in Services Menus
//
int NSSetShowsServicesMenuItem(NSString *item, BOOL showService)
{
	return 0;
}

BOOL NSShowsServicesMenuItem(NSString *item)
{
	return NO;
}

//
// Programmatically Invoke a Service
//
BOOL NSPerformService(NSString *item, NSPasteboard *pboard)
{
	return NO;
}

//
// Force Services Menu to Update Based on New Services
//
void NSUpdateDynamicServices(void)
{}

//
// Other Application Kit Functions
//
//
// Play the System Beep
//
void NSBeep(void)
{
#ifdef WIN32
	MessageBeep(MB_OK);
#endif
}

//
// Return File-related Pasteboard Types
//
NSString *NSCreateFileContentsPboardType(NSString *fileType)
{
	return nil;
}

NSString *NSCreateFilenamePboardType(NSString *filename)
{
	return nil;
}

NSString *NSGetFileType(NSString *pboardType)
{
	return nil;
}

NSArray *NSGetFileTypes(NSArray *pboardTypes)
{
	return nil;
}

//
// Draw a Distinctive Outline around Linked Data
//
void NSFrameLinkRect(NSRect aRect, BOOL isDestination)
{}

float NSLinkFrameThickness(void)
{
	return 0;
}

//
// Convert an Event Mask Type to a Mask
//
unsigned int NSEventMaskFromType(NSEventType type)
{
	return 0;
}
