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
%token RTFansi
%token RTFmac
%token RTFpc
%token RTFpca
%token RTFignore
%token RTFinfo
%token RTFstylesheet
%token RTFfootnote
%token RTFheader
%token RTFfooter
%token RTFpict
%token <cmd> RTFred
%token <cmd> RTFgreen
%token <cmd> RTFblue
%token <cmd> RTFcolorbg
%token <cmd> RTFcolorfg
%token <cmd> RTFcolortable
%token <cmd> RTFfont
%token <cmd> RTFfontSize
%token <cmd> RTFpaperWidth
%token <cmd> RTFpaperHeight
%token <cmd> RTFmarginLeft
%token <cmd> RTFmarginRight
%token <cmd> RTFmarginTop
%token <cmd> RTFmarginButtom
%token <cmd> RTFfirstLineIndent
%token <cmd> RTFleftIndent
%token <cmd> RTFrightIndent
%token <cmd> RTFalignCenter
%token <cmd> RTFalignLeft
%token <cmd> RTFalignRight
%token <cmd> RTFstyle
%token <cmd> RTFbold
%token <cmd> RTFitalic
%token <cmd> RTFunderline
%token <cmd> RTFunderlineStop
%token <cmd> RTFsubscript
%token <cmd> RTFsuperscript
%token <cmd> RTFtabulator
%token <cmd> RTFtabstop
%token <cmd> RTFparagraph
%token <cmd> RTFdefaultParagraph
%token <cmd> RTFfcharset
%token <cmd> RTFfprq
%token <cmd> RTFcpg
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

%type	<number> rtfFontFamily rtfCharset rtfFontStatement

/*	let's go	*/

%%

rtfFile:	'{' { GSRTFstart(ctxt); } RTFstart rtfCharset rtfIngredients { GSRTFstop(ctxt); } '}'
		;

rtfCharset: RTFansi { $$ = 1; }
		|	RTFmac { $$ = 2; }
		|	RTFpc  { $$ = 3; }
		|	RTFpca { $$ = 4; }
		;

rtfIngredients:	/*	empty	*/
		|	rtfIngredients rtfFontList
		|	rtfIngredients rtfColorDef
		|	rtfIngredients rtfStatement
		|	rtfIngredients RTFtext		{ GSRTFmangleText(ctxt, $2); free((void *)$2); }
		|	rtfIngredients rtfBlock
		;

rtfBlock:	'{' { GSRTFopenBlock(ctxt, NO); } rtfIngredients '}' { GSRTFcloseBlock(ctxt, NO); }
		|	'{' { GSRTFopenBlock(ctxt, YES); } RTFignore rtfIngredients '}' { GSRTFcloseBlock(ctxt, YES); }
		|	'{' { GSRTFopenBlock(ctxt, YES); } RTFinfo rtfIngredients '}' { GSRTFcloseBlock(ctxt, YES); }
		|	'{' { GSRTFopenBlock(ctxt, YES); } RTFstylesheet rtfIngredients '}' { GSRTFcloseBlock(ctxt, YES); }
		|	'{' { GSRTFopenBlock(ctxt, YES); } RTFfootnote rtfIngredients '}' { GSRTFcloseBlock(ctxt, YES); }
		|	'{' { GSRTFopenBlock(ctxt, YES); } RTFheader rtfIngredients '}' { GSRTFcloseBlock(ctxt, YES); }
		|	'{' { GSRTFopenBlock(ctxt, YES); } RTFfooter rtfIngredients '}' { GSRTFcloseBlock(ctxt, YES); }
		|	'{' { GSRTFopenBlock(ctxt, YES); } RTFpict rtfIngredients '}' { GSRTFcloseBlock(ctxt, YES); }
                |	'{'  '}' /* empty */
		;


/*
	RTF statements start with a '\', have a alpha name and a number argument
*/

rtfStatement: RTFfont				{ int font;
		    
						  if ($1.isEmpty)
						      font = 0;
						  else
						      font = $1.parameter;
						  GSRTFfontNumber(ctxt, font); }
		|	RTFfontSize		{ int size;

						  if ($1.isEmpty)
						      size = 24;
						  else
						      size = $1.parameter;
						  GSRTFfontSize(ctxt, size); }
		|	RTFpaperWidth		{ int width; 
		
		                                  if ($1.isEmpty)
						      width = 12240;
						  else
						      width = $1.parameter;
						  GSRTFpaperWidth(ctxt, width);}
		|	RTFpaperHeight		{ int height; 
		
		                                  if ($1.isEmpty)
						      height = 15840;
						  else
						      height = $1.parameter;
						  GSRTFpaperHeight(ctxt, height);}
		|	RTFmarginLeft		{ int margin; 
		
		                                  if ($1.isEmpty)
						      margin = 1800;
						  else
						      margin = $1.parameter;
						  GSRTFmarginLeft(ctxt, margin);}
		|	RTFmarginRight		{ int margin; 
		
		                                  if ($1.isEmpty)
						      margin = 1800;
						  else
						      margin = $1.parameter;
						  GSRTFmarginRight(ctxt, margin); }
		|	RTFmarginTop		{ int margin; 
		
		                                  if ($1.isEmpty)
						      margin = 1440;
						  else
						      margin = $1.parameter;
						  GSRTFmarginTop(ctxt, margin); }
		|	RTFmarginButtom		{ int margin; 
		
		                                  if ($1.isEmpty)
						      margin = 1440;
						  else
						      margin = $1.parameter;
						  GSRTFmarginButtom(ctxt, margin); }
		|	RTFfirstLineIndent	{ int indent; 
		
		                                  if ($1.isEmpty)
						      indent = 0;
						  else
						      indent = $1.parameter;
						  GSRTFfirstLineIndent(ctxt, indent); }
		|	RTFleftIndent		{ int indent; 
		
		                                  if ($1.isEmpty)
						      indent = 0;
						  else
						      indent = $1.parameter;
						  GSRTFleftIndent(ctxt, indent);}
		|	RTFrightIndent		{ int indent; 
		
		                                  if ($1.isEmpty)
						      indent = 0;
						  else
						      indent = $1.parameter;
						  GSRTFrightIndent(ctxt, indent);}
		|	RTFtabstop		{ int location; 
		
		                                  if ($1.isEmpty)
						      location = 0;
						  else
						      location = $1.parameter;
						  GSRTFtabstop(ctxt, location);}
		|	RTFalignCenter		{ GSRTFalignCenter(ctxt); }
		|	RTFalignLeft		{ GSRTFalignLeft(ctxt); }
		|	RTFalignRight		{ GSRTFalignRight(ctxt); }
		|	RTFdefaultParagraph	{ GSRTFdefaultParagraph(ctxt); }
		|	RTFstyle		{ GSRTFstyle(ctxt, $1.parameter); }
		|	RTFcolorbg		{ int color; 
		
		                                  if ($1.isEmpty)
						      color = 0;
						  else
						      color = $1.parameter;
						  GSRTFcolorbg(ctxt, color); }
		|	RTFcolorfg		{ int color; 
		
		                                  if ($1.isEmpty)
						      color = 0;
						  else
						      color = $1.parameter;
						  GSRTFcolorfg(ctxt, color); }
		|	RTFsubscript		{ int script;
		
		                                  if ($1.isEmpty)
						      script = 6;
						  else
						      script = $1.parameter;
						  GSRTFsubscript(ctxt, script); }
		|	RTFsuperscript		{ int script;
		
		                                  if ($1.isEmpty)
						      script = 6;
						  else
						      script = $1.parameter;
						  GSRTFsuperscript(ctxt, script); }
		|	RTFbold			{ BOOL on;

		                                  if ($1.isEmpty || $1.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFbold(ctxt, on); }
		|	RTFitalic		{ BOOL on;

		                                  if ($1.isEmpty || $1.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFitalic(ctxt, on); }
		|	RTFunderline		{ BOOL on;

		                                  if ($1.isEmpty || $1.parameter)
						      on = YES;
						  else
						      on = NO;
						  GSRTFunderline(ctxt, on); }
		|	RTFunderlineStop	{ GSRTFunderline(ctxt, NO); }
		|	RTFOtherStatement	{ GSRTFgenericRTFcommand(ctxt, $1); }
		;

/*
	Font description
*/

rtfFontList: '{' RTFfontListStart rtfFonts '}'
		;

rtfFonts:
		|	rtfFonts rtfFontStatement
		|	rtfFonts '{' rtfFontStatement '}'

		;

/* the first RTFfont tags the font with a number */
/* RTFtext introduces the fontName */
rtfFontStatement:	RTFfont rtfFontFamily rtfFontAttrs RTFtext	{ GSRTFregisterFont(ctxt, $4, $2, $1.parameter);
                                                          free((void *)$4); }
		;

rtfFontAttrs: /* empty */
                | rtfFontAttrs RTFfcharset 
                | rtfFontAttrs RTFfprq
                | rtfFontAttrs RTFcpg
                | rtfFontAttrs rtfBlock
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

rtfColorDef: '{' RTFcolortable rtfColors '}'
		;

rtfColors: /* empty */
 		|	rtfColors rtfColorStatement
		;

/* We get the ';' as RTFText */
rtfColorStatement: RTFred RTFgreen RTFblue RTFtext 
                     { 
		       GSRTFaddColor(ctxt, $1.parameter, $2.parameter, $3.parameter);
		       free((void *)$4);
		     }
 		|	RTFtext 
                     { 
		       GSRTFaddDefaultColor(ctxt);
		       free((void *)$1);
		     }
		;

/*
	some cludgy trailer
*/
dummyNonTerminal: '\\' { @1.first_line; }	/* we introduce a @n to fix the lex attributes */
		;

%%

/*	some C code here	*/

