/* 
   NSPrintOperation.h

   Controls operations generating EPS, PDF or PS print jobs.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: November 2000
   Updated to new specification

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

#ifndef _GNUstep_H_NSPrintOperation
#define _GNUstep_H_NSPrintOperation

#include <Foundation/NSObject.h>
#include <Foundation/NSGeometry.h>

@class NSString;
@class NSData;
@class NSMutableData;

@class NSView;
@class NSPrintInfo;
@class NSPrintPanel;
@class NSGraphicsContext;

typedef enum _NSPrintingPageOrder {
  NSDescendingPageOrder,
  NSSpecialPageOrder,
  NSAscendingPageOrder,
  NSUnknownPageOrder
} NSPrintingPageOrder;

@interface NSPrintOperation : NSObject
{
  // Attributes
  NSPrintInfo *_printInfo;
  NSView *_view;
  NSRect _rect;
  NSMutableData *_data;
  NSString *_path;
  NSGraphicsContext *_context;
  NSPrintPanel *_printPanel;
  NSView *_accessoryView;
  NSPrintingPageOrder _pageOrder;
  BOOL _showPanels;
  BOOL _pathSet;
  int  _currentPage;
}

//
// Creating and Initializing an NSPrintOperation Object
//
+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView
				insideRect:(NSRect)rect
				    toData:(NSMutableData *)data;
+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView	
				insideRect:(NSRect)rect
				    toData:(NSMutableData *)data
				 printInfo:(NSPrintInfo *)aPrintInfo;
+ (NSPrintOperation *)EPSOperationWithView:(NSView *)aView	
				insideRect:(NSRect)rect
				    toPath:(NSString *)path
				printInfo:(NSPrintInfo *)aPrintInfo;

+ (NSPrintOperation *)printOperationWithView:(NSView *)aView;
+ (NSPrintOperation *)printOperationWithView:(NSView *)aView
				   printInfo:(NSPrintInfo *)aPrintInfo;

#ifndef	STRICT_OPENSTEP
+ (NSPrintOperation *)PDFOperationWithView:(NSView *)aView 
				insideRect:(NSRect)rect 
				    toData:(NSMutableData *)data;
+ (NSPrintOperation *)PDFOperationWithView:(NSView *)aView 
				insideRect:(NSRect)rect 
				    toData:(NSMutableData *)data 
				 printInfo:(NSPrintInfo*)aPrintInfo;
+ (NSPrintOperation *)PDFOperationWithView:(NSView *)aView 
				insideRect:(NSRect)rect 
				    toPath:(NSString *)path 
				 printInfo:(NSPrintInfo*)aPrintInfo;
#endif

- (id)initEPSOperationWithView:(NSView *)aView
		    insideRect:(NSRect)rect
			toData:(NSMutableData *)data
		    printInfo:(NSPrintInfo *)aPrintInfo;
- (id)initWithView:(NSView *)aView
	 printInfo:(NSPrintInfo *)aPrintInfo;

//
// Setting the Print Operation
//
+ (NSPrintOperation *)currentOperation;
+ (void)setCurrentOperation:(NSPrintOperation *)operation;

//
// Determining the Type of Operation
//
- (BOOL)isEPSOperation;

#ifndef	STRICT_OPENSTEP
- (BOOL)isCopyingOperation;
#endif

//
// Controlling the User Interface
//
- (NSPrintPanel *)printPanel;
- (BOOL)showPanels;
- (void)setPrintPanel:(NSPrintPanel *)panel;
- (void)setShowPanels:(BOOL)flag;

#ifndef	STRICT_OPENSTEP
- (NSView *)accessoryView;
- (void)setAccessoryView:(NSView *)aView;
#endif

//
// Managing the DPS Context
//
- (NSGraphicsContext *)createContext;
- (NSGraphicsContext *)context;
- (void)destroyContext;

//
// Page Information
//
- (int)currentPage;
- (NSPrintingPageOrder)pageOrder;
- (void)setPageOrder:(NSPrintingPageOrder)order;

//
// Running a Print Operation
//
- (void)cleanUpOperation;
- (BOOL)deliverResult;
- (BOOL)runOperation;
#ifndef STRICT_OPENSTEP
- (void)runOperationModalForWindow: (NSWindow *)docWindow 
			  delegate: (id)delegate 
		    didRunSelector: (SEL)didRunSelector 
		       contextInfo:(void *)contextInfo;
#endif

//
// Getting the NSPrintInfo Object
//
- (NSPrintInfo *)printInfo;
- (void)setPrintInfo:(NSPrintInfo *)aPrintInfo;

//
// Getting the NSView Object
//
- (NSView *)view;

@end

#endif // _GNUstep_H_NSPrintOperation
