/*
  Test of NSDiffableDataSourceSnapshot

  Author: GitHub Copilot
  Date: January 2026

  Test for NSDiffableDataSource snapshot functionality in the GNUstep GUI Library.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSDiffableDataSource.h>

int main()
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSApplication *app = [NSApplication sharedApplication];
  
  START_SET("NSDiffableDataSourceSnapshot basic functionality")
    
    // Test 1: Create empty snapshot
    NSDiffableDataSourceSnapshot *snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
    PASS(snapshot != nil, "Empty snapshot creation");
    
    PASS([snapshot numberOfSections] == 0, "Empty snapshot has no sections");
    PASS([snapshot numberOfItems] == 0, "Empty snapshot has no items");
    PASS([[snapshot sectionIdentifiers] count] == 0, "Empty snapshot section identifiers");
    PASS([[snapshot itemIdentifiers] count] == 0, "Empty snapshot item identifiers");
    
    // Test 2: Add sections
    NSArray *sections = @[@"Section1", @"Section2", @"Section3"];
    [snapshot appendSectionsWithIdentifiers: sections];
    
    PASS([snapshot numberOfSections] == 3, "Snapshot has 3 sections after append");
    PASS([[snapshot sectionIdentifiers] isEqualToArray: sections], "Section identifiers match");
    PASS([snapshot numberOfItems] == 0, "No items after adding sections");
    
    // Test 3: Add items to sections
    NSArray *items1 = @[@"Item1", @"Item2"];
    NSArray *items2 = @[@"Item3", @"Item4", @"Item5"];
    
    [snapshot appendItemsWithIdentifiers: items1 intoSectionWithIdentifier: @"Section1"];
    [snapshot appendItemsWithIdentifiers: items2 intoSectionWithIdentifier: @"Section2"];
    
    PASS([snapshot numberOfItems] == 5, "Snapshot has 5 items total");
    
    NSArray *section1Items = [snapshot itemIdentifiersInSectionWithIdentifier: @"Section1"];
    NSArray *section2Items = [snapshot itemIdentifiersInSectionWithIdentifier: @"Section2"];
    NSArray *section3Items = [snapshot itemIdentifiersInSectionWithIdentifier: @"Section3"];
    
    PASS([section1Items isEqualToArray: items1], "Section1 has correct items");
    PASS([section2Items isEqualToArray: items2], "Section2 has correct items");
    PASS([section3Items count] == 0, "Section3 is empty");
    
    // Test 4: Insert sections
    NSArray *newSections = @[@"InsertedSection"];
    [snapshot insertSectionsWithIdentifiers: newSections beforeSectionWithIdentifier: @"Section2"];
    
    NSArray *expectedSections = @[@"Section1", @"InsertedSection", @"Section2", @"Section3"];
    PASS([[snapshot sectionIdentifiers] isEqualToArray: expectedSections], "Section insertion order correct");
    PASS([snapshot numberOfSections] == 4, "Section count after insertion");
    
    // Test 5: Insert items
    NSArray *insertedItems = @[@"InsertedItem"];
    [snapshot insertItemsWithIdentifiers: insertedItems beforeItemWithIdentifier: @"Item2"];
    
    NSArray *updatedSection1Items = [snapshot itemIdentifiersInSectionWithIdentifier: @"Section1"];
    NSArray *expectedSection1Items = @[@"Item1", @"InsertedItem", @"Item2"];
    PASS([updatedSection1Items isEqualToArray: expectedSection1Items], "Item insertion in section");
    
    // Test 6: Delete items
    [snapshot deleteItemsWithIdentifiers: @[@"Item3"]];
    NSArray *updatedSection2Items = [snapshot itemIdentifiersInSectionWithIdentifier: @"Section2"];
    NSArray *expectedSection2ItemsAfterDelete = @[@"Item4", @"Item5"];
    PASS([updatedSection2Items isEqualToArray: expectedSection2ItemsAfterDelete], "Item deletion from section");
    PASS([snapshot numberOfItems] == 5, "Item count after deletion");
    
    // Test 7: Delete sections
    [snapshot deleteSectionsWithIdentifiers: @[@"InsertedSection"]];
    NSArray *sectionsAfterDelete = @[@"Section1", @"Section2", @"Section3"];
    PASS([[snapshot sectionIdentifiers] isEqualToArray: sectionsAfterDelete], "Section deletion");
    PASS([snapshot numberOfSections] == 3, "Section count after deletion");
    
    // Test 8: Copy snapshot
    NSDiffableDataSourceSnapshot *copiedSnapshot = [snapshot copy];
    PASS(copiedSnapshot != snapshot, "Copied snapshot is different object");
    PASS([[copiedSnapshot sectionIdentifiers] isEqualToArray: [snapshot sectionIdentifiers]], "Copied snapshot has same sections");
    PASS([[copiedSnapshot itemIdentifiers] isEqualToArray: [snapshot itemIdentifiers]], "Copied snapshot has same items");
    
    // Test 9: Move sections
    [snapshot moveSectionWithIdentifier: @"Section3" beforeSectionWithIdentifier: @"Section1"];
    NSArray *sectionsAfterMove = @[@"Section3", @"Section1", @"Section2"];
    PASS([[snapshot sectionIdentifiers] isEqualToArray: sectionsAfterMove], "Section move operation");
    
    [snapshot release];
    [copiedSnapshot release];
    
  END_SET("NSDiffableDataSourceSnapshot basic functionality")
  
  [pool drain];
  return 0;
}