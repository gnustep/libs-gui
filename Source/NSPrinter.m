/* 
   NSPrinter.m

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

#include <AppKit/NSPrinter.h>

// Printing Information Dictionary Keys 
NSString *NSPrintAllPages = @"NSPrintAllPages";
NSString *NSPrintBottomMargin = @"NSPrintBottomMargin";
NSString *NSPrintCopies = @"NSPrintCopies";
NSString *NSPrintFaxCoverSheetName = @"NSPrintFaxCoverSheetName";
NSString *NSPrintFaxHighResolution = @"NSPrintFaxHighResolution";
NSString *NSPrintFaxModem = @"NSPrintFaxModem";
NSString *NSPrintFaxReceiverNames = @"NSPrintFaxReceiverNames";
NSString *NSPrintFaxReceiverNumbers = @"NSPrintFaxReceiverNumbers";
NSString *NSPrintFaxReturnReceipt = @"NSPrintFaxReturnReceipt";
NSString *NSPrintFaxSendTime = @"NSPrintFaxSendTime";
NSString *NSPrintFaxTrimPageEnds = @"NSPrintFaxTrimPageEnds";
NSString *NSPrintFaxUseCoverSheet = @"NSPrintFaxUseCoverSheet";
NSString *NSPrintFirstPage = @"NSPrintFirstPage";
NSString *NSPrintHorizonalPagination = @"NSPrintHorizonalPagination";
NSString *NSPrintHorizontallyCentered = @"NSPrintHorizontallyCentered";
NSString *NSPrintJobDisposition = @"NSPrintJobDisposition";
NSString *NSPrintJobFeatures = @"NSPrintJobFeatures";
NSString *NSPrintLastPage = @"NSPrintLastPage";
NSString *NSPrintLeftMargin = @"NSPrintLeftMargin";
NSString *NSPrintManualFeed = @"NSPrintManualFeed";
NSString *NSPrintOrientation = @"NSPrintOrientation";
NSString *NSPrintPagesPerSheet = @"NSPrintPagesPerSheet";
NSString *NSPrintPaperFeed = @"NSPrintPaperFeed";
NSString *NSPrintPaperName = @"NSPrintPaperName";
NSString *NSPrintPaperSize = @"NSPrintPaperSize";
NSString *NSPrintPrinter = @"NSPrintPrinter";
NSString *NSPrintReversePageOrder = @"NSPrintReversePageOrder";
NSString *NSPrintRightMargin = @"NSPrintRightMargin";
NSString *NSPrintSavePath = @"NSPrintSavePath";
NSString *NSPrintScalingFactor = @"NSPrintScalingFactor";
NSString *NSPrintTopMargin = @"NSPrintTopMargin";
NSString *NSPrintVerticalPagination = @"NSPrintVerticalPagination";
NSString *NSPrintVerticallyCentered = @"NSPrintVerticallyCentered";

// Print Job Disposition Values 
NSString  *NSPrintCancelJob = @"NSPrintCancelJob";
NSString  *NSPrintFaxJob = @"NSPrintFaxJob";
NSString  *NSPrintPreviewJob = @"NSPrintPreviewJob";
NSString  *NSPrintSaveJob = @"NSPrintSaveJob";
NSString  *NSPrintSpoolJob = @"NSPrintSpoolJob";

@implementation NSPrinter

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPrinter class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Finding an NSPrinter 
//
+ (NSPrinter *)printerWithName:(NSString *)name
{
  return nil;
}

+ (NSPrinter *)printerWithType:(NSString *)type
{
  return nil;
}

+ (NSArray *)printerTypes
{
  return nil;
}

//
// Instance methods
//
//
// Printer Attributes 
//
- (NSString *)host
{
  return nil;
}

- (NSString *)name
{
  return nil;
}

- (NSString *)note
{
  return nil;
}

- (NSString *)type
{
  return nil;
}

//
// Retrieving Specific Information 
//
- (BOOL)acceptsBinary
{
  return NO;
}

- (NSRect)imageRectForPaper:(NSString *)paperName
{
  return NSZeroRect;
}

- (NSSize)pageSizeForPaper:(NSString *)paperName
{
  return NSZeroSize;
}

- (BOOL)isColor
{
  return NO;
}

- (BOOL)isFontAvailable:(NSString *)fontName
{
  return NO;
}

- (int)languageLevel
{
  return 0;
}

- (BOOL)isOutputStackInReverseOrder
{
  return NO;
}

//
// Querying the NSPrinter Tables 
//
- (BOOL)booleanForKey:(NSString *)key
	      inTable:(NSString *)table
{
  return NO;
}

- (NSDictionary *)deviceDescription
{
  return nil;
}

- (float)floatForKey:(NSString *)key
	     inTable:(NSString *)table
{
  return 0.0;
}

- (int)intForKey:(NSString *)key
	 inTable:(NSString *)table
{
  return 0;
}

- (NSRect)rectForKey:(NSString *)key
	     inTable:(NSString *)table
{
  return NSZeroRect;
}

- (NSSize)sizeForKey:(NSString *)key
	     inTable:(NSString *)table
{
  return NSZeroSize;
}

- (NSString *)stringForKey:(NSString *)key
		   inTable:(NSString *)table
{
  return nil;
}

- (NSArray *)stringListForKey:(NSString *)key
		      inTable:(NSString *)table
{
  return nil;
}

- (NSPrinterTableStatus)statusForTable:(NSString *)table
{
  return 0;
}

- (BOOL)isKey:(NSString *)key
      inTable:(NSString *)table
{
  return NO;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
}

- initWithCoder:aDecoder
{
  return self;
}

@end
