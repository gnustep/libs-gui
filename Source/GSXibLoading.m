#import <Foundation/NSObject.h>
#import <Foundation/NSKeyedArchiver.h>
#import "GNUstepGUI/GSXibElement.h"
#import "GNUstepGUI/GSXibLoading.h"

@interface IBAccessibilityAttribute : NSObject <NSCoding>
@end

@interface IBNSLayoutConstraint : NSObject <NSCoding>
@end

@interface IBLayoutConstant : NSObject <NSCoding>
@end

@implementation IBUserDefinedRuntimeAttribute
 
 - (void) encodeWithCoder: (NSCoder *)coder
 {
   if([coder allowsKeyedCoding])
     {
      [coder encodeObject: typeIdentifier forKey: @"typeIdentifier"];
      [coder encodeObject: keyPath forKey: @"keyPath"];
      [coder encodeObject: value forKey: @"value"];
     }
 }

- (id) initWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
    {
      [self setTypeIdentifier: [coder decodeObjectForKey: @"typeIdentifier"]];
      [self setKeyPath: [coder decodeObjectForKey: @"keyPath"]];
      [self setValue: [coder decodeObjectForKey: @"value"]];
    }
  return self;
}

- (void) setTypeIdentifier: (NSString *)type
{
  ASSIGN(typeIdentifier, type);
}

- (NSString *) typeIdentifier
{
  return typeIdentifier;
}

- (void) setKeyPath: (NSString *)kpath
{
  ASSIGN(keyPath, kpath);
}

- (NSString *) keyPath
{
  return keyPath;
}

- (void) setValue: (id)val
{
  ASSIGN(value, val);
}

- (id) value
{
  return value;
}

- (NSString*) description
{
  NSMutableString *description = [[super description] mutableCopy];

  [description appendString: @" <"];
  [description appendFormat: @" type: %@", typeIdentifier];
  [description appendFormat: @" keyPath: %@", keyPath];
  [description appendFormat: @" value: %@", value];
  [description appendString: @">"];
  return AUTORELEASE(description);
}

@end

@implementation IBUserDefinedRuntimeAttributesPlaceholder

- (void) encodeWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
  {
    [coder encodeObject: name forKey: @"IBUserDefinedRuntimeAttributesPlaceholderName"];
    [coder encodeObject: runtimeAttributes forKey: @"userDefinedRuntimeAttributes"];
  }
}

- (id) initWithCoder: (NSCoder *)coder
{
  if([coder allowsKeyedCoding])
  {
    [self setName: [coder decodeObjectForKey: @"IBUserDefinedRuntimeAttributesPlaceholderName"]];
    [self setRuntimeAttributes: [coder decodeObjectForKey: @"userDefinedRuntimeAttributes"]];
  }
  return self;
}

- (void) setName: (NSString *)value
{
  ASSIGN(name, value);
}

- (NSString *) name
{
  return name;
}

- (void) setRuntimeAttributes: (NSArray *)attrbutes
{
  ASSIGN(runtimeAttributes, attrbutes);
}

- (NSArray *) runtimeAttributes
{
  return runtimeAttributes;
}

@end

@implementation IBAccessibilityAttribute

- (void) encodeWithCoder: (NSCoder *)coder
{
}

- (id) initWithCoder: (NSCoder *)coder
{
  return self;
}

@end

@implementation IBNSLayoutConstraint
- (void) encodeWithCoder: (NSCoder *)coder
{
  // Do nothing...
}

- (id) initWithCoder: (NSCoder *)coder
{
  return self;
}
@end

@implementation IBLayoutConstant
- (void) encodeWithCoder: (NSCoder *)coder
{
  // Do nothing...
}

- (id) initWithCoder: (NSCoder *)coder
{
  return self;
}
@end
