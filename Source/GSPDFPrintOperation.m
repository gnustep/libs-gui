/* 
   GSPDFPrintOperation.m

   Controls operations generating PDF output files.

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 


#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSProcessInfo.h>
#include "AppKit/NSView.h"
#include "GNUstepGUI/GSPDFPrintOperation.h"


/**
  <unit>
  <heading>Class Description</heading>
  <p>
  GSPDFPrintOperation produces PDF files for saving, previewing, etc
  </p>
  </unit>
*/ 


@implementation GSPDFPrintOperation

- (id) initWithView:(NSView *)aView 
         insideRect:(NSRect)rect 
             toData:(NSMutableData *)data 
          printInfo:(NSPrintInfo*)aPrintInfo
{
  self = [super initWithView: aView
                  insideRect: rect
                      toData: data
                   printInfo: aPrintInfo];
                   
  _path = [NSTemporaryDirectory() stringByAppendingPathComponent: @"GSPrint-"];
  
  _path = [_path stringByAppendingString: 
		               [[NSProcessInfo processInfo] globallyUniqueString]];
           
  _path = [_path stringByAppendingPathExtension: @"pdf"];
  RETAIN( _path );
                  
  return self;
}

- (id) initWithView:(NSView *)aView 
         insideRect:(NSRect)rect 
             toPath:(NSString *)path 
          printInfo:(NSPrintInfo*)aPrintInfo
{
  NSMutableData *data = [NSMutableData data];

  self = [super initWithView: aView	
                  insideRect: rect
                      toData: data
                   printInfo: aPrintInfo];

  ASSIGN(_path, path);

  return self;
}

- (NSGraphicsContext*)createContext
{
  // FIXME
  return nil;
}

- (void) _print
{
  [_view displayRectIgnoringOpacity: _rect];
}

- (BOOL)deliverResult
{
  if (_data != nil && _path != nil && [_data length])
    return [_data writeToFile: _path atomically: NO];
  // FIXME Until we can create PDF we shoud convert the file with GhostScript
  
  return YES;
}

@end
