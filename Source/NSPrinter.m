/** <title>NSPrinter</title>

   <abstract>Class representing a printer's or printer model's capabilities.</abstract>

   Copyright (C) 1996, 1997, 2004 Free Software Foundation, Inc.

   Authors: Simon Frankau <sgf@frankau.demon.co.uk>
   Date: June 1997
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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/ 

/* NB:
 * There are a few FIXMEs in the functionality left.
 * Parsing of the PPDs is somewhat suboptimal.
 * (I think it's best to leave optimisation until more of GNUstep is done).
 * The *OpenUI, *CloseUI, *OpenGroup and *CloseGroup are not processed.
 * (This is not required in the OpenStep standard, but could be useful).
 */

#include "config.h"
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSScanner.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSSet.h>
#include "AppKit/AppKitExceptions.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSPrinter.h"
#include "GNUstepGUI/GSPrinting.h"



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

/** Load the appropriate bundle for the Printer
    (eg: GSLPRPrinter, GSCUPSPrinter).
*/
+ (id) allocWithZone: (NSZone*) zone
{
  Class principalClass;

  principalClass = [[GSPrinting printingBundle] principalClass];

  if( principalClass == nil )
    return nil;
	
  return [[principalClass printerClass] allocWithZone: zone];
}


//
// Finding an NSPrinter 
//
+ (NSPrinter *)printerWithName:(NSString *)name
{
  Class principalClass;

  principalClass = [[GSPrinting printingBundle] principalClass];

  if( principalClass == nil )
    return nil;
    
  return  [[principalClass printerClass] printerWithName: name];
}

//
// This now different than the OpenStep spec and instead
// follows the more useful implementation Apple choosed.  In
// OpenStep, this method would read a PPD and return a NSPrinter
// based upon values from that PPD, regardless if that printer
// was actually avaiable for use or not.  On the contrary, Apple's 
// implementation looks
// at all avaiable printers and returns one that has the same
// type.  The reason for this is because they use CUPS.  CUPS
// does not work by maintaining a repository of PPDs.  Instead, 
// the CUPS server trasnmits PPDs as they are needed, and only
// for actual real printers.  Since we cannot know how the backend 
// bundles will be handling their PPDs, or if they will even be using
// PPDs for that matter, (a Win32 printing backend, for example), 
// I've choosen to go with Apple's implementation.  Really, I see
// little use in creating a NSPrinter for a printer that is not
// available for use in the first place, I am open for commments
// on this, of course.
+ (NSPrinter *)printerWithType:(NSString *)type
{
  NSEnumerator *printerNamesEnum;
  NSString *printerName;
  
  printerNamesEnum = [[self printerNames] objectEnumerator];
  
  while( (printerName = [printerNamesEnum nextObject]) )
    {
      NSPrinter *printer;
    
      printer = [self printerWithName: printerName];
    
      if( [[printer type] isEqualToString: type] )
        {
          return printer;
        }
    }
    return nil;
}

+ (NSArray *)printerNames
{
  Class principalClass;

  principalClass = [[GSPrinting printingBundle] principalClass];

  if( principalClass == nil )
    return nil;
    
  return  [[principalClass printerClass] printerNames];
}

// See note at +(NSPrinter *)printerWithType:(NSString *)type
+ (NSArray *)printerTypes
{
  NSMutableSet *printerTypes;
  NSEnumerator *printerNamesEnum;
  NSString *printerName;
  NSPrinter *printer;
  
  printerTypes = [NSMutableSet setWithCapacity:1];
  
  printerNamesEnum = [[self printerNames] objectEnumerator];
  
  while( (printerName = [printerNamesEnum nextObject]) )
    {
      printer = [self printerWithName: printerName];
      
      [printerTypes addObject: [printer type]];
    }
    
  return [printerTypes allObjects];
}

//
// Instance methods
//
//
// Deallocation of instance variables
//
- (void)dealloc
{
  RELEASE(_printerHost);
  RELEASE(_printerName);
  RELEASE(_printerNote);
  RELEASE(_printerType);
  RELEASE(_PPD);
  RELEASE(_PPDOptionTranslation);
  RELEASE(_PPDArgumentTranslation);
  RELEASE(_PPDOrderDependency);
  RELEASE(_PPDUIConstraints);
  [super dealloc];
}

//
// Printer Attributes 
//
- (NSString *)host
{
  return _printerHost;
}

- (NSString *)name
{
  return _printerName;
}

- (NSString *)note
{
  return _printerNote;
}

- (NSString *)type
{
  return _printerType;
}

//
// Retrieving Specific Information 
//
- (BOOL)acceptsBinary
{
  // FIXME: I'm not sure if acceptsBinary is the same as BCP protocol?
  NSString *result;
  NSScanner *protocols;
  NSCharacterSet *whitespace;

  if (_cacheAcceptsBinary != -1)
    return _cacheAcceptsBinary;
  result = [self stringForKey:@"Protocols" inTable:@"PPD"];
  if (!result)
    {
      _cacheAcceptsBinary = NO;
      return NO;
    }
  protocols = [NSScanner scannerWithString:result];
  whitespace = [NSCharacterSet whitespaceCharacterSet];
  while(![protocols isAtEnd])
    {
      [protocols scanUpToCharactersFromSet:whitespace intoString:&result];
      if ([result isEqual:@"BCP"])
	{
	  _cacheAcceptsBinary = YES;
	  return YES;
	}
    }
  _cacheAcceptsBinary = NO;
  return NO;    
}

- (NSRect)imageRectForPaper:(NSString *)paperName
{
  return [self rectForKey:[NSString 
			    stringWithFormat:@"ImageableArea/%@", paperName]
	       inTable:@"PPD"];
}

- (NSSize)pageSizeForPaper:(NSString *)paperName
{
  return [self sizeForKey:[NSString 
			    stringWithFormat:@"PaperDimension/%@", paperName]
	       inTable:@"PPD"];
}

- (BOOL)isColor
{
  return [self booleanForKey:@"ColorDevice" inTable:@"PPD"];
}

- (BOOL)isFontAvailable:(NSString *)fontName
{
  return [self isKey:[NSString stringWithFormat:@"Font/%@", fontName]
	       inTable:@"PPD"];
}

- (int)languageLevel
{
  return [self intForKey:@"LanguageLevel" inTable:@"PPD"];
}

- (BOOL)isOutputStackInReverseOrder
{
  // FIXME: Is this what is needed? I'm not sure how this is worked out.
  NSString *result;
  if (_cacheOutputOrder != -1)
    return _cacheOutputOrder;
  result = [self stringForKey:@"DefaultOutputOrder" inTable:@"PPD"];
  if (!result)
    {
      _cacheOutputOrder = NO;
      return NO;
    }
  if ([result isEqual:@"Reverse"])
    {
      _cacheOutputOrder = YES;
      return YES;
    }
  _cacheOutputOrder = NO;
  return NO;
}

//
// Querying the NSPrinter Tables 
//

/*
 * Caching of converted values:
 * To speed up retrieving non-string values, once they are read and converted
 * they are then cached. Since these use the converted value of a string in
 * whatever table they are in, this assumes there is only one string
 * associated with the key, and so stringListForKey will not be used. The 
 * second place in the array attached for the key is therefore used to cache 
 * the information, and generally assumptions are made which are Bad Things,
 * but it seems quicker and simpler than other ways and shouldn't go wrong in
 * normal use (?).
 */

- (BOOL)booleanForKey:(NSString *)key
	      inTable:(NSString *)table
{
  NSMutableArray *result;
  result = (NSMutableArray *)[self stringListForKey:key inTable:table];
  if (!result)
    return NO;
  if ([result count] == 2)
    {
      // Retrieve cached result
      return [(NSNumber *)[result objectAtIndex:1] boolValue];
    }
  if ([[result objectAtIndex:0] isEqual:@"True"])
    {
      // Cache result
      [result addObject:[NSNumber numberWithBool:YES]];
      return YES;
    }
  // Cache result
  [result addObject:[NSNumber numberWithBool:NO]];
  return NO;
}

- (NSDictionary *)deviceDescription
{
  /* FIXME: This is all rather dodgy - I don't have detailed information.
   * I think I'll wait until NSWindow's deviceDescription is
   * implemented, and then use that, since I'm not sure as to what sort
   * of objects the values should be, and it would be nice to get the
   * deviceDescriptions methods to match in the way they work.
   */
  NSDictionary *result;
  int dpi = [self intForKey:@"DefaultResolution" inTable:@"PPD"];
  BOOL color = [self booleanForKey:@"ColorDevice" inTable:@"PPD"];
  NSString *colorSpaceName;
  int bits = [self intForKey:@"DefaultBitsPerPixel" inTable:@"PPD"];
  NSSize paperSize = [self pageSizeForPaper:
			     [self stringForKey:@"DefaultPageSize"
				   inTable:@"PPD"]];
  // Guess 300 dpi
  if (!dpi)
    dpi = 300;
  // FIXME: Should NSDeviceWhiteColorSpace be NSDeviceBlackColorSpace?
  // FIXME #2: Are they calibrated?
  // Basically I'm not sure which color spaces should be used...
  if (color)
    colorSpaceName = NSDeviceCMYKColorSpace;
  else
    colorSpaceName = NSDeviceWhiteColorSpace;
  if (!bits) // Either not found, or 'None'
    bits=1;
  // If the paper size wasn't found, try Letter
  if (!(paperSize.width && paperSize.height))
    paperSize = NSMakeSize(612,792);
  // Create the dictionary...
  result = [NSDictionary dictionaryWithObjectsAndKeys:
	[NSNumber numberWithInt:dpi],		NSDeviceResolution, 
	colorSpaceName,				NSDeviceColorSpaceName, 
	[NSNumber numberWithInt:bits],		NSDeviceBitsPerSample,
	[NSNumber numberWithBool:NO],		NSDeviceIsScreen, 
	[NSNumber numberWithBool:YES],		NSDeviceIsPrinter,
	[NSValue valueWithSize:paperSize],	NSDeviceSize, 
		nil];
  return result;
}

- (float)floatForKey:(NSString *)key
	     inTable:(NSString *)table
{
  NSMutableArray *result;
  float number;
  result = (NSMutableArray *)[self stringListForKey:key inTable:table];
  if (!result)
    return 0.0;
  if ([result count] == 2)
    {
      // Retrieve cached result
      return [(NSNumber *)[result objectAtIndex:1] floatValue];
    }
  number = [(NSString *)[result objectAtIndex:0] floatValue];
  // Cache result
  [result addObject:[NSNumber numberWithFloat:number]];
  // And return it
  return number;
}

- (int)intForKey:(NSString *)key
	 inTable:(NSString *)table
{
  NSMutableArray *result;
  int number;
  result = (NSMutableArray *)[self stringListForKey:key inTable:table];
  if (!result)
    return 0;
  if ([result count] == 2)
    {
      // Retrieve cached result
      return [(NSNumber *)[result objectAtIndex:1] intValue];
    }
  number = [(NSString *)[result objectAtIndex:0] intValue];
  // Cache result
  [result addObject:[NSNumber numberWithInt:number]];
  // And return it
  return number;
}

- (NSRect)rectForKey:(NSString *)key
	     inTable:(NSString *)table
{
  NSMutableArray *result;
  NSScanner *bits;
  float x1, y1, x2, y2;
  NSRect rectangle;
  result = (NSMutableArray *)[self stringListForKey:key inTable:table];
  if (!result)
    return NSZeroRect;
  if ([result count] == 2)
    {
      // Retrieve cached result
      return [(NSValue *)[result objectAtIndex:1] rectValue];
    }
  bits = [NSScanner scannerWithString:[result objectAtIndex:0]];
  if ([bits scanFloat:&x1] && 
      [bits scanFloat:&y1] &&
      [bits scanFloat:&x2] &&
      [bits scanFloat:&y2])
    {
      rectangle = NSMakeRect(x1, y1, x2-x1, y2-y1);
      // Cache result
      [result addObject:[NSValue valueWithRect:rectangle]];
      // And return it
      return rectangle;
    }
  return NSZeroRect;
}

- (NSSize)sizeForKey:(NSString *)key
	     inTable:(NSString *)table
{
  NSMutableArray *result;
  NSScanner *bits;
  float x, y;
  NSSize size;
  result = (NSMutableArray *)[self stringListForKey:key inTable:table];
  if (!result)
    return NSZeroSize;
  if ([result count] == 2)
    {
      // Retrieve cached result
      return [(NSValue *)[result objectAtIndex:1] sizeValue];
    }
  bits = [NSScanner scannerWithString:[result objectAtIndex:0]];
  if ([bits scanFloat:&x] && 
      [bits scanFloat:&y])
    {
      size = NSMakeSize(x,y);
      // Cache result
      [result addObject:[NSValue valueWithSize:size]];
      // And return it
      return size;
    }
  return NSZeroSize;
}

- (NSString *)stringForKey:(NSString *)key
		   inTable:(NSString *)table
{
  NSMutableDictionary *checkMe = nil;
  NSMutableArray *result;

  // Select correct table
  if ([table isEqual:@"PPD"])
    checkMe = _PPD;
  else if ([table isEqual:@"PPDOptionTranslation"])
    checkMe = _PPDOptionTranslation;
  else if ([table isEqual:@"PPDArgumentTranslation"])
    checkMe = _PPDArgumentTranslation;
  else if ([table isEqual:@"PPDOrderDependency"])
    checkMe = _PPDOrderDependency;
  else if ([table isEqual:@"PPDUIConstraints"])
    checkMe = _PPDUIConstraints;
  else
    {
      [NSException raise:NSGenericException
         format:@"Could not find PPD table %@", table];
      // NOT REACHED
    }
  // And check it
  result = [checkMe objectForKey:key];
  if (!result)
    // Not found
    return nil;
  return [result objectAtIndex:0];
}

- (NSArray *)stringListForKey:(NSString *)key
		      inTable:(NSString *)table
{
  NSMutableDictionary *checkMe = nil;
  NSMutableArray *result;

  // Select correct Table
  if ([table isEqual:@"PPD"])
    checkMe = _PPD;
  else if ([table isEqual:@"PPDOptionTranslation"])
    checkMe = _PPDOptionTranslation;
  else if ([table isEqual:@"PPDArgumentTranslation"])
    checkMe = _PPDArgumentTranslation;
  else if ([table isEqual:@"PPDOrderDependency"])
    checkMe = _PPDOrderDependency;
  else if ([table isEqual:@"PPDUIConstraints"])
    checkMe = _PPDUIConstraints;
  else
    {
      [NSException raise:NSGenericException
         format:@"Could not find PPD table %@", table];
      // NOT REACHED
    }
  // And check it
  result = [checkMe objectForKey:key];
  if (!result)
    // Not found
    return nil;
  if ([[result objectAtIndex:0] isEqual:@""])
    {
      NSMutableArray *oldResult = result;
      result = [NSMutableArray array];
      [result addObjectsFromArray:oldResult];
      [result removeObjectAtIndex:0];
    }
  return result;
}

- (NSPrinterTableStatus)statusForTable:(NSString *)table
{
  NSMutableDictionary *checkMe;
  // Select correct table
  if ([table isEqual:@"PPD"])
    checkMe = _PPD;
  else if ([table isEqual:@"PPDOptionTranslation"])
    checkMe = _PPDOptionTranslation;
  else if ([table isEqual:@"PPDArgumentTranslation"])
    checkMe = _PPDArgumentTranslation;
  else if ([table isEqual:@"PPDOrderDependency"])
    checkMe = _PPDOrderDependency;
  else if ([table isEqual:@"PPDUIConstraints"])
    checkMe = _PPDUIConstraints;
  else
    return NSPrinterTableNotFound;
  if (checkMe)
    return NSPrinterTableOK;
  // Shouldn't happen!
  return NSPrinterTableError;
}

- (BOOL)isKey:(NSString *)key
      inTable:(NSString *)table
{
  NSMutableDictionary *checkMe = nil;
  NSMutableArray *result;

  // Select correct table
  if ([table isEqual:@"PPD"])
    checkMe = _PPD;
  else if ([table isEqual:@"PPDOptionTranslation"])
    checkMe = _PPDOptionTranslation;
  else if ([table isEqual:@"PPDArgumentTranslation"])
    checkMe = _PPDArgumentTranslation;
  else if ([table isEqual:@"PPDOrderDependency"])
    checkMe = _PPDOrderDependency;
  else if ([table isEqual:@"PPDUIConstraints"])
    checkMe = _PPDUIConstraints;
  else
    {
      [NSException raise:NSGenericException
         format:@"Could not find PPD table %@", table];
      // NOT REACHED
    }
  // And check it
  result = [checkMe objectForKey:key];
  if (!result)
    // Not found
    return NO;
  return YES;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  //  [super encodeWithCoder:aCoder];
  
  [aCoder encodeObject: _printerHost];
  [aCoder encodeObject: _printerName];
  [aCoder encodeObject: _printerNote];
  [aCoder encodeObject: _printerType];

  [aCoder encodeValueOfObjCType: @encode(int) at: &_cacheAcceptsBinary];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_cacheOutputOrder];

  [aCoder encodeObject: _PPD];
  [aCoder encodeObject: _PPDOptionTranslation];
  [aCoder encodeObject: _PPDArgumentTranslation];
  [aCoder encodeObject: _PPDOrderDependency];
  [aCoder encodeObject: _PPDUIConstraints];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  //  self = [super initWithCoder:aDecoder];
    
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_printerHost];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_printerName];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_printerNote];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_printerType];

  [aDecoder decodeValueOfObjCType: @encode(int) at: &_cacheAcceptsBinary];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_cacheOutputOrder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_PPD];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_PPDOptionTranslation];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_PPDArgumentTranslation];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_PPDOrderDependency];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_PPDUIConstraints];

  return self;
}

@end



///
///Private implementation of routines that will be usefull
///for the printing backend bundles that subclass us.
///
@implementation NSPrinter (Private)

//
// Initialisation method used by backend bundles
//
-(id) initWithName:(NSString *)name
          withType:(NSString *)type
          withHost:(NSString *)host
          withNote:(NSString *)note
{
  self = [super init];
  
  // Initialise instance variables
  ASSIGN(_printerName, name);
  ASSIGN(_printerType, type);
  ASSIGN(_printerHost, host);
  ASSIGN(_printerNote, note);
  _cacheAcceptsBinary = _cacheOutputOrder = -1;
  _PPD = RETAIN([NSMutableDictionary dictionary]);
  _PPDOptionTranslation = RETAIN([NSMutableDictionary dictionary]);
  _PPDArgumentTranslation = RETAIN([NSMutableDictionary dictionary]);
  _PPDOrderDependency = RETAIN([NSMutableDictionary dictionary]);
  _PPDUIConstraints = RETAIN([NSMutableDictionary dictionary]);
  
  return self;
}




//
// Adds the various values to the relevant tables, for the given key
//
-           addValue:(NSString *)value
 andValueTranslation:(NSString *)valueTranslation
andOptionTranslation:(NSString *)optionTranslation
              forKey:(NSString *)key
{
  [self addString:value forKey:key inTable:_PPD];
  if (valueTranslation)
    [self addString:valueTranslation forKey:key
	  inTable:_PPDArgumentTranslation];
  if (optionTranslation)
    [self addString:optionTranslation forKey:key
	  inTable:_PPDOptionTranslation];
  return self;
}

//
// Adds the string to the array of strings
//
- addString:(NSString *)string
     forKey:(NSString *)key
    inTable:(NSMutableDictionary *)table
{
  NSMutableArray *array;
  array = (NSMutableArray *)[table objectForKey:key];
  if (array)
    // Add string to existing array
    [array addObject:string];
  else
    // Create the array if it does not exist
    [table setObject:[NSMutableArray arrayWithObject:string] forKey:key];
  return self;
}

@end
