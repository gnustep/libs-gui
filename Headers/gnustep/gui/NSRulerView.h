#ifndef _GNUstep_H_NSRulerView
#define _GNUstep_H_NSRulerView

#include <AppKit/NSView.h>
#include <AppKit/NSRulerMarker.h>
#include <AppKit/NSScrollView.h>

typedef enum {
  NSHorizontalRuler,
  NSVerticalRuler
} NSRulerOrientation;

@interface NSRulerView : NSView <NSObject, NSCoding>

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

