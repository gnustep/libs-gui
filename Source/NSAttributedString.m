/* 
   NSAttributedString.m

   Categories which add capabilities to NSAttributedString 

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: July 1999
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

#include <AppKit/NSAttributedString.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSTextAttachment.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSColor.h>
// For the colour name spaces
#include <AppKit/NSGraphics.h>
#include <Foundation/NSString.h>
#include <Foundation/NSRange.h>

#include "Parsers/rtfConsumer.h"
#include "Parsers/RTFProducer.h"

/*
 * function to return a character set containing characters that
 * separate words.
 */
static NSCharacterSet*
wordBreakCSet()
{
  static NSCharacterSet	*cset = nil;

  if (cset == nil)
    {
      NSMutableCharacterSet	*m = [NSMutableCharacterSet new];

      cset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
      [m formUnionWithCharacterSet: cset];
      cset = [NSCharacterSet punctuationCharacterSet];
      [m formUnionWithCharacterSet: cset];
      cset = [NSCharacterSet controlCharacterSet];
      [m formUnionWithCharacterSet: cset];
      cset = [NSCharacterSet illegalCharacterSet];
      [m formUnionWithCharacterSet: cset];
      cset = [m copy];
      RELEASE(m);
    }
  return cset;
}

/*
 * function to return a character set containing characters that
 * are legal within words.
 */
static NSCharacterSet*
wordCSet()
{
  static NSCharacterSet	*cset = nil;

  if (cset == nil)
    {
      cset = [[wordBreakCSet() invertedSet] copy];
    }
  return cset;
}

/*
 * Returns a String containing the attachment character
 */
static NSString *attachmentString()
{
  static NSString *attach  = nil;

  if (attach == nil)
    {
      unichar ch = NSAttachmentCharacter;
      attach = [NSString stringWithCharacters: &ch 
			 length: 1];
    }
  return attach;
}


@implementation NSAttributedString (AppKit)

+ (NSAttributedString *)attributedStringWithAttachment:(NSTextAttachment *)attachment
{
  NSDictionary *attributes = [NSDictionary dictionaryWithObject: attachment
					   forKey: NSAttachmentAttributeName];

  return AUTORELEASE([[self alloc] initWithString: attachmentString() 
				   attributes: attributes]);
}

- (BOOL) containsAttachments
{
  NSRange aRange = [[self string] rangeOfString: attachmentString()];

  return aRange.length;
}

- (NSDictionary*) fontAttributesInRange: (NSRange)range
{
  NSDictionary	*all;
  static SEL	sel = @selector(objectForKey:);
  IMP		objForKey;
  id		objects[8];
  id		keys[8];
  int		count = 0;

  if (NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -fontAttributesInRange:"];
    }
  all = [self attributesAtIndex: range.location
		 effectiveRange: &range];

  objForKey = [all methodForSelector: sel];

  keys[count] = NSFontAttributeName;
  objects[count] = (*objForKey)(all, sel, keys[count]);
  if (objects[count] != nil)
    count++;

  keys[count] = NSForegroundColorAttributeName;
  objects[count] = (*objForKey)(all, sel, keys[count]);
  if (objects[count] != nil)
    count++;

  keys[count] = NSBackgroundColorAttributeName;
  objects[count] = (*objForKey)(all, sel, keys[count]);
  if (objects[count] != nil)
    count++;

  keys[count] = NSUnderlineStyleAttributeName;
  objects[count] = (*objForKey)(all, sel, keys[count]);
  if (objects[count] != nil)
    count++;

  keys[count] = NSSuperscriptAttributeName;
  objects[count] = (*objForKey)(all, sel, keys[count]);
  if (objects[count] != nil)
    count++;

  keys[count] = NSBaselineOffsetAttributeName;
  objects[count] = (*objForKey)(all, sel, keys[count]);
  if (objects[count] != nil)
    count++;

  keys[count] = NSKernAttributeName;
  objects[count] = (*objForKey)(all, sel, keys[count]);
  if (objects[count] != nil)
    count++;

  keys[count] = NSLigatureAttributeName;
  objects[count] = (*objForKey)(all, sel, keys[count]);
  if (objects[count] != nil)
    count++;

  return [NSDictionary dictionaryWithObjects: objects
				     forKeys: keys
				       count: count];
}

- (NSDictionary*) rulerAttributesInRange: (NSRange)range
{
  id	style;

  if (NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -rulerAttributesInRange:"];
    }

  style = [self attribute: NSParagraphStyleAttributeName
		  atIndex: range.location
	   effectiveRange: &range];

  if (style != nil)
    {
      return [NSDictionary dictionaryWithObject: style
					 forKey: NSParagraphStyleAttributeName];
    }
  return [NSDictionary dictionary];
}

- (unsigned) lineBreakBeforeIndex: (unsigned)location
                      withinRange: (NSRange)aRange
{
  NSString *str = [self string];
  unsigned length = [str length];
  NSRange scanRange;
  NSRange startRange;

  if (NSMaxRange(aRange) > length || location > length)
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -lineBreakBeforeIndex:withinRange:"];
    }

  if (!NSLocationInRange(location, aRange))
    return NSNotFound;

  scanRange = NSMakeRange(aRange.location, location - aRange.location);
  startRange = [str rangeOfCharacterFromSet: wordBreakCSet()
				    options: NSBackwardsSearch|NSLiteralSearch
				      range: scanRange];
  if (startRange.length == 0)
    {
      return NSNotFound;
    }
  else
    {
      return NSMaxRange(startRange);
    }
}

- (NSRange) doubleClickAtIndex: (unsigned)location
{
  NSString	*str = [self string];
  unsigned	length = [str length];
  NSRange	scanRange;
  NSRange	startRange;
  NSRange	endRange;

  if (location > length)
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -doubleClickAtIndex:"];
    }

  scanRange = NSMakeRange(0, location);
  startRange = [str rangeOfCharacterFromSet: wordBreakCSet()
				    options: NSBackwardsSearch|NSLiteralSearch
				      range: scanRange];
  scanRange = NSMakeRange(location, length - location);
  endRange = [str rangeOfCharacterFromSet: wordBreakCSet()
				  options: NSLiteralSearch
				    range: scanRange];
  if (startRange.length == 0)
    {
      location = 0;
    }
  else
    {
      location = startRange.location + startRange.length;
    }
  if (endRange.length == 0)
    {
      length = length - location;
    }
  else
    {
      length = endRange.location - location;
    }
  return NSMakeRange(location, length);
}

- (unsigned) nextWordFromIndex: (unsigned)location
		       forward: (BOOL)isForward
{
  NSString *str = [self string];
  unsigned length = [str length];
  NSRange range;

  if (location > length)
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -nextWordFromIndex:forward:"];
    }

  if (isForward)
    {
      range = NSMakeRange(location, length - location);
      range = [str rangeOfCharacterFromSet: wordBreakCSet()
				   options: NSLiteralSearch
				     range: range];
      if (range.length == 0)
	return length;
      range = NSMakeRange(range.location, length - range.location);
      range = [str rangeOfCharacterFromSet: wordCSet()
				   options: NSLiteralSearch
				     range: range];
      if (range.length == 0)
	return length;
      return range.location;
    }
  else
    {
      BOOL inWord = [wordCSet() characterIsMember: [str characterAtIndex: location]];
      
      range = NSMakeRange(0, location);
      if (!inWord)
	{
	  range = [str rangeOfCharacterFromSet: wordCSet()
			 options: NSBackwardsSearch|NSLiteralSearch
			 range: range];
	  if (range.length == 0)
	    return 0;
	  range = NSMakeRange(0, range.location);
	}
      range = [str rangeOfCharacterFromSet: wordBreakCSet()
		   options: NSBackwardsSearch|NSLiteralSearch
		   range: range];
      if (range.length == 0)
	return 0;
      range = NSMakeRange(range.location, location - range.location);
      range = [str rangeOfCharacterFromSet: wordCSet()
				   options: NSLiteralSearch
				     range: range];
      if (range.length == 0)
	return 0;
      return range.location;
    }
}

- (id) initWithPath: (NSString*)path
 documentAttributes: (NSDictionary**)dict
{
  // FIXME: This expects the file to be RTFD
  return [self initWithRTFDFileWrapper: [[NSFileWrapper alloc]
					  initWithPath: path]
	       documentAttributes: dict];
}

- (id) initWithURL: (NSURL*)url 
documentAttributes: (NSDictionary**)dict
{
  NSData *data = [url resourceDataUsingCache: YES];

  // FIXME: This expects the URL to point to a HTML page
  return [self initWithHTML: data
	       baseURL: [url baseURL]
	       documentAttributes: dict];
}

- (id) initWithRTFDFileWrapper: (NSFileWrapper*)wrapper
            documentAttributes: (NSDictionary**)dict
{
  if ([wrapper isRegularFile])
    return [self initWithRTF: [wrapper regularFileContents]
		 documentAttributes: dict];
  else if ([wrapper isDirectory])
    {
      NSDictionary *files = [wrapper fileWrappers];
      NSFileWrapper *contents;

      // We try to read the main file in the directory
      if ((contents = [files objectForKey: @"TXT.rtf"]) != nil)
	return [self initWithRTF: [contents regularFileContents]
		     documentAttributes: dict];
    }

  return nil;
}

- (id) initWithRTFD: (NSData*)data
 documentAttributes: (NSDictionary**)dict
{
  // FIXME: We use RTF, as there are currently no additional images
  return [self initWithRTF: data
	       documentAttributes: dict];
}

- (id) initWithRTF: (NSData*)data
  documentAttributes: (NSDictionary**)dict
{
  NSAttributedString *new = parseRTFintoAttributedString(data, dict);

  // We do not return self but the newly created object
  RELEASE(self);
  return RETAIN(new); 
}

- (id) initWithHTML: (NSData*)data
 documentAttributes: (NSDictionary**)dict
{
  return [self initWithHTML: data
	       baseURL: nil
	       documentAttributes: dict];
}

- (id) initWithHTML: (NSData*)data
            baseURL: (NSURL*)base
 documentAttributes: (NSDictionary**)dict
{
  // FIXME: Not implemented
  return self;
}

- (NSData*) RTFFromRange: (NSRange)range
      documentAttributes: (NSDictionary*)dict
{
  // FIXME: We use RTFD, as there are currently no additional images
  return [self RTFDFromRange: range
	       documentAttributes: dict];
}

- (NSData*) RTFDFromRange: (NSRange)range
       documentAttributes: (NSDictionary*)dict
{
  return [RTFProducer RTFDFromAttributedString: 
			  [self attributedSubstringFromRange: range]
		      documentAttributes: dict];
}

- (NSFileWrapper*) RTFDFileWrapperFromRange: (NSRange)range
			 documentAttributes: (NSDictionary*)dict
{
  if ([self containsAttachments])
    {
      NSMutableDictionary *fileDict = [NSMutableDictionary dictionary];
      NSFileWrapper *txt = [[NSFileWrapper alloc]
			     initRegularFileWithContents:
			       [self RTFFromRange: range
				     documentAttributes: dict]];

      [fileDict setObject: txt forKey: @"TXT.rtf"];
      // FIXME: We have to add the attachments to the directory file wrapper
      
      return [[NSFileWrapper alloc] initDirectoryWithFileWrappers: fileDict];
    }
  else
    return [[NSFileWrapper alloc] initRegularFileWithContents:
				    [self RTFFromRange: range
					  documentAttributes: dict]];
}
@end

@implementation NSMutableAttributedString (AppKit)
- (void) superscriptRange: (NSRange)range
{
  id value;
  int sValue;
  NSRange effRange;

  if (NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -superscriptRange:"];
    }

  // We take the value form the first character and use it for the whole range
  value = [self attribute: NSSuperscriptAttributeName
		  atIndex: range.location
	   effectiveRange: &effRange];

  if (value != nil)
    sValue = [value intValue] + 1;
  else
    sValue = 1;

  [self addAttribute: NSSuperscriptAttributeName
	       value: [NSNumber numberWithInt: sValue]
	       range: range];
}

- (void) subscriptRange: (NSRange)range
{
  id value;
  int sValue;
  NSRange effRange;

  if (NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -subscriptRange:"];
    }

  // We take the value form the first character and use it for the whole range
  value = [self attribute: NSSuperscriptAttributeName
		  atIndex: range.location
	   effectiveRange: &effRange];

  if (value != nil)
    sValue = [value intValue] - 1;
  else
    sValue = -1;

  [self addAttribute: NSSuperscriptAttributeName
	       value: [NSNumber numberWithInt: sValue]
	       range: range];
}

- (void) unscriptRange: (NSRange)range
{
  if (NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -unscriptRange:"];
    }

  [self addAttribute: NSSuperscriptAttributeName
	       value: [NSNumber numberWithInt: 0]
	       range: range];
}

- (void) applyFontTraits: (NSFontTraitMask)traitMask
		   range: (NSRange)range
{
  NSFont *font;
  unsigned loc = range.location;
  NSRange effRange;
  NSFontManager *fm = [NSFontManager sharedFontManager];

  if (NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -applyFontTraits:range:"];
    }

  while (loc < NSMaxRange(range))
    {
      font = [self attribute: NSFontAttributeName
		   atIndex: loc
		   effectiveRange: &effRange];

      if (font != nil && [fm traitsOfFont: font] != traitMask)
	{
	  font = [fm fontWithFamily: [font familyName]
		     traits: traitMask
		     weight: [fm weightOfFont: font]
		     size: [font pointSize]];

	  if (font != nil)
	    [self addAttribute: NSFontAttributeName
		  value: font
		  range: NSIntersectionRange(effRange, range)];
	}
      loc = NSMaxRange(effRange);
    }
}

- (void) setAlignment: (NSTextAlignment)alignment
		range: (NSRange)range
{
  id		value;
  unsigned	loc = range.location;
  
  if (NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -setAlignment:range:"];
    }

  while (loc < NSMaxRange(range))
    {
      BOOL	copiedStyle = NO;
      NSRange	effRange;
      NSRange	newRange;

      value = [self attribute: NSParagraphStyleAttributeName
		      atIndex: loc
	       effectiveRange: &effRange];
      newRange = NSIntersectionRange(effRange, range);

      if (value == nil)
	{
	  value = [NSMutableParagraphStyle defaultParagraphStyle];
	}
      else
	{
	  value = [value mutableCopy];
	  copiedStyle = YES;
	}

      [value setAlignment: alignment];

      [self addAttribute: NSParagraphStyleAttributeName
		   value: value
		   range: newRange];
      if (copiedStyle == YES)
	{
	  RELEASE(value);
	}
      loc = NSMaxRange(effRange);
    }
}

- (void) fixAttributesInRange: (NSRange)range
{
  [self fixFontAttributeInRange: range];
  [self fixParagraphStyleAttributeInRange: range];
//  [self fixAttachmentAttributeInRange: range];
}

- (void) fixFontAttributeInRange: (NSRange)range
{
  if (NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -fixFontAttributeInRange:"];
    }
  // FIXME: Should check for each character if it is supported by the 
  // assigned font
}

- (void) fixParagraphStyleAttributeInRange: (NSRange)range
{
  NSString *str = [self string];
  unsigned loc = range.location;
  NSRange r;

  if (NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -fixParagraphStyleAttributeInRange:"];
    }

  while (loc < NSMaxRange(range))
    {
      NSParagraphStyle	*style;
      NSRange		found;
      unsigned		end;

      /*
       * Extend loc to take in entire paragraph if necessary.
       */
      r = [str lineRangeForRange: NSMakeRange(loc, 1)];
      end = NSMaxRange(r);

      /*
       * get the style in effect at the paragraph start.
       */
      style = [self attribute: NSParagraphStyleAttributeName
		      atIndex: r.location
	       effectiveRange: &found];
      
      if (NSMaxRange(found) < end)
        {
	  /*
	   * Styles differ - add the old style to the remainder of the
	   * range.
	   */
	  found.location = NSMaxRange(found);
	  found.length = end - found.location;
	  [self addAttribute: NSParagraphStyleAttributeName
		value: style
		range: found];
	  loc = end;
	}
      else
	loc = NSMaxRange(found);
    }
}

- (void) fixAttachmentAttributeInRange: (NSRange)aRange
{
  NSString *string = [self string];
  unsigned location = aRange.location;
  unsigned end = NSMaxRange(aRange);

  if (end > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -fixAttachmentAttributeInRange:"];
    }

  // Check for attachments with the wrong character
  while (location < end)
    {
      NSDictionary	*attr;
      NSRange range;

      attr = [self attributesAtIndex: location effectiveRange: &range];
      if ([attr objectForKey: NSAttachmentAttributeName] != nil)
	{
	  unichar	buf[range.length];
	  unsigned	pos = 0;
	  unsigned	start = range.location;

	  // Leave only one character with the attachment
	  [string getCharacters: buf range: range];
	  while (pos < range.length && buf[pos] != NSAttachmentCharacter)
	      pos++;
	  if (pos)
	    [self removeAttribute: NSAttachmentAttributeName
		  range: NSMakeRange(start, pos)];
	  pos++;
	  if (pos < range.length)
	    [self removeAttribute: NSAttachmentAttributeName
		  range: NSMakeRange(start+pos, range.length - pos)];
	}
      location = NSMaxRange(range);
    }

  // Check for attachment characters without attachments
  location = aRange.location;
  while (location < end)
    {
      NSRange range = [string rangeOfString: attachmentString()
			      options: NSLiteralSearch 
			      range: NSMakeRange(location, end - location)];
      NSTextAttachment *attachment;

      if (!range.length)
	break;

      attachment = [self attribute: NSAttachmentAttributeName
			 atIndex: range.location
			 effectiveRange: NULL];

      if (attachment == nil)
        {
	  [self deleteCharactersInRange: NSMakeRange(range.location, 1)];
	  range.length--;
	}

      location = NSMaxRange(range);
    }
}

- (void)updateAttachmentsFromPath:(NSString *)path
{
  NSString *string = [self string];
  unsigned location = 0;
  unsigned end = [string length];

  while (location < end)
    {
      NSRange range = [string rangeOfString: attachmentString()
			      options: NSLiteralSearch 
			      range: NSMakeRange(location, end - location)];
      NSTextAttachment *attachment;
      NSFileWrapper *fileWrapper;

      if (!range.length)
	break;

      attachment = [self attribute: NSAttachmentAttributeName
			 atIndex: range.location
			 effectiveRange: NULL];
      fileWrapper = [attachment fileWrapper];

      // FIXME: Is this the correct thing to do?
      [fileWrapper updateFromPath: [path stringByAppendingPathComponent: 
					     [fileWrapper filename]]];
      location = NSMaxRange(range);
    }
}

@end
