/* A Bison parser, made from rtfGrammer.y, by GNU bison 1.75.  */

/* Skeleton parser for Yacc-like parsing with Bison,
   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

/* As a special exception, when this file is copied by Bison into a
   Bison output file, you may use that output file without restriction.
   This special exception was added by the Free Software Foundation
   in version 1.24 of Bison.  */

#ifndef BISON_RTFGRAMMER_TAB_H
# define BISON_RTFGRAMMER_TAB_H

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     RTFtext = 258,
     RTFstart = 259,
     RTFansi = 260,
     RTFmac = 261,
     RTFpc = 262,
     RTFpca = 263,
     RTFignore = 264,
     RTFinfo = 265,
     RTFstylesheet = 266,
     RTFfootnote = 267,
     RTFheader = 268,
     RTFfooter = 269,
     RTFpict = 270,
     RTFplain = 271,
     RTFparagraph = 272,
     RTFdefaultParagraph = 273,
     RTFrow = 274,
     RTFcell = 275,
     RTFtabulator = 276,
     RTFemdash = 277,
     RTFendash = 278,
     RTFemspace = 279,
     RTFenspace = 280,
     RTFbullet = 281,
     RTFlquote = 282,
     RTFrquote = 283,
     RTFldblquote = 284,
     RTFrdblquote = 285,
     RTFred = 286,
     RTFgreen = 287,
     RTFblue = 288,
     RTFcolorbg = 289,
     RTFcolorfg = 290,
     RTFcolortable = 291,
     RTFfont = 292,
     RTFfontSize = 293,
     RTFpaperWidth = 294,
     RTFpaperHeight = 295,
     RTFmarginLeft = 296,
     RTFmarginRight = 297,
     RTFmarginTop = 298,
     RTFmarginButtom = 299,
     RTFfirstLineIndent = 300,
     RTFleftIndent = 301,
     RTFrightIndent = 302,
     RTFalignCenter = 303,
     RTFalignJustified = 304,
     RTFalignLeft = 305,
     RTFalignRight = 306,
     RTFlineSpace = 307,
     RTFspaceAbove = 308,
     RTFstyle = 309,
     RTFbold = 310,
     RTFitalic = 311,
     RTFunderline = 312,
     RTFunderlineStop = 313,
     RTFunichar = 314,
     RTFsubscript = 315,
     RTFsuperscript = 316,
     RTFtabstop = 317,
     RTFfcharset = 318,
     RTFfprq = 319,
     RTFcpg = 320,
     RTFOtherStatement = 321,
     RTFfontListStart = 322,
     RTFfamilyNil = 323,
     RTFfamilyRoman = 324,
     RTFfamilySwiss = 325,
     RTFfamilyModern = 326,
     RTFfamilyScript = 327,
     RTFfamilyDecor = 328,
     RTFfamilyTech = 329
   };
#endif
#define RTFtext 258
#define RTFstart 259
#define RTFansi 260
#define RTFmac 261
#define RTFpc 262
#define RTFpca 263
#define RTFignore 264
#define RTFinfo 265
#define RTFstylesheet 266
#define RTFfootnote 267
#define RTFheader 268
#define RTFfooter 269
#define RTFpict 270
#define RTFplain 271
#define RTFparagraph 272
#define RTFdefaultParagraph 273
#define RTFrow 274
#define RTFcell 275
#define RTFtabulator 276
#define RTFemdash 277
#define RTFendash 278
#define RTFemspace 279
#define RTFenspace 280
#define RTFbullet 281
#define RTFlquote 282
#define RTFrquote 283
#define RTFldblquote 284
#define RTFrdblquote 285
#define RTFred 286
#define RTFgreen 287
#define RTFblue 288
#define RTFcolorbg 289
#define RTFcolorfg 290
#define RTFcolortable 291
#define RTFfont 292
#define RTFfontSize 293
#define RTFpaperWidth 294
#define RTFpaperHeight 295
#define RTFmarginLeft 296
#define RTFmarginRight 297
#define RTFmarginTop 298
#define RTFmarginButtom 299
#define RTFfirstLineIndent 300
#define RTFleftIndent 301
#define RTFrightIndent 302
#define RTFalignCenter 303
#define RTFalignJustified 304
#define RTFalignLeft 305
#define RTFalignRight 306
#define RTFlineSpace 307
#define RTFspaceAbove 308
#define RTFstyle 309
#define RTFbold 310
#define RTFitalic 311
#define RTFunderline 312
#define RTFunderlineStop 313
#define RTFunichar 314
#define RTFsubscript 315
#define RTFsuperscript 316
#define RTFtabstop 317
#define RTFfcharset 318
#define RTFfprq 319
#define RTFcpg 320
#define RTFOtherStatement 321
#define RTFfontListStart 322
#define RTFfamilyNil 323
#define RTFfamilyRoman 324
#define RTFfamilySwiss 325
#define RTFfamilyModern 326
#define RTFfamilyScript 327
#define RTFfamilyDecor 328
#define RTFfamilyTech 329




#ifndef YYSTYPE
#line 77 "rtfGrammer.y"
typedef union {
	int		number;
	const char	*text;
	RTFcmd		cmd;
} yystype;
/* Line 1281 of /usr/share/bison/yacc.c.  */
#line 194 "rtfGrammer.tab.h"
# define YYSTYPE yystype
#endif




#endif /* not BISON_RTFGRAMMER_TAB_H */

