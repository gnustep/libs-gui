/* rtfConsumerFunctions.h created by pingu on Wed 17-Nov-1999

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

/*	here we define the interface functions to grammer consumers */

#ifndef rtfConsumerFunctions_h_INCLUDE
#define rtfConsumerFunctions_h_INCLUDE

#include	"Parsers/rtfScanner.h"

/* general statements:
   measurement is usually in twips: one twentieth of a point (this is about 0.01764 mm)
   a tabstop of 540 twips (as it occurs on NeXT) is therefore about 0.95 cm
*/

/*	prepare the ctxt, or whatever you want	*/
void	GSRTFstart(void *ctxt);

/*	seal the parsing process, the context or whatever you want	*/
void	GSRTFstop(void *ctxt);

/*	those pairing functions enclose RTFBlocks. Use it to capture the hierarchical attribute changes of blocks.
	i.e. attributes of a block are forgotten once a block is closed
*/
void	GSRTFopenBlock(void *ctxt);
void	GSRTFcloseBlock(void *ctxt);

/*	handle errors	*/
void	GSRTFerror(const char *msg);

/*	handle rtf commands not expicated in the grammer */
void	GSRTFgenericRTFcommand(void *ctxt, RTFcmd cmd);

/*	go, handle text	*/
void	GSRTFmangleText(void *ctxt, const char *text);

/*
	font functions
*/

/* get noticed that a particular font is introduced the font number is
   introduced by an prededing GSRTFchangeFontTo call this state
   can be recognized by the fact that the fontNumber in question
   is unseen by then */
void	GSRTFregisterFont(void *ctxt, const char *fontName, 
			  RTFfontFamily family, int fontNumber);

/* this function is twofold: change font in character stream [you must
   maintain stream info in ctxt]; introduce fonts in the first place */
void	GSRTFchangeFontTo(void *ctxt, int fontNumber);
/*	subject says it all */
void	GSRTFchangeFontSizeTo(void *ctxt, int fontSize);

#endif
