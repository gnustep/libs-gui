/* A printer stored in the GSLPRPrinters defaults can point at a PPD file that
   has moved or been removed. Loading it must not raise an uncaught exception
   (which aborts the application while it is only setting up printing); the
   printer is returned without the PPD so the caller falls back to its defaults.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSPrinter.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSPrinter missing PPD")

  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  id saved = [ud objectForKey: @"GSLPRPrinters"];
  NSDictionary *entry;
  NSDictionary *printers;
  NSPrinter *printer = nil;
  BOOL raised = NO;

  entry = [NSDictionary dictionaryWithObjectsAndKeys:
    @"/does/not/exist/Generic.ppd", @"PPDPath",
    @"localhost", @"Host",
    @"Unknown", @"Type",
    @"test", @"Note",
    nil];
  printers = [NSDictionary dictionaryWithObject: entry forKey: @"MissingPPDPrinter"];
  [ud setObject: printers forKey: @"GSLPRPrinters"];

  NS_DURING
    {
      printer = [NSPrinter printerWithName: @"MissingPPDPrinter"];
    }
  NS_HANDLER
    {
      raised = YES;
    }
  NS_ENDHANDLER

  PASS(raised == NO,
       "loading a printer whose PPD is missing does not raise");
  PASS(printer != nil,
       "a printer is still returned when its PPD is missing");

  if (saved != nil)
    [ud setObject: saved forKey: @"GSLPRPrinters"];
  else
    [ud removeObjectForKey: @"GSLPRPrinters"];

  END_SET("NSPrinter missing PPD")

  DESTROY(arp);
  return 0;
}
