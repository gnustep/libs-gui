/* 
   NSRulerView.h

   The NSRulerView class.

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Michael Hanni <mhanni@sprintmail.com>
   Date: Feb 1999
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
#ifndef _GNUstep_H_NSRulerView
#define _GNUstep_H_NSRulerView

#include <AppKit/NSView.h>

@class NSRulerMarker;
@class NSScrollView;

typedef enum {
  NSHorizontalRuler,
  NSVerticalRuler
} NSRulerOrientation;

@interface NSRulerView : NSView
{
  NSMutableArray *_markers;
  NSString *_measurementUnits;
  NSView *_clientView;
  NSView *_accessoryView; 
  NSScrollView *_scrollView;
  float _originOffset;
  float _reservedThicknessForAccessoryView; 
  float _reservedThicknessForMarkers; 
  float _ruleThickness; 
  NSRulerOrientation _orientation; 
}

- (id)initWithScrollView:(NSScrollView *)aScrollView
	     orientation:(NSRulerOrientation)orientation; 


+ (void)registerUnitWithName:(NSString *)unitName
		abbreviation:(NSString *)abbreviation
unitToPointsConversionFactor:(float)conversionFactor
		 stepUpCycle:(NSArray *)stepUpCycle
	       stepDownCycle:(NSArray *)stepDownCycle;

- (void)setMeasurementUnits:(NSString *)unitName; 
- (NSString *)measurementUnits; 

- (void)setClientView:(NSView *)aView; 
- (NSView *)clientView; 

- (void)setAccessoryView:(NSView *)aView; 
- (NSView *)accessoryView; 

- (void)setOriginOffset:(float)offset; 
- (float)originOffset; 

- (void)setMarkers:(NSArray *)markers; 
- (NSArray *)markers;
- (void)addMarker:(NSRulerMarker *)aMarker; 
- (void)removeMarker:(NSRulerMarker *)aMarker; 
- (BOOL)trackMarker:(NSRulerMarker *)aMarker 
     withMouseEvent:(NSEvent *)theEvent; 

- (void)moveRulerlineFromLocation:(float)oldLoc toLocation:(float)newLoc; 

- (void)drawHashMarksAndLabelsInRect:(NSRect)aRect; 
- (void)drawMarkersInRect:(NSRect)aRect; 
- (void)invalidateHashMarks; 

- (void)setScrollView:(NSScrollView *)scrollView;
- (NSScrollView *)scrollView; 

- (void)setOrientation:(NSRulerOrientation)orientation; 
- (NSRulerOrientation)orientation; 
- (void)setReservedThicknessForAccessoryView:(float)thickness; 
- (float)reservedThicknessForAccessoryView; 
- (void)setReservedThicknessForMarkers:(float)thickness; 
- (float)reservedThicknessForMarkers; 
- (void)setRuleThickness:(float)thickness; 
- (float)ruleThickness; 
- (float)requiredThickness;
- (float)baselineLocation; 
- (BOOL)isFlipped;

@end

//
// Methods Implemented by the Delegate 
//
@interface NSObject (NSRulerViewClient)

- (void)rulerView:(NSRulerView *)aRulerView
     didAddMarker:(NSRulerMarker *)aMarker;
- (void)rulerView:(NSRulerView *)aRulerView 
    didMoveMarker:(NSRulerMarker *)aMarker; 
- (void)rulerView:(NSRulerView *)aRulerView 
  didRemoveMarker:(NSRulerMarker *)aMarker; 
- (void)rulerView:(NSRulerView *)aRulerView 
  handleMouseDown:(NSEvent *)theEvent; 
- (BOOL)rulerView:(NSRulerView *)aRulerView 
  shouldAddMarker:(NSRulerMarker *)aMarker; 
- (BOOL)rulerView:(NSRulerView *)aRulerView
 shouldMoveMarker:(NSRulerMarker *)aMarker; 
- (BOOL)rulerView:(NSRulerView *)aRulerView 
   shouldRemoveMarker: (NSRulerMarker *)aMarker;
- (float)rulerView:(NSRulerView *)aRulerView
     willAddMarker:(NSRulerMarker *)aMarker
        atLocation:(float)location; 
- (float)rulerView:(NSRulerView *)aRulerView
    willMoveMarker:(NSRulerMarker *)aMarker
        toLocation:(float)location; 
- (void)rulerView:(NSRulerView *)aRulerView
willSetClientView:(NSView *)newClient; 
@end

#endif /* _GNUstep_H_NSRulerView */

