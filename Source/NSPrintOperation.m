/* 
   NSPrintOperation.m

   Description...

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#include <gnustep/gui/config.h>
#include <AppKit/NSPrintOperation.h>

@implementation NSPrintOperation

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPrintOperation class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Creating and Initializing an NSPrintOperation Object
//
+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView
				insideRect:(NSRect)rect
toData:(NSMutableData *)data
{
  return nil;
}

+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView	
				insideRect:(NSRect)rect
toData:(NSMutableData *)data
				printInfo:(NSPrintInfo *)aPrintInfo
{
  return nil;
}

+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView	
				insideRect:(NSRect)rect
toPath:(NSString *)path
				printInfo:(NSPrintInfo *)aPrintInfo
{
  return nil;
}

+ (NSPrintOperation *)printOperationWithView:(NSView *)aView
{
  return nil;
}

+ (NSPrintOperation *)printOperationWithView:(NSView *)aView
				   printInfo:(NSPrintInfo *)aPrintInfo
{
  return nil;
}

//
// Setting the Print Operation
//
+ (NSPrintOperation *)currentOperation
{
  return nil;
}

+ (void)setCurrentOperation:(NSPrintOperation *)operation
{}

//
// Instance methods
//
//
// Creating and Initializing an NSPrintOperation Object
//
- (id)initEPSOperationWithView:(NSView *)aView
		    insideRect:(NSRect)rect
toData:(NSMutableData *)data
		    printInfo:(NSPrintInfo *)aPrintInfo
{
  return nil;
}

- (id)initWithView:(NSView *)aView
	 printInfo:(NSPrintInfo *)aPrintInfo
{
  return nil;
}

//
// Determining the Type of Operation
//
- (BOOL)isEPSOperation
{
  return NO;
}

//
// Controlling the User Interface
//
- (NSPrintPanel *)printPanel
{
  return nil;
}

- (BOOL)showPanels
{
  return NO;
}

- (void)setPrintPanel:(NSPrintPanel *)panel
{}

- (void)setShowPanels:(BOOL)flag
{}

//
// Managing the DPS Context
//
- (NSDPSContext *)createContext
{
  return nil;
}

- (NSDPSContext *)context
{
  return nil;
}

- (void)destroyContext
{}

//
// Page Information
//
- (int)currentPage
{
  return 0;
}

- (NSPrintingPageOrder)pageOrder
{
  return 0;
}

- (void)setPageOrder:(NSPrintingPageOrder)order
{}

//
// Running a Print Operation
//
- (void)cleanUpOperation
{}

- (BOOL)deliverResult
{
  return NO;
}

- (BOOL)runOperation
{
  return NO;
}

//
// Getting the NSPrintInfo Object
//
- (NSPrintInfo *)printInfo
{
  return nil;
}

- (void)setPrintInfo:(NSPrintInfo *)aPrintInfo
{}

//
// Getting the NSView Object
//
- (NSView *)view
{
  return nil;
}

@end
