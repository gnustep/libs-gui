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
     RTFpaperWidth = 297,
     RTFpaperHeight = 298,
     RTFmarginLeft = 299,
     RTFmarginRight = 300,
     RTFmarginTop = 301,
     RTFmarginButtom = 302,
     RTFfirstLineIndent = 303,
     RTFleftIndent = 304,
     RTFrightIndent = 305,
     RTFalignCenter = 306,
     RTFalignJustified = 307,
     RTFalignLeft = 308,
     RTFalignRight = 309,
     RTFlineSpace = 310,
     RTFspaceAbove = 311,
     RTFstyle = 312,
     RTFbold = 313,
     RTFitalic = 314,
     RTFunderline = 315,
     RTFunderlineStop = 316,
     RTFunichar = 317,
     RTFsubscript = 318,
     RTFsuperscript = 319,
     RTFtabstop = 320,
     RTFfcharset = 321,
     RTFfprq = 322,
     RTFcpg = 323,
     RTFOtherStatement = 324,
     RTFfontListStart = 325,
     RTFfamilyNil = 326,
     RTFfamilyRoman = 327,
     RTFfamilySwiss = 328,
     RTFfamilyModern = 329,
     RTFfamilyScript = 330,
     RTFfamilyDecor = 331,
     RTFfamilyTech = 332
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
#define RTFpaperWidth 297
#define RTFpaperHeight 298
#define RTFmarginLeft 299
#define RTFmarginRight 300
#define RTFmarginTop 301
#define RTFmarginButtom 302
#define RTFfirstLineIndent 303
#define RTFleftIndent 304
#define RTFrightIndent 305
#define RTFalignCenter 306
#define RTFalignJustified 307
#define RTFalignLeft 308
#define RTFalignRight 309
#define RTFlineSpace 310
#define RTFspaceAbove 311
#define RTFstyle 312
#define RTFbold 313
#define RTFitalic 314
#define RTFunderline 315
#define RTFunderlineStop 316
#define RTFunichar 317
#define RTFsubscript 318
#define RTFsuperscript 319
#define RTFtabstop 320
#define RTFfcharset 321
#define RTFfprq 322
#define RTFcpg 323
#define RTFOtherStatement 324
#define RTFfontListStart 325
#define RTFfamilyNil 326
#define RTFfamilyRoman 327
#define RTFfamilySwiss 328
#define RTFfamilyModern 329
#define RTFfamilyScript 330
#define RTFfamilyDecor 331
#define RTFfamilyTech 332




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 81 "rtfGrammar.y"
{
	int		number;
	const char	*text;
	RTFcmd		cmd;
}
/* Line 1529 of yacc.c.  */
#line 209 "rtfGrammar.tab.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



