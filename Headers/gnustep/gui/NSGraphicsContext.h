/* NSGraphicsContext - Generic drawing DrawContext class.

   Copyright (C) 1998,1999 Free Software Foundation, Inc.

   Author:      Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: Feb 1999
   Based on code by:  Adam Fedor <fedor@gnu.org>
   Date: Nov 1998
   
   This file is part of the GNU Objective C User interface library.

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

#ifndef	STRICT_OPENSTEP

#ifndef _NSGraphicsContext_h_INCLUDE
#define _NSGraphicsContext_h_INCLUDE

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSSet.h>

#include <AppKit/GSMethodTable.h>
#include <AppKit/NSDragging.h>

@class NSDate;
@class NSDictionary;
@class NSEvent;
@class NSMutableArray;
@class NSMutableData;
@class NSString;
@class NSView;

//
// Backing Store Types
//
typedef enum _NSBackingStoreType
{
  NSBackingStoreRetained,
  NSBackingStoreNonretained,
  NSBackingStoreBuffered

} NSBackingStoreType;

//
// Compositing operators
//
typedef enum _NSCompositingOperation
{
  NSCompositeClear,
  NSCompositeCopy,
  NSCompositeSourceOver,
  NSCompositeSourceIn,
  NSCompositeSourceOut,
  NSCompositeSourceAtop,
  NSCompositeDataOver,
  NSCompositeDataIn,
  NSCompositeDataOut,
  NSCompositeDataAtop,
  NSCompositeXOR,
  NSCompositePlusDarker,
  NSCompositeHighlight,
  NSCompositePlusLighter

} NSCompositingOperation;

//
// Window ordering
//
typedef enum _NSWindowOrderingMode
{
  NSWindowAbove,
  NSWindowBelow,
  NSWindowOut

} NSWindowOrderingMode;


@interface NSGraphicsContext : NSObject
{
  /* Make the one public instance variable first in the object so that, if we
   * add or remove others, we don't necessarily need to recompile everything.
   */
@public
  const gsMethodTable	*methods;

@protected
  NSDictionary		*context_info;
  NSMutableData		*context_data;
  NSMutableArray	*focus_stack;
  NSMutableArray	*event_queue;
  NSMapTable		*drag_types;
}

+ (NSGraphicsContext*) currentContext;
+ (void) setCurrentContext: (NSGraphicsContext*)context;

- (void) flush;
- (BOOL) isDrawingToScreen;
- (void) restoreGraphicsState;
- (void) saveGraphicsState;
- (void) wait;
@end

#ifndef	NO_GNUSTEP
NSGraphicsContext	*GSCurrentContext();

@interface NSGraphicsContext (GNUstep)
+ (void) setDefaultContextClass: (Class)defaultContextClass;
+ (NSGraphicsContext*) defaultContextWithInfo: (NSDictionary *)info;
- (id) initWithContextInfo: (NSDictionary *)info;
- (void) destroyContext;
- (NSMutableData *) mutableData;
/*
 * Focus management methods - lock and unlock should only be used by NSView
 * in it's implementation of lockFocus and unlockFocus.
 */
- (NSView*) focusView;
- (void) lockFocusView: (NSView*)aView inRect: (NSRect)rect;
- (void) unlockFocusView: (NSView*)aView needsFlush: (BOOL)flush;

/*
 *	Drag and drop support
 */
- (BOOL) _addDragTypes: (NSArray*)types toWindow: (int)winNum;
- (BOOL) _removeDragTypes: (NSArray*)types fromWindow: (int)winNum;
- (NSCountedSet*) _dragTypesForWindow: (int)winNum;
- (id <NSDraggingInfo>)_dragInfo;
- (void) _postExternalEvent: (NSEvent *)event;

/*
 *	Misc window management support.
 */
- (BOOL) _setFrame: (NSRect)frameRect forWindow: (int)winNum;
- (void) _orderWindow: (NSWindowOrderingMode)place
	   relativeTo: (int)otherWin
	    forWindow: (int)winNum;

@end
#endif



/*
 *	GNUstep drawing engine extensions - these are the methods actually
 *	called when one of the inline PostScript functions (like PSlineto())
 *	is called.
 */

@interface NSGraphicsContext (Ops)

/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */
- (void) DPScurrentcmykcolor: (float*)c : (float*)m : (float*)y : (float*)k ;
- (void) DPSsetcmykcolor: (float)c : (float)m : (float)y : (float)k ;
/* ----------------------------------------------------------------------- */
/* Data operations */
/* ----------------------------------------------------------------------- */
- (void) DPSclear;
- (void) DPScleartomark;
- (void) DPScopy: (int)n ;
- (void) DPScount: (int *)n ;
- (void) DPScounttomark: (int *)n ;
- (void) DPSdup;
- (void) DPSexch;
- (void) DPSexecstack;
- (void) DPSget;
- (void) DPSindex: (int)i ;
- (void) DPSmark;
- (void) DPSmatrix;
- (void) DPSnull;
- (void) DPSpop;
- (void) DPSput;
- (void) DPSroll: (int)n : (int)j ;
/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */
- (void) DPSFontDirectory;
- (void) DPSISOLatin1Encoding;
- (void) DPSSharedFontDirectory;
- (void) DPSStandardEncoding;
- (void) DPScurrentcacheparams;
- (void) DPScurrentfont;
- (void) DPSdefinefont;
- (void) DPSfindfont: (const char *)name ;
- (void) DPSmakefont;
- (void) DPSscalefont: (float)size ;
- (void) DPSselectfont: (const char *)name : (float)scale ;
- (void) DPSsetfont: (int)f ;
- (void) DPSundefinefont: (const char *)name ;
/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */
- (void) DPSconcat: (const float*)m ;
- (void) DPScurrentdash;
- (void) DPScurrentflat: (float*)flatness ;
- (void) DPScurrentgray: (float*)gray ;
- (void) DPScurrentgstate: (int)gst ;
- (void) DPScurrenthalftone;
- (void) DPScurrenthalftonephase: (float*)x : (float*)y ;
- (void) DPScurrenthsbcolor: (float*)h : (float*)s : (float*)b ;
- (void) DPScurrentlinecap: (int *)linecap ;
- (void) DPScurrentlinejoin: (int *)linejoin ;
- (void) DPScurrentlinewidth: (float*)width ;
- (void) DPScurrentmatrix;
- (void) DPScurrentmiterlimit: (float*)limit ;
- (void) DPScurrentpoint: (float*)x : (float*)y ;
- (void) DPScurrentrgbcolor: (float*)r : (float*)g : (float*)b ;
- (void) DPScurrentscreen;
- (void) DPScurrentstrokeadjust: (int *)b ;
- (void) DPScurrenttransfer;
- (void) DPSdefaultmatrix;
- (void) DPSgrestore;
- (void) DPSgrestoreall;
- (void) DPSgsave;
- (void) DPSgstate;
- (void) DPSinitgraphics;
- (void) DPSinitmatrix;
- (void) DPSrotate: (float)angle ;
- (void) DPSscale: (float)x : (float)y ;
- (void) DPSsetdash: (const float*)pat : (int)size : (float)offset ;
- (void) DPSsetflat: (float)flatness ;
- (void) DPSsetgray: (float)gray ;
- (void) DPSsetgstate: (int)gst ;
- (void) DPSsethalftone;
- (void) DPSsethalftonephase: (float)x : (float)y ;
- (void) DPSsethsbcolor: (float)h : (float)s : (float)b ;
- (void) DPSsetlinecap: (int)linecap ;
- (void) DPSsetlinejoin: (int)linejoin ;
- (void) DPSsetlinewidth: (float)width ;
- (void) DPSsetmatrix;
- (void) DPSsetmiterlimit: (float)limit ;
- (void) DPSsetrgbcolor: (float)r : (float)g : (float)b ;
- (void) DPSsetscreen;
- (void) DPSsetstrokeadjust: (int)b ;
- (void) DPSsettransfer;
- (void) DPStranslate: (float)x : (float)y ;
/* ----------------------------------------------------------------------- */
/* I/O  operations */
/* ----------------------------------------------------------------------- */
- (void) DPSflush;
/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
- (void) DPSconcatmatrix;
- (void) DPSdtransform: (float)x1 : (float)y1 : (float*)x2 : (float*)y2 ;
- (void) DPSidentmatrix;
- (void) DPSidtransform: (float)x1 : (float)y1 : (float*)x2 : (float*)y2 ;
- (void) DPSinvertmatrix;
- (void) DPSitransform: (float)x1 : (float)y1 : (float*)x2 : (float*)y2 ;
- (void) DPStransform: (float)x1 : (float)y1 : (float*)x2 : (float*)y2 ;
/* ----------------------------------------------------------------------- */
/* Opstack operations */
/* ----------------------------------------------------------------------- */
- (void) DPSdefineuserobject;
- (void) DPSexecuserobject: (int)index ;
- (void) DPSundefineuserobject: (int)index ;
- (void) DPSgetboolean: (int *)it ;
- (void) DPSgetchararray: (int)size : (char *)s ;
- (void) DPSgetfloat: (float*)it ;
- (void) DPSgetfloatarray: (int)size : (float*)a ;
- (void) DPSgetint: (int *)it ;
- (void) DPSgetintarray: (int)size : (int *)a ;
- (void) DPSgetstring: (char *)s ;
- (void) DPSsendboolean: (int)it ;
- (void) DPSsendchararray: (const char *)s : (int)size ;
- (void) DPSsendfloat: (float)it ;
- (void) DPSsendfloatarray: (const float*)a : (int)size ;
- (void) DPSsendint: (int)it ;
- (void) DPSsendintarray: (const int *)a : (int)size ;
- (void) DPSsendstring: (const char *)s ;
/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */
- (void) DPSashow: (float)x : (float)y : (const char *)s ;
- (void) DPSawidthshow: (float)cx : (float)cy : (int)c : (float)ax : (float)ay : (const char *)s ;
- (void) DPScopypage;
- (void) DPSeofill;
- (void) DPSerasepage;
- (void) DPSfill;
- (void) DPSimage;
- (void) DPSimagemask;
- (void) DPSkshow: (const char *)s ;
- (void) DPSrectfill: (float)x : (float)y : (float)w : (float)h ;
- (void) DPSrectstroke: (float)x : (float)y : (float)w : (float)h ;
- (void) DPSshow: (const char *)s ;
- (void) DPSshowpage;
- (void) DPSstroke;
- (void) DPSstrokepath;
- (void) DPSueofill: (const char *)nums : (int)n : (const char *)ops : (int)l ;
- (void) DPSufill: (const char *)nums : (int)n : (const char *)ops : (int)l ;
- (void) DPSustroke: (const char *)nums : (int)n : (const char *)ops : (int)l ;
- (void) DPSustrokepath: (const char *)nums : (int)n : (const char *)ops : (int)l ;
- (void) DPSwidthshow: (float)x : (float)y : (int)c : (const char *)s ;
- (void) DPSxshow: (const char *)s : (const float*)numarray : (int)size ;
- (void) DPSxyshow: (const char *)s : (const float*)numarray : (int)size ;
- (void) DPSyshow: (const char *)s : (const float*)numarray : (int)size ;
/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */
- (void) DPSarc: (float)x : (float)y : (float)r : (float)angle1 : (float)angle2 ;
- (void) DPSarcn: (float)x : (float)y : (float)r : (float)angle1 : (float)angle2 ;
- (void) DPSarct: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)r ;
- (void) DPSarcto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)r : (float*)xt1 : (float*)yt1 : (float*)xt2 : (float*)yt2 ;
- (void) DPScharpath: (const char *)s : (int)b ;
- (void) DPSclip;
- (void) DPSclippath;
- (void) DPSclosepath;
- (void) DPScurveto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)x3 : (float)y3 ;
- (void) DPSeoclip;
- (void) DPSeoviewclip;
- (void) DPSflattenpath;
- (void) DPSinitclip;
- (void) DPSinitviewclip;
- (void) DPSlineto: (float)x : (float)y ;
- (void) DPSmoveto: (float)x : (float)y ;
- (void) DPSnewpath;
- (void) DPSpathbbox: (float*)llx : (float*)lly : (float*)urx : (float*)ury ;
- (void) DPSpathforall;
- (void) DPSrcurveto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)x3 : (float)y3 ;
- (void) DPSrectclip: (float)x : (float)y : (float)w : (float)h ;
- (void) DPSrectviewclip: (float)x : (float)y : (float)w : (float)h ;
- (void) DPSreversepath;
- (void) DPSrlineto: (float)x : (float)y ;
- (void) DPSrmoveto: (float)x : (float)y ;
- (void) DPSsetbbox: (float)llx : (float)lly : (float)urx : (float)ury ;
- (void) DPSviewclip;
- (void) DPSviewclippath;
/* ----------------------------------------------------------------------- */
/* Window system ops */
/* ----------------------------------------------------------------------- */
- (void) DPScurrentdrawingfunction: (int *)function ;
- (void) DPScurrentgcdrawable: (void* *)gc : (void* *)draw : (int *)x : (int *)y ;
- (void) DPScurrentgcdrawablecolor: (void* *)gc : (void* *)draw : (int *)x : (int *)y : (int *)colorInfo ;
- (void) DPScurrentoffset: (int *)x : (int *)y ;
- (void) DPSsetdrawingfunction: (int)function ;
- (void) DPSsetgcdrawable: (void*)gc : (void*)draw : (int)x : (int)y ;
- (void) DPSsetgcdrawablecolor: (void*)gc : (void*)draw : (int)x : (int)y : (const int *)colorInfo ;
- (void) DPSsetoffset: (short int)x : (short int)y ;
- (void) DPSsetrgbactual: (double)r : (double)g : (double)b : (int *)success ;
- (void) DPScapturegstate: (int *)gst ;

/*-------------------------------------------------------------------------*/
/* Graphics Extensions Ops */
/*-------------------------------------------------------------------------*/
- (void) DPScomposite: (float)x : (float)y : (float)w : (float)h : (int)gstateNum : (float)dx : (float)dy : (int)op;
- (void) DPScompositerect: (float)x : (float)y : (float)w : (float)h : (int)op;
- (void) DPSdissolve: (float)x : (float)y : (float)w : (float)h : (int)gstateNum
 : (float)dx : (float)dy : (float)delta;
- (void) DPSreadimage;
- (void) DPSsetalpha: (float)a;
- (void) DPScurrentalpha: (float *)a;

/* ----------------------------------------------------------------------- */
/* GNUstep Event and other I/O extensions */
/* ----------------------------------------------------------------------- */
- (NSEvent*) DPSGetEventMatchingMask: (unsigned)mask
			  beforeDate: (NSDate*)limit
			      inMode: (NSString*)mode
			     dequeue: (BOOL)flag;
- (void) DPSDiscardEventsMatchingMask: (unsigned)mask
			  beforeEvent: (NSEvent*)limit;
- (void) DPSPostEvent: (NSEvent*)anEvent atStart: (BOOL)flag;
- (void) DPSmouselocation: (float*)x : (float*)y;
@end

#endif /* _NSGraphicsContext_h_INCLUDE */

#endif	/* STRICT_OPENSTEP	*/

