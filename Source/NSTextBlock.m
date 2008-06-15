/* NSTextBlock.m

   Copyright (C) 2008 Free Software Foundation, Inc.

   Author:  H. Nikolaus Schaller
   Date: 2007
   Author:  Fred Kiefer <fredkiefer@gmx.de>
   Date: January 2008
   
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

#include <Foundation/NSCoder.h>
#include <Foundation/NSString.h>

#include "AppKit/NSColor.h"
#include "AppKit/NSTextTable.h"

@implementation NSTextBlock

- (id) init
{
  // FIXME
  return self;
}

- (void) dealloc
{
	RELEASE(_backgroundColor);
  RELEASE(_borderColorForEdge[NSMinXEdge]);
  RELEASE(_borderColorForEdge[NSMinYEdge]);
  RELEASE(_borderColorForEdge[NSMaxXEdge]);
  RELEASE(_borderColorForEdge[NSMaxYEdge]);
	[super dealloc];
}

- (NSColor *) backgroundColor
{
  return _backgroundColor;
}

- (void) setBackgroundColor: (NSColor *)color
{
    ASSIGN(_backgroundColor, color);
}

- (NSColor *) borderColorForEdge: (NSRectEdge)edge
{
  return _borderColorForEdge[edge];
}

- (void) setBorderColor: (NSColor *)color forEdge: (NSRectEdge)edge
{
  ASSIGN(_borderColorForEdge[edge], color);
}

- (void) setBorderColor: (NSColor *)color
{
  ASSIGN(_borderColorForEdge[NSMinXEdge], color);
  ASSIGN(_borderColorForEdge[NSMinYEdge], color);
  ASSIGN(_borderColorForEdge[NSMaxXEdge], color);
  ASSIGN(_borderColorForEdge[NSMaxYEdge], color);
}

- (float) contentWidth
{
  return _contentWidth;
}

- (NSTextBlockValueType) contentWidthValueType
{
  return _contentWidthValueType;
}

- (void) setContentWidth: (float)val type: (NSTextBlockValueType)type
{
  _contentWidth = val;
  _contentWidthValueType = type;
}

- (NSTextBlockVerticalAlignment) verticalAlignment
{
  return _verticalAlignment;
}

- (void) setVerticalAlignment: (NSTextBlockVerticalAlignment)alignment
{
 _verticalAlignment = alignment; 
}

- (float) valueForDimension: (NSTextBlockDimension)dimension
{
  return _value[dimension];
}

- (NSTextBlockValueType) valueTypeForDimension: (NSTextBlockDimension)dimension
{
  return _valueType[dimension];
}

- (void) setValue: (float)val 
             type: (NSTextBlockValueType)type
     forDimension: (NSTextBlockDimension)dimension
{
  _value[dimension] = val;
  _valueType[dimension] = type;
}

- (float) widthForLayer: (NSTextBlockLayer)layer edge: (NSRectEdge)edge
{
  return _width[layer][edge];
}

- (NSTextBlockValueType) widthValueTypeForLayer: (NSTextBlockLayer)layer
                                           edge: (NSRectEdge)edge
{
  return _widthType[layer][edge];
}

- (void) setWidth: (float)val
             type: (NSTextBlockValueType)type
         forLayer: (NSTextBlockLayer)layer
             edge: (NSRectEdge)edge
{
  _width[layer][edge] = val;
  _widthType[layer][edge] = type;
}

- (void) setWidth: (float)val
             type: (NSTextBlockValueType)type 
         forLayer: (NSTextBlockLayer)layer
{
  _width[layer][NSMinXEdge] = val;
  _widthType[layer][NSMinXEdge] = type;
  _width[layer][NSMinYEdge] = val;
  _widthType[layer][NSMinYEdge] = type;
  _width[layer][NSMaxXEdge] = val;
  _widthType[layer][NSMaxXEdge] = type;
  _width[layer][NSMaxYEdge] = val;
  _widthType[layer][NSMaxYEdge] = type;
}

- (NSRect) boundsRectForContentRect: (NSRect)cont
                             inRect: (NSRect)rect
                      textContainer: (NSTextContainer *)container
                     characterRange: (NSRange)range
{
  // FIXME
  return NSZeroRect;
}

- (NSRect) rectForLayoutAtPoint: (NSPoint)point
                         inRect: (NSRect)rect
                  textContainer: (NSTextContainer *)cont
                 characterRange: (NSRange)range
{
  // FIXME
  return NSZeroRect;
}

- (void) drawBackgroundWithFrame: (NSRect)rect
                          inView: (NSView *)view 
                  characterRange: (NSRange)range
                   layoutManager: (NSLayoutManager *)lm
{
  // FIXME
}

- (id) copyWithZone: (NSZone*)zone
{
  NSTextBlock *t = (NSTextBlock*)NSCopyObject(self, 0, zone);

  TEST_RETAIN(_backgroundColor);
  TEST_RETAIN(_borderColorForEdge[NSMinXEdge]);
  TEST_RETAIN(_borderColorForEdge[NSMinYEdge]);
  TEST_RETAIN(_borderColorForEdge[NSMaxXEdge]);
  TEST_RETAIN(_borderColorForEdge[NSMaxYEdge]);

  return t;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // FIXME
  if ([aCoder allowsKeyedCoding])
    {
    }
  else
    {
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  // FIXME
  if ([aDecoder allowsKeyedCoding])
    {
    }
  else
    {
    }
  return self;
}

@end
