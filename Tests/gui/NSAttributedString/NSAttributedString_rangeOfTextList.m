#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSTextList.h>

int main(int argc, char **argv)
{  
  CREATE_AUTORELEASE_POOL(arp);
  
  START_SET("NSAttributedString rangeOfTextList:atIndex: category method");
  
  NSTextList *list1 = AUTORELEASE(
    [[NSTextList alloc] initWithMarkerFormat: @"{box}" options: 0]);
  NSTextList *list2 = AUTORELEASE(
    [[NSTextList alloc] initWithMarkerFormat: @"{box}" options: 0]);
  NSTextList *list3 = AUTORELEASE(
    [[NSTextList alloc] initWithMarkerFormat: @"{box}" options: 0]);

  NSMutableParagraphStyle *style1 = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
  NSMutableParagraphStyle *style2 = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
  NSMutableParagraphStyle *style3 = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
  NSMutableParagraphStyle *style4 = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
  
  [style2 setTextLists: [NSArray arrayWithObject: list1]];
  [style3 setTextLists: [NSArray arrayWithObjects: list1, list2, nil]];
  [style4 setTextLists: [NSArray arrayWithObject: list3]];
  
  NSMutableAttributedString *storage = AUTORELEASE(
    [[NSMutableAttributedString alloc] init]);
  
  NSUInteger pos1 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc] 
    initWithString: @"before\n"
    attributes: [NSDictionary dictionaryWithObject: style1 forKey: NSParagraphStyleAttributeName]])];
    
  NSUInteger pos2 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc] 
    initWithString: @"list 1\n"
    attributes: [NSDictionary dictionaryWithObject: style2 forKey: NSParagraphStyleAttributeName]])];
  
  NSUInteger pos3 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc] 
    initWithString: @"sublist 1\n"
    attributes: [NSDictionary dictionaryWithObject: style3 forKey: NSParagraphStyleAttributeName]])];
  
  NSUInteger pos4 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc] 
    initWithString: @"list 1\n"
    attributes: [NSDictionary dictionaryWithObject: style2 forKey: NSParagraphStyleAttributeName]])];
  
  NSUInteger pos5 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc] 
    initWithString: @"list 2\n"
    attributes: [NSDictionary dictionaryWithObject: style4 forKey: NSParagraphStyleAttributeName]])];
  
  NSUInteger pos6 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc] 
    initWithString: @"ending\n"
    attributes: [NSDictionary dictionaryWithObject: style1 forKey: NSParagraphStyleAttributeName]])];
  
  NSRange expected, actual;
  
  expected = NSMakeRange(pos3, pos4 - pos3);
  actual = [storage rangeOfTextList: list2 atIndex: pos3 + 1];
  PASS(NSEqualRanges(expected, actual), "Found correct range of nested list");
  
  expected = NSMakeRange(pos2, pos5 - pos2);
  actual = [storage rangeOfTextList: list1 atIndex: pos3 + 1];
  PASS(NSEqualRanges(expected, actual), "Found correct range of enclosing list");
  
  expected = NSMakeRange(pos2, pos5 - pos2);
  actual = [storage rangeOfTextList: list1 atIndex: pos2 + 1];
  PASS(NSEqualRanges(expected, actual), "Found correct range including nested list");
  
  expected = NSMakeRange(pos5, pos6 - pos5);
  actual = [storage rangeOfTextList: list3 atIndex: pos5 + 1];
  PASS(NSEqualRanges(expected, actual), "Found correct range of an adjacent list");
  
  actual = [storage rangeOfTextList: list1 atIndex: pos5];
  PASS(actual.location == NSNotFound, "Returned not found for location in different list");
  
  actual = [storage rangeOfTextList: list1 atIndex: pos1];
  PASS(actual.location == NSNotFound, "Returned not found for location not in any list");
  
  END_SET("NSAttributedString rangeOfTextList:atIndex: category method");
  
  DESTROY(arp);
  
  return 0;
}
