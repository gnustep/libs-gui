# NSOutlineView Variable Row Heights Test

This test validates the new delegate methods for NSOutlineView:

## Delegate Methods Tested

1. **`outlineView:heightOfRowByItem:`**
   - Returns custom height for each item
   - Enables variable row heights in outline views
   - Root items: 30pt height
   - Child items: 20pt height

2. **`outlineView:sizeToFitWidthOfColumn:`**
   - Invoked when column header is double-clicked
   - Allows delegate to provide custom column width
   - Returns: 150pt width

## Test Coverage

The test verifies:

- ✓ Basic outline view setup with data source
- ✓ Row expansion/collapse functionality
- ✓ Uniform row heights (default behavior)
- ✓ Variable row heights via delegate
- ✓ Correct row rectangle calculation with variable heights
- ✓ `rowAtPoint:` accuracy with variable heights
- ✓ Cell frame calculations respect row heights
- ✓ Custom column sizing on double-click
- ✓ Total view height calculation with variable rows

## Running the Test

From the Tests directory:

```bash
make check
```

Or to run this specific test:

```bash
cd Tests/gui/NSOutlineView
make
./obj/variableRowHeights
```

## Expected Output

All tests should PASS. The test validates that:

- Rows have correct heights based on delegate return values
- Row positioning accounts for variable heights
- Point-to-row mapping works correctly
- Column resizing respects delegate customization
