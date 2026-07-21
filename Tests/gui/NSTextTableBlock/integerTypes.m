/* The row and column a block covers are NSIntegers, as they are in AppKit, so
 * that code written against AppKit's declarations calls these methods with the
 * arguments they expect.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTextTable.h>

#include <objc/runtime.h>

static BOOL
returnsNSInteger(const char *name)
{
  SEL		sel;
  Method	method;
  char		*type;
  BOOL		result;

  sel = NSSelectorFromString([NSString stringWithUTF8String: name]);
  method = class_getInstanceMethod([NSTextTableBlock class], sel);
  if (method == NULL)
    {
      return NO;
    }
  type = method_copyReturnType(method);
  result = (strcmp(type, @encode(NSInteger)) == 0);
  free(type);
  return result;
}

static BOOL
takesNSIntegerAt(const char *name, unsigned index)
{
  SEL		sel;
  Method	method;
  char		*type;
  BOOL		result;

  sel = NSSelectorFromString([NSString stringWithUTF8String: name]);
  method = class_getInstanceMethod([NSTextTableBlock class], sel);
  if (method == NULL)
    {
      return NO;
    }
  type = method_copyArgumentType(method, index);
  result = (strcmp(type, @encode(NSInteger)) == 0);
  free(type);
  return result;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("the row and column types")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    const char	*initName;
    NSTextTable		*table;
    NSTextTableBlock	*block;

    PASS(returnsNSInteger("startingRow") == YES,
      "startingRow answers an NSInteger");
    PASS(returnsNSInteger("rowSpan") == YES, "rowSpan answers an NSInteger");
    PASS(returnsNSInteger("startingColumn") == YES,
      "startingColumn answers an NSInteger");
    PASS(returnsNSInteger("columnSpan") == YES,
      "columnSpan answers an NSInteger");

    /* arguments 0 and 1 are self and _cmd, so the table is 2 and the row is 3 */
    initName = "initWithTable:startingRow:rowSpan:startingColumn:columnSpan:";
    PASS(takesNSIntegerAt(initName, 3) == YES,
      "the initialiser takes the starting row as an NSInteger");
    PASS(takesNSIntegerAt(initName, 4) == YES,
      "the initialiser takes the row span as an NSInteger");
    PASS(takesNSIntegerAt(initName, 5) == YES,
      "the initialiser takes the starting column as an NSInteger");
    PASS(takesNSIntegerAt(initName, 6) == YES,
      "the initialiser takes the column span as an NSInteger");

    /* and the values still read back */
    table = AUTORELEASE([[NSTextTable alloc] init]);
    block = AUTORELEASE([[NSTextTableBlock alloc] initWithTable: table
                                                   startingRow: 1
                                                       rowSpan: 2
                                                startingColumn: 3
                                                    columnSpan: 4]);
    PASS([block startingRow] == 1 && [block rowSpan] == 2
      && [block startingColumn] == 3 && [block columnSpan] == 4,
      "the row and column a block covers still read back");
  }

  END_SET("the row and column types")

  DESTROY(arp);
  return 0;
}
