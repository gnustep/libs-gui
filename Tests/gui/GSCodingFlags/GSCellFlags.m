#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSValue.h>

#include "GSCodingFlags.h"

int main()
{
    CREATE_AUTORELEASE_POOL(arp);
    GSCellFlagsUnion mask = { { 0 } };

    START_SET("GSCodingFlags GNUstep CellFlags Union")
    
    // first make sure flags translate to values
    mask.flags.state = 1;
    mask.flags.selectable = 1;
    mask.flags.scrollable = 1;
    mask.flags.editable = 1;
    mask.flags.continuous = 1;
    mask.flags.useUserKeyEquivalent = 1;
    mask.flags.truncateLastLine = 1;

    PASS(mask.value == 0b10010000001110000000000001001000, "mask.flags translates to mask.value");

    // reset mask
    mask.value = 0;
    mask.flags = (GSCellFlags){0};

    // now make sure values translate to flags
    mask.value = 0b10010000001110000000000001001000;

    PASS(mask.flags.state == 1, "state is correctly set");
    PASS(mask.flags.selectable == 1, "selectable is correctly set");
    PASS(mask.flags.scrollable == 1, "scrollable is correctly set");
    PASS(mask.flags.editable == 1, "editable is correctly set");
    PASS(mask.flags.continuous == 1, "continuous is correctly set");
    PASS(mask.flags.useUserKeyEquivalent == 1, "useUserKeyEquivalent is correctly set");
    PASS(mask.flags.truncateLastLine == 1, "truncateLastLine is correctly set");
    
    END_SET("GSCodingFlags GNUstep CellFlags Union")

    DESTROY(arp);
    return 0;
}
