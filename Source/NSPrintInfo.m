/* 
   NSPrintInfo.m

   Stores information used in printing

   Copyright (C) 1996,1997,2004 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: July 1997
   Modified for Printing Backend Support
   Author: Chad Hardin <cehardin@mac.com>
   Date: June 2004
   
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

#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSValue.h>
#include "AppKit/NSPrinter.h"
#include "AppKit/NSPrintInfo.h"
#include "GNUstepGUI/GSPrinting.h"

#define NSNUMBER(val) [NSNumber numberWithInt: val]
#define DICTSET(dict, obj, key) \
   [dict setObject: obj forKey: key]

// FIXME: retain/release of dictionary with retain/release of printInfo?

// Class variables:
static NSPrintInfo *sharedPrintInfo = nil;


/**
  <unit>
  <heading>Class Description</heading>
  <p>
  NSPrintInfo is a storage object that stores information that describes
  how a view is to printed and the destination information for printing.
  </p>
  </unit>
*/

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

/** Load the appropriate bundle for the PrintInfo
    (eg: GSLPRPrintInfo, GSCUPSPrintInfo).
*/
+ (id) allocWithZone: (NSZone*) zone
{
  Class principalClass;

  principalClass = [[GSPrinting printingBundle] principalClass];

  if( principalClass == nil )
    return nil;
	
  return [[principalClass printInfoClass] allocWithZone: zone];
}

//
// Managing the Shared NSPrintInfo Object 
//
+ (void)setSharedPrintInfo:(NSPrintInfo *)printInfo
{
  ASSIGN(sharedPrintInfo, printInfo);
}

+ (NSPrintInfo *)sharedPrintInfo
{
  if (!sharedPrintInfo)
   {    
     sharedPrintInfo = [[NSPrintInfo alloc] initWithDictionary: nil]; 
   }
  return sharedPrintInfo;
}

//
// Managing the Printing Rectangle 
//
+ (NSSize)sizeForPaperName:(NSString *)name
{
  return [[self defaultPrinter] pageSizeForPaper:name];
}

//
// Specifying the Printer 
//
+ (NSPrinter *)defaultPrinter
{
  Class principalClass;

  principalClass = [[GSPrinting printingBundle] principalClass];

  if( principalClass == nil )
    return nil;
	
  return [[principalClass printInfoClass] defaultPrinter];
}

+ (void)setDefaultPrinter:(NSPrinter *)printer
{
  Class principalClass;

  principalClass = [[GSPrinting printingBundle] principalClass];

  if( principalClass == nil )
    return;
	
  [[principalClass printInfoClass] setDefaultPrinter: printer];
}

//
// Instance methods
//
//
// Creating and Initializing an NSPrintInfo Instance 
//
- (id)initWithDictionary:(NSDictionary *)aDict
{
  [super init];
  
  _info = [[NSMutableDictionary alloc] init];
      
  //put in the defaults
  [self setVerticalPagination: NSAutoPagination];
   
  [self setHorizontalPagination: NSClipPagination];
  
  [self setJobDisposition: NSPrintSpoolJob];
      
  [self setHorizontallyCentered: YES];
      
  [self setVerticallyCentered: YES];
  
  [self setOrientation: NSPortraitOrientation];
  
  if( aDict != nil )
    {
      [_info addEntriesFromDictionary: aDict];
  
      if([[_info objectForKey: NSPrintPrinter] isKindOfClass: [NSString class]])
        {
          NSString *printerName;
          NSPrinter *printer;
      
          printerName = [_info objectForKey: NSPrintPrinter];
          printer = [NSPrinter printerWithName: printerName];
          
          if( printer )
              [self setPrinter: printer];
          else
              [_info removeObjectForKey: NSPrintPrinter];
        }
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_info);
  [super dealloc];
}

- (id) copyWithZone: (NSZone*)z
{
  NSPrintInfo *new = (NSPrintInfo *)NSCopyObject(self, 0, z);

  new->_info = [_info mutableCopyWithZone: z];

  return new;
}

//
// Managing the Printing Rectangle 
//
- (float)bottomMargin
{
  return [(NSNumber *)[_info objectForKey:NSPrintBottomMargin] floatValue];
}

- (float)leftMargin
{
  return [(NSNumber *)[_info objectForKey:NSPrintLeftMargin] floatValue];
}

- (NSPrintingOrientation)orientation
{
  return [(NSNumber *)[_info objectForKey:NSPrintOrientation] intValue];
}

- (NSString *)paperName
{
  return [_info objectForKey:NSPrintPaperName];
}

- (NSSize)paperSize
{
  return [(NSValue *)[_info objectForKey:NSPrintPaperSize] sizeValue];
}

- (float)rightMargin
{
  return [(NSNumber *)[_info objectForKey:NSPrintRightMargin] floatValue];
}

- (void)setBottomMargin:(float)value
{
  [_info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintBottomMargin];
}

- (void)setLeftMargin:(float)value
{
  [_info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintLeftMargin];
}

- (void)setOrientation:(NSPrintingOrientation)mode
{
  NSSize size;
  [_info setObject:[NSNumber numberWithInt:mode]
	forKey:NSPrintOrientation];
  /* Set the paper size accordingly */
  size = [self paperSize];
  if ((mode == NSPortraitOrientation && size.width > size.height)
      || (mode == NSLandscapeOrientation && size.width < size.height))
    {
      float tmp = size.width;
      size.width = size.height;
      size.height = tmp;
      [_info setObject: [NSValue valueWithSize: size] 
	        forKey: NSPrintPaperSize];
    }
}

- (void)setPaperName:(NSString *)name
{
  DICTSET(_info, name, NSPrintPaperName);
  DICTSET(_info, 
	  [NSValue valueWithSize: [NSPrintInfo sizeForPaperName: name]],
	  NSPrintPaperSize);
}

- (void)setPaperSize:(NSSize)size
{
  NSPrintingOrientation orient;
  [_info setObject:[NSValue valueWithSize:size]
	forKey:NSPrintPaperSize];
  /* Set orientation accordingly */
  if (size.width <= size.height)
    orient = NSPortraitOrientation;
  else
    orient = NSLandscapeOrientation;
  DICTSET(_info, NSNUMBER(orient), NSPrintOrientation);
}

- (void)setRightMargin:(float)value
{
  [_info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintRightMargin];
}

- (void)setTopMargin:(float)value
{
  [_info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintTopMargin];
}

- (float)topMargin
{
  return [(NSNumber *)[_info objectForKey:NSPrintTopMargin] floatValue];
}

//
// Pagination 
//
- (NSPrintingPaginationMode)horizontalPagination
{
  return [(NSNumber *)[_info objectForKey:NSPrintHorizontalPagination]
		      intValue];
}

- (void)setHorizontalPagination:(NSPrintingPaginationMode)mode
{
  [_info setObject:[NSNumber numberWithInt:mode]
	forKey:NSPrintHorizontalPagination];
}

- (void)setVerticalPagination:(NSPrintingPaginationMode)mode
{
  [_info setObject:[NSNumber numberWithInt:mode]
	forKey:NSPrintVerticalPagination];
}

- (NSPrintingPaginationMode)verticalPagination
{
  return [(NSNumber *)[_info objectForKey:NSPrintVerticalPagination] intValue];
}

//
// Positioning the Image on the Page 
//
- (BOOL)isHorizontallyCentered
{
  return [(NSNumber *)[_info objectForKey:NSPrintHorizontallyCentered] 
		      boolValue];
}

- (BOOL)isVerticallyCentered
{
  return [(NSNumber *)[_info objectForKey:NSPrintVerticallyCentered] boolValue];
}

- (void)setHorizontallyCentered:(BOOL)flag
{
  [_info setObject:[NSNumber numberWithBool:flag]
	forKey:NSPrintHorizontallyCentered];
}

- (void)setVerticallyCentered:(BOOL)flag
{
  [_info setObject:[NSNumber numberWithBool:flag]
	forKey:NSPrintVerticallyCentered];
}

//
// Specifying the Printer 
//
- (NSPrinter *)printer
{
  return [_info objectForKey:NSPrintPrinter];
}

- (void)setPrinter:(NSPrinter *)aPrinter
{
  [_info setObject:aPrinter forKey:NSPrintPrinter];
}

//
// Controlling Printing
//
- (NSString *)jobDisposition
{
  return [_info objectForKey:NSPrintJobDisposition];
}

- (void)setJobDisposition:(NSString *)disposition
{
  [_info setObject:disposition forKey:NSPrintJobDisposition];
}

- (void)setUpPrintOperationDefaultValues
{
  [self subclassResponsibility: _cmd];
}

//
// Accessing the NSPrintInfo Object's Dictionary 
//
- (NSMutableDictionary *)dictionary
{
  return _info;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  //There is a NSPrinter in the dict, will that work as a Property list?
  NSMutableDictionary *dict;
  
  dict = AUTORELEASE([_info mutableCopy]);
  
  [dict setObject: [[self printer] name]
           forKey: NSPrintPrinter];
           
  [aCoder encodePropertyList: _info];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  NSString *printerName;
  NSPrinter *printer;
 
  _info = RETAIN([aDecoder decodePropertyList]);
  
  printerName = [_info objectForKey: NSPrintPrinter];
  printer = [NSPrinter printerWithName: printerName];
  
  if( printer )
    [self setPrinter: printer];
  else
    [_info removeObjectForKey: NSPrintPrinter]; 
  
  return self;
}

@end

