/**
   Public serialization API for Native Interface Format files.
*/

#ifndef _GNUstep_H_GSNixSerialization
#define _GNUstep_H_GSNixSerialization

#import <AppKit/AppKitDefines.h>
#import <Foundation/NSObject.h>

@class NSArray;
@class NSData;
@class NSDictionary;
@class NSMapTable;
@class NSString;

APPKIT_EXPORT_CLASS
@interface GSNixSerialization : NSObject

+ (NSString *) identifierForObject: (id)object;
+ (void) setIdentifier: (NSString *)identifier forObject: (id)object;

/** Metadata used when a design tool substitutes a custom class's superclass. */
+ (NSString *) intendedClassNameForObject: (id)object;
+ (NSString *) designSuperclassNameForObject: (id)object;
+ (void) setIntendedClassName: (NSString *)className
         designSuperclassName: (NSString *)superclassName
                    forObject: (id)object;
+ (NSDictionary *) preservedPropertiesForObject: (id)object;
+ (void) setPreservedProperties: (NSDictionary *)properties
                       forObject: (id)object;
+ (NSArray *) preservedConnectionsForObject: (id)object;
+ (void) setPreservedConnections: (NSArray *)connections
                        forObject: (id)object;

/**
 * Encode an interface object graph as an XML NIX property list.
 *
 * By default the writer discovers persistent keys by matching setFoo: methods
 * with foo or isFoo getters. It does not use Objective-C property metadata.
 * keyValuePairs optionally maps a class name to a dictionary whose keys are
 * NIX property names and whose values are KVC keys on the object. An explicit
 * class entry replaces inference for methods declared by that class; inherited
 * classes are still handled independently. First occurrences are
 * emitted as nested definitions and subsequent occurrences as references.
 *
 * Each optional connection dictionary contains kind, source, destination and
 * label. Source and destination are objects in the encoded graph; the strings
 * "owner" and "application" select the two reserved external objects.
 *
 * On failure nil is returned. If errorDescription is non-NULL, the caller
 * owns the returned error string and must release it.
 */
+ (NSData *) dataWithTopLevelObjects: (NSArray *)topLevelObjects
                       keyValuePairs: (NSDictionary *)keyValuePairs
                         connections: (NSArray *)connections
                    errorDescription: (NSString **)errorDescription;

/**
 * Full form with class-specific exclusions. excludedKeys maps class names to
 * arrays of inferred NIX keys that must not be persisted. Exclusions are
 * cumulative through the inheritance chain. Unsupported inferred values make
 * serialization fail rather than being silently omitted.
 */
+ (NSData *) dataWithTopLevelObjects: (NSArray *)topLevelObjects
                       keyValuePairs: (NSDictionary *)keyValuePairs
                        excludedKeys: (NSDictionary *)excludedKeys
                         connections: (NSArray *)connections
                    errorDescription: (NSString **)errorDescription;

/** Full form with an optional identity-keyed object-to-string ID map. */
+ (NSData *) dataWithTopLevelObjects: (NSArray *)topLevelObjects
                       keyValuePairs: (NSDictionary *)keyValuePairs
                        excludedKeys: (NSDictionary *)excludedKeys
                         identifiers: (NSMapTable *)identifiers
                         connections: (NSArray *)connections
                    errorDescription: (NSString **)errorDescription;

/**
 * Compatibility convenience method. Each name in a class's propertyKeys
 * array is used as both the NIX property name and the KVC key.
 */
+ (NSData *) dataWithTopLevelObjects: (NSArray *)topLevelObjects
                        propertyKeys: (NSDictionary *)propertyKeys
                         connections: (NSArray *)connections
                    errorDescription: (NSString **)errorDescription;

@end

#endif
