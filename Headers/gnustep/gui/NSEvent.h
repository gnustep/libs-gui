/* 
   NSEvent.h

   The event class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSEvent
#define _GNUstep_H_NSEvent

#include <AppKit/stdappkit.h>
#include <DPSClient/DPSOperators.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSCoder.h>
#include <DPSClient/NSDPSContext.h>

@class NSWindow;

@interface NSEvent : NSObject <NSCoding>

{
  // Attributes
  NSEventType event_type;
  NSPoint location_point;
  unsigned int modifier_flags;
  NSTimeInterval event_time;
  int window_num;
  NSDPSContext *event_context;
  union _MB_event_data
  {
    struct
      {
	int event_num;
	int click;
	float pressure;
      } mouse;
      struct
	{
	  BOOL repeat;
	  NSString *char_keys;
	  NSString *unmodified_keys;
	  unsigned short key_code;
	} key;
	struct
	  {
	    int event_num;
	    int tracking_num;
	    void *user_data;
	  } tracking;
	  struct
	    {
	      short sub_type;
	      int data1;
	      int data2;
	    } misc;
  } event_data;
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
			   userData:(void *)userData; 

+ (NSEvent *)keyEventWithType:(NSEventType)type
		     location:(NSPoint)location
		modifierFlags:(unsigned int)flags
		    timestamp:(NSTimeInterval)time
		 windowNumber:(int)windowNum
		      context:(NSDPSContext *)context	
		   characters:(NSString *)keys	
  charactersIgnoringModifiers:(NSString *)ukeys
		    isARepeat:(BOOL)repeatKey	
		      keyCode:(unsigned short)code;

+ (NSEvent *)mouseEventWithType:(NSEventType)type	
		       location:(NSPoint)location
		  modifierFlags:(unsigned int)flags
		      timestamp:(NSTimeInterval)time
		   windowNumber:(int)windowNum	
			context:(NSDPSContext *)context	
		    eventNumber:(int)eventNum	
		     clickCount:(int)clickNum	
		       pressure:(float)pressureValue;

+ (NSEvent *)otherEventWithType:(NSEventType)type	
		       location:(NSPoint)location
		  modifierFlags:(unsigned int)flags
		      timestamp:(NSTimeInterval)time
		   windowNumber:(int)windowNum	
			context:(NSDPSContext *)context	
			subtype:(short)subType	
			  data1:(int)data1	
			  data2:(int)data2;

//
// Getting General Event Information
//
- (NSDPSContext *)context;
- (NSPoint)locationInWindow;
- (unsigned int)modifierFlags;
- (NSTimeInterval)timestamp;
- (NSEventType)type;
- (NSWindow *)window;
- (int)windowNumber;

//
// Getting Key Event Information
//
- (NSString *)characters;
- (NSString *)charactersIgnoringModifiers;
- (BOOL)isARepeat;
- (unsigned short)keyCode;

//
// Getting Mouse Event Information
//
- (int)clickCount;
- (int)eventNumber;
- (float)pressure;

//
// Getting Tracking Event Information
//
- (int)trackingNumber;
- (void *)userData;

//
// Requesting Periodic Events
//
+ (void)startPeriodicEventsAfterDelay:(NSTimeInterval)delaySeconds
			   withPeriod:(NSTimeInterval)periodSeconds;
+ (void)stopPeriodicEvents;

//
// Getting Information about Specially Defined Events
//
- (int)data1;
- (int)data2;
- (short)subtype;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSEvent
