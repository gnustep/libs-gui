/* 
   NSPrintInfo.h

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSPrintInfo
#define _GNUstep_H_NSPrintInfo

#include <AppKit/stdappkit.h>
#include <AppKit/NSPrinter.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSCoder.h>

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

#endif // _GNUstep_H_NSPrintInfo
