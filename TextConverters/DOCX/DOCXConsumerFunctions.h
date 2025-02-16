/* docxConsumerFunctions.h created by pingu on Wed 17-Nov-1999

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Stefan Böhringer (stefan.boehringer@uni-bochum.de)
   Date: Dec 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

/*	here we define the interface functions to grammer consumers */

#ifndef docxConsumerFunctions_h_INCLUDE
#define docxConsumerFunctions_h_INCLUDE

#include	"docxScanner.h"

/* general statements:
 * measurement is usually in twips: one twentieth of a point (this is
 * about 0.01764 mm) a tabstop of 540 twips (as it occurs on NeXT) is
 * therefore about 0.95 cm
 */
#define halfpoints2points(a) ((a)/2.0)
#define twips2points(a) ((a)/20.0)
#define twips2mm(a) ((a)*0.01764)

/* prepare the ctxt, or whatever you want */
void GSDOCXstart(void *ctxt);

/* seal the parsing process, the context or whatever you want */
void GSDOCXstop(void *ctxt);

/* */
int GSDOCXgetPosition(void *ctxt);

/*
 * those pairing functions enclose DOCXBlocks. Use it to capture the
 * hierarchical attribute changes of blocks.  i.e. attributes of a
 * block are forgotten once a block is closed
 */
void GSDOCXopenBlock(void *ctxt, BOOL ignore);
void GSDOCXcloseBlock(void *ctxt, BOOL ignore);

/* handle errors */
void GSDOCXerror(void *ctxt, void *lctxt, const char *msg);

/* handle docx commands not expicated in the grammer */
void GSDOCXgenericDOCXcommand(void *ctxt, DOCXcmd cmd);

/* go, handle text */
void GSDOCXmangleText(void *ctxt, const char *text);
void GSDOCXunicode (void *ctxt, int uchar);

/*
 * font functions
 */

/* get noticed that a particular font is introduced */
void GSDOCXregisterFont(void *ctxt, const char *fontName, 
		       DOCXfontFamily family, int fontNumber);

/* change font number */
void GSDOCXfontNumber(void *ctxt, int fontNumber);
/* change font size in half points*/
void GSDOCXfontSize(void *ctxt, int fontSize);

/* set paper width in twips */
void GSDOCXpaperWidth(void *ctxt, int width);
/* set paper height in twips */
void GSDOCXpaperHeight(void *ctxt, int height);
/* set left margin in twips */
void GSDOCXmarginLeft(void *ctxt, int margin);
/* set right margin in twips */
void GSDOCXmarginRight(void *ctxt, int margin);
/* set top margin in twips */
void GSDOCXmarginTop(void *ctxt, int margin);
/* set buttom margin in twips */
void GSDOCXmarginButtom(void *ctxt, int margin);
/* set first line indent */
void GSDOCXfirstLineIndent(void *ctxt, int indent);
/* set left indent */
void GSDOCXleftIndent(void *ctxt, int indent);
/* set right indent */
void GSDOCXrightIndent(void *ctxt, int indent);
/* set tabstop */
void GSDOCXtabstop(void *ctxt, int location);
/* set center alignment */
void GSDOCXalignCenter(void *ctxt);
/* set justified alignment */
void GSDOCXalignJustified(void *ctxt);
/* set left alignment */
void GSDOCXalignLeft(void *ctxt);
/* set right alignment */
void GSDOCXalignRight(void *ctxt);
/* set space above */
void GSDOCXspaceAbove(void *ctxt, int location);
/* set line space */
void GSDOCXlineSpace(void *ctxt, int location);
/* set default paragraph style */
void GSDOCXdefaultParagraph(void *ctxt);
/* set paragraph style */
void GSDOCXstyle(void *ctxt, int style);
/* Add a colour to the colour table*/
void GSDOCXaddColor(void *ctxt, int red, int green, int blue);
/* Add the default colour to the colour table*/
void GSDOCXaddDefaultColor(void *ctxt);
/* set background colour */
void GSDOCXcolorbg(void *ctxt, int color);
/* set foreground colour */
void GSDOCXcolorfg(void *ctxt, int color);
/* set underline colour */
void GSDOCXunderlinecolor(void *ctxt, int color);
/* set default character style */
void GSDOCXdefaultCharacterStyle(void *ctxt);
/* set subscript in half points */
void GSDOCXsubscript(void *ctxt, int script);
/* set superscript in half points */
void GSDOCXsuperscript(void *ctxt, int script);
/* Switch bold mode on or off */
void GSDOCXbold(void *ctxt, BOOL on);
/* Switch italic mode on or off */
void GSDOCXitalic(void *ctxt, BOOL on);
/* Set the underline style */
void GSDOCXunderline(void *ctxt, BOOL on, NSInteger style);
/* Set the strikethrough style */
void GSDOCXstrikethrough(void *ctxt, NSInteger style);
/* new paragraph */
void GSDOCXparagraph(void *ctxt);
/* NeXTGraphic */
void GSDOCXNeXTGraphic(void *ctxt, const char *fileName, int width, int height);
/* NeXTHelpLink */
void GSDOCXNeXTHelpLink(void *ctxt, int num, const char *markername,
		       const char *linkFilename, const char *linkMarkername);
/* NeXTHelpMarker */
void GSDOCXNeXTHelpMarker(void *ctxt, int num, const char *markername);

void GSDOCXaddField (void *ctxt, int start, const char *inst);

/* set encoding */
void GSDOCXencoding(void *ctxt, int encoding);

#endif

