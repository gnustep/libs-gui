/* attributedStringConsumer.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Stefan Bðhringer (stefan.boehringer@uni-bochum.de)
   Date: Dec 1999
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: June 2000

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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "Parsers/rtfConsumer.h"
#include "Parsers/rtfConsumerFunctions.h"

/*  we have to satisfy the scanner with a stream reading function */
typedef struct {
  NSString	*string;
  int		position;
  int		length;
} StringContext;

static void	
initStringContext(StringContext *ctxt, NSString *string)
{
  ctxt->string = string;
  ctxt->position = 0;
  ctxt->length = [string length];
}

static int	
readNSString(StringContext *ctxt)
{
  return (ctxt->position < ctxt->length )
    ? [ctxt->string characterAtIndex:ctxt->position++]: EOF;
}

/*
  we must implement from the rtfConsumerSkeleton.h file (Supporting files)
  this includes the yacc error handling and output
*/

// Hold the attributs of the current run
@interface RTFAttribute: NSObject <NSCopying>
{
@public
  BOOL changed;
  NSParagraphStyle *paragraph;
  NSColor *fgColour;
  NSColor *bgColour;
  NSString *fontName;
  float fontSize;
  BOOL bold;
  BOOL italic;
  BOOL underline;
  int script;
}

- (NSFont*) currentFont;

@end

@implementation RTFAttribute

- (id) init
{
  NSFont *font = [NSFont userFontOfSize:12];

  ASSIGN(fontName, [font familyName]);
  fontSize = 12.0;
  italic = NO;
  bold = NO;
  underline = NO;
  script = 0;
  paragraph = [NSMutableParagraphStyle defaultParagraphStyle];
  changed = YES;

  return self;
}

- (void) dealloc
{
  RELEASE(paragraph);
  RELEASE(fontName);
  RELEASE(fgColour);
  RELEASE(bgColour);
  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  RTFAttribute *new = [isa allocWithZone: zone];

  new->paragraph = [paragraph copyWithZone: zone];
  new->fontName = [fontName copyWithZone: zone];
  new->fontSize = fontSize;
  new->italic = italic;
  new->bold = bold;
  new->underline = underline;
  new->script = script;
  new->changed = NO;

  return new;
}

- (NSFont*) currentFont
{
  NSFont *font;
  NSFontTraitMask traits = 0;
  int weight;

  if (bold)
    {
      weight = 9;
      traits |= NSBoldFontMask;
    }
  else
    {
      weight = 6;
      traits |= NSUnboldFontMask;
    }

  if (italic)
    {
      traits |= NSItalicFontMask;
    }
  else
    {
      traits |= NSUnitalicFontMask;
    }

  font = [[NSFontManager sharedFontManager] fontWithFamily: fontName
					    traits: traits
					    weight: weight
					    size: fontSize];
  return font;
}
 
@end

@interface RTFConsumer: NSObject
{
@public
  NSMutableDictionary *documentAttributes;
  NSMutableDictionary *fonts;
  NSMutableArray *colours;
  NSMutableArray *attrs;
  NSMutableAttributedString *result;
  int textPosition;
  int ignore;
}

- (NSDictionary*) documentAttributes;
- (RTFAttribute*) attr;
- (void) push;
- (void) pop;
- (NSAttributedString*) result;

@end

@implementation RTFConsumer

- (id) init
{
  RTFAttribute *attr = [RTFAttribute new];

  textPosition = 0;
  ignore = 0;  
  result = [[NSMutableAttributedString alloc] init];
  ASSIGN(documentAttributes, [NSMutableDictionary dictionary]);
  ASSIGN(fonts, [NSMutableDictionary dictionary]);
  ASSIGN(attrs, [NSMutableArray array]);
  ASSIGN(colours, [NSMutableArray array]);
  [attrs addObject: attr];

  return self;
}

- (void)dealloc
{
  RELEASE(fonts);
  RELEASE(attrs);
  RELEASE(colours);
  RELEASE(result);
  RELEASE(documentAttributes);
  [super dealloc];
}

- (NSDictionary*) documentAttributes
{
  RETAIN(documentAttributes);
  return AUTORELEASE(documentAttributes);
}

- (RTFAttribute*) attr
{
  return [attrs lastObject];
}

- (void) push
{
  [attrs addObject: [[attrs lastObject] copy]];
}

- (void) pop
{
  [attrs removeLastObject];
}

- (NSAttributedString*) result
{
  RETAIN(result);
  return AUTORELEASE(result);
}

- (NSAttributedString*) parseRTF: (NSData *)rtfData 
	      documentAttributes: (NSDictionary **)dict
{
  CREATE_AUTORELEASE_POOL(pool);
  RTFscannerCtxt scanner;
  StringContext stringCtxt;
  NSString *rtfString = [[NSString alloc] 
			    initWithData: rtfData
			    encoding: NSASCIIStringEncoding];

  // Has this RFTConsumer allready been used? Is so, reset!
  if (textPosition)
    [self init];

  initStringContext(&stringCtxt, rtfString);
  lexInitContext(&scanner, &stringCtxt, (int (*)(void*))readNSString);
  NS_DURING
    GSRTFparse((void *)self, &scanner);
  NS_HANDLER
    NSLog(@"Problem during RTF Parsing: %@", 
	  [localException reason]);
  //[localException raise];
  NS_ENDHANDLER

  RELEASE(pool);
  // document attributes
  if (dict)
    *dict = [self documentAttributes];

  return [self result];
}

@end

#define	FONTS	((RTFConsumer *)ctxt)->fonts
#define	COLOURS	((RTFConsumer *)ctxt)->colours
#define	RESULT	((RTFConsumer *)ctxt)->result
#define	IGNORE	((RTFConsumer *)ctxt)->ignore
#define	TEXTPOSITION ((RTFConsumer *)ctxt)->textPosition
#define DOCUMENTATTRIBUTES ((RTFConsumer*)ctxt)->documentAttributes

#define	CTXT	[((RTFConsumer *)ctxt) attr]
#define	CHANGED	CTXT->changed
#define	PARAGRAPH CTXT->paragraph
#define	FONTNAME CTXT->fontName
#define	SCRIPT CTXT->script
#define	ITALIC CTXT->italic
#define	BOLD CTXT->bold
#define	UNDERLINE CTXT->underline
#define	FGCOLOUR CTXT->fgColour
#define	BGCOLOUR CTXT->bgColour

#define PAPERSIZE @"PaperSize"
#define LEFTMARGIN @"LeftMargin"
#define RIGHTMARGIN @"RightMargin"
#define TOPMARGIN @"TopMargin"
#define BUTTOMMARGIN @"ButtomMargin"

/* handle errors (this is the yacc error mech)	*/
void GSRTFerror(const char *msg)
{
  [NSException raise:NSInvalidArgumentException 
	       format:@"Syntax error in RTF:%s", msg];
}

void GSRTFgenericRTFcommand(void *ctxt, RTFcmd cmd)
{
  NSLog(@"encountered rtf cmd:%s", cmd.name);
  if (cmd.isEmpty) 
      NSLog(@" argument is empty\n");
  else
      NSLog(@" argument is %d\n", cmd.parameter);
}

//Start: we're doing some initialization
void GSRTFstart(void *ctxt)
{
  [RESULT beginEditing];
}

// Finished to parse one piece of RTF.
void GSRTFstop(void *ctxt)
{
  //<!> close all open bolds et al.
  [RESULT endEditing];
}

void GSRTFopenBlock(void *ctxt, BOOL ignore)
{
  if (!IGNORE)
    [(RTFConsumer *)ctxt push];
  // Switch off any output for ignored block statements
  if (ignore)
    IGNORE++;
}

void GSRTFcloseBlock(void *ctxt, BOOL ignore)
{
  if (ignore)
    IGNORE--;
  if (!IGNORE)
    [(RTFConsumer *)ctxt pop];
}

void GSRTFmangleText(void *ctxt, const char *text)
{
  int  oldPosition = TEXTPOSITION;
  int  textlen = strlen(text); 
  int  newPosition = oldPosition + textlen;
  NSRange insertionRange = NSMakeRange(oldPosition,0);
  NSDictionary *attributes;
  NSFont *font;

  if (!IGNORE && textlen)
    {
      TEXTPOSITION = newPosition;
      
      [RESULT replaceCharactersInRange: insertionRange 
	      withString: [NSString stringWithCString:text]];

      if (CHANGED)
        {
	  font = [CTXT currentFont];
	  attributes = [NSDictionary dictionaryWithObjectsAndKeys:
					 font, NSFontAttributeName, 
				     SCRIPT, NSSuperscriptAttributeName,
				     PARAGRAPH, NSParagraphStyleAttributeName,
				     nil];
	  [RESULT setAttributes: attributes range: 
		      NSMakeRange(oldPosition, textlen)];
	  CHANGED = NO;
	}
    }
}

void GSRTFregisterFont(void *ctxt, const char *fontName, 
		       RTFfontFamily family, int fontNumber)
{
  NSString		*fontNameString;
  NSNumber		*fontId = [NSNumber numberWithInt: fontNumber];

  if (!fontName || !*fontName)
    {	
      [NSException raise:NSInvalidArgumentException 
		   format:@"Error in RTF (font omitted?), position:%d",
		   TEXTPOSITION];
    }
  // exclude trailing ';' from fontName
  fontNameString = [NSString stringWithCString: fontName 
			     length: strlen(fontName)-1];
  [FONTS setObject: fontNameString forKey: fontId];
}

void GSRTFfontNumber(void *ctxt, int fontNumber)
{
  NSNumber *fontId = [NSNumber numberWithInt: fontNumber];
  NSString *fontName = [FONTS objectForKey: fontId];

  if (fontName == nil)
    {
      /* we're about to set an unknown font */
      [NSException raise: NSInvalidArgumentException 
		   format: @"Error in RTF (referring to undefined font \\f%d), position:%d",
		   fontNumber,
		   TEXTPOSITION];
    } 
  else 
    {
      if (![fontName isEqual: FONTNAME])
        {
	    ASSIGN(FONTNAME, fontName);
	    CHANGED = YES;
	}
    }
}

//	<N> fontSize is in halfpoints according to spec
void GSRTFfontSize(void *ctxt, int fontSize)
{
  float size = halfpoints2points(fontSize);
  
  if (size != CTXT->fontSize)
    {
      CTXT->fontSize = size;
      CHANGED = YES;
    }
}

void GSRTFpaperWidth(void *ctxt, int width)
{
  float fwidth = twips2points(width);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;
  NSValue *val = [dict objectForKey: PAPERSIZE];
  NSSize size;

  if (val == nil)
    size = NSMakeSize(fwidth, 792);
  else
    {
      size = [val sizeValue];
      size.width = fwidth;
    }
  [dict setObject: [NSValue valueWithSize: size] forKey: PAPERSIZE];
}

void GSRTFpaperHeight(void *ctxt, int height)
{
  float fheight = twips2points(height);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;
  NSValue *val = [dict objectForKey: PAPERSIZE];
  NSSize size;

  if (val == nil)
    size = NSMakeSize(612, fheight);
  else
    {
      size = [val sizeValue];
      size.height = fheight;
    }
  [dict setObject: [NSValue valueWithSize: size] forKey: PAPERSIZE];
}

void GSRTFmarginLeft(void *ctxt, int margin)
{
  float fmargin = twips2points(margin);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;

  [dict setObject: [NSNumber numberWithFloat: fmargin] forKey: LEFTMARGIN];
}

void GSRTFmarginRight(void *ctxt, int margin)
{
  float fmargin = twips2points(margin);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;

  [dict setObject: [NSNumber numberWithFloat: fmargin] forKey: RIGHTMARGIN];
}

void GSRTFmarginTop(void *ctxt, int margin)
{
  float fmargin = twips2points(margin);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;

  [dict setObject: [NSNumber numberWithFloat: fmargin] forKey: TOPMARGIN];
}

void GSRTFmarginButtom(void *ctxt, int margin)
{
  float fmargin = twips2points(margin);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;

  [dict setObject: [NSNumber numberWithFloat: fmargin] forKey: BUTTOMMARGIN];
}

void GSRTFfirstLineIndent(void *ctxt, int indent)
{
  NSMutableParagraphStyle *para = PARAGRAPH;
  float findent = twips2points(indent);

  // for attributed strings only positiv indent is allowed
  if ((findent >= 0.0) && ([para firstLineHeadIndent] != findent))
    {
      [para setFirstLineHeadIndent: findent];
      CHANGED = YES;
    }
}

void GSRTFleftIndent(void *ctxt, int indent)
{
  NSMutableParagraphStyle *para = PARAGRAPH;
  float findent = twips2points(indent);

  // for attributed strings only positiv indent is allowed
  if ((findent >= 0.0) && ([para headIndent] != findent))
    {
      [para setHeadIndent: findent];
      CHANGED = YES;
    }
}

void GSRTFalignCenter(void *ctxt)
{
  NSMutableParagraphStyle *para = PARAGRAPH;

  if ([para alignment] != NSCenterTextAlignment)
    {
      [para setAlignment: NSCenterTextAlignment];
      CHANGED = YES;
    }
}

void GSRTFalignLeft(void *ctxt)
{
  NSMutableParagraphStyle *para = PARAGRAPH;

  if ([para alignment] != NSLeftTextAlignment)
    {
      [para setAlignment: NSLeftTextAlignment];
      CHANGED = YES;
    }
}

void GSRTFalignRight(void *ctxt)
{
  NSMutableParagraphStyle *para = PARAGRAPH;

  if ([para alignment] != NSRightTextAlignment)
    {
      [para setAlignment: NSRightTextAlignment];
      CHANGED = YES;
    }
}

void GSRTFstyle(void *ctxt, int style)
{
}

void GSRTFaddColor(void *ctxt, int red, int green, int blue)
{
  NSColor *colour = [NSColor colorWithCalibratedRed: red/255.0 
			     green: green/255.0 
			     blue: blue/255.0 
			     alpha: 1.0];

  [COLOURS addObject: colour];
}

void GSRTFaddDefaultColor(void *ctxt)
{
  [COLOURS addObject: [NSColor textColor]];
}

void GSRTFcolorbg(void *ctxt, int color)
{
  ASSIGN(BGCOLOUR, [COLOURS objectAtIndex: color]);
}

void GSRTFcolorfg(void *ctxt, int color)
{
  ASSIGN(FGCOLOUR, [COLOURS objectAtIndex: color]);
}

void GSRTFsubscript(void *ctxt, int script)
{
  script = (int) (-halfpoints2points(script) / 3.0);

  if (script != SCRIPT)
    {
      SCRIPT = script;
      CHANGED = YES;
    }    
}

void GSRTFsuperscript(void *ctxt, int script)
{
  script = (int) (halfpoints2points(script) / 3.0);

  if (script != SCRIPT)
    {
      SCRIPT = script;
      CHANGED = YES;
    }    
}

void GSRTFitalic(void *ctxt, BOOL state)
{
  if (state != ITALIC)
    {
      ITALIC = state;
      CHANGED = YES;
    }
}

void GSRTFbold(void *ctxt, BOOL state)
{
  if (state != BOLD)
    {
      BOLD = state;
      CHANGED = YES;
    }
}

void GSRTFunderline(void *ctxt, BOOL state)
{
  if (state != UNDERLINE)
    {
      UNDERLINE = state;
      CHANGED = YES;
    }
}



NSAttributedString *parseRTFintoAttributedString(NSData *rtfData, 
						 NSDictionary **dict)
{
  RTFConsumer *consumer = [RTFConsumer new];
  NSAttributedString *result;

  result = [consumer parseRTF: rtfData documentAttributes: dict];
  RELEASE(consumer);

  return result;
}
