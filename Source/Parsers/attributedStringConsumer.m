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
initStringContext (StringContext *ctxt, NSString *string)
{
  ctxt->string = string;
  ctxt->position = 0;
  ctxt->length = [string length];
}

static int	
readNSString (StringContext *ctxt)
{
  return (ctxt->position < ctxt->length )
    ? [ctxt->string characterAtIndex:ctxt->position++]: EOF;
}

// Hold the attributs of the current run
@interface RTFAttribute: NSObject <NSCopying>
{
@public
  BOOL changed;
  BOOL tabChanged;
  NSMutableParagraphStyle *paragraph;
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
- (NSNumber*) script;
- (NSNumber*) underline;
- (void) resetParagraphStyle;
- (void) resetFont;
- (void) addTab: (float)location  type: (NSTextTabType)type;

@end

@implementation RTFAttribute

- (id) init
{
  [self resetFont];
  [self resetParagraphStyle];

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
  RTFAttribute *new =  (RTFAttribute *)NSCopyObject (self, 0, zone);

  new->paragraph = [paragraph copyWithZone: zone];
  RETAIN(new->fontName);
  RETAIN(new->fgColour);
  RETAIN(new->bgColour);

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
      weight = 5;
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
  if (font == nil)
    {
	NSDebugMLLog(@"RTFParser", 
		     @"Could not find font %@ size %f traits %d weight %d", 
		     fontName, fontSize, traits, weight);
	font = [NSFont userFontOfSize: fontSize];
    }

  return font;
}

- (NSNumber*) script
{
  return [NSNumber numberWithInt: script];
}

- (NSNumber*) underline
{
  if (underline)
    return [NSNumber numberWithInt: NSSingleUnderlineStyle];
  else
    return nil;
}

- (void) resetParagraphStyle
{
  ASSIGN(paragraph, [NSMutableParagraphStyle defaultParagraphStyle]);

  tabChanged = NO;
  changed = YES;
}

- (void) resetFont
{
  NSFont *font = [NSFont userFontOfSize:12];

  ASSIGN(fontName, [font familyName]);
  fontSize = 12.0;
  italic = NO;
  bold = NO;

  underline = NO;
  script = 0;
  DESTROY(fgColour);
  DESTROY(bgColour);

  changed = YES;
}

- (void) addTab: (float) location  type: (NSTextTabType) type
{
  NSTextTab *tab = [[NSTextTab alloc] initWithType: NSLeftTabStopType 
				      location: location];

  if (!tabChanged)
  {
    // remove all tab stops
    [paragraph setTabStops: [NSArray arrayWithObject: tab]];
    tabChanged = YES;
  }
  else
    {
      [paragraph addTabStop: tab];
    }

  changed = YES;
  RELEASE(tab);
}
 
@end

@interface RTFConsumer (Private)

- (NSAttributedString*) parseRTF: (NSData *)rtfData 
	      documentAttributes: (NSDictionary **)dict;
- (NSDictionary*) documentAttributes;
- (NSAttributedString*) result;

- (RTFAttribute*) attr;
- (void) push;
- (void) pop;

@end

@implementation RTFConsumer

+ (NSAttributedString*) parseRTFD: (NSFileWrapper *)wrapper
	       documentAttributes: (NSDictionary **)dict
{
  RTFConsumer *consumer = [RTFConsumer new];
  NSAttributedString *text = nil;

  if ([wrapper isRegularFile])
    {
      text = [consumer parseRTF: [wrapper regularFileContents]
		       documentAttributes: dict];
    }
  else if ([wrapper isDirectory])
    {
      NSDictionary *files = [wrapper fileWrappers];
      NSFileWrapper *contents;

      //FIXME: We should store the files in the consumer
      // We try to read the main file in the directory
      if ((contents = [files objectForKey: @"TXT.rtf"]) != nil)
	{
	  text = [consumer parseRTF: [contents regularFileContents]
			   documentAttributes: dict];
	}
    }

  RELEASE(consumer);

  return text;
}

+ (NSAttributedString*) parseRTF: (NSData *)rtfData 
	      documentAttributes: (NSDictionary **)dict
{
  RTFConsumer *consumer = [RTFConsumer new];
  NSAttributedString *text;

  text = [consumer parseRTF: rtfData
		   documentAttributes: dict];
  RELEASE(consumer);

  return text;
}

- (id) init
{
  ignore = 0;  
  result = nil;
  documentAttributes = nil;
  fonts = nil;
  attrs = nil;
  colours = nil;

  return self;
}

- (void) dealloc
{
  RELEASE(fonts);
  RELEASE(attrs);
  RELEASE(colours);
  RELEASE(result);
  RELEASE(documentAttributes);
  [super dealloc];
}

@end

@implementation RTFConsumer (Private)

- (NSDictionary*) documentAttributes
{
  RETAIN(documentAttributes);
  return AUTORELEASE(documentAttributes);
}

- (void) reset
{
  RTFAttribute *attr = [RTFAttribute new];

  ignore = 0;  
  DESTROY(result);
  result = [[NSMutableAttributedString alloc] init];
  ASSIGN(documentAttributes, [NSMutableDictionary dictionary]);
  ASSIGN(fonts, [NSMutableDictionary dictionary]);
  ASSIGN(attrs, [NSMutableArray array]);
  ASSIGN(colours, [NSMutableArray array]);
  [attrs addObject: attr];
  RELEASE(attr);
}

- (RTFAttribute*) attr
{
  return [attrs lastObject];
}

- (void) push
{
  RTFAttribute *attr = [[attrs lastObject] copy];

  [attrs addObject: attr];
  RELEASE(attr);
}

- (void) pop
{
  [attrs removeLastObject];
  ((RTFAttribute*)[attrs lastObject])->changed = YES;
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
  // We should read in the first few characters to find out which
  // encoding we have
  NSString *rtfString = [[NSString alloc] 
			  initWithData: rtfData
			  encoding: NSASCIIStringEncoding];

  // Reset this RFTConsumer, as it might already have been used!
  [self reset];

  initStringContext(&stringCtxt, rtfString);
  lexInitContext(&scanner, &stringCtxt, (int (*)(void*))readNSString);
  NS_DURING
    GSRTFparse((void *)self, &scanner);
  NS_HANDLER
    NSLog(@"Problem during RTF Parsing: %@", 
	  [localException reason]);
  //[localException raise];
  NS_ENDHANDLER

  RELEASE(rtfString);
  RELEASE(pool);
  // document attributes
  if (dict)
    {
      *dict = [self documentAttributes];
    }

  return [self result];
}

@end

#define	FONTS	((RTFConsumer *)ctxt)->fonts
#define	COLOURS	((RTFConsumer *)ctxt)->colours
#define	RESULT	((RTFConsumer *)ctxt)->result
#define	IGNORE	((RTFConsumer *)ctxt)->ignore
#define	TEXTPOSITION [RESULT length]
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

/*
  we must implement from the rtfConsumerFunctions.h file (Supporting files)
  this includes the yacc error handling and output
*/

/* handle errors (this is the yacc error mech)	*/
void GSRTFerror (const char *msg)
{
  [NSException raise:NSInvalidArgumentException 
	       format:@"Syntax error in RTF: %s", msg];
}

void GSRTFgenericRTFcommand (void *ctxt, RTFcmd cmd)
{
  NSDebugLLog(@"RTFParser", @"encountered rtf cmd:%s", cmd.name);
  if (!cmd.isEmpty) 
    NSDebugLLog(@"RTFParser", @" argument is %d\n", cmd.parameter);
}

//Start: we're doing some initialization
void GSRTFstart (void *ctxt)
{
  NSDebugLLog(@"RTFParser", @"Start RTF parsing");
  [RESULT beginEditing];
}

// Finished to parse one piece of RTF.
void GSRTFstop (void *ctxt)
{
  //<!> close all open bolds et al.
  [RESULT endEditing];
  NSDebugLLog(@"RTFParser", @"End RTF parsing");
}

void GSRTFopenBlock (void *ctxt, BOOL ignore)
{
  if (!IGNORE)
    {
      [(RTFConsumer *)ctxt push];
    }
  // Switch off any output for ignored block statements
  if (ignore)
    {
      IGNORE++;
    }
}

void GSRTFcloseBlock (void *ctxt, BOOL ignore)
{
  if (ignore)
    {
      IGNORE--;
    }
  if (!IGNORE)
    {
      [(RTFConsumer *)ctxt pop];
    }
}

void GSRTFmangleText (void *ctxt, const char *text)
{
  int  oldPosition = TEXTPOSITION;
  int  textlen = strlen(text); 
  NSRange insertionRange = NSMakeRange(oldPosition,0);
  NSMutableDictionary *attributes;

  if (!IGNORE && textlen)
    {
      [RESULT replaceCharactersInRange: insertionRange 
	      withString: [NSString stringWithCString:text]];

      if (CHANGED)
        {
	  attributes = [NSMutableDictionary 
			 dictionaryWithObjectsAndKeys:
			   [CTXT currentFont], NSFontAttributeName,
			   PARAGRAPH, NSParagraphStyleAttributeName,
			   nil];
	  if (UNDERLINE)
	    {
	      [attributes setObject: [CTXT underline]
			  forKey: NSUnderlineStyleAttributeName];
	    }
	  if (SCRIPT)
	    {
	      [attributes setObject: [CTXT script]
			  forKey: NSSuperscriptAttributeName];
	    }
	  if (FGCOLOUR != nil)
	    {
	      [attributes setObject: FGCOLOUR 
			  forKey: NSForegroundColorAttributeName];
	    }
	  if (BGCOLOUR != nil)
	    {
	      [attributes setObject: BGCOLOUR 
			  forKey: NSBackgroundColorAttributeName];
	    }

	  [RESULT setAttributes: attributes 
		  range: NSMakeRange(oldPosition, textlen)];
	  CHANGED = NO;
	}
    }
}

void GSRTFregisterFont (void *ctxt, const char *fontName, 
			RTFfontFamily family, int fontNumber)
{
  NSString		*fontNameString;
  NSNumber		*fontId = [NSNumber numberWithInt: fontNumber];

  if (!fontName || !*fontName)
    {	
      [NSException raise: NSInvalidArgumentException 
		   format: @"Error in RTF (font omitted?), position:%d",
		   TEXTPOSITION];
    }
  // exclude trailing ';' from fontName
  fontNameString = [NSString stringWithCString: fontName 
			     length: strlen(fontName)-1];
  [FONTS setObject: fontNameString forKey: fontId];
}

void GSRTFfontNumber (void *ctxt, int fontNumber)
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
void GSRTFfontSize (void *ctxt, int fontSize)
{
  float size = halfpoints2points(fontSize);
  
  if (size != CTXT->fontSize)
    {
      CTXT->fontSize = size;
      CHANGED = YES;
    }
}

void GSRTFpaperWidth (void *ctxt, int width)
{
  float fwidth = twips2points(width);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;
  NSValue *val = [dict objectForKey: PAPERSIZE];
  NSSize size;

  if (val == nil)
    {
      size = NSMakeSize(fwidth, 792);
    }
  else
    {
      size = [val sizeValue];
      size.width = fwidth;
    }
  [dict setObject: [NSValue valueWithSize: size]  forKey: PAPERSIZE];
}

void GSRTFpaperHeight (void *ctxt, int height)
{
  float fheight = twips2points(height);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;
  NSValue *val = [dict objectForKey: PAPERSIZE];
  NSSize size;

  if (val == nil)
    {
      size = NSMakeSize(612, fheight);
    }
  else
    {
      size = [val sizeValue];
      size.height = fheight;
    }
  [dict setObject: [NSValue valueWithSize: size]  forKey: PAPERSIZE];
}

void GSRTFmarginLeft (void *ctxt, int margin)
{
  float fmargin = twips2points(margin);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;

  [dict setObject: [NSNumber numberWithFloat: fmargin]  forKey: LEFTMARGIN];
}

void GSRTFmarginRight (void *ctxt, int margin)
{
  float fmargin = twips2points(margin);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;

  [dict setObject: [NSNumber numberWithFloat: fmargin]  forKey: RIGHTMARGIN];
}

void GSRTFmarginTop (void *ctxt, int margin)
{
  float fmargin = twips2points(margin);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;

  [dict setObject: [NSNumber numberWithFloat: fmargin]  forKey: TOPMARGIN];
}

void GSRTFmarginButtom (void *ctxt, int margin)
{
  float fmargin = twips2points(margin);
  NSMutableDictionary *dict = DOCUMENTATTRIBUTES;

  [dict setObject: [NSNumber numberWithFloat: fmargin]  forKey: BUTTOMMARGIN];
}

void GSRTFfirstLineIndent (void *ctxt, int indent)
{
  NSMutableParagraphStyle *para = PARAGRAPH;
  float findent = twips2points(indent);

  // FIXME: This should changed the left indent of the paragraph, if < 0
  // for attributed strings only positiv indent is allowed
  if ((findent >= 0.0) && ([para firstLineHeadIndent] != findent))
    {
      [para setFirstLineHeadIndent: findent];
      CHANGED = YES;
    }
}

void GSRTFleftIndent (void *ctxt, int indent)
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

void GSRTFrightIndent (void *ctxt, int indent)
{
  NSMutableParagraphStyle *para = PARAGRAPH;
  float findent = twips2points(indent);

  // for attributed strings only positiv indent is allowed
  if ((findent >= 0.0) && ([para tailIndent] != findent))
    {
      [para setTailIndent: findent];
      CHANGED = YES;
    }
}

void GSRTFtabstop (void *ctxt, int location)
{
  float flocation = twips2points(location);

  if (flocation >= 0.0)
    {
      [CTXT addTab: flocation type: NSLeftTabStopType];
    }
}

void GSRTFalignCenter (void *ctxt)
{
  NSMutableParagraphStyle *para = PARAGRAPH;

  if ([para alignment] != NSCenterTextAlignment)
    {
      [para setAlignment: NSCenterTextAlignment];
      CHANGED = YES;
    }
}

void GSRTFalignJustified (void *ctxt)
{
  NSMutableParagraphStyle *para = PARAGRAPH;

  if ([para alignment] != NSJustifiedTextAlignment)
    {
      [para setAlignment: NSJustifiedTextAlignment];
      CHANGED = YES;
    }
}

void GSRTFalignLeft (void *ctxt)
{
  NSMutableParagraphStyle *para = PARAGRAPH;

  if ([para alignment] != NSLeftTextAlignment)
    {
      [para setAlignment: NSLeftTextAlignment];
      CHANGED = YES;
    }
}

void GSRTFalignRight (void *ctxt)
{
  NSMutableParagraphStyle *para = PARAGRAPH;

  if ([para alignment] != NSRightTextAlignment)
    {
      [para setAlignment: NSRightTextAlignment];
      CHANGED = YES;
    }
}

void GSRTFspaceAbove (void *ctxt, int space)
{
  NSMutableParagraphStyle *para = PARAGRAPH;
  float fspace = twips2points(space);

  if (fspace >= 0.0)
    {
      [para setParagraphSpacing: fspace];
    }
}

void GSRTFlineSpace (void *ctxt, int space)
{
  NSMutableParagraphStyle *para = PARAGRAPH;
  float fspace = twips2points(space);

  if (space == 1000)
    {
      [para setMinimumLineHeight: 0.0];
      [para setMaximumLineHeight: 0.0];
    }
  else if (fspace < 0.0)
    {
      [para setMaximumLineHeight: -fspace];
    }
  else
    {
      [para setMinimumLineHeight: fspace];
    }
}

void GSRTFdefaultParagraph (void *ctxt)
{
  [CTXT resetParagraphStyle];
}

void GSRTFstyle (void *ctxt, int style)
{
}

void GSRTFdefaultCharacterStyle (void *ctxt)
{
  [CTXT resetFont];
}

void GSRTFaddColor (void *ctxt, int red, int green, int blue)
{
  NSColor *colour = [NSColor colorWithCalibratedRed: red/255.0 
			     green: green/255.0 
			     blue: blue/255.0 
			     alpha: 1.0];

  [COLOURS addObject: colour];
}

void GSRTFaddDefaultColor (void *ctxt)
{
  [COLOURS addObject: [NSColor textColor]];
}

void GSRTFcolorbg (void *ctxt, int color)
{
  ASSIGN(BGCOLOUR, [COLOURS objectAtIndex: color]);
}

void GSRTFcolorfg (void *ctxt, int color)
{
  ASSIGN(FGCOLOUR, [COLOURS objectAtIndex: color]);
}

void GSRTFsubscript (void *ctxt, int script)
{
  script = (int) (-halfpoints2points(script) / 3.0);

  if (script != SCRIPT)
    {
      SCRIPT = script;
      CHANGED = YES;
    }    
}

void GSRTFsuperscript (void *ctxt, int script)
{
  script = (int) (halfpoints2points(script) / 3.0);

  if (script != SCRIPT)
    {
      SCRIPT = script;
      CHANGED = YES;
    }    
}

void GSRTFitalic (void *ctxt, BOOL state)
{
  if (state != ITALIC)
    {
      ITALIC = state;
      CHANGED = YES;
    }
}

void GSRTFbold (void *ctxt, BOOL state)
{
  if (state != BOLD)
    {
      BOLD = state;
      CHANGED = YES;
    }
}

void GSRTFunderline (void *ctxt, BOOL state)
{
  if (state != UNDERLINE)
    {
      UNDERLINE = state;
      CHANGED = YES;
    }
}

void GSRTFparagraph (void *ctxt)
{
  GSRTFmangleText(ctxt, "\n");
  CTXT->tabChanged = NO;
}
