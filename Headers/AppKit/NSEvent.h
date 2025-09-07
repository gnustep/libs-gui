/*
   NSEvent.h

   The event class

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996

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

#ifndef _GNUstep_H_NSEvent
#define _GNUstep_H_NSEvent
#import <AppKit/AppKitDefines.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
// For NSTimeInterval
#import <Foundation/NSDate.h>

@class NSString;
@class NSWindow;
@class NSGraphicsContext;

/**
 * <title>NSEventType</title>
 * <abstract>Enumeration of event types recognized within GNUstep GUI</abstract>
 * Each event type has a corresponding mask that can be used when filtering for
 * multiple types. For example, the NSLeftMouseDown type has NSLeftMouseDownMask
 * for its mask. The special mask NSAnyEventMask matches any event.
 *
 * The event types represent different categories of user interaction and system
 * notifications that can be processed by the application. Mouse events handle
 * clicking, dragging, and movement. Keyboard events manage key presses and
 * modifier changes. System events provide notifications about application
 * lifecycle and device changes.
 *
 * Event types are ordered by value, and ranges are used for efficient testing
 * of event categories. The complete list of types includes:
 *
 * Mouse Events:
 * - NSLeftMouseDown, NSLeftMouseUp: Primary mouse button
 * - NSRightMouseDown, NSRightMouseUp: Secondary mouse button
 * - NSOtherMouseDown, NSOtherMouseUp: Additional mouse buttons
 * - NSMouseMoved: Mouse position changes without button pressed
 * - NSLeftMouseDragged, NSRightMouseDragged, NSOtherMouseDragged: Mouse movement with button held
 * - NSMouseEntered, NSMouseExited: Mouse entering/leaving tracking areas
 * - NSScrollWheel: Mouse wheel or trackpad scrolling
 *
 * Keyboard Events:
 * - NSKeyDown, NSKeyUp: Key press and release events
 * - NSFlagsChanged: Modifier key state changes
 *
 * System Events:
 * - NSAppKitDefined: Reserved for AppKit framework use
 * - NSSystemDefined: Reserved for system-level events
 * - NSApplicationDefined: Available for custom application events
 * - NSPeriodic: Timer-based periodic events
 * - NSCursorUpdate: Cursor appearance update requests
 *
 * Tablet Events (10.4+):
 * - NSTabletPoint: Graphics tablet position and pressure
 * - NSTabletProximity: Tablet stylus proximity detection
 *
 * <example>
  NSLeftMouseDown,
  NSLeftMouseUp,
  NSOtherMouseDown,
  NSOtherMouseUp,
  NSRightMouseDown,
  NSRightMouseUp,
  NSMouseMoved,
  NSLeftMouseDragged,
  NSOtherMouseDragged,
  NSRightMouseDragged,
  NSMouseEntered,
  NSMouseExited,
  NSKeyDown,
  NSKeyUp,
  NSFlagsChanged,
  NSAppKitDefined,       // reserved
  NSSystemDefined,       // reserved
  NSApplicationDefined,  // available for custom use by apps
  NSPeriodic,
  NSCursorUpdate,
  NSScrollWheel
 </example>
 */

enum _NSEventType {
  // Note - order IS significant as ranges of values
  // are used for testing for valid event types.
  NSLeftMouseDown = 1,
  NSLeftMouseUp,
  NSRightMouseDown,
  NSRightMouseUp,
  NSMouseMoved,
  NSLeftMouseDragged,
  NSRightMouseDragged,
  NSMouseEntered,
  NSMouseExited,
  NSKeyDown,
  NSKeyUp,
  NSFlagsChanged,
  NSAppKitDefined,
  NSSystemDefined,
  NSApplicationDefined,
  NSPeriodic,
  NSCursorUpdate,
// NSEventTypeCursorUpdate              = 17,
// NSEventTypeRotate                    = 18,
// NSEventTypeBeginGesture              = 19,
// NSEventTypeEndGesture                = 20,
// (not defined)                        = 21,
  NSScrollWheel = 22,
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
  NSTabletPoint,
  NSTabletProximity,
#endif
  NSOtherMouseDown = 25,
  NSOtherMouseUp,
  NSOtherMouseDragged,
#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)
  NSEventTypeLeftMouseDown             = 1,
  NSEventTypeLeftMouseUp               = 2,
  NSEventTypeRightMouseDown            = 3,
  NSEventTypeRightMouseUp              = 4,
  NSEventTypeMouseMoved                = 5,
  NSEventTypeLeftMouseDragged          = 6,
  NSEventTypeRightMouseDragged         = 7,
  NSEventTypeMouseEntered              = 8,
  NSEventTypeMouseExited               = 9,
  NSEventTypeKeyDown                   = 10,
  NSEventTypeKeyUp                     = 11,
  NSEventTypeFlagsChanged              = 12,
  NSEventTypeAppKitDefined             = 13,
  NSEventTypeSystemDefined             = 14,
  NSEventTypeApplicationDefined        = 15,
  NSEventTypePeriodic                  = 16,
  NSEventTypeCursorUpdate              = 17,
  NSEventTypeRotate                    = 18,
  NSEventTypeBeginGesture              = 19,
  NSEventTypeEndGesture                = 20,
// (not defined)                       = 21,
  NSEventTypeScrollWheel               = 22,
  NSEventTypeTabletPoint               = 23,
  NSEventTypeTabletProximity           = 24,
  NSEventTypeOtherMouseDown            = 25,
  NSEventTypeOtherMouseUp              = 26,
  NSEventTypeOtherMouseDragged         = 27,
// (not defined)                       = 28,
  NSEventTypeGesture                   = 29,
  NSEventTypeMagnify                   = 30,
  NSEventTypeSwipe                     = 31,
  NSEventTypeSmartMagnify              = 32,
  NSEventTypeQuickLook                 = 33,
  NSEventTypePressure                  = 34,
// (not defined)                       = 35~37
  NSEventTypeDirectTouch               = 37,
  NSEventTypeChangeMode                = 38,
#endif
};
typedef NSUInteger NSEventType;

/**
 * <title>NSEventMask</title>
 * <abstract>Event mask constants for filtering event types</abstract>
 * Event masks are used to specify which types of events should be processed
 * or filtered. Each event type has a corresponding mask value that can be
 * combined using bitwise OR operations to create composite masks.
 *
 * Individual event masks correspond directly to event types:
 * - NSLeftMouseDownMask, NSLeftMouseUpMask: Primary mouse button events
 * - NSRightMouseDownMask, NSRightMouseUpMask: Secondary mouse button events
 * - NSOtherMouseDownMask, NSOtherMouseUpMask: Additional mouse button events
 * - NSMouseMovedMask: Mouse movement without buttons pressed
 * - NSLeftMouseDraggedMask, NSRightMouseDraggedMask, NSOtherMouseDraggedMask: Dragging events
 * - NSMouseEnteredMask, NSMouseExitedMask: Mouse tracking area events
 * - NSKeyDownMask, NSKeyUpMask: Keyboard press and release events
 * - NSFlagsChangedMask: Modifier key state changes
 * - NSScrollWheelMask: Mouse wheel and trackpad scrolling
 * - NSCursorUpdateMask: Cursor appearance updates
 * - NSPeriodicMask: Timer-based periodic events
 *
 * Special masks:
 * - NSAnyEventMask: Matches all event types
 * - GSKeyEventMask: Combines all keyboard-related events
 * - GSMouseEventMask: Combines all mouse-related events
 * - GSMouseMovedEventMask: Combines all mouse movement events
 * - GSEnterExitEventMask: Combines mouse enter/exit and cursor update events
 * - GSOtherEventMask: Combines system and application-defined events
 * - GSTrackingLoopMask: Events typically needed during mouse tracking loops
 */
enum {
  NSLeftMouseDownMask = (1 << NSLeftMouseDown),
  NSLeftMouseUpMask = (1 << NSLeftMouseUp),
  NSRightMouseDownMask = (1 << NSRightMouseDown),
  NSRightMouseUpMask = (1 << NSRightMouseUp),
  NSMouseMovedMask = (1 << NSMouseMoved),
  NSLeftMouseDraggedMask = (1 << NSLeftMouseDragged),
  NSRightMouseDraggedMask = (1 << NSRightMouseDragged),
  NSMouseEnteredMask = (1 << NSMouseEntered),
  NSMouseExitedMask = (1 << NSMouseExited),
  NSKeyDownMask = (1 << NSKeyDown),
  NSKeyUpMask = (1 << NSKeyUp),
  NSFlagsChangedMask = (1 << NSFlagsChanged),
  NSAppKitDefinedMask = (1 << NSAppKitDefined),
  NSSystemDefinedMask = (1 << NSSystemDefined),
  NSApplicationDefinedMask = (1 << NSApplicationDefined),
  NSPeriodicMask = (1 << NSPeriodic),
  NSCursorUpdateMask = (1 << NSCursorUpdate),
  NSScrollWheelMask = (1 << NSScrollWheel),
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
  NSTabletPointMask = (1 << NSTabletPoint),
  NSTabletProximityMask = (1 << NSTabletProximity),
#endif
  NSOtherMouseDownMask = (1 << NSOtherMouseDown),
  NSOtherMouseUpMask = (1 << NSOtherMouseUp),
  NSOtherMouseDraggedMask = (1 << NSOtherMouseDragged),

  NSAnyEventMask = 0xffffffffU,

  // key events
  GSKeyEventMask = (NSKeyDownMask | NSKeyUpMask | NSFlagsChangedMask),
  // mouse events
  GSMouseEventMask = (NSLeftMouseDownMask | NSLeftMouseUpMask | NSLeftMouseDraggedMask
                      | NSRightMouseDownMask | NSRightMouseUpMask | NSRightMouseDraggedMask
                      | NSOtherMouseDownMask | NSOtherMouseUpMask | NSOtherMouseDraggedMask
                      | NSMouseMovedMask | NSScrollWheelMask
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
                      | NSTabletPointMask | NSTabletProximityMask
#endif
      ),
  // mouse move events
  GSMouseMovedEventMask = (NSMouseMovedMask | NSScrollWheelMask
                           | NSLeftMouseDraggedMask | NSRightMouseDraggedMask
                           | NSOtherMouseDraggedMask),
  // enter/exit event
  GSEnterExitEventMask = (NSMouseEnteredMask | NSMouseExitedMask | NSCursorUpdateMask),
  // other events
  GSOtherEventMask = (NSAppKitDefinedMask | NSSystemDefinedMask
                      | NSApplicationDefinedMask | NSPeriodicMask),

  // tracking loops may need to add NSPeriodicMask
  GSTrackingLoopMask = (NSLeftMouseDownMask | NSLeftMouseUpMask
                        | NSLeftMouseDraggedMask | NSMouseMovedMask
                        | NSRightMouseUpMask | NSOtherMouseUpMask)
};
typedef unsigned long long NSEventMask;

/*
 * Convert an NSEvent Type to it's respective Event Mask
 */
// FIXME: Should we use the inline trick from NSGeometry.h here?
static inline NSEventMask
NSEventMaskFromType(NSEventType type);

static inline NSEventMask
NSEventMaskFromType(NSEventType type)
{
  return (1 << type);
}

enum {
#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
  NSDeviceIndependentModifierFlagsMask = 0xffff0000U,
#endif
  NSAlphaShiftKeyMask = 1 << 16,
  NSShiftKeyMask = 2 << 16,
  NSControlKeyMask = 4 << 16,
  NSAlternateKeyMask = 8 << 16,
  NSCommandKeyMask = 16 << 16,
  NSNumericPadKeyMask = 32 << 16,
  NSHelpKeyMask = 64 << 16,
  NSFunctionKeyMask = 128 << 16,
#if OS_API_VERSION(MAC_OS_X_VERSION_10_12, GS_API_LATEST)
  NSEventModifierFlagCapsLock = NSAlphaShiftKeyMask,
  NSEventModifierFlagShift = NSShiftKeyMask,
  NSEventModifierFlagControl = NSControlKeyMask,
  NSEventModifierFlagOption = NSAlternateKeyMask,
  NSEventModifierFlagCommand = NSCommandKeyMask,
  NSEventModifierFlagNumericPad = NSNumericPadKeyMask,
  NSEventModifierFlagFunction = NSFunctionKeyMask,
  NSEventModifierFlagDeviceIndependentFlagsMask = NSDeviceIndependentModifierFlagsMask,
#endif
};
typedef NSUInteger NSEventModifierFlags;


#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
enum
{
  NSUnknownPointingDevice,
  NSPenPointingDevice,
  NSCursorPointingDevice,
  NSEraserPointingDevice
};
typedef NSUInteger NSPointingDeviceType;

enum
{
  NSPenTipMask = 1,
  NSPenLowerSideMask = 2,
  NSPenUpperSideMask = 4
};
typedef NSUInteger NSEventButtonMask;

enum
{
  NSMouseEventSubtype,
  NSTabletPointEventSubtype,
  NSTabletProximityEventSubtype
};

enum {
  NSWindowExposedEventType = 0,
  NSApplicationActivatedEventType = 1,
  NSApplicationDeactivatedEventType = 2,
  NSWindowMovedEventType = 4,
  NSScreenChangedEventType = 8,
  NSAWTEventType = 16
};

enum
{
  NSPowerOffEventType = 1
};

#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_7, GS_API_LATEST)
enum {
  NSEventPhaseNone = 0,
  NSEventPhaseBegan = 1,
  NSEventPhaseStationary = 2,
  NSEventPhaseChanged = 4,
  NSEventPhaseEnded = 8,
  NSEventPhaseCancelled = 16,
  NSEventPhaseMayBegin = 32
};
typedef NSUInteger NSEventPhase;

enum {
  NSEventGestureAxisNone = 0,
  NSEventGestureAxisHorizontal,
  NSEventGestureAxisVertical
};
typedef NSInteger NSEventGestureAxis;

enum {
  NSEventSwipeTrackingLockDirection = 1,
  NSEventSwipeTrackingClampGestureAmount = 2
};
typedef NSUInteger NSEventSwipeTrackingOptions;

#endif

/**
 * <title>NSEvent</title>
 * <abstract>Represents user input and system events in the application</abstract>
 * NSEvent encapsulates information about user interactions (mouse clicks, key presses,
 * mouse movement) and system notifications (application lifecycle, window changes).
 * It serves as the primary mechanism for delivering input events to applications
 * and provides detailed information about the context and nature of each event.
 *
 * Key features include:
 * - Complete event information including type, location, timing, and modifiers
 * - Factory methods for creating events of different types
 * - Access to event-specific data like click counts, key codes, and pressure values
 * - Support for mouse tracking, keyboard input, and system notifications
 * - Integration with the event loop and event dispatch system
 * - Tablet and touch input support for advanced input devices
 *
 * Event Creation:
 * NSEvent provides class methods to create events for different purposes:
 * - mouseEventWithType:... for mouse events with click counts and pressure
 * - keyEventWithType:... for keyboard events with character and modifier info
 * - enterExitEventWithType:... for mouse tracking events
 * - otherEventWithType:... for custom and system events
 *
 * Event Properties:
 * All events have common properties like type, timestamp, location, and modifiers.
 * Specific event types provide additional information:
 * - Mouse events: button number, click count, pressure, scroll deltas
 * - Key events: character strings, key codes, repeat status
 * - Tracking events: tracking numbers and user data
 * - System events: subtype and custom data values
 *
 * The event data is stored in a union structure that efficiently manages
 * different data types for different event categories, minimizing memory
 * usage while providing type-safe access to event-specific information.
 */
APPKIT_EXPORT_CLASS
@interface NSEvent : NSObject <NSCoding, NSCopying>
{
  /** The type of this event (mouse, keyboard, system, etc.) */
  NSEventType	event_type;

  /** The location of the event in the window's coordinate system */
  NSPoint	location_point;

  /** Modifier key flags active when this event occurred */
  NSUInteger modifier_flags;

  /** The time when this event occurred, measured in seconds since system startup */
  NSTimeInterval event_time;

  /** The window number where this event occurred, or 0 if not window-specific */
  NSInteger window_num;

  /** The graphics context associated with this event's window */
  NSGraphicsContext *event_context;

  /**
   * Union containing event-specific data for different event types.
   * The appropriate struct member is selected based on the event_type.
   */
  union _MB_event_data
    {
      /** Mouse event data including buttons, clicks, pressure, and scroll deltas */
      struct
        {
          /** Sequential event number for this mouse event */
          NSInteger event_num;
          /** Number of clicks for this mouse event (1=single, 2=double, etc.) */
          NSInteger click;
          /** Mouse button number (0=left, 1=right, 2=other) */
          NSInteger button;
          /** Pressure value for pressure-sensitive input devices (0.0 to 1.0) */
          float pressure;
          /** Horizontal scroll delta for scroll wheel events */
          CGFloat deltaX;
          /** Vertical scroll delta for scroll wheel events */
          CGFloat deltaY;
          /** Z-axis scroll delta for 3D scroll devices */
          CGFloat deltaZ;
        } mouse;
      /** Keyboard event data including characters and key codes */
      struct
        {
          /** YES if this is a repeating key event, NO for initial press */
          BOOL     repeat;
          /** Characters generated by this key event with modifiers applied */
          __unsafe_unretained NSString *char_keys;
          /** Characters that would be generated without modifier keys */
          __unsafe_unretained NSString *unmodified_keys;
          /** Hardware-specific key code for the pressed key */
          unsigned short key_code;
        } key;
      /** Mouse tracking event data for enter/exit events */
      struct
        {
          /** Sequential event number for this tracking event */
          NSInteger event_num;
          /** Tracking area number associated with this event */
          NSInteger tracking_num;
          /** User-defined data associated with the tracking area */
          void *user_data;
        } tracking;
      /** System and application-defined event data */
      struct
        {
          /** Event subtype for categorizing system/app events */
          short sub_type;
          /** First custom data value */
          NSInteger data1;
          /** Second custom data value */
          NSInteger data2;
        } misc;
    } event_data;
}

/**
 * Creates an enter/exit event for mouse tracking areas.
 * This factory method creates events that are generated when the mouse
 * enters or exits defined tracking areas within views. These events
 * are used to implement cursor changes, tooltips, and other location-
 * sensitive interface behaviors.
 * type: The event type (NSMouseEntered or NSMouseExited)
 * location: The mouse location in window coordinates
 * flags: Modifier key flags active when the event occurred
 * time: The time when the event occurred (seconds since system startup)
 * windowNum: The window number where the event occurred
 * context: The graphics context associated with the window
 * eventNum: Sequential event number for tracking
 * trackingNum: The tracking area number that generated this event
 * userData: User-defined data associated with the tracking area
 * Returns: A new NSEvent object representing the enter/exit event
 */
+ (NSEvent*) enterExitEventWithType: (NSEventType)type
                           location: (NSPoint)location
                      modifierFlags: (NSUInteger)flags
                          timestamp: (NSTimeInterval)time
                       windowNumber: (NSInteger)windowNum
                            context: (NSGraphicsContext*)context
                        eventNumber: (NSInteger)eventNum
                     trackingNumber: (NSInteger)trackingNum
                           userData: (void *)userData;

/**
 * Creates a keyboard event for key presses and releases.
 * This factory method creates events representing keyboard input,
 * including both the actual characters generated and the raw key codes.
 * It handles modifier key combinations and key repeat detection.
 * type: The event type (NSKeyDown or NSKeyUp)
 * location: The mouse location when the key event occurred
 * flags: Modifier key flags active when the key was pressed
 * time: The time when the event occurred (seconds since system startup)
 * windowNum: The window number where the event occurred
 * context: The graphics context associated with the window
 * keys: The characters generated by this key press with modifiers
 * ukeys: The characters that would be generated without modifiers
 * repeatKey: YES if this is a repeating key event, NO for initial press
 * code: The hardware-specific key code for the pressed key
 * Returns: A new NSEvent object representing the keyboard event
 */
+ (NSEvent*) keyEventWithType: (NSEventType)type
                     location: (NSPoint)location
                modifierFlags: (NSUInteger)flags
                    timestamp: (NSTimeInterval)time
                 windowNumber: (NSInteger)windowNum
                      context: (NSGraphicsContext*)context
                   characters: (NSString *)keys
  charactersIgnoringModifiers: (NSString *)ukeys
                    isARepeat: (BOOL)repeatKey
                      keyCode: (unsigned short)code;

/**
 * Creates a mouse event for clicks, releases, and movement.
 * This factory method creates events representing mouse interactions
 * including button presses, releases, and movement. It supports
 * multi-click detection and pressure-sensitive input devices.
 * type: The event type (NSLeftMouseDown, NSMouseMoved, etc.)
 * location: The mouse location in window coordinates
 * flags: Modifier key flags active when the event occurred
 * time: The time when the event occurred (seconds since system startup)
 * windowNum: The window number where the event occurred
 * context: The graphics context associated with the window
 * eventNum: Sequential event number for tracking
 * clickNum: Number of clicks (1=single, 2=double, 3=triple, etc.)
 * pressureValue: Pressure value for pressure-sensitive devices (0.0 to 1.0)
 * Returns: A new NSEvent object representing the mouse event
 */
+ (NSEvent*) mouseEventWithType: (NSEventType)type
                       location: (NSPoint)location
                  modifierFlags: (NSUInteger)flags
                      timestamp: (NSTimeInterval)time
                   windowNumber: (NSInteger)windowNum
                        context: (NSGraphicsContext*)context
                    eventNumber: (NSInteger)eventNum
                     clickCount: (NSInteger)clickNum
                       pressure: (float)pressureValue;

#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
/**
 * Creates an extended mouse event with additional button and delta information.
 * This GNUstep-specific factory method creates mouse events with support for
 * additional mouse buttons and scroll delta values. This provides more detailed
 * information than the standard mouse event creation method.
 * type: The event type (mouse-related events)
 * location: The mouse location in window coordinates
 * flags: Modifier key flags active when the event occurred
 * time: The time when the event occurred (seconds since system startup)
 * windowNum: The window number where the event occurred
 * context: The graphics context associated with the window
 * eventNum: Sequential event number for tracking
 * clickNum: Number of clicks for button events
 * pressureValue: Pressure value for pressure-sensitive devices
 * buttonNum: The specific mouse button number (0=left, 1=right, 2=middle, etc.)
 * deltaX: Horizontal scroll delta for scroll events
 * deltaY: Vertical scroll delta for scroll events
 * deltaZ: Z-axis scroll delta for 3D scroll devices
 * Returns: A new NSEvent object with extended mouse information
 */
+ (NSEvent*) mouseEventWithType: (NSEventType)type
                       location: (NSPoint)location
                  modifierFlags: (NSUInteger)flags
                      timestamp: (NSTimeInterval)time
                   windowNumber: (NSInteger)windowNum
                        context: (NSGraphicsContext*)context
                    eventNumber: (NSInteger)eventNum
                     clickCount: (NSInteger)clickNum
                       pressure: (float)pressureValue
                   buttonNumber: (NSInteger)buttonNum
                         deltaX: (CGFloat)deltaX
                         deltaY: (CGFloat)deltaY
                         deltaZ: (CGFloat)deltaZ;
#endif

/**
 * Returns the current mouse location in screen coordinates.
 * This class method provides the current mouse cursor position
 * relative to the screen's coordinate system, regardless of
 * which window or application currently has focus.
 * Returns: The current mouse location in screen coordinates
 */
+ (NSPoint)mouseLocation;

/**
 * Creates a system or application-defined event.
 * This factory method creates events for system notifications and
 * custom application events. These events carry custom data and
 * can be used for inter-component communication within applications.
 * type: The event type (NSSystemDefined, NSApplicationDefined, etc.)
 * location: The location associated with this event (may be irrelevant)
 * flags: Modifier key flags active when the event was created
 * time: The time when the event occurred (seconds since system startup)
 * windowNum: The window number associated with this event (may be 0)
 * context: The graphics context (may be nil for non-window events)
 * subType: Event subtype for categorizing similar events
 * data1: First custom data value
 * data2: Second custom data value
 * Returns: A new NSEvent object representing the custom event
 */
+ (NSEvent*) otherEventWithType: (NSEventType)type
                       location: (NSPoint)location
                  modifierFlags: (NSUInteger)flags
                      timestamp: (NSTimeInterval)time
                   windowNumber: (NSInteger)windowNum
                        context: (NSGraphicsContext*)context
                        subtype: (short)subType
                          data1: (NSInteger)data1
                          data2: (NSInteger)data2;

/**
 * Starts generating periodic events at regular intervals.
 * This class method configures the event system to generate NSPeriodic
 * events at specified intervals. These events can be used for regular
 * updates, animations, or periodic processing. The events continue until
 * stopPeriodicEvents is called.
 * delaySeconds: Initial delay before the first periodic event
 * periodSeconds: Time interval between subsequent periodic events
 */
+ (void) startPeriodicEventsAfterDelay: (NSTimeInterval)delaySeconds
                            withPeriod: (NSTimeInterval)periodSeconds;

/**
 * Stops generating periodic events.
 * This class method stops the generation of NSPeriodic events that were
 * started with startPeriodicEventsAfterDelay:withPeriod:. After calling
 * this method, no more periodic events will be generated.
 */
+ (void) stopPeriodicEvents;


#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Returns the mouse button number for mouse events.
 * For mouse button events, this returns which button was pressed or released.
 * Button numbers are: 0=left button, 1=right button, 2=middle button, etc.
 * For non-mouse events, the return value is undefined.
 * Returns: The button number that triggered this mouse event
 */
- (NSInteger) buttonNumber;
#endif

/**
 * Returns the characters generated by a key event.
 * For keyboard events, this returns the string that would be inserted
 * into a text field, taking into account the current modifier keys.
 * For non-keyboard events, returns nil.
 * Returns: The characters generated by this key event with modifiers applied
 */
- (NSString *) characters;

/**
 * Returns the characters that would be generated without modifier keys.
 * For keyboard events, this returns the string that would be generated
 * if no modifier keys (except Shift for capitalization) were pressed.
 * This is useful for key binding systems that want to ignore modifiers.
 * For non-keyboard events, returns nil.
 * Returns: The base characters for this key event without modifier effects
 */
- (NSString *) charactersIgnoringModifiers;

/**
 * Returns the click count for mouse button events.
 * For mouse button events, this indicates the number of consecutive clicks:
 * 1=single click, 2=double click, 3=triple click, etc. The system determines
 * multiple clicks based on timing and proximity of events.
 * For non-mouse events, returns 0.
 * Returns: The number of consecutive clicks for this mouse event
 */
- (NSInteger) clickCount;

/**
 * Returns the graphics context associated with this event.
 * This is the graphics context of the window where the event occurred,
 * which can be used for coordinate transformations and drawing operations.
 * May return nil for events not associated with a specific window.
 * Returns: The NSGraphicsContext associated with this event's window
 */
- (NSGraphicsContext*) context;

/**
 * Returns the first custom data value for system/application events.
 * For NSSystemDefined and NSApplicationDefined events, this contains
 * the first custom data value set when the event was created.
 * For other event types, the return value is undefined.
 * Returns: The first custom data value for this event
 */
- (NSInteger) data1;

/**
 * Returns the second custom data value for system/application events.
 * For NSSystemDefined and NSApplicationDefined events, this contains
 * the second custom data value set when the event was created.
 * For other event types, the return value is undefined.
 * Returns: The second custom data value for this event
 */
- (NSInteger) data2;
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Returns the horizontal scroll delta for scroll wheel events.
 * For scroll events, this indicates the horizontal scrolling amount.
 * Positive values indicate scrolling to the right, negative values
 * indicate scrolling to the left. The magnitude depends on the scroll
 * wheel resolution and system acceleration settings.
 * Returns: The horizontal scroll distance for this scroll event
 */
- (CGFloat)deltaX;

/**
 * Returns the vertical scroll delta for scroll wheel events.
 * For scroll events, this indicates the vertical scrolling amount.
 * Positive values indicate scrolling up (away from user), negative values
 * indicate scrolling down (toward user). The magnitude depends on the scroll
 * wheel resolution and system acceleration settings.
 * Returns: The vertical scroll distance for this scroll event
 */
- (CGFloat)deltaY;

/**
 * Returns the z-axis scroll delta for scroll wheel events.
 * For scroll events with 3D scroll wheels or trackpads, this indicates
 * scrolling along the z-axis (typically used for zooming).
 * Most standard scroll wheels return 0.0 for this value.
 * Returns: The z-axis scroll distance for this scroll event
 */
- (CGFloat)deltaZ;
#endif
#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
/**
 * Returns the unique identifier for this event.
 * Each event has a unique identifier that can be used to track and
 * correlate events. This number increases monotonically within a session.
 * Returns: A unique identifier number for this event
 */
- (NSInteger) eventNumber;
#endif

/**
 * Returns whether this is a key repeat event.
 * For keyboard events, this indicates whether the key was held down long
 * enough to trigger key repeat. The first press returns NO, subsequent
 * repeat events return YES.
 * For non-keyboard events, the return value is undefined.
 * Returns: YES if this is a key repeat event, NO if it's the initial key press
 */
- (BOOL) isARepeat;

/**
 * Returns the hardware key code for keyboard events.
 * For keyboard events, this returns the raw hardware key code that doesn't
 * depend on the current keyboard layout. This is useful for key bindings
 * that should work regardless of keyboard layout.
 * For non-keyboard events, the return value is undefined.
 * Returns: The hardware key code for this keyboard event
 */
- (unsigned short) keyCode;

/**
 * Returns the location of this event in the window's coordinate system.
 * The location is in the window's base coordinate system (bottom-left origin).
 * For events not associated with a window, the coordinates are in screen space.
 * For non-positional events, returns NSZeroPoint.
 * Returns: The location of this event in window coordinates
 */
- (NSPoint) locationInWindow;

/**
 * Returns the modifier flags active when this event occurred.
 * The modifier flags indicate which modifier keys (Command, Option, Control,
 * Shift, Function, etc.) were pressed when the event occurred.
 * Returns: A bitmask of NSEventModifierFlags values
 */
- (NSEventModifierFlags) modifierFlags;

/**
 * Returns the pressure value for tablet and touch events.
 * For tablet events, this returns the pressure applied to the tablet surface
 * (0.0 = no pressure, 1.0 = maximum pressure).
 * For mouse events on pressure-sensitive devices, indicates click pressure.
 * For other event types, returns 0.0.
 * Returns: The pressure value from 0.0 to 1.0
 */
- (float) pressure;

/**
 * Returns the subtype for system and application-defined events.
 * For NSSystemDefined and NSApplicationDefined events, this provides
 * additional categorization of the event type.
 * For other event types, the return value is undefined.
 * Returns: The event subtype identifier
 */
- (short) subtype;

/**
 * Returns the timestamp when this event occurred.
 * The timestamp is relative to system startup time and can be used to
 * measure time intervals between events or determine event ordering.
 * Returns: The time when this event occurred as seconds since system startup
 */
- (NSTimeInterval) timestamp;

/**
 * Returns the tracking rectangle number for tracking events.
 * For mouse entered/exited events generated by tracking rectangles,
 * this returns the tracking rectangle number that was assigned when
 * the tracking rectangle was created.
 * For other event types, the return value is undefined.
 * Returns: The tracking rectangle number that generated this event
 */
- (NSInteger) trackingNumber;

/**
 * Returns the type of this event.
 * This indicates the fundamental category of the event (mouse, keyboard,
 * tracking, etc.) and determines which other properties are meaningful.
 * Returns: The NSEventType value indicating this event's type
 */
- (NSEventType) type;

/**
 * Returns the user data pointer for tracking events.
 * For mouse entered/exited events generated by tracking rectangles,
 * this returns the user data pointer that was provided when the
 * tracking rectangle was created.
 * For other event types, returns NULL.
 * Returns: The user data pointer associated with this tracking event
 */
- (void *) userData;

/**
 * Returns the window associated with this event.
 * This is the window where the event occurred or the window that
 * should receive the event. May be nil for global events or events
 * that occurred outside any window.
 * Returns: The NSWindow associated with this event, or nil
 */
- (NSWindow *) window;

/**
 * Returns the window number associated with this event.
 * This is a unique identifier for the window where the event occurred.
 * Window numbers are assigned by the window server and remain constant
 * for the lifetime of a window.
 * Returns: The window number for this event's associated window
 */
- (NSInteger) windowNumber;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_3, GS_API_LATEST)
/**
 * Returns the event mask for events associated with this event.
 * For tablet proximity events, this returns a mask indicating which
 * types of events will be generated by the tablet device when it
 * enters proximity. This allows applications to prepare for the
 * types of events they will receive.
 * Returns: An NSEventMask indicating associated event types
 */
- (NSEventMask) associatedEventsMask;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)
/**
 * Returns the absolute X coordinate for tablet events.
 * For tablet events, this returns the absolute position on the tablet
 * surface rather than the relative screen position. The coordinate
 * system is tablet-specific.
 * Returns: The absolute X coordinate on the tablet surface
 */
- (NSInteger) absoluteX;

/**
 * Returns the absolute Y coordinate for tablet events.
 * For tablet events, this returns the absolute position on the tablet
 * surface rather than the relative screen position. The coordinate
 * system is tablet-specific.
 * Returns: The absolute Y coordinate on the tablet surface
 */
- (NSInteger) absoluteY;

/**
 * Returns the absolute Z coordinate for tablet events.
 * For 3D tablet events, this returns the height above the tablet surface.
 * Most 2D tablets return 0 for this value.
 * Returns: The absolute Z coordinate (height) above the tablet surface
 */
- (NSInteger) absoluteZ;

/**
 * Returns a bitmask of currently pressed mouse buttons.
 * This bitmask indicates which mouse buttons are currently pressed
 * at the time this event occurred, not just the button that changed
 * state for this particular event.
 * Returns: An NSEventButtonMask indicating which buttons are pressed
 */
- (NSEventButtonMask) buttonMask;

/**
 * Returns the capability mask for tablet devices.
 * For tablet proximity events, this indicates the capabilities of the
 * tablet device (pressure sensitivity, tilt, rotation, etc.).
 * Applications can use this to adapt their behavior to the device.
 * Returns: A bitmask indicating the device capabilities
 */
- (NSUInteger) capabilityMask;

/**
 * Returns the device identifier for tablet events.
 * For tablet events, this uniquely identifies the input device that
 * generated the event. Multiple tablets can be distinguished by
 * their device IDs.
 * Returns: A unique identifier for the input device
 */
- (NSUInteger) deviceID;

/**
 * Returns whether a tablet device is entering proximity.
 * For tablet proximity events, this indicates whether the device is
 * entering (YES) or leaving (NO) proximity to the tablet surface.
 * Returns: YES if entering proximity, NO if leaving proximity
 */
- (BOOL) isEnteringProximity;

/**
 * Returns the pointing device identifier for tablet events.
 * For tablet events, this identifies the specific pointing device
 * (stylus, puck, eraser, etc.) being used with the tablet.
 * Different tools on the same tablet have different IDs.
 * Returns: A unique identifier for the pointing device
 */
- (NSUInteger) pointingDeviceID;

/**
 * Returns the serial number of the pointing device.
 * For tablet events, this is the hardware serial number of the
 * pointing device. This remains constant across sessions and can
 * be used to identify specific styluses or tools.
 * Returns: The serial number of the pointing device
 */
- (NSUInteger) pointingDeviceSerialNumber;

/**
 * Returns the type of the pointing device.
 * For tablet events, this indicates the category of pointing device
 * (stylus, cursor/puck, eraser, etc.) being used.
 * Returns: An NSPointingDeviceType value indicating the device type
 */
- (NSPointingDeviceType) pointingDeviceType;

/**
 * Returns the rotation angle for tablet events.
 * For tablet events from devices that support rotation (like art pens),
 * this returns the rotation angle in degrees. The angle is measured
 * from the device's natural orientation.
 * Returns: The rotation angle in degrees (0.0 to 359.9)
 */
- (float) rotation;

/**
 * Returns the system tablet identifier.
 * For tablet events, this identifies the tablet system that generated
 * the event. This allows distinguishing between multiple tablet systems
 * connected to the same computer.
 * Returns: A unique identifier for the tablet system
 */
- (NSUInteger) systemTabletID;

/**
 * Returns the tablet identifier.
 * For tablet events, this identifies the specific tablet that generated
 * the event. This is useful when multiple tablets are part of the same
 * system.
 * Returns: A unique identifier for the tablet
 */
- (NSUInteger) tabletID;

/**
 * Returns the tangential pressure for tablet events.
 * For tablet events from devices with tangential pressure sensors
 * (like airbrush styluses), this returns the side pressure value.
 * The range is typically 0.0 to 1.0.
 * Returns: The tangential pressure value
 */
- (float) tangentialPressure;

/**
 * Returns the tilt angle for tablet events.
 * For tablet events from devices that support tilt sensing, this
 * returns the tilt of the stylus relative to the tablet surface.
 * The point contains x and y tilt angles.
 * Returns: An NSPoint with x and y tilt angles
 */
- (NSPoint) tilt;

/**
 * Returns a unique identifier for tablet events.
 * For tablet events, this provides a unique identifier that persists
 * across the lifetime of the pointing device session. This can be used
 * to correlate related tablet events.
 * Returns: A unique identifier for the pointing device session
 */
- (unsigned long long) uniqueID;

/**
 * Returns vendor-defined data for tablet events.
 * For tablet events, this contains any additional data defined by
 * the tablet hardware vendor. The format and meaning depend on the
 * specific tablet hardware.
 * Returns: An object containing vendor-specific data, or nil
 */
- (id) vendorDefined;

/**
 * Returns the vendor identifier for tablet events.
 * For tablet events, this identifies the hardware vendor of the tablet
 * device. This can be used to implement vendor-specific features or
 * workarounds.
 * Returns: A unique identifier for the tablet vendor
 */
- (NSUInteger) vendorID;

/**
 * Returns the vendor-specific pointing device type.
 * For tablet events, this provides additional device type information
 * specific to the tablet vendor. This supplements the standard
 * pointingDeviceType with vendor-specific details.
 * Returns: A vendor-specific device type identifier
 */
- (NSUInteger) vendorPointingDeviceType;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_5, GS_API_LATEST)
/**
 * Creates an NSEvent from a Carbon EventRef.
 * This factory method creates an NSEvent object from a Carbon EventRef,
 * allowing integration with Carbon event handling code.
 * eventRef: A Carbon EventRef to convert to an NSEvent
 * Returns: A new NSEvent object representing the Carbon event
 */
+ (NSEvent*) eventWithEventRef: (const void *)eventRef;
//+ (NSEvent*) eventWithCGEvent: (CGEventRef)cgEvent;

/**
 * Returns the Carbon EventRef for this event.
 * This provides access to the underlying Carbon event representation,
 * allowing integration with Carbon event handling APIs.
 * Returns: The Carbon EventRef for this event, or NULL if not available
 */
- (const void *) eventRef;
//- (CGEventRef) CGEvent;

/**
 * Enables or disables mouse event coalescing.
 * When enabled, multiple mouse moved events that occur in rapid succession
 * are coalesced into a single event to improve performance. This is
 * typically desirable for tracking mouse movement.
 * flag: YES to enable coalescing, NO to disable
 */
+ (void) setMouseCoalescingEnabled: (BOOL)flag;

/**
 * Returns whether mouse event coalescing is currently enabled.
 * Mouse coalescing combines multiple rapid mouse movement events into
 * single events to improve performance during mouse tracking operations.
 * Returns: YES if mouse coalescing is enabled, NO otherwise
 */
+ (BOOL) isMouseCoalescingEnabled;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_6, GS_API_LATEST)
/**
 * Returns the currently pressed modifier flags.
 * This class method returns the modifier flags that are currently active
 * system-wide, regardless of which application has focus. This is useful
 * for checking modifier state outside of event handling.
 * Returns: The currently active modifier flags
 */
+ (NSEventModifierFlags) modifierFlags;

/**
 * Returns the key repeat delay interval.
 * This is the time interval between the initial key press and the first
 * key repeat event when a key is held down.
 * Returns: The key repeat delay in seconds
 */
+ (NSTimeInterval) keyRepeatDelay;

/**
 * Returns the key repeat interval.
 * This is the time interval between consecutive key repeat events after
 * the initial delay when a key is held down.
 * Returns: The key repeat interval in seconds
 */
+ (NSTimeInterval) keyRepeatInterval;

/**
 * Returns a bitmask of currently pressed mouse buttons.
 * This class method returns which mouse buttons are currently pressed
 * system-wide. The bitmask uses the same format as buttonMask.
 * Returns: A bitmask indicating which mouse buttons are pressed
 */
+ (NSUInteger) pressedMouseButtons;

/**
 * Returns the double-click time interval.
 * This is the maximum time interval between two mouse clicks for them
 * to be considered a double-click. This value reflects the user's
 * system preferences.
 * Returns: The double-click interval in seconds
 */
+ (NSTimeInterval) doubleClickInterval;
#endif

#if OS_API_VERSION(MAC_OS_X_VERSION_10_7, GS_API_LATEST)
/**
 * Returns the gesture phase for scroll and gesture events.
 * For trackpad scroll and gesture events, this indicates the phase of
 * the gesture: began, changed, ended, cancelled, etc. This allows
 * applications to properly handle multi-phase gestures.
 * Returns: The NSEventPhase value for this gesture event
 */
- (NSEventPhase) phase;

/**
 * Returns the momentum phase for scroll events.
 * For trackpad scroll events, this indicates the momentum phase after
 * the user has lifted their fingers but scrolling continues due to
 * inertia. This helps distinguish user-driven from momentum scrolling.
 * Returns: The NSEventPhase value for momentum scrolling
 */
- (NSEventPhase) momentumPhase;
#endif
@end

enum {
  NSUpArrowFunctionKey = 0xF700,
  NSDownArrowFunctionKey = 0xF701,
  NSLeftArrowFunctionKey = 0xF702,
  NSRightArrowFunctionKey = 0xF703,
  NSF1FunctionKey  = 0xF704,
  NSF2FunctionKey  = 0xF705,
  NSF3FunctionKey  = 0xF706,
  NSF4FunctionKey  = 0xF707,
  NSF5FunctionKey  = 0xF708,
  NSF6FunctionKey  = 0xF709,
  NSF7FunctionKey  = 0xF70A,
  NSF8FunctionKey  = 0xF70B,
  NSF9FunctionKey  = 0xF70C,
  NSF10FunctionKey = 0xF70D,
  NSF11FunctionKey = 0xF70E,
  NSF12FunctionKey = 0xF70F,
  NSF13FunctionKey = 0xF710,
  NSF14FunctionKey = 0xF711,
  NSF15FunctionKey = 0xF712,
  NSF16FunctionKey = 0xF713,
  NSF17FunctionKey = 0xF714,
  NSF18FunctionKey = 0xF715,
  NSF19FunctionKey = 0xF716,
  NSF20FunctionKey = 0xF717,
  NSF21FunctionKey = 0xF718,
  NSF22FunctionKey = 0xF719,
  NSF23FunctionKey = 0xF71A,
  NSF24FunctionKey = 0xF71B,
  NSF25FunctionKey = 0xF71C,
  NSF26FunctionKey = 0xF71D,
  NSF27FunctionKey = 0xF71E,
  NSF28FunctionKey = 0xF71F,
  NSF29FunctionKey = 0xF720,
  NSF30FunctionKey = 0xF721,
  NSF31FunctionKey = 0xF722,
  NSF32FunctionKey = 0xF723,
  NSF33FunctionKey = 0xF724,
  NSF34FunctionKey = 0xF725,
  NSF35FunctionKey = 0xF726,
  NSInsertFunctionKey = 0xF727,
  NSDeleteFunctionKey = 0xF728,
  NSHomeFunctionKey = 0xF729,
  NSBeginFunctionKey = 0xF72A,
  NSEndFunctionKey = 0xF72B,
  NSPageUpFunctionKey = 0xF72C,
  NSPageDownFunctionKey = 0xF72D,
  NSPrintScreenFunctionKey = 0xF72E,
  NSScrollLockFunctionKey = 0xF72F,
  NSPauseFunctionKey = 0xF730,
  NSSysReqFunctionKey = 0xF731,
  NSBreakFunctionKey = 0xF732,
  NSResetFunctionKey = 0xF733,
  NSStopFunctionKey = 0xF734,
  NSMenuFunctionKey = 0xF735,
  NSUserFunctionKey = 0xF736,
  NSSystemFunctionKey = 0xF737,
  NSPrintFunctionKey = 0xF738,
  NSClearLineFunctionKey = 0xF739,
  NSClearDisplayFunctionKey = 0xF73A,
  NSInsertLineFunctionKey = 0xF73B,
  NSDeleteLineFunctionKey = 0xF73C,
  NSInsertCharFunctionKey = 0xF73D,
  NSDeleteCharFunctionKey = 0xF73E,
  NSPrevFunctionKey = 0xF73F,
  NSNextFunctionKey = 0xF740,
  NSSelectFunctionKey = 0xF741,
  NSExecuteFunctionKey = 0xF742,
  NSUndoFunctionKey = 0xF743,
  NSRedoFunctionKey = 0xF744,
  NSFindFunctionKey = 0xF745,
  NSHelpFunctionKey = 0xF746,
  NSModeSwitchFunctionKey = 0xF747
};

#if OS_API_VERSION(GS_API_NONE, GS_API_NONE)
typedef enum {
  GSAppKitWindowMoved = 1,
  GSAppKitWindowResized,
  GSAppKitWindowClose,
  GSAppKitWindowMiniaturize,
  GSAppKitWindowFocusIn,
  GSAppKitWindowFocusOut,
  GSAppKitWindowLeave,
  GSAppKitWindowEnter,
  GSAppKitDraggingEnter,
  GSAppKitDraggingUpdate,
  GSAppKitDraggingStatus,
  GSAppKitDraggingExit,
  GSAppKitDraggingDrop,
  GSAppKitDraggingFinished,
  GSAppKitRegionExposed,
  GSAppKitWindowDeminiaturize,
  GSAppKitAppHide
} GSAppKitSubtype;
#endif

#endif /* _GNUstep_H_NSEvent */
