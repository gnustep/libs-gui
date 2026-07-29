/* A keyword on the line after *OrderDependency or *UIConstraints must still be
   read.  The shipped Generic-PostScript_Printer-Postscript.ppd puts
   *DefaultPageSize, *DefaultPageRegion and *DefaultResolution directly after an
   *OrderDependency line, so losing that line leaves the printer with no default
   page size and no default resolution.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSPrinter.h>

static NSString *ppdText =
  @"*PPD-Adobe: \"4.3\"\n"
  @"*ModelName: \"Test\"\n"
  @"*OpenUI *PageSize/Page Size: PickOne\n"
  @"*OrderDependency: 100 AnySetup *PageSize\n"
  @"*DefaultPageSize: Letter\n"
  @"*PageSize Letter/US Letter: \"612 792\"\n"
  @"*CloseUI: *PageSize\n"
  @"*OrderDependency: 110 AnySetup *Resolution Default\n"
  @"*DefaultResolution: 600dpi\n"
  @"*UIConstraints: *PageSize Legal *Duplex\n"
  @"*DefaultColorSpace: Gray\n"
  @"*PaperDimension Letter/US Letter: \"612 792\"\n";

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("PPD keyword after OrderDependency")

  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  id savedPrinters = [ud objectForKey: @"GSLPRPrinters"];
  id savedBundle = [ud objectForKey: @"GSPrinting"];
  NSString *path;
  NSDictionary *entry;
  NSPrinter *printer = nil;

  path = [NSTemporaryDirectory()
           stringByAppendingPathComponent: @"gsOrderDependency.ppd"];

  if (![ppdText writeToFile: path atomically: YES])
    {
      SKIP("could not write a PPD to the temporary directory")
    }

  entry = [NSDictionary dictionaryWithObjectsAndKeys:
    path, @"PPDPath",
    @"localhost", @"Host",
    @"Test", @"Type",
    @"test", @"Note",
    nil];

  [ud setObject: @"GSLPR" forKey: @"GSPrinting"];
  [ud setObject: [NSDictionary dictionaryWithObject: entry
                                             forKey: @"OrderDependencyPrinter"]
         forKey: @"GSLPRPrinters"];

  NS_DURING
    {
      printer = [NSPrinter printerWithName: @"OrderDependencyPrinter"];
    }
  NS_HANDLER
    {
      printer = nil;
    }
  NS_ENDHANDLER

  if (printer == nil)
    {
      [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
      SKIP("no printing bundle able to read a PPD")
    }

  PASS_EQUAL([printer stringForKey: @"DefaultPageSize" inTable: @"PPD"],
             @"Letter",
             "*DefaultPageSize after *OrderDependency is read");

  PASS_EQUAL([printer stringForKey: @"DefaultResolution" inTable: @"PPD"],
             @"600dpi",
             "*DefaultResolution after an *OrderDependency with an option "
             "keyword is read");

  PASS_EQUAL([printer stringForKey: @"DefaultColorSpace" inTable: @"PPD"],
             @"Gray",
             "*DefaultColorSpace after *UIConstraints is read");

  PASS(NSEqualSizes([printer pageSizeForPaper: @"Letter"],
                    NSMakeSize(612, 792)),
       "the paper dimensions of the printer are read");

  [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];

  if (savedPrinters != nil)
    [ud setObject: savedPrinters forKey: @"GSLPRPrinters"];
  else
    [ud removeObjectForKey: @"GSLPRPrinters"];

  if (savedBundle != nil)
    [ud setObject: savedBundle forKey: @"GSPrinting"];
  else
    [ud removeObjectForKey: @"GSPrinting"];

  END_SET("PPD keyword after OrderDependency")

  DESTROY(arp);
  return 0;
}
