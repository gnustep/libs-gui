/** <title>NSPrinter</title>

   <abstract>Class representing a printer's or printer model's capabilities.</abstract>

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Authors: Simon Frankau <sgf@frankau.demon.co.uk>
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

#include "gnustep/gui/config.h"
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
#include "AppKit/AppKitExceptions.h"
#include "AppKit/NSGraphics.h"

#include "AppKit/NSPrinter.h"

// Define size used for the name and type maps - just use a small table
#define NAMEMAPSIZE 0
#define TYPEMAPSIZE 0

// The maximum level of nesting of *Include directives
#define MAX_PPD_INCLUDES 4

// A macro to skip whitespace over lines
#define skipSpace(x) [x scanCharactersFromSet:\
			  [NSCharacterSet whitespaceAndNewlineCharacterSet]\
			intoString:NULL]

static NSString *NSPrinter_PATH = @"PostScript/PPD";
static NSString *NSPrinter_INDEXFILE = @"Printers";

//
// Class variables:
//

// Maps holding NSPrinters with the types of printers, and the real printers
static NSMapTable *typeMap = NULL;
static NSMapTable *nameMap = NULL;
// Dictionary of real printers, from which NSPrinters can be made
static NSDictionary *nameDict = nil;
// An array to cache the available printer types
static NSArray *printerTypesAvailable = nil;

//
// Class variables used during scanning:
//

// Character sets used in scanning.
static NSCharacterSet *newlineSet = nil;
static NSCharacterSet *keyEndSet = nil;
static NSCharacterSet *optKeyEndSet = nil;
static NSCharacterSet *valueEndSet = nil;
// Array of Repeated Keywords (Appendix B of the PostScript Printer
// Description File Format Specification).
static NSArray *repKeys = nil;		   
// Array to collect the values of symbol values in.
static NSMutableDictionary *PPDSymbolValues;
// File name of the file being processed
static NSString *PPDFileName;

#ifndef LIB_FOUNDATION_LIBRARY

static void __NSRetainNothing(void *table, const void *anObject)
{
}

static void __NSReleaseNothing(void *table, void *anObject)
{
}

static NSString* __NSDescribeObjects(void *table, const void *anObject)
{
    return [(NSObject*)anObject description];
}

static const NSMapTableValueCallBacks NSNonRetainedObjectMapValueCallBacks = {
    (void (*)(NSMapTable *, const void *))__NSRetainNothing,
    (void (*)(NSMapTable *, void *))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribeObjects
}; 

#endif /* LIB_FOUNDATION_LIBRARY */


// Convert a character to a value between 0 and 15
static int gethex(unichar character)
{
  switch (character)
    {
    case '0': return 0;
    case '1': return 1;
    case '2': return 2;
    case '3': return 3;
    case '4': return 4;
    case '5': return 5;
    case '6': return 6;
    case '7': return 7;
    case '8': return 8;
    case '9': return 9;
    case 'A': return 10;
    case 'B': return 11;
    case 'C': return 12;
    case 'D': return 13;
    case 'E': return 14;
    case 'F': return 15;
    case 'a': return 10;
    case 'b': return 11;
    case 'c': return 12;
    case 'd': return 13;
    case 'e': return 14;
    case 'f': return 15;
    }      
  [NSException 
    raise:NSPPDParseException 
    format:@"Badly formatted hexadeximal substring in PPD printer file."];
  // NOT REACHED
  return 0; /* Quiet compiler warnings */
}

// Function to convert hexadecimal substrings
static NSString *interpretQuotedValue(NSString *qString)
{
  NSScanner *scanner;
  NSCharacterSet *emptySet;
  NSString *value = nil;
  NSString *part;
  int stringLength;
  int location;
  NSRange range;

  // Don't bother unless there's something to convert
  range = [qString rangeOfString:@"<"];
  if(!range.length)
    return qString;

  scanner = [NSScanner scannerWithString:qString];
  emptySet = [NSCharacterSet characterSetWithCharactersInString:@""];
  [scanner setCharactersToBeSkipped:emptySet];  
  if(![scanner scanUpToString:@"<" intoString:&value])
    value = [NSString string];
  stringLength = [qString length];

  while (![scanner isAtEnd]) {
    [scanner scanString:@"<" intoString:NULL];
    skipSpace(scanner);
    while (![scanner scanString:@">" intoString:NULL])
      {
	location = [scanner scanLocation];
	if (location+2 > stringLength)
	  {
	    [NSException
	      raise:NSPPDParseException
	      format:@"Badly formatted hexadecimal substring in PPD printer file."];
	    // NOT REACHED
	  }
	value = [value stringByAppendingFormat:@"%c",
		       16 * gethex([qString characterAtIndex:location])
                       + gethex([qString characterAtIndex:location+1])];
	[scanner setScanLocation:location+2];
	skipSpace(scanner);
      }
    if([scanner scanUpToString:@"<" intoString:&part])
      {
	value = [value stringByAppendingString:part];
      }
  }
  return value;
}

static NSString *getFile(NSString *name, NSString *type)
{
  return [NSBundle pathForLibraryResource: name
				   ofType: type
			      inDirectory: NSPrinter_PATH];
}


@interface NSPrinter (private)
+ allocMaps;
- initWithPPD:(NSString *)PPDstring
     withName:(NSString *)name
     withType:(NSString *)type
     withHost:(NSString *)host
     withNote:(NSString *)note
     fromFile:(NSString *)file
       isReal:(BOOL)real;
-    loadPPD:(NSString *)PPDstring
inclusionNum:(int)includeNum;
- addPPDKeyword:(NSString *)mainKeyword
    withScanner:(NSScanner *)PPDdata;
- addPPDUIConstraint:(NSScanner *)constraint;
- addPPDOrderDependency:(NSScanner *)dependency;
-           addValue:(NSString *)value
 andValueTranslation:(NSString *)valueTranslation
andOptionTranslation:(NSString *)optionTranslation
	      forKey:(NSString *)key;
- addString:(NSString *)string
     forKey:(NSString *)key
    inTable:(NSMutableDictionary *)table;
@end

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
  NSString *path;
  NSArray *printerInfo;
  NSPrinter *printer;
  /* Contents of printerInfo array:
   * [0]: NSString of the printer's type
   * [1]: NSString of the printer's host
   * [2]: NSString of the printer's note
   */
  // Make sure the printer names dictionary etc. exists
  if (!nameMap)
    [self allocMaps];
  printer = NSMapGet(nameMap, name);
  // If the NSPrinter object for the printer already exists, return it
  if (printer)
    return printer;
  // Otherwise, try to find the information in the nameDict
  printerInfo = [nameDict objectForKey:name];
  // Make sure you can find the printer name in the dictionary
  if (!printerInfo)
    {
      [NSException raise:NSGenericException
		   format:@"Could not find printer named %@", name];
      // NOT REACHED
    }
  // Create it
  path = getFile([printerInfo objectAtIndex:0], @"ppd");
  // If not found
  if (path == nil || [path length] == 0)
    {
      [NSException raise:NSGenericException
		   format:@"Could not find PPD file %@.ppd",
		   [printerInfo objectAtIndex:0]];
      // NOT REACHED
    }
  printer = AUTORELEASE([[self alloc]
	       initWithPPD:[NSString stringWithContentsOfFile:path]
	       withName:name
	       withType:[printerInfo objectAtIndex:0]
	       withHost:[printerInfo objectAtIndex:1]
	       withNote:[printerInfo objectAtIndex:2]
	       fromFile:[printerInfo objectAtIndex:0]
	       isReal:YES]);
  // Once created, put it in the map table
  NSMapInsert(nameMap, name, printer);
  return printer;
}

+ (NSPrinter *)printerWithType:(NSString *)type
{
  NSString *path;
  NSPrinter *printer = nil;
  // Make sure the printer types dictionary exists
  if (!typeMap)
    [self allocMaps];
  else
    printer = NSMapGet(typeMap, type);
  // If the NSPrinter is already created, use it
  if (printer)
    return printer;
  path = getFile(type, @"ppd");
  // If not found
  if (path == nil || [path length] == 0)
    {
      [NSException raise:NSGenericException
		   format:@"Could not find PPD file %@.ppd", type];
      // NOT REACHED
    }
  printer = AUTORELEASE([[self alloc]
	       initWithPPD:[NSString stringWithContentsOfFile:path]
	       withName:type withType:type withHost:@"" withNote:@""
	       fromFile:path isReal:NO]);
  // Once created, put it in the hash table
  NSMapInsert(typeMap, type, printer);
  return printer;
}

+ (NSArray *)printerNames
{
  if(!nameDict)
    [NSPrinter allocMaps];
  return [nameDict allKeys];
}

+ (NSArray *)printerTypes
{
  NSEnumerator *pathEnum;
  NSBundle *lbdle;
  NSString *lpath;
  NSArray *ppdpaths;
  NSMutableArray *printers;
  NSString *path;
  NSAutoreleasePool *subpool; // There's a lot of temp strings used...
  int i, max;

  if (printerTypesAvailable)
    return printerTypesAvailable;

  printers = RETAIN([NSMutableArray array]);
  subpool = [[NSAutoreleasePool alloc] init];

  pathEnum = [NSSearchPathForDirectoriesInDomains(GSLibrariesDirectory,
               NSAllDomainsMask, YES) objectEnumerator];
  while ((lpath = [pathEnum nextObject]))
    {
      lbdle = [NSBundle bundleWithPath: lpath];
      ppdpaths = [lbdle pathsForResourcesOfType:@"ppd"
                                  inDirectory:NSPrinter_PATH];

      // FIXME - should get name from contents of PPD, not filename
      max = [ppdpaths count];
      for (i = 0; i < max; i++)
        {
          path = [[ppdpaths objectAtIndex:i] lastPathComponent];
          [printers addObject:[path substringToIndex:[path length]-4]];
        }
    }
  RELEASE(subpool);

  printerTypesAvailable = printers;
  return printers;
}

//
// Instance methods
//
//
// Deallocation of instance variables
//
- (void)dealloc
{
  // Remove object from the appropriate table
  if (_isRealPrinter)
    NSMapRemove(nameMap, _printerName);
  else
    NSMapRemove(typeMap, _printerType);
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
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isRealPrinter];

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
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isRealPrinter];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_PPD];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_PPDOptionTranslation];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_PPDArgumentTranslation];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_PPDOrderDependency];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_PPDUIConstraints];

  return self;
}

//
// Private Methods
//

//
// Allocate the printer name to PPD filename index dictionary
//
+ allocMaps
{
  NSString *path;

  // Allocate name and type maps
  typeMap = NSCreateMapTable(NSObjectMapKeyCallBacks,
			     NSNonRetainedObjectMapValueCallBacks,
			     TYPEMAPSIZE);
  nameMap = NSCreateMapTable(NSObjectMapKeyCallBacks,
			     NSNonRetainedObjectMapValueCallBacks,
			     NAMEMAPSIZE);

  // Load the index file
  path = [NSBundle pathForLibraryResource: NSPrinter_INDEXFILE
				   ofType: nil
			      inDirectory: @"PostScript"];
  // If not found
  if (path == nil || [path length] == 0)
    {
      NSLog(@"Could not find index of printers, file %@", NSPrinter_INDEXFILE);
      nameDict = [NSDictionary dictionaryWithObject:
		    [NSArray arrayWithObjects: @"Apple_LaserWriter_II_NTX",
					        @"localhost", @"A Note", nil]
			                     forKey: @"Unknown"];
    }
  else
    nameDict = [NSDictionary dictionaryWithContentsOfFile:path];
  RETAIN(nameDict);
  return self;
}

//
// Initialisation method
//
// To keep loading of PPDs relatively fast, not much checking is done on it.
- initWithPPD:(NSString *)PPDstring
     withName:(NSString *)name
     withType:(NSString *)type
     withHost:(NSString *)host
     withNote:(NSString *)note
     fromFile:(NSString *)file
       isReal:(BOOL)real
{
  NSAutoreleasePool *subpool;
  NSEnumerator *objEnum;
  NSMutableArray *valArray;

  // Initialise instance variables
  _printerName = RETAIN(name);
  _printerType = RETAIN(type);
  _printerHost = RETAIN(host);
  _printerNote = RETAIN(note);
  _cacheAcceptsBinary = _cacheOutputOrder = -1;
  _isRealPrinter = real;
  _PPD = RETAIN([NSMutableDictionary dictionary]);
  _PPDOptionTranslation = RETAIN([NSMutableDictionary dictionary]);
  _PPDArgumentTranslation = RETAIN([NSMutableDictionary dictionary]);
  _PPDOrderDependency = RETAIN([NSMutableDictionary dictionary]);
  _PPDUIConstraints = RETAIN([NSMutableDictionary dictionary]);
  // Create a temporary autorelease pool, as many temporary objects are used
  subpool = [[NSAutoreleasePool alloc] init];
  // Create character sets used during scanning
  newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r"];
  keyEndSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r\t: "];
  optKeyEndSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r:/"];
  valueEndSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r/"];
  // Allowed repeated keys, used during scanning.
  repKeys = [NSArray arrayWithObjects:@"Emulators",
		     @"Extensions",
		     @"FaxSupport",
		   //@"Include", (handled separately)
		     @"Message",
		     @"PrinterError",
		     @"Product",
		     @"Protocols",
		     @"PSVersion",
		     @"Source",
		     @"Status",
		   //@"UIConstraints", (handled separately)
  // Even though this is not mentioned in the list of repeated keywords, 
  // it's often repeated anyway, so I'm putting it here.
		     @"InkName",
		     nil];
  // Set the file name to use
  PPDFileName = file;
  // NB: There are some structure keywords (such as OpenUI/CloseUI) that may
  // be repeated, but as yet are not used. Since they are structure keywords,
  // they'll probably need special processing anyway, and so aren't
  // added to this list.
  // Create dictionary for temporary storage of symbol values
  PPDSymbolValues = [NSMutableDictionary dictionary];
  // And scan the PPD itself
  [self loadPPD:PPDstring inclusionNum:0];
  // Search the PPD dictionary for symbolvalues, and substitute them.
  objEnum = [_PPD objectEnumerator];
  while ((valArray = [objEnum nextObject]))
    {
      NSString *oldValue;
      NSString *newValue;
      int i, max;
      max = [valArray count];
      for(i=0 ; i < max ; i++ )
	{
	  oldValue = [valArray objectAtIndex:i];
	  if ([oldValue isKindOfClass:[NSString class]]
	      && ![oldValue isEqual:@""]
	      && [[oldValue substringToIndex:1] isEqual:@"^"])
	    {
	      newValue = [PPDSymbolValues
			   objectForKey:[oldValue substringFromIndex:1]];
	      if (!newValue)
		{
		  [NSException
		    raise:NSPPDParseException
		    format:@"Unknown symbol value, ^%@ in PPD file %@.ppd",
		    oldValue, PPDFileName];
		  // NOT REACHED
		}
	      [valArray replaceObjectAtIndex:i withObject:newValue];
	    }
	}
    }

#if 0
  // DISABLED: Though the following keywords *should* be present, there seems
  // to be few problems is they are omitted. Many of the .ppd files I have 
  // don't have *LanguageEncoding, for example.

  // Make sure all the required keys are present
  objEnum = [[NSArray arrayWithObjects:@"NickName",
		      @"ModelName",
		      @"PCFileName",
		      @"Product",
		      @"PSVersion",
		      @"FileVersion",
		      @"FormatVersion",
		      @"LanguageEncoding",
		      @"LanguageVersion",
		      @"PageSize",
		      @"PageRegion",
		      @"ImageableArea",
		      @"PaperDimension",
		      @"PPD-Adobe",
		      nil] objectEnumerator];

  while (checkVal = [objEnum nextObject])
    {
      if (![self isKey:checkVal inTable:@"PPD"])
		{
		  [NSException
		    raise:NSPPDParseException
		    format:@"Required keyword *%@ not found in PPD file %@.ppd",
		    checkVal, PPDFileName];
		  // NOT REACHED
		}
    }
#endif

  // Release the local autoreleasePool
  RELEASE(subpool);
  return self;
}

-    loadPPD:(NSString *)PPDstring
inclusionNum:(int)includeNum
{
  NSScanner *PPDdata;
  NSString *keyword;

  // Set up the scanner - Appending a newline means that it should be
  // able to process the last line correctly
  PPDdata = [NSScanner scannerWithString:
			 [PPDstring stringByAppendingString:@"\n"]];
  [PPDdata setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
  // Main processing starts here...
  while (1) // Check it is not at end only after skipping the blanks
    {
      // Get to the start of a new keyword, skipping blank lines
      skipSpace(PPDdata);
      if ([PPDdata isAtEnd])
	break;
      // All new entries should starts '*'
      if (![PPDdata scanString:@"*" intoString:NULL])
	{
	  [NSException raise:NSPPDParseException
		       format:@"Line not starting * in PPD file %@.ppd",
		       PPDFileName];
	  // NOT REACHED
	}
      // Skip lines starting '*%', '*End', '*SymbolLength', or '*SymbolEnd'
      if ([PPDdata scanString:@"%" intoString:NULL]
	  || [PPDdata scanString:@"End" intoString:NULL]
	  || [PPDdata scanString:@"SymbolLength" intoString:NULL]
	  || [PPDdata scanString:@"SymbolEnd" intoString:NULL])
	{
	  [PPDdata scanUpToCharactersFromSet:newlineSet intoString:NULL];
	  continue;
	}
      // Read main keyword, up to a colon, space or newline
      [PPDdata scanUpToCharactersFromSet:keyEndSet intoString:&keyword];
      // Loop if there is no value section
      if ([PPDdata scanCharactersFromSet:newlineSet intoString:NULL])
	continue;
      // Add the line to the relevant table
      if ([keyword isEqual:@"OrderDependency"])
	[self addPPDOrderDependency:PPDdata];
      else if ([keyword isEqual:@"UIConstraints"])
	[self addPPDUIConstraint:PPDdata];
      else if ([keyword isEqual:@"Include"])
	{
	  NSString *fileName;
	  NSString *path;
	  [PPDdata scanString:@":" intoString:NULL];
	  // Find the filename between two "s
	  [PPDdata scanString:@"\"" intoString:NULL];
	  [PPDdata scanUpToString:@"\"" intoString:&fileName];
	  [PPDdata scanString:@"\"" intoString:NULL];
	  // Load the file
	  path = getFile(fileName, nil);
	  // If not found
	  if (path == nil || [path length] == 0)
	    {
	      [NSException raise:NSPPDIncludeNotFoundException
			   format:@"Could not find included PPD file %@", 
			   fileName];
	      // NOT REACHED
	    }
	  includeNum++;
	  if (includeNum > MAX_PPD_INCLUDES)
	    {
	      [NSException raise:NSPPDIncludeStackOverflowException
			   format:@"Too many *Includes in PPD"];
	      // NOT REACHED
	    }	    
	  [self loadPPD:[NSString stringWithContentsOfFile:path]
		inclusionNum:includeNum];
	}
      else if ([keyword isEqual:@"SymbolValue"])
	{
	  NSString *symbolName;
	  NSString *symbolVal;
	  if (![PPDdata scanString:@"^" intoString:NULL])
	    {
	      [NSException
		raise:NSPPDParseException
		format:@"Badly formatted *SymbolValue in PPD file %@.ppd",
		  PPDFileName];
	      // NOT REACHED
	    }	    
	  [PPDdata scanUpToString:@":" intoString:&symbolName];
	  [PPDdata scanString:@":" intoString:NULL];
	  [PPDdata scanString:@"\"" intoString:NULL];
	  [PPDdata scanUpToString:@"\"" intoString:&symbolVal];
	  if (!symbolVal)
	    symbolVal = @"";
	  [PPDdata scanString:@"\"" intoString:NULL];
	  [PPDSymbolValues setObject:symbolVal forKey:symbolName];
	}
      else
	[self addPPDKeyword:keyword withScanner:PPDdata];
    }
  return self;
}

- addPPDKeyword:(NSString *)mainKeyword
    withScanner:(NSScanner *)PPDdata
{ 
  NSString *optionKeyword = nil;
  NSString *optionTranslation = nil;
  NSString *value = nil;
  NSString *valueTranslation = nil;
  // Scan off any optionKeyword
  [PPDdata scanUpToCharactersFromSet:optKeyEndSet intoString:&optionKeyword];
  if ([PPDdata scanCharactersFromSet:newlineSet intoString:NULL])
    {
      [NSException raise:NSPPDParseException
        format:@"Keyword has optional keyword but no value in PPD file %@.ppd",
		   PPDFileName];
      // NOT REACHED
    }
  if ([PPDdata scanString:@"/" intoString:NULL])
    {
      // Option keyword translation exists - scan it
      [PPDdata scanUpToString:@":" intoString:&optionTranslation];
    }
  [PPDdata scanString:@":" intoString:NULL];
  // Read the value part
  // Values starting with a " are read until the second ", ignoring \n etc.
  if ([PPDdata scanString:@"\"" intoString:NULL])
    {
      [PPDdata scanUpToString:@"\"" intoString:&value];
      if (!value)
	value = @"";
      [PPDdata scanString:@"\"" intoString:NULL];
      // It is a QuotedValue if it's in quotes, and there is no option
      // key, or the main key is a *JCL keyword
      if (!optionKeyword || [[mainKeyword substringToIndex:3]
			      isEqualToString:@"JCL"])
	  value = interpretQuotedValue(value);
    }
  else
    {
      // Otherwise, scan up to the end of line or '/'
      [PPDdata scanUpToCharactersFromSet:valueEndSet intoString:&value];
    }
  // If there is a value translation, scan it
  if ([PPDdata scanString:@"/" intoString:NULL])
    {
      [PPDdata scanUpToCharactersFromSet:newlineSet
	       intoString:&valueTranslation];
    }
  // The translations also have to have any hex substrings interpreted
  if (optionTranslation)
    optionTranslation = interpretQuotedValue(optionTranslation);
  if (valueTranslation)
    valueTranslation = interpretQuotedValue(valueTranslation);
  // The keyword (or keyword/option pair, if there's a option), should only
  // only have one value, unless it's one of the optionless keywords which
  // allow multiple instances.
  // If a keyword is read twice, 'first instance is correct', according to
  // the standard.
  // Finally, add the strings to the tables
  if (optionKeyword)
    {
      NSString *mainAndOptionKeyword=[mainKeyword
				       stringByAppendingFormat:@"/%@",
				       optionKeyword];
      if ([self isKey:mainAndOptionKeyword inTable:@"PPD"])
	return self;
      [self addValue:value
	    andValueTranslation:valueTranslation
	    andOptionTranslation:optionTranslation
	    forKey:mainAndOptionKeyword];
      // Deal with the oddities of stringForKey:inTable:
      // If this method is used to find a keyword with options, using
      // just the keyword it should return an empty string
      // stringListForKey:inTable:, however, should return the list of
      // option keywords.
      // This is done by making the first item in the array an empty
      // string, which will be skipped by stringListForKey:, if necessary
      if (![_PPD objectForKey:mainKeyword])
	{
	  [self addString:@"" forKey:mainKeyword inTable:_PPD];
	  [self addString:@"" forKey:mainKeyword inTable:_PPDOptionTranslation];
	  [self addString:@"" forKey:mainKeyword 
		inTable:_PPDArgumentTranslation];
	}
      [self addValue:optionKeyword
	    andValueTranslation:optionKeyword
	    andOptionTranslation:optionKeyword
	    forKey:mainKeyword];
    }
  else
    {
      if ([self isKey:mainKeyword inTable:@"PPD"] && 
	  ![repKeys containsObject:mainKeyword])
	return self;
      [self addValue:value
	    andValueTranslation:valueTranslation
	    andOptionTranslation:optionTranslation
	    forKey:mainKeyword];
    }
  return self;
}

- addPPDUIConstraint:(NSScanner *)constraint
{
  NSString *mainKey1 = nil;
  NSString *optionKey1 = nil;
  NSString *mainKey2 = nil;
  NSString *optionKey2 = nil;
  // UIConstraint should have no option keyword
  if (![constraint scanString:@":" intoString:NULL])
    {
      [NSException raise:NSPPDParseException
	format:@"UIConstraints has option keyword in PPDFileName %@.ppd",
		   PPDFileName];
      // NOT REACHED
    }
  // Skip the '*'
  [constraint scanString:@"*" intoString:NULL];
  // Scan the bits. Stuff not starting with * must be an optionKeyword
  [constraint scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]
	      intoString:&mainKey1];
  if (![constraint scanString:@"*" intoString:NULL])
    {
      [constraint scanUpToCharactersFromSet:[NSCharacterSet 
					     whitespaceCharacterSet]
		  intoString:&optionKey1];
      [constraint scanString:@"*" intoString:NULL];
    }
  [constraint scanUpToCharactersFromSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]
	      intoString:&mainKey2];
  if (![constraint scanCharactersFromSet:newlineSet intoString:NULL])
    {
      [constraint scanUpToCharactersFromSet:
		    [NSCharacterSet whitespaceAndNewlineCharacterSet]
		  intoString:&optionKey2];
    }
  else
    {
      optionKey2 = @"";
    }
  // Add to table
  if (optionKey1)
    mainKey1 = [mainKey1 stringByAppendingFormat:@"/%@", optionKey1];
  [self addString:mainKey2
	forKey:mainKey1
	inTable:_PPDUIConstraints];
  [self addString:optionKey2
	forKey:mainKey1
	inTable:_PPDUIConstraints];
  return self;
}

- addPPDOrderDependency:(NSScanner *)dependency
{
  NSString *realValue = nil;
  NSString *section = nil;
  NSString *keyword = nil;
  NSString *optionKeyword = nil;
  // Order dependency should have no option keyword
  if (![dependency scanString:@":" intoString:NULL])
    {
      [NSException raise:NSPPDParseException
	format:@"OrderDependency has option keyword in PPD file %@.ppd",
		   PPDFileName];
      // NOT REACHED
    }
  [dependency scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]
	      intoString:&realValue];
  [dependency scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]
	      intoString:&section];
  [dependency scanString:@"*" intoString:NULL];
  [dependency scanUpToCharactersFromSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]
	      intoString:&keyword];
  if (![dependency scanCharactersFromSet:newlineSet intoString:NULL])
    {
      // Optional keyword exists
      [dependency scanUpToCharactersFromSet:
		    [NSCharacterSet whitespaceAndNewlineCharacterSet]
		  intoString:&optionKeyword];
    }
  // Go to next line of PPD file
  [dependency scanCharactersFromSet:newlineSet intoString:NULL];
  // Add to table
  if (optionKeyword)
    keyword = [keyword stringByAppendingFormat:@"/%s", optionKeyword];
  [self addString:realValue forKey:keyword inTable:_PPDOrderDependency];
  [self addString:section forKey:keyword inTable:_PPDOrderDependency];
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
