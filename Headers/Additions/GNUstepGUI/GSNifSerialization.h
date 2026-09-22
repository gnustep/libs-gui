/**
   Public serialization API for Native Interface Format files.
*/

#ifndef _GNUstep_H_GSNifSerialization
#define _GNUstep_H_GSNifSerialization

#import <AppKit/AppKitDefines.h>
#import <Foundation/NSObject.h>

@class NSArray;
@class NSData;
@class NSDictionary;
@class NSString;

APPKIT_EXPORT_CLASS
@interface GSNifSerialization : NSObject

/**
 * Encode an interface object graph as an XML NIF property list.
 *
 * propertyKeys maps a class name to the property names that form its archive
 * representation.  A superclass entry is used when the concrete class has no
 * entry.  Values are read using key-value coding.  First occurrences are
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
                        propertyKeys: (NSDictionary *)propertyKeys
                         connections: (NSArray *)connections
                    errorDescription: (NSString **)errorDescription;

@end

#endif
