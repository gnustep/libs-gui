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
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSMapTable.h>
#include "AppKit/AppKitExceptions.h"
#include "AppKit/NSGraphics.h"
#include "GSLPRPrinter.h"
#include "GNUstepGUI/GSPrinting.h"



@interface GSLPRPrinter (Private)

+(NSDictionary*) printersDictionary;

-(id) initWithName: (NSString*) name
          withType: (NSString*) type
          withHost: (NSString*) host
          withNote: (NSString*) note
       withPPDPath: (NSString*) ppdPath;
@end


@implementation GSLPRPrinter

//
// Class methods
//
+(void) initialize
{
  NSDebugMLLog(@"GSPrinting", @"");
  if (self == [GSLPRPrinter class])
    {
      // Initial version
      [self setVersion:1];
    }
}


+(id) allocWithZone: (NSZone*) zone
{
  NSDebugMLLog(@"GSPrinting", @"");
  return NSAllocateObject(self, 0, zone);
}

//
// Finding an NSPrinter 
//
+ (NSPrinter*) printerWithName: (NSString*) name
{
  NSDictionary* printersDict;
  NSDictionary* printerEntry;
  NSString* ppdContents;
  NSPrinter* printer;

  printersDict = [self printersDictionary];
 
  printerEntry = [printersDict objectForKey: name];

  if( printerEntry == nil)
    {
      [NSException raise: NSGenericException
                  format: @"(GSLPR) Could not find printer named %@", name];
      return nil;
    }

  ppdContents = [NSString stringWithContentsOfFile: 
                 [printerEntry objectForKey: @"PPDPath"]];

  NSDebugMLLog(@"GSPrinting", @"Creating NSPrinter with Printer Entry: %@", 
               [printerEntry description]);

  printer = [(GSLPRPrinter*)[self alloc]
                    initWithName: name
                        withType: [printerEntry objectForKey: @"Type"]
                        withHost: [printerEntry objectForKey: @"Host"]
                        withNote: [printerEntry objectForKey: @"Note"]
                     withPPDPath: [printerEntry objectForKey: @"PPDPath"]];
                         
  return [printer autorelease];
}


+ (NSArray *)printerNames
{
  NSDebugMLLog(@"GSPrinting", @"");

  return [[self printersDictionary] allKeys];
}


-(BOOL) acceptsBinary
{
  // FIXME: I'm not sure if acceptsBinary is the same as BCP protocol?
  NSString *result;
  NSScanner *protocols;

  result = [self stringForKey: @"Protocols" 
                      inTable: @"PPD"];
  if (!result)
      return NO;

  protocols = [NSScanner scannerWithString: result];

  while( ![protocols isAtEnd] )
    {
      [protocols scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
                                intoString: &result];

      if ( [result isEqual:@"BCP"] )
	  return YES;
    }

  return NO;    
}


-(NSRect) imageRectForPaper: (NSString*) paperName
{
  NSString *key;
 
  key = [NSString stringWithFormat: @"ImageableArea/%@", paperName];

  return [self rectForKey: key
                  inTable: @"PPD"];
}


-(NSSize) pageSizeForPaper: (NSString*) paperName
{
  NSString *key;

  key = [NSString stringWithFormat: @"PaperDimension/%@", paperName];

  return [self sizeForKey: key
                  inTable: @"PPD"];
}


-(BOOL) isColor
{
  return [self booleanForKey: @"ColorDevice" 
                     inTable: @"PPD"];
}


-(BOOL) isFontAvailable: (NSString*) fontName
{
  NSString *key;

  key = [NSString stringWithFormat: @"Font/%@", fontName];
  return [self isKey: key
             inTable: @"PPD"];
}


-(int) languageLevel
{
  return [self intForKey: @"LanguageLevel" 
                 inTable: @"PPD"];
}


-(BOOL) isOutputStackInReverseOrder
{
  // FIXME: Is this what is needed? I'm not sure how this is worked out.
  NSString *result;
  
  result = [self stringForKey: @"DefaultOutputOrder" 
                      inTable: @"PPD"];

  if (!result)
      return NO;
  
  if ( [result caseInsensitiveCompare: @"REVERSE"] == NSOrderedSame)
    return YES;
  else
    return NO;
}


-(NSDictionary*) deviceDescription
{
  NSMutableDictionary *result;


  result = [NSMutableDictionary dictionary];
  
  if( [self isKey: @"DefaultResolution" 
          inTable:@"PPD"])
    {
      int dpi = [self intForKey: @"DefaultResolution" 
                        inTable: @"PPD"];

      [result setObject: [NSNumber numberWithInt: dpi]
                forKey: NSDeviceResolution];
    }

  if( [self isKey: @"ColorDevice" 
          inTable: @"PPD"])
    {
      BOOL color = [self booleanForKey: @"ColorDevice" 
                      inTable: @"PPD"];

      // FIXME: Should NSDeviceWhiteColorSpace be NSDeviceBlackColorSpace?
      // FIXME #2: Are they calibrated?
      // Basically I'm not sure which color spaces should be used...
      if( color == YES )
        {
          [result setObject: NSDeviceCMYKColorSpace
                     forKey: NSDeviceColorSpaceName];
        }
      else
        {
          [result setObject: NSDeviceWhiteColorSpace
                     forKey: NSDeviceColorSpaceName];
        }
    }

  if( [self isKey: @"DefaultBitsPerPixel" 
          inTable: @"PPD"] )
    {
      int bits = [self intForKey: @"DefaultBitsPerPixel" 
                         inTable: @"PPD"];

      [result setObject: [NSNumber numberWithInt: bits]
                 forKey: NSDeviceBitsPerSample];
    }

  if( [self isKey: @"DefaultPageSize"
          inTable: @"PPD"] )
    {
      NSString* defaultPageSize = [self stringForKey: @"DefaultPageSize"
                                             inTable: @"PPD"];

      if( defaultPageSize )
        {
          NSSize paperSize = [self pageSizeForPaper: defaultPageSize];

          [result setObject: [NSValue valueWithSize:paperSize]
                     forKey: NSDeviceSize];
        }
    }

  [result setObject: [NSNumber numberWithBool:NO]
             forKey: NSDeviceIsScreen];

  [result setObject: [NSNumber numberWithBool:YES]
             forKey: NSDeviceIsPrinter];

  NSDebugMLLog(@"GSPrinting", @"Device Description: %@", [result description]);
  return result;
}



-(id) initWithCoder: (NSCoder*) coder
{
  return [super initWithCoder: coder];
}


-(void) encodeWithCoder: (NSCoder*) coder
{
  [super encodeWithCoder: coder];
}

@end





@implementation GSLPRPrinter (Private)
//
// Load the printer setup from NSUserDefaults
//
+ (NSDictionary*) printersDictionary
{
  NSUserDefaults* defaults;
  NSDictionary *printers;
  
  defaults = [NSUserDefaults standardUserDefaults];

  printers = [defaults objectForKey: @"GSLPRPrinters"];

  if( !printers ) //Not set, make a default printer because we are nice.
    {
      NSString *ppdPath;
      NSMutableDictionary *printerEntry;

      printers = [NSMutableDictionary dictionary];
      printerEntry = [NSMutableDictionary dictionary];

      ppdPath = [NSBundle pathForLibraryResource: @"Apple_LaserWriter_II_NTX"
                                          ofType: @"ppd"
                                     inDirectory: @"PostScript/PPD"];

      [printerEntry setObject: ppdPath
                       forKey: @"PPDPath"];

      [printerEntry setObject: @"localhost"
                       forKey: @"Host"];

      [printerEntry setObject: @"Automatically Generated"
                       forKey: @"Note"];

      [printerEntry setObject: @"Unknown"
                       forKey: @"Type"];

      [(NSMutableDictionary*)printers setObject: printerEntry
                                         forKey: @"Unnamed"];

      NSLog(@"Creating a default printer since one is not \
in the User Defaults (GSLPRPrinters). Description: %@",
             [printerEntry description]);
  }

  return printers;
}




//
// Initialisation method
//
// To keep loading of PPDs relatively fast, not much checking is done on it.
-(id) initWithName: (NSString*) name
          withType: (NSString*) type
          withHost: (NSString*) host
          withNote: (NSString*) note
       withPPDPath: (NSString*) ppdPath
{
  NSDebugMLLog(@"GSPrinting", @"");
  
  self = [super initWithName: name
                    withType: type
                    withHost: host
                    withNote: note];

  [self parsePPDAtPath: ppdPath];
  
  return self;
}



@end
