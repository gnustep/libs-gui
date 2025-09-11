/* Definition of class NSFontCollection
   Copyright (C) 2019 Free Software Foundation, Inc.

   By: Gregory John Casamento
   Date: Tue Dec 10 11:51:33 EST 2019

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

#ifndef _NSFontCollection_h_GNUSTEP_GUI_INCLUDE
#define _NSFontCollection_h_GNUSTEP_GUI_INCLUDE

#import <Foundation/NSObject.h>
#import <AppKit/AppKitDefines.h>

#if OS_API_VERSION(MAC_OS_X_VERSION_10_7, GS_API_LATEST)

#if	defined(__cplusplus)
extern "C" {
#endif

@class NSFontDescriptor, NSLocale, NSError, NSArray, NSMutableArray, NSDictionary, NSMutableDictionary;

/**
 * Visibility levels for font collections.
 * These flags determine where font collections are visible and accessible
 * within the system hierarchy.
 */
enum {
    /** Font collection is visible only within the current process */
    NSFontCollectionVisibilityProcess = (1UL << 0),
    /** Font collection is visible to the current user across all applications */
    NSFontCollectionVisibilityUser = (1UL << 1),
    /** Font collection is visible system-wide to all users */
    NSFontCollectionVisibilityComputer = (1UL << 2)
};
typedef NSUInteger NSFontCollectionVisibility;

/**
 * Type for font collection matching option keys.
 * These keys are used in dictionaries to specify options for font matching operations.
 */
typedef NSString* NSFontCollectionMatchingOptionKey;

/**
 * Option to include disabled fonts in collection results.
 * When this option is set, fonts that are currently disabled in the system
 * will still be included in the collection's matching results.
 */
APPKIT_EXPORT NSFontCollectionMatchingOptionKey const NSFontCollectionIncludeDisabledFontsOption;

/**
 * Option to remove duplicate fonts from collection results.
 * When this option is set, the collection will filter out fonts that appear
 * multiple times, keeping only unique entries in the results.
 */
APPKIT_EXPORT NSFontCollectionMatchingOptionKey const NSFontCollectionRemoveDuplicatesOption;

/**
 * Option to prevent automatic font activation during matching.
 * When this option is set, the system will not automatically activate fonts
 * that might be needed but are not currently active.
 */
APPKIT_EXPORT NSFontCollectionMatchingOptionKey const NSFontCollectionDisallowAutoActivationOption;

/**
 * Type for font collection names.
 * Font collection names are string identifiers used to reference
 * saved or standard font collections throughout the system.
 */
typedef NSString* NSFontCollectionName;

/**
 * <title>NSFontCollection</title>
 * <abstract>Manages collections of font descriptors for organized font access</abstract>
 *
 * NSFontCollection provides a way to organize and manage groups of fonts through
 * collections of font descriptors. It allows applications to create, store, and
 * retrieve sets of fonts based on various criteria such as family, style, or
 * custom requirements.
 *
 * Font collections can be created from explicit lists of font descriptors,
 * from all available fonts in the system, or filtered by locale-specific
 * requirements. The collections support sophisticated matching operations
 * that can find fonts meeting specific criteria while respecting various
 * filtering options.
 *
 * Collections can be saved and managed at different visibility levels:
 * process-local, user-specific, or system-wide. This enables sharing of
 * font collections across applications and users while maintaining appropriate
 * access controls.
 *
 * The class supports both immutable collections (NSFontCollection) and
 * mutable variants (NSMutableFontCollection) for dynamic modification of
 * font sets. Collections can include both query descriptors (fonts to include)
 * and exclusion descriptors (fonts to explicitly exclude) for fine-grained
 * control over the final font set.
 *
 * Font collections are commonly used in font panels, document templates,
 * style systems, and any application that needs to provide curated sets
 * of fonts to users while maintaining consistency and organization.
 */
APPKIT_EXPORT_CLASS
@interface NSFontCollection : NSObject <NSCopying, NSMutableCopying, NSCoding>
{
  NSMutableDictionary *_fontCollectionDictionary;
}

// Initializers...

/**
 * Creates a font collection from an array of font descriptors.
 * This method creates a new font collection that contains fonts matching
 * the provided descriptors. The queryDescriptors parameter specifies an
 * array of NSFontDescriptor objects that define the criteria for fonts
 * to include in the collection.
 * Returns a new font collection containing fonts that match the specified descriptors.
 */
+ (NSFontCollection *) fontCollectionWithDescriptors: (NSArray *)queryDescriptors;

/**
 * Creates a font collection containing all available fonts in the system.
 * This method creates a comprehensive collection that includes every font
 * currently available to the application, regardless of family, style, or
 * other characteristics. This is useful for providing complete font access
 * or as a starting point for filtering operations.
 * Returns a new font collection containing all system fonts.
 */
+ (NSFontCollection *) fontCollectionWithAllAvailableDescriptors;

/**
 * Creates a font collection filtered by locale-specific requirements.
 * This method creates a collection containing fonts that are appropriate
 * for the specified locale, taking into account language-specific character
 * sets, writing systems, and cultural font preferences. The locale parameter
 * specifies the target locale for font selection.
 * Returns a new font collection with fonts suitable for the given locale.
 */
+ (NSFontCollection *) fontCollectionWithLocale: (NSLocale *)locale;

/**
 * Makes a font collection visible in the system with the specified name.
 * This method saves a font collection so it can be accessed by name at the
 * specified visibility level. The collection parameter is the font collection
 * to save, name provides the identifier for later retrieval, visibility
 * determines where the collection is accessible (process, user, or system-wide),
 * and error receives any error information if the operation fails.
 * Returns YES if the collection was successfully saved, NO if an error occurred.
 */
+ (BOOL) showFontCollection: (NSFontCollection *)collection
                   withName: (NSFontCollectionName)name
                 visibility: (NSFontCollectionVisibility)visibility
                      error: (NSError **)error;

/**
 * Hides a previously saved font collection from system visibility.
 * This method removes a saved font collection from the specified visibility
 * level, making it no longer accessible by name. The name parameter specifies
 * the collection to remove, visibility indicates where to remove it from,
 * and error receives any error information if the operation fails.
 * Returns YES if the collection was successfully hidden, NO if an error occurred.
 */
+ (BOOL) hideFontCollectionWithName: (NSFontCollectionName)name
                         visibility: (NSFontCollectionVisibility)visibility
                              error: (NSError **)error;

/**
 * Renames an existing font collection.
 * This method changes the name of a saved font collection at the specified
 * visibility level. The name parameter specifies the current name, visibility
 * indicates where the collection is stored, toName provides the new name,
 * and error receives any error information if the operation fails.
 * Returns YES if the collection was successfully renamed, NO if an error occurred.
 */
+ (BOOL) renameFontCollectionWithName: (NSFontCollectionName)name
                           visibility: (NSFontCollectionVisibility)visibility
                               toName: (NSFontCollectionName)name
                                error: (NSError **)error;

/**
 * Returns the names of all available font collections.
 * This method retrieves a list of names for all font collections that are
 * currently accessible to the application, including system, user, and
 * process-local collections.
 * Returns an array of NSFontCollectionName strings identifying available collections.
 */
+ (NSArray *) allFontCollectionNames;

/**
 * Retrieves a font collection by name from any visibility level.
 * This method searches for a font collection with the specified name across
 * all visibility levels (process, user, and system) and returns the first
 * match found. The name parameter specifies the collection to retrieve.
 * Returns the named font collection, or nil if no collection with that name exists.
 */
+ (NSFontCollection *) fontCollectionWithName: (NSFontCollectionName)name;

/**
 * Retrieves a font collection by name from a specific visibility level.
 * This method searches for a font collection with the specified name at
 * the given visibility level only. The name parameter specifies the collection
 * to retrieve, and visibility indicates where to search for it.
 * Returns the named font collection from the specified level, or nil if not found.
 */
+ (NSFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
                                   visibility: (NSFontCollectionVisibility)visibility;


// Descriptors

/**
 * Returns the query descriptors that define fonts to include in the collection.
 * Query descriptors specify the criteria for fonts that should be included
 * in the collection's results. These descriptors define characteristics like
 * font family, weight, style, and other attributes that fonts must match
 * to be considered part of the collection.
 * Returns an array of NSFontDescriptor objects defining inclusion criteria.
 */
- (NSArray *) queryDescriptors;

/**
 * Returns the exclusion descriptors that define fonts to exclude from the collection.
 * Exclusion descriptors specify fonts that should be explicitly removed from
 * the collection's results, even if they would otherwise match the query
 * descriptors. This provides fine-grained control over the final font set.
 * Returns an array of NSFontDescriptor objects defining exclusion criteria.
 */
- (NSArray *) exclusionDescriptors;

/**
 * Returns font descriptors that match the collection's criteria.
 * This method evaluates the collection's query and exclusion descriptors
 * against the available fonts and returns descriptors for fonts that meet
 * the criteria. The results represent the actual fonts included in the collection.
 * Returns an array of NSFontDescriptor objects for matching fonts.
 */
- (NSArray *) matchingDescriptors;

/**
 * Returns font descriptors that match the collection's criteria with additional options.
 * This method performs the same matching as matchingDescriptors but allows
 * additional options to be specified. The options parameter can include keys
 * for including disabled fonts, removing duplicates, or controlling font activation.
 * Returns an array of NSFontDescriptor objects for matching fonts with options applied.
 */
- (NSArray *) matchingDescriptorsWithOptions: (NSDictionary *)options;

/**
 * Returns font descriptors for fonts within a specific family that match the collection.
 * This method filters the collection's matching fonts to include only those
 * from the specified font family. The family parameter specifies the font
 * family name to filter by.
 * Returns an array of NSFontDescriptor objects for matching fonts in the specified family.
 */
- (NSArray *) matchingDescriptorsForFamily: (NSString *)family;

/**
 * Returns font descriptors for fonts within a specific family with additional options.
 * This method combines family filtering with option-based matching. The family
 * parameter specifies the font family to filter by, and options can include
 * settings for disabled fonts, duplicates, and font activation behavior.
 * Returns an array of NSFontDescriptor objects for matching family fonts with options applied.
 */
- (NSArray *) matchingDescriptorsForFamily: (NSString *)family options: (NSDictionary *)options;

@end

/**
 * <title>NSMutableFontCollection</title>
 * <abstract>A mutable version of NSFontCollection for dynamic font collection management</abstract>
 *
 * NSMutableFontCollection extends NSFontCollection to provide methods for
 * dynamically modifying font collections after creation. This allows applications
 * to build and adjust font collections programmatically based on changing
 * requirements or user preferences.
 *
 * The mutable variant supports adding and removing query descriptors, changing
 * exclusion criteria, and updating the collection's font matching behavior
 * without creating entirely new collection objects. This is particularly useful
 * for interactive font selection interfaces, style editors, and applications
 * that need to respond to dynamic font requirements.
 *
 * Like its immutable counterpart, mutable font collections can be saved and
 * retrieved by name at various visibility levels, allowing modified collections
 * to be preserved and shared across application sessions or between applications.
 */
APPKIT_EXPORT_CLASS
@interface NSMutableFontCollection : NSFontCollection

/**
 * Creates a mutable font collection from an array of font descriptors.
 * This method creates a new mutable font collection that can be modified
 * after creation. The queryDescriptors parameter specifies the initial
 * set of font descriptors defining the collection's content.
 * Returns a new mutable font collection with the specified initial descriptors.
 */
+ (NSMutableFontCollection *) fontCollectionWithDescriptors: (NSArray *)queryDescriptors;

/**
 * Creates a mutable font collection containing all available fonts.
 * This method creates a mutable collection that initially contains all
 * system fonts, but can be modified after creation to add filters,
 * exclusions, or other constraints.
 * Returns a new mutable font collection containing all system fonts.
 */
+ (NSMutableFontCollection *) fontCollectionWithAllAvailableDescriptors;

/**
 * Creates a mutable font collection filtered by locale.
 * This method creates a mutable collection with an initial set of fonts
 * appropriate for the specified locale, but allows subsequent modification
 * of the collection's criteria. The locale parameter specifies the target locale.
 * Returns a new mutable font collection suitable for the given locale.
 */
+ (NSMutableFontCollection *) fontCollectionWithLocale: (NSLocale *)locale;

/**
 * Creates a mutable font collection by loading a saved collection by name.
 * This method retrieves a saved font collection and returns it as a mutable
 * collection that can be modified. The name parameter specifies the collection
 * to load from any visibility level.
 * Returns a mutable copy of the named font collection, or nil if not found.
 */
+ (NSMutableFontCollection *) fontCollectionWithName: (NSFontCollectionName)name;

/**
 * Creates a mutable font collection by loading from a specific visibility level.
 * This method retrieves a saved font collection from the specified visibility
 * level and returns it as a mutable collection. The name parameter specifies
 * the collection to load, and visibility indicates where to search.
 * Returns a mutable copy of the named collection from the specified level, or nil if not found.
 */
+ (NSMutableFontCollection *) fontCollectionWithName: (NSFontCollectionName)name
                                          visibility: (NSFontCollectionVisibility)visibility;

/**
 * Returns the query descriptors for the mutable collection.
 * This method returns the current set of query descriptors that define
 * which fonts are included in the collection. The returned array can be
 * used to examine the current inclusion criteria.
 * Returns an array of NSFontDescriptor objects defining current inclusion criteria.
 */
- (NSArray *) queryDescriptors;

/**
 * Sets the query descriptors for the mutable collection.
 * This method replaces the current query descriptors with a new set,
 * changing which fonts are included in the collection. The queryDescriptors
 * parameter specifies the new inclusion criteria.
 */
- (void) setQueryDescriptors: (NSArray *)queryDescriptors;

/**
 * Returns the exclusion descriptors for the mutable collection.
 * This method returns the current set of exclusion descriptors that define
 * which fonts are explicitly excluded from the collection, even if they
 * would otherwise match the query descriptors.
 * Returns an array of NSFontDescriptor objects defining current exclusion criteria.
 */
- (NSArray *) exclusionDescriptors;

/**
 * Sets the exclusion descriptors for the mutable collection.
 * This method replaces the current exclusion descriptors with a new set,
 * changing which fonts are explicitly excluded from the collection.
 * The exclusionDescriptors parameter specifies the new exclusion criteria.
 */
- (void) setExclusionDescriptors: (NSArray *)exclusionDescriptors;

/**
 * Adds additional query descriptors to the collection.
 * This method expands the collection's inclusion criteria by adding new
 * query descriptors to the existing set. Fonts matching any of the descriptors
 * (existing or new) will be included in the collection. The descriptors
 * parameter specifies the additional criteria to add.
 */
- (void)addQueryForDescriptors: (NSArray *)descriptors;

/**
 * Removes query descriptors from the collection.
 * This method narrows the collection's inclusion criteria by removing
 * specific query descriptors from the existing set. Fonts that only
 * matched the removed descriptors will no longer be included in the
 * collection. The descriptors parameter specifies the criteria to remove.
 */
- (void)removeQueryForDescriptors: (NSArray *)descriptors;

@end

// NSFontCollectionDidChangeNotification

/**
 * Notification posted when font collections change.
 * This notification is sent when font collections are added, removed, renamed,
 * or otherwise modified in the system. Applications can observe this notification
 * to update their font collection displays or invalidate cached collection data.
 */
APPKIT_EXPORT NSString * const NSFontCollectionDidChangeNotification;

// Notification user info dictionary keys

/**
 * Type for user info dictionary keys in font collection notifications.
 * These keys are used in the userInfo dictionary of NSFontCollectionDidChangeNotification
 * to provide details about what changed in the font collection system.
 */
typedef NSString * NSFontCollectionUserInfoKey;

/**
 * User info key indicating the type of action that occurred.
 * The value associated with this key describes what kind of change happened
 * to the font collection (shown, hidden, renamed). The value will be one
 * of the NSFontCollectionActionTypeKey constants.
 */
APPKIT_EXPORT NSFontCollectionUserInfoKey const NSFontCollectionActionKey;

/**
 * User info key containing the name of the affected font collection.
 * The value associated with this key is the name of the font collection
 * that was modified. For rename operations, this is the new name.
 */
APPKIT_EXPORT NSFontCollectionUserInfoKey const NSFontCollectionNameKey;

/**
 * User info key containing the previous name of a renamed font collection.
 * The value associated with this key is the old name of a font collection
 * that was renamed. This key is only present for rename operations.
 */
APPKIT_EXPORT NSFontCollectionUserInfoKey const NSFontCollectionOldNameKey;

/**
 * User info key indicating the visibility level of the affected collection.
 * The value associated with this key specifies the visibility level
 * (process, user, or system) where the font collection change occurred.
 */
APPKIT_EXPORT NSFontCollectionUserInfoKey const NSFontCollectionVisibilityKey;

// Values for NSFontCollectionAction

/**
 * Type for font collection action identifiers.
 * These constants identify the specific type of action that occurred
 * with a font collection, used as values for the NSFontCollectionActionKey.
 */
typedef NSString * NSFontCollectionActionTypeKey;

/**
 * Action type indicating a font collection was made visible.
 * This action occurs when a font collection is saved or restored to
 * visibility in the system, making it available for use by applications.
 */
APPKIT_EXPORT NSFontCollectionActionTypeKey const NSFontCollectionWasShown;

/**
 * Action type indicating a font collection was hidden.
 * This action occurs when a font collection is removed from system
 * visibility, making it no longer available for use by applications.
 */
APPKIT_EXPORT NSFontCollectionActionTypeKey const NSFontCollectionWasHidden;

/**
 * Action type indicating a font collection was renamed.
 * This action occurs when a saved font collection's name is changed,
 * affecting how it can be accessed by applications.
 */
APPKIT_EXPORT NSFontCollectionActionTypeKey const NSFontCollectionWasRenamed;

// Standard named collections

/**
 * Name for the standard collection containing all available fonts.
 * This is a predefined font collection that includes every font currently
 * available in the system, providing comprehensive access to the font library.
 */
APPKIT_EXPORT NSFontCollectionName const NSFontCollectionAllFonts;

/**
 * Name for the standard user font collection.
 * This is a predefined collection that contains fonts specifically
 * associated with or preferred by the current user, often customizable
 * through system preferences or font management tools.
 */
APPKIT_EXPORT NSFontCollectionName const NSFontCollectionUser;

/**
 * Name for the standard favorites font collection.
 * This is a predefined collection that contains fonts marked as favorites
 * by the user, providing quick access to preferred fonts for common use.
 */
APPKIT_EXPORT NSFontCollectionName const NSFontCollectionFavorites;

/**
 * Name for the standard recently used fonts collection.
 * This is a predefined collection that contains fonts that have been
 * recently used by applications, helping users quickly access fonts
 * they've worked with recently.
 */
APPKIT_EXPORT NSFontCollectionName const NSFontCollectionRecentlyUsed;

#if	defined(__cplusplus)
}
#endif

#endif	/* GS_API_MACOSX */

#endif	/* _NSFontCollection_h_GNUSTEP_GUI_INCLUDE */

