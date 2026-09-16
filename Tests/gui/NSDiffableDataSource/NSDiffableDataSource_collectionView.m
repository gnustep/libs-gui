/*
  Test of NSDiffableDataSource with NSCollectionView

  Author: Gregory J. Casamento
  Date: January 2026

  Test for NSDiffableDataSource integration with NSCollectionView.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSIndexPath.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSCollectionView.h>
#include <AppKit/NSCollectionViewLayout.h>
#include <AppKit/NSCollectionViewGridLayout.h>
#include <AppKit/NSDiffableDataSource.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSView.h>

int main()
{
  START_SET("NSDiffableDataSource with NSCollectionView")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
    
    // Test 1: Create collection view and data source
    NSRect frame = NSMakeRect(0, 0, 400, 300);
    NSCollectionView *collectionView = [[NSCollectionView alloc] initWithFrame: frame];
    PASS(collectionView != nil, "Collection view creation");
    
    // Set up a simple grid layout
    NSCollectionViewGridLayout *layout = [[NSCollectionViewGridLayout alloc] init];
    [layout setMaximumNumberOfRows: 3];
    [layout setMaximumNumberOfColumns: 3];
    [collectionView setCollectionViewLayout: layout];
    [layout release];
    
    // Create the diffable data source with NULL item provider for testing
    // Note: In a real implementation, you would provide a proper block
    NSCollectionViewDiffableDataSource *dataSource = [[NSCollectionViewDiffableDataSource alloc] 
                                                       initWithCollectionView: collectionView 
                                                       itemProvider: NULL];
    PASS(dataSource != nil, "Data source creation");
    
    // Test 2: Verify data source setup (simplified for NULL item provider)
    PASS(dataSource != nil, "Data source was created");
    // Note: When item provider is NULL, some functionality may be limited
    
    // Test 3: Create and apply snapshot
    NSDiffableDataSourceSnapshot *snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
    
    // Add sections
    [snapshot appendSectionsWithIdentifiers: [NSArray arrayWithObjects: @"Section1", @"Section2", nil]];
    
    // Add items
    [snapshot appendItemsWithIdentifiers: [NSArray arrayWithObjects: @"Item1", @"Item2", nil] intoSectionWithIdentifier: @"Section1"];
    [snapshot appendItemsWithIdentifiers: [NSArray arrayWithObjects: @"Item3", @"Item4", @"Item5", nil] intoSectionWithIdentifier: @"Section2"];
    
    // Apply snapshot (may have limited functionality without item provider)
    [dataSource applySnapshot: snapshot animatingDifferences: NO];
    
    // Test 4:  Verify data source methods reflect the applied snapshot
    PASS([dataSource numberOfSectionsInCollectionView: collectionView] == 2, "Number of sections matches applied snapshot");
    PASS([dataSource collectionView: collectionView numberOfItemsInSection: 0] == 2, "First section item count matches applied snapshot");
    PASS([dataSource collectionView: collectionView numberOfItemsInSection: 1] == 3, "Second section item count matches applied snapshot");
    
    // Test 5:  Basic snapshot functionality
    NSDiffableDataSourceSnapshot *retrievedSnapshot = [dataSource snapshot];
    PASS(retrievedSnapshot != nil, "Can retrieve snapshot from data source");
    PASS([retrievedSnapshot numberOfSections] == 2, "Retrieved snapshot preserves section count");
    PASS([retrievedSnapshot numberOfItems] == 5, "Retrieved snapshot preserves item count");
    NSArray *expectedItems = [NSArray arrayWithObjects: @"Item1", @"Item2", @"Item3", @"Item4", @"Item5", nil];
    PASS([[retrievedSnapshot itemIdentifiers] isEqualToArray: expectedItems],
	  "Retrieved snapshot preserves item order");
    PASS([[dataSource indexPathForItemIdentifier: @"Item4"] isEqual:
	    [NSIndexPath indexPathForItem: 1 inSection: 1]], "Identifier lookup returns index path");
    PASS([[dataSource itemIdentifierForIndexPath:
	    [NSIndexPath indexPathForItem: 0 inSection: 1]] isEqual: @"Item3"],
	  "Index path lookup returns identifier");
    
    // Test 6:  Basic snapshot updates
    NSDiffableDataSourceSnapshot *updatedSnapshot = [dataSource snapshot];
    if (updatedSnapshot) {
      [updatedSnapshot appendItemsWithIdentifiers: [NSArray arrayWithObjects: @"Item6", nil] intoSectionWithIdentifier: @"Section2"];
      [dataSource applySnapshot: updatedSnapshot animatingDifferences: NO];
      PASS([dataSource collectionView: collectionView numberOfItemsInSection: 1] == 4, "Snapshot update changes item count");
      PASS([[dataSource itemIdentifierForIndexPath:
	      [NSIndexPath indexPathForItem: 3 inSection: 1]] isEqual: @"Item6"],
	    "Snapshot update preserves new item identifier");
    } else {
      PASS(NO, "Could not retrieve snapshot for update");
    }

    // Test 7: Table data source stores applied snapshots and maps flattened rows
    NSTableView *tableView = [[NSTableView alloc] initWithFrame: frame];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier: @"column"];
    [tableView addTableColumn: column];
    [column release];

    NSTableViewDiffableDataSource *tableDataSource =
      [[NSTableViewDiffableDataSource alloc] initWithTableView: tableView
						  cellProvider: NULL];
    [tableDataSource applySnapshot: snapshot animatingDifferences: NO];

    PASS([tableDataSource numberOfRowsInTableView: tableView] == 5, "Table row count matches applied snapshot");
    PASS([[tableDataSource itemIdentifierForRow: 3] isEqual: @"Item4"], "Table row lookup returns identifier");
    PASS([tableDataSource rowForItemIdentifier: @"Item5"] == 4, "Table identifier lookup returns row");
    PASS([[tableDataSource sectionIdentifierForRow: 3] isEqual: @"Section2"], "Table row maps to section identifier");
    PASS([tableDataSource rowForSectionIdentifier: @"Section2"] == 2, "Table section maps to first row");

    // Clean up
    [snapshot release];
    [dataSource release];
    [tableDataSource release];
    [tableView release];
    [collectionView release];
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER
    
  END_SET("NSDiffableDataSource with NSCollectionView")
  
  return 0;
}
