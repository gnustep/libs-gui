/* GPSDrawContextOps - Generic drawing DrawContext class ops.

   Copyright (C) 1995 Free Software Foundation, Inc.

   Written by:  Adam Fedor <fedor@boulder.colorado.edu>
   Date: Nov 1995
   
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

#ifndef _GPSDrawContextOps_h_INCLUDE
#define _GPSDrawContextOps_h_INCLUDE

@interface GPSDrawContext (ColorOps)

- (void) DPScolorimage;

- (void) DPScurrentblackgeneration;

- (void) DPScurrentcmykcolor: (float *)c : (float *)m : (float *)y : (float *)k;

- (void) DPScurrentcolorscreen;

- (void) DPScurrentcolortransfer;

- (void) DPScurrentundercolorremoval;

- (void) DPSsetblackgeneration;

- (void) DPSsetcmykcolor: (float)c : (float)m : (float)y : (float)k;

- (void) DPSsetcolorscreen;

- (void) DPSsetcolortransfer;

- (void) DPSsetundercolorremoval;

@end

@interface GPSDrawContext (FontOps)

- (void) DPSFontDirectory;

- (void) DPSISOLatin1Encoding;

- (void) DPSSharedFontDirectory;

- (void) DPSStandardEncoding;

- (void) DPScachestatus: (int *)bsize : (int *)bmax : (int *)msize;

- (void) DPScurrentcacheparams;

- (void) DPScurrentfont;

- (void) DPSdefinefont;

- (void) DPSfindfont: (const char *)name;

- (void) DPSmakefont;

- (void) DPSscalefont: (float)size;

- (void) DPSselectfont: (const char *)name : (float)scale;

- (void) DPSsetcachedevice: (float)wx : (float)wy : (float)llx : (float)lly : (float)urx : (float)ury;

- (void) DPSsetcachelimit: (float)n;

- (void) DPSsetcacheparams;

- (void) DPSsetcharwidth: (float)wx : (float)wy;

- (void) DPSsetfont: (int)f;

- (void) DPSundefinefont: (const char *)name;

@end

@interface GPSDrawContext (GStateOps)

- (void) DPSconcat: (const float *)m;

- (void) DPScurrentdash;

- (void) DPScurrentflat: (float *)flatness;

- (void) DPScurrentgray: (float *)gray;

- (void) DPScurrentgstate: (int)gst;

- (void) DPScurrenthalftone;

- (void) DPScurrenthalftonephase: (float *)x : (float *)y;

- (void) DPScurrenthsbcolor: (float *)h : (float *)s : (float *)b;

- (void) DPScurrentlinecap: (int *)linecap;

- (void) DPScurrentlinejoin: (int *)linejoin;

- (void) DPScurrentlinewidth: (float *)width;

- (void) DPScurrentmatrix;

- (void) DPScurrentmiterlimit: (float *)limit;

- (void) DPScurrentpoint: (float *)x : (float *)y;

- (void) DPScurrentrgbcolor: (float *)r : (float *)g : (float *)b;

- (void) DPScurrentscreen;

- (void) DPScurrentstrokeadjust: (int *)b;

- (void) DPScurrenttransfer;

- (void) DPSdefaultmatrix;

- (void) DPSgrestore;

- (void) DPSgrestoreall;

- (void) DPSgsave;

- (void) DPSgstate;

- (void) DPSinitgraphics;

- (void) DPSinitmatrix;

- (void) DPSrotate: (float)angle;

- (void) DPSscale: (float)x : (float)y;

- (void) DPSsetdash: (const float *)pat : (int)size : (float)offset;

- (void) DPSsetflat: (float)flatness;

- (void) DPSsetgray: (float)gray;

- (void) DPSsetgstate: (int)gst;

- (void) DPSsethalftone;

- (void) DPSsethalftonephase: (float)x : (float)y;

- (void) DPSsethsbcolor: (float)h : (float)s : (float)b;

- (void) DPSsetlinecap: (int)linecap;

- (void) DPSsetlinejoin: (int)linejoin;

- (void) DPSsetlinewidth: (float)width;

- (void) DPSsetmatrix;

- (void) DPSsetmiterlimit: (float)limit;

- (void) DPSsetrgbcolor: (float)r : (float)g : (float)b;

- (void) DPSsetscreen;

- (void) DPSsetstrokeadjust: (int)b;

- (void) DPSsettransfer;

- (void) DPStranslate: (float)x : (float)y;

@end

@interface GPSDrawContext (IOOps)

- (void) DPSflush;

@end

@interface GPSDrawContext (MatrixOps)

- (void) DPSconcatmatrix;

- (void) DPSdtransform: (float)x1 : (float)y1 : (float *)x2 : (float *)y2;

- (void) DPSidentmatrix;

- (void) DPSidtransform: (float)x1 : (float)y1 : (float *)x2 : (float *)y2;

- (void) DPSinvertmatrix;

- (void) DPSitransform: (float)x1 : (float)y1 : (float *)x2 : (float *)y2;

- (void) DPStransform: (float)x1 : (float)y1 : (float *)x2 : (float *)y2;

@end

@interface GPSDrawContext (PaintOps)

- (void) DPSashow: (float)x : (float)y : (const char *)s;

- (void) DPSawidthshow: (float)cx : (float)cy : (int)c : (float)ax : (float)ay : (const char *)s;

- (void) DPScopypage;

- (void) DPSeofill;

- (void) DPSerasepage;

- (void) DPSfill;

- (void) DPSimage;

- (void) DPSimagemask;

- (void) DPSkshow: (const char *)s;

- (void) DPSrectfill: (float)x : (float)y : (float)w : (float)h;

- (void) DPSrectstroke: (float)x : (float)y : (float)w : (float)h;

- (void) DPSshow: (const char *)s;

- (void) DPSshowpage;

- (void) DPSstroke;

- (void) DPSstrokepath;

- (void) DPSueofill: (const char *)nums : (int)n : (const char *)ops : (int)l;

- (void) DPSufill: (const char *)nums : (int)n : (const char *)ops : (int)l;

- (void) DPSustroke: (const char *)nums : (int)n : (const char *)ops : (int)l;

- (void) DPSustrokepath: (const char *)nums : (int)n : (const char *)ops : (int)l;

- (void) DPSwidthshow: (float)x : (float)y : (int)c : (const char *)s;

- (void) DPSxshow: (const char *)s : (const float *)numarray : (int)size;

- (void) DPSxyshow: (const char *)s : (const float *)numarray : (int)size;

- (void) DPSyshow: (const char *)s : (const float *)numarray : (int)size;

@end

@interface GPSDrawContext (PathOps)

- (void) DPSarc: (float)x : (float)y : (float)r : (float)angle1 : (float)angle2;

- (void) DPSarcn: (float)x : (float)y : (float)r : (float)angle1 : (float)angle2;

- (void) DPSarct: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)r;

- (void) DPSarcto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)r : (float *)xt1 : (float *)yt1 : (float *)xt2 : (float *)yt2;

- (void) DPScharpath: (const char *)s : (int)b;

- (void) DPSclip;

- (void) DPSclippath;

- (void) DPSclosepath;

- (void) DPScurveto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)x3 : (float)y3;

- (void) DPSeoclip;

- (void) DPSeoviewclip;

- (void) DPSflattenpath;

- (void) DPSinitclip;

- (void) DPSinitviewclip;

- (void) DPSlineto: (float)x : (float)y;

- (void) DPSmoveto: (float)x : (float)y;

- (void) DPSnewpath;

- (void) DPSpathbbox: (float *)llx : (float *)lly : (float *)urx : (float *)ury;

- (void) DPSpathforall;

- (void) DPSrcurveto: (float)x1 : (float)y1 : (float)x2 : (float)y2 : (float)x3 : (float)y3;

- (void) DPSrectclip: (float)x : (float)y : (float)w : (float)h;

- (void) DPSrectviewclip: (float)x : (float)y : (float)w : (float)h;

- (void) DPSreversepath;

- (void) DPSrlineto: (float)x : (float)y;

- (void) DPSrmoveto: (float)x : (float)y;

- (void) DPSsetbbox: (float)llx : (float)lly : (float)urx : (float)ury;

- (void) DPSsetucacheparams;

- (void) DPSuappend: (const char *)nums : (int)n : (const char *)ops : (int)l;

- (void) DPSucache;

- (void) DPSucachestatus;

- (void) DPSupath: (int)b;

- (void) DPSviewclip;

- (void) DPSviewclippath;

@end

@interface GPSDrawContext (X11Ops)

- (void) DPScurrentXdrawingfunction: (int *)function;

- (void) DPScurrentXgcdrawable: (int *)gc : (int *)draw : (int *)x : (int *)y;

- (void) DPScurrentXgcdrawablecolor: (int *)gc : (int *)draw : (int *)x 
				  : (int *)y : (int *)colorInfo;

- (void) DPScurrentXoffset: (int *)x : (int *)y;

- (void) DPSsetXdrawingfunction: (int) function;

- (void) DPSsetXgcdrawable: (int)gc : (int)draw : (int)x : (int)y;

- (void) DPSsetXgcdrawablecolor: (int)gc : (int)draw : (int)x : (int)y
				  : (const int *)colorInfo;

- (void) DPSsetXoffset: (short int)x : (short int)y;

- (void) DPSsetXrgbactual: (double)r : (double)g : (double)b : (int *)success;

@end

#endif /* _GPSDrawContext_h_INCLUDE */
