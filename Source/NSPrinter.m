/* 
   NSPrinter.m

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

/* FIXMES to do:
 *
 * Loading PPD files:
 * Interpret *includes
 * Interpret Symbol values
 * Reading of hex values in strings
 * Proper checking of the PPD as it is loaded
 * Add a printerNames function (to complement printerTypes)?
 *
 * Other:
 * Do deviceDescription
 * Do encoding/decoding
 */

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSScanner.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSPrinter.h>

#ifndef NSPrinter_PATH
#define NSPrinter_PATH @GNUSTEP_INSTALL_LIBDIR @"/PrinterTypes"
#endif

#ifndef NSPrinter_INDEXFILE
#define NSPrinter_INDEXFILE @"Printers"
#endif


// Define size used for the name and type maps - just use a small table
#define NAMEMAPSIZE 0
#define TYPEMAPSIZE 0

// Printing Information Dictionary Keys 
NSString *NSPrintAllPages = @"PrintAllPages";
NSString *NSPrintBottomMargin = @"PrintBottomMargin";
NSString *NSPrintCopies = @"PrintCopies";
NSString *NSPrintFaxCoverSheetName = @"PrintFaxCoverSheetName";
NSString *NSPrintFaxHighResolution = @"PrintFaxHighResolution";
NSString *NSPrintFaxModem = @"PrintFaxModem";
NSString *NSPrintFaxReceiverNames = @"PrintFaxReceiverNames";
NSString *NSPrintFaxReceiverNumbers = @"PrintFaxReceiverNumbers";
NSString *NSPrintFaxReturnReceipt = @"PrintFaxReturnReceipt";
NSString *NSPrintFaxSendTime = @"PrintFaxSendTime";
NSString *NSPrintFaxTrimPageEnds = @"PrintFaxTrimPageEnds";
NSString *NSPrintFaxUseCoverSheet = @"PrintFaxUseCoverSheet";
NSString *NSPrintFirstPage = @"PrintFirstPage";
NSString *NSPrintHorizonalPagination = @"PrintHorizonalPagination";
NSString *NSPrintHorizontallyCentered = @"PrintHorizontallyCentered";
NSString *NSPrintJobDisposition = @"PrintJobDisposition";
NSString *NSPrintJobFeatures = @"PrintJobFeatures";
NSString *NSPrintLastPage = @"PrintLastPage";
NSString *NSPrintLeftMargin = @"PrintLeftMargin";
NSString *NSPrintManualFeed = @"PrintManualFeed";
NSString *NSPrintOrientation = @"PrintOrientation";
NSString *NSPrintPagesPerSheet = @"PrintPagesPerSheet";
NSString *NSPrintPaperFeed = @"PrintPaperFeed";
NSString *NSPrintPaperName = @"PrintPaperName";
NSString *NSPrintPaperSize = @"PrintPaperSize";
NSString *NSPrintPrinter = @"PrintPrinter";
NSString *NSPrintReversePageOrder = @"PrintReversePageOrder";
NSString *NSPrintRightMargin = @"PrintRightMargin";
NSString *NSPrintSavePath = @"PrintSavePath";
NSString *NSPrintScalingFactor = @"PrintScalingFactor";
NSString *NSPrintTopMargin = @"PrintTopMargin";
NSString *NSPrintVerticalPagination = @"PrintVerticalPagination";
NSString *NSPrintVerticallyCentered = @"PrintVerticallyCentered";

// Print Job Disposition Values 
NSString  *NSPrintCancelJob = @"PrintCancelJob";
NSString  *NSPrintFaxJob = @"PrintFaxJob";
NSString  *NSPrintPreviewJob = @"PrintPreviewJob";
NSString  *NSPrintSaveJob = @"PrintSaveJob";
NSString  *NSPrintSpoolJob = @"PrintSpoolJob";

// Class variables:

// Maps  holding NSPrinters with the types of printers, and the real printers
NSMapTable *typeMap = NULL;
NSMapTable *nameMap = NULL;

// Dictionary of real printers, from which NSPrinters can be made
NSDictionary *nameDict = nil;

// Character sets used in scanning.
NSCharacterSet *newlineSet = nil;
NSCharacterSet *keyEndSet = nil;
NSCharacterSet *optKeyEndSet = nil;
NSCharacterSet *valueEndSet = nil;

// Bundle used to load printer related information, such as PPDs.
NSBundle *printerBundle = nil;

// An array to cache the available printer types
NSArray *printerTypesAvailable = nil;

extern NSString* NSPPDParseException;

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


@interface NSPrinter (private)
+ allocMaps;
- initWithPPD:(NSString *)PPDstring
     withName:(NSString *)name
     withType:(NSString *)type
     withHost:(NSString *)host
     withNote:(NSString *)note
     fromFile:(NSString *)file
       isReal:(BOOL)real;
- addPPDKeyword:(NSString *)mainKeyword
    withScanner:(NSScanner *)PPDdata
       fromFile:(NSString *)file;
- addPPDUIConstraint:(NSScanner *)constraint
	    fromFile:(NSString *)file;
- addPPDOrderDependency:(NSScanner *)dependency
	       fromFile:(NSString *)file;
- addValue:(NSString *)value
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
		   format:@"Could not find printer named %s", [name cString]];
      // NOT REACHED
    }
  // Create it
  path = [printerBundle pathForResource:[printerInfo objectAtIndex:0]
			ofType:@"ppd"];
  // If not found
  if (path == nil || [path length] == 0)
    {
      [NSException raise:NSGenericException
		   format:@"Could not find PPD file %s.ppd", 
		   [[printerInfo objectAtIndex:0] cString]];
      // NOT REACHED
    }
  printer = [[[self alloc]
	       initWithPPD:[NSString stringWithContentsOfFile:path]
	       withName:name
	       withType:[printerInfo objectAtIndex:0]
	       withHost:[printerInfo objectAtIndex:1]
	       withNote:[printerInfo objectAtIndex:2]
	       fromFile:[printerInfo objectAtIndex:0]
	       isReal:YES] autorelease];
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
  path = [printerBundle pathForResource:type ofType:@"ppd"];
  // If not found
  if (path == nil || [path length] == 0)
    {
      [NSException raise:NSGenericException
		   format:@"Could not find PPD file %s.ppd", 
		   [type cString]];
      // NOT REACHED
    }
  printer = [[[self alloc]
	       initWithPPD:[NSString stringWithContentsOfFile:path]
	       withName:type withType:type withHost:@"" withNote:@""
	       fromFile:path isReal:NO] autorelease];
  // Once created, put it in the hash table
  NSMapInsert(typeMap, type, printer);
  return printer;
}

+ (NSArray *)printerTypes
{
  NSDirectoryEnumerator *files;
  NSMutableArray *printers;
  NSString *fileName;
  int length;
  NSRange range;
  if (printerTypesAvailable)
    return printerTypesAvailable;
  files = [[NSFileManager defaultManager] enumeratorAtPath:NSPrinter_PATH];
  printers = [NSMutableArray array];
  while ((fileName = [files nextObject]))
    {
      length = [fileName length];
      if ([[fileName substringFromIndex:length - 4] isEqual:@".ppd"])
	{
	  range = [fileName rangeOfString:@"/" options:NSBackwardsSearch];
	  if (range.length)
	    {
	      range.location++;
	      range.length = length - range.location - 4;
	      fileName = [fileName substringWithRange:range];
	    }
	  else
	    fileName = [fileName substringToIndex:length - 4];
	  if (![printers containsObject:fileName])
	    [printers addObject:fileName];
	}
    }
  printerTypesAvailable = [printers retain];
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
  if (isRealPrinter)
    NSMapRemove(nameMap, printerName);
  else
    NSMapRemove(typeMap, printerType);
  [printerHost release];
  [printerName release];
  [printerNote release];
  [printerType release];
  [PPD release];
  [PPDOptionTranslation release];
  [PPDArgumentTranslation release];
  [PPDOrderDependency release];
  [PPDUIConstraints release];
  [super dealloc];
}

//
// Printer Attributes 
//
- (NSString *)host
{
  return printerHost;
}

- (NSString *)name
{
  return printerName;
}

- (NSString *)note
{
  return printerNote;
}

- (NSString *)type
{
  return printerType;
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

  if (cacheAcceptsBinary != -1)
    return cacheAcceptsBinary;
  result = [self stringForKey:@"Protocols" inTable:@"PPD"];
  if (!result)
    {
      cacheAcceptsBinary = NO;
      return NO;
    }
  protocols = [NSScanner scannerWithString:result];
  whitespace = [NSCharacterSet whitespaceCharacterSet];
  while(![protocols isAtEnd])
    {
      // FIXME: scanUpToCharactersFromSet does not skip whitespace before
      // reading the actual data, so it needs to be done manually
      [protocols scanCharactersFromSet:whitespace intoString:NULL];
      [protocols scanUpToCharactersFromSet:whitespace intoString:&result];
      if ([result isEqual:@"BCP"])
	{
	  cacheAcceptsBinary = YES;
	  return YES;
	}
    }
  cacheAcceptsBinary = NO;
  return NO;    
}

- (NSRect)imageRectForPaper:(NSString *)paperName
{
  return [self rectForKey:[NSString 
			    stringWithFormat:@"ImageableArea/%s",
			    [paperName cString]]
	       inTable:@"PPD"];
}

- (NSSize)pageSizeForPaper:(NSString *)paperName
{
  return [self sizeForKey:[NSString 
			    stringWithFormat:@"PaperDimension/%s",
			    [paperName cString]]
	       inTable:@"PPD"];
}

- (BOOL)isColor
{
  return [self booleanForKey:@"ColorDevice" inTable:@"PPD"];
}

- (BOOL)isFontAvailable:(NSString *)fontName
{
  return [self isKey:[NSString stringWithFormat:@"Font/%s", [fontName cString]]
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
  if (cacheOutputOrder != -1)
    return cacheOutputOrder;
  result = [self stringForKey:@"DefaultOutputOrder" inTable:@"PPD"];
  if (!result)
    {
      cacheOutputOrder = NO;
      return NO;
    }
  if ([result isEqual:@"Reverse"])
    {
      cacheOutputOrder = YES;
      return YES;
    }
  cacheOutputOrder = NO;
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
  // FIXME: I haven't got NSGraphics.h yet.
  return nil;
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
    checkMe = PPD;
  else if ([table isEqual:@"PPDOptionTranslation"])
    checkMe = PPDOptionTranslation;
  else if ([table isEqual:@"PPDArgumentTranslation"])
    checkMe = PPDArgumentTranslation;
  else if ([table isEqual:@"PPDOrderDependency"])
    checkMe = PPDOrderDependency;
  else if ([table isEqual:@"PPDUIConstraints"])
    checkMe = PPDUIConstraints;
  else
    {
      [NSException raise:NSGenericException
         format:@"Could not find PPD table %s", [table cString]];
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
    checkMe = PPD;
  else if ([table isEqual:@"PPDOptionTranslation"])
    checkMe = PPDOptionTranslation;
  else if ([table isEqual:@"PPDArgumentTranslation"])
    checkMe = PPDArgumentTranslation;
  else if ([table isEqual:@"PPDOrderDependency"])
    checkMe = PPDOrderDependency;
  else if ([table isEqual:@"PPDUIConstraints"])
    checkMe = PPDUIConstraints;
  else
    {
      [NSException raise:NSGenericException
         format:@"Could not find PPD table %s", [table cString]];
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
    checkMe = PPD;
  else if ([table isEqual:@"PPDOptionTranslation"])
    checkMe = PPDOptionTranslation;
  else if ([table isEqual:@"PPDArgumentTranslation"])
    checkMe = PPDArgumentTranslation;
  else if ([table isEqual:@"PPDOrderDependency"])
    checkMe = PPDOrderDependency;
  else if ([table isEqual:@"PPDUIConstraints"])
    checkMe = PPDUIConstraints;
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
    checkMe = PPD;
  else if ([table isEqual:@"PPDOptionTranslation"])
    checkMe = PPDOptionTranslation;
  else if ([table isEqual:@"PPDArgumentTranslation"])
    checkMe = PPDArgumentTranslation;
  else if ([table isEqual:@"PPDOrderDependency"])
    checkMe = PPDOrderDependency;
  else if ([table isEqual:@"PPDUIConstraints"])
    checkMe = PPDUIConstraints;
  else
    {
      [NSException raise:NSGenericException
         format:@"Could not find PPD table %s", [table cString]];
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
- (void)encodeWithCoder:aCoder
{
  // FIXME: implement this
  // [super encodeWithCoder:aCoder];
}

- initWithCoder:aDecoder
{
  //  [super initWithCoder:aDecoder];
  // FIXME: implement this
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

  // Make sure the printer bundle is created
  if (!printerBundle)
    printerBundle = [[NSBundle bundleWithPath:NSPrinter_PATH] retain];
  path = [printerBundle pathForResource:NSPrinter_INDEXFILE ofType:nil];
  // If not found
  if (path == nil || [path length] == 0)
    {
      [NSException raise:NSGenericException
		   format:@"Could not find index of printers, file %s",
		   [NSPrinter_INDEXFILE cString]];
      // NOT REACHED
    }
  // Allocate name and type maps
  typeMap = NSCreateMapTable(NSObjectMapKeyCallBacks,
			     NSNonRetainedObjectMapValueCallBacks,
			     TYPEMAPSIZE);
  nameMap = NSCreateMapTable(NSObjectMapKeyCallBacks,
			     NSNonRetainedObjectMapValueCallBacks,
			     NAMEMAPSIZE);
  // And create the name dictionary, loading it
  nameDict = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
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
  NSScanner *PPDdata;
  NSString *keyword;

  // Initialise instance variables
  printerName = [name retain];
  printerType = [type retain];
  printerHost = [host retain];
  printerNote = [note retain];
  cacheAcceptsBinary = cacheOutputOrder = -1;
  isRealPrinter = real;
  PPD = [[NSMutableDictionary dictionary] retain];
  PPDOptionTranslation = [[NSMutableDictionary dictionary] retain];
  PPDArgumentTranslation = [[NSMutableDictionary dictionary] retain];
  PPDOrderDependency = [[NSMutableDictionary dictionary] retain];
  PPDUIConstraints = [[NSMutableDictionary dictionary] retain];
  // Create a temporary autorelease pool, as many temporary objects are used
  subpool = [[NSAutoreleasePool alloc] init];
  // Create character sets used during scanning
  newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r"];
  keyEndSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r\t: "];
  optKeyEndSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r:/"];
  valueEndSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r/"];
  // Set up the scanner - Appending a newline means that it should be
  // able to process the last line correctly
  PPDdata = [NSScanner scannerWithString:
			 [PPDstring stringByAppendingString:@"\n"]];
  [PPDdata setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
  // Main processing starts here...
  while (1) // Check it is not at end only after skipping the blanks
    {
      // Get to the start of a new keyword, skipping blank lines
      [PPDdata scanCharactersFromSet:[NSCharacterSet 
				       whitespaceAndNewlineCharacterSet]
	       intoString:NULL];
      if ([PPDdata isAtEnd])
	break;
      // All new entries should starts '*'
      if (![PPDdata scanString:@"*" intoString:NULL])
	{
	  [NSException raise:NSPPDParseException
		       format:@"Line not starting * in PPD file %s.ppd",
		       [file cString]];
	  // NOT REACHED
	}
      // Skip comments starting '*%'
      if ([PPDdata scanString:@"%" intoString:NULL])
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
	[self addPPDOrderDependency:PPDdata fromFile:file];
      else if ([keyword isEqual:@"UIConstraints"])
	[self addPPDUIConstraint:PPDdata fromFile:file];
      else
	[self addPPDKeyword:keyword withScanner:PPDdata fromFile:file];
    }
  // Release the local autoreleasePool
  [subpool release];
  return self;
}

- addPPDKeyword:(NSString *)mainKeyword
    withScanner:(NSScanner *)PPDdata
       fromFile:(NSString *)file
{ 
  NSString *optionKeyword = nil;
  NSString *optionTranslation = nil;
  NSString *value = nil;
  NSString *valueTranslation = nil;
  // Scan off any optionKeyword
  // FIXME: scanUpToCharactersFromSet does not skip whitespace before
  // reading the actual data, so it needs to be done manually
  [PPDdata scanCharactersFromSet:
	     [NSCharacterSet whitespaceAndNewlineCharacterSet]
	   intoString:NULL];
  [PPDdata scanUpToCharactersFromSet:optKeyEndSet intoString:&optionKeyword];
  if ([PPDdata scanCharactersFromSet:newlineSet intoString:NULL])
    {
      [NSException raise:NSPPDParseException
        format:@"Keyword has optional keyword but no value in PPD file %s.ppd",
		   [file cString]];
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
      [PPDdata scanString:@"\"" intoString:NULL];
    }
  else
    {
      // Otherwise, scan up to the end of line or '/'
      // FIXME: scanUpToCharactersFromSet does not skip whitespace before
      // reading the actual data, so it needs to be done manually
      [PPDdata scanCharactersFromSet:
		    [NSCharacterSet whitespaceAndNewlineCharacterSet]
		  intoString:NULL];
      [PPDdata scanUpToCharactersFromSet:valueEndSet intoString:&value];
    }
  // If there is a value translation, scan it
  if ([PPDdata scanString:@"/" intoString:NULL])
    {
      [PPDdata scanUpToCharactersFromSet:newlineSet
	       intoString:&valueTranslation];
    }
  // Finally, add the strings to the tables
  if (optionKeyword)
    {
      [self addValue:value
	    andValueTranslation:valueTranslation
	    andOptionTranslation:optionTranslation
	    forKey:[mainKeyword stringByAppendingFormat:@"/%s",
				[optionKeyword cString]]];
      // Deal with the oddities of stringForKey:inTable:
      // If this method is used to find a keyword with options, using
      // just the keyword it should return an empty string
      // stringListForKey:inTable:, however, should return the list of
      // option keywords.
      // This is done by making the first item in the array an empty
      // string, which will be skipped by stringListForKey:, if necessary
      if (![PPD objectForKey:mainKeyword])
	{
	  [self addString:@"" forKey:mainKeyword inTable:PPD];
	  [self addString:@"" forKey:mainKeyword inTable:PPDOptionTranslation];
	  [self addString:@"" forKey:mainKeyword 
		inTable:PPDArgumentTranslation];
	}
      [self addValue:optionKeyword
	    andValueTranslation:optionKeyword
	    andOptionTranslation:optionKeyword
	    forKey:mainKeyword];
    }
  else
    {
      [self addValue:value
	    andValueTranslation:valueTranslation
	    andOptionTranslation:optionTranslation
	    forKey:mainKeyword];
    }
  return self;
}

- addPPDUIConstraint:(NSScanner *)constraint
	    fromFile:(NSString *)file
{
  NSString *mainKey1 = nil;
  NSString *optionKey1 = nil;
  NSString *mainKey2 = nil;
  NSString *optionKey2 = nil;
  // UIConstraint should have no option keyword
  if (![constraint scanString:@":" intoString:NULL])
    {
      [NSException raise:NSPPDParseException
	format:@"UIConstraints has option keyword in PPDfile %s.ppd",
		   [file cString]];
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
      // FIXME: scanUpToCharactersFromSet does not skip whitespace before
      // reading the actual data, so it needs to be done manually
      [constraint scanCharactersFromSet:
		    [NSCharacterSet whitespaceAndNewlineCharacterSet]
		  intoString:NULL];
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
    mainKey1 = [mainKey1 stringByAppendingFormat:@"/%s",[optionKey1 cString]];
  [self addString:mainKey2
	forKey:mainKey1
	inTable:PPDUIConstraints];
  [self addString:optionKey2
	forKey:mainKey1
	inTable:PPDUIConstraints];
  return self;
}

- addPPDOrderDependency:(NSScanner *)dependency
	       fromFile:(NSString *)file
{
  NSString *realValue = nil;
  NSString *section = nil;
  NSString *keyword = nil;
  NSString *optionKeyword = nil;
  // Order dependency  should have no option keyword
  if (![dependency scanString:@":" intoString:NULL])
    {
      [NSException raise:NSPPDParseException
	format:@"OrderDependency has option keyword in PPD file %s.ppd",
		   [file cString]];
      // NOT REACHED
    }
  // FIXME: scanUpToCharactersFromSet does not skip whitespace before
  // reading the actual data, so it needs to be done manually
  [dependency scanCharactersFromSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]
	      intoString:NULL];
  [dependency scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]
	      intoString:&realValue];
  // FIXME: scanUpToCharactersFromSet does not skip whitespace before
  // reading the actual data, so it needs to be done manually
  [dependency scanCharactersFromSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]
	      intoString:NULL];
  [dependency scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]
	      intoString:&section];
  [dependency scanString:@"*" intoString:NULL];
  [dependency scanUpToCharactersFromSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]
	      intoString:&keyword];
  if (![dependency scanCharactersFromSet:newlineSet intoString:NULL])
    {
      // Optional keyword exists
      // FIXME: scanUpToCharactersFromSet does not skip whitespace before
      // reading the actual data, so it needs to be done manually
      [dependency scanCharactersFromSet:
		    [NSCharacterSet whitespaceAndNewlineCharacterSet]
		  intoString:NULL];
      [dependency scanUpToCharactersFromSet:
		    [NSCharacterSet whitespaceAndNewlineCharacterSet]
		  intoString:&optionKeyword];
    }
  // Go to next line of PPD file
  [dependency scanCharactersFromSet:newlineSet intoString:NULL];
  // Add to table
  if (optionKeyword)
    keyword = [keyword stringByAppendingFormat:@"/%s",
		       [optionKeyword cString]];
  [self addString:realValue forKey:keyword inTable:PPDOrderDependency];
  [self addString:section forKey:keyword inTable:PPDOrderDependency];
  return self;
}

//
// Adds the various values to the relevant tables, for the given key
//
- addValue:(NSString *)value
andValueTranslation:(NSString *)valueTranslation
andOptionTranslation:(NSString *)optionTranslation
forKey:(NSString *)key
{
  [self addString:value forKey:key inTable:PPD];
  if (valueTranslation)
    [self addString:valueTranslation forKey:key
	  inTable:PPDArgumentTranslation];
  if (optionTranslation)
    [self addString:optionTranslation forKey:key
	  inTable:PPDOptionTranslation];
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
