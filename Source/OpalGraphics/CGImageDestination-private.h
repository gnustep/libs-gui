#include "CoreGraphics/CGImageDestination.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSSet.h>

@interface CGImageDestination : NSObject
{
}

+ (void) registerDestinationClass: (Class)cls;
+ (NSArray*) destinationClasses;
+ (Class) destinationClassForType: (NSString*)type;

+ (NSArray *)typeIdentifiers;
- (id) initWithDataConsumer: (CGDataConsumerRef)consumer
                       type: (CFStringRef)type
                      count: (size_t)count
                    options: (CFDictionaryRef)opts;
- (void) setProperties: (CFDictionaryRef)properties;
- (void) addImage: (CGImageRef)img properties: (CFDictionaryRef)properties;
- (bool) finalize;

@end