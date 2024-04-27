#import "ObjectTesting.h"

#import <Foundation/NSData.h>
#import <Foundation/NSValue.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSMenuItem.h>

int main()
{
  NSString* mask = @"NSKeyEquivModMask";
  NSMenuItem* item = [[NSMenuItem alloc] init];
  item.keyEquivalentModifierMask = NSShiftKeyMask;

  NSMutableData *data = [NSMutableData data];
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

  [archiver encodeRootObject:item];
  [archiver finishEncoding];

  NSError* error;
  NSDictionary* archive = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:&error];

  NSArray* topLevelObjects = [archive objectForKey:@"$objects"];

  NSDictionary* dict;

  for (id element in topLevelObjects)
    {
      if ([element isKindOfClass:[NSDictionary class]])
        {
          dict = (NSDictionary*)element;
          
          if ([[dict allKeys] containsObject:mask])
            {
              break;
            }
          else
            {
              dict = nil;
            }
      }
  }

  PASS(dict != nil, "Found a dict with a NSKeyEquivModMask entry");

  NSNumber* encodedKeyMask = [dict valueForKey:mask];
  PASS(encodedKeyMask != nil, "Retrieved the NSKeyEquivModMask value");
  PASS([encodedKeyMask intValue] == NSShiftKeyMask, "Encoded key mask 0x%x matches expected key mask 0x%x", [encodedKeyMask intValue], NSShiftKeyMask);
}