/** <title>GSCUPSPrinter</title>

   <abstract>Class representing a printer's or printer model's capabilities.</abstract>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Chad Hardin <cehardin@mac.com>
   Date: October 2004
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/ 

/* NB:
 * There are a few FIXMEs in the functionality left.
 * Parsing of the PPDs is somewhat suboptimal.
 * (I think it's best to leave optimisation until more of GNUstep is done).
 * The *OpenUI, *CloseUI, *OpenGroup and *CloseGroup are not processed.
 * (This is not required in the OpenStep standard, but could be useful).
 */

#include "config.h"
#include <Foundation/NSDebug.h>
//#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
//#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
//#include <Foundation/NSBundle.h>
//#include <Foundation/NSCharacterSet.h>
//#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>
//#include <Foundation/NSScanner.h>
//#include <Foundation/NSString.h>
//#include <Foundation/NSUserDefaults.h>
//#include <Foundation/NSUtilities.h>
//#include <Foundation/NSValue.h>
//#include <Foundation/NSMapTable.h>
#include <Foundation/NSSet.h>
#include "AppKit/AppKitExceptions.h"
#include "AppKit/NSGraphics.h"
#include "GSCUPSPrinter.h"
#include "GNUstepGUI/GSPrinting.h"
#include <cups/cups.h>


NSString *GSCUPSDummyPrinterName = @"GSCUPSDummyPrinter";

@implementation GSCUPSPrinter

//
// Class methods
//
+(void) initialize
{
  NSDebugMLLog(@"GSPrinting", @"");
  if (self == [GSCUPSPrinter class])
    {
      // Initial version
      [self setVersion:1];
    }
}


+(id) allocWithZone: (NSZone*) zone
{
  NSDebugMLLog(@"GSPrinting", @"");
  return NSAllocateObject(self, 0, zone);
}

//
// Finding an NSPrinter 
//
+ (NSPrinter*) printerWithName: (NSString*) name
{
  NSPrinter* printer;
  const char* ppdFile;

  if ([name isEqual: GSCUPSDummyPrinterName])
    {
      /* Create a dummy printer as a fallback.  */
static BOOL didWarn;
      NSString *ppdPath;

      if (!didWarn)
	{
	  NSLog(@"Creating a default printer since no default printer has "
		@"been set in CUPS.");
	  didWarn = YES;
	}

      ppdPath = [NSBundle
	pathForLibraryResource: @"Generic-PostScript_Printer-Postscript"
			ofType: @"ppd"
		   inDirectory: @"PostScript/PPD"];
      NSAssert(ppdPath,
	       @"Couldn't find the PPD file for the fallback printer.");

      printer = [(GSCUPSPrinter*)[self alloc]
		  initWithName: name
		      withType: @"Unknown"
		      withHost: @"Unknown"
		      withNote: @"Automatically Generated"];

      [printer parsePPDAtPath: ppdPath];

      return printer;
    }

  printer = [[GSCUPSPrinter alloc]
                    initWithName: name
                        withType: @"Type Unknown"
                        withHost: @"Host Unknown"
                        withNote: @"No Note"];

  ppdFile = cupsGetPPD( [name UTF8String] );

  if( ppdFile )
    {
      [printer parsePPDAtPath: [NSString stringWithCString: ppdFile]];
      unlink( ppdFile );
    }
  else
    {
      NSLog(@"Printer %@ does not have a PPD!", name);
    }
                         
  return AUTORELEASE(printer);
}


+ (NSArray *)printerNames
{
  NSMutableSet *set;
  int numDests;
  cups_dest_t* dests;
  int n;

  set = [[NSMutableSet alloc] init];
  AUTORELEASE( set );

  numDests = cupsGetDests( &dests );
  
  for( n = 0; n < numDests; n++ )
    {
      [set addObject: [NSString stringWithCString: dests[n].name]];
    }

  cupsFreeDests( numDests, dests );

  // No printer found, return at least the dummy printer
  if ([set count] == 0)
    {
      [set addObject: GSCUPSDummyPrinterName];
    }

  return [set allObjects];
}


-(id) initWithCoder: (NSCoder*) coder
{
  return [super initWithCoder: coder];
}


-(void) encodeWithCoder: (NSCoder*) coder
{
  [super encodeWithCoder: coder];
}


@end

