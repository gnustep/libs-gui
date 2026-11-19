/* Unequal hardware margins must be read from their respective axes. */
#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPrinter.h>

@interface MarginPrinter : NSPrinter

@end

@implementation MarginPrinter

+ (id) allocWithZone: (NSZone *)zone
{
  return NSAllocateObject(self, 0, zone);
}

- (NSSize) pageSizeForPaper: (NSString *)paper
{
  return NSMakeSize(612, 792);
}

- (NSRect) imageRectForPaper: (NSString *)paper
{
  return NSMakeRect(18, 36, 540, 684);
}

@end

@interface NSPrintInfo (MarginTest)

- (void) _updateMargins;

@end

int
main(void)
{
  CREATE_AUTORELEASE_POOL(pool);
  START_SET("Default printer margins")
  MarginPrinter *printer = [[MarginPrinter alloc] init];
  NSPrintInfo *info = [[NSPrintInfo alloc] initWithDictionary: nil];

  [info setPrinter: printer];
  [info _updateMargins];
  PASS([info leftMargin] == 18, "left margin uses the horizontal imageable origin");
  PASS([info bottomMargin] == 36, "bottom margin uses the vertical imageable origin");
  PASS([info rightMargin] == 54, "right margin uses paper width minus the imageable right edge");
  PASS([info topMargin] == 72, "top margin uses paper height minus the imageable top edge");
  RELEASE(info);
  RELEASE(printer);
  END_SET("Default printer margins")
  RELEASE(pool);
  return 0;
}

