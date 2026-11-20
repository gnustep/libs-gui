#import "ObjectTesting.h"

#import <Foundation/NSData.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTableCellView.h>
#import <AppKit/NSTextField.h>
#import <Additions/GNUstepGUI/GSXibKeyedUnarchiver.h>

int main()
{
  START_SET("GSXib5KeyedUnarchiver view-based NSTableView prototype tests")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name]
	isEqualToString: NSInternalInconsistencyException ])
	{
	  SKIP("It looks like GNUstep backend is not yet installed")
	}
    }
  NS_ENDHANDLER

  NSData		*data;
  GSXibKeyedUnarchiver	*unarchiver;
  NSArray		*rootObjects = nil;
  NSEnumerator		*enumerator;
  NSTableView		*table = nil;
  NSView		*plain = nil;
  NSView		*cell;
  id			element;

  data = [NSData dataWithContentsOfFile: @"TableCellView.xib"];
  unarchiver = [GSXibKeyedUnarchiver unarchiverForReadingWithData: data];
  NS_DURING
    {
      rootObjects = [unarchiver decodeObjectForKey: @"IBDocument.RootObjects"];
    }
  NS_HANDLER
    {
      rootObjects = nil;
    }
  NS_ENDHANDLER
  PASS(rootObjects != nil,
    "A xib with a prototype cell view on Automatic identifier loads")

  enumerator = [rootObjects objectEnumerator];
  while ((element = [enumerator nextObject]) != nil)
    {
      if ([element isKindOfClass: [NSTableView class]])
	{
	  table = element;
	}
      else if ([element isKindOfClass: [NSTextField class]])
	{
	  plain = element;
	}
    }

  PASS_EQUAL([plain identifier], @"PlainView",
    "A view's identifier is decoded from the xib")

  cell = [table makeViewWithIdentifier: @"NamedCell" owner: nil];
  PASS([cell isKindOfClass: [NSTableCellView class]],
    "A prototype cell view is made by its own identifier")

  cell = [table makeViewWithIdentifier: @"AutomaticColumn" owner: nil];
  PASS([cell isKindOfClass: [NSTableCellView class]],
    "A prototype cell view without an identifier is made by its column's identifier")

  END_SET("GSXib5KeyedUnarchiver view-based NSTableView prototype tests")

  return 0;
}
