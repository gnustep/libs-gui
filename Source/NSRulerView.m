/*
   NSRulerView.m

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Diego Kreutz (kreutz@inf.ufsm.br)
   Date: January 2002

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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include <math.h>
#include <gnustep/gui/config.h>

#include <Foundation/NSArray.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include <Foundation/NSValue.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSRulerMarker.h>
#include <AppKit/NSRulerView.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/PSOperators.h>

#ifndef HAVE_RINT
static double rint(double a)
{
  return (floor(a+0.5));
}
#endif

#define MIN_LABEL_DISTANCE 40
#define MIN_MARK_DISTANCE 5

#define MARK_SIZE 2
#define MID_MARK_SIZE 4
#define BIG_MARK_SIZE 6
#define LABEL_MARK_SIZE 11

#define BASE_LINE_LOCATION 0
#define RULER_THICKNESS 16

#define ASSIGN_FIRST_VALUE(firstVal, tRect) (firstVal = (int)((tRect - _zeroLocation) / labelDistInRuler) * labelDistInRuler)

#define ASSIGN_FIRST_MARKER(firstMarker, tRect) (firstMarker = ceil(((tRect - _zeroLocation) - firstVal) / (_unitToRuler * markDistInUnits)))

#define ASSIGN_DIFERENCE(diference, tRect) (diference = (firstMarker * (markDistInUnits * _unitToRuler)) + firstVal + _zeroLocation - tRect)

#define SET_MARK_COUNT(markCount, tRect, dif) (markCount = floor(1 + (tRect - dif) / (_unitToRuler * markDistInUnits)))

#define DRAW_HASH_MARK(context, size)  {if (_orientation == NSHorizontalRuler) DPSrlineto(context, 0, size); else DPSrlineto(context, size, 0);}

@interface GSRulerUnit : NSObject
{
  NSString *_unitName;
  NSString *_abbreviation;
  float    _conversionFactor;
  NSArray  *_stepUpCycle;
  NSArray  *_stepDownCycle;
}

+ (GSRulerUnit *) unitWithName: (NSString *)uName 
                  abbreviation: (NSString *)abbrev 
  unitToPointsConversionFactor: (float)factor 
                   stepUpCycle: (NSArray *)upCycle 
                 stepDownCycle: (NSArray *)downCycle;
- (id) initWithUnitName: (NSString *)uName 
                abbreviation: (NSString *)abbrev
unitToPointsConversionFactor: (float)factor 
                 stepUpCycle: (NSArray *)upCycle 
               stepDownCycle: (NSArray *)downCycle;
- (NSString *) unitName;
- (NSString *) abbreviation;
- (float) conversionFactor;
- (NSArray *) stepUpCycle;
- (NSArray *) stepDownCycle;

@end

@implementation GSRulerUnit

+ (GSRulerUnit *) unitWithName: (NSString *)uName 
                  abbreviation: (NSString *)abbrev 
  unitToPointsConversionFactor: (float)factor 
                   stepUpCycle: (NSArray *)upCycle 
                 stepDownCycle: (NSArray *)downCycle
{
  return [[[self alloc] initWithUnitName: uName 
                            abbreviation: abbrev 
            unitToPointsConversionFactor: factor 
                             stepUpCycle: upCycle 
                           stepDownCycle: downCycle] autorelease];
}

- (id) initWithUnitName: (NSString *)uName 
	   abbreviation: (NSString *)abbrev 
unitToPointsConversionFactor: (float)factor 
	    stepUpCycle: (NSArray *)upCycle 
	  stepDownCycle: (NSArray *)downCycle
{
  self = [super init];
  if (self != nil) 
    {
      ASSIGN(_unitName, uName);
      ASSIGN(_abbreviation, abbrev);
      _conversionFactor = factor;
      ASSIGN(_stepUpCycle, upCycle);
      ASSIGN(_stepDownCycle, downCycle);
    }
  
  return self;
}

- (NSString *) unitName
{
  return _unitName;
}

- (NSString *) abbreviation
{
  return _abbreviation;
}

- (float) conversionFactor
{
  return _conversionFactor;
}

- (NSArray *) stepUpCycle
{
  return _stepUpCycle;
}

- (NSArray *) stepDownCycle
{
  return _stepDownCycle;
}

- (void) dealloc
{
  [_unitName release];
  [_abbreviation release];
  [_stepUpCycle release];
  [_stepDownCycle release];
  [super dealloc];
}

@end


@implementation NSRulerView

/*
 * Class variables
*/
static NSMutableDictionary *units = nil;

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSRulerView class]) 
    {
      NSArray *array05;
      NSArray *array052;
      NSArray *array2;
      NSArray *array10;

      NSDebugLog(@"Initialize NSRulerView class\n");
      [self setVersion: 0.01];

      units = [[NSMutableDictionary alloc] init];
      array05 = [NSArray arrayWithObject: [NSNumber numberWithFloat: 0.5]];
      array052 = [NSArray arrayWithObjects: [NSNumber numberWithFloat: 0.5], 
                 [NSNumber numberWithFloat: 0.2], nil];
      array2 = [NSArray arrayWithObject: [NSNumber numberWithFloat: 2.0]];
      array10 = [NSArray arrayWithObject: [NSNumber numberWithFloat: 10.0]];
      [self registerUnitWithName: @"Inches" 
                    abbreviation: @"in" 
    unitToPointsConversionFactor: 72.0 
                     stepUpCycle: array2
                   stepDownCycle: array05];
      [self registerUnitWithName: @"Centimeters" 
                    abbreviation: @"cm" 
    unitToPointsConversionFactor: 28.35 
                     stepUpCycle: array2
                   stepDownCycle: array052];
      [self registerUnitWithName: @"Points" 
                    abbreviation: @"pt" 
    unitToPointsConversionFactor: 1.0 
                     stepUpCycle: array10
                   stepDownCycle: array05];
      [self registerUnitWithName: @"Picas" 
                    abbreviation: @"pc" 
    unitToPointsConversionFactor: 12.0 
                     stepUpCycle: array2
                   stepDownCycle: array05];
    }
}

- (id) initWithScrollView: (NSScrollView *)aScrollView 
              orientation: (NSRulerOrientation)o
{
  self = [super initWithFrame: NSZeroRect];
  if (self != nil)
    {
      [self setScrollView: aScrollView];
      [self setOrientation: o];
      [self setMeasurementUnits: @"Points"]; /* FIXME: should be user's pref */
      [self setRuleThickness: RULER_THICKNESS];
      [self setOriginOffset: 0.0];
      [self setReservedThicknessForAccessoryView: 0.0];
      [self setReservedThicknessForMarkers: 0.0];
      [self invalidateHashMarks];
    }
  return self;
}
  
+ (void) registerUnitWithName: (NSString *)uName
                 abbreviation: (NSString *)abbreviation
 unitToPointsConversionFactor: (float)conversionFactor 
                  stepUpCycle: (NSArray *)stepUpCycle
                stepDownCycle: (NSArray *)stepDownCycle
{
  GSRulerUnit *u = [GSRulerUnit unitWithName: uName
				abbreviation: abbreviation
				unitToPointsConversionFactor: conversionFactor
				stepUpCycle: stepUpCycle
				stepDownCycle: stepDownCycle];
  [units setObject: u  forKey: uName];
}

- (void) setMeasurementUnits: (NSString *)uName
{
  GSRulerUnit *newUnit;
  
  newUnit = [units objectForKey: uName];
  if (newUnit == nil) 
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"Unknown measurement unit %@", uName];
    }
  ASSIGN(_unit, newUnit);
  [self setNeedsDisplay: YES];
}

- (NSString *) measurementUnits
{
  return [_unit unitName];
}

- (void) setClientView: (NSView *)aView
{
  if (_clientView != nil  
      && [_clientView respondsToSelector: 
			@selector(rulerView:willSetClientView:)]) 
    {
      [_clientView rulerView: self  willSetClientView: aView];
    }
  /* NB: We should not RETAIN the clientView.  */
  _clientView = aView;
  [self setMarkers: nil];
  [self setNeedsDisplay: YES];
}

- (BOOL) isOpaque
{
  return YES;
}

- (NSView *) clientView
{
  return _clientView;
}

- (void) setAccessoryView: (NSView *)aView
{
  /* FIXME/TODO: support for accessory views is not implemented */
  ASSIGN(_accessoryView, aView);
  [self setNeedsDisplay: YES];
}

- (NSView *) accessoryView
{
  return _accessoryView;
}

- (void) setOriginOffset: (float)offset
{
  _originOffset = offset;
  [self setNeedsDisplay: YES];
}

- (float) originOffset
{
  return _originOffset;
}

- (void) setMarkers: (NSArray *)newMarkers
{
  if (newMarkers != nil && _clientView == nil)
    {
      [NSException raise: NSInternalInconsistencyException
                  format: @"Cannot set markers without a client view"];
    }
  if (newMarkers != nil)
    {
      ASSIGN(_markers, [NSMutableArray arrayWithArray: newMarkers]);
    }
  else
    {
      ASSIGN(_markers, nil);
    }
  [self setNeedsDisplay: YES];
}

- (NSArray *) markers
{
  return _markers;
}

- (void) addMarker: (NSRulerMarker *)aMarker
{
  float markerThickness = [aMarker thicknessRequiredInRuler];

  if (_clientView == nil)
    {
      [NSException raise: NSInternalInconsistencyException
                 format: @"Cannot add a marker without a client view"];
    }
   
  if (markerThickness > [self reservedThicknessForMarkers])
    {
      [self setReservedThicknessForMarkers: markerThickness];
    }
  if (_markers == nil) 
    {
      _markers = [[NSMutableArray alloc] initWithObjects: aMarker, nil];
    }
  else 
    {
      [_markers addObject: aMarker];
    }
  
  [self setNeedsDisplay: YES];
}

- (void) removeMarker: (NSRulerMarker *)aMarker
{
  [_markers removeObject: aMarker];
  [self setNeedsDisplay: YES];
}

- (BOOL) trackMarker: (NSRulerMarker *)aMarker
      withMouseEvent: (NSEvent *)theEvent
{
  /* FIXME/TODO: not implemented */
  return NO;
}

- (void) moveRulerlineFromLocation: (float)oldLoc 
                        toLocation: (float)newLoc
{
  /* FIXME/TODO: not implemented */
}

- (void)drawRect: (NSRect)aRect
{
  [[NSColor controlColor] set];
  NSRectFill(aRect);
  [self drawHashMarksAndLabelsInRect: aRect];
  [self drawMarkersInRect: aRect];
}

- (float) _stepForIndex: (int)index
{
  int newindex;
  NSArray *stepCycle;

  if (index > 0) 
    {
      stepCycle = [_unit stepUpCycle];
      newindex = (index - 1) % [stepCycle count];
      return [[stepCycle objectAtIndex: newindex] floatValue];
    } 
  else 
    {
      stepCycle = [_unit stepDownCycle];
      newindex = (-index) % [stepCycle count];
      return 1 / [[stepCycle objectAtIndex: newindex] floatValue];
    }
}

- (void) _verifyCachedValues
{
  if (! _cacheIsValid)
    {
      NSRect rect;
      NSRect unitRect;
      float  cf; 
      int    convIndex;

      /* calculate the position of the zero coordinate in the ruler
       * and the size one unit in document view has in the ruler */
      cf = [_unit conversionFactor];
      rect = NSMakeRect(_originOffset, _originOffset, cf, cf);
      unitRect = [self convertRect: rect  
		       fromView: [_scrollView documentView]];

      if (_orientation == NSHorizontalRuler) 
        {
          _unitToRuler = NSWidth(unitRect);
        }
      else 
        {
          _unitToRuler = NSHeight(unitRect);
        }

      /* Calculate distance between marks.  */
      /* It must not be less than MIN_MARK_DISTANCE in ruler units
       * and must obey the current unit's step cycles.  */
      _markDistance = _unitToRuler;
      convIndex = 0;
      /* make sure it's smaller than MIN_MARK_DISTANCE */
      while ((_markDistance) > MIN_MARK_DISTANCE) 
        {
          _markDistance /= [self _stepForIndex: convIndex];
          convIndex--;
        }
      /* find the first size that's not < MIN_MARK_DISTANCE */
      while ((_markDistance) < MIN_MARK_DISTANCE) 
        {
          convIndex++;
          _markDistance *= [self _stepForIndex: convIndex];
        }
    
      /* calculate number of small marks in each bigger mark */
      _marksToMidMark = rint([self _stepForIndex: convIndex + 1]);
      _marksToBigMark = _marksToMidMark 
                     * rint([self _stepForIndex: convIndex + 2]);
    
      /* Calculate distance between labels.
         It must not be less than MIN_LABEL_DISTANCE. */
      _labelDistance = _markDistance;
      while (_labelDistance < MIN_LABEL_DISTANCE) 
        {
          convIndex++;
          _labelDistance *= [self _stepForIndex: convIndex];
        }

      /* number of small marks between two labels */
      _marksToLabel = rint(_labelDistance / _markDistance);

      /* format of labels */
      if (_labelDistance / _unitToRuler >= 1)
        {
          ASSIGN(_labelFormat, @"%1.f");
        }
      else 
        {
          /* smallest integral value not less than log10(1/labelDistInUnits) */
          int log = ceil(log10(1 / (_labelDistance / _unitToRuler)));
          NSString *string = [NSString stringWithFormat: @"%%.%df", (int)log];
          ASSIGN(_labelFormat, string);
        }

      _cacheIsValid = YES;
    }
}

- (void) drawHashMarksAndLabelsInRect: (NSRect)drawRect
{
  NSGraphicsContext *ctxt = GSCurrentContext();
  NSFont *font;
  NSView *docView;
  float firstVisibleLocation;
  float visibleLength;
  int firstVisibleMark;
  int lastVisibleMark;
  int mark;
  NSRect baseLineRect;
  float baselineLocation = [self baselineLocation];
  NSPoint zeroPoint;

  docView = [_scrollView documentView];
  
  zeroPoint = [self convertPoint: NSMakePoint(_originOffset, _originOffset) 
		    fromView: docView];

  if (_orientation == NSHorizontalRuler)
    {
      _zeroLocation = zeroPoint.x;
    }
  else
    {
      _zeroLocation = zeroPoint.y;
    }

  [self _verifyCachedValues];

  /* TODO: should be a user default */
  font = [NSFont systemFontOfSize: 8];
  [font set];
  [[NSColor blackColor] set];

  baseLineRect = [self convertRect: [docView bounds]  fromView: docView];

  if (_orientation == NSHorizontalRuler) 
    {
      baseLineRect.origin.y = baselineLocation; 
      baseLineRect.size.height = 1;
      baseLineRect = NSIntersectionRect(baseLineRect, drawRect);
      firstVisibleLocation = NSMinX(baseLineRect);
      visibleLength = NSWidth(baseLineRect);
    }
  else 
    {
      baseLineRect.origin.x = baselineLocation;
      baseLineRect.size.width = 1;
      baseLineRect = NSIntersectionRect(baseLineRect, drawRect);
      firstVisibleLocation = NSMinY(baseLineRect);
      visibleLength = NSHeight(baseLineRect);
    }

  /* draw the base line */
  NSRectFill(baseLineRect);

  /* draw hash marks */
  firstVisibleMark = ceil((firstVisibleLocation - _zeroLocation)
                          / _markDistance);
  lastVisibleMark = floor((firstVisibleLocation + visibleLength - _zeroLocation) 
                          / _markDistance);
  
  for (mark = firstVisibleMark; mark <= lastVisibleMark; mark++)
    {
      float markLocation;

      markLocation = _zeroLocation + mark * _markDistance;
      if (_orientation == NSHorizontalRuler)
        {
          DPSmoveto(ctxt, markLocation, baselineLocation);
        }
      else
        {
          DPSmoveto(ctxt, baselineLocation, markLocation);
        }

      if ((mark % _marksToLabel) == 0) 
        {
          float labelValue;
          NSString *label;

          DRAW_HASH_MARK(ctxt, LABEL_MARK_SIZE);

          /* draw label */
          /* FIXME: shouldn't be using NSCell to draw labels? */
          labelValue = (markLocation - _zeroLocation) / _unitToRuler;
          if ([self isFlipped] == NO && labelValue != 0.0)
	    {
	      label = [NSString stringWithFormat: _labelFormat, -labelValue];
	    }
          else
	    {
	      label = [NSString stringWithFormat: _labelFormat, labelValue];
	    }
          if (_orientation == NSHorizontalRuler)
            {
              DPSrmoveto(ctxt, 2, 0);
            }
          else
            {
              float labelWidth;
              labelWidth = [font widthOfString: label];
              DPSrmoveto(ctxt, 3 - labelWidth, 9);
            }
          DPSshow(ctxt, [label cString]);
        }
      else if ((mark % _marksToBigMark) == 0) 
        {
          DRAW_HASH_MARK(ctxt, BIG_MARK_SIZE);
        }
      else if ((mark % _marksToMidMark) == 0)
        {
          DRAW_HASH_MARK(ctxt, MID_MARK_SIZE);
        }
      else 
        {
          DRAW_HASH_MARK(ctxt, MARK_SIZE);
        }
    }
  DPSstroke(ctxt);
}

- (void) drawMarkersInRect: (NSRect)aRect
{
  NSRulerMarker *marker;
  NSEnumerator *en;

  en = [_markers objectEnumerator];
  while ((marker = [en nextObject]) != nil)
    {
      [marker drawRect: aRect];
    }
}

- (void) invalidateHashMarks
{
  _cacheIsValid = NO;
}

- (void) setScrollView: (NSScrollView *)sView
{
  /* We do NOT retain the scrollView; the scrollView is retaining us.  */
  _scrollView = sView;
}

- (NSScrollView *) scrollView
{
  return _scrollView;
}

- (void) setOrientation: (NSRulerOrientation)o
{
  _orientation = o;
}

- (NSRulerOrientation)orientation
{
  return _orientation;
}

- (void) setReservedThicknessForAccessoryView: (float)thickness
{
  _reservedThicknessForAccessoryView = thickness;
  [_scrollView tile];
}

- (float) reservedThicknessForAccessoryView
{
  return _reservedThicknessForAccessoryView;
}

- (void) setReservedThicknessForMarkers: (float)thickness
{
  /*  NSLog(@"requiredThicknessForMarkers: %f", thickness); */
  _reservedThicknessForMarkers = thickness;
  [_scrollView tile];
}

- (float) reservedThicknessForMarkers
{
  return _reservedThicknessForMarkers;
}

- (void) setRuleThickness: (float)thickness
{
  _ruleThickness = thickness;
  [_scrollView tile];
}

- (float) ruleThickness
{
  return _ruleThickness;
}

- (float) requiredThickness
{
  return [self ruleThickness]
    + [self reservedThicknessForAccessoryView]
    + [self reservedThicknessForMarkers];
}

- (float) baselineLocation
{
  return [self reservedThicknessForAccessoryView]
    + [self reservedThicknessForMarkers];
}

/* FIXME ... we cache isFlipped in NSView.  */
- (BOOL) isFlipped
{
  if (_orientation == NSVerticalRuler)
    {
      return [[_scrollView documentView] isFlipped]; 
    }
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  /* FIXME/TODO: not implemented */
  return;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  /* FIXME/TODO: not implemented */
  return nil;
}

- (void) dealloc
{
  RELEASE(_unit);
  RELEASE(_scrollView);
  RELEASE(_clientView);
  RELEASE(_accessoryView);
  RELEASE(_markers);
  RELEASE(_labelFormat);
  [super dealloc];
}

@end

