/* 
   GSLPRPrintInfo.m

   Stores information used in printing

   Copyright (C) 1996,1997,2004 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: July 1997
   Modified for Printing Backend Support
   Author: Chad Hardin <cehardin@mac.com>
   Date: June 2004
   
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
#include "GSLPRPrintInfo.h"
#include "GSLPRPrinter.h"




@implementation GSLPRPrintInfo

//
// Class methods
//
+ (void)initialize
{
  NSDebugMLLog(@"GSPrinting", @"");
  if (self == [GSLPRPrintInfo class])
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
  NSUserDefaults *defaults;
  NSString *name;
    
  NSDebugMLLog(@"GSPrinting", @"");
  defaults = [NSUserDefaults standardUserDefaults];
  name = [defaults objectForKey: @"GSLPRDefaultPrinter"];
  
  if( name == nil )
    {
      name = [[GSLPRPrinter printerNames] objectAtIndex: 0];
    }
  else
    {
      if( [GSLPRPrinter printerWithName: name] == nil )
        {
          name = [[GSLPRPrinter printerNames] objectAtIndex: 0];
        }
    }
  return [GSLPRPrinter printerWithName: name];
}



+ (void)setDefaultPrinter:(NSPrinter *)printer
{
  NSUserDefaults *defaults;
  NSMutableDictionary *globalDomain;
  
  NSDebugMLLog(@"GSPrinting", @"");  
  defaults = [NSUserDefaults standardUserDefaults];
  
  globalDomain = (NSMutableDictionary*)[defaults persistentDomainForName: NSGlobalDomain];
  
  if( globalDomain )
    {
      globalDomain = [globalDomain mutableCopy];
  
      [globalDomain setObject: [printer name]
                       forKey: @"GSLPRDefaultPrinter"];
  
      [defaults setPersistentDomain: globalDomain
                            forName: NSGlobalDomain];
    }
  else
    {
      NSDebugMLLog(@"GSPrinting", @"(GSLPR) Could not save default printer named %@ to NSUserDefaults GSLPRDefaultPrinter in NSGlobalDomain.", [printer name]);
    }

}




-(id) initWithDictionary:(NSDictionary *)aDict
{
  NSPrinter *printer;
  NSString *pageSize;
  NSSize size;
  NSMutableDictionary *dict;
  
  NSDebugMLLog(@"GPrinting", @"");
  self = [super initWithDictionary: nil];

  printer = [GSLPRPrintInfo defaultPrinter];
  [self setPrinter: printer];
      

  /* Set up other defaults from the printer object */
  pageSize = [printer stringForKey: @"DefaultPageSize" 
                         inTable: @"PPD"];
                      
  /* FIXME: Need to check for AutoSelect and probably a million other things... */
  if (pageSize == nil)
    pageSize = @"A4";
  
  [self setPaperName: pageSize];
  
  /* Set default margins. FIXME: Probably should check ImageableArea */
  [self setRightMargin: 36];
  
  [self setLeftMargin: 36];
  
  [self setTopMargin: 72];
  
  [self setBottomMargin: 72];
                        
  return self;
}


    
 
@end
