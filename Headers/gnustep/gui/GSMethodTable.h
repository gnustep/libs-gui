/* GSMethodTable.h - Definitions of PostScript methods for NSGraphicsContext

   Copyright (C) 1998 Free Software Foundation, Inc.
   Written by:  Adam Fedor <fedor@gnu.org>
   Date: Nov 1998
   Updated by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   
   This file is part of the GNU Objective C User Interface library.
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
   Software Foundation, Inc., 675 Mass Ave, Cambrvoidge, MA 02139, USA.
   */

#ifndef _GSMethodTable_h_INCLUDE
#define _GSMethodTable_h_INCLUDE

#include <Foundation/NSObject.h>

@class NSDate;
@class NSEvent;
@class NSGraphicsContext;
@class NSString;

typedef struct {

/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */
  void (*DPScurrentcmykcolor____)
	(NSGraphicsContext*, SEL, float*, float*, float*, float*);
  void (*DPSsetcmykcolor____)
	(NSGraphicsContext*, SEL, float, float, float, float);
/* ----------------------------------------------------------------------- */
/* Data operations */
/* ----------------------------------------------------------------------- */
  void (*DPSclear)
	(NSGraphicsContext*, SEL);
  void (*DPScleartomark)
	(NSGraphicsContext*, SEL);
  void (*DPScopy_)
	(NSGraphicsContext*, SEL, int);
  void (*DPScount_)
	(NSGraphicsContext*, SEL, int*);
  void (*DPScounttomark_)
	(NSGraphicsContext*, SEL, int*);
  void (*DPSdup)
	(NSGraphicsContext*, SEL);
  void (*DPSexch)
	(NSGraphicsContext*, SEL);
  void (*DPSexecstack)
	(NSGraphicsContext*, SEL);
  void (*DPSget)
	(NSGraphicsContext*, SEL);
  void (*DPSindex_)
	(NSGraphicsContext*, SEL, int);
  void (*DPSmark)
	(NSGraphicsContext*, SEL);
  void (*DPSmatrix)
	(NSGraphicsContext*, SEL);
  void (*DPSnull)
	(NSGraphicsContext*, SEL);
  void (*DPSpop)
	(NSGraphicsContext*, SEL);
  void (*DPSput)
	(NSGraphicsContext*, SEL);
  void (*DPSroll__)
	(NSGraphicsContext*, SEL, int, int);
/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */
  void (*DPSFontDirectory)
	(NSGraphicsContext*, SEL);
  void (*DPSISOLatin1Encoding)
	(NSGraphicsContext*, SEL);
  void (*DPSSharedFontDirectory)
	(NSGraphicsContext*, SEL);
  void (*DPSStandardEncoding)
	(NSGraphicsContext*, SEL);
  void (*DPScurrentcacheparams)
	(NSGraphicsContext*, SEL);
  void (*DPScurrentfont)
	(NSGraphicsContext*, SEL);
  void (*DPSdefinefont)
	(NSGraphicsContext*, SEL);
  void (*DPSfindfont_)
	(NSGraphicsContext*, SEL, const char*);
  void (*DPSmakefont)
	(NSGraphicsContext*, SEL);
  void (*DPSscalefont_)
	(NSGraphicsContext*, SEL, float);
  void (*DPSselectfont__)
	(NSGraphicsContext*, SEL, const char*, float);
  void (*DPSsetfont_)
	(NSGraphicsContext*, SEL, int);
  void (*DPSundefinefont_)
	(NSGraphicsContext*, SEL, const char*);
/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */
  void (*DPSconcat_)
	(NSGraphicsContext*, SEL, const float *);
  void (*DPScurrentdash)
	(NSGraphicsContext*, SEL);
  void (*DPScurrentflat_)
	(NSGraphicsContext*, SEL, float*);
  void (*DPScurrentgray_)
	(NSGraphicsContext*, SEL, float*);
  void (*DPScurrentgstate_)
	(NSGraphicsContext*, SEL, int);
  void (*DPScurrenthalftone)
	(NSGraphicsContext*, SEL);
  void (*DPScurrenthalftonephase__)
	(NSGraphicsContext*, SEL, float*, float*);
  void (*DPScurrenthsbcolor___)
	(NSGraphicsContext*, SEL, float*, float*, float*);
  void (*DPScurrentlinecap_)
	(NSGraphicsContext*, SEL, int*);
  void (*DPScurrentlinejoin_)
	(NSGraphicsContext*, SEL, int*);
  void (*DPScurrentlinewidth_)
	(NSGraphicsContext*, SEL, float*);
  void (*DPScurrentmatrix)
	(NSGraphicsContext*, SEL);
  void (*DPScurrentmiterlimit_)
	(NSGraphicsContext*, SEL, float*);
  void (*DPScurrentpoint__)
	(NSGraphicsContext*, SEL, float*, float*);
  void (*DPScurrentrgbcolor___)
	(NSGraphicsContext*, SEL, float*, float*, float*);
  void (*DPScurrentscreen)
	(NSGraphicsContext*, SEL);
  void (*DPScurrentstrokeadjust_)
	(NSGraphicsContext*, SEL, int*);
  void (*DPScurrenttransfer)
	(NSGraphicsContext*, SEL);
  void (*DPSdefaultmatrix)
	(NSGraphicsContext*, SEL);
  void (*DPSgrestore)
	(NSGraphicsContext*, SEL);
  void (*DPSgrestoreall)
	(NSGraphicsContext*, SEL);
  void (*DPSgsave)
	(NSGraphicsContext*, SEL);
  void (*DPSgstate)
	(NSGraphicsContext*, SEL);
  void (*DPSinitgraphics)
	(NSGraphicsContext*, SEL);
  void (*DPSinitmatrix)
	(NSGraphicsContext*, SEL);
  void (*DPSrotate_)
	(NSGraphicsContext*, SEL, float);
  void (*DPSscale__)
	(NSGraphicsContext*, SEL, float, float);
  void (*DPSsetdash___)
	(NSGraphicsContext*, SEL, const float*, int, float);
  void (*DPSsetflat_)
	(NSGraphicsContext*, SEL, float);
  void (*DPSsetgray_)
	(NSGraphicsContext*, SEL, float);
  void (*DPSsetgstate_)
	(NSGraphicsContext*, SEL, int);
  void (*DPSsethalftone)
	(NSGraphicsContext*, SEL);
  void (*DPSsethalftonephase__)
	(NSGraphicsContext*, SEL, float, float);
  void (*DPSsethsbcolor___)
	(NSGraphicsContext*, SEL, float, float, float);
  void (*DPSsetlinecap_)
	(NSGraphicsContext*, SEL, int);
  void (*DPSsetlinejoin_)
	(NSGraphicsContext*, SEL, int);
  void (*DPSsetlinewidth_)
	(NSGraphicsContext*, SEL, float);
  void (*DPSsetmatrix)
	(NSGraphicsContext*, SEL);
  void (*DPSsetmiterlimit_)
	(NSGraphicsContext*, SEL, float);
  void (*DPSsetrgbcolor___)
	(NSGraphicsContext*, SEL, float, float, float);
  void (*DPSsetscreen)
	(NSGraphicsContext*, SEL);
  void (*DPSsetstrokeadjust_)
	(NSGraphicsContext*, SEL, int);
  void (*DPSsettransfer)
	(NSGraphicsContext*, SEL);
  void (*DPStranslate__)
	(NSGraphicsContext*, SEL, float, float);
/* ----------------------------------------------------------------------- */
/* I/O operations */
/* ----------------------------------------------------------------------- */
  void (*DPSflush)
	(NSGraphicsContext*, SEL);
/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
  void (*DPSconcatmatrix)
	(NSGraphicsContext*, SEL);
  void (*DPSdtransform____)
	(NSGraphicsContext*, SEL, float, float, float*, float*);
  void (*DPSidentmatrix)
	(NSGraphicsContext*, SEL);
  void (*DPSidtransform____)
	(NSGraphicsContext*, SEL, float, float, float*, float*);
  void (*DPSinvertmatrix)
	(NSGraphicsContext*, SEL);
  void (*DPSitransform____)
	(NSGraphicsContext*, SEL, float, float, float*, float*);
  void (*DPStransform____)
	(NSGraphicsContext*, SEL, float, float, float*, float*);
/* ----------------------------------------------------------------------- */
/* Opstack operations */
/* ----------------------------------------------------------------------- */
  void (*DPSgetboolean_)
	(NSGraphicsContext*, SEL, int*);
  void (*DPSgetchararray__)
	(NSGraphicsContext*, SEL, int, char*);
  void (*DPSgetfloat_)
	(NSGraphicsContext*, SEL, float*);
  void (*DPSgetfloatarray__)
	(NSGraphicsContext*, SEL, int, float*);
  void (*DPSgetint_)
	(NSGraphicsContext*, SEL, int*);
  void (*DPSgetintarray__)
	(NSGraphicsContext*, SEL, int, int*);
  void (*DPSgetstring_)
	(NSGraphicsContext*, SEL, char*);
  void (*DPSsendboolean_)
	(NSGraphicsContext*, SEL, int);
  void (*DPSsendchararray__)
	(NSGraphicsContext*, SEL, const char*, int);
  void (*DPSsendfloat_)
	(NSGraphicsContext*, SEL, float);
  void (*DPSsendfloatarray__)
	(NSGraphicsContext*, SEL, const float*, int);
  void (*DPSsendint_)
	(NSGraphicsContext*, SEL, int);
  void (*DPSsendintarray__)
	(NSGraphicsContext*, SEL, const int*, int);
  void (*DPSsendstring_)
	(NSGraphicsContext*, SEL, const char*);
/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */
  void (*DPSashow___)
	(NSGraphicsContext*, SEL, float, float, const char*);
  void (*DPSawidthshow______)
	(NSGraphicsContext*, SEL, float, float, int, float, float, const char*);
  void (*DPScopypage)
	(NSGraphicsContext*, SEL);
  void (*DPSeofill)
	(NSGraphicsContext*, SEL);
  void (*DPSerasepage)
	(NSGraphicsContext*, SEL);
  void (*DPSfill)
	(NSGraphicsContext*, SEL);
  void (*DPSimage)
	(NSGraphicsContext*, SEL);
  void (*DPSimagemask)
	(NSGraphicsContext*, SEL);
  void (*DPSkshow_)
	(NSGraphicsContext*, SEL, const char*);
  void (*DPSrectfill____)
	(NSGraphicsContext*, SEL, float, float, float, float);
  void (*DPSrectstroke____)
	(NSGraphicsContext*, SEL, float, float, float, float);
  void (*DPSshow_)
	(NSGraphicsContext*, SEL, const char*);
  void (*DPSshowpage)
	(NSGraphicsContext*, SEL);
  void (*DPSstroke)
	(NSGraphicsContext*, SEL);
  void (*DPSstrokepath)
	(NSGraphicsContext*, SEL);
  void (*DPSueofill____)
	(NSGraphicsContext*, SEL, const char*, int, const char*, int);
  void (*DPSufill____)
	(NSGraphicsContext*, SEL, const char*, int, const char*, int);
  void (*DPSustroke____)
	(NSGraphicsContext*, SEL, const char*, int, const char*, int);
  void (*DPSustrokepath____)
	(NSGraphicsContext*, SEL, const char*, int, const char*, int);
  void (*DPSwidthshow____)
	(NSGraphicsContext*, SEL, float, float, int, const char*);
  void (*DPSxshow___)
	(NSGraphicsContext*, SEL, const char*, const float*, int);
  void (*DPSxyshow___)
	(NSGraphicsContext*, SEL, const char*, const float*, int);
  void (*DPSyshow___)
	(NSGraphicsContext*, SEL, const char*, const float*, int);
/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */
  void (*DPSarc_____)
	(NSGraphicsContext*, SEL, float, float, float, float, float);
  void (*DPSarcn_____)
	(NSGraphicsContext*, SEL, float, float, float, float, float);
  void (*DPSarct_____)
	(NSGraphicsContext*, SEL, float, float, float, float, float);
  void (*DPSarcto_________)
	(NSGraphicsContext*, SEL, float, float, float, float, float, float*, float*, float*, float*);
  void (*DPScharpath__)
	(NSGraphicsContext*, SEL, const char*, int);
  void (*DPSclip)
	(NSGraphicsContext*, SEL);
  void (*DPSclippath)
	(NSGraphicsContext*, SEL);
  void (*DPSclosepath)
	(NSGraphicsContext*, SEL);
  void (*DPScurveto______)
	(NSGraphicsContext*, SEL, float, float, float, float, float, float);
  void (*DPSeoclip)
	(NSGraphicsContext*, SEL);
  void (*DPSeoviewclip)
	(NSGraphicsContext*, SEL);
  void (*DPSflattenpath)
	(NSGraphicsContext*, SEL);
  void (*DPSinitclip)
	(NSGraphicsContext*, SEL);
  void (*DPSinitviewclip)
	(NSGraphicsContext*, SEL);
  void (*DPSlineto__)
	(NSGraphicsContext*, SEL, float, float);
  void (*DPSmoveto__)
	(NSGraphicsContext*, SEL, float, float);
  void (*DPSnewpath)
	(NSGraphicsContext*, SEL);
  void (*DPSpathbbox____)
	(NSGraphicsContext*, SEL, float*, float*, float*, float*);
  void (*DPSpathforall)
	(NSGraphicsContext*, SEL);
  void (*DPSrcurveto______)
	(NSGraphicsContext*, SEL, float, float, float, float, float, float);
  void (*DPSrectclip____)
	(NSGraphicsContext*, SEL, float, float, float, float);
  void (*DPSrectviewclip____)
	(NSGraphicsContext*, SEL, float, float, float, float);
  void (*DPSreversepath)
	(NSGraphicsContext*, SEL);
  void (*DPSrlineto__)
	(NSGraphicsContext*, SEL, float, float);
  void (*DPSrmoveto__)
	(NSGraphicsContext*, SEL, float, float);
  void (*DPSsetbbox____)
	(NSGraphicsContext*, SEL, float, float, float, float);
  void (*DPSviewclip)
	(NSGraphicsContext*, SEL);
  void (*DPSviewclippath)
	(NSGraphicsContext*, SEL);
/* ----------------------------------------------------------------------- */
/* Window system ops */
/* ----------------------------------------------------------------------- */
  void (*DPScurrentdrawingfunction_)
	(NSGraphicsContext*, SEL, int*);
  void (*DPScurrentgcdrawable____)
	(NSGraphicsContext*, SEL, void**, void**, int*, int*);
  void (*DPScurrentgcdrawablecolor_____)
	(NSGraphicsContext*, SEL, void**, void**, int*, int*, int*);
  void (*DPScurrentoffset__)
	(NSGraphicsContext*, SEL, int*, int*);
  void (*DPSsetdrawingfunction_)
	(NSGraphicsContext*, SEL, int);
  void (*DPSsetgcdrawable____)
	(NSGraphicsContext*, SEL, void*, void*, int, int);
  void (*DPSsetgcdrawablecolor_____)
	(NSGraphicsContext*, SEL, void*, void*, int, int, const int*);
  void (*DPSsetoffset__)
	(NSGraphicsContext*, SEL, short int, short int);
  void (*DPSsetrgbactual____)
	(NSGraphicsContext*, SEL, double, double, double, int*);
  void (*DPScapturegstate_)
	(NSGraphicsContext*, SEL, int*);

/*-------------------------------------------------------------------------*/
/* Graphics Extensions Ops */
/*-------------------------------------------------------------------------*/
  void (*DPScomposite________)
        (NSGraphicsContext*, SEL, float, float, float, float, int, float, float, int);
  void (*DPScompositerect_____)
        (NSGraphicsContext*, SEL, float, float, float, float, int);
  void (*DPSdissolve________)
        (NSGraphicsContext*, SEL, float, float, float, float, int, float, float, float);
  void (*DPSreadimage)
        (NSGraphicsContext*, SEL);
  void (*DPSsetalpha_)
        (NSGraphicsContext*, SEL, float);
  void (*DPScurrentalpha_)
        (NSGraphicsContext*, SEL, float*);

/* ----------------------------------------------------------------------- */
/* GNUstep Event and other I/O extensions */
/* ----------------------------------------------------------------------- */
  NSEvent* (*DPSGetEventMatchingMask_beforeDate_inMode_dequeue_)
	(NSGraphicsContext*, SEL, unsigned, NSDate*, NSString*, BOOL);
  void (*DPSDiscardEventsMatchingMask_beforeEvent_)
	(NSGraphicsContext*, SEL, unsigned, NSEvent*);
  void (*DPSPostEvent_atStart_)
	(NSGraphicsContext*, SEL, NSEvent*, BOOL);

} gsMethodTable;

#endif
