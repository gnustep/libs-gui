/* 
   NSEvent.m

   The event class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Author:  Ovidiu Predescu <ovidiu@net-community.com>
   Date: 1996
   
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

@implementation NSEvent

// Class variables
static NSMutableDictionary* timers = nil;
static NSRecursiveLock* timersLock = nil;

//
// Private methods
//
- (void)setType:(NSEventType)type
{
  event_type = type;
}

- (void)setLocation:(NSPoint)location
{
  location_point = location;
}

- (void)setFlags:(unsigned int)flags
{
  modifier_flags = flags;
}

- (void)setTime:(NSTimeInterval)time
{
  event_time = time;
}

- (void)setWindowNum:(int)windowNum
{
  window_num = windowNum;
}

- (void)setContext:(NSDPSContext *)context
{
  event_context = context;
}

- (void)setMouseEventNumber:(int)eventNum
{
  event_data.mouse.event_num = eventNum;
}

- (void)setMouseClick:(int)clickNum
{
  event_data.mouse.click = clickNum;
}

- (void)setPressure:(float)pressureValue
{
  event_data.mouse.pressure = pressureValue;
}

- (void)setTrackingEventNumber:(int)eventNum
{
  event_data.tracking.event_num = eventNum;
}

- (void)setTrackingNumber:(int)trackingNum
{
  event_data.tracking.tracking_num = trackingNum;
}

- (void)setUserData:(void *)userData
{
  event_data.tracking.user_data = userData;
}

- (void)setRepeat:(BOOL)repeat
{
  event_data.key.repeat = repeat;
}

- (void)setCharacters:(NSString *)keys
{
  event_data.key.char_keys = keys;
  [event_data.key.char_keys retain];
}

- (void)setUnmodifiedCharacters:(NSString *)ukeys
{
  event_data.key.unmodified_keys = ukeys;
  [event_data.key.unmodified_keys retain];
}

- (void)setKeyCode:(unsigned short)code
{
  event_data.key.key_code = code;
}

- (void)setSubType:(short)subType
{
  event_data.misc.sub_type = subType;
}

- (void)setData1:(int)data1
{
  event_data.misc.data1 = data1;
}

- (void)setData2:(int)data2
{
  event_data.misc.data2 = data2;
}

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSEvent class])
    {
      NSDebugLog(@"Initialize NSEvent class\n");

      // Initial version
      [self setVersion:1];
      timers = [NSMutableDictionary new];
      timersLock = [NSRecursiveLock new];
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
  NSEvent *e;

  e = [[[NSEvent alloc] init] autorelease];

  // Make sure it is one of the right event types
  if ((type != NSMouseEntered) && (type != NSMouseExited)
       && (type != NSCursorUpdate))
    return nil;

  // Set the event fields
  [e setType:type];
  [e setLocation:location];
  [e setFlags:flags];
  [e setTime:time];
  [e setWindowNum:windowNum];
  [e setContext:context];
  [e setTrackingEventNumber:eventNum];
  [e setTrackingNumber:trackingNum];
  [e setUserData:userData];

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
  NSEvent *e;

  e = [[[NSEvent alloc] init] autorelease];

  // Make sure it is one of the right event types
  if ((type != NSKeyDown) && (type != NSKeyUp))
    return nil;

  // Set the event fields
  [e setType:type];
  [e setLocation:location];
  [e setFlags:flags];
  [e setTime:time];
  [e setWindowNum:windowNum];
  [e setContext:context];
  [e setCharacters:keys];
  [e setUnmodifiedCharacters:ukeys];
  [e setRepeat:repeatKey];
  [e setKeyCode:code];

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
  NSEvent *e;

  e = [[[NSEvent alloc] init] autorelease];

  // Make sure it is one of the right event types
  if ((type != NSLeftMouseDown) && (type != NSLeftMouseUp) &&
      (type != NSRightMouseDown) && (type != NSRightMouseUp) &&
      (type != NSLeftMouseDragged) && (type != NSRightMouseDragged) &&
      (type != NSMouseMoved))
    return nil;

  // Set the event fields
  [e setType:type];
  [e setLocation:location];
  [e setFlags:flags];
  [e setTime:time];
  [e setWindowNum:windowNum];
  [e setContext:context];
  [e setMouseEventNumber:eventNum];
  [e setMouseClick:clickNum];
  [e setPressure:pressureValue];

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
  NSEvent *e;

  e = [[[NSEvent alloc] init] autorelease];

  // Make sure it is one of the right event types
  if ((type != NSFlagsChanged) && (type != NSPeriodic))
    return nil;

  // Set the event fields
  [e setType:type];
  [e setLocation:location];
  [e setFlags:flags];
  [e setTime:time];
  [e setWindowNum:windowNum];
  [e setContext:context];
  [e setSubType:subType];
  [e setData1:data1];
  [e setData2:data2];

  return e;
}

//
// Requesting Periodic Events
//
+ (void)startPeriodicEventsAfterDelay:(NSTimeInterval)delaySeconds
			   withPeriod:(NSTimeInterval)periodSeconds
{
  NSTimer* timer;
  NSThread* currentThread = [NSThread currentThread];

  [timersLock lock];

  NSDebugLog (@"startPeriodicEventsAfterDelay:withPeriod:");
  /* Check for any pending timer for this thread */
  if ([timers objectForKey:currentThread])
    [NSException raise:NSInternalInconsistencyException
		 format:@"Periodic events are already being generated for "
			@"this thread %x", currentThread];

  /* If the delay time is 0 then register a timer right now. Otherwise register
     a timer with no repeat that when fired registers the real timer */
  if (!delaySeconds)
    timer = [NSTimer timerWithTimeInterval:periodSeconds
		      target:self
		      selector:@selector(_timerFired:)
		      userInfo:nil
		      repeats:YES];
  else
    timer = [NSTimer timerWithTimeInterval:delaySeconds
		      target:self
		      selector:@selector(_registerRealTimer:)
		      userInfo:[NSNumber numberWithDouble:periodSeconds]
		      repeats:NO];

  [[NSRunLoop currentRunLoop]
      addTimer:timer forMode:NSEventTrackingRunLoopMode];
  [timers setObject:timer forKey:currentThread];

  [timersLock unlock];
}

+ (void)_timerFired:(NSTimer*)timer
{
  NSEvent* periodicEvent
      = [self otherEventWithType:NSPeriodic
	      location:NSZeroPoint
	      modifierFlags:0
	      timestamp:[[NSDate date] timeIntervalSinceReferenceDate]
	      windowNumber:0
	      context:[[NSApplication sharedApplication] context]
	      subtype:0
	      data1:0
	      data2:0];

  NSDebugLog (@"_timerFired:");
  [[NSApplication sharedApplication] postEvent:periodicEvent atStart:NO];
}

+ (void)_registerRealTimer:(NSTimer*)timer
{
  NSTimeInterval periodSeconds = [[timer userInfo] doubleValue];
  NSTimer* realTimer = [NSTimer timerWithTimeInterval:periodSeconds
				target:self
				selector:@selector(_timerFired:)
				userInfo:nil
				repeats:YES];
  NSThread* currentThread = [NSThread currentThread];

  NSDebugLog (@"_registerRealTimer:");
  [timersLock lock];

  /* Add the real timer into the timers dictionary and to the run loop */
  [timers setObject:realTimer forKey:currentThread];
  [[NSRunLoop currentRunLoop]
      addTimer:realTimer forMode:NSEventTrackingRunLoopMode];

  [timersLock unlock];
}

+ (void)stopPeriodicEvents
{
  NSTimer* timer;
  NSThread* currentThread;

  NSDebugLog (@"stopPeriodicEvents");
  [timersLock lock];

  currentThread = [NSThread currentThread];
  /* Remove any existing timer for this thread */
  timer = [timers objectForKey:currentThread];
  [timer invalidate];
  [timers removeObjectForKey:currentThread];

  [timersLock unlock];
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
