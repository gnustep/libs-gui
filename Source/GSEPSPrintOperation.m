/* 
   GSEPSPrintOperation.m

   Controls operations generating EPS output files.

   Copyright (C) 1996, 2004 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: November 2000
   Started implementation.
   Author: Chad Hardin <cehardin@mac.com>
   Date: June 2004
   Modified for printing backend support, split off from NSPrintOperation.m

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 


#include <Foundation/NSDebug.h>
#include <Foundation/NSData.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSProcessInfo.h>
#include "AppKit/NSView.h"
#include "AppKit/NSPrintInfo.h"
#include "AppKit/NSPrintOperation.h"
#include "GNUstepGUI/GSEPSPrintOperation.h"


/**
  <unit>
  <heading>Class Description</heading>
  <p>
  GSEPSPrintOperation is a subclass of NSPrintOperation
  that can create eps files suitable for saving, previewing, etc.
  </p>
  </unit>
*/ 

@implementation GSEPSPrintOperation

- (id)initWithView:(NSView *)aView
        insideRect:(NSRect)rect
            toData:(NSMutableData *)data
         printInfo:(NSPrintInfo *)aPrintInfo
{
  self = [super initWithView: aView
                  insideRect: rect
                      toData: data
                   printInfo: aPrintInfo];
                   
  _path = [NSTemporaryDirectory() stringByAppendingPathComponent: @"GSPrint-"];
  
  _path = [_path stringByAppendingString: 
		               [[NSProcessInfo processInfo] globallyUniqueString]];
           
  _path = [_path stringByAppendingPathExtension: @"ps"];
  RETAIN(_path); 
  return self;
}

- (id) initWithView:(NSView *)aView	
         insideRect:(NSRect)rect
             toPath:(NSString *)path
          printInfo:(NSPrintInfo *)aPrintInfo
{
  NSMutableData *data = [NSMutableData data];
  
  self = [super initWithView: aView	
                  insideRect: rect
                      toData: data
                   printInfo: aPrintInfo];

  ASSIGN(_path, path);

  return self;
}

- (void) _print
{
  /* Save this for the view to look at. Seems like there should
     be a better way to pass it to beginDocument */
  [[[self printInfo] dictionary] setObject: [NSValue valueWithRect: _rect]
				 forKey: @"NSPrintSheetBounds"];
                              
  [_view beginDocument];
  
  [_view beginPageInRect: _rect 
             atPlacement: NSMakePoint(0,0)];
             
  [_view displayRectIgnoringOpacity: _rect];
  [_view endDocument];
}

- (BOOL)isEPSOperation
{
  return YES;
}

- (BOOL)deliverResult
{
  if (_data != nil && _path != nil)
    {
      NSString	*eps;

      eps = [NSString stringWithContentsOfFile: _path];
      
      [_data setData: [eps dataUsingEncoding:NSASCIIStringEncoding]];
    }

  return YES;
}

- (NSGraphicsContext*)createContext
{
  NSMutableDictionary *info;

  if (_context)
    return _context;

  info = [[self printInfo] dictionary];
  
  [info setObject: _path 
           forKey: @"NSOutputFile"];
  
  [info setObject: NSGraphicsContextPSFormat
           forKey: NSGraphicsContextRepresentationFormatAttributeName];
           
  _context = RETAIN([NSGraphicsContext graphicsContextWithAttributes: info]);
  return _context;
}

@end
