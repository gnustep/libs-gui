#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSTextTable.h>

int main(int argc, char **argv)
{
  START_SET("NSAttributedString rangeOfTextBlock:atIndex: category method");

  NSTextBlock *block1 = AUTORELEASE([[NSTextBlock alloc] init]);
  NSTextBlock *block2 = AUTORELEASE([[NSTextBlock alloc] init]);
  NSTextBlock *block3 = AUTORELEASE([[NSTextBlock alloc] init]);

  NSMutableParagraphStyle *style1 = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
  NSMutableParagraphStyle *style2 = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
  NSMutableParagraphStyle *style3 = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
  NSMutableParagraphStyle *style4 = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);

  [style2 setTextBlocks: [NSArray arrayWithObject: block1]];
  [style3 setTextBlocks: [NSArray arrayWithObjects: block1, block2, nil]];
  [style4 setTextBlocks: [NSArray arrayWithObject: block3]];

  NSMutableAttributedString *storage = AUTORELEASE(
    [[NSMutableAttributedString alloc] init]);

  NSUInteger pos1 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"before\n"
    attributes: [NSDictionary dictionaryWithObject: style1 forKey: NSParagraphStyleAttributeName]])];

  NSUInteger pos2 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"block 1\n"
    attributes: [NSDictionary dictionaryWithObject: style2 forKey: NSParagraphStyleAttributeName]])];

  NSUInteger pos3 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"nested\n"
    attributes: [NSDictionary dictionaryWithObject: style3 forKey: NSParagraphStyleAttributeName]])];

  NSUInteger pos4 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"block 1\n"
    attributes: [NSDictionary dictionaryWithObject: style2 forKey: NSParagraphStyleAttributeName]])];

  NSUInteger pos5 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"block 3\n"
    attributes: [NSDictionary dictionaryWithObject: style4 forKey: NSParagraphStyleAttributeName]])];

  NSUInteger pos6 = [storage length];
  [storage appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"ending\n"
    attributes: [NSDictionary dictionaryWithObject: style1 forKey: NSParagraphStyleAttributeName]])];

  NSRange expected, actual;

  expected = NSMakeRange(pos3, pos4 - pos3);
  actual = [storage rangeOfTextBlock: block2 atIndex: pos3 + 1];
  PASS(NSEqualRanges(expected, actual), "Found correct range of nested block");

  expected = NSMakeRange(pos2, pos5 - pos2);
  actual = [storage rangeOfTextBlock: block1 atIndex: pos3 + 1];
  PASS(NSEqualRanges(expected, actual), "Found correct range of enclosing block");

  expected = NSMakeRange(pos2, pos5 - pos2);
  actual = [storage rangeOfTextBlock: block1 atIndex: pos2 + 1];
  PASS(NSEqualRanges(expected, actual), "Found correct range including nested block");

  expected = NSMakeRange(pos5, pos6 - pos5);
  actual = [storage rangeOfTextBlock: block3 atIndex: pos5 + 1];
  PASS(NSEqualRanges(expected, actual), "Found correct range of an adjacent block");

  actual = [storage rangeOfTextBlock: block1 atIndex: pos5];
  PASS(actual.location == NSNotFound, "Returned not found for location in different block");

  actual = [storage rangeOfTextBlock: block1 atIndex: pos1];
  PASS(actual.location == NSNotFound, "Returned not found for location not in any block");

  END_SET("NSAttributedString rangeOfTextBlock:atIndex: category method");

  START_SET("NSAttributedString rangeOfTextTable:atIndex: category method");

  NSRange tableExpected, tableActual;

  NSTextTable *table1 = AUTORELEASE([[NSTextTable alloc] init]);
  NSTextTable *table2 = AUTORELEASE([[NSTextTable alloc] init]);

  NSTextTableBlock *cell1 = AUTORELEASE([[NSTextTableBlock alloc]
    initWithTable: table1 startingRow: 0 rowSpan: 1
    startingColumn: 0 columnSpan: 1]);
  NSTextTableBlock *cell2 = AUTORELEASE([[NSTextTableBlock alloc]
    initWithTable: table1 startingRow: 1 rowSpan: 1
    startingColumn: 0 columnSpan: 1]);
  NSTextTableBlock *cell3 = AUTORELEASE([[NSTextTableBlock alloc]
    initWithTable: table2 startingRow: 0 rowSpan: 1
    startingColumn: 0 columnSpan: 1]);

  NSMutableParagraphStyle *plain = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
  NSMutableParagraphStyle *cellStyle1 = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
  NSMutableParagraphStyle *cellStyle2 = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
  NSMutableParagraphStyle *cellStyle3 = AUTORELEASE(
    [[NSParagraphStyle defaultParagraphStyle] mutableCopy]);

  [cellStyle1 setTextBlocks: [NSArray arrayWithObject: cell1]];
  [cellStyle2 setTextBlocks: [NSArray arrayWithObject: cell2]];
  [cellStyle3 setTextBlocks: [NSArray arrayWithObject: cell3]];

  NSMutableAttributedString *tableStorage = AUTORELEASE(
    [[NSMutableAttributedString alloc] init]);

  NSUInteger tpos1 = [tableStorage length];
  [tableStorage appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"before\n"
    attributes: [NSDictionary dictionaryWithObject: plain forKey: NSParagraphStyleAttributeName]])];

  NSUInteger tpos2 = [tableStorage length];
  [tableStorage appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"cell 1\n"
    attributes: [NSDictionary dictionaryWithObject: cellStyle1 forKey: NSParagraphStyleAttributeName]])];

  NSUInteger tpos3 = [tableStorage length];
  [tableStorage appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"cell 2\n"
    attributes: [NSDictionary dictionaryWithObject: cellStyle2 forKey: NSParagraphStyleAttributeName]])];

  NSUInteger tpos4 = [tableStorage length];
  [tableStorage appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"other table\n"
    attributes: [NSDictionary dictionaryWithObject: cellStyle3 forKey: NSParagraphStyleAttributeName]])];

  NSUInteger tpos5 = [tableStorage length];
  [tableStorage appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
    initWithString: @"ending\n"
    attributes: [NSDictionary dictionaryWithObject: plain forKey: NSParagraphStyleAttributeName]])];

  tableExpected = NSMakeRange(tpos2, tpos4 - tpos2);
  tableActual = [tableStorage rangeOfTextTable: table1 atIndex: tpos2 + 1];
  PASS(NSEqualRanges(tableExpected, tableActual), "Found correct range of table from its first cell");

  tableExpected = NSMakeRange(tpos2, tpos4 - tpos2);
  tableActual = [tableStorage rangeOfTextTable: table1 atIndex: tpos3 + 1];
  PASS(NSEqualRanges(tableExpected, tableActual), "Found correct range of table from its second cell");

  tableExpected = NSMakeRange(tpos4, tpos5 - tpos4);
  tableActual = [tableStorage rangeOfTextTable: table2 atIndex: tpos4 + 1];
  PASS(NSEqualRanges(tableExpected, tableActual), "Found correct range of an adjacent table");

  tableActual = [tableStorage rangeOfTextTable: table1 atIndex: tpos4];
  PASS(tableActual.location == NSNotFound, "Returned not found for location in different table");

  tableActual = [tableStorage rangeOfTextTable: table1 atIndex: tpos1];
  PASS(tableActual.location == NSNotFound, "Returned not found for location not in any table");

  END_SET("NSAttributedString rangeOfTextTable:atIndex: category method");


  return 0;
}
