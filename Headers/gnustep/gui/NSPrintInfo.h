/* 
   NSPrintInfo.h

   Stores information used in printing

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

#ifndef _GNUstep_H_NSPrintInfo
#define _GNUstep_H_NSPrintInfo

#include <Foundation/NSCoder.h>
#include <Foundation/NSGeometry.h>

@class NSString;
@class NSDictionary;
@class NSMutableDictionary;

@class NSPrinter;

typedef enum _NSPrintingOrientation {
  NSPortraitOrientation,
  NSLandscapeOrientation
} NSPrintingOrientation;

typedef enum _NSPrintingPaginationMode {
  NSAutoPagination,
  NSFitPagination,
  NSClipPagination
} NSPrintingPaginationMode;

@interface NSPrintInfo : NSObject <NSCoding>
{
  // Attributes
}

//
// Creating and Initializing an NSPrintInfo Instance 
//
- (id)initWithDictionary:(NSDictionary *)aDict;

//
// Managing the Shared NSPrintInfo Object 
//
+ (void)setSharedPrintInfo:(NSPrintInfo *)printInfo;
+ (NSPrintInfo *)sharedPrintInfo;

//
// Managing the Printing Rectangle 
//
+ (NSSize)sizeForPaperName:(NSString *)name;
- (float)bottomMargin;
- (float)leftMargin;
- (NSPrintingOrientation)orientation;
- (NSString *)paperName;
- (NSSize)paperSize;
- (float)rightMargin;
- (void)setBottomMargin:(float)value;
- (void)setLeftMargin:(float)value;
- (void)setOrientation:(NSPrintingOrientation)mode;
- (void)setPaperName:(NSString *)name;
- (void)setPaperSize:(NSSize)size;
- (void)setRightMargin:(float)value;
- (void)setTopMargin:(float)value;
- (float)topMargin;

//
// Pagination 
//
- (NSPrintingPaginationMode)horizontalPagination;
- (void)setHorizontalPagination:(NSPrintingPaginationMode)mode;
- (void)setVerticalPagination:(NSPrintingPaginationMode)mode;
- (NSPrintingPaginationMode)verticalPagination;

//
// Positioning the Image on the Page 
//
- (BOOL)isHorizontallyCentered;
- (BOOL)isVerticallyCentered;
- (void)setHorizontallyCentered:(BOOL)flag;
- (void)setVerticallyCentered:(BOOL)flag;

//
// Specifying the Printer 
//
+ (NSPrinter *)defaultPrinter;
+ (void)setDefaultPrinter:(NSPrinter *)printer;
- (NSPrinter *)printer;
- (void)setPrinter:(NSPrinter *)aPrinter;

//
// Controlling Printing
//
- (NSString *)jobDisposition;
- (void)setJobDisposition:(NSString *)disposition;
- (void)setUpPrintOperationDefaultValues;

//
// Accessing the NSPrintInfo Object's Dictionary 
//
- (NSMutableDictionary *)dictionary;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

//
// Printing Information Dictionary Keys 
//
extern NSString *NSPrintAllPages;
extern NSString *NSPrintBottomMargin;
extern NSString *NSPrintCopies;
extern NSString *NSPrintFaxCoverSheetName;
extern NSString *NSPrintFaxHighResolution;
extern NSString *NSPrintFaxModem;
extern NSString *NSPrintFaxReceiverNames;
extern NSString *NSPrintFaxReceiverNumbers;
extern NSString *NSPrintFaxReturnReceipt;
extern NSString *NSPrintFaxSendTime;
extern NSString *NSPrintFaxTrimPageEnds;
extern NSString *NSPrintFaxUseCoverSheet;
extern NSString *NSPrintFirstPage;
extern NSString *NSPrintHorizonalPagination;
extern NSString *NSPrintHorizontallyCentered;
extern NSString *NSPrintJobDisposition;
extern NSString *NSPrintJobFeatures;
extern NSString *NSPrintLastPage;
extern NSString *NSPrintLeftMargin;
extern NSString *NSPrintManualFeed;
extern NSString *NSPrintOrientation;
extern NSString *NSPrintPackageException;
extern NSString *NSPrintPagesPerSheet;
extern NSString *NSPrintPaperFeed;
extern NSString *NSPrintPaperName;
extern NSString *NSPrintPaperSize;
extern NSString *NSPrintPrinter;
extern NSString *NSPrintReversePageOrder;
extern NSString *NSPrintRightMargin;
extern NSString *NSPrintSavePath;
extern NSString *NSPrintScalingFactor;
extern NSString *NSPrintTopMargin;
extern NSString *NSPrintVerticalPagination;
extern NSString *NSPrintVerticallyCentered;

//
// Print Job Disposition Values 
//
extern NSString *NSPrintCancelJob;
extern NSString *NSPrintFaxJob;
extern NSString *NSPrintPreviewJob;
extern NSString *NSPrintSaveJob;
extern NSString *NSPrintSpoolJob;

#endif // _GNUstep_H_NSPrintInfo
