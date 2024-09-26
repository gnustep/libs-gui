#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSTextList.h>

int main(int argc, char **argv)
{  
  CREATE_AUTORELEASE_POOL(arp);
  
  START_SET("NSAttributedString itemNumberInTextList:atIndex: category method");
  
  NSTextList *list1 = [[NSTextList alloc] initWithMarkerFormat:@"{decimal}" options:0];
  NSTextList *list2 = [[NSTextList alloc] initWithMarkerFormat:@"{box}" options:0];

  NSMutableParagraphStyle *style1 = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  NSMutableParagraphStyle *style2 = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  
  [style1 setTextLists: [NSArray arrayWithObject: list1]];
  [style2 setTextLists: [NSArray arrayWithObjects: list1, list2, nil]];
  
  NSDictionary *attrs1 = [NSDictionary dictionaryWithObject: style1 
    forKey: NSParagraphStyleAttributeName];
  NSDictionary *attrs2 = [NSDictionary dictionaryWithObject: style2 
    forKey: NSParagraphStyleAttributeName];  
  NSDictionary *attrs3 = [NSDictionary dictionaryWithObject: [NSParagraphStyle defaultParagraphStyle]
    forKey: NSParagraphStyleAttributeName];
  
  NSMutableAttributedString *storage = [[NSMutableAttributedString alloc] init];
  
  NSUInteger index1 = [storage length];
  [storage appendAttributedString: 
    [[NSMutableAttributedString alloc] initWithString: @"item 1\r\n" attributes: attrs1]];
    
  NSUInteger index2 = [storage length];
  [storage appendAttributedString: 
    [[NSMutableAttributedString alloc] initWithString: @"item 2\n" attributes: attrs1]];
    
  NSUInteger index3 = [storage length];
  [storage appendAttributedString: 
    [[NSMutableAttributedString alloc] initWithString: @"item 3\n" attributes: attrs1]];
    
  NSUInteger index4A = [storage length];
  [storage appendAttributedString: 
    [[NSMutableAttributedString alloc] initWithString: @"item 4A\n" attributes: attrs2]];
  
  NSUInteger index4B = [storage length];
  [storage appendAttributedString: 
    [[NSMutableAttributedString alloc] initWithString: @"item 4B\n" attributes: attrs2]];
    
  NSUInteger index5 = [storage length];
  [storage appendAttributedString: 
    [[NSMutableAttributedString alloc] initWithString: @"item 5\n" attributes: attrs1]];
  
  NSUInteger index6 = [storage length];
  [storage appendAttributedString: 
    [[NSMutableAttributedString alloc] initWithString: @"extra text\n" attributes: attrs3]];
  
  pass([storage itemNumberInTextList: list1 atIndex: index1] == 1, "Index for first list item");
  pass([storage itemNumberInTextList: list1 atIndex: index2] == 2, "Index with CR+LF sequence");
  pass([storage itemNumberInTextList: list1 atIndex: index3 - 1] == 2, "Index on boundary");
  pass([storage itemNumberInTextList: list1 atIndex: index3] == 3, "Index for third list item");
  pass([storage itemNumberInTextList: list1 atIndex: index4A] == 4, "Index for fourth list item, A");
  pass([storage itemNumberInTextList: list1 atIndex: index4B] == 4, "Index for fourth list item, B");
  pass([storage itemNumberInTextList: list1 atIndex: index5] == 5, "Index for fifth list item");
  
  pass([storage itemNumberInTextList: list2 atIndex: index4A] == 1, "Index for first sublist item");  
  pass([storage itemNumberInTextList: list2 atIndex: index4B] == 2, "Index for second sublist item");
  
  pass([storage itemNumberInTextList: list2 atIndex: index1] == 0, "Index in other list is zero");
  pass([storage itemNumberInTextList: list1 atIndex: index6] == 0, "Index in nonlist is zero");
  
  END_SET("NSAttributedString itemNumberInTextList:atIndex: category method");
  
  DESTROY(arp);
  
  return 0;
}
