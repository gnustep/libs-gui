/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

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
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

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
     RTFNeXTGraphic = 294,
     RTFNeXTGraphicWidth = 295,
     RTFNeXTGraphicHeight = 296,
     RTFNeXTHelpLink = 297,
     RTFNeXTHelpMarker = 298,
     RTFNeXTfilename = 299,
     RTFNeXTmarkername = 300,
     RTFNeXTlinkFilename = 301,
     RTFNeXTlinkMarkername = 302,
     RTFpaperWidth = 303,
     RTFpaperHeight = 304,
     RTFmarginLeft = 305,
     RTFmarginRight = 306,
     RTFmarginTop = 307,
     RTFmarginButtom = 308,
     RTFfirstLineIndent = 309,
     RTFleftIndent = 310,
     RTFrightIndent = 311,
     RTFalignCenter = 312,
     RTFalignJustified = 313,
     RTFalignLeft = 314,
     RTFalignRight = 315,
     RTFlineSpace = 316,
     RTFspaceAbove = 317,
     RTFstyle = 318,
     RTFbold = 319,
     RTFitalic = 320,
     RTFunderline = 321,
     RTFunderlineStop = 322,
     RTFunichar = 323,
     RTFsubscript = 324,
     RTFsuperscript = 325,
     RTFtabstop = 326,
     RTFfcharset = 327,
     RTFfprq = 328,
     RTFcpg = 329,
     RTFOtherStatement = 330,
     RTFfontListStart = 331,
     RTFfamilyNil = 332,
     RTFfamilyRoman = 333,
     RTFfamilySwiss = 334,
     RTFfamilyModern = 335,
     RTFfamilyScript = 336,
     RTFfamilyDecor = 337,
     RTFfamilyTech = 338
   };
#endif
/* Tokens.  */
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
#define RTFNeXTGraphic 294
#define RTFNeXTGraphicWidth 295
#define RTFNeXTGraphicHeight 296
#define RTFNeXTHelpLink 297
#define RTFNeXTHelpMarker 298
#define RTFNeXTfilename 299
#define RTFNeXTmarkername 300
#define RTFNeXTlinkFilename 301
#define RTFNeXTlinkMarkername 302
#define RTFpaperWidth 303
#define RTFpaperHeight 304
#define RTFmarginLeft 305
#define RTFmarginRight 306
#define RTFmarginTop 307
#define RTFmarginButtom 308
#define RTFfirstLineIndent 309
#define RTFleftIndent 310
#define RTFrightIndent 311
#define RTFalignCenter 312
#define RTFalignJustified 313
#define RTFalignLeft 314
#define RTFalignRight 315
#define RTFlineSpace 316
#define RTFspaceAbove 317
#define RTFstyle 318
#define RTFbold 319
#define RTFitalic 320
#define RTFunderline 321
#define RTFunderlineStop 322
#define RTFunichar 323
#define RTFsubscript 324
#define RTFsuperscript 325
#define RTFtabstop 326
#define RTFfcharset 327
#define RTFfprq 328
#define RTFcpg 329
#define RTFOtherStatement 330
#define RTFfontListStart 331
#define RTFfamilyNil 332
#define RTFfamilyRoman 333
#define RTFfamilySwiss 334
#define RTFfamilyModern 335
#define RTFfamilyScript 336
#define RTFfamilyDecor 337
#define RTFfamilyTech 338




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 81 "rtfGrammar.y"
{
	int		number;
	const char	*text;
	RTFcmd		cmd;
}
/* Line 1529 of yacc.c.  */
#line 221 "rtfGrammar.tab.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



