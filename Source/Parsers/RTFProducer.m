/* 
   RTFProducer.m

   Writes out a NSAttributedString as RTF 

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Daniel Bðhringer
   Date: November 1999
   Modifications: Fred Kiefer <FredKiefer@gmx.de>
   Date: June 2000
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "RTFProducer.h"

// FIXME: Should be defined in a central place
#define PAPERSIZE @"PaperSize"
#define LEFTMARGIN @"LeftMargin"
#define RIGHTMARGIN @"RightMargin"
#define TOPMARGIN @"TopMargin"
#define BUTTOMMARGIN @"ButtomMargin"

#define	points2twips(a)	((a)*20.0)

@interface RTFProducer (Private)

- (NSString*) headerString;
- (NSString*) trailerString;
- (NSString*) bodyString;
- (NSString*) RTFDStringFromAttributedString: (NSAttributedString*)aText
			  documentAttributes: (NSDictionary*)dict;
@end

@interface NSString (Replacing)
- (NSString*) stringByReplacingEveryOccurrenceOfString: (NSString*)aString
					    withString: (NSString*)other;
@end

@implementation NSString (Replacing)

- (NSString*) stringByReplacingEveryOccurrenceOfString: (NSString*)aString
					    withString: (NSString*)other
{
  unsigned		len = [self length];
  NSMutableString	*erg = [NSMutableString string];
  NSRange		currRange = [self rangeOfString: aString];
  unsigned		prevLocation = 0;

  while (currRange.length > 0)
    {
      if (currRange.location > 0)
	{
	  NSRange	r;

	  r = NSMakeRange(prevLocation, currRange.location - prevLocation);
	  [erg appendString: [self substringWithRange: r]];
	}
      [erg appendString: other];
      currRange.location += currRange.length;
      currRange.length = len - currRange.location;
      prevLocation = currRange.location;
      currRange = [self rangeOfString: aString
			      options: NSLiteralSearch
				range: currRange];
    }
  if (prevLocation < len)
    {
      NSRange	r;

      r = NSMakeRange(prevLocation, len - prevLocation);
      [erg appendString: [self substringWithRange: r]];
    }

  return erg;
}
@end

@implementation RTFProducer

+ (NSFileWrapper*) produceRTFD: (NSAttributedString*) aText
	documentAttributes: (NSDictionary*)dict
{
  RTFProducer *new = [self new];
  NSData *data;
  NSFileWrapper *wrapper;

  data = [[new RTFDStringFromAttributedString: aText
	       documentAttributes: dict]
	     dataUsingEncoding: NSISOLatin1StringEncoding];

  if ([aText containsAttachments])
    {
      NSMutableDictionary *fileDict = [NSMutableDictionary dictionary];
      NSFileWrapper *txt = [[NSFileWrapper alloc]
			     initRegularFileWithContents: data];

      [fileDict setObject: txt forKey: @"TXT.rtf"];
      RELEASE(txt);
      // FIXME: We have to add the attachments to the directory file wrapper

      wrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers: fileDict];
    }
  else
      wrapper = [[NSFileWrapper alloc] initRegularFileWithContents: data];


  RELEASE(new);
  return AUTORELEASE(wrapper);
}

+ (NSData*) produceRTF: (NSAttributedString*) aText
    documentAttributes: (NSDictionary*)dict
{
  RTFProducer *new = [self new];
  NSData *data;

  data = [[new RTFDStringFromAttributedString: aText
	       documentAttributes: dict]
	     dataUsingEncoding: NSISOLatin1StringEncoding];
  RELEASE(new);
  return data;
}

- (id)init
{
  /*
   * maintain a dictionary for the used colours
   * (for rtf-header generation)
   */
  colorDict = [NSMutableDictionary new];
  /*
   * maintain a dictionary for the used fonts
   * (for rtf-header generation)
   */
  fontDict = [NSMutableDictionary new];
  
  currentFont = nil;
  ASSIGN(fgColor, [NSColor textColor]);
  ASSIGN(bgColor, [NSColor textBackgroundColor]);

  return self;
}

- (void) dealloc
{
  RELEASE(text);
  RELEASE(fontDict);
  RELEASE(colorDict);
  RELEASE(docDict);

  RELEASE(currentFont);
  RELEASE(fgColor);
  RELEASE(bgColor);
}

@end

@implementation RTFProducer (Private)

- (NSString*) fontTable
{
  // write Font Table
  if ([fontDict count])
    {
      NSMutableString	*fontlistString = [NSMutableString string];
      NSEnumerator	*fontEnum;
      NSString		*currFont;
      NSArray		*keyArray;

      keyArray = [fontDict allKeys];
      keyArray = [keyArray sortedArrayUsingSelector: @selector(compare:)];

      fontEnum = [keyArray objectEnumerator];
      while ((currFont = [fontEnum nextObject]) != nil)
	{
	  NSString	*fontFamily;
	  NSString	*detail;

	  if ([currFont isEqualToString: @"Symbol"])
	    fontFamily = @"tech";
	  else if ([currFont isEqualToString: @"Helvetica"])
	    fontFamily = @"swiss";
	  else if ([currFont isEqualToString: @"Courier"])
	    fontFamily = @"modern";
	  else if ([currFont isEqualToString: @"Times"])
	    fontFamily = @"roman";
	  else
	    fontFamily = @"nil";

	  detail = [NSString stringWithFormat: @"%@\\f%@ %@;",
	    [fontDict objectForKey: currFont], fontFamily, currFont];
	  [fontlistString appendString: detail];
	}
      return [NSString stringWithFormat: @"{\\fonttbl%@}\n", fontlistString];
    }
  else
    return @"";
}

- (NSString*) colorTable
{
  // write Colour table
  if ([colorDict count])
    {
      NSMutableString	*result;
      unsigned int count = [colorDict count];
      NSMutableArray *list = [NSMutableArray arrayWithCapacity: count];
      NSEnumerator *keyEnum = [colorDict keyEnumerator];
      id next;
      int i;

      while ((next = [keyEnum nextObject]) != nil)
	{
	  NSNumber *cn = [colorDict objectForKey: next];
	  [list insertObject: next atIndex: [cn intValue]-1];
	}

      result = (NSMutableString*)[NSMutableString stringWithString: @"{\\colortbl;"];
      for (i = 0; i < count; i++)
	{
	  NSColor *color = [[list objectAtIndex: i] 
			       colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
	  [result appendString: [NSString stringWithFormat:
					    @"\\red%d\\green%d\\blue%d;",
					  (int)([color redComponent]*255),
					  (int)([color greenComponent]*255),
					  (int)([color blueComponent]*255)]];
	}

      [result appendString: @"}\n"];
      return result;
    }
  else
    return @"";
}

- (NSString*) documentAttributes
{
  if (docDict != nil)
    {
      NSMutableString *result;
      NSString *detail;
      NSValue *val;
      NSNumber *num;

      result = (NSMutableString*)[NSMutableString string];

      val = [docDict objectForKey: PAPERSIZE];
      if (val != nil)
        {
	  NSSize size = [val sizeValue];
	  detail = [NSString stringWithFormat: @"\\paperw%d \\paperh%d",
			     (int)points2twips(size.width), 
			     (int)points2twips(size.height)];
	  [result appendString: detail];
	}

      num = [docDict objectForKey: LEFTMARGIN];
      if (num != nil)
        {
	  float f = [num floatValue];
	  detail = [NSString stringWithFormat: @"\\margl%d",
			     (int)points2twips(f)];
	  [result appendString: detail];
	}
      num = [docDict objectForKey: RIGHTMARGIN];
      if (num != nil)
        {
	  float f = [num floatValue];
	  detail = [NSString stringWithFormat: @"\\margr%d",
			     (int)points2twips(f)];
	  [result appendString: detail];
	}
      num = [docDict objectForKey: TOPMARGIN];
      if (num != nil)
        {
	  float f = [num floatValue];
	  detail = [NSString stringWithFormat: @"\\margt%d",
			     (int)points2twips(f)];
	  [result appendString: detail];
	}
      num = [docDict objectForKey: BUTTOMMARGIN];
      if (num != nil)
        {
	  float f = [num floatValue];
	  detail = [NSString stringWithFormat: @"\\margb%d",
			     (int)points2twips(f)];
	  [result appendString: detail];
	}

      return result;
    }
  else
    return @"";
}

- (NSString*) headerString
{
  NSMutableString	*result;

  result = (NSMutableString*)[NSMutableString stringWithString: @"{\\rtf1\\ansi"];

  [result appendString: [self fontTable]];
  [result appendString: [self colorTable]];
  [result appendString: [self documentAttributes]];

  return result;
}

- (NSString*) trailerString
{
  return @"}";
}

- (NSString*) fontToken: (NSString*) fontName
{
  NSString *fCount = [fontDict objectForKey: fontName];

  if (fCount == nil)
    {
      unsigned	count = [fontDict count];
      
      fCount = [NSString stringWithFormat: @"\\f%d", count];
      [fontDict setObject: fCount forKey: fontName];
    }

  return fCount;
}

- (int) numberForColor: (NSColor*)color
{
  unsigned int cn;
  NSNumber *num = [colorDict objectForKey: color];

  if (num == nil)
    {
      cn = [colorDict count] + 1;
	    
      [colorDict setObject: [NSNumber numberWithInt: cn]
		 forKey: color];
    }
  else
    cn = [num intValue];

  return cn;
}

- (NSString*) paragraphStyle: (NSParagraphStyle*) paraStyle
{
  NSMutableString *headerString = (NSMutableString *)[NSMutableString 
							 stringWithString: 
							     @"\\pard\\plain"];
  int twips;

  if (paraStyle == nil)
    return headerString;

  switch ([paraStyle alignment])
    {
      case NSRightTextAlignment:
	[headerString appendString: @"\\qr"];
	break;
      case NSCenterTextAlignment:
	[headerString appendString: @"\\qc"];
	break;
      case NSLeftTextAlignment:
	[headerString appendString: @"\\ql"];
	break;
      case NSJustifiedTextAlignment:
	[headerString appendString: @"\\qj"];
	break;
      default: break;
    }

  // write first line indent and left indent
  twips = (int)points2twips([paraStyle firstLineHeadIndent]);
  if (twips != 0.0)
    {
      [headerString appendString: [NSString stringWithFormat:
						@"\\fi%d",
					    twips]];
    }
  twips = (int)points2twips([paraStyle headIndent]);
  if (twips != 0.0)
    {
      [headerString appendString: [NSString stringWithFormat:
						@"\\li%d",
					    twips]];
    }
  twips = (int)points2twips([paraStyle tailIndent]);
  if (twips != 0.0)
    {
      [headerString appendString: [NSString stringWithFormat:
						@"\\ri%d",
					    twips]];
    }
  twips = (int)points2twips([paraStyle paragraphSpacing]);
  if (twips != 0.0)
    {
      [headerString appendString: [NSString stringWithFormat:
						@"\\sa%d",
					    twips]];
    }
  twips = (int)points2twips([paraStyle minimumLineHeight]);
  if (twips != 0.0)
    {
      [headerString appendString: [NSString stringWithFormat:
						@"\\sl%d",
					    twips]];
    }
  twips = (int)points2twips([paraStyle maximumLineHeight]);
  if (twips != 0.0)
    {
      [headerString appendString: [NSString stringWithFormat:
						@"\\sl-%d",
					    twips]];
    }
  // FIXME: Tab definitions are still missing
  
  return headerString;
}

- (NSString*) runStringForString: (NSString*) substring
		     attributes: (NSDictionary*) attributes
		 paragraphStart: (BOOL) first
{
  NSMutableString *result = [NSMutableString stringWithCapacity: 
						 [substring length]*2];
  NSMutableString *headerString = [NSMutableString stringWithCapacity: 20];
  NSMutableString *trailerString = [NSMutableString stringWithCapacity: 20];
  NSEnumerator	*attribEnum;
  id currAttrib;
  
  if (first)
    {
      NSParagraphStyle *paraStyle = [attributes objectForKey:
						    NSParagraphStyleAttributeName];
      [headerString appendString: [self paragraphStyle: paraStyle]];
      DESTROY(currentFont);
    }

  /*
   * analyze attributes of current run
   *
   * FIXME: All the character attributes should be output relative to the font
   * attributes of the paragraph. So if the paragraph has underline on it should 
   * still be possible to switch it off for some characters, which currently is 
   * not possible.
   */
  attribEnum = [attributes keyEnumerator];
  while ((currAttrib = [attribEnum nextObject]) != nil)
    {
      if ([currAttrib isEqualToString: NSFontAttributeName])
        {
	  /*
	   * handle fonts
	   */
	  NSFont			*font;
	  NSString			*fontName;
	  NSFontTraitMask		traits;
	  
	  font = [attributes objectForKey: NSFontAttributeName];
	  fontName = [font familyName];
	  traits = [[NSFontManager sharedFontManager] traitsOfFont: font];
	  
	  /*
	   * font name
	   */
	  if (currentFont == nil || 
	      ![fontName isEqualToString: [currentFont familyName]])
	  {
	    [headerString appendString: [self fontToken: fontName]];
	  }
	  /*
	   * font size
	   */
	  if (currentFont == nil || 
	      [font pointSize] != [currentFont pointSize])
	    {
	      int points = (int)[font pointSize]*2;
	      NSString *pString;
	      
	      pString = [NSString stringWithFormat: @"\\fs%d", points];
	      [headerString appendString: pString];
	    }
	  /*
	   * font attributes
	   */
	  if (traits & NSItalicFontMask)
	    {
	      [headerString appendString: @"\\i"];
	      [trailerString appendString: @"\\i0"];
	    }
	  if (traits & NSBoldFontMask)
	    {
	      [headerString appendString: @"\\b"];
	      [trailerString appendString: @"\\b0"];
	    }

	  if (first)
	    ASSIGN(currentFont, font);
	}
      else if ([currAttrib isEqualToString: NSForegroundColorAttributeName])
        {
	  NSColor *color = [attributes objectForKey: NSForegroundColorAttributeName];
	  if (![color isEqual: fgColor])
	    {
	      [headerString appendString: [NSString stringWithFormat:
							@"\\cf%d", 
						    [self numberForColor: color]]];
	      [trailerString appendString: @"\\cf0"];
	    }
	}
      else if ([currAttrib isEqualToString: NSBackgroundColorAttributeName])
        {
	  NSColor *color = [attributes objectForKey: NSBackgroundColorAttributeName];
	  if (![color isEqual: bgColor])
	    {
	      [headerString appendString: [NSString stringWithFormat:
							@"\\cb%d", 
						    [self numberForColor: color]]];
	      [trailerString appendString: @"\\cb0"];
	    }
	}
      else if ([currAttrib isEqualToString: NSUnderlineStyleAttributeName])
        {
	  [headerString appendString: @"\\ul"];
	  [trailerString appendString: @"\\ulnone"];
	}
      else if ([currAttrib isEqualToString: NSSuperscriptAttributeName])
        {
	  NSNumber *value = [attributes objectForKey: NSSuperscriptAttributeName];
	  int svalue = [value intValue] * 6;
	  
	  if (svalue > 0)
	    {
	      [headerString appendString: [NSString stringWithFormat:
							@"\\up%d", svalue]];
	      [trailerString appendString: @"\\up0"];
	    }
	  else if (svalue < 0)
	    {
	      [headerString appendString: [NSString stringWithFormat:
							@"\\dn-%d", svalue]];
	      [trailerString appendString: @"\\dn0"];
	    }
	}
      else if ([currAttrib isEqualToString: NSBaselineOffsetAttributeName])
        {
	  NSNumber *value = [attributes objectForKey: NSBaselineOffsetAttributeName];
	  int svalue = (int)[value floatValue] * 2;
	  
	  if (svalue > 0)
	    {
	      [headerString appendString: [NSString stringWithFormat:
							@"\\up%d", svalue]];
	      [trailerString appendString: @"\\up0"];
	    }
	  else if (svalue < 0)
	    {
	      [headerString appendString: [NSString stringWithFormat:
							@"\\dn-%d", svalue]];
	      [trailerString appendString: @"\\dn0"];
	    }
	}
      else if ([currAttrib isEqualToString: NSAttachmentAttributeName])
        {
	}
      else if ([currAttrib isEqualToString: NSLigatureAttributeName])
        {
	}
      else if ([currAttrib isEqualToString: NSKernAttributeName])
        {
	}
    }

  // FIXME: There should be a more efficient way to replace these
  substring = [substring stringByReplacingString: @"\\"
			 withString: @"\\\\"];
  substring = [substring stringByReplacingString: @"\n"
			 withString: @"\\par\n"];
  substring = [substring stringByReplacingString: @"\t"
			 withString: @"\\tab "];
  substring = [substring stringByReplacingString: @"{"
			 withString: @"\\{"];
  substring = [substring stringByReplacingString: @"}"
			 withString: @"\\}"];
  // FIXME: All characters not in the standard encoding must be
  // replaced by \'xx
  
  if (!first)
    {
      NSString	*braces;
      
      if ([headerString length])
	  braces = [NSString stringWithFormat: @"{%@ %@}",
			     headerString, substring];
      else
	  braces = substring;
      
      [result appendString: braces];
    }
  else
    {
      NSString	*nobraces;

      if ([headerString length])
	  nobraces = [NSString stringWithFormat: @"%@ %@",
			       headerString, substring];
      else 
	  nobraces = substring;

/* This has no result, as the character style is reset for each paragraph
      if ([trailerString length])
	  nobraces = [NSString stringWithFormat: @"%@%@ ",
			       nobraces, trailerString];
*/
      
      [result appendString: nobraces];
    }

  return result;
}

- (NSString*) bodyString
{
  NSString		*string = [text string];
  NSMutableString	*result = [NSMutableString string];
  unsigned loc = 0;
  unsigned length = [string length];

  while (loc < length)
    {
      // Range of the current run
      NSRange currRange = NSMakeRange(loc, 0);
      // Range of the current paragraph
      NSRange completeRange = [string lineRangeForRange: currRange];
      BOOL first = YES;

      while (NSMaxRange(currRange) < NSMaxRange(completeRange))  // save all "runs"
        {
	  NSDictionary	*attributes;
	  NSString	*substring;
	  NSString	*runString;
	  
	  attributes = [text attributesAtIndex: NSMaxRange(currRange)
			     longestEffectiveRange: &currRange
			     inRange: completeRange];
	  substring = [string substringWithRange: currRange];
	  
	  runString = [self runStringForString: substring
			    attributes: attributes
			    paragraphStart: first];
	  [result appendString: runString];
	  first = NO;
	}

      loc = NSMaxRange(completeRange);
    }

  return result;
}


- (NSString*) RTFDStringFromAttributedString: (NSAttributedString*)aText
	       documentAttributes: (NSDictionary*)dict
{
  NSMutableString	*output = [NSMutableString string];
  NSString		*headerString;
  NSString		*trailerString;
  NSString		*bodyString;

  ASSIGN(text, aText);
  ASSIGN(docDict, dict);

  /*
   * do not change order! (esp. body has to be generated first; builds context)
   */
  bodyString = [self bodyString];
  trailerString = [self trailerString];
  headerString = [self headerString];

  [output appendString: headerString];
  [output appendString: bodyString];
  [output appendString: trailerString];
  return (NSString*)output;
}
@end
