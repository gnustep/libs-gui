/* attributedStringConsumer.m

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

#import	<Foundation/Foundation.h>
#import	<AppKit/AppKit.h>
#import "Parsers/rtfConsumer.h"

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
#define	GSfontDictName		@"fonts"
#define	GScurrentTextPosition	@"textPosition"
#define	GSresultName		@"result"
#define	GSchanged		@"changed"

#define	GSparagraph		@"paragraph"
#define	GSfontName		@"fontName"
#define	GSfontSize		@"fontSize"
#define	GSbold			@"bold"
#define	GSitalic		@"italic"
#define	GSunderline		@"underline"
#define	GSscript		@"script"

#define	GSdocumentAttributes	@"documentAttributes"

#define	CTXT	((NSMutableDictionary *)ctxt)
#define	FONTS	[CTXT objectForKey: GSfontDictName]
#define	RESULT	[CTXT objectForKey: GSresultName]
#define	CHANGED	[[CTXT objectForKey: GSchanged] boolValue]
#define	SETCHANGED(flag) [CTXT setObject: [NSNumber numberWithBool: flag] forKey: GSchanged]
#define	PARAGRAPH [CTXT objectForKey: GSparagraph]

#define	halfpoints2points(a)	((a)/2.0)
// FIXME: How to convert twips to points???
#define	twips2points(a)	((a)/500.0)


static int textPosition(void *ctxt)
{
  return [[CTXT objectForKey: GScurrentTextPosition] intValue];
}

static NSFont *currentFont(void *ctxt)
{
  NSFont *font;
  BOOL boldOn;
  BOOL italicOn;
  NSString *name;
  float size;
  NSFontTraitMask traits = 0;
  int weight;

  name = [CTXT objectForKey: GSfontName];
  size = [[CTXT objectForKey: GSfontSize] floatValue];
  boldOn = [[CTXT objectForKey: GSbold] boolValue];
  italicOn = [[CTXT objectForKey: GSitalic] boolValue];

  if (boldOn)
    {
      weight = 9;
      traits |= NSBoldFontMask;
    }
  else
    {
      weight = 6;
      traits |= NSUnboldFontMask;
    }

  if (italicOn)
    {
      traits |= NSItalicFontMask;
    }
  else
    {
      traits |= NSUnitalicFontMask;
    }

  font = [[NSFontManager sharedFontManager] fontWithFamily: name
					    traits: traits
					    weight: weight
					    size: size];
  return font;
}

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
  NSFont *font = [NSFont userFontOfSize:12];

  [CTXT setObject: [NSNumber numberWithInt:0] forKey: GScurrentTextPosition];
  [CTXT setObject: [NSMutableDictionary dictionary] forKey: GSfontDictName];
  SETCHANGED(YES);

  [CTXT setObject: [NSMutableParagraphStyle defaultParagraphStyle] 
	forKey: GSparagraph];

  [CTXT setObject: [font familyName] forKey: GSfontName];
  [CTXT setObject: [NSNumber numberWithFloat: 12.0] forKey: GSfontSize];
  [CTXT setObject: [NSNumber numberWithBool: NO] forKey: GSbold];
  [CTXT setObject: [NSNumber numberWithBool: NO] forKey: GSitalic];
  [CTXT setObject: [NSNumber numberWithBool: NO] forKey: GSunderline];
  [CTXT setObject: [NSNumber numberWithInt: 0] forKey: GSscript];
  
  [RESULT beginEditing];
}

// Finished to parse one piece of RTF.
void GSRTFstop(void *ctxt)
{
  //<!> close all open bolds et al.
  [RESULT endEditing];
}

void GSRTFopenBlock(void *ctxt)
{
    // FIXME: Should push the current state on a stack
}

void GSRTFcloseBlock(void *ctxt)
{
    // FIXME: Should pop the current state from a stack
}

void GSRTFmangleText(void *ctxt, const char *text)
{
  int  oldPosition = textPosition(ctxt);
  int  textlen = strlen(text); 
  int  newPosition = oldPosition + textlen;
  NSRange insertionRange = NSMakeRange(oldPosition,0);
  NSDictionary *attributes;
  NSFont *font;

  if (textlen)
    {
      [CTXT setObject:[NSNumber numberWithInt: newPosition] 
	    forKey: GScurrentTextPosition];
      
      [RESULT replaceCharactersInRange: insertionRange 
	      withString: [NSString stringWithCString:text]];

      if (CHANGED)
        {
	  font = currentFont(ctxt);
	  attributes = [NSDictionary dictionaryWithObjectsAndKeys:
					 font, NSFontAttributeName, 
				     [CTXT objectForKey: GSscript], NSSuperscriptAttributeName,
				     PARAGRAPH, NSParagraphStyleAttributeName,
				     nil];
	  [RESULT setAttributes: attributes range: 
		      NSMakeRange(oldPosition, textlen)];
	  SETCHANGED(NO);
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
		   textPosition(ctxt)];
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
		   textPosition(ctxt)];
    } 
  else 
    {
      if (![fontName isEqual: [CTXT objectForKey: GSfontName]])
        {
	    [CTXT setObject: fontName forKey: GSfontName];
	    SETCHANGED(YES);
	}
    }
}

//	<N> fontSize is in halfpoints according to spec
void GSRTFfontSize(void *ctxt, int fontSize)
{
  float size = halfpoints2points(fontSize);
  
  if (size != [[CTXT objectForKey: GSfontSize] floatValue])
    {
      [CTXT setObject: [NSNumber numberWithFloat: size]
	    forKey: GSfontSize];
      SETCHANGED(YES);
    }
}

void GSRTFpaperWidth(void *ctxt, int width)
{
}

void GSRTFpaperHeight(void *ctxt, int height)
{
}

void GSRTFmarginLeft(void *ctxt, int margin)
{
}

void GSRTFmarginRight(void *ctxt, int margin)
{
}

void GSRTFfirstLineIndent(void *ctxt, int indent)
{
  NSMutableParagraphStyle *para = PARAGRAPH;
  float findent = twips2points(indent);

  if ([para firstLineHeadIndent] != findent)
    {
      [para setFirstLineHeadIndent: findent];
      SETCHANGED(YES);
    }
}

void GSRTFleftIndent(void *ctxt, int indent)
{
  NSMutableParagraphStyle *para = PARAGRAPH;
  float findent = twips2points(indent);

  if ([para headIndent] != findent)
    {
      [para setHeadIndent: findent];
      SETCHANGED(YES);
    }
}

void GSRTFalignCenter(void *ctxt)
{
  NSMutableParagraphStyle *para = PARAGRAPH;

  if ([para alignment] != NSCenterTextAlignment)
    {
      [para setAlignment: NSCenterTextAlignment];
      SETCHANGED(YES);
    }
}

void GSRTFalignLeft(void *ctxt)
{
  NSMutableParagraphStyle *para = PARAGRAPH;

  if ([para alignment] != NSLeftTextAlignment)
    {
      [para setAlignment: NSLeftTextAlignment];
      SETCHANGED(YES);
    }
}

void GSRTFalignRight(void *ctxt)
{
  NSMutableParagraphStyle *para = PARAGRAPH;

  if ([para alignment] != NSRightTextAlignment)
    {
      [para setAlignment: NSRightTextAlignment];
      SETCHANGED(YES);
    }
}

void GSRTFstyle(void *ctxt, int style)
{
}

void GSRTFcolorbg(void *ctxt, int color)
{
}

void GSRTFcolorfg(void *ctxt, int color)
{
}

void GSRTFsubscript(void *ctxt, int script)
{
  script = (int) (-halfpoints2points(script) / 3.0);

  if (script != [[CTXT objectForKey: GSscript] intValue])
    {
      [CTXT setObject: [NSNumber numberWithInt: script]
	    forKey: GSscript];
      SETCHANGED(YES);
    }    
}

void GSRTFsuperscript(void *ctxt, int script)
{
  script = (int) (halfpoints2points(script) / 3.0);

  if (script != [[CTXT objectForKey: GSscript] intValue])
    {
      [CTXT setObject: [NSNumber numberWithInt: script]
	    forKey: GSscript];
      SETCHANGED(YES);
    }    
}

void GSRTFitalic(void *ctxt, BOOL state)
{
  if (state != [[CTXT objectForKey: GSitalic] boolValue])
    {
      [CTXT setObject: [NSNumber numberWithBool: state] forKey: GSitalic];
      SETCHANGED(YES);
    }
}

void GSRTFbold(void *ctxt, BOOL state)
{
  if (state != [[CTXT objectForKey: GSbold] boolValue])
    {
      [CTXT setObject: [NSNumber numberWithBool: state] forKey: GSbold];
      SETCHANGED(YES);
    }
}

void GSRTFunderline(void *ctxt, BOOL state)
{
  if (state != [[CTXT objectForKey: GSunderline] boolValue])
    {
      [CTXT setObject: [NSNumber numberWithBool: state] forKey: GSunderline];
      SETCHANGED(YES);
    }
}



BOOL parseRTFintoAttributedString(NSString *rtfString, 
				  NSMutableAttributedString *result,
				  NSDictionary **dict)
{
  RTFscannerCtxt	scanner;
  StringContext		stringCtxt;
  NSMutableDictionary	*myDict = [NSMutableDictionary dictionary];
  
  [myDict setObject: result forKey: GSresultName];
  initStringContext(&stringCtxt, rtfString);
  lexInitContext(&scanner, &stringCtxt, (int (*)(void*))readNSString);
  GSRTFparse(myDict, &scanner);

  // document attributes
  if (dict)
    (*dict)=[myDict objectForKey: GSdocumentAttributes];

  return YES;
}

NSMutableAttributedString *attributedStringFromRTF(NSString *rtfString)
{
  NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
  
  parseRTFintoAttributedString(rtfString, result, NULL);

  return AUTORELEASE(result);
}
