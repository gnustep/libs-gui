/** <title>GSLPRPrinter</title>

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
#include <Foundation/NSDebug.h>
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
#include "GSLPRPrinter.h"
#include "GNUstepGUI/GSPrinting.h"

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


static NSDictionary *printerIndexDict = nil;  //The list of printers from NSPrinter_INDEXFILE
static NSMutableDictionary *printerObjNameDict = nil; //Printer objects mapped to names

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


@interface GSLPRPrinter (private)
+ loadPrinterIndexFile;
-(id)initWithPPD:(NSString *)PPDstring
        withName:(NSString *)name
        withType:(NSString *)type
        withHost:(NSString *)host
        withNote:(NSString *)note
        fromFile:(NSString *)file;
       
-     loadPPD:(NSString *)PPDstring
 inclusionNum:(int)includeNum;

- addPPDKeyword:(NSString *)mainKeyword
    withScanner:(NSScanner *)PPDdata;
    
- addPPDUIConstraint:(NSScanner *)constraint;

- addPPDOrderDependency:(NSScanner *)dependency;

@end


@implementation GSLPRPrinter

//
// Class methods
//
+ (void)initialize
{
  NSDebugMLLog(@"GSPrinting", @"");
  if (self == [GSLPRPrinter class])
    {
      // Initial version
      [self setVersion:1];
    }
}

+ (id) allocWithZone: (NSZone*)zone
{
  NSDebugMLLog(@"GSPrinting", @"");
  return NSAllocateObject(self, 0, zone);
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
   
  NSDebugMLLog(@"GSPrinting", @"");
  // Make sure the printer names dictionary etc. exists
  if (!printerIndexDict)
    [self loadPrinterIndexFile];
  
  if( name == nil )
    return nil;
    
  printer = [printerObjNameDict objectForKey: name];
  // If the NSPrinter object for the printer already exists, return it
  if (printer)
    return printer;
    
  // Otherwise, try to find the information in the printerIndexDict
  printerInfo = [printerIndexDict objectForKey: name];
  // Make sure you can find the printer name in the dictionary
  if (!printerInfo)
    {
      [NSException raise: NSGenericException
		              format: @"Could not find printer named %@", name];
      // NOT REACHED
    }
  // Create it
  path = getFile([printerInfo objectAtIndex:0], @"ppd");
  // If not found
  if (path == nil || [path length] == 0)
    {
      [NSException raise: NSGenericException
		              format: @"Could not find PPD file %@.ppd",
		              [printerInfo objectAtIndex:0]];
      // NOT REACHED
    }
    
  printer = [(GSLPRPrinter*)[self alloc]
	              initWithPPD: [NSString stringWithContentsOfFile:path]
	                 withName: name
	                 withType: [printerInfo objectAtIndex:0]
	                 withHost: [printerInfo objectAtIndex:1]
	                 withNote: [printerInfo objectAtIndex:2]
	                 fromFile: [printerInfo objectAtIndex:0]];
         
  // Once created, set it in the dict for later use, this also retains it
  [printerObjNameDict setObject: printer
                         forKey: name];
                         
  return [printer autorelease];
}


+ (NSArray *)printerNames
{
  NSDebugMLLog(@"GSPrinting", @"");
  if(!printerIndexDict)
    [self loadPrinterIndexFile];
    
  return [printerIndexDict allKeys];
}



//
// Instance methods
//


//
// Private Methods
//

//
// Allocate the printer name to PPD filename index dictionary
//
+ loadPrinterIndexFile
{
  NSString *path;
  
  NSDebugMLLog(@"GSPrinting", @"");
  printerObjNameDict = [NSMutableDictionary dictionary];

  // Load the index file
  path = [NSBundle pathForLibraryResource: NSPrinter_INDEXFILE
				                           ofType: nil
			                        inDirectory: @"PostScript"];
                              
  // If not found
  if (path == nil || [path length] == 0)
    {
      NSLog(@"Could not find index of printers, file %@", NSPrinter_INDEXFILE);
      printerIndexDict = [NSDictionary dictionaryWithObject:
		    [NSArray arrayWithObjects: @"Apple_LaserWriter_II_NTX",
					        @"localhost", @"A Note", nil]
			                     forKey: @"Unknown"];
    }
  else
    {
      printerIndexDict = [NSDictionary dictionaryWithContentsOfFile:path];
    }
  RETAIN(printerObjNameDict);
  RETAIN(printerIndexDict);
  
  return self;
}

//
// Initialisation method
//
// To keep loading of PPDs relatively fast, not much checking is done on it.
-(id)initWithPPD:(NSString *)PPDstring
       withName:(NSString *)name
       withType:(NSString *)type
       withHost:(NSString *)host
       withNote:(NSString *)note
       fromFile:(NSString *)file
{
  NSAutoreleasePool *subpool;
  NSEnumerator *objEnum;
  NSMutableArray *valArray;
  
  self = [super initWithName: name
                    withType: type
                    withHost: host
                    withNote: note];
  
  NSDebugMLLog(@"GSPrinting", @"");

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
		              [NSException raise: NSPPDParseException
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
		      [NSException raise:NSPPDParseException
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

-     loadPPD:(NSString *)PPDstring
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
        {
	        [self addPPDOrderDependency:PPDdata];
        }
      else if ([keyword isEqual:@"UIConstraints"])
        {
	        [self addPPDUIConstraint:PPDdata];
        }
      else if ([keyword isEqual:@"Include"])
	      {
	        NSString *fileName;
	        NSString *path;
	        [PPDdata scanString:@":" 
                  intoString:NULL];
                  
	        // Find the filename between two "s"
	        [PPDdata scanString:@"\"" 
                   intoString:NULL];
                  
	        [PPDdata scanUpToString:@"\"" 
                       intoString:&fileName];
                      
	        [PPDdata scanString:@"\"" 
                   intoString:NULL];
                 
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
        
	        [self  loadPPD:[NSString stringWithContentsOfFile:path]
		        inclusionNum:includeNum];
	      }
      else if ([keyword isEqual:@"SymbolValue"])
	      {
	        NSString *symbolName;
	        NSString *symbolVal;
	        if (![PPDdata scanString:@"^" intoString:NULL])
	          {
	            [NSException raise:NSPPDParseException
		                  format:@"Badly formatted *SymbolValue in PPD file %@.ppd",
		                  PPDFileName];
	            // NOT REACHED
	          }	    
	        [PPDdata scanUpToString:@":" 
                       intoString:&symbolName];
                      
	        [PPDdata scanString:@":" 
                   intoString:NULL];
                  
	        [PPDdata scanString:@"\"" 
                   intoString:NULL];
                 
	        [PPDdata scanUpToString:@"\"" 
                       intoString:&symbolVal];
                 
	        if (!symbolVal)
	          symbolVal = @"";
      
	        [PPDdata scanString:@"\"" 
                   intoString:NULL];
             
	        [PPDSymbolValues setObject:symbolVal 
                              forKey:symbolName];
                        
	       }
       else
         {
	         [self addPPDKeyword:keyword 
                   withScanner:PPDdata];
         }
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
      [PPDdata scanUpToString:@"\"" 
                   intoString:&value];
                   
      if (!value)
	      value = @"";
        
      [PPDdata scanString:@"\"" 
               intoString:NULL];
               
      // It is a QuotedValue if it's in quotes, and there is no option
      // key, or the main key is a *JCL keyword
      if (!optionKeyword || [[mainKeyword substringToIndex:3]
			      isEqualToString:@"JCL"])
        {
	        value = interpretQuotedValue(value);
        }
    }
  else
    {
      // Otherwise, scan up to the end of line or '/'
      [PPDdata scanUpToCharactersFromSet:valueEndSet 
                              intoString:&value];
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
        
      [self             addValue:value
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
	        [self addString:@"" 
                   forKey:mainKeyword 
                  inTable:_PPD];
                  
	        [self addString:@"" 
                   forKey:mainKeyword 
                  inTable:_PPDOptionTranslation];
                  
	        [self addString:@"" 
                   forKey:mainKeyword 
		              inTable:_PPDArgumentTranslation];
                  
	      }
        
      [self             addValue:optionKeyword
	           andValueTranslation:optionKeyword
	          andOptionTranslation:optionKeyword
	                        forKey:mainKeyword];
    }
  else
    {
      if ([self isKey:mainKeyword inTable:@"PPD"] && 
	        ![repKeys containsObject:mainKeyword])
        {
	        return self;
        }
        
      [self             addValue:value
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
  [constraint scanString:@"*" 
              intoString:NULL];
              
  // Scan the bits. Stuff not starting with * must be an optionKeyword
  [constraint scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]
	      intoString:&mainKey1];
  if (![constraint scanString:@"*" intoString:NULL])
    {
      [constraint scanUpToCharactersFromSet:
                          [NSCharacterSet whitespaceCharacterSet]
		                             intoString:&optionKey1];
                                 
      [constraint scanString:@"*" 
                  intoString:NULL];
                  
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
                             
  [dependency scanString:@"*" 
              intoString:NULL];
              
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
  [dependency scanCharactersFromSet:newlineSet 
                         intoString:NULL];
                         
  // Add to table
  if (optionKeyword)
    keyword = [keyword stringByAppendingFormat:@"/%s", optionKeyword];
    
  [self addString:realValue 
           forKey:keyword 
          inTable:_PPDOrderDependency];
          
  [self addString:section 
           forKey:keyword 
          inTable:_PPDOrderDependency];
          
  return self;
}




-(id) initWithCoder: (NSCoder*) coder
{
  self = [super initWithCoder: coder];
  return self;
}

-(void) encodeWithCoder: (NSCoder*) coder
{
  [super encodeWithCoder: coder];
}
  

@end
