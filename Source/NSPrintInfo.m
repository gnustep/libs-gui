/* 
   NSPrintInfo.m

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

#include <AppKit/NSPrintInfo.h>

@implementation NSPrintInfo

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPrintInfo class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Managing the Shared NSPrintInfo Object 
//
+ (void)setSharedPrintInfo:(NSPrintInfo *)printInfo
{}

+ (NSPrintInfo *)sharedPrintInfo
{
  return nil;
}

//
// Managing the Printing Rectangle 
//
+ (NSSize)sizeForPaperName:(NSString *)name
{
  return NSZeroSize;
}

//
// Specifying the Printer 
//
+ (NSPrinter *)defaultPrinter
{
  return nil;
}

+ (void)setDefaultPrinter:(NSPrinter *)printer
{}

//
// Instance methods
//
//
// Creating and Initializing an NSPrintInfo Instance 
//
- (id)initWithDictionary:(NSDictionary *)aDict
{
  return nil;
}

//
// Managing the Printing Rectangle 
//
- (float)bottomMargin
{
  return 0.0;
}

- (float)leftMargin
{
  return 0.0;
}

- (NSPrintingOrientation)orientation
{
  return 0;
}

- (NSString *)paperName
{
  return nil;
}

- (NSSize)paperSize
{
  return NSZeroSize;
}

- (float)rightMargin
{
  return 0.0;
}

- (void)setBottomMargin:(float)value
{}

- (void)setLeftMargin:(float)value
{}

- (void)setOrientation:(NSPrintingOrientation)mode
{}

- (void)setPaperName:(NSString *)name
{}

- (void)setPaperSize:(NSSize)size
{}

- (void)setRightMargin:(float)value
{}

- (void)setTopMargin:(float)value
{}

- (float)topMargin
{
  return 0.0;
}

//
// Pagination 
//
- (NSPrintingPaginationMode)horizontalPagination
{
  return 0;
}

- (void)setHorizontalPagination:(NSPrintingPaginationMode)mode
{}

- (void)setVerticalPagination:(NSPrintingPaginationMode)mode
{}

- (NSPrintingPaginationMode)verticalPagination
{
  return 0;
}

//
// Positioning the Image on the Page 
//
- (BOOL)isHorizontallyCentered
{
  return NO;
}

- (BOOL)isVerticallyCentered
{
  return NO;
}

- (void)setHorizontallyCentered:(BOOL)flag
{}

- (void)setVerticallyCentered:(BOOL)flag
{}

//
// Specifying the Printer 
//
- (NSPrinter *)printer
{
  return nil;
}

- (void)setPrinter:(NSPrinter *)aPrinter
{}

//
// Controlling Printing
//
- (NSString *)jobDisposition
{
  return nil;
}

- (void)setJobDisposition:(NSString *)disposition
{}

- (void)setUpPrintOperationDefaultValues
{}

//
// Accessing the NSPrintInfo Object's Dictionary 
//
- (NSMutableDictionary *)dictionary
{
  return nil;
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
