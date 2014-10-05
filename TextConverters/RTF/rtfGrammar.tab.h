/* A Bison parser, made by GNU Bison 2.7.  */

/* Bison interface for Yacc-like parsers in C
   
      Copyright (C) 1984, 1989-1990, 2000-2012 Free Software Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

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

#ifndef YY_GSRTF_RTFGRAMMAR_TAB_H_INCLUDED
# define YY_GSRTF_RTFGRAMMAR_TAB_H_INCLUDED
/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int GSRTFdebug;
#endif

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
     RTFfield = 282,
     RTFfldinst = 283,
     RTFfldalt = 284,
     RTFfldrslt = 285,
     RTFflddirty = 286,
     RTFfldedit = 287,
     RTFfldlock = 288,
     RTFfldpriv = 289,
     RTFfttruetype = 290,
     RTFlquote = 291,
     RTFrquote = 292,
     RTFldblquote = 293,
     RTFrdblquote = 294,
     RTFred = 295,
     RTFgreen = 296,
     RTFblue = 297,
     RTFcolorbg = 298,
     RTFcolorfg = 299,
     RTFunderlinecolor = 300,
     RTFcolortable = 301,
     RTFfont = 302,
     RTFfontSize = 303,
     RTFNeXTGraphic = 304,
     RTFNeXTGraphicWidth = 305,
     RTFNeXTGraphicHeight = 306,
     RTFNeXTHelpLink = 307,
     RTFNeXTHelpMarker = 308,
     RTFNeXTfilename = 309,
     RTFNeXTmarkername = 310,
     RTFNeXTlinkFilename = 311,
     RTFNeXTlinkMarkername = 312,
     RTFpaperWidth = 313,
     RTFpaperHeight = 314,
     RTFmarginLeft = 315,
     RTFmarginRight = 316,
     RTFmarginTop = 317,
     RTFmarginButtom = 318,
     RTFfirstLineIndent = 319,
     RTFleftIndent = 320,
     RTFrightIndent = 321,
     RTFalignCenter = 322,
     RTFalignJustified = 323,
     RTFalignLeft = 324,
     RTFalignRight = 325,
     RTFlineSpace = 326,
     RTFspaceAbove = 327,
     RTFstyle = 328,
     RTFbold = 329,
     RTFitalic = 330,
     RTFunderline = 331,
     RTFunderlineDot = 332,
     RTFunderlineDash = 333,
     RTFunderlineDashDot = 334,
     RTFunderlineDashDotDot = 335,
     RTFunderlineDouble = 336,
     RTFunderlineStop = 337,
     RTFunderlineThick = 338,
     RTFunderlineThickDot = 339,
     RTFunderlineThickDash = 340,
     RTFunderlineThickDashDot = 341,
     RTFunderlineThickDashDotDot = 342,
     RTFunderlineWord = 343,
     RTFstrikethrough = 344,
     RTFstrikethroughDouble = 345,
     RTFunichar = 346,
     RTFsubscript = 347,
     RTFsuperscript = 348,
     RTFtabstop = 349,
     RTFfcharset = 350,
     RTFfprq = 351,
     RTFcpg = 352,
     RTFOtherStatement = 353,
     RTFfontListStart = 354,
     RTFfamilyNil = 355,
     RTFfamilyRoman = 356,
     RTFfamilySwiss = 357,
     RTFfamilyModern = 358,
     RTFfamilyScript = 359,
     RTFfamilyDecor = 360,
     RTFfamilyTech = 361,
     RTFfamilyBiDi = 362
   };
#endif


#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
{
/* Line 2058 of yacc.c  */
#line 85 "rtfGrammar.y"

	int		number;
	const char	*text;
	RTFcmd		cmd;


/* Line 2058 of yacc.c  */
#line 171 "rtfGrammar.tab.h"
} YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif


#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int GSRTFparse (void *YYPARSE_PARAM);
#else
int GSRTFparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int GSRTFparse (void *ctxt, void *lctxt);
#else
int GSRTFparse ();
#endif
#endif /* ! YYPARSE_PARAM */

#endif /* !YY_GSRTF_RTFGRAMMAR_TAB_H_INCLUDED  */
