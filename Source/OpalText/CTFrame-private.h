/** <title>CTFrame</title>
 
 <abstract>C Interface to text layout library</abstract>
 
 Copyright <copy>(C) 2011 Free Software Foundation, Inc.</copy>
 
 Author: Eric Wasylishen
 Date: Mar 2011
 
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


/**
 * Container of CTLine objects
 */
@interface CTFrame : NSObject
{
	CGPathRef _path;
	NSMutableArray *_lines;
	NSRange _stringRange;
	NSRange _visibleStringRange;
  NSDictionary *_attributes;
}

- (id) initWithPath: (CGPathRef)aPath
        stringRange: (NSRange)aRange
         attributes: (NSDictionary*)attribs;
- (void) addLine: (CTLineRef)aLine;
- (CGPathRef)path;
- (NSArray*)lines;
- (NSRange)stringRange;
- (NSRange)visibleStringRange;
- (void)setVisibleStringRange: (NSRange)aRange;
- (NSDictionary*)attributes;
- (void)drawOnContext: (CGContextRef)ctx;

@end