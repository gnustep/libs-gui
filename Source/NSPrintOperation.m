/* 
   NSPrintOperation.m

   Controls operations generating EPS, PDF or PS print jobs.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: November 2000
   Started implementation.

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
#include <Foundation/NSString.h>
#include <Foundation/NSData.h>
#include <Foundation/NSException.h>
#include <Foundation/NSThread.h>
#include <AppKit/AppKitExceptions.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSView.h>
#include <AppKit/NSPrintPanel.h>
#include <AppKit/NSPrintInfo.h>
#include <AppKit/NSPrintOperation.h>

@interface NSPrintOperation (Private)

- (void) setPath: (NSString *) path;

- (id) initWithView:(NSView *)aView
	 insideRect:(NSRect)rect
	     toData:(NSMutableData *)data
	  printInfo:(NSPrintInfo *)aPrintInfo;

- (id) initPDFOperationWithView:(NSView *)aView 
		     insideRect:(NSRect)rect 
			 toData:(NSMutableData *)data 
		      printInfo:(NSPrintInfo*)aPrintInfo;

@end

static NSString *NSPrintOperationThreadKey = @"NSPrintOperationThreadKey";

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
  return [self EPSOperationWithView: aView	
	       insideRect: rect
	       toData: data
	       printInfo: nil];
}

+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView	
				insideRect:(NSRect)rect
				    toData:(NSMutableData *)data
				 printInfo:(NSPrintInfo *)aPrintInfo
{
  return [[self alloc] initEPSOperationWithView: aView
		    insideRect: rect
			toData: data
		     printInfo: aPrintInfo];
}

+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView	
				insideRect:(NSRect)rect
				    toPath:(NSString *)path
				 printInfo:(NSPrintInfo *)aPrintInfo
{
  NSMutableData *data = [NSMutableData data];
  NSPrintOperation *new = [self EPSOperationWithView: aView	
				insideRect: rect
				toData: data
				printInfo: aPrintInfo];

  [new setPath: path];
  return new;
}

+ (NSPrintOperation *)printOperationWithView:(NSView *)aView
{
  return [self printOperationWithView: aView
	       printInfo: nil];
}

+ (NSPrintOperation *)printOperationWithView:(NSView *)aView
				   printInfo:(NSPrintInfo *)aPrintInfo
{
  return [[self alloc] initWithView: aView
		       printInfo: aPrintInfo];
}

+ (NSPrintOperation *)PDFOperationWithView:(NSView *)aView 
				insideRect:(NSRect)rect 
				    toData:(NSMutableData *)data
{
  return [self PDFOperationWithView: aView 
	       insideRect: rect 
	       toData: data 
	       printInfo: nil];
}

+ (NSPrintOperation *)PDFOperationWithView:(NSView *)aView 
				insideRect:(NSRect)rect 
				    toData:(NSMutableData *)data 
				 printInfo:(NSPrintInfo*)aPrintInfo
{
  return [[self alloc] initPDFOperationWithView: aView 
		       insideRect: rect 
		       toData: data 
		       printInfo: aPrintInfo];
}

+ (NSPrintOperation *)PDFOperationWithView:(NSView *)aView 
				insideRect:(NSRect)rect 
				    toPath:(NSString *)path 
				 printInfo:(NSPrintInfo*)aPrintInfo
{
  NSMutableData *data = [NSMutableData data];
  NSPrintOperation *new = [self PDFOperationWithView: aView	
				insideRect: rect
				toData: data
				printInfo: aPrintInfo];

  [new setPath: path];
  return new;
}

//
// Setting the Print Operation
//
+ (NSPrintOperation *)currentOperation
{
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];

  return (NSPrintOperation*)[dict objectForKey: NSPrintOperationThreadKey];
}

+ (void)setCurrentOperation:(NSPrintOperation *)operation
{
  NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];

  if (operation == nil)
    [dict removeObjectForKey: NSPrintOperationThreadKey];
  else
    [dict setObject: operation forKey: NSPrintOperationThreadKey];
}

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
  self = [self initWithView: aView
	       insideRect: rect
	       toData: data
	       printInfo: aPrintInfo];

  return self;
}

- (id)initWithView:(NSView *)aView
	 printInfo:(NSPrintInfo *)aPrintInfo
{
  NSMutableData *data = [NSMutableData data];
    
  self = [self initWithView: aView
	       insideRect: [aView bounds]
	       toData: data
	       printInfo: aPrintInfo];
  _showPanels = YES;

  return self;
}

- (void) dealloc
{
  RELEASE(_printInfo);
  RELEASE(_view);  
  RELEASE(_data);
  TEST_RELEASE(_path);  
  TEST_RELEASE(_context);
  TEST_RELEASE(_printPanel);  
  TEST_RELEASE(_accessoryView);  
}

//
// Determining the Type of Operation
//
- (BOOL)isEPSOperation
{
  return NO;
}

- (BOOL)isCopyingOperation
{
  return NO;
}

//
// Controlling the User Interface
//
- (NSPrintPanel *)printPanel
{
  if (_printPanel == nil)
    ASSIGN(_printPanel, [NSPrintPanel printPanel]); 

  return _printPanel;
}

- (BOOL)showPanels
{
  return _showPanels;
}

- (void)setPrintPanel:(NSPrintPanel *)panel
{
  ASSIGN(_printPanel, panel);
}

- (void)setShowPanels:(BOOL)flag
{
  _showPanels = flag;
}

- (NSView *)accessoryView
{
  return _accessoryView;
}

- (void)setAccessoryView:(NSView *)aView
{
  ASSIGN(_accessoryView, aView);
}

//
// Managing the drawing Context
//
- (NSGraphicsContext*)createContext
{
  // FIXME
  return _context;
}

- (NSGraphicsContext *)context
{
  return _context;
}

- (void)destroyContext
{
  DESTROY(_context);
}

//
// Page Information
//
- (int)currentPage
{
  // FIXME
  return 0;
}

- (NSPrintingPageOrder)pageOrder
{
  return _pageOrder;
}

- (void)setPageOrder:(NSPrintingPageOrder)order
{
  _pageOrder = order;
}

//
// Running a Print Operation
//
- (void)cleanUpOperation
{
  [NSPrintOperation setCurrentOperation: nil];
}

- (BOOL)deliverResult
{
  // FIXME
  return NO;
}

- (BOOL)runOperation
{
  BOOL result;
  NSGraphicsContext *oldContext;

  if (_showPanels)
    {
	NSPrintPanel *panel = [self printPanel];
	int button;

	[panel setAccessoryView: _accessoryView];
	[panel updateFromPrintInfo];
	button = [panel runModal];
	[panel setAccessoryView: nil];

	if (button != NSOKButton)
	{
	  [self cleanUpOperation];
	  return NO;
	}
	[panel finalWritePrintInfo];
    }

  // This is the actual printing
  oldContext = [NSGraphicsContext currentContext];
  [NSGraphicsContext setCurrentContext: [self createContext]];
  [_view displayRect: _rect];
  [NSGraphicsContext setCurrentContext: oldContext];

  result = [self deliverResult];
  [self cleanUpOperation];
  return result;
}

//
// Getting the NSPrintInfo Object
//
- (NSPrintInfo *)printInfo
{
  return _printInfo;
}

- (void)setPrintInfo:(NSPrintInfo *)aPrintInfo
{
  if (aPrintInfo == nil)
    aPrintInfo = [NSPrintInfo sharedPrintInfo];

  ASSIGNCOPY(_printInfo, aPrintInfo);
}

//
// Getting the NSView Object
//
- (NSView *)view
{
  return _view;
}

@end


@implementation NSPrintOperation (Private)

- (void) setPath: (NSString *) path
{
  ASSIGN(_path, path);
}

- (id) initWithView:(NSView *)aView
	 insideRect:(NSRect)rect
	     toData:(NSMutableData *)data
	  printInfo:(NSPrintInfo *)aPrintInfo
{
  if ([NSPrintOperation currentOperation] != nil)
    [NSException raise: NSPrintOperationExistsException
		 format: @"There is already a printoperation for this thread"];

  ASSIGN(_view, aView);
  _rect = rect;
  ASSIGN(_data, data);
  _pageOrder = NSUnknownPageOrder;
  _showPanels = NO;
  [self setPrintInfo: aPrintInfo];

  [NSPrintOperation setCurrentOperation: self];
  return self;
}

- (id) initPDFOperationWithView:(NSView *)aView 
		     insideRect:(NSRect)rect 
			 toData:(NSMutableData *)data 
		      printInfo:(NSPrintInfo*)aPrintInfo
{
  self = [self initWithView: aView
	       insideRect: rect
	       toData: data
	       printInfo: aPrintInfo];

  return self;
}

@end
