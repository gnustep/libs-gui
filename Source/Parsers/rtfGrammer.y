/* rtfGrammer.y

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Stefan Bðhringer (stefan.boehringer@uni-bochum.de)
   Date: Dec 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

/*  
  if processed using -p GSRTFP (as recommended) it will introduce the following global symbols:
  'GSRTFPparse', `GSRTFPlex', `GSRTFPerror', `GSRTFPnerrs', `GSRTFPlval',
  `GSRTFPchar', `GSRTFPdebug
*/

/*	we request for a reentrant parser	*/
%pure_parser

%{

/*
  The overall plan is to make this grammer universal in usage.
  Intrested buddies can implement plain C functions to consume what
  the grammer is producing. this way the rtf-grammer-tree can be
  converted to what is needed: GNUstep attributed strings, tex files,
  ...
  
  The plan is laid out by defining a set of C functions which cover
  all what is needed to mangle rtf information (it is NeXT centric
  however and may even lack some features).  Be aware that some
  functions are called at specific times when some information may or
  may not be available. The first argument of all functions is a
  context, which is asked to be maintained by the consumer at
  whichever purpose seems appropriate.  This context must be passed to
  the parser by issuing 'value = GSRTFparse(ctxt, lctxt);' in the
  first place.
*/

#include <stdlib.h>
#include <string.h>
#include "Parsers/rtfScanner.h"

/*	this context is passed to the interface functions	*/
typedef void	* GSRTFctxt;
#define YYPARSE_PARAM	ctxt, lctxt
#define YYLEX_PARAM		lctxt

#define	YYERROR_VERBOSE

#include "rtfConsumerFunctions.h"

%}

%union {
	int			number;
	const char	*text;
	RTFcmd		cmd;
}

/*	<!><p> RTFtext values have to be freed	*/
%token <text> RTFtext
%token RTFstart
%token <cmd> RTFfont
%token <cmd> RTFfontSize
%token <cmd> RTFpaperWidth
%token <cmd> RTFpaperHeight
%token <cmd> RTFmarginLeft
%token <cmd> RTFmarginRight
%token <cmd> RTFbold
%token <cmd> RTFitalic
%token <cmd> RTFunderline
%token <cmd> RTFunderlineStop
%token <cmd> RTFOtherStatement
%token RTFfontListStart

//	<!> we assume token numbers to be sequential
//	\fnil | \froman | \fswiss | \fmodern | \fscript | \fdecor | \ftech
//	look at rtfScanner.h for enum definition
%token	RTFfamilyNil
%token	RTFfamilyRoman
%token	RTFfamilySwiss
%token	RTFfamilyModern
%token	RTFfamilyScript
%token	RTFfamilyDecor
%token	RTFfamilyTech

%type	<number> rtfFontFamily rtfStatement rtfGeneralStatement rtfBlockStatement rtfFontStatement

/*	let's go	*/

%%

rtfText:	{ GSRTFstart(ctxt); } rtfBlock { GSRTFstop(ctxt); }
		;

rtfBlock:	'{' { GSRTFopenBlock(ctxt); } rtfIngredients '}' { GSRTFcloseBlock(ctxt); }
		;

rtfIngredients:	/*	empty	*/
		|	rtfIngredients rtfStatement
		|	rtfIngredients RTFtext		{ GSRTFmangleText(ctxt, $2); free((void *)$2); }
		|	rtfIngredients rtfBlock
		;


/*
	RTF statements start with a '\', have a alpha name and a number argument
*/

rtfGeneralStatement:	rtfBlockStatement
		|	rtfStatement
		;

rtfBlockStatement:	'{' rtfStatement '}'	{ $$=0; }
		;

rtfStatement: RTFstart			{ $$=0; }
		|	rtfFontList			{ $$=0; }
		|	RTFfont				{ $$=0; GSRTFchangeFontTo(ctxt, $1.parameter); }
		|	RTFfontSize			{ $$=0; GSRTFchangeFontSizeTo(ctxt, $1.parameter); }
		|	RTFpaperWidth		{ $$=0; }
		|	RTFpaperHeight		{ $$=0; }
		|	RTFmarginLeft		{ $$=0; }
		|	RTFmarginRight		{ $$=0; }
		|	RTFbold				{ $$=0; GSRTFhandleBoldAttribute(ctxt, $1.isEmpty || !!$1.parameter); }
		|	RTFitalic			{ $$=0; GSRTFhandleItalicAttribute(ctxt, $1.isEmpty || !!$1.parameter); }
		|	RTFunderline		{ $$=0; }
		|	RTFunderlineStop	{ $$=0; }
		|	RTFOtherStatement	{ $$=0; GSRTFgenericRTFcommand(ctxt, $1); }
		;

/*
	Font description
*/

rtfFontList: RTFfontListStart rtfFonts
		;

rtfFonts:
		|	rtfFonts rtfFontStatement
		|	rtfFonts '{' rtfFontStatement '}'

		;

					/* the first RTFfont tags the font with a number */
					/* RTFtext introduces the fontName */
rtfFontStatement:	RTFfont rtfFontFamily RTFtext	{	$$=0; GSRTFregisterFont(ctxt, $3, $2, $1.parameter);
														free((void *)$3);
													}
		;

rtfFontFamily:
			RTFfamilyNil	{ $$ = RTFfamilyNil - RTFfamilyNil; }
		|	RTFfamilyRoman	{ $$ = RTFfamilyRoman - RTFfamilyNil; }
		|	RTFfamilySwiss	{ $$ = RTFfamilySwiss - RTFfamilyNil; }
		|	RTFfamilyModern	{ $$ = RTFfamilyModern - RTFfamilyNil; }
		|	RTFfamilyScript	{ $$ = RTFfamilyScript - RTFfamilyNil; }
		|	RTFfamilyDecor	{ $$ = RTFfamilyDecor - RTFfamilyNil; }
		|	RTFfamilyTech	{ $$ = RTFfamilyTech - RTFfamilyNil; }
		;


/*
	Font description end
*/

/*
	some cludgy trailer
*/
dummyNonTerminal: '\\' { @1.first_line; }	/* we introduce a @n to fix the lex attributes */
		;

%%

/*	some C code here	*/

