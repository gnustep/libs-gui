/* 
   NSEvent.m

   The event class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Scott Christley <scottc@net-community.com>
   Author:	Ovidiu Predescu <ovidiu@net-community.com>
   Date: 1996
   Author:	Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Sept 1998
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <gnustep/gui/config.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSTimer.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSException.h>

#include <AppKit/NSEvent.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSDPSContext.h>

@implementation NSEvent

// Class variables
static NSString	*timerKey = @"NSEventTimersKey";

//
// Class methods
//
+ (void)initialize
{
	if (self == [NSEvent class])
		{
		NSDebugLog(@"Initialize NSEvent class\n");
		[self setVersion:1];								// Initial version
		}
}

//
// Creating NSEvent objects
//
+ (NSEvent *)enterExitEventWithType:(NSEventType)type	
						   location:(NSPoint)location
						   modifierFlags:(unsigned int)flags
						   timestamp:(NSTimeInterval)time
						   windowNumber:(int)windowNum
						   context:(NSDPSContext *)context	
						   eventNumber:(int)eventNum
						   trackingNumber:(int)trackingNum
						   userData:(void *)userData
{
NSEvent *e = [[[NSEvent alloc] init] autorelease];
															// do nothing if
	if ((type != NSMouseEntered) && (type != NSMouseExited) // event is not of
			&& (type != NSCursorUpdate))					// a desired type
		return nil;											

	e->event_type = type;									// Set the event's
	e->location_point = location;							// fields
	e->modifier_flags = flags;
	e->event_time = time;
	e->window_num = windowNum;
	e->event_context = context;
	e->event_data.tracking.event_num = eventNum;
	e->event_data.tracking.tracking_num = trackingNum;
	e->event_data.tracking.user_data = userData;

	return e;
}

+ (NSEvent *)keyEventWithType:(NSEventType)type
					 location:(NSPoint)location
					 modifierFlags:(unsigned int)flags
					 timestamp:(NSTimeInterval)time
					 windowNumber:(int)windowNum
					 context:(NSDPSContext *)context	
					 characters:(NSString *)keys	
					 charactersIgnoringModifiers:(NSString *)ukeys
					 isARepeat:(BOOL)repeatKey	
					 keyCode:(unsigned short)code
{
NSEvent *e = [[[NSEvent alloc] init] autorelease];
															// do nothing if
	if ((type != NSKeyDown) && (type != NSKeyUp))			// event is not of
		return nil;											// a desired type

	e->event_type = type;									// Set the event's
	e->location_point = location;							// fields
	e->modifier_flags = flags;
	e->event_time = time;
	e->window_num = windowNum;
	e->event_context = context;
	[keys retain];
	e->event_data.key.char_keys = keys;
	[ukeys retain];
	e->event_data.key.unmodified_keys = ukeys;
	e->event_data.key.repeat = repeatKey;
	e->event_data.key.key_code = code;

	return e;
}

+ (NSEvent *)mouseEventWithType:(NSEventType)type	
						location:(NSPoint)location
						modifierFlags:(unsigned int)flags
						timestamp:(NSTimeInterval)time
						windowNumber:(int)windowNum 
						context:(NSDPSContext *)context 
						eventNumber:(int)eventNum	
						clickCount:(int)clickNum	
						pressure:(float)pressureValue
{
NSEvent *e = [[[NSEvent alloc] init] autorelease];			// do nothing if
															// event is not of
	if ((type != NSMouseMoved) && (type != NSLeftMouseUp)	// a desired type
			&& (type != NSLeftMouseDown) && (type != NSRightMouseDown) 
			&& (type != NSRightMouseUp) && (type != NSLeftMouseDragged) 
			&& (type != NSRightMouseDragged))
		return nil;

	e->event_type = type;									// Set the event's
	e->location_point = location;							// fields
	e->modifier_flags = flags;
	e->event_time = time;
	e->window_num = windowNum;
	e->event_context = context;
	e->event_data.mouse.event_num = eventNum;
	e->event_data.mouse.click = clickNum;
	e->event_data.mouse.pressure = pressureValue;

	return e;
}

+ (NSEvent *)otherEventWithType:(NSEventType)type	
						location:(NSPoint)location
						modifierFlags:(unsigned int)flags
						timestamp:(NSTimeInterval)time
						windowNumber:(int)windowNum 
						context:(NSDPSContext *)context 
						subtype:(short)subType	
						data1:(int)data1	
						data2:(int)data2
{
NSEvent *e = [[[NSEvent alloc] init] autorelease];
															// do nothing if
	if ((type != NSFlagsChanged) && (type != NSPeriodic))	// event is not of
		return nil;											// a desired type
	
	e->event_type = type;									// Set the event's
	e->location_point = location;							// fields
	e->modifier_flags = flags;
	e->event_time = time;
	e->window_num = windowNum;
	e->event_context = context;
	e->event_data.misc.sub_type = subType;
	e->event_data.misc.data1 = data1;
	e->event_data.misc.data2 = data2;

	return e;
}

//
// Requesting Periodic Events
//
+ (void)startPeriodicEventsAfterDelay:(NSTimeInterval)delaySeconds
						   withPeriod:(NSTimeInterval)periodSeconds
{
NSTimer* timer;
NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];

	NSDebugLog (@"startPeriodicEventsAfterDelay:withPeriod:");
														// Check this thread 
	if ([dict objectForKey: timerKey])					// for a pending timer
		[NSException raise:NSInternalInconsistencyException
					 format:@"Periodic events are already being generated for "
					 @"this thread %x", [NSThread currentThread]];
										// If the delay time is 0 then register	 
										// a timer immediately. Otherwise  
										// register a timer with no repeat that	 
	if (!delaySeconds)					// when fired registers the real timer
		timer = [NSTimer timerWithTimeInterval:periodSeconds	// register an
						 target:self							// immediate
						 selector:@selector(_timerFired:)		// timer
						 userInfo:nil
						 repeats:YES];
	else													// register a one
		timer = [NSTimer timerWithTimeInterval:delaySeconds // shot timer to 
						 target:self						// register a timer 
						 selector:@selector(_registerRealTimer:)
						 userInfo:[NSNumber numberWithDouble:periodSeconds]
						 repeats:NO];

	[[NSRunLoop currentRunLoop] addTimer: timer 
								forMode: NSEventTrackingRunLoopMode];
	[dict setObject: timer forKey: timerKey];
}

+ (void)_timerFired:(NSTimer*)timer
{
NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceReferenceDate];
NSApplication *theApp = [NSApplication sharedApplication];
NSEvent* periodicEvent = [self otherEventWithType:NSPeriodic
								location:NSZeroPoint
								modifierFlags:0
								timestamp:timeInterval
								windowNumber:0
								context:[theApp context]
								subtype:0
								data1:0
								data2:0];

	NSDebugLog (@"_timerFired:");
	[theApp postEvent:periodicEvent atStart:NO];		// place a periodic
}														// event in the queue 

+ (void)_registerRealTimer:(NSTimer*)timer			// this method provides a
{													// means of delaying the
NSTimer* realTimer;								  	// start of periodic events
NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];

	NSDebugLog (@"_registerRealTimer:");		  

	realTimer = [NSTimer timerWithTimeInterval:[[timer userInfo] doubleValue]
						 target:self
						 selector:@selector(_timerFired:)
						 userInfo:nil
						 repeats:YES];		// Add the real timer to the timers
											// dictionary and to the run loop
	[dict setObject: realTimer forKey: timerKey];		
	[[NSRunLoop currentRunLoop] addTimer: realTimer	   
				   				forMode: NSEventTrackingRunLoopMode];
}

+ (void)stopPeriodicEvents
{
NSTimer* timer;
NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];

	NSDebugLog (@"stopPeriodicEvents");
													// Remove any existing 
	timer = [dict objectForKey: timerKey];			// timer for this thread
	[timer invalidate];
	[dict removeObjectForKey: timerKey];
}

//
// Instance methods
//
- (void)dealloc
{
	if ((event_type == NSKeyUp) || (event_type == NSKeyDown))
		{
		[event_data.key.char_keys release];
		[event_data.key.unmodified_keys release];
		}

	[super dealloc];
}

//
// Getting General Event Information
//
- (NSDPSContext *)context
{
	return event_context;
}

- (NSPoint)locationInWindow
{
	return location_point;
}

- (unsigned int)modifierFlags
{
	return modifier_flags;
}

- (NSTimeInterval)timestamp
{
	return event_time;
}

- (NSEventType)type
{
	return event_type;
}

- (NSWindow *)window
{
	return [NSWindow windowWithNumber:window_num];
}

- (int)windowNumber
{
	return window_num;
}

//
// Getting Key Event Information
//
- (NSString *)characters
{
	if ((event_type != NSKeyUp) && (event_type != NSKeyDown))
		return nil;

	return event_data.key.char_keys;
}

- (NSString *)charactersIgnoringModifiers
{
	if ((event_type != NSKeyUp) && (event_type != NSKeyDown))
		return nil;

	return event_data.key.unmodified_keys;
}

- (BOOL)isARepeat
{
	if ((event_type != NSKeyUp) && (event_type != NSKeyDown))
		return NO;

	return event_data.key.repeat;
}

- (unsigned short)keyCode
{
	if ((event_type != NSKeyUp) && (event_type != NSKeyDown))
		return 0;

	return event_data.key.key_code;
}

//
// Getting Mouse Event Information
//
- (int)clickCount
{
  // Make sure it is one of the right event types
  if ((event_type != NSLeftMouseDown) && (event_type != NSLeftMouseUp) &&
	  (event_type != NSRightMouseDown) && (event_type != NSRightMouseUp) &&
	  (event_type != NSLeftMouseDragged) && (event_type != NSRightMouseDragged) &&
	  (event_type != NSMouseMoved))
	return 0;

  return event_data.mouse.click;
}

- (int)eventNumber
{
  // Make sure it is one of the right event types
  if ((event_type != NSLeftMouseDown) && (event_type != NSLeftMouseUp) &&
	  (event_type != NSRightMouseDown) && (event_type != NSRightMouseUp) &&
	  (event_type != NSLeftMouseDragged) && (event_type != NSRightMouseDragged) &&
	  (event_type != NSMouseMoved) &&
	  (event_type != NSMouseEntered) && (event_type != NSMouseExited))
	return 0;

  if ((event_type == NSMouseEntered) || (event_type == NSMouseExited))
	return event_data.tracking.event_num;
  else
	return event_data.mouse.event_num;
}

- (float)pressure
{
  // Make sure it is one of the right event types
  if ((event_type != NSLeftMouseDown) && (event_type != NSLeftMouseUp) &&
	  (event_type != NSRightMouseDown) && (event_type != NSRightMouseUp) &&
	  (event_type != NSLeftMouseDragged) && (event_type != NSRightMouseDragged) &&
	  (event_type != NSMouseMoved))
	return 0;

  return event_data.mouse.pressure;
}

//
// Getting Tracking Event Information
//
- (int)trackingNumber
{
  if ((event_type != NSMouseEntered) && (event_type != NSMouseExited)
	   && (event_type != NSCursorUpdate))
	return 0;

  return event_data.tracking.tracking_num;
}

- (void *)userData
{
  if ((event_type != NSMouseEntered) && (event_type != NSMouseExited)
	  && (event_type != NSCursorUpdate))
	return NULL;

  return event_data.tracking.user_data;
}

//
// Getting Information about Specially Defined Events
//
- (int)data1
{
  // Make sure it is one of the right event types
  if ((event_type != NSFlagsChanged) && (event_type != NSPeriodic))
	return 0;

  return event_data.misc.data1;
}

- (int)data2
{
  // Make sure it is one of the right event types
  if ((event_type != NSFlagsChanged) && (event_type != NSPeriodic))
	return 0;

  return event_data.misc.data2;
}

- (short)subtype
{
  // Make sure it is one of the right event types
  if ((event_type != NSFlagsChanged) && (event_type != NSPeriodic))
	return 0;

  return event_data.misc.sub_type;;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [aCoder encodeValueOfObjCType: @encode(NSEventType) at: &event_type];
  [aCoder encodePoint: location_point];
  [aCoder encodeValueOfObjCType: "I" at: &modifier_flags];
  [aCoder encodeValueOfObjCType: @encode(NSTimeInterval) at: &event_time];
  [aCoder encodeValueOfObjCType: "i" at: &window_num];
  // We don't want to encode the context, right?
  // DPSContext doesn't conform to NSCoding
  //[aCoder encodeObjectReference: event_context withName: @"Context"];

  // Encode the event date based upon the event type
  switch (event_type)
	{
	case NSLeftMouseDown:
	case NSLeftMouseUp:
	case NSRightMouseDown:
	case NSRightMouseUp:
	case NSMouseMoved:
	case NSLeftMouseDragged:
	case NSRightMouseDragged:
	  [aCoder encodeValuesOfObjCTypes: "iif", &event_data.mouse.event_num,
		  &event_data.mouse.click, &event_data.mouse.pressure];
	  break;

	case NSMouseEntered:
	case NSMouseExited:
	case NSCursorUpdate:
	  // Can't do anything with the user_data!?
	  [aCoder encodeValuesOfObjCTypes: "ii", &event_data.tracking.event_num,
		  &event_data.tracking.tracking_num];
	  break;

	case NSKeyDown:
	case NSKeyUp:
	  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &event_data.key.repeat];
	  [aCoder encodeObject: event_data.key.char_keys];
	  [aCoder encodeObject: event_data.key.unmodified_keys];
	  [aCoder encodeValueOfObjCType: "S" at: &event_data.key.key_code];
	  break;

	case NSFlagsChanged:
	case NSPeriodic:
	  [aCoder encodeValuesOfObjCTypes: "sii", &event_data.misc.sub_type,
		  &event_data.misc.data1, &event_data.misc.data2];
	  break;
	}
}

- initWithCoder:aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(NSEventType) at: &event_type];
  location_point = [aDecoder decodePoint];
  [aDecoder decodeValueOfObjCType: "I" at: &modifier_flags];
  [aDecoder decodeValueOfObjCType: @encode(NSTimeInterval) at: &event_time];
  [aDecoder decodeValueOfObjCType: "i" at: &window_num];

  // Decode the event date based upon the event type
  switch (event_type)
	{
	case NSLeftMouseDown:
	case NSLeftMouseUp:
	case NSRightMouseDown:
	case NSRightMouseUp:
	case NSMouseMoved:
	case NSLeftMouseDragged:
	case NSRightMouseDragged:
	  [aDecoder decodeValuesOfObjCTypes: "iif", &event_data.mouse.event_num,
		&event_data.mouse.click, &event_data.mouse.pressure];
	  break;

	case NSMouseEntered:
	case NSMouseExited:
	case NSCursorUpdate:
	  // Can't do anything with the user_data!?
	  [aDecoder decodeValuesOfObjCTypes: "ii", &event_data.tracking.event_num,
		&event_data.tracking.tracking_num];
	  break;

	case NSKeyDown:
	case NSKeyUp:
	  [aDecoder decodeValueOfObjCType: @encode(BOOL) 
		at: &event_data.key.repeat];
	  event_data.key.char_keys = [aDecoder decodeObject];
	  event_data.key.unmodified_keys = [aDecoder decodeObject];
	  [aDecoder decodeValueOfObjCType: "S" at: &event_data.key.key_code];
	  break;

	case NSFlagsChanged:
	case NSPeriodic:
	  [aDecoder decodeValuesOfObjCTypes: "sii", &event_data.misc.sub_type,
		  &event_data.misc.data1, &event_data.misc.data2];
	  break;
	}

  return self;
}

- (NSString*)description
{
  const char* eventTypes[] = { "leftMouseDown", "leftMouseUp",
	  "rightMouseDown", "rightMouseUp", "mouseMoved", "leftMouseDragged",
	  "rightMouseDragged", "mouseEntered", "mouseExited", "keyDown", "keyUp",
	  "flagsChanged", "periodic", "cursorUpdate"
  };

  switch (event_type) {
	case NSLeftMouseDown:
	case NSLeftMouseUp:
	case NSRightMouseDown:
	case NSRightMouseUp:
	case NSMouseMoved:
	case NSLeftMouseDragged:
	case NSRightMouseDragged:
	  return [NSString stringWithFormat:
		@"NSEvent: eventType = %s, point = { %f, %f }, modifiers = %u,"
		@" time = %f, window = %d, dpsContext = %p,"
		@" event number = %d, click = %d, pressure = %f",
		eventTypes[event_type], location_point.x, location_point.y,
		modifier_flags, event_time, window_num, event_context,
		event_data.mouse.event_num, event_data.mouse.click,
		event_data.mouse.pressure];
	  break;

	case NSMouseEntered:
	case NSMouseExited:
	  return [NSString stringWithFormat:
		@"NSEvent: eventType = %s, point = { %f, %f }, modifiers = %u,"
		@" time = %f, window = %d, dpsContext = %p, "
		@" event number = %d, tracking number = %d, user data = %p",
		eventTypes[event_type], location_point.x, location_point.y,
		modifier_flags, event_time, window_num, event_context,
		event_data.tracking.event_num,
		event_data.tracking.tracking_num,
		event_data.tracking.user_data];
	  break;

	case NSKeyDown:
	case NSKeyUp:
	  return [NSString stringWithFormat:
		@"NSEvent: eventType = %s, point = { %f, %f }, modifiers = %u,"
		@" time = %f, window = %d, dpsContext = %p, "
		@" repeat = %s, keys = %@, ukeys = %@, keyCode = 0x%x",
		eventTypes[event_type], location_point.x, location_point.y,
		modifier_flags, event_time, window_num, event_context,
		(event_data.key.repeat ? "YES" : "NO"),
		event_data.key.char_keys, event_data.key.unmodified_keys,
		event_data.key.key_code];
	  break;

	case NSFlagsChanged:
	case NSPeriodic:
	case NSCursorUpdate:
	  return [NSString stringWithFormat:
		@"NSEvent: eventType = %s, point = { %f, %f }, modifiers = %u,"
		@" time = %f, window = %d, dpsContext = %p, "
		@" subtype = %d, data1 = %p, data2 = %p",
		eventTypes[event_type], location_point.x, location_point.y,
		modifier_flags, event_time, window_num, event_context,
		event_data.misc.sub_type, event_data.misc.data1,
		event_data.misc.data2];
	  break;
  }

  return [super description];
}

@end
