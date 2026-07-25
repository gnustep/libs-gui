#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSTextList.h>

int main(int argc, char **argv)
{    
  CREATE_AUTORELEASE_POOL(arp);
    
  START_SET("NSParagraphStyle equality tests");
  
  NSMutableParagraphStyle *default1 = [NSParagraphStyle defaultParagraphStyle];
  NSMutableParagraphStyle *default2 = [NSParagraphStyle defaultParagraphStyle];
  
  PASS_EQUAL(default1, default2, "NSParagraphStyle isEqual: works for default paragraph styles");
  
  NSMutableParagraphStyle *style1 = AUTORELEASE(
    [[NSMutableParagraphStyle alloc] init]);
  NSMutableParagraphStyle *style2 = AUTORELEASE(
    [[NSMutableParagraphStyle alloc] init]);
  
  PASS_EQUAL(style1, style2, "NSParagraphStyle isEqual: works for default mutable copies");
  
  NSTextList *textList = AUTORELEASE(
    [[NSTextList alloc] init]);
  
  [style1 setTextLists: [NSArray arrayWithObject: textList]];
  [style2 setTextLists: [NSArray arrayWithObject: textList]];
  
  PASS_EQUAL(style1, style2, "NSParagraphStyle isEqual: works for identical textlists");
  
  [style1 setTextLists: [NSArray arrayWithObject: AUTORELEASE(
    [[NSTextList alloc] init])]];
  [style2 setTextLists: [NSArray arrayWithObject: AUTORELEASE(
    [[NSTextList alloc] init])]];
  
  PASS(![style1 isEqual: style2], "NSParagraphStyle isEqual: works for different textlists");
  
  END_SET("NSParagraphStyle equality tests");
  
  DESTROY(arp);
  
  return 0;
}
