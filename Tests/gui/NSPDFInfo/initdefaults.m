/* -[NSPDFInfo init] gives AppKit's defaults: a non-nil (empty) attributes
   dictionary and tagNames array, fileExtensionHidden YES, and a paper size
   taken from the shared print info (the system default), rather than leaving
   everything zero/nil. */
#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPDFInfo.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSPDFInfo *info = [[NSPDFInfo alloc] init];

  PASS([info attributes] != nil, "default attributes is non-nil");
  PASS([[info attributes] isKindOfClass: [NSMutableDictionary class]],
       "attributes is a mutable dictionary");
  PASS([[info attributes] count] == 0, "default attributes is empty");

  PASS([info tagNames] != nil, "default tagNames is non-nil");
  PASS([[info tagNames] count] == 0, "default tagNames is empty");

  PASS([info isFileExtensionHidden] == YES,
       "default fileExtensionHidden is YES");

  NSSize dflt = [[NSPrintInfo sharedPrintInfo] paperSize];
  PASS(NSEqualSizes([info paperSize], dflt),
       "default paperSize is the shared print info's paper size");
  PASS([info paperSize].width > 0 && [info paperSize].height > 0,
       "default paperSize is non-zero");

  RELEASE(info);
  DESTROY(arp);
  return 0;
}
