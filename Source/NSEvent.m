/*
   NSEvent.m

   The event class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: 	Scott Christley <scottc@net-community.com>
   Author: 	Ovidiu Predescu <ovidiu@net-community.com>
   Date: 1996
   Author: 	Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Sept 1998
   Updated: 	Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: June 1999

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
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSGraphics.h>

/*
 *	gstep-base has a faster mechanism to get the current thread.
 */
#ifndef GNUSTEP_BASE_LIBRARY
#define	GSCurrentThread()		[NSThread currentThread]
#define	GSCurrentThreadDictionary()	[[NSThread currentThread] threadDictionary]
#endif

@implementation NSEvent

/*
 * Class variables
 */
static NSString	*timerKey = @"NSEventTimersKey";
static Class eventClass;

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSEvent class])
    {
      NSDebugLog(@"Initialize NSEvent class\n");
      [self setVersion: 1];
      eventClass = [NSEvent class];
    }
}

/*
 * Creating NSEvent objects
 */
+ (NSEvent*) enterExitEventWithType: (NSEventType)type
			   location: (NSPoint)location
		      modifierFlags: (unsigned int)flags
			  timestamp: (NSTimeInterval)time
		       windowNumber: (int)windowNum
			    context: (NSGraphicsContext*)context
		        eventNumber: (int)eventNum
		     trackingNumber: (int)trackingNum
			   userData: (void *)userData
{
  NSEvent	*e;

  if (type == NSCursorUpdate)
    RETAIN((id)userData);
  else if ((type != NSMouseEntered) && (type != NSMouseExited))
    [NSException raise: NSInvalidArgumentException
		format: @"enterExitEvent with wrong type"];

  e = (NSEvent*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  if (self != eventClass)
    e = [e init];
  AUTORELEASE(e);

  e->event_type = type;

  e->location_point = location;
  e->modifier_flags = flags;
  e->event_time = time;
  e->window_num = windowNum;
  e->event_context = context;
  e->event_data.tracking.event_num = eventNum;
  e->event_data.tracking.tracking_num = trackingNum;
  e->event_data.tracking.user_data = userData;

  return e;
}

+ (NSEvent*) keyEventWithType: (NSEventType)type
		     location: (NSPoint)location
		modifierFlags: (unsigned int)flags
		    timestamp: (NSTimeInterval)time
		 windowNumber: (int)windowNum
		      context: (NSGraphicsContext *)context
		   characters: (NSString *)keys
  charactersIgnoringModifiers: (NSString *)ukeys
		    isARepeat: (BOOL)repeatKey
		      keyCode: (unsigned short)code
{
  NSEvent	*e;

  if (type < NSKeyDown || type > NSFlagsChanged)
    [NSException raise: NSInvalidArgumentException
		format: @"keyEvent with wrong type"];

  e = (NSEvent*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  if (self != eventClass)
    e = [e init];
  AUTORELEASE(e);

  e->event_type = type;
  e->location_point = location;
  e->modifier_flags = flags;
  e->event_time = time;
  e->window_num = windowNum;
  e->event_context = context;
  RETAIN(keys);
  e->event_data.key.char_keys = keys;
  RETAIN(ukeys);
  e->event_data.key.unmodified_keys = ukeys;
  e->event_data.key.repeat = repeatKey;
  e->event_data.key.key_code = code;

  return e;
}

+ (NSEvent*) mouseEventWithType: (NSEventType)type
		       location: (NSPoint)location
		  modifierFlags: (unsigned int)flags
		      timestamp: (NSTimeInterval)time
		   windowNumber: (int)windowNum
			context: (NSGraphicsContext*)context
		    eventNumber: (int)eventNum
		     clickCount: (int)clickNum
		       pressure: (float)pressureValue
{
  NSEvent	*e;

  if (type < NSLeftMouseDown || type > NSRightMouseDragged)
    [NSException raise: NSInvalidArgumentException
		format: @"mouseEvent with wrong type"];

  e = (NSEvent*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  if (self != eventClass)
    e = [e init];
  AUTORELEASE(e);

  e->event_type = type;
  e->location_point = location;
  e->modifier_flags = flags;
  e->event_time = time;
  e->window_num = windowNum;
  e->event_context = context;
  e->event_data.mouse.event_num = eventNum;
  e->event_data.mouse.click = clickNum;
  e->event_data.mouse.pressure = pressureValue;

  return e;
}

+ (NSEvent*) otherEventWithType: (NSEventType)type
		       location: (NSPoint)location
		  modifierFlags: (unsigned int)flags
		      timestamp: (NSTimeInterval)time
		   windowNumber: (int)windowNum
			context: (NSGraphicsContext*)context
			subtype: (short)subType
			  data1: (int)data1
			  data2: (int)data2
{
  NSEvent	*e;

  if (type < NSAppKitDefined || type > NSPeriodic)
    [NSException raise: NSInvalidArgumentException
		format: @"otherEvent with wrong type"];

  e = (NSEvent*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  if (self != eventClass)
    e = [e init];
  AUTORELEASE(e);

  e->event_type = type;
  e->location_point = location;
  e->modifier_flags = flags;
  e->event_time = time;
  e->window_num = windowNum;
  e->event_context = context;
  e->event_data.misc.sub_type = subType;
  e->event_data.misc.data1 = data1;
  e->event_data.misc.data2 = data2;

  return e;
}

/*
 * Requesting Periodic Events
 */
+ (void) startPeriodicEventsAfterDelay: (NSTimeInterval)delaySeconds
			    withPeriod: (NSTimeInterval)periodSeconds
{
  NSTimer		*timer;
  NSMutableDictionary	*dict = GSCurrentThreadDictionary();

  NSDebugLog (@"startPeriodicEventsAfterDelay: withPeriod: ");

  if ([dict objectForKey: timerKey])
    [NSException raise: NSInternalInconsistencyException
		format: @"Periodic events are already being generated for "
		        @"this thread %x", GSCurrentThread()];

  /*
   * If the delay time is 0 then register a timer immediately. Otherwise
   * register a timer with no repeat that when fired registers the real timer
   */
  if (!delaySeconds)
    timer = [NSTimer timerWithTimeInterval: periodSeconds
				    target: self
				  selector: @selector(_timerFired:)
				  userInfo: nil
				   repeats: YES];
  else
    timer = [NSTimer timerWithTimeInterval: delaySeconds
				    target: self
				  selector: @selector(_registerRealTimer:)
				  userInfo: [NSNumber numberWithDouble: periodSeconds]
				   repeats: NO];

  [[NSRunLoop currentRunLoop] addTimer: timer
			       forMode: NSEventTrackingRunLoopMode];
  [dict setObject: timer forKey: timerKey];
}

+ (void) _timerFired: (NSTimer*)timer
{
  NSTimeInterval	timeInterval;
  NSEvent		*periodicEvent;

  timeInterval = [[NSDate date] timeIntervalSinceReferenceDate];
  periodicEvent = [self otherEventWithType: NSPeriodic
				  location: NSZeroPoint
			     modifierFlags: 0
				 timestamp: timeInterval
			      windowNumber: 0
				   context: [NSApp context]
				   subtype: 0
				     data1: 0
				     data2: 0];

  NSDebugLog (@"_timerFired: ");
  [NSApp postEvent: periodicEvent atStart: NO];
}

/*
 * This method provides a means of delaying the start of periodic events
 */
+ (void) _registerRealTimer: (NSTimer*)timer
{
  NSTimer		*realTimer;
  NSMutableDictionary	*dict = GSCurrentThreadDictionary();

  NSDebugLog (@"_registerRealTimer: ");

  realTimer = [NSTimer timerWithTimeInterval: [[timer userInfo] doubleValue]
				      target: self
				    selector: @selector(_timerFired:)
				    userInfo: nil
				     repeats: YES];
  [dict setObject: realTimer forKey: timerKey];
  [[NSRunLoop currentRunLoop] addTimer: realTimer
			       forMode: NSEventTrackingRunLoopMode];
}

+ (void) stopPeriodicEvents
{
  NSTimer		*timer;
  NSMutableDictionary	*dict = GSCurrentThreadDictionary();

  NSDebugLog (@"stopPeriodicEvents");
  timer = [dict objectForKey: timerKey];
  [timer invalidate];
  [dict removeObjectForKey: timerKey];
}

/*
 * Instance methods
 */
- (void) dealloc
{
  if ((event_type == NSKeyUp) || (event_type == NSKeyDown))
    {
      RELEASE(event_data.key.char_keys);
      RELEASE(event_data.key.unmodified_keys);
    }
  else if (event_type == NSCursorUpdate)
    RELEASE((id)event_data.tracking.user_data);

  NSDeallocateObject(self);
}

/*
 * Getting General Event Information
 */
- (NSGraphicsContext*) context
{
  return event_context;
}

- (NSPoint) locationInWindow
{
  return location_point;
}

- (unsigned int) modifierFlags
{
  return modifier_flags;
}

- (NSTimeInterval) timestamp
{
  return event_time;
}

- (NSEventType) type
{
  return event_type;
}

- (NSWindow *) window
{
  return GSWindowWithNumber(window_num);
}

- (int) windowNumber
{
  return window_num;
}

/*
 * Getting Key Event Information
 */
- (NSString *) characters
{
  if ((event_type != NSKeyUp) && (event_type != NSKeyDown))
    [NSException raise: NSInvalidArgumentException
		format: @"characters requested for non-keyboard event"];

  return event_data.key.char_keys;
}

- (NSString *) charactersIgnoringModifiers
{
  if ((event_type != NSKeyUp) && (event_type != NSKeyDown))
    [NSException raise: NSInvalidArgumentException
		format: @"charactersIgnoringModifiers requested for "
			@"non-keyboard event"];

  return event_data.key.unmodified_keys;
}

- (BOOL) isARepeat
{
  if ((event_type != NSKeyUp) && (event_type != NSKeyDown))
    [NSException raise: NSInvalidArgumentException
		format: @"isARepeat requested for non-keyboard event"];

  return event_data.key.repeat;
}

- (unsigned short) keyCode
{
  if ((event_type != NSKeyUp) && (event_type != NSKeyDown)
    && (event_type != NSFlagsChanged))
    [NSException raise: NSInvalidArgumentException
		format: @"keyCode requested for non-keyboard event"];

  return event_data.key.key_code;
}

/*
 * Getting Mouse Event Information
 */
- (int) clickCount
{
  /* Make sure it is one of the right event types */
  if (event_type < NSLeftMouseDown || event_type > NSRightMouseDragged)
    [NSException raise: NSInvalidArgumentException
		format: @"clickCount requested for non-mouse event"];

  return event_data.mouse.click;
}

- (int) eventNumber
{
  /* Make sure it is one of the right event types */
  if (event_type < NSLeftMouseDown || event_type > NSMouseExited)
    [NSException raise: NSInvalidArgumentException
		format: @"eventNumber requested for non-mouse event"];

  if ((event_type == NSMouseEntered) || (event_type == NSMouseExited))
    return event_data.tracking.event_num;
  else
    return event_data.mouse.event_num;
}

- (float) pressure
{
  /* Make sure it is one of the right event types */
  if (event_type < NSLeftMouseDown || event_type > NSRightMouseDragged)
    [NSException raise: NSInvalidArgumentException
		format: @"pressure requested for non-mouse event"];

  return event_data.mouse.pressure;
}

/*
 * Getting Tracking Event Information
 */
- (int) trackingNumber
{
  if (event_type != NSMouseEntered && event_type != NSMouseExited
    &&  event_type != NSCursorUpdate)
    [NSException raise: NSInvalidArgumentException
		format: @"trackingNumber requested for non-tracking event"];

  return event_data.tracking.tracking_num;
}

- (void *) userData
{
  if (event_type != NSMouseEntered && event_type != NSMouseExited
    &&  event_type != NSCursorUpdate)
    [NSException raise: NSInvalidArgumentException
                format: @"userData requested for non-tracking event"];

  return event_data.tracking.user_data;
}

/*
 * Getting Information about Specially Defined Events
 */
- (int) data1
{
  if (event_type < NSAppKitDefined || event_type > NSPeriodic)
    [NSException raise: NSInvalidArgumentException
		format: @"data1 requested for invalid event type"];

  return event_data.misc.data1;
}

- (int) data2
{
  if (event_type < NSAppKitDefined || event_type > NSPeriodic)
    [NSException raise: NSInvalidArgumentException
		format: @"data2 requested for invalid event type"];

  return event_data.misc.data2;
}

- (short) subtype
{
  if (event_type < NSAppKitDefined || event_type > NSPeriodic)
    [NSException raise: NSInvalidArgumentException
		format: @"subtype requested for invalid event type"];

  return event_data.misc.sub_type;;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(NSEventType) at: &event_type];
  [aCoder encodePoint: location_point];
  [aCoder encodeValueOfObjCType: @encode(unsigned) at: &modifier_flags];
  [aCoder encodeValueOfObjCType: @encode(NSTimeInterval) at: &event_time];
  [aCoder encodeValueOfObjCType: @encode(unsigned) at: &window_num];

  switch (event_type)
    {
      case NSLeftMouseDown:
      case NSLeftMouseUp:
      case NSMiddleMouseDown:
      case NSMiddleMouseUp:
      case NSRightMouseDown:
      case NSRightMouseUp:
      case NSMouseMoved:
      case NSLeftMouseDragged:
      case NSMiddleMouseDragged:
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
	[aCoder encodeValueOfObjCType: @encode(BOOL)
				   at: &event_data.key.repeat];
	[aCoder encodeObject: event_data.key.char_keys];
	[aCoder encodeObject: event_data.key.unmodified_keys];
	[aCoder encodeValueOfObjCType: "S" at: &event_data.key.key_code];
	break;

      case NSFlagsChanged:
      case NSPeriodic:
      case NSAppKitDefined:
      case NSSystemDefined:
      case NSApplicationDefined:
	[aCoder encodeValuesOfObjCTypes: "sii", &event_data.misc.sub_type,
		&event_data.misc.data1, &event_data.misc.data2];
	break;
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(NSEventType) at: &event_type];
  location_point = [aDecoder decodePoint];
  [aDecoder decodeValueOfObjCType: @encode(unsigned) at: &modifier_flags];
  [aDecoder decodeValueOfObjCType: @encode(NSTimeInterval) at: &event_time];
  [aDecoder decodeValueOfObjCType: @encode(unsigned) at: &window_num];

  // Decode the event date based upon the event type
  switch (event_type)
    {
      case NSLeftMouseDown:
      case NSLeftMouseUp:
      case NSMiddleMouseDown:
      case NSMiddleMouseUp:
      case NSRightMouseDown:
      case NSRightMouseUp:
      case NSMouseMoved:
      case NSLeftMouseDragged:
      case NSMiddleMouseDragged:
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
      case NSAppKitDefined:
      case NSSystemDefined:
      case NSApplicationDefined:
	[aDecoder decodeValuesOfObjCTypes: "sii", &event_data.misc.sub_type,
		&event_data.misc.data1, &event_data.misc.data2];
	break;
    }

  return self;
}

- (NSString*) description
{
  const char* eventTypes[] = {
    "leftMouseDown",
    "leftMouseUp",
    "middleMouseDown",
    "middleMouseUp",
    "rightMouseDown",
    "rightMouseUp",
    "mouseMoved",
    "leftMouseDragged",
    "middleMouseDragged",
    "rightMouseDragged",
    "mouseEntered",
    "mouseExited",
    "keyDown",
    "keyUp",
    "flagsChanged",
    "appKitDefined",
    "systemDefined",
    "applicationDefined",
    "periodic",
    "cursorUpdate"
  };

  switch (event_type)
    {
      case NSLeftMouseDown:
      case NSLeftMouseUp:
      case NSMiddleMouseDown:
      case NSMiddleMouseUp:
      case NSRightMouseDown:
      case NSRightMouseUp:
      case NSMouseMoved:
      case NSLeftMouseDragged:
      case NSMiddleMouseDragged:
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
      case NSAppKitDefined:
      case NSSystemDefined:
      case NSApplicationDefined:
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
