/* 
   GLPRSPrintOperation.m

   Controls operations generating EPS, PDF or PS print jobs.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: November 2000
   Started implementation.
   Modified for Printing Backend Support
   Author: Chad Hardin
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

#include <math.h>
#include <config.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSData.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSException.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSValue.h>
#include <AppKit/AppKitExceptions.h>
#include <AppKit/NSAffineTransform.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSView.h>
#include <AppKit/NSPrinter.h>
#include <AppKit/NSPrintPanel.h>
#include <AppKit/NSPrintInfo.h>
#include <AppKit/NSPrintOperation.h>
#include <AppKit/NSWorkspace.h>
#include <AppKit/PSOperators.h>
#include "GSLPRPrintOperation.h"

#define NSNUMBER(a) [NSNumber numberWithInt: (a)]
#define NSFNUMBER(a) [NSNumber numberWithFloat: (a)]




//A subclass of GSPrintOperation, NOT NSPrintOperation.
@implementation GSLPRPrintOperation
//
// Class methods
//
+ (id) allocWithZone: (NSZone*)zone
{
  NSDebugMLLog(@"GSPrinting", @"");
  return NSAllocateObject(self, 0, zone);
}


- (id)initWithView:(NSView *)aView
	       printInfo:(NSPrintInfo *)aPrintInfo
{
  self = [super initWithView: aView
                   printInfo: aPrintInfo];

  _path = [NSTemporaryDirectory() stringByAppendingPathComponent: @"GSLPRPrintJob-"];
  
  _path = [_path stringByAppendingString: 
		       [[NSProcessInfo processInfo] globallyUniqueString]];
           
  _path = [_path stringByAppendingPathExtension: @"ps"];
  
  RETAIN( _path ); 
  
  return self;
}
  


- (BOOL) _deliverSpooledResult
{
  int copies;
  NSDictionary *dict;
  NSTask *task;
  NSString *name, *status;
  NSMutableArray *args;
  
  NSDebugMLLog(@"GSPrinting", @"");
  name = [[_printInfo printer] name];
  status = [NSString stringWithFormat: @"Spooling to printer %@.", name];
  [_printPanel _setStatusStringValue: status];

  dict = [_printInfo dictionary];
  args = [NSMutableArray array];
  copies = [[dict objectForKey: NSPrintCopies] intValue];
  if (copies > 1)
    [args addObject: [NSString stringWithFormat: @"-#%0d", copies]];
  if ([name isEqual: @"Unknown"] == NO)
    {
      [args addObject: @"-P"];
      [args addObject: name];
    }
  [args addObject: _path];

  task = [NSTask new];
  [task setLaunchPath: @"lpr"];
  [task setArguments: args];
  [task launch];
  [task waitUntilExit];
  AUTORELEASE(task);
  return YES;
}

- (NSGraphicsContext*)createContext
{
  NSMutableDictionary *info;
  
  //NSDebugMLLog(@"GSPrinting", @"_path is %@", _path);
  if (_context)
    {
      NSDebugMLLog(@"GSPrinting", @"Already had context, returning it.");
      return _context;
    }
  NSDebugMLLog(@"GSPrinting", @"Creating context.");

  info = [_printInfo dictionary];
  if (_path == nil)
    {
      NSString *output = [info objectForKey: NSPrintSavePath];
      
      if (output)
        {
          ASSIGN(_path, output);
        }        
    }
    
  NSDebugMLLog(@"GSPrinting", @"_path is %@", _path); 
  
  [info setObject: _path 
           forKey: @"NSOutputFile"];
  
  [info setObject: NSGraphicsContextPSFormat
           forKey: NSGraphicsContextRepresentationFormatAttributeName];
           
  _context = RETAIN([NSGraphicsContext graphicsContextWithAttributes: info]);

  return _context;
}

@end
