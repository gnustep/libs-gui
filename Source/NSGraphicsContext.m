/* NSGraphicsContext - GNUstep drawing context class.

   Copyright (C) 1998 Free Software Foundation, Inc.

   Written by:  Adam Fedor <fedor@gnu.org>
   Date: Nov 1998
   Updated by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: Feb 1999
   
   This file is part of the GNUStep GUI Library.

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
   

#include <Foundation/NSString.h> 
#include <Foundation/NSArray.h> 
#include <Foundation/NSValue.h> 
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSData.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSZone.h>
#include "AppKit/NSGraphicsContext.h"
#include "AppKit/NSAffineTransform.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSView.h"

/* The memory zone where all global objects are allocated from (Contexts
   are also allocated from this zone) */
NSZone *_globalGSZone = NULL;

/* The current concrete class */
static Class defaultNSGraphicsContextClass = NULL;

/* List of contexts */
static NSMutableArray	*contextList;

/* Class variable for holding pointers to method functions */
static NSMutableDictionary *classMethodTable;

/* Lock for use when creating contexts */
static NSRecursiveLock  *contextLock = nil;

#ifndef GNUSTEP_BASE_LIBRARY
static NSString	*NSGraphicsContextThreadKey = @"NSGraphicsContextThreadKey";
#endif

/*
 *	Function for rapid access to current graphics context.
 */
NSGraphicsContext	*GSCurrentContext()
{
#ifdef GNUSTEP_BASE_LIBRARY
/*
 *	gstep-base has a faster mechanism to get the current thread.
 */
  NSThread *th = GSCurrentThread();

  return (NSGraphicsContext*) th->_gcontext;
#else
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];

  return (NSGraphicsContext*) [dict objectForKey: NSGraphicsContextThreadKey];
#endif
}


@interface NSGraphicsContext (Private)
+ (gsMethodTable *) _initializeMethodTable;
@end

@implementation NSGraphicsContext 

+ (void) initialize
{
  if (contextLock == nil)
    {
      [gnustep_global_lock lock];
      if (contextLock == nil)
	{
	  contextLock = [NSRecursiveLock new];
	  defaultNSGraphicsContextClass = [NSGraphicsContext class];
	  _globalGSZone = NSDefaultMallocZone();
	  contextList = [[NSMutableArray allocWithZone: _globalGSZone] init];
	  classMethodTable =
	    [[NSMutableDictionary allocWithZone: _globalGSZone] init];
	}
      [gnustep_global_lock unlock];
    }
}

+ (void) setDefaultContextClass: (Class)defaultContextClass
{
  defaultNSGraphicsContextClass = defaultContextClass;
}

+ defaultContextWithInfo: (NSDictionary *)info;
{
  NSGraphicsContext *ctxt;

  NSAssert(defaultNSGraphicsContextClass, 
	   @"Internal Error: No default NSGraphicsContext set\n");
  ctxt = [[defaultNSGraphicsContextClass allocWithZone: _globalGSZone]
	   initWithContextInfo: info];
  [ctxt autorelease];
  return ctxt;
}

+ (void) setCurrentContext: (NSGraphicsContext *)context
{
#ifdef GNUSTEP_BASE_LIBRARY
/*
 *	gstep-base has a faster mechanism to get the current thread.
 */
  NSThread *th = GSCurrentThread();

  th->_gcontext = context;
#else
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];

  [dict setObject: context forKey: NSGraphicsContextThreadKey];
#endif
}

+ (NSGraphicsContext *) currentContext
{
  return GSCurrentContext();
}

- (void) dealloc
{
  if (GSCurrentContext() == self)
    [NSGraphicsContext setCurrentContext: nil];
  DESTROY(focus_stack);
  DESTROY(context_data);
  DESTROY(context_info);
  DESTROY(event_queue);
  NSFreeMapTable(drag_types);
  [super dealloc];
}

/* Just remove ourselves from the context list so we will be dealloced on
   the next autorelease pool end */
- (void) destroyContext;
{
  [contextLock lock];
  [contextList removeObject: self];
  [contextLock unlock];
}

- (id) init
{
  return [self initWithContextInfo: NULL];
}

/* designated initializer for the NSGraphicsContext class */
- (id) initWithContextInfo: (NSDictionary *)info
{
  [super init];

  context_info = [info retain];
  focus_stack = [[NSMutableArray allocWithZone: [self zone]]
			initWithCapacity: 1];
  event_queue = [[NSMutableArray allocWithZone: [self zone]]
			initWithCapacity: 32];
  drag_types = NSCreateMapTable(NSIntMapKeyCallBacks,
                NSObjectMapValueCallBacks, 0);

  /*
   * The classMethodTable dictionary and the list of all contexts must both
   * be protected from other threads.
   */
  [contextLock lock];
  if (!(methods = [[classMethodTable objectForKey: [self class]] pointerValue]))
    {
      methods = [[self class] _initializeMethodTable];
      [classMethodTable setObject: [NSValue valueWithPointer: methods]
			   forKey: [self class]];
    }
  [contextList addObject: self];
  [contextLock unlock];

  return self;
}

- (void) flush
{
}

- (BOOL) isDrawingToScreen
{
  return NO;
}

- (NSMutableData*) mutableData
{
  return context_data;
}

- (void) restoreGraphicsState
{
}

- (void) saveGraphicsState
{
}

- (void) wait
{
}

- (NSView*) focusView
{
  return [focus_stack lastObject];
}

- (void) lockFocusView: (NSView*)aView inRect: (NSRect)rect
{
  [focus_stack addObject: aView];
}

- (void) unlockFocusView: (NSView*)aView needsFlush: (BOOL)flush
{
  [focus_stack removeLastObject];
}

/*
 *      Drag and drop support
 */

/*
 * Add (increment count by 1) each drag type to those registered
 * for the window.  If this results in a change to the types registered
 * in the counted set, return YES, otherwise return NO.
 * Subclasses should override this method, call 'super' and take
 * appropriate action if the method returns 'YES'.
 */
- (BOOL) _addDragTypes: (NSArray*)types toWindow: (int)winNum
{
  NSCountedSet	*old = (NSCountedSet*)NSMapGet(drag_types, (void*)winNum);
  unsigned	originalCount;
  unsigned	i = [types count];

  /*
   * Make sure the set exists.
   */
  if (old == nil)
    {
      old = [NSCountedSet new];
      NSMapInsert(drag_types, (void*)winNum, (void*)(gsaddr)old);
      RELEASE(old);
    }
  originalCount = [old count];

  while (i-- > 0)
    {
      id	o = [types objectAtIndex: i];

      [old addObject: o];
    }
  if ([old count] == originalCount)
    return NO;
  return YES;
}

/*
 * Remove (decrement count by 1) each drag type from those registered
 * for the window.  If this results in a change to the types registered
 * in the counted set, return YES, otherwise return NO.
 * If given 'nil' as the array of types, remove ALL.
 * Subclasses should override this method, call 'super' and take
 * appropriate action if the method returns 'YES'.
 */
- (BOOL) _removeDragTypes: (NSArray*)types fromWindow: (int)winNum
{
  NSCountedSet	*old = (NSCountedSet*)NSMapGet(drag_types, (void*)winNum);

  if (types == nil)
    {
      if (old == nil)
	return NO;
      NSMapRemove(drag_types, (void*)winNum);
      return YES;
    }
  else if (old == nil)
    {
      return NO;
    }
  else
    {
      unsigned	originalCount = [old count];
      unsigned	i = [types count];

      while (i-- > 0)
	{
	  id	o = [types objectAtIndex: i];

	  [old removeObject: o];
	}
      if ([old count] == originalCount)
	return NO;
      return YES;
    }
}

- (NSCountedSet*) _dragTypesForWindow: (int)winNum
{
  return (NSCountedSet*)NSMapGet(drag_types, (void*)winNum);
}

- (id <NSDraggingInfo>)_dragInfo
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (void) _postExternalEvent: (NSEvent *)event;
{
  [self subclassResponsibility: _cmd];
}

/*
 *	Misc window management support.
 */
- (BOOL) _setFrame: (NSRect)frameRect forWindow: (int)winNum
{
  [self subclassResponsibility: _cmd];
  return NO;
}

- (void) _orderWindow: (NSWindowOrderingMode)place
	   relativeTo: (int)otherWin
	    forWindow: (int)winNum
{
  [self subclassResponsibility: _cmd];
}

@end

@implementation NSGraphicsContext (Private)

/* Build up method table for fast access to methods. Cast to (void *) to
   avoid compiler warnings */
+ (gsMethodTable *) _initializeMethodTable
{
  gsMethodTable methodTable;
  gsMethodTable *mptr;

#define	GET_IMP(X) ((void*) [self instanceMethodForSelector: (X)])

/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPScurrentcmykcolor____ =
    GET_IMP(@selector(DPScurrentcmykcolor::::));
  methodTable.DPSsetcmykcolor____ =
    GET_IMP(@selector(DPSsetcmykcolor::::));
/* ----------------------------------------------------------------------- */
/* Data operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPSclear =
    GET_IMP(@selector(DPSclear));
  methodTable.DPScleartomark =
    GET_IMP(@selector(DPScleartomark));
  methodTable.DPScopy_ =
    GET_IMP(@selector(DPScopy:));
  methodTable.DPScount_ =
    GET_IMP(@selector(DPScount:));
  methodTable.DPScounttomark_ =
    GET_IMP(@selector(DPScounttomark:));
  methodTable.DPSdup =
    GET_IMP(@selector(DPSdup));
  methodTable.DPSexch =
    GET_IMP(@selector(DPSexch));
  methodTable.DPSexecstack =
    GET_IMP(@selector(DPSexecstack));
  methodTable.DPSget =
    GET_IMP(@selector(DPSget));
  methodTable.DPSindex_ =
    GET_IMP(@selector(DPSindex:));
  methodTable.DPSmark =
    GET_IMP(@selector(DPSmark));
  methodTable.DPSmatrix =
    GET_IMP(@selector(DPSmatrix));
  methodTable.DPSnull =
    GET_IMP(@selector(DPSnull));
  methodTable.DPSpop =
    GET_IMP(@selector(DPSpop));
  methodTable.DPSput =
    GET_IMP(@selector(DPSput));
  methodTable.DPSroll__ =
    GET_IMP(@selector(DPSroll::));
/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPSFontDirectory =
    GET_IMP(@selector(DPSFontDirectory));
  methodTable.DPSISOLatin1Encoding =
    GET_IMP(@selector(DPSISOLatin1Encoding));
  methodTable.DPSSharedFontDirectory =
    GET_IMP(@selector(DPSSharedFontDirectory));
  methodTable.DPSStandardEncoding =
    GET_IMP(@selector(DPSStandardEncoding));
  methodTable.DPScurrentcacheparams =
    GET_IMP(@selector(DPScurrentcacheparams));
  methodTable.DPScurrentfont =
    GET_IMP(@selector(DPScurrentfont));
  methodTable.DPSdefinefont =
    GET_IMP(@selector(DPSdefinefont));
  methodTable.DPSfindfont_ =
    GET_IMP(@selector(DPSfindfont:));
  methodTable.DPSmakefont =
    GET_IMP(@selector(DPSmakefont));
  methodTable.DPSscalefont_ =
    GET_IMP(@selector(DPSscalefont:));
  methodTable.DPSselectfont__ =
    GET_IMP(@selector(DPSselectfont::));
  methodTable.DPSsetfont_ =
    GET_IMP(@selector(DPSsetfont:));
  methodTable.DPSundefinefont_ =
    GET_IMP(@selector(DPSundefinefont:));
/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPSconcat_ =
    GET_IMP(@selector(DPSconcat:));
  methodTable.DPScurrentdash =
    GET_IMP(@selector(DPScurrentdash));
  methodTable.DPScurrentflat_ =
    GET_IMP(@selector(DPScurrentflat:));
  methodTable.DPScurrentgray_ =
    GET_IMP(@selector(DPScurrentgray:));
  methodTable.DPScurrentgstate_ =
    GET_IMP(@selector(DPScurrentgstate:));
  methodTable.DPScurrenthalftone =
    GET_IMP(@selector(DPScurrenthalftone));
  methodTable.DPScurrenthalftonephase__ =
    GET_IMP(@selector(DPScurrenthalftonephase::));
  methodTable.DPScurrenthsbcolor___ =
    GET_IMP(@selector(DPScurrenthsbcolor:::));
  methodTable.DPScurrentlinecap_ =
    GET_IMP(@selector(DPScurrentlinecap:));
  methodTable.DPScurrentlinejoin_ =
    GET_IMP(@selector(DPScurrentlinejoin:));
  methodTable.DPScurrentlinewidth_ =
    GET_IMP(@selector(DPScurrentlinewidth:));
  methodTable.DPScurrentmatrix =
    GET_IMP(@selector(DPScurrentmatrix));
  methodTable.DPScurrentmiterlimit_ =
    GET_IMP(@selector(DPScurrentmiterlimit:));
  methodTable.DPScurrentpoint__ =
    GET_IMP(@selector(DPScurrentpoint::));
  methodTable.DPScurrentrgbcolor___ =
    GET_IMP(@selector(DPScurrentrgbcolor:::));
  methodTable.DPScurrentscreen =
    GET_IMP(@selector(DPScurrentscreen));
  methodTable.DPScurrentstrokeadjust_ =
    GET_IMP(@selector(DPScurrentstrokeadjust:));
  methodTable.DPScurrenttransfer =
    GET_IMP(@selector(DPScurrenttransfer));
  methodTable.DPSdefaultmatrix =
    GET_IMP(@selector(DPSdefaultmatrix));
  methodTable.DPSgrestore =
    GET_IMP(@selector(DPSgrestore));
  methodTable.DPSgrestoreall =
    GET_IMP(@selector(DPSgrestoreall));
  methodTable.DPSgsave =
    GET_IMP(@selector(DPSgsave));
  methodTable.DPSgstate =
    GET_IMP(@selector(DPSgstate));
  methodTable.DPSinitgraphics =
    GET_IMP(@selector(DPSinitgraphics));
  methodTable.DPSinitmatrix =
    GET_IMP(@selector(DPSinitmatrix));
  methodTable.DPSrotate_ =
    GET_IMP(@selector(DPSrotate:));
  methodTable.DPSscale__ =
    GET_IMP(@selector(DPSscale::));
  methodTable.DPSsetdash___ =
    GET_IMP(@selector(DPSsetdash:::));
  methodTable.DPSsetflat_ =
    GET_IMP(@selector(DPSsetflat:));
  methodTable.DPSsetgray_ =
    GET_IMP(@selector(DPSsetgray:));
  methodTable.DPSsetgstate_ =
    GET_IMP(@selector(DPSsetgstate:));
  methodTable.DPSsethalftone =
    GET_IMP(@selector(DPSsethalftone));
  methodTable.DPSsethalftonephase__ =
    GET_IMP(@selector(DPSsethalftonephase::));
  methodTable.DPSsethsbcolor___ =
    GET_IMP(@selector(DPSsethsbcolor:::));
  methodTable.DPSsetlinecap_ =
    GET_IMP(@selector(DPSsetlinecap:));
  methodTable.DPSsetlinejoin_ =
    GET_IMP(@selector(DPSsetlinejoin:));
  methodTable.DPSsetlinewidth_ =
    GET_IMP(@selector(DPSsetlinewidth:));
  methodTable.DPSsetmatrix =
    GET_IMP(@selector(DPSsetmatrix));
  methodTable.DPSsetmiterlimit_ =
    GET_IMP(@selector(DPSsetmiterlimit:));
  methodTable.DPSsetrgbcolor___ =
    GET_IMP(@selector(DPSsetrgbcolor:::));
  methodTable.DPSsetscreen =
    GET_IMP(@selector(DPSsetscreen));
  methodTable.DPSsetstrokeadjust_ =
    GET_IMP(@selector(DPSsetstrokeadjust:));
  methodTable.DPSsettransfer =
    GET_IMP(@selector(DPSsettransfer));
  methodTable.DPStranslate__ =
    GET_IMP(@selector(DPStranslate::));
/* ----------------------------------------------------------------------- */
/* I/O operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPSflush =
    GET_IMP(@selector(DPSflush));
/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPSconcatmatrix =
    GET_IMP(@selector(DPSconcatmatrix));
  methodTable.DPSdtransform____ =
    GET_IMP(@selector(DPSdtransform::::));
  methodTable.DPSidentmatrix =
    GET_IMP(@selector(DPSidentmatrix));
  methodTable.DPSidtransform____ =
    GET_IMP(@selector(DPSidtransform::::));
  methodTable.DPSinvertmatrix =
    GET_IMP(@selector(DPSinvertmatrix));
  methodTable.DPSitransform____ =
    GET_IMP(@selector(DPSitransform::::));
  methodTable.DPStransform____ =
    GET_IMP(@selector(DPStransform::::));
/* ----------------------------------------------------------------------- */
/* Opstack operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPSdefineuserobject =
    GET_IMP(@selector(DPSdefineuserobject));
  methodTable.DPSexecuserobject_ =
    GET_IMP(@selector(DPSexecuserobject:));
  methodTable.DPSundefineuserobject_ =
    GET_IMP(@selector(DPSundefineuserobject:));
  methodTable.DPSgetboolean_ =
    GET_IMP(@selector(DPSgetboolean:));
  methodTable.DPSgetchararray__ =
    GET_IMP(@selector(DPSgetchararray::));
  methodTable.DPSgetfloat_ =
    GET_IMP(@selector(DPSgetfloat:));
  methodTable.DPSgetfloatarray__ =
    GET_IMP(@selector(DPSgetfloatarray::));
  methodTable.DPSgetint_ =
    GET_IMP(@selector(DPSgetint:));
  methodTable.DPSgetintarray__ =
    GET_IMP(@selector(DPSgetintarray::));
  methodTable.DPSgetstring_ =
    GET_IMP(@selector(DPSgetstring:));
  methodTable.DPSsendboolean_ =
    GET_IMP(@selector(DPSsendboolean:));
  methodTable.DPSsendchararray__ =
    GET_IMP(@selector(DPSsendchararray::));
  methodTable.DPSsendfloat_ =
    GET_IMP(@selector(DPSsendfloat:));
  methodTable.DPSsendfloatarray__ =
    GET_IMP(@selector(DPSsendfloatarray::));
  methodTable.DPSsendint_ =
    GET_IMP(@selector(DPSsendint:));
  methodTable.DPSsendintarray__ =
    GET_IMP(@selector(DPSsendintarray::));
  methodTable.DPSsendstring_ =
    GET_IMP(@selector(DPSsendstring:));
/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPSashow___ =
    GET_IMP(@selector(DPSashow:::));
  methodTable.DPSawidthshow______ =
    GET_IMP(@selector(DPSawidthshow::::::));
  methodTable.DPScopypage =
    GET_IMP(@selector(DPScopypage));
  methodTable.DPSeofill =
    GET_IMP(@selector(DPSeofill));
  methodTable.DPSerasepage =
    GET_IMP(@selector(DPSerasepage));
  methodTable.DPSfill =
    GET_IMP(@selector(DPSfill));
  methodTable.DPSimage =
    GET_IMP(@selector(DPSimage));
  methodTable.DPSimagemask =
    GET_IMP(@selector(DPSimagemask));
  methodTable.DPSkshow_ =
    GET_IMP(@selector(DPSkshow:));
  methodTable.DPSrectfill____ =
    GET_IMP(@selector(DPSrectfill::::));
  methodTable.DPSrectstroke____ =
    GET_IMP(@selector(DPSrectstroke::::));
  methodTable.DPSshow_ =
    GET_IMP(@selector(DPSshow:));
  methodTable.DPSshowpage =
    GET_IMP(@selector(DPSshowpage));
  methodTable.DPSstroke =
    GET_IMP(@selector(DPSstroke));
  methodTable.DPSstrokepath =
    GET_IMP(@selector(DPSstrokepath));
  methodTable.DPSueofill____ =
    GET_IMP(@selector(DPSueofill::::));
  methodTable.DPSufill____ =
    GET_IMP(@selector(DPSufill::::));
  methodTable.DPSustroke____ =
    GET_IMP(@selector(DPSustroke::::));
  methodTable.DPSustrokepath____ =
    GET_IMP(@selector(DPSustrokepath::::));
  methodTable.DPSwidthshow____ =
    GET_IMP(@selector(DPSwidthshow::::));
  methodTable.DPSxshow___ =
    GET_IMP(@selector(DPSxshow:::));
  methodTable.DPSxyshow___ =
    GET_IMP(@selector(DPSxyshow:::));
  methodTable.DPSyshow___ =
    GET_IMP(@selector(DPSyshow:::));
/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPSarc_____ =
    GET_IMP(@selector(DPSarc:::::));
  methodTable.DPSarcn_____ =
    GET_IMP(@selector(DPSarcn:::::));
  methodTable.DPSarct_____ =
    GET_IMP(@selector(DPSarct:::::));
  methodTable.DPSarcto_________ =
    GET_IMP(@selector(DPSarcto:::::::::));
  methodTable.DPScharpath__ =
    GET_IMP(@selector(DPScharpath::));
  methodTable.DPSclip =
    GET_IMP(@selector(DPSclip));
  methodTable.DPSclippath =
    GET_IMP(@selector(DPSclippath));
  methodTable.DPSclosepath =
    GET_IMP(@selector(DPSclosepath));
  methodTable.DPScurveto______ =
    GET_IMP(@selector(DPScurveto::::::));
  methodTable.DPSeoclip =
    GET_IMP(@selector(DPSeoclip));
  methodTable.DPSeoviewclip =
    GET_IMP(@selector(DPSeoviewclip));
  methodTable.DPSflattenpath =
    GET_IMP(@selector(DPSflattenpath));
  methodTable.DPSinitclip =
    GET_IMP(@selector(DPSinitclip));
  methodTable.DPSinitviewclip =
    GET_IMP(@selector(DPSinitviewclip));
  methodTable.DPSlineto__ =
    GET_IMP(@selector(DPSlineto::));
  methodTable.DPSmoveto__ =
    GET_IMP(@selector(DPSmoveto::));
  methodTable.DPSnewpath =
    GET_IMP(@selector(DPSnewpath));
  methodTable.DPSpathbbox____ =
    GET_IMP(@selector(DPSpathbbox::::));
  methodTable.DPSpathforall =
    GET_IMP(@selector(DPSpathforall));
  methodTable.DPSrcurveto______ =
    GET_IMP(@selector(DPSrcurveto::::::));
  methodTable.DPSrectclip____ =
    GET_IMP(@selector(DPSrectclip::::));
  methodTable.DPSrectviewclip____ =
    GET_IMP(@selector(DPSrectviewclip::::));
  methodTable.DPSreversepath =
    GET_IMP(@selector(DPSreversepath));
  methodTable.DPSrlineto__ =
    GET_IMP(@selector(DPSrlineto::));
  methodTable.DPSrmoveto__ =
    GET_IMP(@selector(DPSrmoveto::));
  methodTable.DPSsetbbox____ =
    GET_IMP(@selector(DPSsetbbox::::));
  methodTable.DPSviewclip =
    GET_IMP(@selector(DPSviewclip));
  methodTable.DPSviewclippath =
    GET_IMP(@selector(DPSviewclippath));
/* ----------------------------------------------------------------------- */
/* Window system ops */
/* ----------------------------------------------------------------------- */
  methodTable.DPScurrentdrawingfunction_ =
    GET_IMP(@selector(DPScurrentdrawingfunction:));
  methodTable.DPScurrentgcdrawable____ =
    GET_IMP(@selector(DPScurrentgcdrawable::::));
  methodTable.DPScurrentgcdrawablecolor_____ =
    GET_IMP(@selector(DPScurrentgcdrawablecolor:::::));
  methodTable.DPScurrentoffset__ =
    GET_IMP(@selector(DPScurrentoffset::));
  methodTable.DPSsetdrawingfunction_ =
    GET_IMP(@selector(DPSsetdrawingfunction:));
  methodTable.DPSsetgcdrawable____ =
    GET_IMP(@selector(DPSsetgcdrawable::::));
  methodTable.DPSsetgcdrawablecolor_____ =
    GET_IMP(@selector(DPSsetgcdrawablecolor:::::));
  methodTable.DPSsetoffset__ =
    GET_IMP(@selector(DPSsetoffset::));
  methodTable.DPSsetrgbactual____ =
    GET_IMP(@selector(DPSsetrgbactual::::));
  methodTable.DPScapturegstate_ =
    GET_IMP(@selector(DPScapturegstate:));
/*-------------------------------------------------------------------------*/
/* Graphics Extension Ops */
/*-------------------------------------------------------------------------*/
  methodTable.DPScomposite________ = 
    GET_IMP(@selector(DPScomposite::::::::));
  methodTable.DPScompositerect_____ = 
    GET_IMP(@selector(DPScompositerect:::::));
  methodTable.DPSdissolve________ = 
    GET_IMP(@selector(DPSdissolve::::::::));
  methodTable.DPSreadimage = 
    GET_IMP(@selector(DPSreadimage));
  methodTable.DPSsetalpha_ = 
    GET_IMP(@selector(DPSsetalpha:));
  methodTable.DPScurrentalpha_ = 
    GET_IMP(@selector(DPScurrentalpha:));
/*-------------------------------------------------------------------------*/
/* Window Extension Ops */
/*-------------------------------------------------------------------------*/
  methodTable.DPSwindow______ = 
    GET_IMP(@selector(DPSwindow::::::));
  methodTable.DPStermwindow_ = 
    GET_IMP(@selector(DPStermwindow:));
  methodTable.DPSstylewindow__ = 
    GET_IMP(@selector(DPSstylewindow::));
  methodTable.DPStitlewindow__ = 
    GET_IMP(@selector(DPStitlewindow::));
  methodTable.DPSminiwindow_ = 
    GET_IMP(@selector(DPSminiwindow:));
  methodTable.DPSwindowdevice_ = 
    GET_IMP(@selector(DPSwindowdevice:));
  methodTable.DPSwindowdeviceround_ = 
    GET_IMP(@selector(DPSwindowdeviceround:));
  methodTable.DPScurrentwindow_ = 
    GET_IMP(@selector(DPScurrentwindow:));
  methodTable.DPSorderwindow___ = 
    GET_IMP(@selector(DPSorderwindow:::));
  methodTable.DPSmovewindow___ = 
    GET_IMP(@selector(DPSmovewindow:::));
  methodTable.DPSupdatewindow_ = 
    GET_IMP(@selector(DPSupdatewindow:));
  methodTable.DPSplacewindow_____ = 
    GET_IMP(@selector(DPSplacewindow:::::));
  methodTable.DPSfrontwindow_ = 
    GET_IMP(@selector(DPSfrontwindow:));
  methodTable.DPSfindwindow________ = 
    GET_IMP(@selector(DPSfindwindow::::::::));
  methodTable.DPScurrentwindowbounds_____ = 
    GET_IMP(@selector(DPScurrentwindowbounds:::::));
  methodTable.DPSsetexposurecolor = 
    GET_IMP(@selector(DPSsetexposurecolor));
  methodTable.DPSsetsendexposed__ = 
    GET_IMP(@selector(DPSsetsendexposed::));
  methodTable.DPSsetautofill__ = 
    GET_IMP(@selector(DPSsetautofill::));
  methodTable.DPScurrentwindowalpha__ = 
    GET_IMP(@selector(DPScurrentwindowalpha::));
  methodTable.DPScountscreenlist__ = 
    GET_IMP(@selector(DPScountscreenlist::));
  methodTable.DPSscreenlist___ = 
    GET_IMP(@selector(DPSscreenlist:::));
  methodTable.DPSsetowner__ = 
    GET_IMP(@selector(DPSsetowner::));
  methodTable.DPScurrentowner__ = 
    GET_IMP(@selector(DPScurrentowner::));
  methodTable.DPSsetwindowtype__ = 
    GET_IMP(@selector(DPSsetwindowtype::));
  methodTable.DPSsetwindowlevel__ = 
    GET_IMP(@selector(DPSsetwindowlevel::));
  methodTable.DPScurrentwindowlevel__ = 
    GET_IMP(@selector(DPScurrentwindowlevel::));
  methodTable.DPScountwindowlist__ = 
    GET_IMP(@selector(DPScountwindowlist::));
  methodTable.DPSwindowlist___ = 
    GET_IMP(@selector(DPSwindowlist:::));
  methodTable.DPSsetwindowdepthlimit__ = 
    GET_IMP(@selector(DPSsetwindowdepthlimit::));
  methodTable.DPScurrentwindowdepthlimit__ = 
    GET_IMP(@selector(DPScurrentwindowdepthlimit::));
  methodTable.DPScurrentwindowdepth__ = 
    GET_IMP(@selector(DPScurrentwindowdepth::));
  methodTable.DPSsetdefaultdepthlimit_ = 
    GET_IMP(@selector(DPSsetdefaultdepthlimit:));
  methodTable.DPScurrentdefaultdepthlimit_ = 
    GET_IMP(@selector(DPScurrentdefaultdepthlimit:));
  methodTable.DPSsetmaxsize___ = 
    GET_IMP(@selector(DPSsetmaxsize:::));
  methodTable.DPSsetminsize___ = 
    GET_IMP(@selector(DPSsetminsize:::));
  methodTable.DPSsetresizeincrements___ = 
    GET_IMP(@selector(DPSsetresizeincrements:::));
  methodTable.DPSflushwindowrect_____ = 
    GET_IMP(@selector(DPSflushwindowrect:::::));
  methodTable.DPScapturemouse_ = 
    GET_IMP(@selector(DPScapturemouse:));
  methodTable.DPSreleasemouse = 
    GET_IMP(@selector(DPSreleasemouse));
  methodTable.DPSsetinputfocus_ = 
    GET_IMP(@selector(DPSsetinputfocus:));
  methodTable.DPShidecursor = 
    GET_IMP(@selector(DPShidecursor));
  methodTable.DPSshowcursor = 
    GET_IMP(@selector(DPSshowcursor));
  methodTable.DPSstandardcursor__ = 
    GET_IMP(@selector(DPSstandardcursor::));
  methodTable.DPSimagecursor_______ = 
    GET_IMP(@selector(DPSimagecursor:::::::));
  methodTable.DPSsetcursorcolor_______ = 
    GET_IMP(@selector(DPSsetcursorcolor:::::::));
/* ----------------------------------------------------------------------- */
/* GNUstep Event and other I/O extensions */
/* ----------------------------------------------------------------------- */
  methodTable.DPSGetEventMatchingMask_beforeDate_inMode_dequeue_ = 
    GET_IMP(@selector(DPSGetEventMatchingMask:beforeDate:inMode:dequeue:));
  methodTable.DPSDiscardEventsMatchingMask_beforeEvent_ = 
    GET_IMP(@selector(DPSDiscardEventsMatchingMask:beforeEvent:));
  methodTable.DPSPostEvent_atStart_ = 
    GET_IMP(@selector(DPSPostEvent:atStart:));
  methodTable.DPSmouselocation__ = 
    GET_IMP(@selector(DPSmouselocation::));

  mptr = NSZoneMalloc(_globalGSZone, sizeof(gsMethodTable));
  memcpy(mptr, &methodTable, sizeof(gsMethodTable));
  return mptr;
}

@end


/*
 *	The 'Ops' catagory contains the methods to implement all the
 *	PostScript functions.  In this abstract class, these will all
 *	raise an exception.  Concrete instances of the NSGraphicsContext
 *	class should override these methods in order to implement the
 *	PostScript functions.
 */
@implementation NSGraphicsContext (Ops)

/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */
- (void) DPScurrentcmykcolor: (float*)c : (float*)m : (float*)y : (float*)k 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetcmykcolor: (float)c : (float)m : (float)y : (float)k 
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Data operations */
/* ----------------------------------------------------------------------- */
- (void) DPSclear 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScleartomark 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScopy: (int)n 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScount: (int *)n 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScounttomark: (int *)n 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSdup 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSexch 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSexecstack 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSget 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSindex: (int)i 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSmark 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSmatrix 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSnull 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSpop 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSput 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSroll: (int)n : (int)j 
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */

- (void) DPSdefineresource: (const char *)category 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSfindresource: (const char *)key : (const char *)category 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSFontDirectory 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSISOLatin1Encoding 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSSharedFontDirectory 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSStandardEncoding 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentcacheparams 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentfont 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSdefinefont 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSfindfont: (const char *)name 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSmakefont 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSscalefont: (float)size 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSselectfont: (const char *)name : (float)scale 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetfont: (int)f 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSundefinefont: (const char *)name 
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */

- (void) DPSconcat: (const float*)m 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentdash 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentflat: (float*)flatness 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentgray: (float*)gray 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentgstate: (int)gst 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrenthalftone 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrenthalftonephase: (float*)x : (float*)y 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrenthsbcolor: (float*)h : (float*)s : (float*)b 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentlinecap: (int *)linecap 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentlinejoin: (int *)linejoin 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentlinewidth: (float*)width 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentmatrix 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentmiterlimit: (float*)limit 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentpoint: (float*)x : (float*)y 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentrgbcolor: (float*)r : (float*)g : (float*)b 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentscreen 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentstrokeadjust: (int *)b 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrenttransfer 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSdefaultmatrix 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSgrestore 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSgrestoreall 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSgsave 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSgstate 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSinitgraphics 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSinitmatrix 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSrotate: (float)angle 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSscale: (float)x : (float)y 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetdash: (const float*)pat : (int)size : (float)offset 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetflat: (float)flatness 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetgray: (float)gray 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetgstate: (int)gst 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsethalftone 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsethalftonephase: (float)x : (float)y 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsethsbcolor: (float)h : (float)s : (float)b 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetlinecap: (int)linecap 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetlinejoin: (int)linejoin 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetlinewidth: (float)width 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetmatrix 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetmiterlimit: (float)limit 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetrgbcolor: (float)r : (float)g : (float)b 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetscreen 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetstrokeadjust: (int)b 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsettransfer 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPStranslate: (float)x : (float)y 
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
- (void) DPSflush
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */

- (void) DPSconcatmatrix
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSdtransform: (float)x1 : (float)y1 : (float*)x2 : (float*)y2 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSidentmatrix 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSidtransform: (float)x1 : (float)y1 : (float*)x2 : (float*)y2 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSinvertmatrix 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSitransform: (float)x1 : (float)y1 : (float*)x2 : (float*)y2 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPStransform: (float)x1 : (float)y1 : (float*)x2 : (float*)y2 
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Opstack operations */
/* ----------------------------------------------------------------------- */

- (void)DPSdefineuserobject
{
  [self subclassResponsibility: _cmd];
}

- (void)DPSexecuserobject: (int)index
{
  [self subclassResponsibility: _cmd];
}

- (void)DPSundefineuserobject: (int)index
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSgetboolean: (int *)it 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSgetchararray: (int)size : (char *)s 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSgetfloat: (float*)it 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSgetfloatarray: (int)size : (float*)a 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSgetint: (int *)it 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSgetintarray: (int)size : (int *)a 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSgetstring: (char *)s 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsendboolean: (int)it 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsendchararray: (const char *)s : (int)size 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsendfloat: (float)it 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsendfloatarray: (const float*)a : (int)size 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsendint: (int)it 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsendintarray: (const int *)a : (int)size 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsendstring: (const char *)s 
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */

- (void) DPSashow: (float)x : (float)y : (const char *)s 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSawidthshow: (float)cx : (float)cy : (int)c : (float)ax : (float)ay : (const char *)s 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScopypage 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSeofill 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSerasepage 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSfill 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSimage 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSimagemask 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSkshow: (const char *)s 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSrectfill: (float)x : (float)y : (float)w : (float)h 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSrectstroke: (float)x : (float)y : (float)w : (float)h 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSshow: (const char *)s 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSshowpage 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSstroke 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSstrokepath 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSueofill: (const char *)nums : (int)n : (const char *)op : (int)l 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSufill: (const char *)nums : (int)n : (const char *)ops : (int)l 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSustroke: (const char *)nums   : (int)n : (const char *)ops : (int)l 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSustrokepath: (const char *)nums : (int)n : (const char *)ops : (int)l 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSwidthshow: (float)x : (float)y : (int)c : (const char *)s 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSxshow: (const char *)s : (const float*)numarray : (int)size 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSxyshow: (const char *)s : (const float*)numarray : (int)size 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSyshow: (const char *)s : (const float*)numarray : (int)size 
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */

- (void) DPSarc: (float)x : (float)y : (float)r : (float)angle1 : (float)angle2 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSarcn: (float)x : (float)y : (float)r : (float)angle1 : (float)angle2 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSarct: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)r 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSarcto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)r : (float*)xt1 : (float*)yt1 : (float*)xt2 : (float*)yt2 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScharpath: (const char *)s : (int)b 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSclip 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSclippath 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSclosepath 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurveto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)x3 : (float)y3 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSeoclip 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSeoviewclip 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSflattenpath 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSinitclip 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSinitviewclip 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSlineto: (float)x : (float)y 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSmoveto: (float)x : (float)y 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSnewpath 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSpathbbox: (float*)llx : (float*)lly : (float*)urx : (float*)ury 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSpathforall 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSrcurveto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)x3 : (float)y3 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSrectclip: (float)x : (float)y : (float)w : (float)h 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSrectviewclip: (float)x : (float)y : (float)w : (float)h 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSreversepath 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSrlineto: (float)x : (float)y 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSrmoveto: (float)x : (float)y 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetbbox: (float)llx : (float)lly : (float)urx : (float)ury 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSviewclip 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSviewclippath 
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Window system ops */
/* ----------------------------------------------------------------------- */

- (void) DPScurrentdrawingfunction: (int *)function
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentgcdrawable: (void **)gc : (void **)draw : (int *)x : (int *)y
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentgcdrawablecolor: (void **)gc : (void **)draw : (int *)x 
				  : (int *)y : (int *)colorInfo
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentoffset: (int *)x : (int *)y
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetdrawingfunction: (int) function
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetgcdrawable: (void *)gc : (void *)draw : (int)x : (int)y
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetgcdrawablecolor: (void *)gc : (void *)draw : (int)x : (int)y
				  : (const int *)colorInfo
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetoffset: (short int)x : (short int)y
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetrgbactual: (double)r : (double)g : (double)b : (int *)success
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScapturegstate: (int *)gst
{
  [self subclassResponsibility: _cmd];
}

/*-------------------------------------------------------------------------*/
/* Graphics Extension Ops */
/*-------------------------------------------------------------------------*/
- (void) DPScomposite: (float)x : (float)y : (float)w : (float)h : (int)gstateNum : (float)dx : (float)dy : (int)op
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScompositerect: (float)x : (float)y : (float)w : (float)h : (int)op
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSdissolve: (float)x : (float)y : (float)w : (float)h : (int)gstateNum
 : (float)dx : (float)dy : (float)delta
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSreadimage
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetalpha: (float)a
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentalpha: (float *)alpha
{
  [self subclassResponsibility: _cmd];
}

/*-------------------------------------------------------------------------*/
/* Window Extension Ops */
/*-------------------------------------------------------------------------*/
- (void) DPSwindow: (float) x : (float) y : (float) w : (float) h : (int) type : (int *) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPStermwindow: (int) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSstylewindow: (int) style : (int) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPStitlewindow: (const char *) window_title : (int) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSminiwindow: (int) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSwindowdevice: (int) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSwindowdeviceround: (int) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentwindow: (int *) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSorderwindow: (int) op : (int) otherWin : (int) winNum ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSmovewindow: (float) x : (float) y : (int) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSupdatewindow: (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSplacewindow: (float) x : (float) y : (float) w : (float) h : (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSfrontwindow: (int *) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSfindwindow: (float) x : (float) y : (int) op : (int) otherWin : (float *) lx : (float *) ly : (int *) winFound : (int *) didFind ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentwindowbounds: (int) num : (float *) x : (float *) y : (float *) w : (float *) h ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetexposurecolor;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetsendexposed: (int) truth : (int) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetautofill: (int) truth : (int) num ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentwindowalpha: (int) win : (int *) alpha ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScountscreenlist: (int) context : (int *) count ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSscreenlist: (int) context : (int) count : (int *) windows ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetowner: (int) owner : (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentowner: (int) win : (int *) owner ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetwindowtype: (int) type : (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetwindowlevel: (int) level : (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentwindowlevel: (int) win : (int *) level ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScountwindowlist: (int) context : (int *) count ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSwindowlist: (int) context : (int) count : (int *) windows ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetwindowdepthlimit: (int) limit : (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentwindowdepthlimit: (int) win : (int *) limit ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentwindowdepth: (int) win : (int *) depth ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetdefaultdepthlimit: (int) limit ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentdefaultdepthlimit: (int *) limit ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetmaxsize: (float) width : (float) height : (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetminsize: (float) width : (float) height : (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetresizeincrements: (float) width : (float) height : (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSflushwindowrect: (float) x : (float) y : (float) w : (float) h : (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScapturemouse: (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSreleasemouse;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetinputfocus: (int) win ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPShidecursor;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSshowcursor;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSstandardcursor: (int) style : (void **) cid ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSimagecursor: (float) hotx : (float) hoty : (float) w : (float) h : (int) colors : (const char *) image : (void **) cid ;
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetcursorcolor: (float) fr : (float) fg : (float) fb : (float) br : (float) bg : (float) bb : (void *) cid ;
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* GNUstep Event and other I/O extensions */
/* ----------------------------------------------------------------------- */
- (NSEvent*) DPSGetEventMatchingMask: (unsigned)mask
			  beforeDate: (NSDate*)limit
			      inMode: (NSString*)mode
			     dequeue: (BOOL)flag
{
  unsigned	pos = 0;	/* Position in queue scanned so far	*/
  NSRunLoop	*loop = nil;

  do
    {
      unsigned	count = [event_queue count];
      NSEvent	*event;
      unsigned	i = 0;

      if (count == 0)
	{
	  event = nil;
	}
      else if (mask == NSAnyEventMask)
	{
	  /*
	   * Special case - if the mask matches any event, we just get the
	   * first event on the queue.
	   */
	  event = [event_queue objectAtIndex: 0];
	}
      else
	{
	  event = nil;
	  /*
	   * Scan the queue from the last position we have seen, up to the end.
	   */
	  if (count > pos)
	    {
	      unsigned	end = count - pos;
	      NSRange	r = NSMakeRange(pos, end);
	      NSEvent	*events[end];

	      [event_queue getObjects: events range: r];
	      for (i = 0; i < end; i++)
		{
		  BOOL	matched = NO;

		  switch ([events[i] type])
		    {
		      case NSLeftMouseDown:
			if (mask & NSLeftMouseDownMask)
			  matched = YES;
			break;

		      case NSLeftMouseUp:
			if (mask & NSLeftMouseUpMask)
			  matched = YES;
			break;

		      case NSRightMouseDown:
			if (mask & NSRightMouseDownMask)
			  matched = YES;
			break;

		      case NSRightMouseUp:
			if (mask & NSRightMouseUpMask)
			  matched = YES;
			break;

		      case NSMouseMoved:
			if (mask & NSMouseMovedMask)
			  matched = YES;
			break;

		      case NSMouseEntered:
			if (mask & NSMouseEnteredMask)
			  matched = YES;
			break;

		      case NSMouseExited:
			if (mask & NSMouseExitedMask)
			  matched = YES;
			break;

		      case NSLeftMouseDragged:
			if (mask & NSLeftMouseDraggedMask)
			  matched = YES;
			break;

		      case NSRightMouseDragged:
			if (mask & NSRightMouseDraggedMask)
			  matched = YES;
			break;

		      case NSKeyDown:
			if (mask & NSKeyDownMask)
			  matched = YES;
			break;

		      case NSKeyUp:
			if (mask & NSKeyUpMask)
			  matched = YES;
			break;

		      case NSFlagsChanged:
			if (mask & NSFlagsChangedMask)
			  matched = YES;
			break;

		      case NSAppKitDefined:
			if (mask & NSAppKitDefinedMask)
			  matched = YES;
			break;

		      case NSSystemDefined:
			if (mask & NSSystemDefinedMask)
			  matched = YES;
			break;

		      case NSApplicationDefined:
			if (mask & NSApplicationDefinedMask)
			  matched = YES;
			break;

		      case NSPeriodic:
			if (mask & NSPeriodicMask)
			  matched = YES;
			break;

		      case NSCursorUpdate:
			if (mask & NSCursorUpdateMask)
			  matched = YES;
			break;

		      default:
			break;
		    }
		  if (matched)
		    {
		      event = events[i];
		      break;
		    }
		}
	    }
	}

      /*
       * Note the positon we have read up to.
       */
      pos += i;

      /*
       * If we found a matching event, we (depending on the flag) de-queue it.
       * We return the event RETAINED - the caller must release it.
       */
      if (event)
	{
	  RETAIN(event);
	  if (flag)
	    {
	      [event_queue removeObjectAtIndex: pos];
	    }
	  return AUTORELEASE(event);
	}
      if (loop == nil)
	loop = [NSRunLoop currentRunLoop];
    }
  while ([loop runMode: mode beforeDate: limit] == YES);

  return nil;	/* No events in specified time	*/
}

- (void) DPSDiscardEventsMatchingMask: (unsigned)mask
			  beforeEvent: (NSEvent*)limit
{
  unsigned		index = [event_queue count];

  /*
   *	If there is a range to use - remove all the matching events in it
   *    which were created before the specified event.
   */
  if (index > 0)
    {
      NSTimeInterval	when = [limit timestamp];
      NSEvent		*events[index];

      [event_queue getObjects: events];

      while (index-- > 0)
	{
	  NSEvent	*event = events[index];

	  if ([event timestamp] < when)
	    {	
	      BOOL	shouldRemove = NO;

	      if (mask == NSAnyEventMask)
		{
		  shouldRemove = YES;
		}
	      else
		{
		  switch ([event type])
		    {
		      case NSLeftMouseDown:
			if (mask & NSLeftMouseDownMask)
			  shouldRemove = YES;
			break;

		      case NSLeftMouseUp:
			if (mask & NSLeftMouseUpMask)
			  shouldRemove = YES;
			break;

		      case NSRightMouseDown:
			if (mask & NSRightMouseDownMask)
			  shouldRemove = YES;
			break;

		      case NSRightMouseUp:
			if (mask & NSRightMouseUpMask)
			  shouldRemove = YES;
			break;

		      case NSMouseMoved:
			if (mask & NSMouseMovedMask)
			  shouldRemove = YES;
			break;

		      case NSMouseEntered:
			if (mask & NSMouseEnteredMask)
			  shouldRemove = YES;
			break;

		      case NSMouseExited:
			if (mask & NSMouseExitedMask)
			  shouldRemove = YES;
			break;

		      case NSLeftMouseDragged:
			if (mask & NSLeftMouseDraggedMask)
			  shouldRemove = YES;
			break;

		      case NSRightMouseDragged:
			if (mask & NSRightMouseDraggedMask)
			  shouldRemove = YES;
			break;

		      case NSKeyDown:
			if (mask & NSKeyDownMask)
			  shouldRemove = YES;
			break;

		      case NSKeyUp:
			if (mask & NSKeyUpMask)
			  shouldRemove = YES;
			break;

		      case NSFlagsChanged:
			if (mask & NSFlagsChangedMask)
			  shouldRemove = YES;
			break;

		      case NSPeriodic:
			if (mask & NSPeriodicMask)
			  shouldRemove = YES;
			break;

		      case NSCursorUpdate:
			if (mask & NSCursorUpdateMask)
			  shouldRemove = YES;
			break;

		      default:
			break;
		    }
		}
	      if (shouldRemove)
		[event_queue removeObjectAtIndex: index];
	    }
	}
    }
}

- (void) DPSPostEvent: (NSEvent*)anEvent atStart: (BOOL)flag
{
  if (flag)
    [event_queue insertObject: anEvent atIndex: 0];
  else
    [event_queue addObject: anEvent];
}

- (void) DPSmouselocation: (float*)x : (float*)y 
{
  [self subclassResponsibility: _cmd];
}
@end
