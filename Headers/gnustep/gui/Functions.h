/* 
   Functions.h

   Generic functions for the GNUstep GUI Library

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

#ifndef _GNUstep_H_AppKitFunctions
#define _GNUstep_H_AppKitFunctions

#include <AppKit/stdappkit.h>
#include <DPSClient/DPSOperators.h>

@class NSPasteboard, NSColor;

//
// Rectangle Drawing Functions
//
//
// Optimize Drawing
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
// Color Functions
//
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
// Text Functions
//
//
// Filter Characters Entered into a Text Object
//
unsigned short NSEditorFilter(unsigned short theChar, 
			      int flags, NSStringEncoding theEncoding);
unsigned short NSFieldFilter(unsigned short theChar, 
			     int flags, NSStringEncoding theEncoding);

//
// Calculate or Draw a Line of Text (in Text Object)
//
int NSDrawALine(id self, NSLayInfo *layInfo);
int NSScanALine(id self, NSLayInfo *layInfo);

//
// Calculate Font Ascender, Descender, and Line Height (in Text Object)
//
void NSTextFontInfo(id fid, 
		    float *ascender, float *descender, 
		    float *lineHeight);

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
			     BOOL charWrap);
void NSReadWordTable(NSZone *zone,
		     NSData *data,
		     unsigned char **smartLeft,
		     unsigned char **smartRight,
		     unsigned char **charClasses,
		     NSFSM **wrapBreaks,
		     int *wrapBreaksCount,
		     NSFSM **clickBreaks,
		     int *clickBreaksCount, 
		     BOOL *charWrap);

//
// Array Allocation Functions for Use by the NSText Class
//
NSTextChunk *NSChunkCopy(NSTextChunk *pc, NSTextChunk *dpc);
NSTextChunk *NSChunkGrow(NSTextChunk *pc, int newUsed);
NSTextChunk *NSChunkMalloc(int growBy, int initUsed);
NSTextChunk *NSChunkRealloc(NSTextChunk *pc);
NSTextChunk *NSChunkZoneCopy(NSTextChunk *pc, 
                             NSTextChunk *dpc,
                             NSZone *zone);
NSTextChunk *NSChunkZoneGrow(NSTextChunk *pc, int newUsed, NSZone *zone);
NSTextChunk *NSChunkZoneMalloc(int growBy, int initUsed, NSZone *zone);
NSTextChunk *NSChunkZoneRealloc(NSTextChunk *pc, NSZone *zone);

//
// Imaging Functions
//
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
// Attention Panel Functions
//
//
// Create an Attention Panel without Running It Yet
//
id NSGetAlertPanel(NSString *title,
                   NSString *msg,
                   NSString *defaultButton,
                   NSString *alternateButton, 
                   NSString *otherButton, ...);

//
// Create and Run an Attention Panel
//
int NSRunAlertPanel(NSString *title,
                    NSString *msg,
                    NSString *defaultButton,
                    NSString *alternateButton,
                    NSString *otherButton, ...);
int NSRunLocalizedAlertPanel(NSString *table,
                             NSString *title,
                             NSString *msg,
                             NSString *defaultButton, 
                             NSString *alternateButton, 
                             NSString *otherButton, ...);

//
// Release an Attention Panel
//
void NSReleaseAlertPanel(id panel);

//
// Services Menu Functions
//
//
// Determine Whether an Item Is Included in Services Menus
//
int NSSetShowsServicesMenuItem(NSString *item, BOOL showService);
BOOL NSShowsServicesMenuItem(NSString *item);

//
// Programmatically Invoke a Service
//
BOOL NSPerformService(NSString *item, NSPasteboard *pboard);

//
// Force Services Menu to Update Based on New Services
//
void NSUpdateDynamicServices(void);

//
// Other GNUstep GUI Library Functions
//
//
// Play the System Beep
//
void NSBeep(void);

//
// Return File-related Pasteboard Types
//
NSString *NSCreateFileContentsPboardType(NSString *fileType);
NSString *NSCreateFilenamePboardType(NSString *filename);
NSString *NSGetFileType(NSString *pboardType);
NSArray *NSGetFileTypes(NSArray *pboardTypes);

//
// Draw a Distinctive Outline around Linked Data
//
void NSFrameLinkRect(NSRect aRect, BOOL isDestination);
float NSLinkFrameThickness(void);

//
// Convert an Event Mask Type to a Mask
//
unsigned int NSEventMaskFromType(NSEventType type);

#endif // _GNUstep_H_AppKitFunctions
