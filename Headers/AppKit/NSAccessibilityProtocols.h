/** <title>NSAccessibilityProtocols</title>

    <abstract>Protocol definitions for accessibility support in AppKit</abstract>

    This header defines the formal protocols that objects must implement to
    participate in the accessibility system. These protocols enable assistive
    technologies such as screen readers, voice control software, and other
    accessibility tools to interact with AppKit user interface elements.

    The accessibility protocols defined here provide:
    * Standard methods for exposing UI element properties and state
    * Actions that can be performed on accessible elements
    * Hierarchical navigation between accessibility elements
    * Text access and manipulation capabilities
    * Value and selection state reporting

    By implementing these protocols, custom views and controls can be made
    accessible to users with disabilities. The protocols follow the
    accessibility guidelines established by Apple's accessibility framework
    and provide compatibility with system accessibility services.

    Key protocols include element identification, action handling, value
    access, and hierarchical navigation support for complex UI structures.

    Copyright (C) 2020 Free Software Foundation, Inc.

    By: Gregory John Casamento
    Date: Sun Apr 19 09:56:39 EDT 2020

    This file is part of the GNUstep Library.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free
    Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110 USA.
*/

#ifndef _NSAccessibilityProtocols_h_GNUSTEP_GUI_INCLUDE
#define _NSAccessibilityProtocols_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSRange.h>

@class NSArray, NSString, NSAttributedString, NSNumber, NSDictionary, NSError;

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@protocol NSAccessibilityElement <NSObject>
- (NSRect)accessibilityFrame;
- (NSString *)accessibilityIdentifier;
- (id)accessibilityParent;
- (BOOL)isAccessibilityFocused;

// Additional core accessibility methods
- (NSString *)accessibilityRole;
- (NSString *)accessibilityRoleDescription;
- (NSString *)accessibilitySubrole;
- (NSString *)accessibilityLabel;
- (NSString *)accessibilityTitle;
- (id)accessibilityValue;
- (NSString *)accessibilityHelp;
- (BOOL)isAccessibilityEnabled;
- (NSArray *)accessibilityChildren;
- (NSArray *)accessibilitySelectedChildren;
- (NSArray *)accessibilityVisibleChildren;
- (id)accessibilityWindow;
- (id)accessibilityTopLevelUIElement;
- (NSPoint)accessibilityActivationPoint;
- (NSString *)accessibilityURL;
- (NSNumber *)accessibilityIndex;

// Element hierarchy and navigation
- (NSArray *)accessibilityCustomRotors;
- (BOOL)accessibilityPerformEscape;
- (NSArray *)accessibilityCustomActions;

// State and properties
- (BOOL)isAccessibilityElement;
- (void)setAccessibilityElement:(BOOL)isElement;
- (void)setAccessibilityFrame:(NSRect)frame;
- (void)setAccessibilityParent:(id)parent;
- (void)setAccessibilityFocused:(BOOL)focused;
@end

@protocol NSAccessibilityButton <NSAccessibilityElement>
- (NSString *)accessibilityLabel;
- (BOOL)accessibilityPerformPress;

// Button-specific properties and actions
- (NSString *)accessibilityTitle;
- (BOOL)isAccessibilitySelected;
- (void)setAccessibilitySelected:(BOOL)selected;
- (NSString *)accessibilityPlaceholderValue;
- (void)setAccessibilityPlaceholderValue:(NSString *)placeholderValue;
@end

@protocol NSAccessibilitySwitch <NSAccessibilityButton>
- (BOOL)accessibilityPerformDecrement;
- (BOOL)accessibilityPerformIncrement;
- (NSString *)accessibilityValue;

// Switch-specific properties
- (id)accessibilityMinValue;
- (id)accessibilityMaxValue;
- (NSArray *)accessibilityAllowedValues;
- (NSString *)accessibilityValueDescription;
- (void)setAccessibilityValue:(id)value;
@end

@protocol NSAccessibilityLoadingToken
// Marker protocol for loading tokens used in custom rotors
// No methods required - this is a marker protocol
@end

@protocol NSAccessibilityGroup <NSAccessibilityElement>
// Group container properties and navigation
- (NSArray *)accessibilityChildren;
- (NSArray *)accessibilitySelectedChildren;
- (NSArray *)accessibilityVisibleChildren;
- (NSString *)accessibilityLabel;
- (NSString *)accessibilityTitle;
- (NSString *)accessibilityHelp;

// Group-specific methods
- (NSArray *)accessibilityContents;
- (BOOL)isAccessibilityExpanded;
- (void)setAccessibilityExpanded:(BOOL)expanded;
- (NSString *)accessibilityOrientation;
@end

@protocol NSAccessibilityRadioButton <NSAccessibilityButton>
// Radio button specific properties
- (BOOL)isAccessibilitySelected;
- (void)setAccessibilitySelected:(BOOL)selected;
- (NSString *)accessibilityValue;
- (void)setAccessibilityValue:(id)value;

// Radio group navigation
- (NSArray *)accessibilityLinkedUIElements;
- (void)setAccessibilityLinkedUIElements:(NSArray *)linkedElements;
@end

@protocol NSAccessibilityCheckBox <NSAccessibilityButton>
// Checkbox state and properties
- (NSNumber *)accessibilityValue;
- (void)setAccessibilityValue:(id)value;
- (id)accessibilityMinValue;
- (id)accessibilityMaxValue;

// Mixed state support (for tri-state checkboxes)
- (BOOL)isAccessibilitySelected;
- (void)setAccessibilitySelected:(BOOL)selected;
- (NSString *)accessibilityValueDescription;
@end

@protocol NSAccessibilityStaticText <NSAccessibilityElement>
// Text content and properties
- (NSString *)accessibilityValue;
- (NSString *)accessibilityLabel;
- (NSString *)accessibilityTitle;
- (NSAttributedString *)accessibilityAttributedStringForRange:(NSRange)range;
- (NSRange)accessibilityRangeForPosition:(NSPoint)point;
- (NSRange)accessibilityRangeForIndex:(NSInteger)index;
- (NSRect)accessibilityFrameForRange:(NSRange)range;
- (NSString *)accessibilityStringForRange:(NSRange)range;

// Text attributes
- (id)accessibilityAttributeValue:(NSString *)attribute forParameter:(id)parameter;
- (NSArray *)accessibilityParameterizedAttributeNames;
@end

@protocol NSAccessibilityNavigableStaticText <NSAccessibilityStaticText>
// Text navigation and manipulation
- (NSRange)accessibilityVisibleCharacterRange;
- (void)setAccessibilityVisibleCharacterRange:(NSRange)range;
- (NSInteger)accessibilityNumberOfCharacters;
- (NSInteger)accessibilityInsertionPointLineNumber;
- (NSRange)accessibilitySelectedTextRange;
- (void)setAccessibilitySelectedTextRange:(NSRange)range;
- (NSArray *)accessibilitySelectedTextRanges;
- (void)setAccessibilitySelectedTextRanges:(NSArray *)ranges;

// Line and word navigation
- (NSRange)accessibilityRangeForLine:(NSInteger)line;
- (NSInteger)accessibilityLineForIndex:(NSInteger)index;
- (NSRange)accessibilityStyleRangeForIndex:(NSInteger)index;
@end

@protocol NSAccessibilityProgressIndicator <NSAccessibilityGroup>
// Progress indicator values and properties
- (NSNumber *)accessibilityValue;
- (void)setAccessibilityValue:(id)value;
- (NSNumber *)accessibilityMinValue;
- (NSNumber *)accessibilityMaxValue;
- (NSString *)accessibilityValueDescription;
- (void)setAccessibilityValueDescription:(NSString *)valueDescription;

// Progress indicator specific properties
- (NSString *)accessibilityOrientation;
- (BOOL)isAccessibilityIndeterminate;
- (void)setAccessibilityIndeterminate:(BOOL)indeterminate;
@end

@protocol NSAccessibilityStepper <NSAccessibilityElement>
// Stepper value control
- (NSNumber *)accessibilityValue;
- (void)setAccessibilityValue:(id)value;
- (NSNumber *)accessibilityMinValue;
- (NSNumber *)accessibilityMaxValue;
- (NSString *)accessibilityValueDescription;

// Stepper actions
- (BOOL)accessibilityPerformIncrement;
- (BOOL)accessibilityPerformDecrement;

// Stepper components
- (id)accessibilityIncrementButton;
- (id)accessibilityDecrementButton;
@end

@protocol NSAccessibilitySlider <NSAccessibilityElement>
// Slider value control
- (NSNumber *)accessibilityValue;
- (void)setAccessibilityValue:(id)value;
- (NSNumber *)accessibilityMinValue;
- (NSNumber *)accessibilityMaxValue;
- (NSString *)accessibilityValueDescription;
- (void)setAccessibilityValueDescription:(NSString *)valueDescription;

// Slider orientation and properties
- (NSString *)accessibilityOrientation;
- (NSArray *)accessibilityAllowedValues;

// Slider actions
- (BOOL)accessibilityPerformIncrement;
- (BOOL)accessibilityPerformDecrement;
@end

@protocol NSAccessibilityImage <NSAccessibilityElement>
// Image description and properties
- (NSString *)accessibilityLabel;
- (NSString *)accessibilityTitle;
- (NSString *)accessibilityValue;
- (NSString *)accessibilityHelp;
- (NSString *)accessibilityRoleDescription;

// Image-specific properties
- (NSString *)accessibilityURL;
- (NSString *)accessibilityDescription;
- (NSString *)accessibilityFilename;
@end

@protocol NSAccessibilityContainsTransientUI <NSAccessibilityElement>
// Transient UI management
- (NSArray *)accessibilityChildren;
- (NSArray *)accessibilityContents;
- (BOOL)isAccessibilityAlternateUIVisible;
- (void)setAccessibilityAlternateUIVisible:(BOOL)alternateUIVisible;

// Transient UI actions
- (BOOL)accessibilityPerformShowAlternateUI;
- (BOOL)accessibilityPerformShowDefaultUI;
- (BOOL)accessibilityPerformCancel;
@end

@protocol NSAccessibilityRow;

@protocol NSAccessibilityTable <NSAccessibilityGroup>
// Table structure and navigation
- (NSArray *)accessibilityRows;
- (NSArray *)accessibilityColumns;
- (NSArray *)accessibilityVisibleRows;
- (NSArray *)accessibilityVisibleColumns;
- (NSArray *)accessibilitySelectedRows;
- (NSArray *)accessibilitySelectedColumns;
- (NSArray *)accessibilitySelectedCells;

// Table properties
- (NSNumber *)accessibilityRowCount;
- (NSNumber *)accessibilityColumnCount;
- (NSString *)accessibilityLabel;
- (NSString *)accessibilityColumnHeaderUIElements;
- (NSString *)accessibilityRowHeaderUIElements;

// Table cell access
- (id)accessibilityCellForColumn:(NSInteger)column row:(NSInteger)row;
- (NSArray *)accessibilityVisibleCells;
@end

@protocol NSAccessibilityOutline <NSAccessibilityTable>
// Outline-specific properties and navigation
- (NSArray *)accessibilityDisclosedRows;
- (id)accessibilityDisclosedByRow;
- (NSNumber *)accessibilityDisclosureLevel;
- (BOOL)isAccessibilityDisclosing;
- (void)setAccessibilityDisclosing:(BOOL)disclosing;

// Outline actions
- (BOOL)accessibilityPerformShowMenu;
- (NSArray *)accessibilityChildren;
- (NSArray *)accessibilitySelectedChildren;
@end

@protocol NSAccessibilityList <NSAccessibilityTable>
// List-specific properties
- (NSArray *)accessibilityChildren;
- (NSArray *)accessibilitySelectedChildren;
- (NSArray *)accessibilityVisibleChildren;
- (NSString *)accessibilityOrientation;

// List navigation and selection
- (BOOL)isAccessibilitySelected;
- (void)setAccessibilitySelected:(BOOL)selected;
- (NSArray *)accessibilityContents;
- (NSNumber *)accessibilityIndex;
@end

@protocol NSAccessibilityRow <NSAccessibilityGroup>
// Row properties and navigation  
- (NSNumber *)accessibilityIndex;
- (BOOL)isAccessibilitySelected;
- (void)setAccessibilitySelected:(BOOL)selected;
- (NSArray *)accessibilityChildren;
- (NSArray *)accessibilityVisibleChildren;

// Row-specific properties
- (NSString *)accessibilityLabel;
- (NSString *)accessibilityValue;
- (id)accessibilityDisclosedByRow;
- (NSNumber *)accessibilityDisclosureLevel;
- (BOOL)isAccessibilityDisclosing;
- (void)setAccessibilityDisclosing:(BOOL)disclosing;
- (NSArray *)accessibilityDisclosedRows;
@end

@protocol NSAccessibilityLayoutArea <NSAccessibilityGroup>
// Layout area properties and management
- (NSArray *)accessibilityChildren;
- (NSString *)accessibilityLabel;
- (NSString *)accessibilityRole;
- (NSString *)accessibilityRoleDescription;
- (NSRect)accessibilityFrame;

// Layout-specific properties
- (NSString *)accessibilityOrientation;
- (NSArray *)accessibilityContents;
- (NSArray *)accessibilitySelectedChildren;
@end

@protocol NSAccessibilityLayoutItem <NSAccessibilityGroup>
// Layout item properties and positioning
- (NSRect)accessibilityFrame;
- (void)setAccessibilityFrame:(NSRect)frame;
- (NSString *)accessibilityLabel;
- (NSString *)accessibilityTitle;
- (NSString *)accessibilityValue;

// Layout item specific properties
- (id)accessibilityParent;
- (NSArray *)accessibilityChildren;
- (NSNumber *)accessibilityIndex;
- (NSString *)accessibilityRole;
- (NSString *)accessibilityRoleDescription;
@end

@protocol NSAccessibilityElementLoading <NSObject>
// Element loading for lazy accessibility trees
- (void)accessibilityLoadingCompleted:(NSArray *)loadedElements;
- (void)accessibilityLoadingFailed:(NSError *)error;

// Loading state queries
- (BOOL)isAccessibilityLoading;
- (NSString *)accessibilityLoadingDescription;
@end

@protocol NSAccessibility <NSObject>
// Core accessibility protocol - informal protocol for all accessibility-enabled objects
// This provides the foundational methods that any object can implement

// Essential accessibility methods
- (BOOL)isAccessibilityElement;
- (NSString *)accessibilityRole;
- (NSString *)accessibilitySubrole;
- (NSString *)accessibilityRoleDescription;
- (NSString *)accessibilityLabel;
- (NSString *)accessibilityTitle;
- (NSString *)accessibilityHelp;
- (id)accessibilityValue;
- (NSRect)accessibilityFrame;
- (id)accessibilityParent;
- (NSArray *)accessibilityChildren;
- (BOOL)isAccessibilityFocused;
- (BOOL)isAccessibilityEnabled;

// Hierarchy and navigation
- (NSArray *)accessibilityVisibleChildren;
- (NSArray *)accessibilitySelectedChildren;
- (id)accessibilityWindow;
- (id)accessibilityTopLevelUIElement;
- (NSPoint)accessibilityActivationPoint;

// Action handling
- (NSArray *)accessibilityActionNames;
- (NSString *)accessibilityActionDescription:(NSString *)action;
- (void)accessibilityPerformAction:(NSString *)action;

// Attribute handling
- (NSArray *)accessibilityAttributeNames;
- (id)accessibilityAttributeValue:(NSString *)attribute;
- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute;
- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute;

// Parameterized attributes
- (NSArray *)accessibilityParameterizedAttributeNames;
- (id)accessibilityAttributeValue:(NSString *)attribute forParameter:(id)parameter;

// Hit testing and focus
- (id)accessibilityHitTest:(NSPoint)point;
- (id)accessibilityFocusedUIElement;

// Notifications
- (void)accessibilityPostNotification:(NSString *)notification;
- (void)accessibilityPostNotificationWithUserInfo:(NSString *)notification userInfo:(NSDictionary *)userInfo;

// Index and identification
- (NSNumber *)accessibilityIndex;
- (NSString *)accessibilityIdentifier;
@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSAccessibilityProtocols_h_GNUSTEP_GUI_INCLUDE */

