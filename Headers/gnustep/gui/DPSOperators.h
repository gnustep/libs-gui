/* DPSOperators - Drawing engine operators that require context

   Copyright (C) 1999 Free Software Foundation, Inc.
   Written by:  Richard frith-Macdonald <richard@brainstorm.co.uk>
   Based on code by Adam Fedor
   Date: Feb 1999
   
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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   */

#ifndef _DPSOperators_h_INCLUDE
#define _DPSOperators_h_INCLUDE

#include <AppKit/NSGraphicsContext.h>

#define	GSCTXT	NSGraphicsContext

/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */
static inline void
DPScurrentcmykcolor(GSCTXT *ctxt, float *c, float *m, float *y, float *k)
__attribute__((unused));

static inline void
DPSsetcmykcolor(GSCTXT *ctxt, float c, float m, float y, float k)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Data operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSclear(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPScleartomark(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPScopy(GSCTXT *ctxt, int n)
__attribute__((unused));

static inline void
DPScount(GSCTXT *ctxt, int *n)
__attribute__((unused));

static inline void
DPScounttomark(GSCTXT *ctxt, int *n)
__attribute__((unused));

static inline void
DPSdup(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSexch(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSexecstack(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSget(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSindex(GSCTXT *ctxt, int i)
__attribute__((unused));

static inline void
DPSmark(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSmatrix(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSnull(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSpop(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSput(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSroll(GSCTXT *ctxt, int n, int j)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSFontDirectory(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSISOLatin1Encoding(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSSharedFontDirectory(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSStandardEncoding(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPScurrentcacheparams(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPScurrentfont(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSdefinefont(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSfindfont(GSCTXT *ctxt, const char *name)
__attribute__((unused));

static inline void
DPSmakefont(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSscalefont(GSCTXT *ctxt, float size)
__attribute__((unused));

static inline void
DPSselectfont(GSCTXT *ctxt, const char *name, float scale)
__attribute__((unused));

static inline void
DPSsetfont(GSCTXT *ctxt, int f)
__attribute__((unused));

static inline void
DPSundefinefont(GSCTXT *ctxt, const char *name)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSconcat(GSCTXT *ctxt, const float m[])
__attribute__((unused));

static inline void
DPScurrentdash(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPScurrentflat(GSCTXT *ctxt, float *flatness)
__attribute__((unused));

static inline void
DPScurrentgray(GSCTXT *ctxt, float *gray)
__attribute__((unused));

static inline void
DPScurrentgstate(GSCTXT *ctxt, int gst)
__attribute__((unused));

static inline void
DPScurrenthalftone(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPScurrenthalftonephase(GSCTXT *ctxt, float *x, float *y)
__attribute__((unused));

static inline void
DPScurrenthsbcolor(GSCTXT *ctxt, float *h, float *s, float *b)
__attribute__((unused));

static inline void
DPScurrentlinecap(GSCTXT *ctxt, int *linecap)
__attribute__((unused));

static inline void
DPScurrentlinejoin(GSCTXT *ctxt, int *linejoin)
__attribute__((unused));

static inline void
DPScurrentlinewidth(GSCTXT *ctxt, float *width)
__attribute__((unused));

static inline void
DPScurrentmatrix(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPScurrentmiterlimit(GSCTXT *ctxt, float *limit)
__attribute__((unused));

static inline void
DPScurrentpoint(GSCTXT *ctxt, float *x, float *y)
__attribute__((unused));

static inline void
DPScurrentrgbcolor(GSCTXT *ctxt, float *r, float *g, float *b)
__attribute__((unused));

static inline void
DPScurrentscreen(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPScurrentstrokeadjust(GSCTXT *ctxt, int *b)
__attribute__((unused));

static inline void
DPScurrenttransfer(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSdefaultmatrix(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSgrestore(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSgrestoreall(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSgsave(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSgstate(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSinitgraphics(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSinitmatrix(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSrotate(GSCTXT *ctxt, float angle)
__attribute__((unused));

static inline void
DPSscale(GSCTXT *ctxt, float x, float y)
__attribute__((unused));

static inline void
DPSsetdash(GSCTXT *ctxt, const float pat[], int size, float offset)
__attribute__((unused));

static inline void
DPSsetflat(GSCTXT *ctxt, float flatness)
__attribute__((unused));

static inline void
DPSsetgray(GSCTXT *ctxt, float gray)
__attribute__((unused));

static inline void
DPSsetgstate(GSCTXT *ctxt, int gst)
__attribute__((unused));

static inline void
DPSsethalftone(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSsethalftonephase(GSCTXT *ctxt, float x, float y)
__attribute__((unused));

static inline void
DPSsethsbcolor(GSCTXT *ctxt, float h, float s, float b)
__attribute__((unused));

static inline void
DPSsetlinecap(GSCTXT *ctxt, int linecap)
__attribute__((unused));

static inline void
DPSsetlinejoin(GSCTXT *ctxt, int linejoin)
__attribute__((unused));

static inline void
DPSsetlinewidth(GSCTXT *ctxt, float width)
__attribute__((unused));

static inline void
DPSsetmatrix(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSsetmiterlimit(GSCTXT *ctxt, float limit)
__attribute__((unused));

static inline void
DPSsetrgbcolor(GSCTXT *ctxt, float r, float g, float b)
__attribute__((unused));

static inline void
DPSsetscreen(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSsetstrokeadjust(GSCTXT *ctxt, int b)
__attribute__((unused));

static inline void
DPSsettransfer(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPStranslate(GSCTXT *ctxt, float x, float y)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSconcatmatrix(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSdtransform(GSCTXT *ctxt, float x1, float y1, float *x2, float *y2)
__attribute__((unused));

static inline void
DPSidentmatrix(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSidtransform(GSCTXT *ctxt, float x1, float y1, float *x2, float *y2)
__attribute__((unused));

static inline void
DPSinvertmatrix(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSitransform(GSCTXT *ctxt, float x1, float y1, float *x2, float *y2)
__attribute__((unused));

static inline void
DPStransform(GSCTXT *ctxt, float x1, float y1, float *x2, float *y2)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Opstack operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSgetboolean(GSCTXT *ctxt, int *it)
__attribute__((unused));

static inline void
DPSgetchararray(GSCTXT *ctxt, int size, char s[])
__attribute__((unused));

static inline void
DPSgetfloat(GSCTXT *ctxt, float *it)
__attribute__((unused));

static inline void
DPSgetfloatarray(GSCTXT *ctxt, int size, float a[])
__attribute__((unused));

static inline void
DPSgetint(GSCTXT *ctxt, int *it)
__attribute__((unused));

static inline void
DPSgetintarray(GSCTXT *ctxt, int size, int a[])
__attribute__((unused));

static inline void
DPSgetstring(GSCTXT *ctxt, char *s)
__attribute__((unused));

static inline void
DPSsendboolean(GSCTXT *ctxt, int it)
__attribute__((unused));

static inline void
DPSsendchararray(GSCTXT *ctxt, const char s[], int size)
__attribute__((unused));

static inline void
DPSsendfloat(GSCTXT *ctxt, float it)
__attribute__((unused));

static inline void
DPSsendfloatarray(GSCTXT *ctxt, const float a[], int size)
__attribute__((unused));

static inline void
DPSsendint(GSCTXT *ctxt, int it)
__attribute__((unused));

static inline void
DPSsendintarray(GSCTXT *ctxt, const int a[], int size)
__attribute__((unused));

static inline void
DPSsendstring(GSCTXT *ctxt, const char *s)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSashow(GSCTXT *ctxt, float x, float y, const char *s)
__attribute__((unused));

static inline void
DPSawidthshow(GSCTXT *ctxt, float cx, float cy, int c, float ax, float ay, const char *s)
__attribute__((unused));

static inline void
DPScopypage(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSeofill(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSerasepage(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSfill(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSimage(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSimagemask(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSkshow(GSCTXT *ctxt, const char *s)
__attribute__((unused));

static inline void
DPSrectfill(GSCTXT *ctxt, float x, float y, float w, float h)
__attribute__((unused));

static inline void
DPSrectstroke(GSCTXT *ctxt, float x, float y, float w, float h)
__attribute__((unused));

static inline void
DPSshow(GSCTXT *ctxt, const char *s)
__attribute__((unused));

static inline void
DPSshowpage(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSstroke(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSstrokepath(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSueofill(GSCTXT *ctxt, const char nums[], int n, const char ops[], int l)
__attribute__((unused));

static inline void
DPSufill(GSCTXT *ctxt, const char nums[], int n, const char ops[], int l)
__attribute__((unused));

static inline void
DPSustroke(GSCTXT *ctxt, const char nums[], int n, const char ops[], int l)
__attribute__((unused));

static inline void
DPSustrokepath(GSCTXT *ctxt, const char nums[], int n, const char ops[], int l)
__attribute__((unused));

static inline void
DPSwidthshow(GSCTXT *ctxt, float x, float y, int c, const char *s)
__attribute__((unused));

static inline void
DPSxshow(GSCTXT *ctxt, const char *s, const float numarray[], int size)
__attribute__((unused));

static inline void
DPSxyshow(GSCTXT *ctxt, const char *s, const float numarray[], int size)
__attribute__((unused));

static inline void
DPSyshow(GSCTXT *ctxt, const char *s, const float numarray[], int size)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSarc(GSCTXT *ctxt, float x, float y, float r, float angle1, float angle2)
__attribute__((unused));

static inline void
DPSarcn(GSCTXT *ctxt, float x, float y, float r, float angle1, float angle2)
__attribute__((unused));

static inline void
DPSarct(GSCTXT *ctxt, float x1, float y1, float x2, float y2, float r)
__attribute__((unused));

static inline void
DPSarcto(GSCTXT *ctxt, float x1, float y1, float x2, float y2, float r, float *xt1, float *yt1, float *xt2, float *yt2)
__attribute__((unused));

static inline void
DPScharpath(GSCTXT *ctxt, const char *s, int b)
__attribute__((unused));

static inline void
DPSclip(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSclippath(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSclosepath(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPScurveto(GSCTXT *ctxt, float x1, float y1, float x2, float y2, float x3, float y3)
__attribute__((unused));

static inline void
DPSeoclip(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSeoviewclip(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSflattenpath(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSinitclip(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSinitviewclip(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSlineto(GSCTXT *ctxt, float x, float y)
__attribute__((unused));

static inline void
DPSmoveto(GSCTXT *ctxt, float x, float y)
__attribute__((unused));

static inline void
DPSnewpath(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSpathbbox(GSCTXT *ctxt, float *llx, float *lly, float *urx, float *ury)
__attribute__((unused));

static inline void
DPSpathforall(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSrcurveto(GSCTXT *ctxt, float x1, float y1, float x2, float y2, float x3, float y3)
__attribute__((unused));

static inline void
DPSrectclip(GSCTXT *ctxt, float x, float y, float w, float h)
__attribute__((unused));

static inline void
DPSrectviewclip(GSCTXT *ctxt, float x, float y, float w, float h)
__attribute__((unused));

static inline void
DPSreversepath(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSrlineto(GSCTXT *ctxt, float x, float y)
__attribute__((unused));

static inline void
DPSrmoveto(GSCTXT *ctxt, float x, float y)
__attribute__((unused));

static inline void
DPSsetbbox(GSCTXT *ctxt, float llx, float lly, float urx, float ury)
__attribute__((unused));

static inline void
DPSviewclip(GSCTXT *ctxt)
__attribute__((unused));

static inline void
DPSviewclippath(GSCTXT *ctxt)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Window system ops */
/* ----------------------------------------------------------------------- */
static inline void
DPScurrentdrawingfunction(GSCTXT *ctxt, int *function)
__attribute__((unused));

static inline void
DPScurrentgcdrawable(GSCTXT *ctxt, void* *gc, void* *draw, int *x, int *y)
__attribute__((unused));

static inline void
DPScurrentgcdrawablecolor(GSCTXT *ctxt, void* *gc, void* *draw, int *x, int *y, int colorInfo[])
__attribute__((unused));

static inline void
DPScurrentoffset(GSCTXT *ctxt, int *x, int *y)
__attribute__((unused));

static inline void
DPSsetdrawingfunction(GSCTXT *ctxt, int function)
__attribute__((unused));

static inline void
DPSsetgcdrawable(GSCTXT *ctxt, void* gc, void* draw, int x, int y)
__attribute__((unused));

static inline void
DPSsetgcdrawablecolor(GSCTXT *ctxt, void* gc, void* draw, int x, int y, const int colorInfo[])
__attribute__((unused));

static inline void
DPSsetoffset(GSCTXT *ctxt, short int x, short int y)
__attribute__((unused));

static inline void
DPSsetrgbactual(GSCTXT *ctxt, double r, double g, double b, int *success)
__attribute__((unused));

static inline void
DPScapturegstate(GSCTXT *ctxt, int *gst)
__attribute__((unused));




/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */
static inline void
DPScurrentcmykcolor(GSCTXT *ctxt, float *c, float *m, float *y, float *k)
{
  (ctxt->methods->DPScurrentcmykcolor____)
    (ctxt, @selector(DPScurrentcmykcolor::::), c, m, y, k);
}

static inline void
DPSsetcmykcolor(GSCTXT *ctxt, float c, float m, float y, float k)
{
  (ctxt->methods->DPSsetcmykcolor____)
    (ctxt, @selector(DPSsetcmykcolor::::), c, m, y, k);
}

/* ----------------------------------------------------------------------- */
/* Data operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSclear(GSCTXT *ctxt)
{
  (ctxt->methods->DPSclear)
    (ctxt, @selector(DPSclear));
}

static inline void
DPScleartomark(GSCTXT *ctxt)
{
  (ctxt->methods->DPScleartomark)
    (ctxt, @selector(DPScleartomark));
}

static inline void
DPScopy(GSCTXT *ctxt, int n)
{
  (ctxt->methods->DPScopy_)
    (ctxt, @selector(DPScopy:), n);
}

static inline void
DPScount(GSCTXT *ctxt, int *n)
{
  (ctxt->methods->DPScount_)
    (ctxt, @selector(DPScount:), n);
}

static inline void
DPScounttomark(GSCTXT *ctxt, int *n)
{
  (ctxt->methods->DPScounttomark_)
    (ctxt, @selector(DPScounttomark:), n);
}

static inline void
DPSdup(GSCTXT *ctxt)
{
  (ctxt->methods->DPSdup)
    (ctxt, @selector(DPSdup));
}

static inline void
DPSexch(GSCTXT *ctxt)
{
  (ctxt->methods->DPSexch)
    (ctxt, @selector(DPSexch));
}

static inline void
DPSexecstack(GSCTXT *ctxt)
{
  (ctxt->methods->DPSexecstack)
    (ctxt, @selector(DPSexecstack));
}

static inline void
DPSget(GSCTXT *ctxt)
{
  (ctxt->methods->DPSget)
    (ctxt, @selector(DPSget));
}

static inline void
DPSindex(GSCTXT *ctxt, int i)
{
  (ctxt->methods->DPSindex_)
    (ctxt, @selector(DPSindex:), i);
}

static inline void
DPSmark(GSCTXT *ctxt)
{
  (ctxt->methods->DPSmark)
    (ctxt, @selector(DPSmark));
}

static inline void
DPSmatrix(GSCTXT *ctxt)
{
  (ctxt->methods->DPSmatrix)
    (ctxt, @selector(DPSmatrix));
}

static inline void
DPSnull(GSCTXT *ctxt)
{
  (ctxt->methods->DPSnull)
    (ctxt, @selector(DPSnull));
}

static inline void
DPSpop(GSCTXT *ctxt)
{
  (ctxt->methods->DPSpop)
    (ctxt, @selector(DPSpop));
}

static inline void
DPSput(GSCTXT *ctxt)
{
  (ctxt->methods->DPSput)
    (ctxt, @selector(DPSput));
}

static inline void
DPSroll(GSCTXT *ctxt, int n, int j)
{
  (ctxt->methods->DPSroll__)
    (ctxt, @selector(DPSroll::), n, j);
}

/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSFontDirectory(GSCTXT *ctxt)
{
  (ctxt->methods->DPSFontDirectory)
    (ctxt, @selector(DPSFontDirectory));
}

static inline void
DPSISOLatin1Encoding(GSCTXT *ctxt)
{
  (ctxt->methods->DPSISOLatin1Encoding)
    (ctxt, @selector(DPSISOLatin1Encoding));
}

static inline void
DPSSharedFontDirectory(GSCTXT *ctxt)
{
  (ctxt->methods->DPSSharedFontDirectory)
    (ctxt, @selector(DPSSharedFontDirectory));
}

static inline void
DPSStandardEncoding(GSCTXT *ctxt)
{
  (ctxt->methods->DPSStandardEncoding)
    (ctxt, @selector(DPSStandardEncoding));
}

static inline void
DPScurrentcacheparams(GSCTXT *ctxt)
{
  (ctxt->methods->DPScurrentcacheparams)
    (ctxt, @selector(DPScurrentcacheparams));
}

static inline void
DPScurrentfont(GSCTXT *ctxt)
{
  (ctxt->methods->DPScurrentfont)
    (ctxt, @selector(DPScurrentfont));
}

static inline void
DPSdefinefont(GSCTXT *ctxt)
{
  (ctxt->methods->DPSdefinefont)
    (ctxt, @selector(DPSdefinefont));
}

static inline void
DPSfindfont(GSCTXT *ctxt, const char *name)
{
  (ctxt->methods->DPSfindfont_)
    (ctxt, @selector(DPSfindfont:), name);
}

static inline void
DPSmakefont(GSCTXT *ctxt)
{
  (ctxt->methods->DPSmakefont)
    (ctxt, @selector(DPSmakefont));
}

static inline void
DPSscalefont(GSCTXT *ctxt, float size)
{
  (ctxt->methods->DPSscalefont_)
    (ctxt, @selector(DPSscalefont:), size);
}

static inline void
DPSselectfont(GSCTXT *ctxt, const char *name, float scale)
{
  (ctxt->methods->DPSselectfont__)
    (ctxt, @selector(DPSselectfont::), name, scale);
}

static inline void
DPSsetfont(GSCTXT *ctxt, int f)
{
  (ctxt->methods->DPSsetfont_)
    (ctxt, @selector(DPSsetfont:), f);
}

static inline void
DPSundefinefont(GSCTXT *ctxt, const char *name)
{
  (ctxt->methods->DPSundefinefont_)
    (ctxt, @selector(DPSundefinefont:), name);
}

/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSconcat(GSCTXT *ctxt, const float m[])
{
  (ctxt->methods->DPSconcat_)
    (ctxt, @selector(DPSconcat:), m);
}

static inline void
DPScurrentdash(GSCTXT *ctxt)
{
  (ctxt->methods->DPScurrentdash)
    (ctxt, @selector(DPScurrentdash));
}

static inline void
DPScurrentflat(GSCTXT *ctxt, float *flatness)
{
  (ctxt->methods->DPScurrentflat_)
    (ctxt, @selector(DPScurrentflat:), flatness);
}

static inline void
DPScurrentgray(GSCTXT *ctxt, float *gray)
{
  (ctxt->methods->DPScurrentgray_)
    (ctxt, @selector(DPScurrentgray:), gray);
}

static inline void
DPScurrentgstate(GSCTXT *ctxt, int gst)
{
  (ctxt->methods->DPScurrentgstate_)
    (ctxt, @selector(DPScurrentgstate:), gst);
}

static inline void
DPScurrenthalftone(GSCTXT *ctxt)
{
  (ctxt->methods->DPScurrenthalftone)
    (ctxt, @selector(DPScurrenthalftone));
}

static inline void
DPScurrenthalftonephase(GSCTXT *ctxt, float *x, float *y)
{
  (ctxt->methods->DPScurrenthalftonephase__)
    (ctxt, @selector(DPScurrenthalftonephase::), x, y);
}

static inline void
DPScurrenthsbcolor(GSCTXT *ctxt, float *h, float *s, float *b)
{
  (ctxt->methods->DPScurrenthsbcolor___)
    (ctxt, @selector(DPScurrenthsbcolor:::), h, s, b);
}

static inline void
DPScurrentlinecap(GSCTXT *ctxt, int *linecap)
{
  (ctxt->methods->DPScurrentlinecap_)
    (ctxt, @selector(DPScurrentlinecap:), linecap);
}

static inline void
DPScurrentlinejoin(GSCTXT *ctxt, int *linejoin)
{
  (ctxt->methods->DPScurrentlinejoin_)
    (ctxt, @selector(DPScurrentlinejoin:), linejoin);
}

static inline void
DPScurrentlinewidth(GSCTXT *ctxt, float *width)
{
  (ctxt->methods->DPScurrentlinewidth_)
    (ctxt, @selector(DPScurrentlinewidth:), width);
}

static inline void
DPScurrentmatrix(GSCTXT *ctxt)
{
  (ctxt->methods->DPScurrentmatrix)
    (ctxt, @selector(DPScurrentmatrix));
}

static inline void
DPScurrentmiterlimit(GSCTXT *ctxt, float *limit)
{
  (ctxt->methods->DPScurrentmiterlimit_)
    (ctxt, @selector(DPScurrentmiterlimit:), limit);
}

static inline void
DPScurrentpoint(GSCTXT *ctxt, float *x, float *y)
{
  (ctxt->methods->DPScurrentpoint__)
    (ctxt, @selector(DPScurrentpoint::), x, y);
}

static inline void
DPScurrentrgbcolor(GSCTXT *ctxt, float *r, float *g, float *b)
{
  (ctxt->methods->DPScurrentrgbcolor___)
    (ctxt, @selector(DPScurrentrgbcolor:::), r, g, b);
}

static inline void
DPScurrentscreen(GSCTXT *ctxt)
{
  (ctxt->methods->DPScurrentscreen)
    (ctxt, @selector(DPScurrentscreen));
}

static inline void
DPScurrentstrokeadjust(GSCTXT *ctxt, int *b)
{
  (ctxt->methods->DPScurrentstrokeadjust_)
    (ctxt, @selector(DPScurrentstrokeadjust:), b);
}

static inline void
DPScurrenttransfer(GSCTXT *ctxt)
{
  (ctxt->methods->DPScurrenttransfer)
    (ctxt, @selector(DPScurrenttransfer));
}

static inline void
DPSdefaultmatrix(GSCTXT *ctxt)
{
  (ctxt->methods->DPSdefaultmatrix)
    (ctxt, @selector(DPSdefaultmatrix));
}

static inline void
DPSgrestore(GSCTXT *ctxt)
{
  (ctxt->methods->DPSgrestore)
    (ctxt, @selector(DPSgrestore));
}

static inline void
DPSgrestoreall(GSCTXT *ctxt)
{
  (ctxt->methods->DPSgrestoreall)
    (ctxt, @selector(DPSgrestoreall));
}

static inline void
DPSgsave(GSCTXT *ctxt)
{
  (ctxt->methods->DPSgsave)
    (ctxt, @selector(DPSgsave));
}

static inline void
DPSgstate(GSCTXT *ctxt)
{
  (ctxt->methods->DPSgstate)
    (ctxt, @selector(DPSgstate));
}

static inline void
DPSinitgraphics(GSCTXT *ctxt)
{
  (ctxt->methods->DPSinitgraphics)
    (ctxt, @selector(DPSinitgraphics));
}

static inline void
DPSinitmatrix(GSCTXT *ctxt)
{
  (ctxt->methods->DPSinitmatrix)
    (ctxt, @selector(DPSinitmatrix));
}

static inline void
DPSrotate(GSCTXT *ctxt, float angle)
{
  (ctxt->methods->DPSrotate_)
    (ctxt, @selector(DPSrotate:), angle);
}

static inline void
DPSscale(GSCTXT *ctxt, float x, float y)
{
  (ctxt->methods->DPSscale__)
    (ctxt, @selector(DPSscale::), x, y);
}

static inline void
DPSsetdash(GSCTXT *ctxt, const float pat[], int size, float offset)
{
  (ctxt->methods->DPSsetdash___)
    (ctxt, @selector(DPSsetdash:::), pat, size, offset);
}

static inline void
DPSsetflat(GSCTXT *ctxt, float flatness)
{
  (ctxt->methods->DPSsetflat_)
    (ctxt, @selector(DPSsetflat:), flatness);
}

static inline void
DPSsetgray(GSCTXT *ctxt, float gray)
{
  (ctxt->methods->DPSsetgray_)
    (ctxt, @selector(DPSsetgray:), gray);
}

static inline void
DPSsetgstate(GSCTXT *ctxt, int gst)
{
  (ctxt->methods->DPSsetgstate_)
    (ctxt, @selector(DPSsetgstate:), gst);
}

static inline void
DPSsethalftone(GSCTXT *ctxt)
{
  (ctxt->methods->DPSsethalftone)
    (ctxt, @selector(DPSsethalftone));
}

static inline void
DPSsethalftonephase(GSCTXT *ctxt, float x, float y)
{
  (ctxt->methods->DPSsethalftonephase__)
    (ctxt, @selector(DPSsethalftonephase::), x, y);
}

static inline void
DPSsethsbcolor(GSCTXT *ctxt, float h, float s, float b)
{
  (ctxt->methods->DPSsethsbcolor___)
    (ctxt, @selector(DPSsethsbcolor:::), h, s, b);
}

static inline void
DPSsetlinecap(GSCTXT *ctxt, int linecap)
{
  (ctxt->methods->DPSsetlinecap_)
    (ctxt, @selector(DPSsetlinecap:), linecap);
}

static inline void
DPSsetlinejoin(GSCTXT *ctxt, int linejoin)
{
  (ctxt->methods->DPSsetlinejoin_)
    (ctxt, @selector(DPSsetlinejoin:), linejoin);
}

static inline void
DPSsetlinewidth(GSCTXT *ctxt, float width)
{
  (ctxt->methods->DPSsetlinewidth_)
    (ctxt, @selector(DPSsetlinewidth:), width);
}

static inline void
DPSsetmatrix(GSCTXT *ctxt)
{
  (ctxt->methods->DPSsetmatrix)
    (ctxt, @selector(DPSsetmatrix));
}

static inline void
DPSsetmiterlimit(GSCTXT *ctxt, float limit)
{
  (ctxt->methods->DPSsetmiterlimit_)
    (ctxt, @selector(DPSsetmiterlimit:), limit);
}

static inline void
DPSsetrgbcolor(GSCTXT *ctxt, float r, float g, float b)
{
  (ctxt->methods->DPSsetrgbcolor___)
    (ctxt, @selector(DPSsetrgbcolor:::), r, g, b);
}

static inline void
DPSsetscreen(GSCTXT *ctxt)
{
  (ctxt->methods->DPSsetscreen)
    (ctxt, @selector(DPSsetscreen));
}

static inline void
DPSsetstrokeadjust(GSCTXT *ctxt, int b)
{
  (ctxt->methods->DPSsetstrokeadjust_)
    (ctxt, @selector(DPSsetstrokeadjust:), b);
}

static inline void
DPSsettransfer(GSCTXT *ctxt)
{
  (ctxt->methods->DPSsettransfer)
    (ctxt, @selector(DPSsettransfer));
}

static inline void
DPStranslate(GSCTXT *ctxt, float x, float y)
{
  (ctxt->methods->DPStranslate__)
    (ctxt, @selector(DPStranslate::), x, y);
}

/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSconcatmatrix(GSCTXT *ctxt)
{
  (ctxt->methods->DPSconcatmatrix)
    (ctxt, @selector(DPSconcatmatrix));
}

static inline void
DPSdtransform(GSCTXT *ctxt, float x1, float y1, float *x2, float *y2)
{
  (ctxt->methods->DPSdtransform____)
    (ctxt, @selector(DPSdtransform::::), x1, y1, x2, y2);
}

static inline void
DPSidentmatrix(GSCTXT *ctxt)
{
  (ctxt->methods->DPSidentmatrix)
    (ctxt, @selector(DPSidentmatrix));
}

static inline void
DPSidtransform(GSCTXT *ctxt, float x1, float y1, float *x2, float *y2)
{
  (ctxt->methods->DPSidtransform____)
    (ctxt, @selector(DPSidtransform::::), x1, y1, x2, y2);
}

static inline void
DPSinvertmatrix(GSCTXT *ctxt)
{
  (ctxt->methods->DPSinvertmatrix)
    (ctxt, @selector(DPSinvertmatrix));
}

static inline void
DPSitransform(GSCTXT *ctxt, float x1, float y1, float *x2, float *y2)
{
  (ctxt->methods->DPSitransform____)
    (ctxt, @selector(DPSitransform::::), x1, y1, x2, y2);
}

static inline void
DPStransform(GSCTXT *ctxt, float x1, float y1, float *x2, float *y2)
{
  (ctxt->methods->DPStransform____)
    (ctxt, @selector(DPStransform::::), x1, y1, x2, y2);
}

/* ----------------------------------------------------------------------- */
/* Opstack operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSgetboolean(GSCTXT *ctxt, int *it)
{
  (ctxt->methods->DPSgetboolean_)
    (ctxt, @selector(DPSgetboolean:), it);
}

static inline void
DPSgetchararray(GSCTXT *ctxt, int size, char s[])
{
  (ctxt->methods->DPSgetchararray__)
    (ctxt, @selector(DPSgetchararray::), size, s);
}

static inline void
DPSgetfloat(GSCTXT *ctxt, float *it)
{
  (ctxt->methods->DPSgetfloat_)
    (ctxt, @selector(DPSgetfloat:), it);
}

static inline void
DPSgetfloatarray(GSCTXT *ctxt, int size, float a[])
{
  (ctxt->methods->DPSgetfloatarray__)
    (ctxt, @selector(DPSgetfloatarray::), size, a);
}

static inline void
DPSgetint(GSCTXT *ctxt, int *it)
{
  (ctxt->methods->DPSgetint_)
    (ctxt, @selector(DPSgetint:), it);
}

static inline void
DPSgetintarray(GSCTXT *ctxt, int size, int a[])
{
  (ctxt->methods->DPSgetintarray__)
    (ctxt, @selector(DPSgetintarray::), size, a);
}

static inline void
DPSgetstring(GSCTXT *ctxt, char *s)
{
  (ctxt->methods->DPSgetstring_)
    (ctxt, @selector(DPSgetstring:), s);
}

static inline void
DPSsendboolean(GSCTXT *ctxt, int it)
{
  (ctxt->methods->DPSsendboolean_)
    (ctxt, @selector(DPSsendboolean:), it);
}

static inline void
DPSsendchararray(GSCTXT *ctxt, const char s[], int size)
{
  (ctxt->methods->DPSsendchararray__)
    (ctxt, @selector(DPSsendchararray::), s, size);
}

static inline void
DPSsendfloat(GSCTXT *ctxt, float it)
{
  (ctxt->methods->DPSsendfloat_)
    (ctxt, @selector(DPSsendfloat:), it);
}

static inline void
DPSsendfloatarray(GSCTXT *ctxt, const float a[], int size)
{
  (ctxt->methods->DPSsendfloatarray__)
    (ctxt, @selector(DPSsendfloatarray::), a, size);
}

static inline void
DPSsendint(GSCTXT *ctxt, int it)
{
  (ctxt->methods->DPSsendint_)
    (ctxt, @selector(DPSsendint:), it);
}

static inline void
DPSsendintarray(GSCTXT *ctxt, const int a[], int size)
{
  (ctxt->methods->DPSsendintarray__)
    (ctxt, @selector(DPSsendintarray::), a, size);
}

static inline void
DPSsendstring(GSCTXT *ctxt, const char *s)
{
  (ctxt->methods->DPSsendstring_)
    (ctxt, @selector(DPSsendstring:), s);
}

/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSashow(GSCTXT *ctxt, float x, float y, const char *s)
{
  (ctxt->methods->DPSashow___)
    (ctxt, @selector(DPSashow:::), x, y, s);
}

static inline void
DPSawidthshow(GSCTXT *ctxt, float cx, float cy, int c, float ax, float ay, const char *s)
{
  (ctxt->methods->DPSawidthshow______)
    (ctxt, @selector(DPSawidthshow::::::), cx, cy, c, ax, ay, s);
}

static inline void
DPScopypage(GSCTXT *ctxt)
{
  (ctxt->methods->DPScopypage)
    (ctxt, @selector(DPScopypage));
}

static inline void
DPSeofill(GSCTXT *ctxt)
{
  (ctxt->methods->DPSeofill)
    (ctxt, @selector(DPSeofill));
}

static inline void
DPSerasepage(GSCTXT *ctxt)
{
  (ctxt->methods->DPSerasepage)
    (ctxt, @selector(DPSerasepage));
}

static inline void
DPSfill(GSCTXT *ctxt)
{
  (ctxt->methods->DPSfill)
    (ctxt, @selector(DPSfill));
}

static inline void
DPSimage(GSCTXT *ctxt)
{
  (ctxt->methods->DPSimage)
    (ctxt, @selector(DPSimage));
}

static inline void
DPSimagemask(GSCTXT *ctxt)
{
  (ctxt->methods->DPSimagemask)
    (ctxt, @selector(DPSimagemask));
}

static inline void
DPSkshow(GSCTXT *ctxt, const char *s)
{
  (ctxt->methods->DPSkshow_)
    (ctxt, @selector(DPSkshow:), s);
}

static inline void
DPSrectfill(GSCTXT *ctxt, float x, float y, float w, float h)
{
  (ctxt->methods->DPSrectfill____)
    (ctxt, @selector(DPSrectfill::::), x, y, w, h);
}

static inline void
DPSrectstroke(GSCTXT *ctxt, float x, float y, float w, float h)
{
  (ctxt->methods->DPSrectstroke____)
    (ctxt, @selector(DPSrectstroke::::), x, y, w, h);
}

static inline void
DPSshow(GSCTXT *ctxt, const char *s)
{
  (ctxt->methods->DPSshow_)
    (ctxt, @selector(DPSshow:), s);
}

static inline void
DPSshowpage(GSCTXT *ctxt)
{
  (ctxt->methods->DPSshowpage)
    (ctxt, @selector(DPSshowpage));
}

static inline void
DPSstroke(GSCTXT *ctxt)
{
  (ctxt->methods->DPSstroke)
    (ctxt, @selector(DPSstroke));
}

static inline void
DPSstrokepath(GSCTXT *ctxt)
{
  (ctxt->methods->DPSstrokepath)
    (ctxt, @selector(DPSstrokepath));
}

static inline void
DPSueofill(GSCTXT *ctxt, const char nums[], int n, const char ops[], int l)
{
  (ctxt->methods->DPSueofill____)
    (ctxt, @selector(DPSueofill::::), nums, n, ops, l);
}

static inline void
DPSufill(GSCTXT *ctxt, const char nums[], int n, const char ops[], int l)
{
  (ctxt->methods->DPSufill____)
    (ctxt, @selector(DPSufill::::), nums, n, ops, l);
}

static inline void
DPSustroke(GSCTXT *ctxt, const char nums[], int n, const char ops[], int l)
{
  (ctxt->methods->DPSustroke____)
    (ctxt, @selector(DPSustroke::::), nums, n, ops, l);
}

static inline void
DPSustrokepath(GSCTXT *ctxt, const char nums[], int n, const char ops[], int l)
{
  (ctxt->methods->DPSustrokepath____)
    (ctxt, @selector(DPSustrokepath::::), nums, n, ops, l);
}

static inline void
DPSwidthshow(GSCTXT *ctxt, float x, float y, int c, const char *s)
{
  (ctxt->methods->DPSwidthshow____)
    (ctxt, @selector(DPSwidthshow::::), x, y, c, s);
}

static inline void
DPSxshow(GSCTXT *ctxt, const char *s, const float numarray[], int size)
{
  (ctxt->methods->DPSxshow___)
    (ctxt, @selector(DPSxshow:::), s, numarray, size);
}

static inline void
DPSxyshow(GSCTXT *ctxt, const char *s, const float numarray[], int size)
{
  (ctxt->methods->DPSxyshow___)
    (ctxt, @selector(DPSxyshow:::), s, numarray, size);
}

static inline void
DPSyshow(GSCTXT *ctxt, const char *s, const float numarray[], int size)
{
  (ctxt->methods->DPSyshow___)
    (ctxt, @selector(DPSyshow:::), s, numarray, size);
}

/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */
static inline void
DPSarc(GSCTXT *ctxt, float x, float y, float r, float angle1, float angle2)
{
  (ctxt->methods->DPSarc_____)
    (ctxt, @selector(DPSarc:::::), x, y, r, angle1, angle2);
}

static inline void
DPSarcn(GSCTXT *ctxt, float x, float y, float r, float angle1, float angle2)
{
  (ctxt->methods->DPSarcn_____)
    (ctxt, @selector(DPSarcn:::::), x, y, r, angle1, angle2);
}

static inline void
DPSarct(GSCTXT *ctxt, float x1, float y1, float x2, float y2, float r)
{
  (ctxt->methods->DPSarct_____)
    (ctxt, @selector(DPSarct:::::), x1, y1, x2, y2, r);
}

static inline void
DPSarcto(GSCTXT *ctxt, float x1, float y1, float x2, float y2, float r, float *xt1, float *yt1, float *xt2, float *yt2)
{
  (ctxt->methods->DPSarcto_________)
    (ctxt, @selector(DPSarcto:::::::::), x1, y1, x2, y2, r, xt1, yt1, xt2, yt2);
}

static inline void
DPScharpath(GSCTXT *ctxt, const char *s, int b)
{
  (ctxt->methods->DPScharpath__)
    (ctxt, @selector(DPScharpath::), s, b);
}

static inline void
DPSclip(GSCTXT *ctxt)
{
  (ctxt->methods->DPSclip)
    (ctxt, @selector(DPSclip));
}

static inline void
DPSclippath(GSCTXT *ctxt)
{
  (ctxt->methods->DPSclippath)
    (ctxt, @selector(DPSclippath));
}

static inline void
DPSclosepath(GSCTXT *ctxt)
{
  (ctxt->methods->DPSclosepath)
    (ctxt, @selector(DPSclosepath));
}

static inline void
DPScurveto(GSCTXT *ctxt, float x1, float y1, float x2, float y2, float x3, float y3)
{
  (ctxt->methods->DPScurveto______)
    (ctxt, @selector(DPScurveto::::::), x1, y1, x2, y2, x3, y3);
}

static inline void
DPSeoclip(GSCTXT *ctxt)
{
  (ctxt->methods->DPSeoclip)
    (ctxt, @selector(DPSeoclip));
}

static inline void
DPSeoviewclip(GSCTXT *ctxt)
{
  (ctxt->methods->DPSeoviewclip)
    (ctxt, @selector(DPSeoviewclip));
}

static inline void
DPSflattenpath(GSCTXT *ctxt)
{
  (ctxt->methods->DPSflattenpath)
    (ctxt, @selector(DPSflattenpath));
}

static inline void
DPSinitclip(GSCTXT *ctxt)
{
  (ctxt->methods->DPSinitclip)
    (ctxt, @selector(DPSinitclip));
}

static inline void
DPSinitviewclip(GSCTXT *ctxt)
{
  (ctxt->methods->DPSinitviewclip)
    (ctxt, @selector(DPSinitviewclip));
}

static inline void
DPSlineto(GSCTXT *ctxt, float x, float y)
{
  (ctxt->methods->DPSlineto__)
    (ctxt, @selector(DPSlineto::), x, y);
}

static inline void
DPSmoveto(GSCTXT *ctxt, float x, float y)
{
  (ctxt->methods->DPSmoveto__)
    (ctxt, @selector(DPSmoveto::), x, y);
}

static inline void
DPSnewpath(GSCTXT *ctxt)
{
  (ctxt->methods->DPSnewpath)
    (ctxt, @selector(DPSnewpath));
}

static inline void
DPSpathbbox(GSCTXT *ctxt, float *llx, float *lly, float *urx, float *ury)
{
  (ctxt->methods->DPSpathbbox____)
    (ctxt, @selector(DPSpathbbox::::), llx, lly, urx, ury);
}

static inline void
DPSpathforall(GSCTXT *ctxt)
{
  (ctxt->methods->DPSpathforall)
    (ctxt, @selector(DPSpathforall));
}

static inline void
DPSrcurveto(GSCTXT *ctxt, float x1, float y1, float x2, float y2, float x3, float y3)
{
  (ctxt->methods->DPSrcurveto______)
    (ctxt, @selector(DPSrcurveto::::::), x1, y1, x2, y2, x3, y3);
}

static inline void
DPSrectclip(GSCTXT *ctxt, float x, float y, float w, float h)
{
  (ctxt->methods->DPSrectclip____)
    (ctxt, @selector(DPSrectclip::::), x, y, w, h);
}

static inline void
DPSrectviewclip(GSCTXT *ctxt, float x, float y, float w, float h)
{
  (ctxt->methods->DPSrectviewclip____)
    (ctxt, @selector(DPSrectviewclip::::), x, y, w, h);
}

static inline void
DPSreversepath(GSCTXT *ctxt)
{
  (ctxt->methods->DPSreversepath)
    (ctxt, @selector(DPSreversepath));
}

static inline void
DPSrlineto(GSCTXT *ctxt, float x, float y)
{
  (ctxt->methods->DPSrlineto__)
    (ctxt, @selector(DPSrlineto::), x, y);
}

static inline void
DPSrmoveto(GSCTXT *ctxt, float x, float y)
{
  (ctxt->methods->DPSrmoveto__)
    (ctxt, @selector(DPSrmoveto::), x, y);
}

static inline void
DPSsetbbox(GSCTXT *ctxt, float llx, float lly, float urx, float ury)
{
  (ctxt->methods->DPSsetbbox____)
    (ctxt, @selector(DPSsetbbox::::), llx, lly, urx, ury);
}

static inline void
DPSviewclip(GSCTXT *ctxt)
{
  (ctxt->methods->DPSviewclip)
    (ctxt, @selector(DPSviewclip));
}

static inline void
DPSviewclippath(GSCTXT *ctxt)
{
  (ctxt->methods->DPSviewclippath)
    (ctxt, @selector(DPSviewclippath));
}

/* ----------------------------------------------------------------------- */
/* Window system ops */
/* ----------------------------------------------------------------------- */
static inline void
DPScurrentdrawingfunction(GSCTXT *ctxt, int *function)
{
  (ctxt->methods->DPScurrentdrawingfunction_)
    (ctxt, @selector(DPScurrentdrawingfunction:), function);
}

static inline void
DPScurrentgcdrawable(GSCTXT *ctxt, void* *gc, void* *draw, int *x, int *y)
{
  (ctxt->methods->DPScurrentgcdrawable____)
    (ctxt, @selector(DPScurrentgcdrawable::::), gc, draw, x, y);
}

static inline void
DPScurrentgcdrawablecolor(GSCTXT *ctxt, void* *gc, void* *draw, int *x, int *y, int colorInfo[])
{
  (ctxt->methods->DPScurrentgcdrawablecolor_____)
    (ctxt, @selector(DPScurrentgcdrawablecolor:::::), gc, draw, x, y, colorInfo);
}

static inline void
DPScurrentoffset(GSCTXT *ctxt, int *x, int *y)
{
  (ctxt->methods->DPScurrentoffset__)
    (ctxt, @selector(DPScurrentoffset::), x, y);
}

static inline void
DPSsetdrawingfunction(GSCTXT *ctxt, int function)
{
  (ctxt->methods->DPSsetdrawingfunction_)
    (ctxt, @selector(DPSsetdrawingfunction:), function);
}

static inline void
DPSsetgcdrawable(GSCTXT *ctxt, void* gc, void* draw, int x, int y)
{
  (ctxt->methods->DPSsetgcdrawable____)
    (ctxt, @selector(DPSsetgcdrawable::::), gc, draw, x, y);
}

static inline void
DPSsetgcdrawablecolor(GSCTXT *ctxt, void* gc, void* draw, int x, int y, const int colorInfo[])
{
  (ctxt->methods->DPSsetgcdrawablecolor_____)
    (ctxt, @selector(DPSsetgcdrawablecolor:::::), gc, draw, x, y, colorInfo);
}

static inline void
DPSsetoffset(GSCTXT *ctxt, short int x, short int y)
{
  (ctxt->methods->DPSsetoffset__)
    (ctxt, @selector(DPSsetoffset::), x, y);
}

static inline void
DPSsetrgbactual(GSCTXT *ctxt, double r, double g, double b, int *success)
{
  (ctxt->methods->DPSsetrgbactual____)
    (ctxt, @selector(DPSsetrgbactual::::), r, g, b, success);
}

static inline void
DPScapturegstate(GSCTXT *ctxt, int *gst)
{
  (ctxt->methods->DPScapturegstate_)
    (ctxt, @selector(DPScapturegstate:), gst);
}

/* ----------------------------------------------------------------------- */
/* GNUstep Event and other I/O extensions */
/* ----------------------------------------------------------------------- */
static inline NSEvent*
DPSGetEventMatchingMaskBeforeDateInModeDequeue(GSCTXT *ctxt, unsigned mask, NSDate* limit, NSString *mode, BOOL dequeue)
{
  return (ctxt->methods->DPSGetEventMatchingMask_beforeDate_inMode_dequeue_)
    (ctxt, @selector(DPSGetEventMatchingMask:beforeDate:inMode:dequeue:),
    mask, limit, mode, dequeue);
}

static inline void
DPSDiscardEventsMatchingMaskBeforeEvent(GSCTXT *ctxt, unsigned mask, NSEvent* limit)
{
  (ctxt->methods->DPSDiscardEventsMatchingMask_beforeEvent_)
    (ctxt, @selector(DPSDiscardEventsMatchingMask:beforeEvent:), mask, limit);
}

static inline void
DPSPostEventAtStart(GSCTXT *ctxt, NSEvent* anEvent, BOOL atStart)
{
  (ctxt->methods->DPSPostEvent_atStart_)
    (ctxt, @selector(DPSPostEvent:atStart:), anEvent, atStart);
}

#endif	
