/*
   NSScroller.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   A completely rewritten version of the original source by Scott Christley.
   Date: July 1997
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   
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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <gnustep/gui/config.h>
#include <math.h>

#include <Foundation/NSDate.h>
#include <Foundation/NSRunLoop.h>

#include <AppKit/NSScroller.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSImage.h>
#include <AppKit/PSMatrix.h>



@implementation NSScroller

//
// Class variables 
//
static NSButtonCell* upCell = nil;						// button cells used by 
static NSButtonCell* downCell = nil;					// scroller instances
static NSButtonCell* leftCell = nil;					// to draw scroller 
static NSButtonCell* rightCell = nil;					// buttons and knob.
static NSButtonCell* knobCell = nil;

static const float scrollerWidth = 17;
static const float buttonsWidth = 16;
static const float buttonsDistance = 1;

static float halfKnobRectHeight;							
static float slotOriginPlusKnobHeight;
static float slotOriginPlusSlotHeightMinusKnobHeight;
static float slotHeightMinusKnobHeight;
static float halfKnobRectWidth;
static float slotOriginPlusKnobWidth;
static float slotOriginPlusSlotWidthMinusHalfKnobWidth;
static float slotWidthMinusKnobWidth;
static NSRect slotRect = {{0,0},{0,0}};
static BOOL preCalcValues = NO;

//
// Class methods 
//
+ (void)initialize
{
	if (self == [NSScroller class])
		[self setVersion:1];
}

+ (float)scrollerWidth						{ return scrollerWidth; }
- (NSScrollArrowPosition)arrowsPosition		{ return _arrowsPosition; }
- (NSUsableScrollerParts)usableParts		{ return _usableParts; }
- (float)knobProportion						{ return _knobProportion; }
- (NSScrollerPart)hitPart					{ return _hitPart; }
- (float)floatValue							{ return _floatValue; }
- (void)setAction:(SEL)action				{ _action = action; }
- (SEL)action								{ return _action; }
- (void)setTarget:(id)target				{ ASSIGN(_target, target); }
- (id)target								{ return _target; }
- (void)encodeWithCoder:aCoder				{ }
- initWithCoder:aDecoder					{ return self; }
- (BOOL)isOpaque							{ return YES; }

- initWithFrame:(NSRect)frameRect
{
	if (frameRect.size.width > frameRect.size.height) 		// determine the
		{													// orientation of
		_isHorizontal = YES;								// the scroller and
		frameRect.size.height = [isa scrollerWidth];		// adjust it's size
		}													// accordingly
	else 
		{
		_isHorizontal = NO;
		frameRect.size.width = [isa scrollerWidth];
		}

	[super initWithFrame:frameRect];
	
	if (_isHorizontal)
		_arrowsPosition = NSScrollerArrowsMinEnd;
	else
		_arrowsPosition = NSScrollerArrowsMaxEnd;
	
	_hitPart = NSScrollerNoPart;
	[self drawParts];
	[self setEnabled:NO];
	[self checkSpaceForParts];
	
	return self;
}

- init
{
	return [self initWithFrame:NSZeroRect];
}

- (void)drawParts
{												// Create the class variable 
	if (knobCell)								// button cells if they do not 
		return;									// yet exist.
	
	upCell = [NSButtonCell new];
	[upCell setHighlightsBy:NSChangeBackgroundCellMask|NSContentsCellMask];
	[upCell setImage:[NSImage imageNamed:@"common_ArrowUp"]];
	[upCell setAlternateImage:[NSImage imageNamed:@"common_ArrowUpH"]];
	[upCell setImagePosition:NSImageOnly];
	[upCell setContinuous:YES];
	[upCell setPeriodicDelay:0.05 interval:0.05];
	
	downCell = [NSButtonCell new];
	[downCell setHighlightsBy:NSChangeBackgroundCellMask|NSContentsCellMask];
	[downCell setImage:[NSImage imageNamed:@"common_ArrowDown"]];
	[downCell setAlternateImage:[NSImage imageNamed:@"common_ArrowDownH"]];
	[downCell setImagePosition:NSImageOnly];
	[downCell setContinuous:YES];
	[downCell setPeriodicDelay:0.05 interval:0.05];
	
	leftCell = [NSButtonCell new];
	[leftCell setHighlightsBy:NSChangeBackgroundCellMask|NSContentsCellMask];
	[leftCell setImage:[NSImage imageNamed:@"common_ArrowLeft"]];
	[leftCell setAlternateImage:[NSImage imageNamed:@"common_ArrowLeftH"]];
	[leftCell setImagePosition:NSImageOnly];
	[leftCell setContinuous:YES];
	[leftCell setPeriodicDelay:0.05 interval:0.05];
	
	rightCell = [NSButtonCell new];
	[rightCell setHighlightsBy:NSChangeBackgroundCellMask|NSContentsCellMask];
	[rightCell setImage:[NSImage imageNamed:@"common_ArrowRight"]];
	[rightCell setAlternateImage:[NSImage imageNamed:@"common_ArrowRightH"]];
	[rightCell setImagePosition:NSImageOnly];
	[rightCell setContinuous:YES];
	[rightCell setPeriodicDelay:0.05 interval:0.05];
	
	knobCell = [NSButtonCell new];
	[knobCell setButtonType:NSMomentaryChangeButton];
	[knobCell setImage:[NSImage imageNamed:@"common_Dimple"]];
	[knobCell setImagePosition:NSImageOnly];
}

- (void)_setTargetAndActionToCells
{
	[upCell setTarget:_target];
	[upCell setAction:_action];
	
	[downCell setTarget:_target];
	[downCell setAction:_action];
	
	[leftCell setTarget:_target];
	[leftCell setAction:_action];
	
	[rightCell setTarget:_target];
	[rightCell setAction:_action];
	
	[knobCell setTarget:_target];
	[knobCell setAction:_action];
}

- (void)checkSpaceForParts
{
NSSize frameSize = [self frame].size;
float size = (_isHorizontal ? frameSize.width : frameSize.height);
float scrollerWidth = [isa scrollerWidth];

	if (size > 3 * scrollerWidth + 2)
		_usableParts = NSAllScrollerParts;
	else 
		if (size > 2 * scrollerWidth + 1)
			_usableParts = NSOnlyScrollerArrows;
		else 
			if (size > scrollerWidth)
				_usableParts = NSNoScrollerParts;
}

- (void)setEnabled:(BOOL)flag
{
	if (_isEnabled == flag)
		return;
	
	_isEnabled = flag;
	[self setNeedsDisplay:YES];
}

- (void)setArrowsPosition:(NSScrollArrowPosition)where
{
	if (_arrowsPosition == where)
		return;

	_arrowsPosition = where;
	[self setNeedsDisplay:YES];
}

- (void)setFloatValue:(float)aFloat
{
	if (aFloat < 0)
		_floatValue = 0;
	else 
		if (aFloat > 1)
			_floatValue = 1;
		else
			_floatValue = aFloat;
							
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

- (void)setFloatValue:(float)aFloat knobProportion:(float)ratio
{
	if (ratio < 0)
		_knobProportion = 0;
	else 
		if (ratio > 1)
			_knobProportion = 1;
		else
			_knobProportion = ratio;

	[self setFloatValue:aFloat];
}

- (void)setFrame:(NSRect)frameRect
{
	if (frameRect.size.width > frameRect.size.height) 		// determine the
		{													// orientation of
		_isHorizontal = YES;								// the scroller and
		frameRect.size.height = [isa scrollerWidth];		// adjust it's size
		}													// accordingly
	else 
		{
		_isHorizontal = NO;
		frameRect.size.width = [isa scrollerWidth];
		}

	[super setFrame:frameRect];
	
	if (_isHorizontal)
		_arrowsPosition = NSScrollerArrowsMinEnd;
	else
		_arrowsPosition = NSScrollerArrowsMaxEnd;
	
	_hitPart = NSScrollerNoPart;
	[self checkSpaceForParts];
}

- (void)setFrameSize:(NSSize)size
{
	[super setFrameSize:size];
	[self checkSpaceForParts];
	[self setNeedsDisplay:YES];
}

- (NSScrollerPart)testPart:(NSPoint)thePoint				// return what part
{															// of the scroller
NSRect rect;												// the mouse hit

	if (thePoint.x < 0 || thePoint.x > frame.size.width
			|| thePoint.y < 0 || thePoint.y > frame.size.height)
		return NSScrollerNoPart;
	
	rect = [self rectForPart:NSScrollerDecrementLine];
	if ([self mouse:thePoint inRect:rect])
		return NSScrollerDecrementLine;
	
	rect = [self rectForPart:NSScrollerIncrementLine];
	if ([self mouse:thePoint inRect:rect])
		return NSScrollerIncrementLine;
	
	rect = [self rectForPart:NSScrollerKnob];
	if ([self mouse:thePoint inRect:rect])
		return NSScrollerKnob;
	
	rect = [self rectForPart:NSScrollerKnobSlot];
	if ([self mouse:thePoint inRect:rect])
		return NSScrollerKnobSlot;
	
	rect = [self rectForPart:NSScrollerDecrementPage];
	if ([self mouse:thePoint inRect:rect])
		return NSScrollerDecrementPage;
	
	rect = [self rectForPart:NSScrollerIncrementPage];
	if ([self mouse:thePoint inRect:rect])
		return NSScrollerIncrementPage;
	
	return NSScrollerNoPart;
}

- (float)_floatValueForMousePoint:(NSPoint)point
{
NSRect knobRect = [self rectForPart:NSScrollerKnob];
NSRect slotRect = [self rectForPart:NSScrollerKnobSlot];
float floatValue = 0;
float position;

	if (_isHorizontal) 									// Adjust point to lie
		{												// within the knob slot 
		float halfKnobRectWidth = knobRect.size.width / 2;

		if (point.x < slotRect.origin.x + halfKnobRectWidth)
			position = slotRect.origin.x + halfKnobRectWidth;
		else
			{ 
			if (point.x > slotRect.origin.x + slotRect.size.width - 
					halfKnobRectWidth)
				position = slotRect.origin.x + slotRect.size.width - 
							halfKnobRectWidth;
			else
				position = point.x;						
			}											// Compute float value 
														// given the knob size
		floatValue = (position - (slotRect.origin.x + halfKnobRectWidth))
						/ (slotRect.size.width - knobRect.size.width);
		}
	else 												// Adjust point to lie
		{						 						// within the knob slot 
		float halfKnobRectHeight = knobRect.size.height / 2;

		if (point.y < slotRect.origin.y + halfKnobRectHeight)
			position = slotRect.origin.y + halfKnobRectHeight;
		else 
			{
			if (point.y > slotRect.origin.y + slotRect.size.height - 
					halfKnobRectHeight)
				position = slotRect.origin.y + slotRect.size.height - 
							halfKnobRectHeight;
			else
				position = point.y;
			}
														// Compute float value
		floatValue = (position - (slotRect.origin.y + halfKnobRectHeight)) / 
						(slotRect.size.height - knobRect.size.height);
		floatValue = 1 - floatValue;
		}

	return floatValue;
}

- (void)_preCalcParts										// pre calculate
{															// values to lessen
NSRect knobRect = [self rectForPart:NSScrollerKnob];		// the burden while
															// scrolling
	slotRect = [self rectForPart:NSScrollerKnobSlot];

	halfKnobRectWidth = knobRect.size.width / 2;
	slotOriginPlusKnobWidth = slotRect.origin.x + halfKnobRectWidth;
	slotOriginPlusSlotWidthMinusHalfKnobWidth = slotRect.origin.x + 	
									slotRect.size.width - halfKnobRectWidth;
	slotWidthMinusKnobWidth = slotRect.size.width - knobRect.size.width;

	halfKnobRectHeight = knobRect.size.height / 2;
	slotOriginPlusKnobHeight = slotRect.origin.y + halfKnobRectHeight;
	slotOriginPlusSlotHeightMinusKnobHeight = slotRect.origin.y + 
									slotRect.size.height - halfKnobRectHeight;
	slotHeightMinusKnobHeight = slotRect.size.height - knobRect.size.height;
}

- (float)_floatValueForMousePointFromPreCalc:(NSPoint)point
{															
float floatValue = 0;										 
float position;

	if (_isHorizontal) 									// Adjust point to lie
		{												// within the knob slot 
		if (point.x < slotOriginPlusKnobWidth)
			position = slotOriginPlusKnobWidth;
		else
			{ 
			if (point.x > slotOriginPlusSlotWidthMinusHalfKnobWidth)
				position = slotOriginPlusSlotWidthMinusHalfKnobWidth;
			else
				position = point.x;
			}											// Compute float value 
														// given the knob size
		floatValue = (position - slotOriginPlusKnobWidth) / 
						slotWidthMinusKnobWidth;
		}
	else 												// Adjust point to lie
		{						 						// within the knob slot 
		if (point.y < slotOriginPlusKnobHeight)
			position = slotOriginPlusKnobHeight;
		else 
			{
			if (point.y > slotOriginPlusSlotHeightMinusKnobHeight)
				position = slotOriginPlusSlotHeightMinusKnobHeight;
			else
				position = point.y;
			}
														// Compute float value
		floatValue = (position - slotOriginPlusKnobHeight) / 
						slotHeightMinusKnobHeight;
		floatValue = 1 - floatValue;
		}

	return floatValue;
}

- (void)mouseDown:(NSEvent*)theEvent
{
NSPoint location = [self convertPoint:[theEvent locationInWindow]
						 fromView:nil];

	[self lockFocus];
	_hitPart = [self testPart:location];
	[self _setTargetAndActionToCells];
	
	switch (_hitPart) 
		{
		case NSScrollerIncrementLine:
		case NSScrollerDecrementLine:
		case NSScrollerIncrementPage:
		case NSScrollerDecrementPage:
			[self trackScrollButtons:theEvent];
			break;
		
		case NSScrollerKnob:
			[self trackKnob:theEvent];
			break;
		
		case NSScrollerKnobSlot: 
			{
			float floatValue = [self _floatValueForMousePoint:location];
		
			[self setFloatValue:floatValue];
			[self sendAction:_action to:_target];
			[self drawKnobSlot];
			[self drawKnob];
			[window flushWindow];
			[self trackKnob:theEvent];
			break;
			}
	
		case NSScrollerNoPart:
			break;
		}
	
	_hitPart = NSScrollerNoPart;
	[self unlockFocus];
}

- (void)trackKnob:(NSEvent*)theEvent
{
unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
							| NSLeftMouseDraggedMask | NSMouseMovedMask
							| NSPeriodicMask;
NSApplication *app = [NSApplication sharedApplication];
NSPoint point, apoint;
float oldFloatValue = _floatValue;
float floatValue;
NSDate *theDistantFuture = [NSDate distantFuture];
PSMatrix* matrix;
NSEventType eventType;
NSRect knobRect = {{0,0},{0,0}};
int periodCount = 0;								// allows a forced update
NSArray* path = [self _pathBetweenSubview:self 
					  toSuperview:[window contentView]];

    matrix = [self _concatenateMatricesInReverseOrderFromPath:path];
    [matrix inverse];

//fprintf(stderr, " trackKnob \n");

	[self _preCalcParts];							// pre calc scroller parts
	preCalcValues = YES;

	_hitPart = NSScrollerKnob;						// set periodic events rate
													// to achieve max of ~30fps
	[NSEvent startPeriodicEventsAfterDelay:0.02 withPeriod:0.03];
	[[NSRunLoop currentRunLoop] limitDateForMode:NSEventTrackingRunLoopMode];

	while ((eventType = [theEvent type]) != NSLeftMouseUp)				 
		{											// user is moving scroller
		if (eventType != NSPeriodic)				// loop until left mouse up
			{
			apoint = [theEvent locationInWindow];	// zero the periodic count 
			periodCount = 0;						// whenever a real position
			}										// event is recieved
		else				
			{						// if 6x periods have gone by w/o movement 
			if(periodCount == 6)	// check mouse and update if necessary
				apoint = [window mouseLocationOutsideOfEventStream];

			point = [matrix pointInMatrixSpace:apoint];

			if (point.x != knobRect.origin.x || point.y != knobRect.origin.y) 
				{									
				floatValue = [self _floatValueForMousePointFromPreCalc:point];

				if (floatValue != oldFloatValue) 
					{
					if (floatValue < 0)
						_floatValue = 0;
					else
						{ 
						if (floatValue > 1)
							_floatValue = 1;
						else
							_floatValue = floatValue;
						}

					[self drawKnobSlot];			// draw the scroller slot
					[self drawKnob];				// draw the scroller knob
					[_target performSelector:_action withObject:self];
					[window flushWindow];

					oldFloatValue = floatValue;
					}						// avoid timing related scrolling
											// hesitation by counting number of
				knobRect.origin = point;	// periodic events since scroll pos
				}							// was updated, when this reaches
			periodCount++;					// 6x periodic rate an update is
			}								// forced on next periodic event
		theEvent = [app nextEventMatchingMask:eventMask
						untilDate:theDistantFuture 
						inMode:NSEventTrackingRunLoopMode
						dequeue:YES];
  		}				
	[NSEvent stopPeriodicEvents];

	if([_target isKindOf:[NSScrollView class]])			// hack for XRAW FIX ME
		{												 
		NSObject *targetCV = (NSObject *)[_target contentView];

		if([targetCV respondsToSelector:@selector(_freeMatrix)])
			[targetCV _freeMatrix];
		}

	preCalcValues = NO;
}

- (void)trackScrollButtons:(NSEvent*)theEvent
{
NSApplication *theApp = [NSApplication sharedApplication];
unsigned int eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask | 
							NSLeftMouseDraggedMask | NSMouseMovedMask;
NSPoint location;
BOOL shouldReturn = NO;
id theCell = nil;
NSRect rect;

	NSDebugLog (@"trackScrollButtons");
	do {
		location = [self convertPoint:[theEvent locationInWindow]fromView:nil];
		_hitPart = [self testPart:location];
		rect = [self rectForPart:_hitPart];
		
		switch (_hitPart) 									// determine which 
			{												// cell was hit
			case NSScrollerIncrementLine:
			case NSScrollerIncrementPage:
				theCell = (_isHorizontal ? rightCell : upCell);
				break;

			case NSScrollerDecrementLine:
			case NSScrollerDecrementPage:
				theCell = (_isHorizontal ? leftCell : downCell);
				break;

			default:
				theCell = nil;
				break;
			}

		if (theCell) 
			{
			[theCell highlight:YES withFrame:rect inView:self];	
			[window flushWindow];

			NSLog (@"tracking cell %x", theCell);
       
			shouldReturn = [theCell trackMouse:theEvent		// Track the mouse
									inRect:rect				// until left mouse
									ofView:self				// goes up
									untilMouseUp:YES];

			if([_target isKindOf:[NSScrollView class]])		// a hack for XRAW
				{											// FIX ME
				NSObject *targetCV = (NSObject *)[_target contentView];

				if([targetCV respondsToSelector:@selector(_freeMatrix)])
					[targetCV _freeMatrix];
				}

			[theCell highlight:NO withFrame:rect inView:self];
			[window flushWindow];
			}

		if (shouldReturn)
			break;

		theEvent = [theApp nextEventMatchingMask:eventMask
							untilDate:[NSDate distantFuture] 
							inMode:NSEventTrackingRunLoopMode
							dequeue:YES];
		} 
	while ([theEvent type] != NSLeftMouseUp);

	NSDebugLog (@"return from trackScrollButtons");
}

- (BOOL)sendActionO:(SEL)theAction to:(id)theTarget
{															// send action to
BOOL ret = [super sendAction:theAction to:theTarget];		// the target on 
															// behalf of cell
	[self drawKnobSlot];			// lockFocus set in mouseDown method is 
	[self drawKnob];				// active so we simply redraw the knob and 
  	[window flushWindow];			// slot to reflect the hit scroll button	

	return ret;
}												

//
//	draw the scroller
//
- (void)drawRect:(NSRect)rect
{
	NSDebugLog (@"NSScroller drawRect: ((%f, %f), (%f, %f))",
			rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	
	[self drawArrow:NSScrollerDecrementArrow highlight:NO];	
	[self drawArrow:NSScrollerIncrementArrow highlight:NO];
	
	[self drawKnobSlot];
	[self drawKnob];
}

- (void)drawArrow:(NSScrollerArrow)whichButton highlight:(BOOL)flag
{
NSRect rect = [self rectForPart:(whichButton == NSScrollerIncrementArrow
						? NSScrollerIncrementLine : NSScrollerDecrementLine)];
id theCell = nil;

	NSDebugLog (@"position of %s cell is (%f, %f)",
		(whichButton == NSScrollerIncrementArrow ? "increment" : "decrement"),
		rect.origin.x, rect.origin.y);
	
	switch (whichButton) 
		{
		case NSScrollerDecrementArrow:
			theCell = (_isHorizontal ? leftCell : downCell);
			break;
		case NSScrollerIncrementArrow:
			theCell = (_isHorizontal ? rightCell : upCell);
			break;
		}
	
	[theCell drawWithFrame:rect inView:self];
}

- (void)drawKnob
{
	[knobCell drawWithFrame:[self rectForPart:NSScrollerKnob] inView:self];
}

- (void)drawKnobSlot
{
NSRect rect;

	if(preCalcValues)									// in a modal loop we
		rect = slotRect;								// have already pre
	else												// calc'd our parts
		rect = [self rectForPart:NSScrollerKnobSlot];

	[[NSColor darkGrayColor] set];						
	NSRectFill(rect);									// draw the bar slot
}

- (NSRect)rectForPart:(NSScrollerPart)partCode
{
NSRect scrollerFrame = frame;
float x = 1, y = 1, width = 0, height = 0, floatValue;
NSScrollArrowPosition arrowsPosition;
NSUsableScrollerParts usableParts;
											// If the scroller is disabled then
	if (!_isEnabled)						// the scroller buttons and the 
		usableParts = NSNoScrollerParts;	// knob are not displayed at all.
	else
		usableParts = _usableParts;

								// Since we haven't yet flipped views we have 
	if (!_isHorizontal) 		// to swap the meaning of the arrows position
		{						// if the scroller's orientation is vertical.
		if (_arrowsPosition == NSScrollerArrowsMaxEnd)
			arrowsPosition = NSScrollerArrowsMinEnd;
		else
			{ 
			if (_arrowsPosition == NSScrollerArrowsMinEnd)
				arrowsPosition = NSScrollerArrowsMaxEnd;
			else
				arrowsPosition = NSScrollerArrowsNone;
			}
		}
	else
		arrowsPosition = _arrowsPosition;

						// Assign to `width' and `height' values describing 
						// the width and height of the scroller regardless 
						// of its orientation.  Also compute the `floatValue' 
   if (_isHorizontal) 	// which is essentially the same width as _floatValue
		{				// but keeps track of the scroller's orientation.
		width = scrollerFrame.size.height;
		height = scrollerFrame.size.width;
		floatValue = _floatValue;
		}
    else 
		{
		width = scrollerFrame.size.width;
		height = scrollerFrame.size.height;
		floatValue = 1 - _floatValue;
    	}								// The x, y, width and height values 
										// are computed below for the vertical  	
	switch (partCode) 					// scroller.  The height of the scroll 
		{								// buttons is assumed to be equal to 
    	case NSScrollerKnob: 			// the width.
			{
			float knobHeight, knobPosition, slotHeight;
      									// If the scroller does not have parts 
										// or a knob return a zero rect. 
			if (usableParts == NSNoScrollerParts || 
									usableParts == NSOnlyScrollerArrows)
				return NSZeroRect;
      													// calc the slot Height
			slotHeight = height - (arrowsPosition == NSScrollerArrowsNone ? 
									0 : 2 * (buttonsWidth + buttonsDistance));
			if (_isHorizontal) 
				slotHeight -= 2;
      		knobHeight = _knobProportion * slotHeight;
      		if (knobHeight < buttonsWidth)
        		knobHeight = buttonsWidth;
														// calc knob's position
      		knobPosition = floatValue * (slotHeight - knobHeight);
     		knobPosition = (float)floor(knobPosition);	// avoid rounding error
      													// calc actual position
      		y = knobPosition + (arrowsPosition == NSScrollerArrowsMaxEnd
			  					|| arrowsPosition == NSScrollerArrowsNone ? 
								0 : 2 * (buttonsWidth + buttonsDistance));
			height = knobHeight;
			width = buttonsWidth;
			if (_isHorizontal) 							// keeps horiz knob off
				y++;									// of the buttons
			break;
    		}

		case NSScrollerKnobSlot:
			x = 0;										// if the scroller does		 
      		width = scrollerWidth; 						// not have buttons the 
														// slot completely 
			if (usableParts == NSNoScrollerParts) 		// fills the scroller.
				{
				y = 0;									// `height' unchanged
				break;
				}
			if (arrowsPosition == NSScrollerArrowsMaxEnd) 
				{
				y = 0;
				height -= 2 * (buttonsWidth + buttonsDistance) + 1;
				}
			else 
				{
				if (arrowsPosition == NSScrollerArrowsMinEnd) 
					{
					y = 2 * (buttonsWidth + buttonsDistance) + 1;
					height -= y;
					}
				else 
					y = 0;								// `height' unchanged
				}
			break;

		case NSScrollerDecrementLine:
		case NSScrollerDecrementPage:
			if (usableParts == NSNoScrollerParts)		// if scroller has no
				return NSZeroRect;						// parts or knob then
														// return a zero rect
			width = buttonsWidth;
			if (arrowsPosition == NSScrollerArrowsMaxEnd)
				y = height - 2 * (buttonsWidth + buttonsDistance);
			else
				{ 
				if (arrowsPosition == NSScrollerArrowsMinEnd)
					y = 1;
				else
					return NSZeroRect;
				}
      		height = buttonsWidth;
			break;

		case NSScrollerIncrementLine:
		case NSScrollerIncrementPage:
			if (usableParts == NSNoScrollerParts)		// if scroller has no
				return NSZeroRect;						// parts or knob then
														// return a zero rect
      		width = buttonsWidth;
      		if (arrowsPosition == NSScrollerArrowsMaxEnd)
				y = height - (buttonsWidth + buttonsDistance);
      		else 
				{
				if (arrowsPosition == NSScrollerArrowsMinEnd)
					y = buttonsWidth + buttonsDistance + 1;
      			else
					return NSZeroRect;
				}
				height = buttonsWidth;
				break;

		case NSScrollerNoPart:
      		return NSZeroRect;
  		}

	if (_isHorizontal)
		return NSMakeRect (y, x, height, width);
	else
		return NSMakeRect (x, y, width, height);
}

@end
