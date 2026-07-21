/* Coverage for NSTextBlock: the value type, dimension and layer enumerations,
 * the init defaults, and the content width, background colour, layer width and
 * border colour round-trips.  Every assertion here matches AppKit (verified on
 * a macOS runner) and passes on unmodified GNUstep.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSTextTable.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSTextBlock basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSTextBlock	*block;
    NSColor	*red;
    NSColor	*blue;

    /* the enumerations */
    PASS(NSTextBlockAbsoluteValueType == 0
      && NSTextBlockPercentageValueType == 1,
      "the value types have their AppKit values");
    PASS(NSTextBlockWidth == 0 && NSTextBlockMinimumWidth == 1
      && NSTextBlockMaximumWidth == 2 && NSTextBlockHeight == 4,
      "the dimensions have their AppKit values");
    PASS(NSTextBlockPadding == -1 && NSTextBlockBorder == 0
      && NSTextBlockMargin == 1,
      "the layers have their AppKit values");

    /* init defaults */
    block = AUTORELEASE([[NSTextBlock alloc] init]);
    PASS(block != nil, "a text block is created");
    PASS([block contentWidth] == 0, "a new block has no content width");
    PASS([block contentWidthValueType] == NSTextBlockAbsoluteValueType,
      "a new block's content width is an absolute value");
    PASS([block backgroundColor] == nil,
      "a new block has no background colour");
    PASS([block widthForLayer: NSTextBlockBorder edge: NSMinYEdge] == 0
      && [block widthForLayer: NSTextBlockBorder edge: NSMinXEdge] == 0,
      "a new block has no border width");
    PASS([block borderColorForEdge: NSMinYEdge] == nil,
      "a new block has no border colour");

    /* round-trips */
    red = [NSColor redColor];
    blue = [NSColor blueColor];

    [block setContentWidth: 50.0 type: NSTextBlockAbsoluteValueType];
    PASS([block contentWidth] == 50.0
      && [block contentWidthValueType] == NSTextBlockAbsoluteValueType,
      "the content width and its type round-trip");

    [block setBackgroundColor: red];
    PASS([block backgroundColor] == red, "the background colour reads back");

    [block setWidth: 3.0 type: NSTextBlockAbsoluteValueType
      forLayer: NSTextBlockBorder];
    PASS([block widthForLayer: NSTextBlockBorder edge: NSMinYEdge] == 3.0,
      "a layer width set for every edge round-trips");
    PASS([block widthValueTypeForLayer: NSTextBlockBorder edge: NSMinYEdge]
      == NSTextBlockAbsoluteValueType,
      "the layer width type round-trips");

    [block setWidth: 7.0 type: NSTextBlockAbsoluteValueType
      forLayer: NSTextBlockMargin edge: NSMaxXEdge];
    PASS([block widthForLayer: NSTextBlockMargin edge: NSMaxXEdge] == 7.0,
      "a layer width set for one edge round-trips");
    PASS([block widthForLayer: NSTextBlockMargin edge: NSMinXEdge] == 0,
      "setting one edge leaves the others alone");

    [block setBorderColor: red forEdge: NSMinYEdge];
    PASS([block borderColorForEdge: NSMinYEdge] == red,
      "a border colour set for one edge reads back");
    PASS([block borderColorForEdge: NSMaxYEdge] == nil,
      "setting one edge's border colour leaves the others alone");

    [block setBorderColor: blue];
    PASS([block borderColorForEdge: NSMinYEdge] == blue
      && [block borderColorForEdge: NSMaxYEdge] == blue,
      "a border colour set for every edge reads back on each");
  }

  END_SET("NSTextBlock basic")

  DESTROY(arp);
  return 0;
}
