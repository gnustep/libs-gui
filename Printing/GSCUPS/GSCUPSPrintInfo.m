/* 
   GSCUPSPrintInfo.m

   Stores information used in printing

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

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSValue.h>
#include <AppKit/NSPrinter.h>
#include "GSCUPSPrintInfo.h"
#include "GSCUPSPrinter.h"
#include <cups/cups.h>


@implementation GSCUPSPrintInfo

//
// Class methods
//
+ (void)initialize
{
  NSDebugMLLog(@"GSPrinting", @"");
  if (self == [GSCUPSPrintInfo class])
    {
      // Initial version
      [self setVersion:1];
    }
}


+ (id) allocWithZone: (NSZone*)zone
{
  NSDebugMLLog(@"GSPrinting", @"");
  return NSAllocateObject(self, 0, zone);
}


+(NSPrinter*) defaultPrinter
{
  const char *defaultName;
  
  defaultName = cupsGetDefault();
  NSDebugLLog(@"GSCUPS", @"The default printer name is %s", defaultName);

  if (defaultName)
    {
      return [NSPrinter printerWithName:
	       [NSString stringWithCString: defaultName]];
    }
  else
    {
      return [NSPrinter printerWithName: GSCUPSDummyPrinterName];
    }  
}



+ (void)setDefaultPrinter:(NSPrinter *)printer
{
  NSString* name;
  int numDests;
  cups_dest_t* dests;
  int n;
  BOOL found = NO;
  
  name = [printer name];
  
  numDests = cupsGetDests( &dests );

  for( n = 0; n < numDests; n++ )
    {
      if( [name isEqualToString: [NSString stringWithCString: dests[n].name]] &&
          dests[n].instance == NULL)
        {
          found = YES;
          break;
        }
    }

  if( found == NO )
    {
      NSDebugMLLog(@"GSPrinting", @"Printer %@ not found", name);
      return;
    }

  for( n = 0; n < numDests; n++ )
    {
      dests[n].is_default = 0;
    }

  for( n = 0; n < numDests; n++ )
    {
      if( [name isEqualToString: [NSString stringWithCString: dests[n].name]] &&
          dests[n].instance == NULL)
        {
          dests[n].is_default = 1;
          break;
        }
    }

  cupsSetDests( numDests, dests );
  cupsFreeDests( numDests, dests );
}

@end
