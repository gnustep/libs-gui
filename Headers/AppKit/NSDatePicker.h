/* -*-objc-*-
   NSDatePicker.h

   The date picker class

   Copyright (C) 2020 Free Software Foundation, Inc.

   Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
   Copyright (c) 2005 DSITRI.

   Author:	Fabian Spillner
   Date:	22. October 2007

   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	7. November 2007 - aligned with 10.5

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

#ifndef _GNUstep_H_NSDatePicker
#define _GNUstep_H_NSDatePicker

#import <AppKit/NSControl.h>
#import <AppKit/NSDatePickerCell.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_4, GS_API_LATEST)

/**
 * NSDatePicker provides an interactive user interface for selecting dates and times.
 * It can display various combinations of date and time elements (day, month, year,
 * hour, minute, second) and supports different presentation styles including text
 * fields, stepper controls, and graphical calendars.
 *
 * The date picker can be configured to operate in different modes, such as showing
 * only dates, only times, or both dates and times together. It supports localization
 * for different calendar systems, time zones, and cultural date/time formatting
 * conventions.
 *
 * Date pickers can enforce minimum and maximum date constraints, making them suitable
 * for applications that need to restrict date selection to valid ranges. They integrate
 * with the target-action pattern like other NSControl subclasses, sending actions
 * when the selected date or time changes.
 *
 * The control supports various visual styles and can be customized with background
 * colors, text colors, borders, and bezeled appearances to match application design
 * requirements.
 */
APPKIT_EXPORT_CLASS
@interface NSDatePicker : NSControl

/**
 * Returns the background color used when drawing the date picker.
 * The background color is only visible when the drawsBackground property
 * is set to YES. This color fills the control's bounds behind the date
 * picker elements and text.
 * Returns the current background color, or nil if using the default.
 */
- (NSColor *) backgroundColor;

/**
 * Returns the calendar system used by the date picker.
 * The calendar determines how dates are interpreted, formatted, and displayed.
 * Different calendar systems (Gregorian, Hebrew, Islamic, etc.) have different
 * rules for months, years, and date calculations.
 * Returns the NSCalendar object used for date calculations and formatting.
 */
- (NSCalendar *) calendar;

/**
 * Returns the currently enabled date picker elements.
 * Date picker elements control which components of the date and time are
 * displayed and editable. This can include combinations of year, month, day,
 * hour, minute, and second elements.
 * Returns a bitmask of NSDatePickerElementFlags indicating which elements are enabled.
 */
- (NSDatePickerElementFlags) datePickerElements;

/**
 * Returns the current date picker mode.
 * The mode determines whether the picker displays date components, time components,
 * or both. This affects which elements are visible and how the picker behaves.
 * Returns the NSDatePickerMode value indicating the current operating mode.
 */
- (NSDatePickerMode) datePickerMode;

/**
 * Returns the visual style of the date picker.
 * The style determines the overall appearance and interaction model of the
 * date picker, such as whether it uses text fields, steppers, or a calendar view.
 * Returns the NSDatePickerStyle value indicating the current visual style.
 */
- (NSDatePickerStyle) datePickerStyle;

/**
 * Returns the currently selected date and time.
 * This is the primary value of the date picker and represents the user's
 * current selection. The date includes both date and time components,
 * though only relevant components are used based on the picker mode.
 * Returns the NSDate object representing the current selection.
 */
- (NSDate *) dateValue;

/**
 * Returns the delegate object for the date picker.
 * The delegate can receive notifications about date picker events and
 * customize certain aspects of the picker's behavior. Note that this
 * method is a GNUstep extension and does not exist in the standard API.
 * Returns the current delegate object, or nil if no delegate is set.
 */
- (id) delegate;

/**
 * Returns whether the date picker draws its background.
 * When YES, the date picker fills its bounds with the background color.
 * When NO, the background is transparent and the parent view shows through.
 * Returns YES if background drawing is enabled, NO otherwise.
 */
- (BOOL) drawsBackground;

/**
 * Returns whether the date picker has a bezeled appearance.
 * A bezeled appearance gives the control a raised, three-dimensional look
 * with shadowed edges. This is purely visual and does not affect functionality.
 * Returns YES if the date picker is bezeled, NO otherwise.
 */
- (BOOL) isBezeled;

/**
 * Returns whether the date picker has a border.
 * The border provides a visual frame around the date picker control.
 * This can help distinguish the control from surrounding interface elements.
 * Returns YES if the date picker has a border, NO otherwise.
 */
- (BOOL) isBordered;

/**
 * Returns the locale used for date and time formatting.
 * The locale determines how dates and times are formatted according to
 * regional and cultural conventions, including number formats, month names,
 * and date ordering.
 * Returns the NSLocale object used for formatting, or nil for the default locale.
 */
- (NSLocale *) locale;

/**
 * Returns the maximum selectable date.
 * Users cannot select dates later than this maximum date. This constraint
 * helps ensure that selected dates fall within valid or meaningful ranges
 * for the application.
 * Returns the maximum selectable NSDate, or nil if no maximum is set.
 */
- (NSDate *) maxDate;

/**
 * Returns the minimum selectable date.
 * Users cannot select dates earlier than this minimum date. This constraint
 * helps ensure that selected dates fall within valid or meaningful ranges
 * for the application.
 * Returns the minimum selectable NSDate, or nil if no minimum is set.
 */
- (NSDate *) minDate;

/**
 * Sets the background color for the date picker.
 * The background color is only visible when drawsBackground is set to YES.
 * The color parameter specifies the new background color to use. Pass nil
 * to use the default background color for the control.
 * This setting affects the visual appearance but not the functionality.
 */
- (void) setBackgroundColor:(NSColor *) color;

/**
 * Sets whether the date picker has a bezeled appearance.
 * A bezeled appearance gives the control a raised, three-dimensional look
 * with shadowed edges. The flag parameter specifies whether to enable (YES)
 * or disable (NO) the bezeled appearance.
 * This is a purely visual setting that does not affect control behavior.
 */
- (void) setBezeled:(BOOL) flag;

/**
 * Sets whether the date picker displays a border.
 * The border provides a visual frame around the date picker control to help
 * distinguish it from surrounding interface elements. The flag parameter
 * specifies whether to show (YES) or hide (NO) the border.
 * This affects only the visual appearance of the control.
 */
- (void) setBordered:(BOOL) flag;

/**
 * Sets the calendar system used by the date picker.
 * The calendar determines how dates are interpreted, calculated, and displayed.
 * Different calendar systems have different rules for months, years, and
 * date arithmetic. The calendar parameter specifies the NSCalendar to use
 * for all date operations and formatting.
 * Changing the calendar updates the display to reflect the new system.
 */
- (void) setCalendar:(NSCalendar *) calendar;

/**
 * Sets which date and time elements are displayed and editable.
 * Date picker elements control the visibility and editability of individual
 * components like year, month, day, hour, minute, and second. The flags
 * parameter should be a bitmask of NSDatePickerElementFlags values.
 * This setting works in conjunction with the date picker mode to determine
 * the overall appearance and functionality.
 */
- (void) setDatePickerElements:(NSDatePickerElementFlags) flags;

/**
 * Sets the operating mode of the date picker.
 * The mode determines whether the picker shows date components, time components,
 * or both together. The mode parameter should be a NSDatePickerMode value
 * that specifies the desired behavior.
 * Changing the mode updates the visible elements and interaction model.
 */
- (void) setDatePickerMode:(NSDatePickerMode) mode;

/**
 * Sets the visual style of the date picker.
 * The style determines the overall appearance and interaction model, such as
 * whether the picker uses text fields, stepper controls, or a calendar view.
 * The style parameter should be a NSDatePickerStyle value specifying the
 * desired presentation format.
 * Different styles may support different feature sets and interaction methods.
 */
- (void) setDatePickerStyle:(NSDatePickerStyle) style;

/**
 * Sets the selected date and time value.
 * This is the primary method for programmatically setting the date picker's
 * value. The date parameter should contain the desired date and time selection.
 * The picker will update its display to reflect the new value and will send
 * its action message if the value actually changes.
 * The date must fall within any minimum and maximum constraints that have been set.
 */
- (void) setDateValue:(NSDate *) date;

/**
 * Sets the delegate object for the date picker.
 * The delegate can receive notifications about date picker events and customize
 * certain aspects of behavior. The obj parameter specifies the delegate object
 * to use, or nil to remove the current delegate.
 * Note that this method is a GNUstep extension and does not exist in the standard API.
 */
- (void) setDelegate:(id) obj; /* DOESNT EXIST IN API */

/**
 * Sets whether the date picker draws its background.
 * When flag is YES, the picker fills its bounds with the background color.
 * When flag is NO, the background is transparent and the parent view shows through.
 * This setting affects the visual appearance but not the control functionality.
 */
- (void) setDrawsBackground:(BOOL) flag;

/**
 * Sets the locale used for date and time formatting.
 * The locale determines how dates and times are displayed according to regional
 * and cultural conventions. The locale parameter specifies the NSLocale to use
 * for formatting, or nil to use the system default locale.
 * Changing the locale updates the display format immediately.
 */
- (void) setLocale:(NSLocale *) locale;

/**
 * Sets the maximum selectable date.
 * Users cannot select dates later than the specified maximum. The date parameter
 * sets the latest selectable date, or pass nil to remove any maximum constraint.
 * This constraint helps ensure selected dates fall within meaningful ranges.
 * The current date value will be adjusted if it exceeds the new maximum.
 */
- (void) setMaxDate:(NSDate *) date;

/**
 * Sets the minimum selectable date.
 * Users cannot select dates earlier than the specified minimum. The date parameter
 * sets the earliest selectable date, or pass nil to remove any minimum constraint.
 * This constraint helps ensure selected dates fall within meaningful ranges.
 * The current date value will be adjusted if it falls below the new minimum.
 */
- (void) setMinDate:(NSDate *) date;

/**
 * Sets the text color used for displaying date and time values.
 * The color parameter specifies the color to use for text elements within
 * the date picker. This affects the readability and visual integration with
 * the surrounding interface.
 * Pass nil to use the default text color for the control.
 */
- (void) setTextColor:(NSColor *) color;

/**
 * Sets the time interval for time-based date picker operations.
 * The interval parameter specifies a time interval in seconds that can be
 * used for certain date picker behaviors, such as step increments or
 * granularity of time selection.
 * The exact usage depends on the date picker style and configuration.
 */
- (void) setTimeInterval:(NSTimeInterval) interval;

/**
 * Sets the time zone used for date and time interpretation.
 * The time zone affects how dates and times are displayed and calculated,
 * particularly for applications that work across multiple time zones.
 * The zone parameter specifies the NSTimeZone to use, or nil for the
 * system default time zone.
 * Changing the time zone updates the display to reflect the new zone.
 */
- (void) setTimeZone:(NSTimeZone *) zone;

/**
 * Returns the text color used for displaying date and time values.
 * This is the color used for text elements within the date picker,
 * including numbers, month names, and other textual components.
 * Returns the current text color, or nil if using the default color.
 */
- (NSColor *) textColor;

/**
 * Returns the time interval used for date picker operations.
 * The time interval represents a duration in seconds that may be used
 * for certain date picker behaviors such as step increments or selection
 * granularity, depending on the picker style and configuration.
 * Returns the current time interval setting in seconds.
 */
- (NSTimeInterval) timeInterval;

/**
 * Returns the time zone used for date and time interpretation.
 * The time zone affects how dates and times are displayed and calculated,
 * which is important for applications that work across multiple time zones
 * or need to display times in specific regions.
 * Returns the NSTimeZone object currently in use, or nil for the system default.
 */
- (NSTimeZone *) timeZone;

@end

#endif
#endif /* _GNUstep_H_NSDatePicker */
