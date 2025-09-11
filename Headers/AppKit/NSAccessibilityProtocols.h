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

#if OS_API_VERSION(MAC_OS_X_VERSION_10_10, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@protocol NSAccessibilityElement <NSObject>
- (NSRect)accessibilityFrame;
- (NSString *)accessibilityIdentifier;
- (id)accessibilityParent;
- (BOOL)isAccessibilityFocused;
@end

@protocol NSAccessibilityButton <NSAccessibilityElement>
- (NSString *)accessibilityLabel;
- (BOOL)accessibilityPerformPress;
@end

@protocol NSAccessibilitySwitch <NSAccessibilityButton>
- (BOOL) accessibilityPerformDecrement;
- (BOOL) accessibilityPerformIncrement;
- (NSString *) accessibilityValue;
@end

@protocol NSAccessibilityLoadingToken
@end

@protocol NSAccessibilityGroup <NSAccessibilityElement>
@end

@protocol NSAccessibilityRadioButton <NSAccessibilityButton>
@end

@protocol NSAccessibilityCheckBox <NSAccessibilityButton>
@end

@protocol NSAccessibilityStaticText <NSAccessibilityElement>
@end

@protocol NSAccessibilityNavigableStaticText <NSAccessibilityStaticText>
@end

@protocol NSAccessibilityProgressIndicator <NSAccessibilityGroup>
@end

@protocol NSAccessibilityStepper <NSAccessibilityElement>
@end

@protocol NSAccessibilitySlider <NSAccessibilityElement>
@end

@protocol NSAccessibilityImage <NSAccessibilityElement>
@end

@protocol NSAccessibilityContainsTransientUI <NSAccessibilityElement>
@end

@protocol NSAccessibilityRow;

@protocol NSAccessibilityTable <NSAccessibilityGroup>
@end

@protocol NSAccessibilityOutline <NSAccessibilityTable>
@end

@protocol NSAccessibilityList <NSAccessibilityTable>
@end

@protocol NSAccessibilityRow <NSAccessibilityGroup>
@end

@protocol NSAccessibilityLayoutArea <NSAccessibilityGroup>
@end

@protocol NSAccessibilityLayoutItem <NSAccessibilityGroup>
@end

@protocol NSAccessibilityElementLoading <NSObject>
@end

@protocol NSAccessibility <NSObject>
@end

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSAccessibilityProtocols_h_GNUSTEP_GUI_INCLUDE */

