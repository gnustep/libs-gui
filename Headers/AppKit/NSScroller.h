/* 
   NSScroller.h

   The scroller class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   A completely rewritten version of the original source by Scott Christley.
   Date: July 1997
   
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

#ifndef _GNUstep_H_NSScroller
#define _GNUstep_H_NSScroller
#import <GNUstepBase/GSVersionMacros.h>

#include <AppKit/NSControl.h>
#include <AppKit/NSCell.h>

@class NSEvent;

typedef enum _NSScrollArrowPosition {
  NSScrollerArrowsMaxEnd,
  NSScrollerArrowsMinEnd,
  NSScrollerArrowsNone 
} NSScrollArrowPosition;

typedef enum _NSScrollerPart {
  NSScrollerNoPart = 0,
  NSScrollerDecrementPage,
  NSScrollerKnob,
  NSScrollerIncrementPage,
  NSScrollerDecrementLine,
  NSScrollerIncrementLine,
  NSScrollerKnobSlot
} NSScrollerPart;

typedef enum _NSScrollerUsablePart {
  NSNoScrollerParts = 0,
  NSOnlyScrollerArrows,
  NSAllScrollerParts  
} NSUsableScrollerParts;

typedef enum _NSScrollerArrow {
  NSScrollerIncrementArrow,
  NSScrollerDecrementArrow
} NSScrollerArrow;

@interface NSScroller : NSControl <NSCoding>
{
  float _floatValue;
  float _knobProportion;
  float _pendingKnobProportion;
  id _target;
  SEL _action;
  BOOL _isHorizontal;
  BOOL _isEnabled;
  NSScrollerPart _hitPart;
  NSScrollArrowPosition _arrowsPosition;
  NSUsableScrollerParts _usableParts;
  BOOL _cacheValid;
}

//
// Laying out the NSScroller 
//
+ (float)scrollerWidth;
- (NSScrollArrowPosition)arrowsPosition;
- (void)checkSpaceForParts;
- (NSRect)rectForPart:(NSScrollerPart)partCode;
- (void)setArrowsPosition:(NSScrollArrowPosition)where;
- (NSUsableScrollerParts)usableParts;

//
// Setting the NSScroller's Values
//
- (float)knobProportion;
- (void)setFloatValue:(float)aFloat knobProportion:(float)ratio;

//
// Displaying 
//
- (void)drawArrow:(NSScrollerArrow)whichButton highlight:(BOOL)flag;
- (void)drawKnobSlot;
- (void)drawKnob;
- (void)drawParts;
- (void)highlight:(BOOL)flag;

//
// Handling Events 
//
- (NSScrollerPart)hitPart;

/* Return the part of the scroller which contains thePoint.  thePoint
 * is in the window's coordinate system.
 */
- (NSScrollerPart)testPart:(NSPoint)thePoint;
- (void)trackKnob:(NSEvent *)theEvent;
- (void)trackScrollButtons:(NSEvent *)theEvent;

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
+ (float)scrollerWidthForControlSize:(NSControlSize)controlSize;
- (void)setControlSize:(NSControlSize)controlSize;
- (NSControlSize)controlSize;
- (void)setControlTint:(NSControlTint)controlTint;
- (NSControlTint)controlTint;
#endif

@end

#endif // _GNUstep_H_NSScroller
