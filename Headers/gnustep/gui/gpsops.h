/* PostScript operators. 

   Copyright (C) 1995 Free Software Foundation, Inc.

   Written by:  Adam Fedor <fedor@boulder.colorado.edu>
   Date: Nov 1995
   
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

/*
 * (c) Copyright 1988-1994 Adobe Systems Incorporated.
 * All rights reserved.
 * 
 * Permission to use, copy, modify, distribute, and sublicense this software
 * and its documentation for any purpose and without fee is hereby granted,
 * provided that the above copyright notices appear in all copies and that
 * both those copyright notices and this permission notice appear in
 * supporting documentation and that the name of Adobe Systems Incorporated
 * not be used in advertising or publicity pertaining to distribution of the
 * software without specific, written prior permission.  No trademark license
 * to use the Adobe trademarks is hereby granted.  If the Adobe trademark
 * "Display PostScript"(tm) is used to describe this software, its
 * functionality or for any other purpose, such use shall be limited to a
 * statement that this software works in conjunction with the Display
 * PostScript system.  Proper trademark attribution to reflect Adobe's
 * ownership of the trademark shall be given whenever any such reference to
 * the Display PostScript system is made.
 * 
 * ADOBE MAKES NO REPRESENTATIONS ABOUT THE SUITABILITY OF THE SOFTWARE FOR
 * ANY PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.
 * ADOBE DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
 * IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NON- INFRINGEMENT OF THIRD PARTY RIGHTS.  IN NO EVENT SHALL ADOBE BE LIABLE
 * TO YOU OR ANY OTHER PARTY FOR ANY SPECIAL, INDIRECT, OR CONSEQUENTIAL
 * DAMAGES OR ANY DAMAGES WHATSOEVER WHETHER IN AN ACTION OF CONTRACT,
 * NEGLIGENCE, STRICT LIABILITY OR ANY OTHER ACTION ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.  ADOBE WILL NOT
 * PROVIDE ANY TRAINING OR OTHER SUPPORT FOR THE SOFTWARE.
 * 
 * Adobe, PostScript, and Display PostScript are trademarks of Adobe Systems
 * Incorporated which may be registered in certain jurisdictions
 * 
 * Author:  Adobe Systems Incorporated
 */

#ifndef _GSOPS_H_
#define _GSOPS_H_

/* ----------------------------------------------------------------------- */
/* Color operations */
/* ----------------------------------------------------------------------- */

extern void GScolorimage( void );

//extern void GScurrentblackgeneration( void );

extern void GScurrentcmykcolor(float *c, float *m, float *y, float *k);

//extern void GScurrentcolorscreen( void );

//extern void GScurrentcolortransfer( void );

//extern void GScurrentundercolorremoval( void );

//extern void GSsetblackgeneration( void );

extern void GSsetcmykcolor(float c, float m, float y, float k);

//extern void GSsetcolorscreen( void );

//extern void GSsetcolortransfer( void );

//extern void GSsetundercolorremoval( void );

/* ----------------------------------------------------------------------- */
/* Font operations */
/* ----------------------------------------------------------------------- */

//extern void GSFontDirectory( void );

//extern void GSISOLatin1Encoding( void );

//extern void GSSharedFontDirectory( void );

//extern void GSStandardEncoding( void );

//extern void GScachestatus(int *bsize, int *bmax, int *msize);

//extern void GScurrentcacheparams( void );

//extern void GScurrentfont( void );

//extern void GSdefinefont( void );

extern void GSfindfont(const char *name);

extern void GSmakefont( void );

extern void GSscalefont(float size);

extern void GSselectfont(const char *name, float scale);

//extern void GSsetcachedevice(float wx, float wy, float llx, float lly, float urx, float ury);

//extern void GSsetcachelimit(float n);

//extern void GSsetcacheparams( void );

//extern void GSsetcharwidth(float wx, float wy);

extern void GSsetfont(int f);

extern void GSundefinefont(const char *name);

/* ----------------------------------------------------------------------- */
/* Gstate operations */
/* ----------------------------------------------------------------------- */

extern void GSconcat(const float m[]);

//extern void GScurrentdash( void );

extern void GScurrentflat(float *flatness);

extern void GScurrentgray(float *gray);

extern void GScurrentgstate(int gst);

//extern void GScurrenthalftone( void );

extern void GScurrenthalftonephase(float *x, float *y);

extern void GScurrenthsbcolor(float *h, float *s, float *b);

extern void GScurrentlinecap(int *linecap);

extern void GScurrentlinejoin(int *linejoin);

extern void GScurrentlinewidth(float *width);

//extern void GScurrentmatrix( void );

extern void GScurrentmiterlimit(float *limit);

extern void GScurrentpoint(float *x, float *y);

extern void GScurrentrgbcolor(float *r, float *g, float *b);

//extern void GScurrentscreen( void );

extern void GScurrentstrokeadjust(int *b);

//extern void GScurrenttransfer( void );

extern void GSdefaultmatrix( void );

extern void GSgrestore( void );

extern void GSgrestoreall( void );

extern void GSgsave( void );

//extern void GSgstate( void );

extern void GSinitgraphics( void );

extern void GSinitmatrix( void );

extern void GSrotate(float angle);

extern void GSscale(float x, float y);

extern void GSsetdash(const float pat[], int size, float offset);

extern void GSsetflat(float flatness);

extern void GSsetgray(float gray);

extern void GSsetgstate(int gst);

extern void GSsethalftone( void );

extern void GSsethalftonephase(float x, float y);

extern void GSsethsbcolor(float h, float s, float b);

extern void GSsetlinecap(int linecap);

extern void GSsetlinejoin(int linejoin);

extern void GSsetlinewidth(float width);

extern void GSsetmatrix( void );

extern void GSsetmiterlimit(float limit);

extern void GSsetrgbcolor(float r, float g, float b);

extern void GSsetscreen( void );

extern void GSsetstrokeadjust(int b);

extern void GSsettransfer( void );

extern void GStranslate(float x, float y);

/* ----------------------------------------------------------------------- */
/* I/O operations */
/* ----------------------------------------------------------------------- */

//extern void GSequals( void );

//extern void GSequalsequals( void );

//extern void GSbytesavailable(int *n);

//extern void GSclosefile( void );

//extern void GScurrentfile( void );

//extern void GSdeletefile(const char *filename);

//extern void GSecho(int b);

//extern void GSfile(const char *name, const char *access);

//extern void GSfilenameforall( void );

//extern void GSfileposition(int *pos);

extern void GSflush( void );

//extern void GSflushfile( void );

//extern void GSprint( void );

//extern void GSprintobject(int tag);

//extern void GSpstack( void );

//extern void GSread(int *b);

//extern void GSreadhexstring(int *b);

//extern void GSreadline(int *b);

//extern void GSreadstring(int *b);

//extern void GSrenamefile(const char *old, const char *new);

//extern void GSresetfile( void );

//extern void GSsetfileposition(int pos);

//extern void GSstack( void );

//extern void GSstatus(int *b);

//extern void GStoken(int *b);

//extern void GSwrite( void );

//extern void GSwritehexstring( void );

//extern void GSwriteobject(int tag);

//extern void GSwritestring( void );

/* ----------------------------------------------------------------------- */
/* Matrix operations */
/* ----------------------------------------------------------------------- */

extern void GSconcatmatrix( void );

extern void GSdtransform(float x1, float y1, float *x2, float *y2);

extern void GSidentmatrix( void );

extern void GSidtransform(float x1, float y1, float *x2, float *y2);

extern void GSinvertmatrix( void );

extern void GSitransform(float x1, float y1, float *x2, float *y2);

extern void GStransform(float x1, float y1, float *x2, float *y2);

/* ----------------------------------------------------------------------- */
/* Paint operations */
/* ----------------------------------------------------------------------- */

extern void GSashow(float x, float y, const char *s);

extern void GSawidthshow(float cx, float cy, int c, float ax, float ay, const char *s);

//extern void GScopypage( void );

extern void GSeofill( void );

extern void GSerasepage( void );

extern void GSfill( void );

//extern void GSimage( void );

//extern void GSimagemask( void );

extern void GSkshow(const char *s);

extern void GSrectfill(float x, float y, float w, float h);

extern void GSrectstroke(float x, float y, float w, float h);

extern void GSshow(const char *s);

extern void GSshowpage( void );

extern void GSstroke( void );

extern void GSstrokepath( void );

extern void GSueofill(const char nums[], int n, const char ops[], int l);

extern void GSufill(const char nums[], int n, const char ops[], int l);

extern void GSustroke(const char nums[], int n, const char ops[], int l);

extern void GSustrokepath(const char nums[], int n, const char ops[], int l);

extern void GSwidthshow(float x, float y, int c, const char *s);

extern void GSxshow(const char *s, const float numarray[], int size);

extern void GSxyshow(const char *s, const float numarray[], int size);

extern void GSyshow(const char *s, const float numarray[], int size);

/* ----------------------------------------------------------------------- */
/* Path operations */
/* ----------------------------------------------------------------------- */

extern void GSarc(float x, float y, float r, float angle1, float angle2);

extern void GSarcn(float x, float y, float r, float angle1, float angle2);

extern void GSarct(float x1, float y1, float x2, float y2, float r);

extern void GSarcto(float x1, float y1, float x2, float y2, float r, float *xt1, float *yt1, float *xt2, float *yt2);

extern void GScharpath(const char *s, int b);

extern void GSclip( void );

extern void GSclippath( void );

extern void GSclosepath( void );

extern void GScurveto(float x1, float y1, float x2, float y2, float x3, float y3);

extern void GSeoclip( void );

extern void GSeoviewclip( void );

extern void GSflattenpath( void );

extern void GSinitclip( void );

extern void GSinitviewclip( void );

extern void GSlineto(float x, float y);

extern void GSmoveto(float x, float y);

extern void GSnewpath( void );

extern void GSpathbbox(float *llx, float *lly, float *urx, float *ury);

extern void GSpathforall( void );

extern void GSrcurveto(float x1, float y1, float x2, float y2, float x3, float y3);

extern void GSrectclip(float x, float y, float w, float h);

extern void GSrectviewclip(float x, float y, float w, float h);

extern void GSreversepath( void );

extern void GSrlineto(float x, float y);

extern void GSrmoveto(float x, float y);

extern void GSsetbbox(float llx, float lly, float urx, float ury);

extern void GSsetucacheparams( void );

extern void GSuappend(const char nums[], int n, const char ops[], int l);

extern void GSucache( void );

extern void GSucachestatus( void );

extern void GSupath(int b);

extern void GSviewclip( void );

extern void GSviewclippath( void );

/* ----------------------------------------------------------------------- */
/* X operations */
/* ----------------------------------------------------------------------- */

extern void GScurrentXdrawingfunction(int *function);

extern void GScurrentXgcdrawable(int *gc, int *draw, int *x, int *y);

extern void GScurrentXgcdrawablecolor(int *gc, int *draw, int *x, int *y, 
				      int colorInfo[]);

extern void GScurrentXoffset(int *x, int *y);

extern void GSsetXdrawingfunction(int function);

extern void GSsetXgcdrawable(int gc, int draw, int x, int y);

extern void GSsetXgcdrawablecolor(int gc, int draw, int x, int y, 
				  const int colorInfo[]);

extern void GSsetXoffset(short int x, short int y);

extern void GSsetXrgbactual(double r, double g, double b, int *success);



#endif	/* _GSOPS_H_ */
