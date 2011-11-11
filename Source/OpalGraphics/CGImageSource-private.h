#include "CoreGraphics/CGImageSource.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSSet.h>

@interface CGImageSource : NSObject
{
}

+ (void) registerSourceClass: (Class)cls;
+ (NSArray*) sourceClasses;

+ (NSArray *)typeIdentifiers;
- (id)initWithProvider: (CGDataProviderRef)provider;
- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts;
- (NSDictionary*)propertiesWithOptions: (NSDictionary*)opts atIndex: (size_t)index;
- (size_t)count;
- (CGImageRef)createImageAtIndex: (size_t)index options: (NSDictionary*)opts;
- (CGImageRef)createThumbnailAtIndex: (size_t)index options: (NSDictionary*)opts;
- (CGImageSourceStatus)status;
- (CGImageSourceStatus)statusAtIndex: (size_t)index;
- (NSString*)type;
- (void)updateDataProvider: (CGDataProviderRef)provider finalUpdate: (bool)finalUpdate;

@end