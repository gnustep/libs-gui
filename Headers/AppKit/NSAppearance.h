/* Definition of class NSAppearance
   Copyright (C) 2020 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: Wed Jan 15 07:03:39 EST 2020

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#ifndef _NSAppearance_h_GNUSTEP_GUI_INCLUDE
#define _NSAppearance_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>
#import <Foundation/NSBundle.h>
#import <AppKit/AppKitDefines.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_9, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

typedef NSString* NSAppearanceName;

APPKIT_EXPORT_CLASS
@interface NSAppearance : NSObject <NSCoding>
{
  NSString *_name;
  BOOL _allowsVibrancy;
  NSAppearanceName _currentAppearance;
}

/**
 * Creates and returns an NSAppearance object for the given name.
 * Takes a string specifying the name of the appearance.
 * Returns an NSAppearance instance corresponding to the specified name.
 */
+ (instancetype) appearanceNamed: (NSString *)name;

/**
 * Initializes a new NSAppearance object with the given name and bundle.
 * Takes a string for the appearance name and a bundle where the appearance can be found.
 * Returns an initialized NSAppearance instance.
 */
- (instancetype) initWithAppearanceNamed: (NSString *)name bundle: (NSBundle *)bundle;

/**
 * Gets the name of the appearance.
 * Returns a string representing the appearance name.
 */
- (NSString *) name;

/**
  * Determining the most appropriate appearance, returns the name of the best
  * match.
  */
- (NSAppearanceName) bestMatchFromAppearancesWithNames: (NSArray *)appearances;

/**
 * Setting the current appearance
 */
+ (void) setCurrentAppearance: (NSAppearance *)appearance;

/**
 * Getting the current appearance
 */
+ (NSAppearance *) currentAppearance;

/**
 * Returns YES if the appearance allows vibrancy
 */
- (BOOL) allowsVibrancy;
  
@end

APPKIT_EXPORT NSAppearanceName const NSAppearanceNameAqua;
APPKIT_EXPORT NSAppearanceName const NSAppearanceNameDarkAqua;
APPKIT_EXPORT NSAppearanceName const NSAppearanceNameVibrantLight;
APPKIT_EXPORT NSAppearanceName const NSAppearanceNameVibrantDark;
APPKIT_EXPORT NSAppearanceName const NSAppearanceNameAccessibilityHighContrastAqua;
APPKIT_EXPORT NSAppearanceName const NSAppearanceNameAccessibilityHighContrastDarkAqua;
APPKIT_EXPORT NSAppearanceName const NSAppearanceNameAccessibilityHighContrastVibrantLight;
APPKIT_EXPORT NSAppearanceName const NSAppearanceNameAccessibilityHighContrastVibrantDark;
APPKIT_EXPORT NSAppearanceName const NSAppearanceNameLightContent;


#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

@protocol NSAppearanceCustomization
#if OS_API_VERSION(MAC_OS_X_VERSION_10_0, GS_API_LATEST)
@required
#if GS_HAS_DECLARED_PROPERTIES
/** Set the appearance of the reciever. Default is nil. */
@property(retain) NSAppearance* appearance;
/** Get the appearance of the reciever. If self.appearance is nil, then go up the 
    view hierarchy to find an appearance. If still nil, go up to NSApp. If still nil,
    go up to [NSAppearance currentAppearance]. */
@property(readonly, retain) NSAppearance* effectiveAppearance;
#else
- (NSAppearance*) appearance;
- (void) setAppearance: (NSAppearance*) appearance;
- (NSAppearance*) effectiveAppearance;
#endif
#endif
@end

#endif	/* _NSAppearance_h_GNUSTEP_GUI_INCLUDE */

