/* 
   GSContext.m

   Abstract superclass for all types of Contexts (drawing destinations).  

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@gnu.org>
   Date: Nov 1998
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Nov 1998
   
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

#include <gnustep/gui/config.h>

#include <Foundation/NSString.h> 
#include <Foundation/NSArray.h> 
#include <Foundation/NSValue.h> 
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSData.h>
#include <Foundation/NSZone.h>
#include <Foundation/NSUserDefaults.h>

#include "AppKit/GSContext.h"

NSZone *_globalGSZone = NULL;					// The memory zone where all 
												// global objects are allocated 
												// from (Contexts are also 
												// allocated from this zone)
//
//  Class variables
//
static Class _concreteClass;					// actual class of GSContext
static NSMutableArray *contextList;				// list of drawing destinations
static BOOL _gnustepBackendInitialized = NO;

extern GSContext *_currentGSContext;

/* Class variable for holding pointers to method functions */
static NSMutableDictionary *classMethodTable;

static NSString *knownBackends[] = {
  @"XGContext",
  @"XRContext",
  nil
};

@interface GSContext (Backend)
+ (void) _initializeGUIBackend;
@end

@interface GSContext (Private)
+ (gsMethodTable *) _initializeMethodTable;
@end

@implementation GSContext 

//
// Class methods
//
+ (void)initialize
{
	if (self == (_concreteClass = [GSContext class]))
		{
        _globalGSZone = NSDefaultMallocZone();
        contextList = [[NSMutableArray allocWithZone: _globalGSZone] init];
        classMethodTable = 
          [[NSMutableDictionary allocWithZone: _globalGSZone] init];
		NSDebugLog(@"Initialize GSContext class\n");
		[self setVersion:1];								// Initial version
		}
}

+ (void) initializeGUIBackend
{
  NSString *backend;

  if (_gnustepBackendInitialized)
    {
      NSLog(@"Invalid initialization: Backend already initialized\n");
      return;
    }
  backend = [[NSUserDefaults standardUserDefaults] 
              stringForKey: NSBackendContext];
  if (backend)
    _concreteClass = NSClassFromString(backend);
  if (!_concreteClass || _concreteClass == [GSContext class])
    {
      /* No backend class set, or class not found */
      int i = 0;
      _concreteClass = Nil;
      while (knownBackends[i])
        if ((_concreteClass = NSClassFromString(knownBackends[i++])))
          break;
    }

  if (!_concreteClass)
    {
      NSLog(@"Invalid initialization: No backend found\n");
      return;
    }

  [_concreteClass _initializeGUIBackend];
}

+ (void) setConcreteClass: (Class)c		{ _concreteClass = c; }
+ (Class) concreteClass					{ return _concreteClass; }

+ allocWithZone: (NSZone*)z
{
	return NSAllocateObject(_concreteClass, 0, z);
}

+ contextWithInfo: (NSDictionary *)info;
{
GSContext *context;

	NSAssert(_concreteClass, @"Error: No concrete GSContext is set\n");
	context = [[_concreteClass allocWithZone: _globalGSZone] 
							   initWithContextInfo: info];
	[context autorelease];

	return context;
}

+ (GSContext *) currentContext			{ return _currentGSContext;}

+ (void) setCurrentContext: (GSContext *)context
{
  _currentGSContext = context;
}

+ (void) destroyContext:(GSContext *) context		
{													// if concrete class is not 
	if(_concreteClass != [GSContext class])			// a GSContext invoke it's 
		[_concreteClass destroyContext: context];	// version of method first
	else
		[self _destroyContext: context];			
}													
													// private method which
+ (void) _destroyContext:(GSContext *) context		// removes context from the
{													// list so that it gets
int top;											// deallocated with the
													// next autorelease pool
	[contextList removeObject: context];			 
													// if not last context set 
	if((top = [contextList count]) > 0)				// next in list as current
		[_concreteClass setCurrentContext:[contextList objectAtIndex:top - 1]];
}													

//
// Instance methods
//
- init							
{ 
	return [self initWithContextInfo: nil]; 
}

- initWithContextInfo: (NSDictionary *)info
{													// designated initializer 	
	[super init];									// for GSContext class

	[contextList addObject: self];
	[_concreteClass setCurrentContext: self];
    if (!(methods = [[classMethodTable objectForKey: [self class]] pointerValue]))
      {
        methods = [[self class] _initializeMethodTable];
        [classMethodTable setObject: [NSValue valueWithPointer: methods]
                          forKey: [self class]];
      }
 
	if(info)
		context_info = [info retain];

	return self;
}

- (BOOL)isDrawingToScreen				{ return NO; }
- (NSMutableData *)mutableData			{ return context_data; }

- (void) destroy									// remove self from context
{													// list so that self gets  
	[_concreteClass destroyContext: self];			// deallocated with the  
}													// next autorelease pool
   
- (void) dealloc
{
	DESTROY(context_data);

	[super dealloc];
}

@end

@implementation GSContext (Private)

/* Build up method table for fast access to methods. Cast to (void *) to
   avoid compiler warnings */
+ (gsMethodTable *) _initializeMethodTable
{
  gsMethodTable methodTable;
  gsMethodTable *mptr;

/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */
      methodTable.DPScurrentcmykcolor____ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentcmykcolor::::)];
      methodTable.DPSsetcmykcolor____ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetcmykcolor::::)];
/* ----------------------------------------------------------------------- */
/* Data operations */
/* ----------------------------------------------------------------------- */
      methodTable.DPSclear = (void *)[self instanceMethodForSelector:
				@selector(DPSclear)];
      methodTable.DPScleartomark = (void *)[self instanceMethodForSelector:
				@selector(DPScleartomark)];
      methodTable.DPScopy_ = (void *)[self instanceMethodForSelector:
				@selector(DPScopy:)];
      methodTable.DPScount_ = (void *)[self instanceMethodForSelector:
				@selector(DPScount:)];
      methodTable.DPScounttomark_ = (void *)[self instanceMethodForSelector:
				@selector(DPScounttomark:)];
      methodTable.DPSdup = (void *)[self instanceMethodForSelector:
				@selector(DPSdup)];
      methodTable.DPSexch = (void *)[self instanceMethodForSelector:
				@selector(DPSexch)];
      methodTable.DPSexecstack = (void *)[self instanceMethodForSelector:
				@selector(DPSexecstack)];
      methodTable.DPSget = (void *)[self instanceMethodForSelector:
				@selector(DPSget)];
      methodTable.DPSindex_ = (void *)[self instanceMethodForSelector:
				@selector(DPSindex:)];
      methodTable.DPSmark = (void *)[self instanceMethodForSelector:
				@selector(DPSmark)];
      methodTable.DPSmatrix = (void *)[self instanceMethodForSelector:
				@selector(DPSmatrix)];
      methodTable.DPSnull = (void *)[self instanceMethodForSelector:
				@selector(DPSnull)];
      methodTable.DPSpop = (void *)[self instanceMethodForSelector:
				@selector(DPSpop)];
      methodTable.DPSput = (void *)[self instanceMethodForSelector:
				@selector(DPSput)];
      methodTable.DPSroll__ = (void *)[self instanceMethodForSelector:
				@selector(DPSroll::)];
/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */
      methodTable.DPSFontDirectory = (void *)[self instanceMethodForSelector:
				@selector(DPSFontDirectory)];
      methodTable.DPSISOLatin1Encoding = (void *)[self instanceMethodForSelector:
				@selector(DPSISOLatin1Encoding)];
      methodTable.DPSSharedFontDirectory = (void *)[self instanceMethodForSelector:
				@selector(DPSSharedFontDirectory)];
      methodTable.DPSStandardEncoding = (void *)[self instanceMethodForSelector:
				@selector(DPSStandardEncoding)];
      methodTable.DPScurrentcacheparams = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentcacheparams)];
      methodTable.DPScurrentfont = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentfont)];
      methodTable.DPSdefinefont = (void *)[self instanceMethodForSelector:
				@selector(DPSdefinefont)];
      methodTable.DPSfindfont_ = (void *)[self instanceMethodForSelector:
				@selector(DPSfindfont:)];
      methodTable.DPSmakefont = (void *)[self instanceMethodForSelector:
				@selector(DPSmakefont)];
      methodTable.DPSscalefont_ = (void *)[self instanceMethodForSelector:
				@selector(DPSscalefont:)];
      methodTable.DPSselectfont__ = (void *)[self instanceMethodForSelector:
				@selector(DPSselectfont::)];
      methodTable.DPSsetfont_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetfont:)];
      methodTable.DPSundefinefont_ = (void *)[self instanceMethodForSelector:
				@selector(DPSundefinefont:)];
/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */
      methodTable.DPSconcat_ = (void *)[self instanceMethodForSelector:
				@selector(DPSconcat:)];
      methodTable.DPScurrentdash = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentdash)];
      methodTable.DPScurrentflat_ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentflat:)];
      methodTable.DPScurrentgray_ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentgray:)];
      methodTable.DPScurrentgstate_ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentgstate:)];
      methodTable.DPScurrenthalftone = (void *)[self instanceMethodForSelector:
				@selector(DPScurrenthalftone)];
      methodTable.DPScurrenthalftonephase__ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrenthalftonephase::)];
      methodTable.DPScurrenthsbcolor___ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrenthsbcolor:::)];
      methodTable.DPScurrentlinecap_ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentlinecap:)];
      methodTable.DPScurrentlinejoin_ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentlinejoin:)];
      methodTable.DPScurrentlinewidth_ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentlinewidth:)];
      methodTable.DPScurrentmatrix = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentmatrix)];
      methodTable.DPScurrentmiterlimit_ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentmiterlimit:)];
      methodTable.DPScurrentpoint__ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentpoint::)];
      methodTable.DPScurrentrgbcolor___ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentrgbcolor:::)];
      methodTable.DPScurrentscreen = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentscreen)];
      methodTable.DPScurrentstrokeadjust_ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentstrokeadjust:)];
      methodTable.DPScurrenttransfer = (void *)[self instanceMethodForSelector:
				@selector(DPScurrenttransfer)];
      methodTable.DPSdefaultmatrix = (void *)[self instanceMethodForSelector:
				@selector(DPSdefaultmatrix)];
      methodTable.DPSgrestore = (void *)[self instanceMethodForSelector:
				@selector(DPSgrestore)];
      methodTable.DPSgrestoreall = (void *)[self instanceMethodForSelector:
				@selector(DPSgrestoreall)];
      methodTable.DPSgsave = (void *)[self instanceMethodForSelector:
				@selector(DPSgsave)];
      methodTable.DPSgstate = (void *)[self instanceMethodForSelector:
				@selector(DPSgstate)];
      methodTable.DPSinitgraphics = (void *)[self instanceMethodForSelector:
				@selector(DPSinitgraphics)];
      methodTable.DPSinitmatrix = (void *)[self instanceMethodForSelector:
				@selector(DPSinitmatrix)];
      methodTable.DPSrotate_ = (void *)[self instanceMethodForSelector:
				@selector(DPSrotate:)];
      methodTable.DPSscale__ = (void *)[self instanceMethodForSelector:
				@selector(DPSscale::)];
      methodTable.DPSsetdash___ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetdash:::)];
      methodTable.DPSsetflat_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetflat:)];
      methodTable.DPSsetgray_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetgray:)];
      methodTable.DPSsetgstate_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetgstate:)];
      methodTable.DPSsethalftone = (void *)[self instanceMethodForSelector:
				@selector(DPSsethalftone)];
      methodTable.DPSsethalftonephase__ = (void *)[self instanceMethodForSelector:
				@selector(DPSsethalftonephase::)];
      methodTable.DPSsethsbcolor___ = (void *)[self instanceMethodForSelector:
				@selector(DPSsethsbcolor:::)];
      methodTable.DPSsetlinecap_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetlinecap:)];
      methodTable.DPSsetlinejoin_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetlinejoin:)];
      methodTable.DPSsetlinewidth_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetlinewidth:)];
      methodTable.DPSsetmatrix = (void *)[self instanceMethodForSelector:
				@selector(DPSsetmatrix)];
      methodTable.DPSsetmiterlimit_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetmiterlimit:)];
      methodTable.DPSsetrgbcolor___ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetrgbcolor:::)];
      methodTable.DPSsetscreen = (void *)[self instanceMethodForSelector:
				@selector(DPSsetscreen)];
      methodTable.DPSsetstrokeadjust_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetstrokeadjust:)];
      methodTable.DPSsettransfer = (void *)[self instanceMethodForSelector:
				@selector(DPSsettransfer)];
      methodTable.DPStranslate__ = (void *)[self instanceMethodForSelector:
				@selector(DPStranslate::)];
/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
      methodTable.DPSconcatmatrix = (void *)[self instanceMethodForSelector:
				@selector(DPSconcatmatrix)];
      methodTable.DPSdtransform____ = (void *)[self instanceMethodForSelector:
				@selector(DPSdtransform::::)];
      methodTable.DPSidentmatrix = (void *)[self instanceMethodForSelector:
				@selector(DPSidentmatrix)];
      methodTable.DPSidtransform____ = (void *)[self instanceMethodForSelector:
				@selector(DPSidtransform::::)];
      methodTable.DPSinvertmatrix = (void *)[self instanceMethodForSelector:
				@selector(DPSinvertmatrix)];
      methodTable.DPSitransform____ = (void *)[self instanceMethodForSelector:
				@selector(DPSitransform::::)];
      methodTable.DPStransform____ = (void *)[self instanceMethodForSelector:
				@selector(DPStransform::::)];
/* ----------------------------------------------------------------------- */
/* Opstack operations */
/* ----------------------------------------------------------------------- */
      methodTable.DPSgetboolean_ = (void *)[self instanceMethodForSelector:
				@selector(DPSgetboolean:)];
      methodTable.DPSgetchararray__ = (void *)[self instanceMethodForSelector:
				@selector(DPSgetchararray::)];
      methodTable.DPSgetfloat_ = (void *)[self instanceMethodForSelector:
				@selector(DPSgetfloat:)];
      methodTable.DPSgetfloatarray__ = (void *)[self instanceMethodForSelector:
				@selector(DPSgetfloatarray::)];
      methodTable.DPSgetint_ = (void *)[self instanceMethodForSelector:
				@selector(DPSgetint:)];
      methodTable.DPSgetintarray__ = (void *)[self instanceMethodForSelector:
				@selector(DPSgetintarray::)];
      methodTable.DPSgetstring_ = (void *)[self instanceMethodForSelector:
				@selector(DPSgetstring:)];
      methodTable.DPSsendboolean_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsendboolean:)];
      methodTable.DPSsendchararray__ = (void *)[self instanceMethodForSelector:
				@selector(DPSsendchararray::)];
      methodTable.DPSsendfloat_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsendfloat:)];
      methodTable.DPSsendfloatarray__ = (void *)[self instanceMethodForSelector:
				@selector(DPSsendfloatarray::)];
      methodTable.DPSsendint_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsendint:)];
      methodTable.DPSsendintarray__ = (void *)[self instanceMethodForSelector:
				@selector(DPSsendintarray::)];
      methodTable.DPSsendstring_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsendstring:)];
/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */
      methodTable.DPSashow___ = (void *)[self instanceMethodForSelector:
				@selector(DPSashow:::)];
      methodTable.DPSawidthshow______ = (void *)[self instanceMethodForSelector:
				@selector(DPSawidthshow::::::)];
      methodTable.DPScopypage = (void *)[self instanceMethodForSelector:
				@selector(DPScopypage)];
      methodTable.DPSeofill = (void *)[self instanceMethodForSelector:
				@selector(DPSeofill)];
      methodTable.DPSerasepage = (void *)[self instanceMethodForSelector:
				@selector(DPSerasepage)];
      methodTable.DPSfill = (void *)[self instanceMethodForSelector:
				@selector(DPSfill)];
      methodTable.DPSimage = (void *)[self instanceMethodForSelector:
				@selector(DPSimage)];
      methodTable.DPSimagemask = (void *)[self instanceMethodForSelector:
				@selector(DPSimagemask)];
      methodTable.DPSkshow_ = (void *)[self instanceMethodForSelector:
				@selector(DPSkshow:)];
      methodTable.DPSrectfill____ = (void *)[self instanceMethodForSelector:
				@selector(DPSrectfill::::)];
      methodTable.DPSrectstroke____ = (void *)[self instanceMethodForSelector:
				@selector(DPSrectstroke::::)];
      methodTable.DPSshow_ = (void *)[self instanceMethodForSelector:
				@selector(DPSshow:)];
      methodTable.DPSshowpage = (void *)[self instanceMethodForSelector:
				@selector(DPSshowpage)];
      methodTable.DPSstroke = (void *)[self instanceMethodForSelector:
				@selector(DPSstroke)];
      methodTable.DPSstrokepath = (void *)[self instanceMethodForSelector:
				@selector(DPSstrokepath)];
      methodTable.DPSueofill____ = (void *)[self instanceMethodForSelector:
				@selector(DPSueofill::::)];
      methodTable.DPSufill____ = (void *)[self instanceMethodForSelector:
				@selector(DPSufill::::)];
      methodTable.DPSustroke____ = (void *)[self instanceMethodForSelector:
				@selector(DPSustroke::::)];
      methodTable.DPSustrokepath____ = (void *)[self instanceMethodForSelector:
				@selector(DPSustrokepath::::)];
      methodTable.DPSwidthshow____ = (void *)[self instanceMethodForSelector:
				@selector(DPSwidthshow::::)];
      methodTable.DPSxshow___ = (void *)[self instanceMethodForSelector:
				@selector(DPSxshow:::)];
      methodTable.DPSxyshow___ = (void *)[self instanceMethodForSelector:
				@selector(DPSxyshow:::)];
      methodTable.DPSyshow___ = (void *)[self instanceMethodForSelector:
				@selector(DPSyshow:::)];
/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */
      methodTable.DPSarc_____ = (void *)[self instanceMethodForSelector:
				@selector(DPSarc:::::)];
      methodTable.DPSarcn_____ = (void *)[self instanceMethodForSelector:
				@selector(DPSarcn:::::)];
      methodTable.DPSarct_____ = (void *)[self instanceMethodForSelector:
				@selector(DPSarct:::::)];
      methodTable.DPSarcto_________ = (void *)[self instanceMethodForSelector:
				@selector(DPSarcto:::::::::)];
      methodTable.DPScharpath__ = (void *)[self instanceMethodForSelector:
				@selector(DPScharpath::)];
      methodTable.DPSclip = (void *)[self instanceMethodForSelector:
				@selector(DPSclip)];
      methodTable.DPSclippath = (void *)[self instanceMethodForSelector:
				@selector(DPSclippath)];
      methodTable.DPSclosepath = (void *)[self instanceMethodForSelector:
				@selector(DPSclosepath)];
      methodTable.DPScurveto______ = (void *)[self instanceMethodForSelector:
				@selector(DPScurveto::::::)];
      methodTable.DPSeoclip = (void *)[self instanceMethodForSelector:
				@selector(DPSeoclip)];
      methodTable.DPSeoviewclip = (void *)[self instanceMethodForSelector:
				@selector(DPSeoviewclip)];
      methodTable.DPSflattenpath = (void *)[self instanceMethodForSelector:
				@selector(DPSflattenpath)];
      methodTable.DPSinitclip = (void *)[self instanceMethodForSelector:
				@selector(DPSinitclip)];
      methodTable.DPSinitviewclip = (void *)[self instanceMethodForSelector:
				@selector(DPSinitviewclip)];
      methodTable.DPSlineto__ = (void *)[self instanceMethodForSelector:
				@selector(DPSlineto::)];
      methodTable.DPSmoveto__ = (void *)[self instanceMethodForSelector:
				@selector(DPSmoveto::)];
      methodTable.DPSnewpath = (void *)[self instanceMethodForSelector:
				@selector(DPSnewpath)];
      methodTable.DPSpathbbox____ = (void *)[self instanceMethodForSelector:
				@selector(DPSpathbbox::::)];
      methodTable.DPSpathforall = (void *)[self instanceMethodForSelector:
				@selector(DPSpathforall)];
      methodTable.DPSrcurveto______ = (void *)[self instanceMethodForSelector:
				@selector(DPSrcurveto::::::)];
      methodTable.DPSrectclip____ = (void *)[self instanceMethodForSelector:
				@selector(DPSrectclip::::)];
      methodTable.DPSrectviewclip____ = (void *)[self instanceMethodForSelector:
				@selector(DPSrectviewclip::::)];
      methodTable.DPSreversepath = (void *)[self instanceMethodForSelector:
				@selector(DPSreversepath)];
      methodTable.DPSrlineto__ = (void *)[self instanceMethodForSelector:
				@selector(DPSrlineto::)];
      methodTable.DPSrmoveto__ = (void *)[self instanceMethodForSelector:
				@selector(DPSrmoveto::)];
      methodTable.DPSsetbbox____ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetbbox::::)];
      methodTable.DPSviewclip = (void *)[self instanceMethodForSelector:
				@selector(DPSviewclip)];
      methodTable.DPSviewclippath = (void *)[self instanceMethodForSelector:
				@selector(DPSviewclippath)];
/* ----------------------------------------------------------------------- */
/* Window system ops */
/* ----------------------------------------------------------------------- */
      methodTable.DPScurrentdrawingfunction_ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentdrawingfunction:)];
      methodTable.DPScurrentgcdrawable____ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentgcdrawable::::)];
      methodTable.DPScurrentgcdrawablecolor_____ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentgcdrawablecolor:::::)];
      methodTable.DPScurrentoffset__ = (void *)[self instanceMethodForSelector:
				@selector(DPScurrentoffset::)];
      methodTable.DPSsetdrawingfunction_ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetdrawingfunction:)];
      methodTable.DPSsetgcdrawable____ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetgcdrawable::::)];
      methodTable.DPSsetgcdrawablecolor_____ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetgcdrawablecolor:::::)];
      methodTable.DPSsetoffset__ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetoffset::)];
      methodTable.DPSsetrgbactual____ = (void *)[self instanceMethodForSelector:
				@selector(DPSsetrgbactual::::)];
      methodTable.DPScapturegstate_ = (void *)[self instanceMethodForSelector:
				@selector(DPScapturegstate:)];

  mptr = NSZoneMalloc(_globalGSZone, sizeof(gsMethodTable));
  memcpy(mptr, &methodTable, sizeof(gsMethodTable));
  return mptr;
}

@end
