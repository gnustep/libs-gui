/** <title>NSGraphicsContext</title>

   <abstract>GNUstep drawing context class.</abstract>

   Copyright (C) 1998 Free Software Foundation, Inc.

   Written by: Adam Fedor <fedor@gnu.org>
   Date: Nov 1998
   Updated by: Richard Frith-Macdonald <richard@brainstorm.co.uk>
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
   

#include <Foundation/NSGeometry.h> 
#include <Foundation/NSString.h> 
#include <Foundation/NSArray.h> 
#include <Foundation/NSValue.h> 
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSData.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSZone.h>
#include "AppKit/AppKitExceptions.h"
#include "AppKit/NSGraphicsContext.h"
#include "AppKit/NSAffineTransform.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSView.h"
#include "AppKit/DPSOperators.h"

/* The memory zone where all global objects are allocated from (Contexts
   are also allocated from this zone) */
static NSZone *_globalGSZone = NULL;

/* The current concrete class */
static Class defaultNSGraphicsContextClass = NULL;

/* Class variable for holding pointers to method functions */
static NSMutableDictionary *classMethodTable;

/* Lock for use when creating contexts */
static NSRecursiveLock  *contextLock = nil;

#ifndef GNUSTEP_BASE_LIBRARY
static NSString	*NSGraphicsContextThreadKey = @"NSGraphicsContextThreadKey";
#endif
static NSString	*NSGraphicsContextStackKey = @"NSGraphicsContextStackKey";

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

/**
  <unit>
  <heading>NSGraphicsContext</heading>

  <p>This is an abstract class which provides a framework for a device
  independant drawing. 
  </p>
  
  <p>In addition, this class provides methods to perform the actual
  drawing. As a convenience, you can also access these through various
  function interfaces. One is a Display Postscript interface using PS
  and DPS operations. Another is a Quartz interface (not yet written).
  </p>

  </unit> */
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
	  classMethodTable =
	    [[NSMutableDictionary allocWithZone: _globalGSZone] init];
	}
      [gnustep_global_lock unlock];
    }
}

+ (void) initializeBackend
{
  [self subclassResponsibility: _cmd];
}

/** Set the concrete subclass that will provide the device dependant
    implementation.
*/
+ (void) setDefaultContextClass: (Class)defaultContextClass
{
  defaultNSGraphicsContextClass = defaultContextClass;
}

/** Set the current context that will handle drawing. */
+ (void) setCurrentContext: (NSGraphicsContext *)context
{
#ifdef GNUSTEP_BASE_LIBRARY
/*
 *	gstep-base has a faster mechanism to get the current thread.
 */
  NSThread *th = GSCurrentThread();

  ASSIGN(th->_gcontext, context);
#else
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];

  [dict setObject: context forKey: NSGraphicsContextThreadKey];
#endif
}

/** Returns the current context. Also see the convienience function
    GSCurrentContext() */
+ (NSGraphicsContext *) currentContext
{
  return GSCurrentContext();
}

/** Returns YES if the current context is a display context */
+ (BOOL) currentContextDrawingToScreen
{
  return [GSCurrentContext() isDrawingToScreen];
}

/** 
    <p>Create a graphics context with attributes, which contains key/value
    pairs which describe the specifics of how the context is to
    be initialized. 
    </p>
    */
+ (NSGraphicsContext *) graphicsContextWithAttributes: (NSDictionary *)attributes
{
  NSGraphicsContext *ctxt;
  if (self == [NSGraphicsContext class])
    {
      NSAssert(defaultNSGraphicsContextClass, 
	       @"Internal Error: No default NSGraphicsContext set\n");
      ctxt = [[defaultNSGraphicsContextClass allocWithZone: _globalGSZone]
	       initWithContextInfo: attributes];
    }
  else
    ctxt = [[self allocWithZone: _globalGSZone] initWithContextInfo: attributes];
 
  return AUTORELEASE(ctxt);
}

/**
   Create graphics context with attributes speficied by aWindow's
   device description. */
+ (NSGraphicsContext *) graphicsContextWithWindow: (NSWindow *)aWindow
{
  return [self graphicsContextWithAttributes: [aWindow deviceDescription]];
}

+ (void) restoreGraphicsState
{
  NSGraphicsContext *ctxt;
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
  NSMutableArray *stack = [dict objectForKey: NSGraphicsContextStackKey];
  if (stack == nil || [stack count] == 0)
    {
      [NSException raise: NSGenericException
		   format: @"restoreGraphicsState without previous save"];
    }
  ctxt = [stack lastObject];
  [NSGraphicsContext setCurrentContext: ctxt];
  [stack removeLastObject];
  [ctxt restoreGraphicsState];
}

+ (void) saveGraphicsState
{
  NSGraphicsContext *ctxt;
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
  NSMutableArray *stack = [dict objectForKey: NSGraphicsContextStackKey];
  if (stack == nil)
    {
      stack = [[NSMutableArray allocWithZone: _globalGSZone] init];
      [dict setObject: stack forKey: NSGraphicsContextStackKey];
    }
  ctxt = GSCurrentContext();
  [ctxt saveGraphicsState];
  [stack addObject: ctxt];
}

+ (void) setGraphicsState: (int)graphicsState
{
  /* FIXME: Need to keep a table of which context goes with a graphicState,
     or perhaps we could rely on the backend? */
  [self notImplemented: _cmd];
}

- (void) dealloc
{
  DESTROY(focus_stack);
  DESTROY(context_data);
  DESTROY(context_info);
  [super dealloc];
}

- (id) init
{
  return [self initWithContextInfo: NULL];
}

/* designated initializer for the NSGraphicsContext class */
- (id) initWithContextInfo: (NSDictionary *)info
{
  [super init];

  ASSIGN(context_info, info);
  focus_stack = [[NSMutableArray allocWithZone: [self zone]]
			initWithCapacity: 1];
  usedFonts = nil;

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
  [contextLock unlock];

  return self;
}

- (NSDictionary *) attributes
{
  return context_info;
}

- (void)flushGraphics
{
  [self subclassResponsibility: _cmd];
}

- (void *)graphicsPort
{
  return NULL;
}

- (BOOL) isDrawingToScreen
{
  return NO;
}

- (void) restoreGraphicsState
{
  [self DPSgrestore];
}

- (void) saveGraphicsState
{
  [self DPSgsave];
}

- (void *) focusStack
{
  return focus_stack;
}

- (void) setFocusStack: (void *)stack
{
  ASSIGN(focus_stack, stack);
}

- (void) setImageInterpolation: (NSImageInterpolation)interpolation
{
  _interp = interpolation;
}

- (NSImageInterpolation) imageInterpolation
{
  return _interp;
}

- (void) setShouldAntialias: (BOOL)antialias
{
  _antialias = antialias;
}

- (BOOL) shouldAntialias
{
  return _antialias;
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

- (void) useFont: (NSString*)name
{
  if ([self isDrawingToScreen] == YES)
    return;

  if (usedFonts == nil)
    usedFonts = RETAIN([NSMutableSet setWithCapacity: 2]);

  [usedFonts addObject: name];
}

- (void) resetUsedFonts
{
  if (usedFonts)
    [usedFonts removeAllObjects];
}

- (NSSet *) usedFonts
{
  return usedFonts;
}

/* Private backend methods */
- (void) contextDevice: (int)num
{
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
  methodTable.DPScurrentalpha_ =
    GET_IMP(@selector(DPScurrentalpha:));
  methodTable.DPScurrentcmykcolor____ =
    GET_IMP(@selector(DPScurrentcmykcolor::::));
  methodTable.DPScurrentgray_ =
    GET_IMP(@selector(DPScurrentgray:));
  methodTable.DPScurrenthsbcolor___ =
    GET_IMP(@selector(DPScurrenthsbcolor:::));
  methodTable.DPScurrentrgbcolor___ =
    GET_IMP(@selector(DPScurrentrgbcolor:::));
  methodTable.DPSsetalpha_ =
    GET_IMP(@selector(DPSsetalpha:));
  methodTable.DPSsetcmykcolor____ =
    GET_IMP(@selector(DPSsetcmykcolor::::));
  methodTable.DPSsetgray_ =
    GET_IMP(@selector(DPSsetgray:));
  methodTable.DPSsethsbcolor___ =
    GET_IMP(@selector(DPSsethsbcolor:::));
  methodTable.DPSsetrgbcolor___ =
    GET_IMP(@selector(DPSsetrgbcolor:::));

  methodTable.GSSetFillColorspace_ =
    GET_IMP(@selector(GSSetFillColorspace:));
  methodTable.GSSetStrokeColorspace_ =
    GET_IMP(@selector(GSSetStrokeColorspace:));
  methodTable.GSSetFillColor_ =
    GET_IMP(@selector(GSSetFillColor:));
  methodTable.GSSetStrokeColor_ =
    GET_IMP(@selector(GSSetStrokeColor:));

/* ----------------------------------------------------------------------- */
/* Text operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPSashow___ =
    GET_IMP(@selector(DPSashow:::));
  methodTable.DPSawidthshow______ =
    GET_IMP(@selector(DPSawidthshow::::::));
  methodTable.DPScharpath__ =
    GET_IMP(@selector(DPScharpath::));
  methodTable.DPSshow_ =
    GET_IMP(@selector(DPSshow:));
  methodTable.DPSwidthshow____ =
    GET_IMP(@selector(DPSwidthshow::::));
  methodTable.DPSxshow___ =
    GET_IMP(@selector(DPSxshow:::));
  methodTable.DPSxyshow___ =
    GET_IMP(@selector(DPSxyshow:::));
  methodTable.DPSyshow___ =
    GET_IMP(@selector(DPSyshow:::));

  methodTable.GSSetCharacterSpacing_ =
    GET_IMP(@selector(GSSetCharacterSpacing:));
  methodTable.GSSetFont_ =
    GET_IMP(@selector(GSSetFont:));
  methodTable.GSSetFontSize_ =
    GET_IMP(@selector(GSSetFontSize:));
  methodTable.GSGetTextCTM =
    GET_IMP(@selector(GSGetTextCTM));
  methodTable.GSGetTextPosition =
    GET_IMP(@selector(GSGetTextPosition));
  methodTable.GSSetTextCTM_ =
    GET_IMP(@selector(GSSetTextCTM:));
  methodTable.GSSetTextDrawingMode_ =
    GET_IMP(@selector(GSSetTextDrawingMode:));
  methodTable.GSSetTextPosition_ =
    GET_IMP(@selector(GSSetTextPosition:));
  methodTable.GSShowText__ =
    GET_IMP(@selector(GSShowText::));
  methodTable.GSShowGlyphs__ =
    GET_IMP(@selector(GSShowGlyphs::));

/* ----------------------------------------------------------------------- */
/* Gstate Handling */
/* ----------------------------------------------------------------------- */
  methodTable.DPSgrestore =
    GET_IMP(@selector(DPSgrestore));
  methodTable.DPSgsave =
    GET_IMP(@selector(DPSgsave));
  methodTable.DPSinitgraphics =
    GET_IMP(@selector(DPSinitgraphics));
  methodTable.DPSsetgstate_ =
    GET_IMP(@selector(DPSsetgstate:));

  methodTable.GSDefineGState =
    GET_IMP(@selector(GSDefineGState));
  methodTable.GSUndefineGState_ =
    GET_IMP(@selector(GSUndefineGState:));
  methodTable.GSReplaceGState_ =
    GET_IMP(@selector(GSReplaceGState:));

/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPScurrentflat_ =
    GET_IMP(@selector(DPScurrentflat:));
  methodTable.DPScurrentlinecap_ =
    GET_IMP(@selector(DPScurrentlinecap:));
  methodTable.DPScurrentlinejoin_ =
    GET_IMP(@selector(DPScurrentlinejoin:));
  methodTable.DPScurrentlinewidth_ =
    GET_IMP(@selector(DPScurrentlinewidth:));
  methodTable.DPScurrentmiterlimit_ =
    GET_IMP(@selector(DPScurrentmiterlimit:));
  methodTable.DPScurrentpoint__ =
    GET_IMP(@selector(DPScurrentpoint::));
  methodTable.DPScurrentstrokeadjust_ =
    GET_IMP(@selector(DPScurrentstrokeadjust:));
  methodTable.DPSsetdash___ =
    GET_IMP(@selector(DPSsetdash:::));
  methodTable.DPSsetflat_ =
    GET_IMP(@selector(DPSsetflat:));
  methodTable.DPSsethalftonephase__ =
    GET_IMP(@selector(DPSsethalftonephase::));
  methodTable.DPSsetlinecap_ =
    GET_IMP(@selector(DPSsetlinecap:));
  methodTable.DPSsetlinejoin_ =
    GET_IMP(@selector(DPSsetlinejoin:));
  methodTable.DPSsetlinewidth_ =
    GET_IMP(@selector(DPSsetlinewidth:));
  methodTable.DPSsetmiterlimit_ =
    GET_IMP(@selector(DPSsetmiterlimit:));
  methodTable.DPSsetstrokeadjust_ =
    GET_IMP(@selector(DPSsetstrokeadjust:));

/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPSconcat_ =
    GET_IMP(@selector(DPSconcat:));
  methodTable.DPSinitmatrix =
    GET_IMP(@selector(DPSinitmatrix));
  methodTable.DPSrotate_ =
    GET_IMP(@selector(DPSrotate:));
  methodTable.DPSscale__ =
    GET_IMP(@selector(DPSscale::));
  methodTable.DPStranslate__ =
    GET_IMP(@selector(DPStranslate::));

  methodTable.GSCurrentCTM =
    GET_IMP(@selector(GSCurrentCTM));
  methodTable.GSSetCTM_ =
    GET_IMP(@selector(GSSetCTM:));
  methodTable.GSConcatCTM_ =
    GET_IMP(@selector(GSConcatCTM:));

/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */
  methodTable.DPSarc_____ =
    GET_IMP(@selector(DPSarc:::::));
  methodTable.DPSarcn_____ =
    GET_IMP(@selector(DPSarcn:::::));
  methodTable.DPSarct_____ =
    GET_IMP(@selector(DPSarct:::::));
  methodTable.DPSclip =
    GET_IMP(@selector(DPSclip));
  methodTable.DPSclosepath =
    GET_IMP(@selector(DPSclosepath));
  methodTable.DPScurveto______ =
    GET_IMP(@selector(DPScurveto::::::));
  methodTable.DPSeoclip =
    GET_IMP(@selector(DPSeoclip));
  methodTable.DPSeofill =
    GET_IMP(@selector(DPSeofill));
  methodTable.DPSfill =
    GET_IMP(@selector(DPSfill));
  methodTable.DPSflattenpath =
    GET_IMP(@selector(DPSflattenpath));
  methodTable.DPSinitclip =
    GET_IMP(@selector(DPSinitclip));
  methodTable.DPSlineto__ =
    GET_IMP(@selector(DPSlineto::));
  methodTable.DPSmoveto__ =
    GET_IMP(@selector(DPSmoveto::));
  methodTable.DPSnewpath =
    GET_IMP(@selector(DPSnewpath));
  methodTable.DPSpathbbox____ =
    GET_IMP(@selector(DPSpathbbox::::));
  methodTable.DPSrcurveto______ =
    GET_IMP(@selector(DPSrcurveto::::::));
  methodTable.DPSrectclip____ =
    GET_IMP(@selector(DPSrectclip::::));
  methodTable.DPSrectfill____ =
    GET_IMP(@selector(DPSrectfill::::));
  methodTable.DPSrectstroke____ =
    GET_IMP(@selector(DPSrectstroke::::));
  methodTable.DPSreversepath =
    GET_IMP(@selector(DPSreversepath));
  methodTable.DPSrlineto__ =
    GET_IMP(@selector(DPSrlineto::));
  methodTable.DPSrmoveto__ =
    GET_IMP(@selector(DPSrmoveto::));
  methodTable.DPSstroke =
    GET_IMP(@selector(DPSstroke));

  methodTable.GSSendBezierPath_ =
    GET_IMP(@selector(GSSendBezierPath:));
  methodTable.GSRectClipList__ =
    GET_IMP(@selector(GSRectClipList::));
  methodTable.GSRectFillList__ =
    GET_IMP(@selector(GSRectFillList::));

/* ----------------------------------------------------------------------- */
/* Window system ops */
/* ----------------------------------------------------------------------- */
  methodTable.DPScurrentgcdrawable____ =
    GET_IMP(@selector(DPScurrentgcdrawable::::));
  methodTable.DPScurrentoffset__ =
    GET_IMP(@selector(DPScurrentoffset::));
  methodTable.DPSsetgcdrawable____ =
    GET_IMP(@selector(DPSsetgcdrawable::::));
  methodTable.DPSsetoffset__ =
    GET_IMP(@selector(DPSsetoffset::));

/*-------------------------------------------------------------------------*/
/* Graphics Extensions Ops */
/*-------------------------------------------------------------------------*/
  methodTable.DPScomposite________ =
    GET_IMP(@selector(DPScomposite::::::::));
  methodTable.DPScompositerect_____ =
    GET_IMP(@selector(DPScompositerect:::::));
  methodTable.DPSdissolve________ =
    GET_IMP(@selector(DPSdissolve::::::::));

  methodTable.GSDrawImage__ =
    GET_IMP(@selector(GSDrawImage::));

/* ----------------------------------------------------------------------- */
/* Postscript Client functions */
/* ----------------------------------------------------------------------- */
  methodTable.DPSPrintf__ =
    GET_IMP(@selector(DPSPrintf::));
  methodTable.DPSWriteData__ =
    GET_IMP(@selector(DPSWriteData::));

/* ----------------------------------------------------------------------- */
/* NSGraphics Ops */	
/* ----------------------------------------------------------------------- */
  methodTable.NSReadPixel_ =
    GET_IMP(@selector(NSReadPixel:));

  methodTable.NSBeep =
    GET_IMP(@selector(NSBeep));

/* Context helper wraps */
  methodTable.GSWSetViewIsFlipped_ =
    GET_IMP(@selector(GSWSetViewIsFlipped:));
  methodTable.GSWViewIsFlipped =
    GET_IMP(@selector(GSWViewIsFlipped));

/*
 * Render Bitmap Images
 */
  methodTable.NSDrawBitmap___________ = 
    GET_IMP(@selector(NSDrawBitmap:::::::::::));

  mptr = NSZoneMalloc(_globalGSZone, sizeof(gsMethodTable));
  memcpy(mptr, &methodTable, sizeof(gsMethodTable));
  return mptr;
}

- (id) subclassResponsibility: (SEL)aSel
{
  [NSException raise: GSWindowServerInternalException
    format: @"subclass %s(%s) should override %s", 
	       object_get_class_name(self),
	       GSObjCIsInstance(self) ? "instance" : "class",
	       sel_get_name(aSel)];
  return nil;
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
/** Returns the current alpha component */
- (void) DPScurrentalpha: (float *)a
{
  [self subclassResponsibility: _cmd];
}

/** Returns the current color according to the CMYK color model */
- (void) DPScurrentcmykcolor: (float*)c : (float*)m : (float*)y : (float*)k 
{
  [self subclassResponsibility: _cmd];
}

/** Returns the gray-level equivalent in the current color space. The
    value may depend on the current color space and may be 0 if the
    current color space has no notion of a gray value */
- (void) DPScurrentgray: (float*)gray 
{
  [self subclassResponsibility: _cmd];
}

/** Returns the current color according to the HSB color model. */
- (void) DPScurrenthsbcolor: (float*)h : (float*)s : (float*)b 
{
  [self subclassResponsibility: _cmd];
}

/** Returns the current color according to the RGB color model */
- (void) DPScurrentrgbcolor: (float*)r : (float*)g : (float*)b 
{
  [self subclassResponsibility: _cmd];
}

/** Sets the alpha drawing component. For this and other color setting
    commands that have no differentiation between fill and stroke colors,
    both the fill and stroke alpha are set. */
- (void) DPSsetalpha: (float)a
{
  [self subclassResponsibility: _cmd];
}

/** Sets the current colorspace to Device CMYK and the current color
    based on the indicated values. For this and other color setting
    commands that have no differentiation between fill and stroke colors,
    both the fill and stroke colors are set. */
- (void) DPSsetcmykcolor: (float)c : (float)m : (float)y : (float)k 
{
  [self subclassResponsibility: _cmd];
}

/** Sets the current colorspace to Device Gray and the current gray value */
- (void) DPSsetgray: (float)gray 
{
  [self subclassResponsibility: _cmd];
}

/** Sets the current colorspace to Device RGB and the current color based on 
   the indicated values */
- (void) DPSsethsbcolor: (float)h : (float)s : (float)b 
{
  [self subclassResponsibility: _cmd];
}

/** Sets the current colorspace to Device RGB and the current color based on 
   the indicated values */
- (void) DPSsetrgbcolor: (float)r : (float)g : (float)b 
{
  [self subclassResponsibility: _cmd];
}

/**
   <p>Sets the colorspace for fill operations based on values in the supplied
   dictionary dict.</p>
   <p>For device colorspaces (GSDeviceGray, GSDeviceRGB,
   GSDeviceCMYK), only the name of the colorspace needs to be set
   using the GSColorSpaceName key.</p>
   <p>Other colorspaces will be documented later</p>
*/
- (void) GSSetFillColorspace: (NSDictionary *)dict
{
  [self subclassResponsibility: _cmd];
}

/** Sets the colorspace for stroke operations based on the values in
    the supplied dictionary. See -GSSetFillColorspace: for a
    description of the values that need to be supplied */
- (void) GSSetStrokeColorspace: (NSDictionary *)dict
{
  [self subclassResponsibility: _cmd];
}

/** Sets the current color for fill operations. The values array
    should have n components, where n corresponds to the number of
    color components required to specify the color in the current
    colorspace. */
- (void) GSSetFillColor: (float *)values
{
  [self subclassResponsibility: _cmd];
}

/** Sets the current color for fill operations. The values array
    should have n components, where n corresponds to the number of
    color components required to specify the color in the current
    colorspace. */
- (void) GSSetStrokeColor: (float *)values
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Text operations */
/* ----------------------------------------------------------------------- */
- (void) DPSashow: (float)x : (float)y : (const char *)s 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSawidthshow: (float)cx : (float)cy : (int)c : (float)ax : (float)ay : (const char *)s 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScharpath: (const char *)s : (int)b 
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSshow: (const char *)s 
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

- (void) GSSetCharacterSpacing: (float)extra
{
  [self subclassResponsibility: _cmd];
}

- (void) GSSetFont: (NSFont*)font
{
  [self subclassResponsibility: _cmd];
}

- (void) GSSetFontSize: (float)size
{
  [self subclassResponsibility: _cmd];
}

- (NSAffineTransform *) GSGetTextCTM
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (NSPoint) GSGetTextPosition
{
  [self subclassResponsibility: _cmd];
  return NSMakePoint(0,0);
}

- (void) GSSetTextCTM: (NSAffineTransform *)ctm
{
  [self subclassResponsibility: _cmd];
}

- (void) GSSetTextDrawingMode: (GSTextDrawingMode)mode
{
  [self subclassResponsibility: _cmd];
}

- (void) GSSetTextPosition: (NSPoint)loc
{
  [self subclassResponsibility: _cmd];
}

- (void) GSShowText: (const char *)string : (size_t) length
{
  [self subclassResponsibility: _cmd];
}

- (void) GSShowGlyphs: (const NSGlyph *)glyphs : (size_t) length
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Gstate Handling */
/* ----------------------------------------------------------------------- */

/** Pops a previously saved gstate from the gstate stack and makes it
    current. Drawing information in the previously saved gstate
    becomes the current information */
- (void) DPSgrestore
{
  [self subclassResponsibility: _cmd];
}

/** Saves (pushes) a copy of the current gstate information onto the
    gstate stack. This saves drawing information contained in the
    gstate, such as the current path, ctm and colors. */
- (void) DPSgsave
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSinitgraphics
{
  [self subclassResponsibility: _cmd];
}

/** Makes the gstate indicated by the tag gst the current gstate. Note
    that the gstate is copied, so that changes to either gstate do not
    affect the other. */
- (void) DPSsetgstate: (int)gst
{
  [self subclassResponsibility: _cmd];
}

/** Creates a copy of the current gstate and associates it with a tag,
    which is given in the return value. This tag can later be used in
    -DPSsetgstate: to set the gstate as being current again. */
- (int)  GSDefineGState
{
  [self subclassResponsibility: _cmd];
  return 0;
}

/** Disassociates the tag gst with it's gstate and destroys the gstate
    object. The tag will no longer be valid and should not be used to
    refer to the gstate again. */
- (void) GSUndefineGState: (int)gst
{
  [self subclassResponsibility: _cmd];
}

/** Replaces the gstate refered to by the tag gst with the current
    gstate. The former gstate is destroyed. */
- (void) GSReplaceGState: (int)gst
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */
- (void) DPScurrentflat: (float*)flatness
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentlinecap: (int*)linecap
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentlinejoin: (int*)linejoin
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentlinewidth: (float*)width
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

- (void) DPScurrentstrokeadjust: (int*)b
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

- (void) DPSsethalftonephase: (float)x : (float)y
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

- (void) DPSsetmiterlimit: (float)limit
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetstrokeadjust: (int)b
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
- (void) DPSconcat: (const float*)m
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

- (void) DPStranslate: (float)x : (float)y
{
  [self subclassResponsibility: _cmd];
}

- (NSAffineTransform *) GSCurrentCTM
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (void) GSSetCTM: (NSAffineTransform *)ctm
{
  [self subclassResponsibility: _cmd];
}

- (void) GSConcatCTM: (NSAffineTransform *)ctm
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */
- (void) DPSarc: (float)x : (float)y : (float)r : (float)angle1 
	       : (float)angle2
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSarcn: (float)x : (float)y : (float)r : (float)angle1 
		: (float)angle2
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSarct: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)r
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSclip
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSclosepath
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurveto: (float)x1 : (float)y1 : (float)x2 : (float)y2 
		   : (float)x3 : (float)y3
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSeoclip
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSeofill
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSfill
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

- (void) DPSrcurveto: (float)x1 : (float)y1 : (float)x2 : (float)y2 
		    : (float)x3 : (float)y3
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSrectclip: (float)x : (float)y : (float)w : (float)h
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

- (void) DPSstroke
{
  [self subclassResponsibility: _cmd];
}

- (void) GSSendBezierPath: (NSBezierPath *)path
{
  [self subclassResponsibility: _cmd];
}

- (void) GSRectClipList: (const NSRect *)rects : (int) count
{
  [self subclassResponsibility: _cmd];
}

- (void) GSRectFillList: (const NSRect *)rects : (int) count
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Window system ops */
/* ----------------------------------------------------------------------- */
- (void) DPScurrentgcdrawable: (void **)gc : (void **)draw : (int *)x : (int *)y
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScurrentoffset: (int *)x : (int *)y
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetgcdrawable: (void *)gc : (void *)draw : (int)x : (int)y
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSsetoffset: (short int)x : (short int)y
{
  [self subclassResponsibility: _cmd];
}

/*-------------------------------------------------------------------------*/
/* Graphics Extension Ops */
/*-------------------------------------------------------------------------*/
- (void) DPScomposite: (float)x : (float)y : (float)w : (float)h 
		     : (int)gstateNum : (float)dx : (float)dy : (int)op
{
  [self subclassResponsibility: _cmd];
}

- (void) DPScompositerect: (float)x : (float)y : (float)w : (float)h : (int)op
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSdissolve: (float)x : (float)y : (float)w : (float)h 
		    : (int)gstateNum : (float)dx : (float)dy : (float)delta
{
  [self subclassResponsibility: _cmd];
}

- (void) GSDrawImage: (NSRect) rect: (void *) imageref
{
  [self subclassResponsibility: _cmd];
}

/* ----------------------------------------------------------------------- */
/* Client functions */
/* ----------------------------------------------------------------------- */
- (void) DPSPrintf: (char *)fmt : (va_list)args
{
  [self subclassResponsibility: _cmd];
}

- (void) DPSWriteData: (char *)buf : (unsigned int)count
{
  [self subclassResponsibility: _cmd];
}

@end

/* ----------------------------------------------------------------------- */
/* NSGraphics Ops */	
/* ----------------------------------------------------------------------- */
@implementation NSGraphicsContext (NSGraphics)
/*
 * Read the Color at a Screen Position
 */
- (NSColor *) NSReadPixel: (NSPoint) location
{
  [self subclassResponsibility: _cmd];
  return nil;
}

/*
 * Render Bitmap Images
 */
- (void) NSDrawBitmap: (NSRect) rect : (int) pixelsWide : (int) pixelsHigh
		     : (int) bitsPerSample : (int) samplesPerPixel 
		     : (int) bitsPerPixel : (int) bytesPerRow : (BOOL) isPlanar
		     : (BOOL) hasAlpha : (NSString *) colorSpaceName
		     : (const unsigned char *const [5]) data
{
  [self subclassResponsibility: _cmd];
}

/*
 * Play the System Beep
 */
- (void) NSBeep
{
  [self subclassResponsibility: _cmd];
}

- (void) GSWSetViewIsFlipped: (BOOL) flipped
{
}

- (BOOL) GSWViewIsFlipped
{
  return [[self focusView] isFlipped];
}

@end
