/** <title>NSRulerView</title>

   <abstract>The NSRulerView class.</abstract>

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: Sept 2001
   
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

#include <Foundation/NSValue.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSRulerMarker.h>
#include <AppKit/NSRulerView.h>
#include <AppKit/NSScrollView.h>


NSString *defaultUnits;

@implementation NSRulerView

+ (void) initialize
{
  if (self == [NSRulerView class])
    {
      NSArray *two = [NSArray arrayWithObject: [NSNumber numberWithFloat: 2.0]];
      NSArray *half = [NSArray arrayWithObject: [NSNumber numberWithFloat: 0.5]];
      NSArray *ten = [NSArray arrayWithObject: [NSNumber numberWithFloat: 10.0]];
      NSArray *half_fifth = [NSArray arrayWithObjects: 
					 [NSNumber numberWithFloat: 0.5],
				     [NSNumber numberWithFloat: 0.2],
				     nil];

      // Register the predefined units
      [self registerUnitWithName: @"Inches"
	    abbreviation: @"in"
	    unitToPointsConversionFactor: 72.0
	    stepUpCycle: two
	    stepDownCycle: half];
      [self registerUnitWithName: @"Centimeters"
	    abbreviation: @"cm"
	    unitToPointsConversionFactor: 28.35
	    stepUpCycle: two
	    stepDownCycle: half_fifth];
      [self registerUnitWithName: @"Points"
	    abbreviation: @"pt"
	    unitToPointsConversionFactor: 1.0
	    stepUpCycle: ten
	    stepDownCycle: half];
      [self registerUnitWithName: @"Picas"
	    abbreviation: @"pc"
	    unitToPointsConversionFactor: 12.0
	    stepUpCycle: ten
	    stepDownCycle: half];

      defaultUnits = [[NSUserDefaults standardUserDefaults] 
			objectForKey: @"NSMeasurementUnit"];
      if (defaultUnits == nil)
	defaultUnits = @"Centimeters";
    }
}

+ (void)registerUnitWithName:(NSString *)unitName
		abbreviation:(NSString *)abbreviation
unitToPointsConversionFactor:(float)conversionFactor
		 stepUpCycle:(NSArray *)stepUpCycle
	       stepDownCycle:(NSArray *)stepDownCycle
{
  // FIXME
}

- (id)initWithScrollView:(NSScrollView *)aScrollView
	     orientation:(NSRulerOrientation)orientation
{
  // FIXME
  [super init];
  _scrollView = aScrollView;
  _orientation = orientation;
  [self setMeasurementUnits: defaultUnits];

  return self;
}


- (void)setMeasurementUnits:(NSString *)unitName
{
  // FIXME
  ASSIGN(_measurementUnits, unitName);
}

- (NSString *)measurementUnits
{
  return _measurementUnits;
}

- (void)setClientView:(NSView *)aView
{
  if (_clientView == aView)
    return;

  if ([_clientView respondsToSelector: @selector(rulerView:willSetClientView:)])
    [_clientView rulerView: self willSetClientView: aView];

  _clientView = aView;
  // FIXME Remove all markers
}

- (NSView *)clientView
{
  return _clientView;
} 

- (void)setAccessoryView:(NSView *)aView
{
  // FIXME
  ASSIGN(_accessoryView, aView);
}

- (NSView *)accessoryView
{
  return _accessoryView;
}

- (void)setOriginOffset:(float)offset
{
  _originOffset = offset;
}

- (float)originOffset
{
  return _originOffset;
}

- (void)setMarkers:(NSArray *)markers
{
  // FIXME
}

- (NSArray *)markers
{
  return _markers;
}

- (void)addMarker:(NSRulerMarker *)aMarker
{
  [_markers addObject: aMarker];
}

- (void)removeMarker:(NSRulerMarker *)aMarker
{
  [_markers removeObject: aMarker];
}

- (BOOL)trackMarker:(NSRulerMarker *)aMarker 
     withMouseEvent:(NSEvent *)theEvent
{
  return [aMarker trackMouse: theEvent adding: YES];
}

- (void)moveRulerlineFromLocation:(float)oldLoc toLocation:(float)newLoc
{
  // FIXME
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)aRect
{
  // FIXME
}

- (void)drawMarkersInRect:(NSRect)aRect
{
  // FIXME
}

- (void) drawRect: (NSRect)rect
{
  [self drawHashMarksAndLabelsInRect: rect];
  [self drawMarkersInRect: rect];
}

- (void)invalidateHashMarks
{
  // FIXME
}

- (void)setScrollView:(NSScrollView *)scrollView
{
  // FIXME
  _scrollView = scrollView;
}

- (NSScrollView *)scrollView
{
  return _scrollView;
}

- (void)setOrientation:(NSRulerOrientation)orientation
{
  _orientation = orientation; 
}

- (NSRulerOrientation)orientation
{
  return _orientation;
}

- (void)setReservedThicknessForAccessoryView:(float)thickness
{
  _reservedThicknessForAccessoryView = thickness;
}

- (float)reservedThicknessForAccessoryView
{
  return _reservedThicknessForAccessoryView;
}

- (void)setReservedThicknessForMarkers:(float)thickness
{
  _reservedThicknessForMarkers = thickness; 
}

- (float)reservedThicknessForMarkers
{
  return _reservedThicknessForMarkers;
}

- (void)setRuleThickness:(float)thickness
{
  _ruleThickness = thickness; 
}

- (float)ruleThickness
{
  return _ruleThickness;
}

- (float)requiredThickness
{
  // FIXME
  return 0.0;
}

- (float)baselineLocation
{
  // FIXME
  return 0.0;
}

- (BOOL)isFlipped
{
  return [_scrollView isFlipped];
}

// NSCoding protocol
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // FIXME
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  // FIXME
  return [super initWithCoder: aDecoder];
}

// NSObject protocol

@end
