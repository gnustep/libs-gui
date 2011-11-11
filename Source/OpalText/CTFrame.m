/** <title>CTFrame</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#include <CoreText/CTFrame.h>
#import "CTFrame-private.h"

/* Constants */

const CFStringRef kCTFrameProgressionAttributeName = @"kCTFrameProgressionAttributeName";

/* Classes */

@implementation CTFrame

- (id) initWithPath: (CGPathRef)aPath
        stringRange: (NSRange)aRange
         attributes: (NSDictionary*)attribs
{
  if ((self = [super init]))
  {
    _path = [aPath retain];
    _lines = [[NSMutableArray alloc] init];
    _attributes = [attribs copy];
    _stringRange = aRange;
  }
  return self;
}

- (void) dealloc
{
  [_attributes release];
  [_path release];
  [_lines release];
  [super dealloc];
}

- (void) addLine: (CTLineRef)aLine
{
  [_lines addObject: aLine];
}

- (CGPathRef)path
{
  return _path;
}

- (NSArray*)lines
{
  return _lines;
}

- (NSRange)stringRange
{
  return _stringRange; 
}
- (NSRange)visibleStringRange
{
  return _visibleStringRange;
}
- (void)setVisibleStringRange: (NSRange)aRange
{
  _visibleStringRange = aRange;
}
- (NSDictionary*)attributes
{
  return nil;
}
- (void)drawOnContext: (CGContextRef)ctx
{
  // FIXME: see CTFrameProgression docs comment about rotating 90 degrees
  NSUInteger linesCount = [_lines count];
  for (NSUInteger i=0; i<linesCount; i++)
  {
    CTLineRef line = [_lines objectAtIndex: i];
    // FIXME: How does positioning work?
    CTLineDraw(line, ctx);
  }
}

@end


/* Functions */

CFRange CTFrameGetStringRange(CTFrameRef frame)
{
  return [frame stringRange];
}
CFRange CTFrameGetVisibleStringRange(CTFrameRef frame)
{
  return [frame visibleStringRange];
}
CGPathRef CTFrameGetPath(CTFrameRef frame)
{
  return [frame path];
}
CFDictionaryRef CTFrameGetFrameAttributes(CTFrameRef frame)
{
  return [frame attributes];
}
CFArrayRef CTFrameGetLines(CTFrameRef frame)
{
  return [frame lines];
}
void CTFrameGetLineOrigins(
	CTFrameRef frame,
	CFRange range,
	CGPoint origins[])
{

}
void CTFrameDraw(CTFrameRef frame, CGContextRef ctx)
{
  [frame drawOnContext: ctx];
}

CFTypeID CTFrameGetTypeID()
{
  return (CFTypeID)[CTFrame class];
}

