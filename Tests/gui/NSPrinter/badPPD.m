/* A printer stored in a printing bundle's defaults can point at a PPD file
   that has moved or been removed. Loading it must not raise an uncaught
   exception (which aborts the application while it is only setting up
   printing); the printer is returned without the PPD so the caller falls back
   to its defaults.

   The entry is written under the key of each bundle that reads one, since
   which bundle is loaded is a property of the platform: GSLPR on Unix and
   GSWIN32 on Windows, where only one of the two is installed.
*/
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSException.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSPrinter.h>

int
main(int argc, char **argv)
{
  START_SET("NSPrinter missing PPD")

  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSArray *keys = [NSArray arrayWithObjects:
    @"GSLPRPrinters", @"GSWIN32Printers", nil];
  NSMutableDictionary *saved = [NSMutableDictionary dictionary];
  NSEnumerator *keyEnum;
  NSString *key;
  NSDictionary *entry;
  NSDictionary *printers;
  NSPrinter *printer = nil;

  entry = [NSDictionary dictionaryWithObjectsAndKeys:
    @"/does/not/exist/Generic.ppd", @"PPDPath",
    @"localhost", @"Host",
    @"Unknown", @"Type",
    @"test", @"Note",
    nil];
  printers = [NSDictionary dictionaryWithObject: entry forKey: @"MissingPPDPrinter"];

  keyEnum = [keys objectEnumerator];
  while ((key = [keyEnum nextObject]) != nil)
    {
      id was = [ud objectForKey: key];

      if (was != nil)
	{
	  [saved setObject: was forKey: key];
	}
      [ud setObject: printers forKey: key];
    }

  PASS_RUNS(({
    printer = [NSPrinter printerWithName: @"MissingPPDPrinter"];
  }), "loading a printer whose PPD is missing does not raise");
  PASS(printer != nil,
       "a printer is still returned when its PPD is missing");

  keyEnum = [keys objectEnumerator];
  while ((key = [keyEnum nextObject]) != nil)
    {
      id was = [saved objectForKey: key];

      if (was != nil)
	{
	  [ud setObject: was forKey: key];
	}
      else
	{
	  [ud removeObjectForKey: key];
	}
    }

  END_SET("NSPrinter missing PPD")

  return 0;
}
