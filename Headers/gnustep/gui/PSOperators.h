/* PSOperators.h - Drawing engine operators that use default context

   Copyright (C) 1999 Free Software Foundation, Inc.
   Written by:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
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

#ifndef _PSOperators_h_INCLUDE
#define _PSOperators_h_INCLUDE

#include <AppKit/DPSOperators.h>

#ifndef NO_GNUSTEP
#define	DEFCTXT	GSCurrentContext()
#else
#define	DEFCTXT	[NSGraphicsContext currentContext]
#endif

/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */
static inline void
PScurrentcmykcolor(float *c, float *m, float *y, float *k)
__attribute__((unused));

static inline void
PSsetcmykcolor(float c, float m, float y, float k)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Data operations */
/* ----------------------------------------------------------------------- */
static inline void
PSclear()
__attribute__((unused));

static inline void
PScleartomark()
__attribute__((unused));

static inline void
PScopy(int n)
__attribute__((unused));

static inline void
PScount(int *n)
__attribute__((unused));

static inline void
PScounttomark(int *n)
__attribute__((unused));

static inline void
PSdup()
__attribute__((unused));

static inline void
PSexch()
__attribute__((unused));

static inline void
PSexecstack()
__attribute__((unused));

static inline void
PSget()
__attribute__((unused));

static inline void
PSindex(int i)
__attribute__((unused));

static inline void
PSmark()
__attribute__((unused));

static inline void
PSmatrix()
__attribute__((unused));

static inline void
PSnull()
__attribute__((unused));

static inline void
PSpop()
__attribute__((unused));

static inline void
PSput()
__attribute__((unused));

static inline void
PSroll(int n, int j)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */
static inline void
PSFontDirectory()
__attribute__((unused));

static inline void
PSISOLatin1Encoding()
__attribute__((unused));

static inline void
PSSharedFontDirectory()
__attribute__((unused));

static inline void
PSStandardEncoding()
__attribute__((unused));

static inline void
PScurrentcacheparams()
__attribute__((unused));

static inline void
PScurrentfont()
__attribute__((unused));

static inline void
PSdefinefont()
__attribute__((unused));

static inline void
PSfindfont(const char *name)
__attribute__((unused));

static inline void
PSmakefont()
__attribute__((unused));

static inline void
PSscalefont(float size)
__attribute__((unused));

static inline void
PSselectfont(const char *name, float scale)
__attribute__((unused));

static inline void
PSsetfont(int f)
__attribute__((unused));

static inline void
PSundefinefont(const char *name)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */
static inline void
PSconcat(const float m[])
__attribute__((unused));

static inline void
PScurrentdash()
__attribute__((unused));

static inline void
PScurrentflat(float *flatness)
__attribute__((unused));

static inline void
PScurrentgray(float *gray)
__attribute__((unused));

static inline void
PScurrentgstate(int gst)
__attribute__((unused));

static inline void
PScurrenthalftone()
__attribute__((unused));

static inline void
PScurrenthalftonephase(float *x, float *y)
__attribute__((unused));

static inline void
PScurrenthsbcolor(float *h, float *s, float *b)
__attribute__((unused));

static inline void
PScurrentlinecap(int *linecap)
__attribute__((unused));

static inline void
PScurrentlinejoin(int *linejoin)
__attribute__((unused));

static inline void
PScurrentlinewidth(float *width)
__attribute__((unused));

static inline void
PScurrentmatrix()
__attribute__((unused));

static inline void
PScurrentmiterlimit(float *limit)
__attribute__((unused));

static inline void
PScurrentpoint(float *x, float *y)
__attribute__((unused));

static inline void
PScurrentrgbcolor(float *r, float *g, float *b)
__attribute__((unused));

static inline void
PScurrentscreen()
__attribute__((unused));

static inline void
PScurrentstrokeadjust(int *b)
__attribute__((unused));

static inline void
PScurrenttransfer()
__attribute__((unused));

static inline void
PSdefaultmatrix()
__attribute__((unused));

static inline void
PSgrestore()
__attribute__((unused));

static inline void
PSgrestoreall()
__attribute__((unused));

static inline void
PSgsave()
__attribute__((unused));

static inline void
PSgstate()
__attribute__((unused));

static inline void
PSinitgraphics()
__attribute__((unused));

static inline void
PSinitmatrix()
__attribute__((unused));

static inline void
PSrotate(float angle)
__attribute__((unused));

static inline void
PSscale(float x, float y)
__attribute__((unused));

static inline void
PSsetdash(const float pat[], int size, float offset)
__attribute__((unused));

static inline void
PSsetflat(float flatness)
__attribute__((unused));

static inline void
PSsetgray(float gray)
__attribute__((unused));

static inline void
PSsetgstate(int gst)
__attribute__((unused));

static inline void
PSsethalftone()
__attribute__((unused));

static inline void
PSsethalftonephase(float x, float y)
__attribute__((unused));

static inline void
PSsethsbcolor(float h, float s, float b)
__attribute__((unused));

static inline void
PSsetlinecap(int linecap)
__attribute__((unused));

static inline void
PSsetlinejoin(int linejoin)
__attribute__((unused));

static inline void
PSsetlinewidth(float width)
__attribute__((unused));

static inline void
PSsetmatrix()
__attribute__((unused));

static inline void
PSsetmiterlimit(float limit)
__attribute__((unused));

static inline void
PSsetrgbcolor(float r, float g, float b)
__attribute__((unused));

static inline void
PSsetscreen()
__attribute__((unused));

static inline void
PSsetstrokeadjust(int b)
__attribute__((unused));

static inline void
PSsettransfer()
__attribute__((unused));

static inline void
PStranslate(float x, float y)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* I/O Operations operations */
/* ----------------------------------------------------------------------- */
static inline void
PSflush()
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
static inline void
PSconcatmatrix()
__attribute__((unused));

static inline void
PSdtransform(float x1, float y1, float *x2, float *y2)
__attribute__((unused));

static inline void
PSidentmatrix()
__attribute__((unused));

static inline void
PSidtransform(float x1, float y1, float *x2, float *y2)
__attribute__((unused));

static inline void
PSinvertmatrix()
__attribute__((unused));

static inline void
PSitransform(float x1, float y1, float *x2, float *y2)
__attribute__((unused));

static inline void
PStransform(float x1, float y1, float *x2, float *y2)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Opstack operations */
/* ----------------------------------------------------------------------- */
static inline void
PSgetboolean(int *it)
__attribute__((unused));

static inline void
PSgetchararray(int size, char s[])
__attribute__((unused));

static inline void
PSgetfloat(float *it)
__attribute__((unused));

static inline void
PSgetfloatarray(int size, float a[])
__attribute__((unused));

static inline void
PSgetint(int *it)
__attribute__((unused));

static inline void
PSgetintarray(int size, int a[])
__attribute__((unused));

static inline void
PSgetstring(char *s)
__attribute__((unused));

static inline void
PSsendboolean(int it)
__attribute__((unused));

static inline void
PSsendchararray(const char s[], int size)
__attribute__((unused));

static inline void
PSsendfloat(float it)
__attribute__((unused));

static inline void
PSsendfloatarray(const float a[], int size)
__attribute__((unused));

static inline void
PSsendint(int it)
__attribute__((unused));

static inline void
PSsendintarray(const int a[], int size)
__attribute__((unused));

static inline void
PSsendstring(const char *s)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */
static inline void
PSashow(float x, float y, const char *s)
__attribute__((unused));

static inline void
PSawidthshow(float cx, float cy, int c, float ax, float ay, const char *s)
__attribute__((unused));

static inline void
PScopypage()
__attribute__((unused));

static inline void
PSeofill()
__attribute__((unused));

static inline void
PSerasepage()
__attribute__((unused));

static inline void
PSfill()
__attribute__((unused));

static inline void
PSimage()
__attribute__((unused));

static inline void
PSimagemask()
__attribute__((unused));

static inline void
PSkshow(const char *s)
__attribute__((unused));

static inline void
PSrectfill(float x, float y, float w, float h)
__attribute__((unused));

static inline void
PSrectstroke(float x, float y, float w, float h)
__attribute__((unused));

static inline void
PSshow(const char *s)
__attribute__((unused));

static inline void
PSshowpage()
__attribute__((unused));

static inline void
PSstroke()
__attribute__((unused));

static inline void
PSstrokepath()
__attribute__((unused));

static inline void
PSueofill(const char nums[], int n, const char ops[], int l)
__attribute__((unused));

static inline void
PSufill(const char nums[], int n, const char ops[], int l)
__attribute__((unused));

static inline void
PSustroke(const char nums[], int n, const char ops[], int l)
__attribute__((unused));

static inline void
PSustrokepath(const char nums[], int n, const char ops[], int l)
__attribute__((unused));

static inline void
PSwidthshow(float x, float y, int c, const char *s)
__attribute__((unused));

static inline void
PSxshow(const char *s, const float numarray[], int size)
__attribute__((unused));

static inline void
PSxyshow(const char *s, const float numarray[], int size)
__attribute__((unused));

static inline void
PSyshow(const char *s, const float numarray[], int size)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */
static inline void
PSarc(float x, float y, float r, float angle1, float angle2)
__attribute__((unused));

static inline void
PSarcn(float x, float y, float r, float angle1, float angle2)
__attribute__((unused));

static inline void
PSarct(float x1, float y1, float x2, float y2, float r)
__attribute__((unused));

static inline void
PSarcto(float x1, float y1, float x2, float y2, float r, float *xt1, float *yt1, float *xt2, float *yt2)
__attribute__((unused));

static inline void
PScharpath(const char *s, int b)
__attribute__((unused));

static inline void
PSclip()
__attribute__((unused));

static inline void
PSclippath()
__attribute__((unused));

static inline void
PSclosepath()
__attribute__((unused));

static inline void
PScurveto(float x1, float y1, float x2, float y2, float x3, float y3)
__attribute__((unused));

static inline void
PSeoclip()
__attribute__((unused));

static inline void
PSeoviewclip()
__attribute__((unused));

static inline void
PSflattenpath()
__attribute__((unused));

static inline void
PSinitclip()
__attribute__((unused));

static inline void
PSinitviewclip()
__attribute__((unused));

static inline void
PSlineto(float x, float y)
__attribute__((unused));

static inline void
PSmoveto(float x, float y)
__attribute__((unused));

static inline void
PSnewpath()
__attribute__((unused));

static inline void
PSpathbbox(float *llx, float *lly, float *urx, float *ury)
__attribute__((unused));

static inline void
PSpathforall()
__attribute__((unused));

static inline void
PSrcurveto(float x1, float y1, float x2, float y2, float x3, float y3)
__attribute__((unused));

static inline void
PSrectclip(float x, float y, float w, float h)
__attribute__((unused));

static inline void
PSrectviewclip(float x, float y, float w, float h)
__attribute__((unused));

static inline void
PSreversepath()
__attribute__((unused));

static inline void
PSrlineto(float x, float y)
__attribute__((unused));

static inline void
PSrmoveto(float x, float y)
__attribute__((unused));

static inline void
PSsetbbox(float llx, float lly, float urx, float ury)
__attribute__((unused));

static inline void
PSviewclip()
__attribute__((unused));

static inline void
PSviewclippath()
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Window system ops */
/* ----------------------------------------------------------------------- */
static inline void
PScurrentdrawingfunction(int *function)
__attribute__((unused));

static inline void
PScurrentgcdrawable(void* *gc, void* *draw, int *x, int *y)
__attribute__((unused));

static inline void
PScurrentgcdrawablecolor(void* *gc, void* *draw, int *x, int *y, int colorInfo[])
__attribute__((unused));

static inline void
PScurrentoffset(int *x, int *y)
__attribute__((unused));

static inline void
PSsetdrawingfunction(int function)
__attribute__((unused));

static inline void
PSsetgcdrawable(void* gc, void* draw, int x, int y)
__attribute__((unused));

static inline void
PSsetgcdrawablecolor(void* gc, void* draw, int x, int y, const int colorInfo[])
__attribute__((unused));

static inline void
PSsetoffset(short int x, short int y)
__attribute__((unused));

static inline void
PSsetrgbactual(double r, double g, double b, int *success)
__attribute__((unused));

static inline void
PScapturegstate(int *gst)
__attribute__((unused));

/*-------------------------------------------------------------------------*/
/* Graphics Extension Ops */
/*-------------------------------------------------------------------------*/

static inline void 
PScomposite(float x, float y, float w, float h, int gstateNum, float dx, float dy, int op)
__attribute__((unused));

static inline void 
PScompositerect(float x, float y, float w, float h, int op)
__attribute__((unused));

static inline void 
PSdissolve(float x, float y, float w, float h, int gstateNum, float dx, float dy, float delta)
__attribute__((unused));

static inline void 
PSreadimage( void )
__attribute__((unused));

static inline void 
PSsetalpha(float a)
__attribute__((unused));

static inline void 
PScurrentalpha(float *a)
__attribute__((unused));

/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */
static inline void
PScurrentcmykcolor(float *c, float *m, float *y, float *k)
{
  DPScurrentcmykcolor(DEFCTXT, c, m, y, k);
}

static inline void
PSsetcmykcolor(float c, float m, float y, float k)
{
  DPSsetcmykcolor(DEFCTXT, c, m, y, k);
}

/* ----------------------------------------------------------------------- */
/* Data operations */
/* ----------------------------------------------------------------------- */
static inline void
PSclear()
{
  DPSclear(DEFCTXT);
}

static inline void
PScleartomark()
{
  DPScleartomark(DEFCTXT);
}

static inline void
PScopy(int n)
{
  DPScopy(DEFCTXT, n);
}

static inline void
PScount(int *n)
{
  DPScount(DEFCTXT, n);
}

static inline void
PScounttomark(int *n)
{
  DPScounttomark(DEFCTXT, n);
}

static inline void
PSdup()
{
  DPSdup(DEFCTXT);
}

static inline void
PSexch()
{
  DPSexch(DEFCTXT);
}

static inline void
PSexecstack()
{
  DPSexecstack(DEFCTXT);
}

static inline void
PSget()
{
  DPSget(DEFCTXT);
}

static inline void
PSindex(int i)
{
  DPSindex(DEFCTXT, i);
}

static inline void
PSmark()
{
  DPSmark(DEFCTXT);
}

static inline void
PSmatrix()
{
  DPSmatrix(DEFCTXT);
}

static inline void
PSnull()
{
  DPSnull(DEFCTXT);
}

static inline void
PSpop()
{
  DPSpop(DEFCTXT);
}

static inline void
PSput()
{
  DPSput(DEFCTXT);
}

static inline void
PSroll(int n, int j)
{
  DPSroll(DEFCTXT, n, j);
}

/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */
static inline void
PSFontDirectory()
{
  DPSFontDirectory(DEFCTXT);
}

static inline void
PSISOLatin1Encoding()
{
  DPSISOLatin1Encoding(DEFCTXT);
}

static inline void
PSSharedFontDirectory()
{
  DPSSharedFontDirectory(DEFCTXT);
}

static inline void
PSStandardEncoding()
{
  DPSStandardEncoding(DEFCTXT);
}

static inline void
PScurrentcacheparams()
{
  DPScurrentcacheparams(DEFCTXT);
}

static inline void
PScurrentfont()
{
  DPScurrentfont(DEFCTXT);
}

static inline void
PSdefinefont()
{
  DPSdefinefont(DEFCTXT);
}

static inline void
PSfindfont(const char *name)
{
  DPSfindfont(DEFCTXT, name);
}

static inline void
PSmakefont()
{
  DPSmakefont(DEFCTXT);
}

static inline void
PSscalefont(float size)
{
  DPSscalefont(DEFCTXT, size);
}

static inline void
PSselectfont(const char *name, float scale)
{
  DPSselectfont(DEFCTXT, name, scale);
}

static inline void
PSsetfont(int f)
{
  DPSsetfont(DEFCTXT, f);
}

static inline void
PSundefinefont(const char *name)
{
  DPSundefinefont(DEFCTXT, name);
}

/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */
static inline void
PSconcat(const float m[])
{
  DPSconcat(DEFCTXT, m);
}

static inline void
PScurrentdash()
{
  DPScurrentdash(DEFCTXT);
}

static inline void
PScurrentflat(float *flatness)
{
  DPScurrentflat(DEFCTXT, flatness);
}

static inline void
PScurrentgray(float *gray)
{
  DPScurrentgray(DEFCTXT, gray);
}

static inline void
PScurrentgstate(int gst)
{
  DPScurrentgstate(DEFCTXT, gst);
}

static inline void
PScurrenthalftone()
{
  DPScurrenthalftone(DEFCTXT);
}

static inline void
PScurrenthalftonephase(float *x, float *y)
{
  DPScurrenthalftonephase(DEFCTXT, x, y);
}

static inline void
PScurrenthsbcolor(float *h, float *s, float *b)
{
  DPScurrenthsbcolor(DEFCTXT, h, s, b);
}

static inline void
PScurrentlinecap(int *linecap)
{
  DPScurrentlinecap(DEFCTXT, linecap);
}

static inline void
PScurrentlinejoin(int *linejoin)
{
  DPScurrentlinejoin(DEFCTXT, linejoin);
}

static inline void
PScurrentlinewidth(float *width)
{
  DPScurrentlinewidth(DEFCTXT, width);
}

static inline void
PScurrentmatrix()
{
  DPScurrentmatrix(DEFCTXT);
}

static inline void
PScurrentmiterlimit(float *limit)
{
  DPScurrentmiterlimit(DEFCTXT, limit);
}

static inline void
PScurrentpoint(float *x, float *y)
{
  DPScurrentpoint(DEFCTXT, x, y);
}

static inline void
PScurrentrgbcolor(float *r, float *g, float *b)
{
  DPScurrentrgbcolor(DEFCTXT, r, g, b);
}

static inline void
PScurrentscreen()
{
  DPScurrentscreen(DEFCTXT);
}

static inline void
PScurrentstrokeadjust(int *b)
{
  DPScurrentstrokeadjust(DEFCTXT, b);
}

static inline void
PScurrenttransfer()
{
  DPScurrenttransfer(DEFCTXT);
}

static inline void
PSdefaultmatrix()
{
  DPSdefaultmatrix(DEFCTXT);
}

static inline void
PSgrestore()
{
  DPSgrestore(DEFCTXT);
}

static inline void
PSgrestoreall()
{
  DPSgrestoreall(DEFCTXT);
}

static inline void
PSgsave()
{
  DPSgsave(DEFCTXT);
}

static inline void
PSgstate()
{
  DPSgstate(DEFCTXT);
}

static inline void
PSinitgraphics()
{
  DPSinitgraphics(DEFCTXT);
}

static inline void
PSinitmatrix()
{
  DPSinitmatrix(DEFCTXT);
}

static inline void
PSrotate(float angle)
{
  DPSrotate(DEFCTXT, angle);
}

static inline void
PSscale(float x, float y)
{
  DPSscale(DEFCTXT, x, y);
}

static inline void
PSsetdash(const float pat[], int size, float offset)
{
  DPSsetdash(DEFCTXT, pat, size, offset);
}

static inline void
PSsetflat(float flatness)
{
  DPSsetflat(DEFCTXT, flatness);
}

static inline void
PSsetgray(float gray)
{
  DPSsetgray(DEFCTXT, gray);
}

static inline void
PSsetgstate(int gst)
{
  DPSsetgstate(DEFCTXT, gst);
}

static inline void
PSsethalftone()
{
  DPSsethalftone(DEFCTXT);
}

static inline void
PSsethalftonephase(float x, float y)
{
  DPSsethalftonephase(DEFCTXT, x, y);
}

static inline void
PSsethsbcolor(float h, float s, float b)
{
  DPSsethsbcolor(DEFCTXT, h, s, b);
}

static inline void
PSsetlinecap(int linecap)
{
  DPSsetlinecap(DEFCTXT, linecap);
}

static inline void
PSsetlinejoin(int linejoin)
{
  DPSsetlinejoin(DEFCTXT, linejoin);
}

static inline void
PSsetlinewidth(float width)
{
  DPSsetlinewidth(DEFCTXT, width);
}

static inline void
PSsetmatrix()
{
  DPSsetmatrix(DEFCTXT);
}

static inline void
PSsetmiterlimit(float limit)
{
  DPSsetmiterlimit(DEFCTXT, limit);
}

static inline void
PSsetrgbcolor(float r, float g, float b)
{
  DPSsetrgbcolor(DEFCTXT, r, g, b);
}

static inline void
PSsetscreen()
{
  DPSsetscreen(DEFCTXT);
}

static inline void
PSsetstrokeadjust(int b)
{
  DPSsetstrokeadjust(DEFCTXT, b);
}

static inline void
PSsettransfer()
{
  DPSsettransfer(DEFCTXT);
}

static inline void
PStranslate(float x, float y)
{
  DPStranslate(DEFCTXT, x, y);
}

/* ----------------------------------------------------------------------- */
/* I/O Operations operations */
/* ----------------------------------------------------------------------- */
static inline void
PSflush()
{
  DPSflush(DEFCTXT);
}

/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */
static inline void
PSconcatmatrix()
{
  DPSconcatmatrix(DEFCTXT);
}

static inline void
PSdtransform(float x1, float y1, float *x2, float *y2)
{
  DPSdtransform(DEFCTXT, x1, y1, x2, y2);
}

static inline void
PSidentmatrix()
{
  DPSidentmatrix(DEFCTXT);
}

static inline void
PSidtransform(float x1, float y1, float *x2, float *y2)
{
  DPSidtransform(DEFCTXT, x1, y1, x2, y2);
}

static inline void
PSinvertmatrix()
{
  DPSinvertmatrix(DEFCTXT);
}

static inline void
PSitransform(float x1, float y1, float *x2, float *y2)
{
  DPSitransform(DEFCTXT, x1, y1, x2, y2);
}

static inline void
PStransform(float x1, float y1, float *x2, float *y2)
{
  DPStransform(DEFCTXT, x1, y1, x2, y2);
}

/* ----------------------------------------------------------------------- */
/* Opstack operations */
/* ----------------------------------------------------------------------- */
static inline void
PSgetboolean(int *it)
{
  DPSgetboolean(DEFCTXT, it);
}

static inline void
PSgetchararray(int size, char s[])
{
  DPSgetchararray(DEFCTXT, size, s);
}

static inline void
PSgetfloat(float *it)
{
  DPSgetfloat(DEFCTXT, it);
}

static inline void
PSgetfloatarray(int size, float a[])
{
  DPSgetfloatarray(DEFCTXT, size, a);
}

static inline void
PSgetint(int *it)
{
  DPSgetint(DEFCTXT, it);
}

static inline void
PSgetintarray(int size, int a[])
{
  DPSgetintarray(DEFCTXT, size, a);
}

static inline void
PSgetstring(char *s)
{
  DPSgetstring(DEFCTXT, s);
}

static inline void
PSsendboolean(int it)
{
  DPSsendboolean(DEFCTXT, it);
}

static inline void
PSsendchararray(const char s[], int size)
{
  DPSsendchararray(DEFCTXT, s, size);
}

static inline void
PSsendfloat(float it)
{
  DPSsendfloat(DEFCTXT, it);
}

static inline void
PSsendfloatarray(const float a[], int size)
{
  DPSsendfloatarray(DEFCTXT, a, size);
}

static inline void
PSsendint(int it)
{
  DPSsendint(DEFCTXT, it);
}

static inline void
PSsendintarray(const int a[], int size)
{
  DPSsendintarray(DEFCTXT, a, size);
}

static inline void
PSsendstring(const char *s)
{
  DPSsendstring(DEFCTXT, s);
}

/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */
static inline void
PSashow(float x, float y, const char *s)
{
  DPSashow(DEFCTXT, x, y, s);
}

static inline void
PSawidthshow(float cx, float cy, int c, float ax, float ay, const char *s)
{
  DPSawidthshow(DEFCTXT, cx, cy, c, ax, ay, s);
}

static inline void
PScopypage()
{
  DPScopypage(DEFCTXT);
}

static inline void
PSeofill()
{
  DPSeofill(DEFCTXT);
}

static inline void
PSerasepage()
{
  DPSerasepage(DEFCTXT);
}

static inline void
PSfill()
{
  DPSfill(DEFCTXT);
}

static inline void
PSimage()
{
  DPSimage(DEFCTXT);
}

static inline void
PSimagemask()
{
  DPSimagemask(DEFCTXT);
}

static inline void
PSkshow(const char *s)
{
  DPSkshow(DEFCTXT, s);
}

static inline void
PSrectfill(float x, float y, float w, float h)
{
  DPSrectfill(DEFCTXT, x, y, w, h);
}

static inline void
PSrectstroke(float x, float y, float w, float h)
{
  DPSrectstroke(DEFCTXT, x, y, w, h);
}

static inline void
PSshow(const char *s)
{
  DPSshow(DEFCTXT, s);
}

static inline void
PSshowpage()
{
  DPSshowpage(DEFCTXT);
}

static inline void
PSstroke()
{
  DPSstroke(DEFCTXT);
}

static inline void
PSstrokepath()
{
  DPSstrokepath(DEFCTXT);
}

static inline void
PSueofill(const char nums[], int n, const char ops[], int l)
{
  DPSueofill(DEFCTXT, nums, n, ops, l);
}

static inline void
PSufill(const char nums[], int n, const char ops[], int l)
{
  DPSufill(DEFCTXT, nums, n, ops, l);
}

static inline void
PSustroke(const char nums[], int n, const char ops[], int l)
{
  DPSustroke(DEFCTXT, nums, n, ops, l);
}

static inline void
PSustrokepath(const char nums[], int n, const char ops[], int l)
{
  DPSustrokepath(DEFCTXT, nums, n, ops, l);
}

static inline void
PSwidthshow(float x, float y, int c, const char *s)
{
  DPSwidthshow(DEFCTXT, x, y, c, s);
}

static inline void
PSxshow(const char *s, const float numarray[], int size)
{
  DPSxshow(DEFCTXT, s, numarray, size);
}

static inline void
PSxyshow(const char *s, const float numarray[], int size)
{
  DPSxyshow(DEFCTXT, s, numarray, size);
}

static inline void
PSyshow(const char *s, const float numarray[], int size)
{
  DPSyshow(DEFCTXT, s, numarray, size);
}

/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */
static inline void
PSarc(float x, float y, float r, float angle1, float angle2)
{
  DPSarc(DEFCTXT, x, y, r, angle1, angle2);
}

static inline void
PSarcn(float x, float y, float r, float angle1, float angle2)
{
  DPSarcn(DEFCTXT, x, y, r, angle1, angle2);
}

static inline void
PSarct(float x1, float y1, float x2, float y2, float r)
{
  DPSarct(DEFCTXT, x1, y1, x2, y2, r);
}

static inline void
PSarcto(float x1, float y1, float x2, float y2, float r, float *xt1, float *yt1, float *xt2, float *yt2)
{
  DPSarcto(DEFCTXT, x1, y1, x2, y2, r, xt1, yt1, xt2, yt2);
}

static inline void
PScharpath(const char *s, int b)
{
  DPScharpath(DEFCTXT, s, b);
}

static inline void
PSclip()
{
  DPSclip(DEFCTXT);
}

static inline void
PSclippath()
{
  DPSclippath(DEFCTXT);
}

static inline void
PSclosepath()
{
  DPSclosepath(DEFCTXT);
}

static inline void
PScurveto(float x1, float y1, float x2, float y2, float x3, float y3)
{
  DPScurveto(DEFCTXT, x1, y1, x2, y2, x3, y3);
}

static inline void
PSeoclip()
{
  DPSeoclip(DEFCTXT);
}

static inline void
PSeoviewclip()
{
  DPSeoviewclip(DEFCTXT);
}

static inline void
PSflattenpath()
{
  DPSflattenpath(DEFCTXT);
}

static inline void
PSinitclip()
{
  DPSinitclip(DEFCTXT);
}

static inline void
PSinitviewclip()
{
  DPSinitviewclip(DEFCTXT);
}

static inline void
PSlineto(float x, float y)
{
  DPSlineto(DEFCTXT, x, y);
}

static inline void
PSmoveto(float x, float y)
{
  DPSmoveto(DEFCTXT, x, y);
}

static inline void
PSnewpath()
{
  DPSnewpath(DEFCTXT);
}

static inline void
PSpathbbox(float *llx, float *lly, float *urx, float *ury)
{
  DPSpathbbox(DEFCTXT, llx, lly, urx, ury);
}

static inline void
PSpathforall()
{
  DPSpathforall(DEFCTXT);
}

static inline void
PSrcurveto(float x1, float y1, float x2, float y2, float x3, float y3)
{
  DPSrcurveto(DEFCTXT, x1, y1, x2, y2, x3, y3);
}

static inline void
PSrectclip(float x, float y, float w, float h)
{
  DPSrectclip(DEFCTXT, x, y, w, h);
}

static inline void
PSrectviewclip(float x, float y, float w, float h)
{
  DPSrectviewclip(DEFCTXT, x, y, w, h);
}

static inline void
PSreversepath()
{
  DPSreversepath(DEFCTXT);
}

static inline void
PSrlineto(float x, float y)
{
  DPSrlineto(DEFCTXT, x, y);
}

static inline void
PSrmoveto(float x, float y)
{
  DPSrmoveto(DEFCTXT, x, y);
}

static inline void
PSsetbbox(float llx, float lly, float urx, float ury)
{
  DPSsetbbox(DEFCTXT, llx, lly, urx, ury);
}

static inline void
PSviewclip()
{
  DPSviewclip(DEFCTXT);
}

static inline void
PSviewclippath()
{
  DPSviewclippath(DEFCTXT);
}

/* ----------------------------------------------------------------------- */
/* Window system ops */
/* ----------------------------------------------------------------------- */
static inline void
PScurrentdrawingfunction(int *function)
{
  DPScurrentdrawingfunction(DEFCTXT, function);
}

static inline void
PScurrentgcdrawable(void* *gc, void* *draw, int *x, int *y)
{
  DPScurrentgcdrawable(DEFCTXT, gc, draw, x, y);
}

static inline void
PScurrentgcdrawablecolor(void* *gc, void* *draw, int *x, int *y, int colorInfo[])
{
  DPScurrentgcdrawablecolor(DEFCTXT, gc, draw, x, y, colorInfo);
}

static inline void
PScurrentoffset(int *x, int *y)
{
  DPScurrentoffset(DEFCTXT, x, y);
}

static inline void
PSsetdrawingfunction(int function)
{
  DPSsetdrawingfunction(DEFCTXT, function);
}

static inline void
PSsetgcdrawable(void* gc, void* draw, int x, int y)
{
  DPSsetgcdrawable(DEFCTXT, gc, draw, x, y);
}

static inline void
PSsetgcdrawablecolor(void* gc, void* draw, int x, int y, const int colorInfo[])
{
  DPSsetgcdrawablecolor(DEFCTXT, gc, draw, x, y, colorInfo);
}

static inline void
PSsetoffset(short int x, short int y)
{
  DPSsetoffset(DEFCTXT, x, y);
}

static inline void
PSsetrgbactual(double r, double g, double b, int *success)
{
  DPSsetrgbactual(DEFCTXT, r, g, b, success);
}

static inline void
PScapturegstate(int *gst)
{
  DPScapturegstate(DEFCTXT, gst);
}

/*-------------------------------------------------------------------------*/
/* Graphics Extension Ops */
/*-------------------------------------------------------------------------*/

static inline void 
PScomposite(float x, float y, float w, float h, int gstateNum, float dx, float dy, int op)
{
  DPScomposite(DEFCTXT, x, y, w, h, gstateNum, dx, dy, op);
}

static inline void 
PScompositerect(float x, float y, float w, float h, int op)
{
  DPScompositerect(DEFCTXT, x, y, w, h, op);
}

static inline void 
PSdissolve(float x, float y, float w, float h, int gstateNum, float dx, float dy, float delta)
{
  DPSdissolve(DEFCTXT, x, y, w, h, gstateNum, dx, dy, delta);
}

static inline void 
PSreadimage( void )
{
  DPSreadimage(DEFCTXT);
}

static inline void 
PSsetalpha(float a)
{
  DPSsetalpha(DEFCTXT, a);
}

static inline void 
PScurrentalpha(float *a)
{
  DPScurrentalpha(DEFCTXT, a);
}

/* ----------------------------------------------------------------------- */
/* GNUstep Event and other I/O extensions */
/* ----------------------------------------------------------------------- */
static inline NSEvent*
PSGetEvent(unsigned mask, NSDate* limit, NSString *mode)
{
  return DPSGetEvent(DEFCTXT, mask, limit, mode);
}

static inline NSEvent*
PSPeekEvent(unsigned mask, NSDate* limit, NSString *mode)
{
  return DPSPeekEvent(DEFCTXT, mask, limit, mode);
}

static inline void
PSDiscardEvents(unsigned mask, NSEvent* limit)
{
  DPSDiscardEvents(DEFCTXT, mask, limit);
}

static inline void
PSPostEvent(NSEvent* anEvent, BOOL atStart)
{
  DPSPostEvent(DEFCTXT, anEvent, atStart);
}

#endif	
