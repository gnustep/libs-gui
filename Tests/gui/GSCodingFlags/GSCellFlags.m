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

#if GS_WORDS_BIGENDIAN == 1
    pass(mask.value == 0b00010010000000000001110000001001, "mask.flags translates to mask.value");
#else
    pass(mask.value == 0b10010000001110000000000001001000, "mask.flags translates to mask.value");
#endif
    // reset mask
    mask.value = 0;
    mask.flags = (GSCellFlags){0};
    // now make sure values translate to flags
#if GS_WORDS_BIGENDIAN == 1
    mask.value = 0b00010010000000000001110000001001;
#else
    mask.value = 0b10010000001110000000000001001000;
#endif

    pass(mask.flags.state == 1, "state is correctly set");
    pass(mask.flags.selectable == 1, "selectable is correctly set");
    pass(mask.flags.scrollable == 1, "scrollable is correctly set");
    pass(mask.flags.editable == 1, "editable is correctly set");
    pass(mask.flags.continuous == 1, "continuous is correctly set");
    pass(mask.flags.useUserKeyEquivalent == 1, "useUserKeyEquivalent is correctly set");
    pass(mask.flags.truncateLastLine == 1, "truncateLastLine is correctly set");
    
    END_SET("GSCodingFlags GNUstep CellFlags Union")

    DESTROY(arp);
    return 0;
}