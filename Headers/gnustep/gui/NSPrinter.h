/* 
   NSPrinter.h

   Class representing a printer's or printer model's capabilities.

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Authors:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: June 1997
   
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

#ifndef _GNUstep_H_NSPrinter
#define _GNUstep_H_NSPrinter

#include <Foundation/NSCoder.h>
#include <Foundation/NSGeometry.h>

@class NSString;
@class NSArray;
@class NSDictionary;
@class NSMutableDictionary;

typedef enum _NSPrinterTableStatus {
  NSPrinterTableOK,
  NSPrinterTableNotFound,
  NSPrinterTableError
} NSPrinterTableStatus;

@interface NSPrinter : NSObject <NSCoding>
{
  NSString *printerHost, *printerName, *printerNote, *printerType;
  int cacheAcceptsBinary, cacheOutputOrder;
  BOOL isRealPrinter;
  NSMutableDictionary *PPD;
  NSMutableDictionary *PPDOptionTranslation;
  NSMutableDictionary *PPDArgumentTranslation;
  NSMutableDictionary *PPDOrderDependency;
  NSMutableDictionary *PPDUIConstraints;
}

//
// Finding an NSPrinter 
//
+ (NSPrinter *)printerWithName:(NSString *)name;
+ (NSPrinter *)printerWithType:(NSString *)type;
+ (NSArray *)printerTypes;

//
// Printer Attributes 
//
- (NSString *)host;
- (NSString *)name;
- (NSString *)note;
- (NSString *)type;

//
// Retrieving Specific Information 
//
- (BOOL)acceptsBinary;
- (NSRect)imageRectForPaper:(NSString *)paperName;
- (NSSize)pageSizeForPaper:(NSString *)paperName;
- (BOOL)isColor;
- (BOOL)isFontAvailable:(NSString *)fontName;
- (int)languageLevel;
- (BOOL)isOutputStackInReverseOrder;

//
// Querying the NSPrinter Tables 
//
- (BOOL)booleanForKey:(NSString *)key
	      inTable:(NSString *)table;
- (NSDictionary *)deviceDescription;
- (float)floatForKey:(NSString *)key
	     inTable:(NSString *)table;
- (int)intForKey:(NSString *)key
	 inTable:(NSString *)table;
- (NSRect)rectForKey:(NSString *)key
	     inTable:(NSString *)table;
- (NSSize)sizeForKey:(NSString *)key
	     inTable:(NSString *)table;
- (NSString *)stringForKey:(NSString *)key
		   inTable:(NSString *)table;
- (NSArray *)stringListForKey:(NSString *)key
		      inTable:(NSString *)table;
- (NSPrinterTableStatus)statusForTable:(NSString *)table;
- (BOOL)isKey:(NSString *)key
      inTable:(NSString *)table;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSPrinter
