/* gpsops - PostScript operators and mappings to current context

   Copyright (C) 1995 Free Software Foundation, Inc.

   Written by:  Adam Fedor <fedor@gnu.org>
   Date: Nov 1998
   
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

#include "AppKit/GPSDrawContext.h"

/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */

void GScolorimage( void )
{
  [_currentGPSContext DPScolorimage];
}

void GScurrentblackgeneration( void )
{
  [_currentGPSContext DPScurrentblackgeneration];
}


void GScurrentcmykcolor(float *c, float *m, float *y, float *k)
{
  [_currentGPSContext DPScurrentcmykcolor:c :m :y :k];
}

void GScurrentcolorscreen( void )
{
  [_currentGPSContext DPScurrentcolorscreen];
}

void GScurrentcolortransfer( void )
{
  [_currentGPSContext DPScurrentcolortransfer];
}

void GScurrentundercolorremoval( void )
{
  [_currentGPSContext DPScurrentundercolorremoval];
}

void GSsetblackgeneration( void )
{
  [_currentGPSContext DPSsetblackgeneration];
}

void GSsetcmykcolor(float c, float m, float y, float k)
{
  [_currentGPSContext DPSsetcmykcolor: c : m : y : k];
}

void GSsetcolorscreen( void )
{
  [_currentGPSContext DPSsetcolorscreen];
}

void GSsetcolortransfer( void )
{
  [_currentGPSContext DPSsetcolortransfer];
}

void GSsetundercolorremoval( void )
{
  [_currentGPSContext DPSsetundercolorremoval];
}

/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */

void GSFontDirectory( void )
{
  [_currentGPSContext DPSFontDirectory];
}

void GSISOLatin1Encoding( void )
{
  [_currentGPSContext DPSISOLatin1Encoding];
}

void GSSharedFontDirectory( void )
{
  [_currentGPSContext DPSSharedFontDirectory];
}

void GSStandardEncoding( void )
{
  [_currentGPSContext DPSStandardEncoding];
}

void GScachestatus(int *bsize, int *bmax, int *msize)
{
  [_currentGPSContext DPScachestatus: bsize : bmax : msize];
}

void GScurrentcacheparams( void )
{
  [_currentGPSContext DPScurrentcacheparams];
}

void GScurrentfont( void )
{
  [_currentGPSContext DPScurrentfont];
}

void GSdefinefont( void )
{
  [_currentGPSContext DPSdefinefont];
}

void GSfindfont(const char *name)
{
  [_currentGPSContext DPSfindfont: name];
}

void GSmakefont( void )
{
  [_currentGPSContext DPSmakefont];
}

void GSscalefont(float size)
{
  [_currentGPSContext DPSscalefont: size];
}

void GSselectfont(const char *name, float scale)
{
  [_currentGPSContext DPSselectfont: name : scale];
}

void GSsetcachedevice(float wx, float wy, float llx, float lly, float urx, float ury)
{
  [_currentGPSContext DPSsetcachedevice: wy : wy : lly : lly : urx : ury];
}

void GSsetcachelimit(float n)
{
  [_currentGPSContext DPSsetcachelimit: n];
}

void GSsetcacheparams( void )
{
  [_currentGPSContext DPSsetcacheparams];
}

void GSsetcharwidth(float wx, float wy)
{
  [_currentGPSContext DPSsetcharwidth: wx : wy];
}

void GSsetfont(int f)
{
  [_currentGPSContext DPSsetfont: f];
}

void GSundefinefont(const char *name)
{
  [_currentGPSContext DPSundefinefont: name];
}

/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */

void 
GSconcat(const float m[])
{
  [_currentGPSContext DPSconcat: m];
}

void 
GScurrentdash( void )
{
  [_currentGPSContext DPScurrentdash];
}

void GScurrentflat(float *flatness)
{
  [_currentGPSContext DPScurrentflat: flatness];
}

void GScurrentgray(float *gray)
{
  [_currentGPSContext DPScurrentgray: gray];
}

void GScurrentgstate(int gst)
{
  [_currentGPSContext DPScurrentgstate: gst];
}

void GScurrenthalftone( void )
{
  [_currentGPSContext DPScurrenthalftone];
}

void GScurrenthalftonephase(float *x, float *y)
{
  [_currentGPSContext DPScurrenthalftonephase: x : y];
}

void GScurrenthsbcolor(float *h, float *s, float *b)
{
  [_currentGPSContext DPScurrenthsbcolor: h : s : b];
}

void GScurrentlinecap(int *linecap)
{
  [_currentGPSContext DPScurrentlinecap: linecap];
}

void GScurrentlinejoin(int *linejoin)
{
  [_currentGPSContext DPScurrentlinejoin: linejoin];
}

void GScurrentlinewidth(float *width)
{
  [_currentGPSContext DPScurrentlinewidth: width];
}

void GScurrentmatrix( void )
{
  [_currentGPSContext DPScurrentmatrix];
}

void GScurrentmiterlimit(float *limit)
{
  [_currentGPSContext DPScurrentmiterlimit: limit];
}

void GScurrentpoint(float *x, float *y)
{
  [_currentGPSContext DPScurrentpoint: x : y];
}

void GScurrentrgbcolor(float *r, float *g, float *b)
{
  [_currentGPSContext DPScurrentrgbcolor: r : g : b];
}

void GScurrentscreen( void )
{
  [_currentGPSContext DPScurrentscreen];
}

void GScurrentstrokeadjust(int *b)
{
  [_currentGPSContext DPScurrentstrokeadjust: b];
}

void GScurrenttransfer( void )
{
  [_currentGPSContext DPScurrenttransfer];
}

void GSdefaultmatrix( void )
{
  [_currentGPSContext DPSdefaultmatrix];
}

void GSgrestore( void )
{
  [_currentGPSContext DPSgrestore];
}

void GSgrestoreall( void )
{
  [_currentGPSContext DPSgrestoreall];
}

void GSgsave( void )
{
  [_currentGPSContext DPSgsave];
}

void GSgstate( void )
{
  [_currentGPSContext DPSgstate];
}

void GSinitgraphics( void )
{
  [_currentGPSContext DPSinitgraphics];
}

void GSinitmatrix( void )
{
  [_currentGPSContext DPSinitmatrix];
}

void GSrotate(float angle)
{
  [_currentGPSContext DPSrotate: angle];
}

void GSscale(float x, float y)
{
  [_currentGPSContext DPSscale: x : y];
}

void GSsetdash(const float pat[], int size, float offset)
{
  [_currentGPSContext DPSsetdash: pat : size : offset];
}

void GSsetflat(float flatness)
{
  [_currentGPSContext DPSsetflat: flatness];
}

void GSsetgray(float gray)
{
  [_currentGPSContext DPSsetgray: gray];
}

void GSsetgstate(int gst)
{
  [_currentGPSContext DPSsetgstate: gst];
}

void GSsethalftone( void )
{
  [_currentGPSContext DPSsethalftone];
}

void GSsethalftonephase(float x, float y)
{
  [_currentGPSContext DPSsethalftonephase: x : y];
}

void GSsethsbcolor(float h, float s, float b)
{
  [_currentGPSContext DPSsethsbcolor: h : s : b];
}

void GSsetlinecap(int linecap)
{
  [_currentGPSContext DPSsetlinecap: linecap];
}

void GSsetlinejoin(int linejoin)
{
  [_currentGPSContext DPSsetlinejoin: linejoin];
}

void GSsetlinewidth(float width)
{
  [_currentGPSContext DPSsetlinewidth: width];
}

void GSsetmatrix( void )
{
  [_currentGPSContext DPSsetmatrix];
}

void GSsetmiterlimit(float limit)
{
  [_currentGPSContext DPSsetmiterlimit: limit];
}

void GSsetrgbcolor(float r, float g, float b)
{
  [_currentGPSContext DPSsetrgbcolor: r : g : b];
}

void GSsetscreen( void )
{
  [_currentGPSContext DPSsetscreen];
}

void GSsetstrokeadjust(int b)
{
  [_currentGPSContext DPSsetstrokeadjust: b];
}

void GSsettransfer( void )
{
  [_currentGPSContext DPSsettransfer];
}

void GStranslate(float x, float y)
{
  [_currentGPSContext DPStranslate: x : y];
}

/* ----------------------------------------------------------------------- */
/* I/O operations */
/* ----------------------------------------------------------------------- */

void GSflush( void )
{
  [_currentGPSContext DPSflush];
}

/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */

void GSconcatmatrix( void )
{
  [_currentGPSContext DPSconcatmatrix];
}

void GSdtransform(float x1, float y1, float *x2, float *y2)
{
  [_currentGPSContext DPSdtransform: x1 : y1 : x2 : y2];
}

void GSidentmatrix( void )
{
  [_currentGPSContext DPSidentmatrix];
}

void GSidtransform(float x1, float y1, float *x2, float *y2)
{
  [_currentGPSContext DPSidtransform: x1 : y1 : x2 : y2];
}

void GSinvertmatrix( void )
{
  [_currentGPSContext DPSinvertmatrix];
}

void GSitransform(float x1, float y1, float *x2, float *y2)
{
  [_currentGPSContext DPSitransform: x1 : y1 : x2 : y2];
}

void GStransform(float x1, float y1, float *x2, float *y2)
{
  [_currentGPSContext DPStransform: x1 : y1 : x2 : y2];
}

/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */

void GSashow(float x, float y, const char *s)
{
  [_currentGPSContext DPSashow: x : y : s];
}

void GSawidthshow(float cx, float cy, int c, float ax, float ay, const char *s)
{
  [_currentGPSContext DPSawidthshow: cx : cy : c : ax : ay : s];
}

void GScopypage( void )
{
  [_currentGPSContext DPScopypage];
}

void GSeofill( void )
{
  [_currentGPSContext DPSeofill];
}

void GSerasepage( void )
{
  [_currentGPSContext DPSerasepage];
}

void GSfill( void )
{
  [_currentGPSContext DPSfill];
}

void GSimage( void )
{
  [_currentGPSContext DPSimage];
}

void GSimagemask( void )
{
  [_currentGPSContext DPSimagemask];
}

void GSkshow(const char *s)
{
  [_currentGPSContext DPSkshow: s];
}

void GSrectfill(float x, float y, float w, float h)
{
  [_currentGPSContext DPSrectfill: x : y : w : h];
}

void GSrectstroke(float x, float y, float w, float h)
{
  [_currentGPSContext DPSrectstroke: x : y : w : h];
}

void GSshow(const char *s)
{
  [_currentGPSContext DPSshow: s];
}

void GSshowpage( void )
{
  [_currentGPSContext DPSshowpage];
}

void GSstroke( void )
{
  [_currentGPSContext DPSstroke];
}

void GSstrokepath( void )
{
  [_currentGPSContext DPSstrokepath];
}

void GSueofill(const char nums[], int n, const char ops[], int l)
{
  [_currentGPSContext DPSueofill: nums : n : ops : l];
}

void GSufill(const char nums[], int n, const char ops[], int l)
{
  [_currentGPSContext DPSufill: nums : n : ops : l];
}

void GSustroke(const char nums[], int n, const char ops[], int l)
{
  [_currentGPSContext DPSustroke: nums : n : ops : l];
}

void GSustrokepath(const char nums[], int n, const char ops[], int l)
{
  [_currentGPSContext DPSustrokepath: nums : n : ops : l];
}

void GSwidthshow(float x, float y, int c, const char *s)
{
  [_currentGPSContext DPSwidthshow: x : y : c : s];
}

void GSxshow(const char *s, const float numarray[], int size)
{
  [_currentGPSContext DPSxshow: s : numarray : size];
}

void GSxyshow(const char *s, const float numarray[], int size)
{
  [_currentGPSContext DPSxyshow: s : numarray : size];
}

void GSyshow(const char *s, const float numarray[], int size)
{
  [_currentGPSContext DPSyshow: s : numarray : size];
}

/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */

void GSarc(float x, float y, float r, float angle1, float angle2)
{
  [_currentGPSContext DPSarc: x : y : r : angle1 : angle2];
}

void GSarcn(float x, float y, float r, float angle1, float angle2)
{
  [_currentGPSContext DPSarcn: x : y : r : angle1 : angle2];
}

void GSarct(float x1, float y1, float x2, float y2, float r)
{
  [_currentGPSContext DPSarct: x1 : y1 : x2 : y2 : r];
}

void GSarcto(float x1, float y1, float x2, float y2, float r, float *xt1, float *yt1, float *xt2, float *yt2)
{
  [_currentGPSContext DPSarcto: x1 : y1 : x2 : y2 : r : xt1 : yt1 : xt2 : yt2];
}

void GScharpath(const char *s, int b)
{
  [_currentGPSContext DPScharpath: s : b];
}

void GSclip( void )
{
  [_currentGPSContext DPSclip];
}

void GSclippath( void )
{
  [_currentGPSContext DPSclippath];
}

void GSclosepath( void )
{
  [_currentGPSContext DPSclosepath];
}

void GScurveto(float x1, float y1, float x2, float y2, float x3, float y3)
{
  [_currentGPSContext DPScurveto: x1 : y1 : x2 : y2 : x3 : y3];
}

void GSeoclip( void )
{
  [_currentGPSContext DPSeoclip];
}

void GSeoviewclip( void )
{
  [_currentGPSContext DPSeoviewclip];
}

void GSflattenpath( void )
{
  [_currentGPSContext DPSflattenpath];
}

void GSinitclip( void )
{
  [_currentGPSContext DPSinitclip];
}

void GSinitviewclip( void )
{
  [_currentGPSContext DPSinitviewclip];
}

void GSlineto(float x, float y)
{
  [_currentGPSContext DPSlineto: x : y];
}

void GSmoveto(float x, float y)
{
  [_currentGPSContext DPSmoveto: x : y];
}

void GSnewpath( void )
{
  [_currentGPSContext DPSnewpath];
}

void GSpathbbox(float *llx, float *lly, float *urx, float *ury)
{
  [_currentGPSContext DPSpathbbox: llx : lly : urx : ury];
}

void GSpathforall( void )
{
  [_currentGPSContext DPSpathforall];
}

void GSrcurveto(float x1, float y1, float x2, float y2, float x3, float y3)
{
  [_currentGPSContext DPSrcurveto: x1 : y1 : x2 : y2 : x3 : y3];
}

void GSrectclip(float x, float y, float w, float h)
{
  [_currentGPSContext DPSrectclip: x : y : w : h];
}

void GSrectviewclip(float x, float y, float w, float h)
{
  [_currentGPSContext DPSrectviewclip: x : y : w : h];
}

void GSreversepath( void )
{
  [_currentGPSContext DPSreversepath];
}

void GSrlineto(float x, float y)
{
  [_currentGPSContext DPSrlineto: x : y];
}

void GSrmoveto(float x, float y)
{
  [_currentGPSContext DPSrmoveto: x : y];
}

void GSsetbbox(float llx, float lly, float urx, float ury)
{
  [_currentGPSContext DPSsetbbox: llx : lly : urx : ury];
}

void GSsetucacheparams( void )
{
  [_currentGPSContext DPSsetucacheparams];
}

void GSuappend(const char nums[], int n, const char ops[], int l)
{
  [_currentGPSContext DPSuappend: nums : n : ops : l];
}

void GSucache( void )
{
  [_currentGPSContext DPSucache];
}

void GSucachestatus( void )
{
  [_currentGPSContext DPSucachestatus];
}

void GSupath(int b)
{
  [_currentGPSContext DPSupath: b];
}

void GSviewclip( void )
{
  [_currentGPSContext DPSviewclip];
}

void GSviewclippath( void )
{
  [_currentGPSContext DPSviewclippath];
}

/* ----------------------------------------------------------------------- */
/* X operations */
/* ----------------------------------------------------------------------- */

void GScurrentXdrawingfunction(int *function)
{
  [_currentGPSContext DPScurrentXdrawingfunction: function];
}

void GScurrentXgcdrawable(int *gc, int *draw, int *x, int *y)
{
  [_currentGPSContext DPScurrentXgcdrawable: gc : draw : x : y];
}

void GScurrentXgcdrawablecolor(int *gc, int *draw, int *x, int *y, 
				      int colorInfo[])
{
  [_currentGPSContext DPScurrentXgcdrawablecolor: gc : draw : x : y : colorInfo];
}

void GScurrentXoffset(int *x, int *y)
{
  [_currentGPSContext DPScurrentXoffset: x : y];
}

void GSsetXdrawingfunction(int function)
{
  [_currentGPSContext DPSsetXdrawingfunction: function];
}

void GSsetXgcdrawable(int gc, int draw, int x, int y)
{
  [_currentGPSContext DPSsetXgcdrawable: gc : draw : x : y];
}

void GSsetXgcdrawablecolor(int gc, int draw, int x, int y, 
				  const int colorInfo[])
{
  [_currentGPSContext DPSsetXgcdrawablecolor: gc : draw : x : y : colorInfo];
}

void GSsetXoffset(short int x, short int y)
{
  [_currentGPSContext DPSsetXoffset: x : y];
}

void GSsetXrgbactual(double r, double g, double b, int *success)
{
  [_currentGPSContext DPSsetXrgbactual: r : g : b : success];
}


