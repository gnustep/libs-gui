/* Coverage for NSNibConnector: the source, destination and label it holds,
 * replacing an object it holds, how it compares itself to another connector,
 * and archiving.  These are plain model objects and need no backend.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSNibConnector.h>
#include <AppKit/NSNibControlConnector.h>
#include <AppKit/NSNibOutletConnector.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("a new connector")
    NSNibConnector	*connector;

    connector = AUTORELEASE([[NSNibConnector alloc] init]);
    PASS(connector != nil, "a connector is created");
    PASS([connector source] == nil, "a new connector has no source");
    PASS([connector destination] == nil, "a new connector has no destination");
    PASS([connector label] == nil, "a new connector has no label");
  END_SET("a new connector")

  START_SET("what it holds")
    NSNibConnector	*connector;
    NSString		*source = @"theSource";
    NSString		*destination = @"theDestination";

    connector = AUTORELEASE([[NSNibConnector alloc] init]);
    [connector setSource: source];
    [connector setDestination: destination];
    [connector setLabel: @"theLabel"];

    PASS([connector source] == source, "the source reads back");
    PASS([connector destination] == destination,
      "the destination reads back");
    PASS([[connector label] isEqualToString: @"theLabel"],
      "the label reads back");

    [connector setSource: nil];
    [connector setLabel: nil];
    PASS([connector source] == nil, "the source can be cleared");
    PASS([connector label] == nil, "the label can be cleared");
  END_SET("what it holds")

  START_SET("replacing an object")
    NSNibConnector	*connector;
    NSString		*held = @"held";
    NSString		*other = @"other";

    connector = AUTORELEASE([[NSNibConnector alloc] init]);
    [connector setSource: held];
    [connector setDestination: held];
    [connector replaceObject: held withObject: other];
    PASS([connector source] == other, "the source is replaced");
    PASS([connector destination] == other, "the destination is replaced");

    [connector replaceObject: @"neverHeld" withObject: @"something"];
    PASS([connector source] == other
      && [connector destination] == other,
      "replacing an object it does not hold changes nothing");
  END_SET("replacing an object")

  START_SET("comparing connectors")
    NSNibConnector		*one;
    NSNibConnector		*two;
    NSNibControlConnector	*control;

    one = AUTORELEASE([[NSNibConnector alloc] init]);
    PASS([one isEqual: one] == YES, "a connector equals itself");

    two = AUTORELEASE([[NSNibConnector alloc] init]);
    [one setSource: @"s"];
    [one setDestination: @"d"];
    [one setLabel: @"l"];
    [two setSource: @"s"];
    [two setDestination: @"d"];
    [two setLabel: @"l"];
    PASS([one isEqual: two] == YES,
      "connectors joining the same objects with the same label are equal");

    [two setLabel: @"other"];
    PASS([one isEqual: two] == NO,
      "connectors with different labels are not equal");

    /* the class is part of it: a control connector is not an outlet one */
    control = AUTORELEASE([[NSNibControlConnector alloc] init]);
    [control setSource: @"s"];
    [control setDestination: @"d"];
    [control setLabel: @"l"];
    PASS([one isEqual: control] == NO,
      "connectors of different classes are not equal");

    PASS([one isEqual: @"not a connector"] == NO,
      "a connector is not equal to something that is not one");
  END_SET("comparing connectors")

  START_SET("establishing a connection")
    NSNibConnector	*connector;
    BOOL		raised;

    connector = AUTORELEASE([[NSNibConnector alloc] init]);
    raised = NO;
    NS_DURING
      [connector establishConnection];
    NS_HANDLER
      raised = YES;
    NS_ENDHANDLER
    PASS(raised == NO,
      "establishing a connection with nothing to join does not raise");
  END_SET("establishing a connection")

  START_SET("archiving")
    NSNibConnector	*connector;
    NSNibConnector	*decoded;
    NSData		*data;

    connector = AUTORELEASE([[NSNibConnector alloc] init]);
    [connector setSource: @"theSource"];
    [connector setDestination: @"theDestination"];
    [connector setLabel: @"theLabel"];

    data = [NSKeyedArchiver archivedDataWithRootObject: connector];
    decoded = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    PASS(decoded != nil, "the connector comes back from a keyed archive");
    PASS([[decoded source] isEqualToString: @"theSource"],
      "the archived connector keeps its source");
    PASS([[decoded destination] isEqualToString: @"theDestination"],
      "the archived connector keeps its destination");
    PASS([[decoded label] isEqualToString: @"theLabel"],
      "the archived connector keeps its label");
  END_SET("archiving")

  DESTROY(arp);
  return 0;
}
