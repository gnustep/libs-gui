/* 
   NSParagraphStyle.m

     NSParagraphStyle and NSMutableParagraphStyle hold paragraph style 
     information NSTextTab holds information about a single tab stop

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998 - skeleton
   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date March 1999 - implementation
   
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

#import <Foundation/Foundation.h>
#include <AppKit/NSParagraphStyle.h>

@implementation NSTextTab

- (id) copyWithZone: (NSZone*)aZone
{
  if (NSShouldRetainWithZone(self, aZone) == YES)
    return RETAIN(self);
  return NSCopyObject(self, 0, aZone);
}

- (id) initWithType: (NSTextTabType)type location: (float)loc
{
  self = [super init];
  tabStopType = type;
  location = loc;
  return self;
}

- (NSComparisonResult) compare: (id)anObject
{
  float	loc;

  if (anObject == self)
    return NSOrderedSame;
  if (anObject == nil || ([anObject isKindOfClass: self->isa] == NO))
    return NSOrderedAscending;
  loc = ((NSTextTab*)anObject)->location;
  if (loc < location)
    return NSOrderedAscending;
  else if (loc > location)
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}

- (unsigned) hash
{
  unsigned val = (unsigned)location;

  val ^= (unsigned)tabStopType;
  return val;
}

- (BOOL) isEqual: (id)anObject
{
  if (anObject == self)
    return YES;
  if ([anObject isKindOfClass: self->isa] == NO)
    return NO;
  else if (((NSTextTab*)anObject)->tabStopType != tabStopType)
    return NO;
  else if (((NSTextTab*)anObject)->location != location)
    return NO;
  return YES;
}

- (float) location
{
  return location;
}

- (NSTextTabType) tabStopType
{
  return tabStopType;
}
@end



@implementation NSParagraphStyle

static NSParagraphStyle	*defaultStyle = nil;

+ (NSParagraphStyle*) defaultParagraphStyle
{
  if (defaultStyle == nil)
    {
      NSParagraphStyle	*style = [[self alloc] init];
      int		i;

      for (i = 0; i < 12; i++)
	{
	  NSTextTab	*tab;

	  tab = [[NSTextTab alloc] initWithType: NSLeftTabStopType
				       location: (i*1)*28.0];
	  [style->tabStops addObject: tab];
	  RELEASE(tab);
	}

      /*
       * If another thread was doing this at the same time, it may have
       * assigned it's own defaultStyle - if so we use that and discard ours.
       */
      if (defaultStyle != nil)
	RELEASE(style);
      else
	defaultStyle = style;
    }
  return defaultStyle;
}

- (void) dealloc
{
  if (self == defaultStyle)
    {
      NSLog(@"Argh - attempt to dealloc the default paragraph style!");
      return;
    }
  RELEASE(tabStops);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  alignment = NSNaturalTextAlignment;
  firstLineHeadIndent = 0.0;
  headIndent = 0.0;
  lineBreakMode = NSLineBreakByWordWrapping;
  lineSpacing = 0.0;
  maximumLineHeight = 0.0;
  minimumLineHeight = 0.0;
  paragraphSpacing = 0.0;
  tailIndent = 0.0;
  // FIXME: I find it surprising that this is mutable, this propably was done to
  // reuse it for NSMutableParagraphStyle. Still I think it is wrong.
  tabStops = [[NSMutableArray allocWithZone: [self zone]] initWithCapacity: 12];
  return self;
}

/*
 *      "Leading": distance between the bottom of one line fragment and top
 *      of next (applied between lines in the same container).
 *      Can't be negative. This value is included in the line fragment
 *      heights in layout manager.
 */
- (float) lineSpacing
{
  return lineSpacing;
}

/*
 *      Distance between the bottom of this paragraph and top of next.
 */
- (float) paragraphSpacing
{
  return paragraphSpacing;
}

- (NSTextAlignment) alignment
{
  return alignment;
}

/*
 *      The following values are relative to the appropriate margin
 *      (depending on the paragraph direction)
 */

/*
 *      Distance from margin to front edge of paragraph
 */
- (float) headIndent
{
  return headIndent;
}

/*
 *      Distance from margin to back edge of paragraph; if negative or 0,
 *      from other margin
 */
- (float) tailIndent
{
  return tailIndent;
}

/*
 *      Distance from margin to edge appropriate for text direction
 */
- (float) firstLineHeadIndent
{
  return firstLineHeadIndent;
}

/*
 *      Distance from margin to tab stops
 */
- (NSArray *) tabStops
{
  return AUTORELEASE([tabStops copyWithZone: NSDefaultMallocZone()]);
}

/*
 *      Line height is the distance from bottom of descenders to to
 *      of ascenders; basically the line fragment height. Does not include
 *      lineSpacing (which is added after this computation).
 */
- (float) minimumLineHeight
{
  return minimumLineHeight;
}

/*
 *      0 implies no maximum.
 */
- (float) maximumLineHeight
{
  return maximumLineHeight;
} 

- (NSLineBreakMode) lineBreakMode
{
  return lineBreakMode;
}

- (id) copyWithZone: (NSZone*)aZone
{
  if (NSShouldRetainWithZone(self, aZone) == YES)
    return RETAIN(self);
  else
    {
      NSParagraphStyle	*c;

      c = (NSParagraphStyle*)NSCopyObject(self, 0, aZone);
      c->tabStops = [tabStops mutableCopyWithZone: aZone];
      return c;
    }
}

- (id) mutableCopyWithZone: (NSZone*)aZone
{
  NSMutableParagraphStyle	*c;

  c = [[NSMutableParagraphStyle allocWithZone: aZone] init];
  [c setParagraphStyle: self];
  return c;
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  unsigned	count;

  [aCoder decodeValueOfObjCType: @encode(NSTextAlignment) at: &alignment];
  [aCoder decodeValueOfObjCType: @encode(NSLineBreakMode) at: &lineBreakMode];
  [aCoder decodeValueOfObjCType: @encode(float) at: &firstLineHeadIndent];
  [aCoder decodeValueOfObjCType: @encode(float) at: &headIndent];
  [aCoder decodeValueOfObjCType: @encode(float) at: &lineSpacing];
  [aCoder decodeValueOfObjCType: @encode(float) at: &maximumLineHeight];
  [aCoder decodeValueOfObjCType: @encode(float) at: &minimumLineHeight];
  [aCoder decodeValueOfObjCType: @encode(float) at: &paragraphSpacing];
  [aCoder decodeValueOfObjCType: @encode(float) at: &tailIndent];

  /*
   *	Tab stops don't conform to NSCoding - so we do it the long way.
   */
  [aCoder decodeValueOfObjCType: @encode(unsigned) at: &count];
  tabStops = [[NSMutableArray alloc] initWithCapacity: count];
  if (count > 0)
    {
      float		locations[count];
      NSTextTabType	types[count];
      unsigned		i;

      [aCoder decodeArrayOfObjCType: @encode(float)
			      count: count
				 at: locations];
      [aCoder decodeArrayOfObjCType: @encode(NSTextTabType)
			      count: count
				 at: types];
      for (i = 0; i < count; i++)
	{
	  NSTextTab	*tab;

	  tab = [NSTextTab alloc];
	  tab = [tab initWithType: types[i] location: locations[i]];
	  [tabStops addObject: tab];
	  RELEASE(tab);
	}
    }

  return self;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  unsigned	count;

  [aCoder encodeValueOfObjCType: @encode(NSTextAlignment) at: &alignment];
  [aCoder encodeValueOfObjCType: @encode(NSLineBreakMode) at: &lineBreakMode];
  [aCoder encodeValueOfObjCType: @encode(float) at: &firstLineHeadIndent];
  [aCoder encodeValueOfObjCType: @encode(float) at: &headIndent];
  [aCoder encodeValueOfObjCType: @encode(float) at: &lineSpacing];
  [aCoder encodeValueOfObjCType: @encode(float) at: &maximumLineHeight];
  [aCoder encodeValueOfObjCType: @encode(float) at: &minimumLineHeight];
  [aCoder encodeValueOfObjCType: @encode(float) at: &paragraphSpacing];
  [aCoder encodeValueOfObjCType: @encode(float) at: &tailIndent];

  /*
   *	Tab stops don't conform to NSCoding - so we do it the long way.
   */
  count = [tabStops count];
  [aCoder encodeValueOfObjCType: @encode(unsigned) at: &count];
  if (count > 0)
    {
      float		locations[count];
      NSTextTabType	types[count];
      unsigned		i;

      for (i = 0; i < count; i++)
	{
	  NSTextTab	*tab = [tabStops objectAtIndex: i];

	  locations[count] = [tab location]; 
	  types[count] = [tab tabStopType]; 
	}
      [aCoder encodeArrayOfObjCType: @encode(float)
			      count: count
				 at: locations];
      [aCoder encodeArrayOfObjCType: @encode(NSTextTabType)
			      count: count
				 at: types];
    }
}

@end



@implementation NSMutableParagraphStyle 

+ (NSParagraphStyle*) defaultParagraphStyle
{
  return AUTORELEASE([[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
}

- (void) setLineSpacing: (float)aFloat
{
  NSAssert(aFloat >= 0.0, NSInvalidArgumentException);
  lineSpacing = aFloat;
}

- (void) setParagraphSpacing: (float)aFloat
{
  NSAssert(aFloat >= 0.0, NSInvalidArgumentException);
  paragraphSpacing = aFloat;
}

- (void) setAlignment: (NSTextAlignment)newAlignment
{
  alignment = newAlignment;
}

- (void) setFirstLineHeadIndent: (float)aFloat
{
  NSAssert(aFloat >= 0.0, NSInvalidArgumentException);
  firstLineHeadIndent = aFloat;
}

- (void) setHeadIndent: (float)aFloat
{
  NSAssert(aFloat >= 0.0, NSInvalidArgumentException);
  headIndent = aFloat;
}

- (void) setTailIndent: (float)aFloat
{
  tailIndent = aFloat;
}

- (void) setLineBreakMode: (NSLineBreakMode)mode
{
  lineBreakMode = mode;
}

- (void) setMinimumLineHeight: (float)aFloat
{
  NSAssert(aFloat >= 0.0, NSInvalidArgumentException);
  minimumLineHeight = aFloat;
}

- (void) setMaximumLineHeight: (float)aFloat
{
  NSAssert(aFloat >= 0.0, NSInvalidArgumentException);
  maximumLineHeight = aFloat;
}

- (void) addTabStop: (NSTextTab*)anObject
{
  unsigned	count = [tabStops count];

  if (count == 0)
    {
      [tabStops addObject: anObject];
    }
  else
    {
      while (count-- > 0)
	{
	  NSTextTab	*tab;

	  tab = [tabStops objectAtIndex: count];
	  if ([tab compare: anObject] != NSOrderedDescending)
	    {
	      [tabStops insertObject: anObject atIndex: count+1];
	      return;
	    }
	}
      [tabStops insertObject: anObject atIndex: 0];
    }
}

- (void) removeTabStop: (NSTextTab*)anObject
{
  unsigned	i = [tabStops indexOfObject: anObject];

  if (i != NSNotFound)
    [tabStops removeObjectAtIndex: i];
}

- (void) setTabStops: (NSArray *)array
{
  if (array != tabStops)
    {
      [tabStops removeAllObjects];
      [tabStops addObjectsFromArray: array];
      [tabStops sortUsingSelector: @selector(compare:)];
    }
}

- (void) setParagraphStyle: (NSParagraphStyle*)obj
{
  NSMutableParagraphStyle	*p = (NSMutableParagraphStyle*)obj;

  if (p == self)
    return;

  /* Can add tab stops without sorting as we know they are already sorted. */
  [tabStops removeAllObjects];
  [tabStops addObjectsFromArray: p->tabStops];

  alignment = p->alignment;
  firstLineHeadIndent = p->firstLineHeadIndent;
  headIndent = p->headIndent;
  lineBreakMode = p->lineBreakMode;
  lineSpacing = p->lineSpacing;
  maximumLineHeight = p->maximumLineHeight;
  minimumLineHeight = p->minimumLineHeight;
  paragraphSpacing = p->paragraphSpacing;
  tailIndent = p->tailIndent;
}

@end

