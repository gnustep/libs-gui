#include <AppKit/NSAttributedString.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSTextAttachment.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSColor.h>
#include <Foundation/NSString.h>
#include <Foundation/NSRange.h>
#include "Parsers/rtfConsumer.h"

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
 * function to return a character set containing paragraph separators
 */
static NSCharacterSet*
paraBreakCSet()
{
  static NSCharacterSet	*cset = nil;

  if (cset == nil)
    {
      NSMutableCharacterSet	*m = [NSMutableCharacterSet new];

      /*
       * Build set with characters specified in MacOS-X documentation for
       * [NSAttributedString -fixParagraphStyleAttributeInRange:]
       */
      [m addCharactersInRange: NSMakeRange(0x000A, 1)];	/* CR */
      [m addCharactersInRange: NSMakeRange(0x000D, 1)];	/* LF */
      [m addCharactersInRange: NSMakeRange(0x2028, 1)];	/* line sep */
      [m addCharactersInRange: NSMakeRange(0x2029, 1)];	/* para sep */
      cset = [m copy];
      RELEASE(m);
    }
  return cset;
}

@interface NSAttributedString(AttributedStringRTFDAdditions)

- (NSString*) RTFHeaderStringWithContext: (NSMutableDictionary*) contextDict;
- (NSString*) RTFTrailerStringWithContext: (NSMutableDictionary*) contextDict;
- (NSString*) RTFBodyStringWithContext: (NSMutableDictionary*) contextDict;
- (NSString*) RTFDStringFromRange: (NSRange)range
	       documentAttributes: (NSDictionary*)dict;
@end

@implementation NSAttributedString (AppKit)

+ (NSAttributedString *)attributedStringWithAttachment:(NSTextAttachment *)attachment
{
  // FIXME: Still missing
  return nil;
}

- (BOOL) containsAttachments
{
  // FIXME: Currently there are no attachment in GNUstep.
  return NO;
}

- (NSDictionary*) fontAttributesInRange: (NSRange)range
{
  NSDictionary	*all;
  static SEL	sel = @selector(objectForKey:);
  IMP		objForKey;
  id		objects[8];
  id		keys[8];
  int		count = 0;

  if (range.location < 0 || NSMaxRange(range) > [self length])
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

  if (range.location < 0 || NSMaxRange(range) > [self length])
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

  if (aRange.location < 0 || NSMaxRange(aRange) > length || 
      location < 0 || location > length)
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

  if (location < 0 || location > length)
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

/*
 * This is where the fun begins with RTF/RTFD/HTML
 * This is currently ALL FIXME. :-)
 * With love from Michael, hehe.
 */


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
  NSString *rtfString = [[NSString alloc] 
			    initWithData: data
			    encoding: NSASCIIStringEncoding];
  NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];

  parseRTFintoAttributedString(rtfString, result, dict); 

  self = [self initWithAttributedString: result];
  RELEASE(rtfString);
  RELEASE(result);

  return self;
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
  return [[self RTFDStringFromRange: range documentAttributes: dict]
    dataUsingEncoding: NSASCIIStringEncoding];
}

- (NSFileWrapper*) RTFDFileWrapperFromRange: (NSRange)range
			 documentAttributes: (NSDictionary*)dict
{
  if ([self containsAttachments])
    {
      NSMutableDictionary *fileDict = [NSMutableDictionary dictionary];
      NSFileWrapper *txt = [[NSFileWrapper alloc]
			     initRegularFileWithContents:
			       [self RTFDFromRange: range
				     documentAttributes: dict]];

      // FIXME: We have to add the attachements to the directory file wrapper
      [fileDict setObject: txt forKey: @"TXT.rtf"];
      return [[NSFileWrapper alloc] initDirectoryWithFileWrappers: fileDict];
    }
  else
    return [[NSFileWrapper alloc] initRegularFileWithContents:
				    [self RTFDFromRange: range
					  documentAttributes: dict]];
}
@end

@implementation NSMutableAttributedString (AppKit)
- (void) superscriptRange: (NSRange)range
{
  id value;
  int sValue;
  NSRange effRange;

  if (range.location < 0 || NSMaxRange(range) > [self length])
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

  if (range.location < 0 || NSMaxRange(range) > [self length])
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
  if (range.location < 0 || NSMaxRange(range) > [self length])
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

  if (range.location < 0 || NSMaxRange(range) > [self length])
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
  
  if (range.location < 0 || NSMaxRange(range) > [self length])
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
//  [self fixParagraphStyleAttributeInRange: range];
//  [self fixAttachmentAttributeInRange: range];
}

- (void) fixFontAttributeInRange: (NSRange)range
{
  if (range.location < 0 || NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -fixFontAttributeInRange:"];
    }
}

- (void) fixParagraphStyleAttributeInRange: (NSRange)range
{
  NSString	*str = [self string];
  unsigned	length = [str length];
  unsigned	location;
  NSRange	r;

  if (range.location < 0 || NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -fixParagraphStyleAttributeInRange:"];
    }

  if (range.location > 0)
    {
      /*
       * Extend range backward to take in entire paragraph if necessary.
       */
      r = NSMakeRange(0, range.location);
      r = [str rangeOfCharacterFromSet: paraBreakCSet()
			       options: NSBackwardsSearch|NSLiteralSearch
				 range: r];
      if (r.length == 0)
	{
	  /*
	   * No paragraph before this in range - so extend range right
	   * back to the start of the string.
	   */
	  range.length += range.location;
	  range.location = 0;
	}
      else if (r.location + 1 < range.location)
	{
	  range.length += (range.location - r.location - 1);
	  range.location = r.location + 1;
	}
    }

  /*
   * Extend range forwards to take in entire paragraph if necessary.
   */
  location = r.location + r.length;
  if (location > 0)
    location--;
  r = NSMakeRange(location, length - location);
  r = [str rangeOfCharacterFromSet: paraBreakCSet()
			   options: NSLiteralSearch
			     range: r];
  if (r.length > 0 && r.location > location)
    range.length += (r.location - location);

  /*
   * Now try to step through the range fixing up the paragraph styles in
   * each paragraph so the entire paragraph has the same style as the
   * first character in the paragraph.
   */
  while (range.length > 0)
    {
      NSParagraphStyle	*style;
      NSRange		found;
      unsigned		end;

      /*
       * Determine position of next paragraph end.
       */
      r = [str rangeOfCharacterFromSet: paraBreakCSet()
			       options: NSLiteralSearch
				 range: range];
      if (r.length == 0)
        end = NSMaxRange(range);
      else
	end = r.location + 1;

      /*
       * get the style in effect at the paragraph start.
       */
      style = [self attribute: NSParagraphStyleAttributeName
		      atIndex: location
	       effectiveRange: &found];
      /*
       * Fix up this paragraph to have the starting style.
       */
      while (NSMaxRange(found) < end)
	{
	  NSParagraphStyle	*nextStyle;
	  NSRange		nextFound;

	  nextStyle = [self attribute: NSParagraphStyleAttributeName
			      atIndex: NSMaxRange(found)
		       effectiveRange: &nextFound];
	  if (nextStyle == style || [nextStyle isEqual: style] == YES)
	    {
	      found = nextFound;
	    }
	  else
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
	    }
	}
      /*
       * Adjust the range to start at the beginning of the next paragraph.
       */
      range.length = NSMaxRange(range) - end;
      range.location = end;
    }
}

- (void) fixAttachmentAttributeInRange: (NSRange)range
{
  unsigned	location = range.location;
  unsigned	end = NSMaxRange(range);

  if (range.location < 0 || NSMaxRange(range) > [self length])
    {
      [NSException raise: NSRangeException
		  format: @"RangeError in method -fixAttachmentAttributeInRange:"];
    }

  while (location < end)
    {
      NSDictionary	*attr;

      attr = [self attributesAtIndex: location effectiveRange: &range];
      if ([attr objectForKey: NSAttachmentAttributeName] != nil)
	{
	  unichar	buf[range.length];
	  unsigned	pos = 0;

	  [[self string] getCharacters: buf range: range];
	  while (pos < range.length)
	    {
	      unsigned	start;
	      unsigned	end;

	      while (pos < range.length && buf[pos] == NSAttachmentCharacter)
		pos++;
	      start = pos;
	      while (pos < range.length && buf[pos] == NSAttachmentCharacter)
		pos++;
	      end = pos;
	      if (start != end)
		[self removeAttribute: NSAttachmentAttributeName
				range: NSMakeRange(start, end - start)];
	    }
	}
      location = NSMaxRange(range);
    }
}

- (void)updateAttachmentsFromPath:(NSString *)path
{
    // FIXME: Still missing
}
@end




/* AttributedStringRTFDAdditions.m created by daniel on Wed 24-Nov-1999 */

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

@implementation NSAttributedString(AttributedStringRTFDAdditions)

- (NSString*) RTFHeaderStringWithContext: (NSMutableDictionary*) contextDict
{
  NSMutableString	*result;
  NSDictionary	*fontDict;
  NSDictionary	*colorDict;
  NSDictionary	*docDict;

  result = (NSMutableString*)[NSMutableString stringWithString: @"{\\rtf0\\ansi"];
  fontDict = [contextDict objectForKey: @"Fonts"];

  // write Font Table
  if (fontDict != nil)
    {
      NSMutableString	*fontlistString = [NSMutableString string];
      NSString		*table;
      NSEnumerator	*fontEnum;
      id		currFont;
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
	  else
	    fontFamily = @"nil";

	  detail = [NSString stringWithFormat: @"%@\\f%@ %@;",
	    [fontDict objectForKey: currFont], fontFamily, currFont];
	  [fontlistString appendString: detail];
	}
      table = [NSString stringWithFormat: @"{\\fonttbl%@}\n", fontlistString];
      [result appendString: table];
    }

  // write Colour table
  colorDict = [contextDict objectForKey: @"Colors"];
  if (colorDict != nil)
    {
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

      [result appendString: @"{\\colortbl;"];
      for (i = 0; i < count; i++)
	{
	  NSColor *color = [list objectAtIndex: i];
	  [result appendString: [NSString stringWithFormat:
					    @"\\red%d\\green%d\\blue%d;",
					  (int)([color redComponent]*255),
					  (int)([color greenComponent]*255),
					  (int)([color blueComponent]*255)]];
	}

      [result appendString: @"}\n"];
    }
  // We should output the parameters for the document
  docDict = [contextDict objectForKey: @"DocumentAttributes"];

  return result;
}

- (NSString*) RTFTrailerStringWithContext: (NSMutableDictionary*) contextDict
{
  return @"}";
}

- (NSString*) RTFBodyStringWithContext: (NSMutableDictionary*) contextDict
{
  NSRange		completeRange;
  NSRange		currRange;
  NSString		*string = [self string];
  NSMutableString	*result = [NSMutableString string];
  NSFont		*currentFont = nil;
  NSColor               *fgColor = [NSColor textColor];
  NSColor               *bgColor = [NSColor textBackgroundColor];

  completeRange = NSRangeFromString([contextDict objectForKey: @"Range"]);
  currRange = NSMakeRange(completeRange.location, 0);

  while (NSMaxRange(currRange) < NSMaxRange(completeRange))  // save all "runs"
    {
      NSDictionary	*attributes;
      NSString		*substring;
      BOOL		useBraces = NO;
      NSMutableString	*headerString;
      NSMutableString	*trailerString;
      NSEnumerator	*attribEnum;
      id		currAttrib;

      attributes = [self attributesAtIndex: NSMaxRange(currRange)
		     longestEffectiveRange: &currRange
				   inRange: completeRange];
      substring = [string substringWithRange: currRange];
      headerString = (id)[NSMutableString string];
      trailerString = (id)[NSMutableString string];

      /*
       * analyze attributes of current run
       */
      attribEnum = [attributes keyEnumerator];
      while ((currAttrib = [attribEnum nextObject]) != nil)
	{
	  /*
	   * handle fonts
	   */
	  if ([currAttrib isEqualToString: NSFontAttributeName])
	    {
	      NSFont			*font;
	      NSMutableDictionary	*peekDict;
	      NSString			*fontToken;
	      NSString			*fontName;
	      NSFontTraitMask		traits;

	      font = [attributes objectForKey: NSFontAttributeName];
	      peekDict = [contextDict objectForKey: @"Fonts"];
	      fontName = [font familyName];
	      traits = [[NSFontManager sharedFontManager] traitsOfFont: font];

	      /*
	       * maintain a dictionary for the used fonts
	       * (for rtf-header generation)
	       */
	      if (peekDict == nil)
		{
		  peekDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		    @"\\f0", fontName, nil];
		  [contextDict setObject: peekDict forKey: @"Fonts"];
		}
	      else
		{
		  if ([peekDict objectForKey: fontName] == nil)
		    {
		      unsigned	count = [peekDict count];
		      NSString	*fCount;

		      fCount = [NSString stringWithFormat: @"\\f%d", count];
		      [peekDict setObject: fCount forKey: fontName];
		    }
		}
	      fontToken = [peekDict objectForKey: fontName];
	      /*
	       * font name
	       */
	      if (![fontName isEqualToString: [currentFont familyName]]
		|| currentFont == nil)
		{
		  [headerString appendString: fontToken];
		}
	      /*
	       * font size
	       */
	      if ([font pointSize] != [currentFont pointSize])
		{
		  int		points = (int)[font pointSize]*2;
		  NSString	*pString;

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
	      currentFont = font;
	    }
	  else if ([currAttrib isEqualToString: NSParagraphStyleAttributeName])
	    {
	      float firstLineIndent;
	      float lineIndent;
	      NSParagraphStyle *paraStyle = [attributes objectForKey:
		NSParagraphStyleAttributeName];
	      NSTextAlignment alignment = [paraStyle alignment];

	      switch (alignment)
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
	      firstLineIndent = [paraStyle firstLineHeadIndent];
	      if (firstLineIndent != 0.0)
		{
		  // FIXME: How should the units be converted?
		  [headerString appendString: [NSString stringWithFormat:
							  @"\\fi%d",
							(int)firstLineIndent]];
		  [trailerString appendString: @"\\fi0"];
		}
	      lineIndent = [paraStyle headIndent];
	      if (lineIndent != 0.0)
		{
		  // FIXME: How should the units be converted?
		  [headerString appendString: [NSString stringWithFormat:
							  @"\\li%d",
							(int)lineIndent]];
		  [trailerString appendString: @"\\li0"];
		}
	    }
	  else if ([currAttrib isEqualToString: NSForegroundColorAttributeName])
	    {
	      NSColor *color = [attributes objectForKey: NSForegroundColorAttributeName];
	      if (![color isEqual: fgColor])
		{
		  NSMutableDictionary	*peekDict;
		  unsigned int cn;

		  peekDict = [contextDict objectForKey: @"Colors"];
		  /*
		   * maintain a dictionary for the used colours
		   * (for rtf-header generation)
		   */
		  if (peekDict == nil)
		    {
		      peekDict = [NSMutableDictionary
				   dictionaryWithObjectsAndKeys:
				     [NSNumber numberWithInt: 1], color, nil];
		      [contextDict setObject: peekDict forKey: @"Colors"];
		      cn = 1;
		    }
		  else
		    {
		      if ([peekDict objectForKey: color] == nil)
			{
			  cn = [peekDict count] + 1;

			  [peekDict setObject: [NSNumber numberWithInt: cn]
				    forKey: color];
			}
		      else
			cn = [[peekDict objectForKey: color] intValue];
		    }
		  [headerString appendString: [NSString stringWithFormat:
							  @"\\cf%d", cn]];
		  [trailerString appendString: @"\\cf0"];
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
							  @"\\dn%d", -svalue]];
		  [trailerString appendString: @"\\dn0"];
		}
	    }
	  else if ([currAttrib isEqualToString: NSBackgroundColorAttributeName])
	    {
	      NSColor *color = [attributes objectForKey: NSForegroundColorAttributeName];
	      if (![color isEqual: bgColor])
		{
		  NSMutableDictionary	*peekDict;
		  unsigned int cn;

		  peekDict = [contextDict objectForKey: @"Colors"];
		  /*
		   * maintain a dictionary for the used colours
		   * (for rtf-header generation)
		   */
		  if (peekDict == nil)
		    {
		      peekDict = [NSMutableDictionary
				   dictionaryWithObjectsAndKeys:
				     [NSNumber numberWithInt: 1], color, nil];
		      [contextDict setObject: peekDict forKey: @"Colors"];
		      cn = 1;
		    }
		  else
		    {
		      if ([peekDict objectForKey: color] == nil)
			{
			  cn = [peekDict count] + 1;

			  [peekDict setObject: [NSNumber numberWithInt: cn]
				    forKey: color];
			}
		      else
			cn = [[peekDict objectForKey: color] intValue];
		    }
		  [headerString appendString: [NSString stringWithFormat:
							  @"\\cb%d", cn]];
		  [trailerString appendString: @"\\cb0"];
		}
	    }
	  else if ([currAttrib isEqualToString: NSAttachmentAttributeName])
	    {
	    }
	  else if ([currAttrib isEqualToString: NSLigatureAttributeName])
	    {
	    }
	  else if ([currAttrib isEqualToString: NSBaselineOffsetAttributeName])
	    {
	    }
	  else if ([currAttrib isEqualToString: NSKernAttributeName])
	    {
	    }
	}
    // write down current run
      substring = [substring stringByReplacingString: @"\\"
					  withString: @"\\\\"];
      substring = [substring stringByReplacingString: @"\n"
					  withString: @"\\par\n"];
      substring = [substring stringByReplacingString: @"\t"
					  withString: @"\\tab"];
      substring = [substring stringByReplacingString: @"{"
					  withString: @"\\{"];
      substring = [substring stringByReplacingString: @"}"
					  withString: @"\\}"];
      // FIXME: All characters not in the standard encodeing must be
      // replaced by \'xx

      if (useBraces)
	{
	  NSString	*braces;

	  if ([headerString length])
	      braces = [NSString stringWithFormat: @"{%@ %@%@}",
				 headerString, substring, trailerString];
	  else
	      braces = [NSString stringWithFormat: @"{%@%@}",
				 substring, trailerString];

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
	  
	  if ([trailerString length])
	      nobraces = [NSString stringWithFormat: @"%@%@ ",
				   nobraces, trailerString];

	  [result appendString: nobraces];
	}
    }
  return result;
}


- (NSString*) RTFDStringFromRange: (NSRange)range
	       documentAttributes: (NSDictionary*)dict
{
  NSMutableString	*output = [NSMutableString string];
  NSString		*headerString;
  NSString		*trailerString;
  NSString		*bodyString;
  NSMutableDictionary	*context = [NSMutableDictionary dictionary];

  [context setObject: (dict ? dict : [NSMutableDictionary dictionary])
	      forKey: @"DocumentAttributes"];
  [context setObject: NSStringFromRange(range) forKey: @"Range"];

  /*
   * do not change order! (esp. body has to be generated first; builds context)
   */
  bodyString = [self RTFBodyStringWithContext: context];
  trailerString = [self RTFTrailerStringWithContext: context];
  headerString = [self RTFHeaderStringWithContext: context];

  [output appendString: headerString];
  [output appendString: bodyString];
  [output appendString: trailerString];
  return (NSString*)output;
}
@end
