#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSTextList.h>

int main(int argc, char **argv)
{  
  CREATE_AUTORELEASE_POOL(arp);
  
  START_SET("NSAttributedString attribute merging");
  
  NSMutableParagraphStyle *style1 = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  NSMutableParagraphStyle *style2 = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  NSMutableParagraphStyle *style3 = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  NSMutableParagraphStyle *style4 = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  
  NSTextList *list1 = [[NSTextList alloc] initWithMarkerFormat: @"{box}" options: 0];
  NSTextList *list2 = [[NSTextList alloc] initWithMarkerFormat: @"{box}" options: 0];
  
  [style3 setTextLists: [NSArray arrayWithObject: list1]];
  [style4 setTextLists: [NSArray arrayWithObject: list2]];
  
  NSAttributedString *str1 = [[NSAttributedString alloc] 
    initWithString: @"string 1" 
    attributes: [NSDictionary dictionaryWithObject: style1 forKey: NSParagraphStyleAttributeName]];
  NSAttributedString *str2 = [[NSAttributedString alloc] 
    initWithString: @"string 2"
    attributes: [NSDictionary dictionaryWithObject: style2 forKey: NSParagraphStyleAttributeName]];
  NSAttributedString *str3 = [[NSAttributedString alloc] 
    initWithString: @"string 3" 
    attributes: [NSDictionary dictionaryWithObject: style3 forKey: NSParagraphStyleAttributeName]];
  NSAttributedString *str4 = [[NSAttributedString alloc] 
    initWithString: @"string 4"
    attributes: [NSDictionary dictionaryWithObject: style4 forKey: NSParagraphStyleAttributeName]];
  
  NSMutableAttributedString *storage = [[NSMutableAttributedString alloc] init];
  
  NSUInteger pos1 = [storage length];
  [storage appendAttributedString: str1];
  
  NSUInteger pos2 = [storage length];
  [storage appendAttributedString: str2];
  
  NSUInteger pos3 = [storage length];
  [storage appendAttributedString: str3];
  
  NSUInteger pos4 = [storage length];
  [storage appendAttributedString: str4];
  
  NSParagraphStyle *result1 = [storage attribute: NSParagraphStyleAttributeName 
    atIndex: pos1 
    effectiveRange: NULL];
  NSParagraphStyle *result2 = [storage attribute: NSParagraphStyleAttributeName 
    atIndex: pos2 
    effectiveRange: NULL];
  NSParagraphStyle *result3 = [storage attribute: NSParagraphStyleAttributeName 
    atIndex: pos3 
    effectiveRange: NULL];
  NSParagraphStyle *result4 = [storage attribute: NSParagraphStyleAttributeName 
    atIndex: pos4 
    effectiveRange: NULL];
  
  pass(result1 == result2, "Did merge equal paragraph styles");
  pass(result3 != result4, "Did not merge equal paragraph styles with text lists");
  
  END_SET("NSAttributedString attribute merging");
  
  DESTROY(arp);
  
  return 0;
}
